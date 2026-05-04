import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
      backgroundColor: AppColors.dashboardSurface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 32,
                children: [
                  // ── Header: SMARTATTEND + subtitle ──
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 8,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'SMART',
                              style: TextStyle(
                                color: AppColors.orange,
                                fontSize: 57,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                height: 1.20,
                                letterSpacing: -1.20,
                              ),
                            ),
                            TextSpan(
                              text: 'ATTEND',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 57,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                height: 1.20,
                                letterSpacing: -1.20,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Text(
                        'Selamat Datang!!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.grayMedium,
                          fontSize: 18,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w400,
                          height: 1.56,
                        ),
                      ),
                    ],
                  ),

                  // ── Card form login ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      top: 40,
                      left: 32,
                      right: 32,
                      bottom: 32,
                    ),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 2,
                          color: AppColors.grayDark,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: ValueListenableBuilder<bool>(
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
                  ),

                  // ── Info box akun testing (hapus di production) ──
                  // Container(
                  //   width: double.infinity,
                  //   padding: const EdgeInsets.all(16),
                  //   decoration: ShapeDecoration(
                  //     color: AppColors.skyBlue,
                  //     shape: RoundedRectangleBorder(
                  //       side: const BorderSide(
                  //         width: 2,
                  //         color: AppColors.grayDark,
                  //       ),
                  //       borderRadius: BorderRadius.circular(4),
                  //     ),
                  //   ),
                  //   child: const Text(
                  //     'Mahasiswa: 241511033 (Pass: *PassMhs033#)\n'
                  //     'Dosen: KO009N (Pass: \$2b\$10\$defaultHashForDosen123)\n'
                  //     'Gunakan sesuai data di database.',
                  //     style: TextStyle(
                  //       color: AppColors.royalBlue,
                  //       fontSize: 10,
                  //       fontFamily: 'Plus Jakarta Sans',
                  //       fontWeight: FontWeight.w400,
                  //       height: 1.25,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
