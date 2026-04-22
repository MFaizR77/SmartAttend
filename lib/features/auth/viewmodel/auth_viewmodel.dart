import 'package:flutter/foundation.dart';
import '../../../data/local/models/user.dart';
import '../../../data/remote/database_service.dart';
/// ViewModel untuk autentikasi.
/// Mencocokkan email+password ke dummy data, role otomatis dari data.
class AuthViewModel {
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<User?> currentUser = ValueNotifier(null);

  /// Login dengan email dan password.
  /// Mencocokkan ke [DummyData.users], role ditentukan otomatis.
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

        currentUser.value = User(
          id: dbUser['_id']?.toString() ?? '',
          nama: dbUser['nama'] ?? 'Unknown',
          email: dbUser['email'] ?? '',
          role: mappedRole,
          passwordHash: dbUser['passwordHash'] ?? '',
          createdAt: dbUser['createdAt'] != null 
              ? DateTime.tryParse(dbUser['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
        );
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
  void logout() {
    currentUser.value = null;
    errorMessage.value = null;
    isLoading.value = false;
  }

  /// Bersihkan resource.
  void dispose() {
    isLoading.dispose();
    errorMessage.dispose();
    currentUser.dispose();
  }
}
