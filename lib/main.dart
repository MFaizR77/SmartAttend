import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/auth/view/login_screen.dart';
import 'features/mahasiswa/dashboard/view/mahasiswa_dashboard_screen.dart';
import 'features/dosen/dashboard/view/dosen_dashboard_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/admin/dashboard/view/admin_dashboard_screen.dart';
import 'data/local/hive_helper.dart';
import 'data/local/models/user.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await HiveHelper.init();
  await initializeDateFormatting('id_ID', null);
  
  final authViewModel = AuthViewModel();
  await authViewModel.checkOfflineSession();

  runApp(SmartAttendApp(authViewModel: authViewModel));
}

/// Root widget aplikasi SmartAttend.
class SmartAttendApp extends StatefulWidget {
  final AuthViewModel authViewModel;
  const SmartAttendApp({super.key, required this.authViewModel});

  @override
  State<SmartAttendApp> createState() => _SmartAttendAppState();
}

class _SmartAttendAppState extends State<SmartAttendApp> {
  late AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = widget.authViewModel;
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    super.dispose();
  }

  /// Logout — reset state dan kembali ke login.
  void _handleLogout(BuildContext context) async {
    await _authViewModel.logout();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authViewModel.currentUser.value;
    String initialRoute = '/login';
    
    if (currentUser != null) {
      if (currentUser.role == UserRole.mahasiswa) initialRoute = '/mahasiswa';
      else if (currentUser.role == UserRole.dosen) initialRoute = '/dosen';
      else if (currentUser.role == UserRole.admin) initialRoute = '/admin';
    }

    return MaterialApp(
      title: 'SmartAttend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: initialRoute,
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
