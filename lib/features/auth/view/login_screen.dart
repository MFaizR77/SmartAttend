import 'package:flutter/material.dart';
import '../../../data/local/models/user.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'widgets/login_form.dart';

/// Halaman login SmartAttend.
/// Satu form untuk semua role — sistem auto-detect dari credential.
class LoginScreen extends StatefulWidget {
  final AuthViewModel authViewModel;

  const LoginScreen({super.key, required this.authViewModel});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthViewModel get _vm => widget.authViewModel;

  @override
  void initState() {
    super.initState();
    // Navigasi otomatis saat login berhasil
    _vm.currentUser.addListener(_onUserChanged);
  }

  @override
  void dispose() {
    _vm.currentUser.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    final user = _vm.currentUser.value;
    if (user == null) return;

    // Redirect ke dashboard sesuai role
    String route;
    switch (user.role) {
      case UserRole.mahasiswa:
        route = '/mahasiswa';
        break;
      case UserRole.dosen:
        route = '/dosen';
        break;
      case UserRole.admin:
        route = '/admin';
        break;
    }

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo & nama app
                const Icon(
                  Icons.school_rounded,
                  size: 64,
                  color: Color(0xFF3B82F6),
                ),
                const SizedBox(height: 12),
                Text(
                  'SmartAttend',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sistem Presensi Mahasiswa',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 40),

                // Form login dalam card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Masuk',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Masukkan NIM/ID dan password untuk melanjutkan',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form — listen loading & error dari ViewModel
                        ValueListenableBuilder<bool>(
                          valueListenable: _vm.isLoading,
                          builder: (context, isLoading, _) {
                            return ValueListenableBuilder<String?>(
                              valueListenable: _vm.errorMessage,
                              builder: (context, errorMsg, _) {
                                return LoginForm(
                                  isLoading: isLoading,
                                  errorMessage: errorMsg,
                                  onLogin: (identifier, password) {
                                    _vm.login(identifier, password);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Info akun testing (hapus di production)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Color(0xFF3B82F6)),
                          const SizedBox(width: 6),
                          Text(
                            'Akun Testing',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                        const Text(
                        'Mahasiswa: 241511033 (Pass: *PassMhs033#)\n'
                        'Dosen: KO009N (Pass: \$2b\$10\$defaultHashForDosen123)\n'
                        'Gunakan sesuai data di database.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1E1E2C), height: 1.6),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
