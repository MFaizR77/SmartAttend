import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/auth/view/login_screen.dart';
import 'features/mahasiswa/dashboard/view/mahasiswa_dashboard_screen.dart';
import 'features/dosen/dashboard/view/dosen_dashboard_screen.dart';
import 'features/admin/dashboard/view/admin_dashboard_screen.dart';

void main() {
  runApp(const SmartAttendApp());
}

/// Root widget aplikasi SmartAttend.
class SmartAttendApp extends StatefulWidget {
  const SmartAttendApp({super.key});

  @override
  State<SmartAttendApp> createState() => _SmartAttendAppState();
}

class _SmartAttendAppState extends State<SmartAttendApp> {
  final _authViewModel = AuthViewModel();

  @override
  void dispose() {
    _authViewModel.dispose();
    super.dispose();
  }

  /// Logout — reset state dan kembali ke login.
  void _handleLogout(BuildContext context) {
    _authViewModel.logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartAttend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(
              builder: (_) => LoginScreen(authViewModel: _authViewModel),
            );

          case '/mahasiswa':
            final user = _authViewModel.currentUser.value;
            if (user == null) return _redirectToLogin();
            return MaterialPageRoute(
              builder: (ctx) => MahasiswaDashboardScreen(
                user: user,
                onLogout: () => _handleLogout(ctx),
              ),
            );

          case '/dosen':
            final user = _authViewModel.currentUser.value;
            if (user == null) return _redirectToLogin();
            return MaterialPageRoute(
              builder: (ctx) => DosenDashboardScreen(
                user: user,
                onLogout: () => _handleLogout(ctx),
              ),
            );

          case '/admin':
            final user = _authViewModel.currentUser.value;
            if (user == null) return _redirectToLogin();
            return MaterialPageRoute(
              builder: (ctx) => AdminDashboardScreen(
                user: user,
                onLogout: () => _handleLogout(ctx),
              ),
            );

          default:
            return _redirectToLogin();
        }
      },
    );
  }

  /// Fallback: redirect ke login jika route tidak dikenal atau user null.
  MaterialPageRoute _redirectToLogin() {
    return MaterialPageRoute(
      builder: (_) => LoginScreen(authViewModel: _authViewModel),
    );
  }
}
