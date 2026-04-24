import 'package:flutter/foundation.dart';
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
    final userData = userBox.get('currentUser');
    final expiryStr = userBox.get('expiryDate');

    if (userData != null && expiryStr != null) {
      final expiryDate = DateTime.tryParse(expiryStr.toString());
      if (expiryDate != null && DateTime.now().isBefore(expiryDate)) {
        // Sesi valid
        try {
          currentUser.value = User.fromMap(userData as Map<dynamic, dynamic>);
          return true;
        } catch (e) {
          print('Error parsing offline user: $e');
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
          passwordHash: dbUser['passwordHash'] ?? '',
          createdAt: dbUser['createdAt'] != null 
              ? DateTime.tryParse(dbUser['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
          kelas: dbUser['kelas'], // Menambahkan mapping kelas
        );

        // Simpan sesi ke Hive (Offline First)
        final userBox = HiveHelper.userBoxInstance;
        await userBox.put('currentUser', user.toMap());
        await userBox.put('expiryDate', DateTime.now().add(const Duration(days: 1)).toIso8601String());

        currentUser.value = user;
        errorMessage.value = null;
      } else {
        errorMessage.value = 'NIM/ID atau password salah';
      }
    } catch (e) {
      errorMessage.value = 'Gagal terhubung ke server: $e';
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
    final userBox = HiveHelper.userBoxInstance;
    await userBox.delete('currentUser');
    await userBox.delete('expiryDate');

    DatabaseService().close();
  }

  /// Bersihkan resource.
  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
    currentUser.dispose();
  }
}
