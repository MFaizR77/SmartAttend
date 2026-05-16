import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/viewmodel/auth_viewmodel.dart';
import 'features/auth/view/login_screen.dart';
import 'features/mahasiswa/dashboard/view/mahasiswa_dashboard_screen.dart';
import 'features/mahasiswa/izin/view/izin_screen.dart';
import 'features/dosen/dashboard/view/dosen_dashboard_screen.dart';
import 'features/dosen/tindak_lanjut_izin/view/tindak_lanjut_screen.dart';
import 'features/admin/dashboard/view/admin_dashboard_screen.dart';
import 'features/admin/upload_jadwal/view/upload_jadwal_screen.dart';
import 'features/admin/manajemen_periode/view/manajemen_periode_screen.dart';
import 'features/admin/assign_wali/view/assign_wali_screen.dart';
import 'features/walidosen/dashboard/view/walidosen_dashboard_screen.dart';
import 'features/onboarding/view/onboarding_screen.dart';
import 'data/local/hive_helper.dart';
import 'data/local/models/user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/services/sync_manager.dart';
import 'core/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await HiveHelper.init();
  await initializeDateFormatting('id_ID', null);

  // Inisialisasi proses sinkronisasi background
  SyncManager().init();

  // Inisialisasi notifikasi & timezone
  tz.initializeTimeZones();
  await NotificationService().init();

  final authViewModel = AuthViewModel();
  final hasSession = await authViewModel.checkOfflineSession();

  String initialRoute;
  if (hasSession && authViewModel.currentUser.value != null) {
    final acc = authViewModel.currentUser.value!.accountType;
    switch (acc) {
      case AccountType.mahasiswa:
        initialRoute = '/mahasiswa';
        break;
      case AccountType.dosen:
        initialRoute = '/dosen';
        break;
      case AccountType.walidosen:
        initialRoute = '/walidosen';
        break;
      case AccountType.admin:
        initialRoute = '/admin';
        break;
    }
  } else {
    initialRoute = '/onboarding';
  }

  runApp(SmartAttendApp(
    authViewModel: authViewModel,
    initialRoute: initialRoute,
  ));
}

class SmartAttendApp extends StatefulWidget {
  final AuthViewModel authViewModel;
  final String initialRoute;

  const SmartAttendApp({
    super.key,
    required this.authViewModel,
    required this.initialRoute,
  });

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

  void _handleLogout(BuildContext context) async {
    await _authViewModel.logout();
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartAttend',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: widget.initialRoute,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/onboarding':
            return MaterialPageRoute(
              builder: (_) => const OnboardingScreen(),
            );

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

          case '/walidosen':
            final user = _authViewModel.currentUser.value;
            if (user == null) return _redirectToLogin();
            return MaterialPageRoute(
              builder: (ctx) => WaliDosenDashboardScreen(
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

          case '/mahasiswa/izin':
            final user = _authViewModel.currentUser.value;
            if (user == null) return _redirectToLogin();
            return MaterialPageRoute(
              builder: (_) => IzinScreen(user: user),
            );

          case '/dosen/tindak-lanjut-izin':
            final user = _authViewModel.currentUser.value;
            if (user == null) return _redirectToLogin();
            return MaterialPageRoute(
              builder: (_) => TindakLanjutIzinScreen(user: user),
            );

          case '/admin/upload-jadwal':
            final user = _authViewModel.currentUser.value;
            if (user == null) return _redirectToLogin();
            return MaterialPageRoute(
              builder: (_) => UploadJadwalScreen(user: user),
            );

          case '/admin/periode':
            final user = _authViewModel.currentUser.value;
            if (user == null) return _redirectToLogin();
            return MaterialPageRoute(
              builder: (_) => ManajemenPeriodeScreen(user: user),
            );

          case '/admin/assign-wali':
            final user = _authViewModel.currentUser.value;
            if (user == null) return _redirectToLogin();
            return MaterialPageRoute(
              builder: (_) => AssignWaliScreen(user: user),
            );

          default:
            return _redirectToLogin();
        }
      },
    );
  }

  MaterialPageRoute _redirectToLogin() {
    return MaterialPageRoute(
      builder: (_) => LoginScreen(authViewModel: _authViewModel),
    );
  }
}
