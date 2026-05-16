import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/models/user.dart';
import '../viewmodel/auth_viewmodel.dart';
import 'widgets/login_form.dart';

/// Halaman login SmartAttend dengan dropdown role.
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

    String route;
    switch (user.accountType) {
      case AccountType.mahasiswa:
        route = '/mahasiswa';
        break;
      case AccountType.dosen:
        route = '/dosen';
        break;
      case AccountType.walidosen:
        route = '/walidosen';
        break;
      case AccountType.admin:
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 32,
                children: [
                  // Header
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

                  // Card form
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                      top: 32,
                      left: 32,
                      right: 32,
                      bottom: 32,
                    ),
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(width: 2, color: AppColors.grayDark),
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
                              onLogin: (role, identifier, password) {
                                _vm.loginAs(
                                  accountType: role,
                                  identifier: identifier,
                                  password: password,
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
