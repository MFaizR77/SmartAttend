import 'package:flutter/foundation.dart';
import '../../../data/local/models/user.dart';
import '../../../data/local/dummy_data.dart';

/// ViewModel untuk autentikasi.
/// Mencocokkan email+password ke dummy data, role otomatis dari data.
class AuthViewModel {
  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<String?> errorMessage = ValueNotifier(null);
  final ValueNotifier<User?> currentUser = ValueNotifier(null);

  /// Login dengan email dan password.
  /// Mencocokkan ke [DummyData.users], role ditentukan otomatis.
  Future<void> login(String email, String password) async {
    // Reset error
    errorMessage.value = null;

    // Validasi input
    if (email.trim().isEmpty) {
      errorMessage.value = 'Email tidak boleh kosong';
      return;
    }
    if (password.isEmpty) {
      errorMessage.value = 'Password tidak boleh kosong';
      return;
    }

    isLoading.value = true;

    // Simulasi delay jaringan
    await Future.delayed(const Duration(milliseconds: 800));

    // Cari user yang cocok
    final matchedUser = DummyData.users.where(
      (u) => u.email == email.trim().toLowerCase() && u.passwordHash == password,
    );

    if (matchedUser.isNotEmpty) {
      currentUser.value = matchedUser.first;
      errorMessage.value = null;
    } else {
      errorMessage.value = 'Email atau password salah';
    }

    isLoading.value = false;
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
