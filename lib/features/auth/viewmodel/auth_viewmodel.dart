import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../../data/local/models/user.dart';
import '../../../data/remote/database_service.dart';
import '../../../data/local/hive_helper.dart';

/// ViewModel untuk autentikasi.
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
        // Sesi valid
        try {
          // Decode JSON string back to Map<String, dynamic>
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
        // Sesi expired
        await userBox.delete('currentUser');
        await userBox.delete('expiryDate');
      }
    }
    return false;
  }

  /// Login dengan email dan password.
  Future<void> login(String identifier, String password) async {
    // Reset error
    errorMessage.value = null;

    // Validasi input
    if (identifier.trim().isEmpty) {
      errorMessage.value = 'NIM/ID tidak boleh kosong';
      return;
    }
    if (password.isEmpty) {
      errorMessage.value = 'Password tidak boleh kosong';
      return;
    }

    isLoading.value = true;

    try {
      final dbUser = await DatabaseService().login(identifier.trim(), password);

      if (dbUser != null) {
        UserRole mappedRole = UserRole.mahasiswa;
        if (dbUser['role'] == 'dosen') mappedRole = UserRole.dosen;
        if (dbUser['role'] == 'admin') mappedRole = UserRole.admin;

        final user = User(
          id: dbUser['nim']?.toString() ?? dbUser['kode']?.toString() ?? dbUser['_id']?.toString() ?? '',
          nama: dbUser['nama'] ?? 'Unknown',
          email: dbUser['email'] ?? '',
          role: mappedRole,
          passwordHash: password, // Simpan password plain yang diketik agar bisa dicek saat offline
          createdAt: dbUser['createdAt'] != null 
              ? DateTime.tryParse(dbUser['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
          kelas: dbUser['kelas'],
        );

        // Simpan sesi ke Hive (Offline First)
        final userBox = HiveHelper.userBoxInstance;
        await userBox.put('currentUser', jsonEncode(user.toMap()));
        await userBox.put('expiryDate', DateTime.now().add(const Duration(days: 1)).toIso8601String());

        currentUser.value = user;
        errorMessage.value = null;
      } else {
        errorMessage.value = 'NIM/ID atau password salah';
      }
    } on SocketException catch (e) {
      debugPrint('SocketException saat login: $e');
      errorMessage.value =
          'Koneksi internet bermasalah. Periksa jaringan lalu coba lagi.';
    } catch (e) {
      // Jika gagal connect ke server (offline), coba validasi dengan data lokal di Hive
      final message = e.toString();
      debugPrint('Login error: $message');
      final isNetworkError =
          message.contains('SocketException') ||
          message.contains('ConnectionException') ||
          message.contains('HandshakeException') ||
          message.contains('Failed host lookup') ||
          message.contains('ClientException with SocketException');

      if (isNetworkError) {
        final userBox = HiveHelper.userBoxInstance;
        final userDataStr = userBox.get('currentUser');
        final expiryStr = userBox.get('expiryDate');

        if (userDataStr != null && expiryStr != null) {
          try {
            Map<String, dynamic> userMap;
            if (userDataStr is String) {
              userMap = jsonDecode(userDataStr);
            } else {
              userMap = Map<String, dynamic>.from(userDataStr as Map);
            }
            final localUser = User.fromMap(userMap);

            // Pengecekan kredensial lokal
            final isIdentifierMatch =
                localUser.id == identifier.trim() ||
                localUser.email == identifier.trim();
            // Asumsi passwordHash lokal menyimpan nilai yang bisa dicocokkan saat offline.
            final isPasswordMatch = localUser.passwordHash == password;

            if (isIdentifierMatch && isPasswordMatch) {
              final expiryDate = DateTime.tryParse(expiryStr.toString());
              if (expiryDate != null && DateTime.now().isBefore(expiryDate)) {
                currentUser.value = localUser;
                errorMessage.value = null;
                isLoading.value = false;
                return; // Sukses login offline
              } else {
                errorMessage.value =
                    'Sesi offline telah kadaluarsa (lebih dari 1 hari). Anda harus online.';
              }
            } else {
              errorMessage.value = 'NIM/ID atau password salah (Mode Offline)';
            }
          } catch (offlineErr) {
            errorMessage.value = 'Gagal membaca sesi offline: $offlineErr';
          }
        } else {
          errorMessage.value =
              'Anda sedang offline dan belum pernah login sebelumnya di perangkat ini.';
        }
      } else {
        errorMessage.value = 'Gagal login. Coba lagi dalam beberapa saat.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout — reset semua state.
  Future<void> logout() async {
    currentUser.value = null;
    errorMessage.value = null;
    isLoading.value = false;
    
    // Hapus sesi di Hive
    // final userBox = HiveHelper.userBoxInstance; 
    // await userBox.delete('currentUser');
    // await userBox.delete('expiryDate'); 

    DatabaseService().close();
  }

  /// Bersihkan resource.
  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
    currentUser.dispose();
  }
}
