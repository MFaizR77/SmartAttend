import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../data/local/hive_helper.dart';
import '../../../data/local/models/user.dart';
import '../../../data/remote/database_service.dart';

/// ViewModel untuk autentikasi multi-role.
///
/// Login flow (offline-first):
///   1. Cek konektivitas — kalau offline, langsung pakai sesi lokal Hive.
///   2. Kalau online, coba login ke Mongo.
///   3. Kalau online tapi server unreachable (timeout/dns/dll), fallback ke
///      sesi lokal Hive.
///   4. Sesi lokal valid 30 hari sejak login online terakhir.
class AuthViewModel {
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<User?> currentUser = ValueNotifier(null);

  /// Cek sesi offline saat aplikasi dibuka. Dipakai di main() untuk skip
  /// login screen kalau session di Hive masih valid.
  Future<bool> checkOfflineSession() async {
    final userBox = HiveHelper.userBoxInstance;
    final userDataStr = userBox.get('currentUser');
    final expiryStr = userBox.get('expiryDate');

    if (userDataStr != null && expiryStr != null) {
      final expiryDate = DateTime.tryParse(expiryStr.toString());
      if (expiryDate != null && DateTime.now().isBefore(expiryDate)) {
        try {
          Map<String, dynamic> userMap;
          if (userDataStr is String) {
            userMap = jsonDecode(userDataStr);
          } else {
            userMap = Map<String, dynamic>.from(userDataStr as Map);
          }
          currentUser.value = User.fromMap(userMap);
          return true;
        } catch (e) {
          debugPrint('Error parsing offline user: $e');
        }
      } else {
        await userBox.delete('currentUser');
        await userBox.delete('expiryDate');
      }
    }
    return false;
  }

  /// Login dengan tipe akun eksplisit. Ini metode utama yang dipakai UI.
  Future<void> loginAs({
    required AccountType accountType,
    required String identifier,
    required String password,
  }) async {
    errorMessage.value = null;

    if (identifier.trim().isEmpty) {
      errorMessage.value = 'Username tidak boleh kosong';
      return;
    }
    if (password.isEmpty) {
      errorMessage.value = 'Password tidak boleh kosong';
      return;
    }

    isLoading.value = true;

    try {
      // ── 1. Pre-check connectivity ────────────────────────────────────
      // connectivity_plus tidak garansi server reachable — cuma garansi
      // device punya koneksi. Tapi cukup untuk skip percobaan online yang
      // sudah pasti gagal kalau sinyal mati total.
      final isOnline = await ConnectivityService().checkNow();
      if (!isOnline) {
        await _tryOfflineLogin(accountType, identifier, password);
        return;
      }

      // ── 2. Online attempt ────────────────────────────────────────────
      Map<String, dynamic>? doc;
      try {
        doc = await _onlineLogin(accountType, identifier, password)
            .timeout(const Duration(seconds: 12));
      } on TimeoutException {
        debugPrint('Online login timeout, fallback ke offline.');
        await _tryOfflineLogin(accountType, identifier, password);
        return;
      } on SocketException catch (e) {
        debugPrint('SocketException saat login: $e');
        await _tryOfflineLogin(accountType, identifier, password);
        return;
      } catch (e) {
        // mongo_dart suka throw error yang bukan SocketException langsung
        // (MongoDartError, ConnectionException, dll). Cek substring sebagai
        // safety net, lalu fallback ke offline.
        final msg = e.toString();
        final transient = msg.contains('SocketException') ||
            msg.contains('ConnectionException') ||
            msg.contains('HandshakeException') ||
            msg.contains('Failed host lookup') ||
            msg.contains('ClientException') ||
            msg.contains('Timeout') ||
            msg.contains('No master') ||
            msg.contains('reset by peer') ||
            msg.contains('connection closed');
        if (transient) {
          debugPrint('Transient online error, fallback ke offline: $e');
          await _tryOfflineLogin(accountType, identifier, password);
          return;
        }
        // Error yang bukan jaringan — kemungkinan bug, jangan diam-diam.
        errorMessage.value = 'Gagal login. Coba lagi dalam beberapa saat.';
        debugPrint('Login non-transient error: $e');
        return;
      }

      // ── 3. Process result ────────────────────────────────────────────
      if (doc != null) {
        final user = _userFromDoc(doc, accountType, password);
        await _persistSession(user);
        currentUser.value = user;
        errorMessage.value = null;
      } else {
        // Server jawab, tapi credential salah. Coba match offline juga —
        // mungkin user pakai password lama tapi belum sync. Konservatif:
        // tampilkan invalid credential.
        errorMessage.value = _msgInvalid(accountType);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Backward-compat: login lama tanpa accountType. Cari ke semua koleksi.
  Future<void> login(String identifier, String password) async {
    errorMessage.value = null;
    if (identifier.trim().isEmpty) {
      errorMessage.value = 'Username tidak boleh kosong';
      return;
    }
    if (password.isEmpty) {
      errorMessage.value = 'Password tidak boleh kosong';
      return;
    }

    isLoading.value = true;
    try {
      final isOnline = await ConnectivityService().checkNow();
      if (!isOnline) {
        // Tanpa accountType, fallback offline minimal: cek match user lokal.
        await _tryOfflineLoginAny(identifier, password);
        return;
      }

      try {
        final doc = await DatabaseService()
            .login(identifier.trim(), password)
            .timeout(const Duration(seconds: 12));
        if (doc != null) {
          final accStr = doc['_accountType']?.toString() ?? 'mahasiswa';
          final acc = AccountType.values.firstWhere(
            (e) => e.name == accStr,
            orElse: () => AccountType.mahasiswa,
          );
          final user = _userFromDoc(doc, acc, password);
          await _persistSession(user);
          currentUser.value = user;
          errorMessage.value = null;
        } else {
          errorMessage.value = 'Username atau password salah';
        }
      } catch (e) {
        await _tryOfflineLoginAny(identifier, password);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout — bersihkan state runtime, JANGAN hapus session Hive
  /// (agar offline-login berikutnya tetap bisa).
  Future<void> logout() async {
    currentUser.value = null;
    errorMessage.value = null;
    isLoading.value = false;
    DatabaseService().close();
  }

  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
    currentUser.dispose();
  }

  // ────────────────────────────────────────────
  // INTERNAL
  // ────────────────────────────────────────────

  Future<Map<String, dynamic>?> _onlineLogin(
    AccountType accountType,
    String identifier,
    String password,
  ) {
    final svc = DatabaseService();
    switch (accountType) {
      case AccountType.mahasiswa:
        return svc.loginMahasiswa(identifier.trim(), password);
      case AccountType.dosen:
        return svc.loginDosen(identifier.trim(), password);
      case AccountType.walidosen:
        return svc.loginWaliDosen(identifier.trim(), password);
      case AccountType.kaprodi:
        return svc.loginKaprodi(identifier.trim(), password);
      case AccountType.admin:
        return svc.loginAdmin(identifier.trim(), password);
    }
  }

  String _msgInvalid(AccountType acc) {
    switch (acc) {
      case AccountType.mahasiswa:
        return 'NIM atau password salah';
      case AccountType.dosen:
        return 'Kode dosen atau password salah';
      case AccountType.walidosen:
        return 'Kode wali dosen atau password salah';
      case AccountType.kaprodi:
        return 'Kode kaprodi atau password salah';
      case AccountType.admin:
        return 'Kode admin atau password salah';
    }
  }

  User _userFromDoc(Map<String, dynamic> doc, AccountType acc, String password) {
    UserRole role;
    switch (acc) {
      case AccountType.mahasiswa:
        role = UserRole.mahasiswa;
        break;
      case AccountType.dosen:
      case AccountType.walidosen:
      case AccountType.kaprodi:
        role = UserRole.dosen;
        break;
      case AccountType.admin:
        role = UserRole.admin;
        break;
    }

    final id = doc['_id']?.toString() ??
        doc['nim']?.toString() ??
        doc['kode']?.toString() ??
        '';

    return User(
      id: id,
      nama: doc['nama']?.toString() ?? 'Unknown',
      email: doc['email']?.toString() ?? '',
      role: role,
      accountType: acc,
      passwordHash: password,
      createdAt: doc['createdAt'] != null
          ? (doc['createdAt'] is DateTime
              ? doc['createdAt'] as DateTime
              : DateTime.tryParse(doc['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      kelas: doc['kelas']?.toString(),
      program: doc['program']?.toString(),
      kelasWali: doc['kelasWali']?.toString(),
      dosenKode: doc['dosenKode']?.toString(),
    );
  }

  Future<void> _persistSession(User user) async {
    final userBox = HiveHelper.userBoxInstance;
    await userBox.put('currentUser', jsonEncode(user.toMap()));
    await userBox.put(
      'expiryDate',
      DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    );
  }

  /// Fallback offline login — match credential yang user input dengan sesi
  /// lokal yang tersimpan saat login online terakhir.
  Future<void> _tryOfflineLogin(
    AccountType acc,
    String identifier,
    String password,
  ) async {
    final localUser = _loadLocalUser();
    if (localUser == null) {
      errorMessage.value = 'Anda offline dan belum pernah login di perangkat ini.';
      return;
    }
    final id = identifier.trim();
    final identifierMatch = localUser.id == id || localUser.email == id;
    final passwordMatch = localUser.passwordHash == password;
    final accountMatch = localUser.accountType == acc;

    if (!identifierMatch || !passwordMatch) {
      errorMessage.value = 'Username atau password salah (Mode Offline)';
      return;
    }
    if (!accountMatch) {
      errorMessage.value = 'Sesi offline tersimpan untuk role yang berbeda.';
      return;
    }
    if (_isSessionExpired()) {
      errorMessage.value = 'Sesi offline kadaluarsa. Anda harus online sekali.';
      return;
    }
    currentUser.value = localUser;
    errorMessage.value = null;
  }

  /// Versi tanpa cek role — untuk method `login()` legacy.
  Future<void> _tryOfflineLoginAny(String identifier, String password) async {
    final localUser = _loadLocalUser();
    if (localUser == null) {
      errorMessage.value = 'Anda offline dan belum pernah login di perangkat ini.';
      return;
    }
    final id = identifier.trim();
    final identifierMatch = localUser.id == id || localUser.email == id;
    final passwordMatch = localUser.passwordHash == password;
    if (!identifierMatch || !passwordMatch) {
      errorMessage.value = 'Username atau password salah (Mode Offline)';
      return;
    }
    if (_isSessionExpired()) {
      errorMessage.value = 'Sesi offline kadaluarsa. Anda harus online sekali.';
      return;
    }
    currentUser.value = localUser;
    errorMessage.value = null;
  }

  User? _loadLocalUser() {
    final userBox = HiveHelper.userBoxInstance;
    final userDataStr = userBox.get('currentUser');
    if (userDataStr == null) return null;
    try {
      Map<String, dynamic> userMap;
      if (userDataStr is String) {
        userMap = jsonDecode(userDataStr);
      } else {
        userMap = Map<String, dynamic>.from(userDataStr as Map);
      }
      return User.fromMap(userMap);
    } catch (e) {
      debugPrint('Gagal parse local user: $e');
      return null;
    }
  }

  bool _isSessionExpired() {
    final userBox = HiveHelper.userBoxInstance;
    final expiryStr = userBox.get('expiryDate');
    if (expiryStr == null) return true;
    final expiryDate = DateTime.tryParse(expiryStr.toString());
    if (expiryDate == null) return true;
    return !DateTime.now().isBefore(expiryDate);
  }
}
