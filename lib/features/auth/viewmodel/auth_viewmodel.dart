import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../../data/local/models/user.dart';
import '../../../data/remote/database_service.dart';
import '../../../data/local/hive_helper.dart';

/// ViewModel untuk autentikasi multi-role.
///
/// Login flow:
///   - User pilih [AccountType] di login screen.
///   - Service cari ke koleksi yang sesuai (mahasiswa/dosen/wali_dosen/admin).
///   - Kalau berhasil, simpan sesi ke Hive (30 hari).
///   - Kalau offline & sesi valid, login pakai data lokal.
class AuthViewModel {
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<User?> currentUser = ValueNotifier(null);

  /// Cek sesi offline saat aplikasi dibuka
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

  /// Login dengan tipe akun eksplisit. Ini metode utama.
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
      final svc = DatabaseService();
      Map<String, dynamic>? doc;
      switch (accountType) {
        case AccountType.mahasiswa:
          doc = await svc.loginMahasiswa(identifier.trim(), password);
          break;
        case AccountType.dosen:
          doc = await svc.loginDosen(identifier.trim(), password);
          break;
        case AccountType.walidosen:
          doc = await svc.loginWaliDosen(identifier.trim(), password);
          break;
        case AccountType.admin:
          doc = await svc.loginAdmin(identifier.trim(), password);
          break;
      }

      if (doc != null) {
        final user = _userFromDoc(doc, accountType, password);
        await _persistSession(user);
        currentUser.value = user;
        errorMessage.value = null;
      } else {
        errorMessage.value = _msgInvalid(accountType);
      }
    } on SocketException catch (e) {
      debugPrint('SocketException saat login: $e');
      errorMessage.value = 'Koneksi internet bermasalah. Periksa jaringan lalu coba lagi.';
    } catch (e) {
      final message = e.toString();
      debugPrint('Login error: $message');
      final isNetworkError = message.contains('SocketException') ||
          message.contains('ConnectionException') ||
          message.contains('HandshakeException') ||
          message.contains('Failed host lookup') ||
          message.contains('ClientException');

      if (isNetworkError) {
        await _tryOfflineLogin(accountType, identifier, password);
      } else {
        errorMessage.value = 'Gagal login. Coba lagi dalam beberapa saat.';
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
      final doc = await DatabaseService().login(identifier.trim(), password);
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
      // Tangani offline
      final message = e.toString();
      final isNetworkError = message.contains('SocketException') ||
          message.contains('ConnectionException') ||
          message.contains('HandshakeException') ||
          message.contains('Failed host lookup');
      if (isNetworkError) {
        await _tryOfflineLogin(AccountType.mahasiswa, identifier, password);
      } else {
        errorMessage.value = 'Gagal login. Coba lagi.';
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

  String _msgInvalid(AccountType acc) {
    switch (acc) {
      case AccountType.mahasiswa: return 'NIM atau password salah';
      case AccountType.dosen: return 'Kode dosen atau password salah';
      case AccountType.walidosen: return 'Kode wali dosen atau password salah';
      case AccountType.admin: return 'Kode admin atau password salah';
    }
  }

  User _userFromDoc(Map<String, dynamic> doc, AccountType acc, String password) {
    UserRole role;
    switch (acc) {
      case AccountType.mahasiswa: role = UserRole.mahasiswa; break;
      case AccountType.dosen:
      case AccountType.walidosen: role = UserRole.dosen; break;
      case AccountType.admin: role = UserRole.admin; break;
    }

    final id = doc['_id']?.toString()
        ?? doc['nim']?.toString()
        ?? doc['kode']?.toString()
        ?? '';

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

  Future<void> _tryOfflineLogin(
    AccountType acc,
    String identifier,
    String password,
  ) async {
    final userBox = HiveHelper.userBoxInstance;
    final userDataStr = userBox.get('currentUser');
    final expiryStr = userBox.get('expiryDate');

    if (userDataStr == null || expiryStr == null) {
      errorMessage.value = 'Anda offline dan belum pernah login di perangkat ini.';
      return;
    }
    try {
      Map<String, dynamic> userMap;
      if (userDataStr is String) {
        userMap = jsonDecode(userDataStr);
      } else {
        userMap = Map<String, dynamic>.from(userDataStr as Map);
      }
      final localUser = User.fromMap(userMap);
      final identifierMatch = localUser.id == identifier.trim() || localUser.email == identifier.trim();
      final passwordMatch = localUser.passwordHash == password;
      final accountMatch = localUser.accountType == acc;

      if (identifierMatch && passwordMatch && accountMatch) {
        final expiryDate = DateTime.tryParse(expiryStr.toString());
        if (expiryDate != null && DateTime.now().isBefore(expiryDate)) {
          currentUser.value = localUser;
          errorMessage.value = null;
        } else {
          errorMessage.value = 'Sesi offline kadaluarsa. Anda harus online.';
        }
      } else if (!accountMatch) {
        errorMessage.value = 'Sesi offline tersimpan untuk role yang berbeda.';
      } else {
        errorMessage.value = 'Username atau password salah (Mode Offline)';
      }
    } catch (e) {
      errorMessage.value = 'Gagal membaca sesi offline.';
    }
  }
}
