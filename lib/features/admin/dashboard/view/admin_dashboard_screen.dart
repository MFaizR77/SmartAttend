import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../data/local/models/user.dart';
import '../../dashboard/viewmodel/admin_dashboard_viewmodel.dart';
import '../../approval_jadwal/view/approval_jadwal_screen.dart';
import '../../../profil/view/profil_screen.dart';
import '../../manajemen_user/view/manajemen_user_screen.dart';
import '../../manajemen_jadwal/view/manajemen_jadwal_screen.dart';
import '../../rekap/view/rekap_admin_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const AdminDashboardScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _vm = AdminDashboardViewModel();
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _vm.loadData();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actionsAlignment: MainAxisAlignment.center,
            title: const Text(
              'Keluar Aplikasi?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Text(
              'Apakah Anda yakin ingin keluar dari aplikasi?',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
            ),
            actions: [
              SizedBox(
                width: 110,
                height: 40,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(bottom: false, child: _buildCurrentScreen(bottomInset)),
        bottomNavigationBar: _buildBottomNav(bottomInset),
      ),
    );
  }

  Widget _buildCurrentScreen(double bottomInset) {
    switch (_currentNavIndex) {
      case 0:
        return _buildDashboardContent(bottomInset);
      case 1:
        return const ManajemenUserScreen();
      case 2:
        return const ManajemenJadwalScreen();
      case 3:
        return ProfilScreen(user: widget.user, onLogout: widget.onLogout);
      default:
        return _buildDashboardContent(bottomInset);
    }
  }

  Widget _buildDashboardContent(double bottomInset) {
    return Column(
      children: [
        _buildTopHeader(),
        Expanded(
          child: Container(
            color: AppColors.surface,
            child: RefreshIndicator(
              onRefresh: () => _vm.loadData(),
              color: AppColors.primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, 24, 24, 124 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Peringatan Sistem'),
                    const SizedBox(height: 16),
                    _buildAlertBanner(),
                    const SizedBox(height: 34),
                    _buildSectionTitle('Menu Cepat'),
                    const SizedBox(height: 16),
                    _buildMenuRow(),
                    const SizedBox(height: 34),
                    _buildSectionTitle('Aktivitas Terbaru'),
                    const SizedBox(height: 16),
                    _buildActivityLog(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.29, -0.41),
          end: Alignment(0.71, 1.41),
          colors: [Color(0xFF1A237E), Color(0xFF1E3A8A), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Halo,\n${widget.user.nama}!',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    fontSize: 28,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildAvatar(widget.user.nama),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.user.roleLabel,
                  style: const TextStyle(
                    color: AppColors.grayDark,
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: ConnectivityService().isOnline,
                builder: (_, isOnline, __) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? Colors.white.withOpacity(0.24)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOnline
                          ? AppColors.surface
                          : Colors.red.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                        color: isOnline ? AppColors.surface : Colors.red,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          color: isOnline ? AppColors.surface : Colors.red,
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initials = _initials(name);
    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8003),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3949AB), Color(0xFF1A237E)],
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    final first = parts[0].substring(0, 1);
    final second = parts[1].substring(0, 1);
    return '$first$second'.toUpperCase();
  }

  Widget _buildOverviewCards() {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: _vm.statistik,
      builder: (_, stats, child) {
        if (stats.isEmpty) return const SizedBox.shrink();
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _buildOverviewCard(
              'Total Mahasiswa',
              '${stats['totalMahasiswa']}',
              AppColors.accent,
            ),
            _buildOverviewCard(
              'Total Dosen',
              '${stats['totalDosen']}',
              AppColors.primary,
            ),
            _buildOverviewCard(
              'Sesi Hari Ini',
              '${stats['sesiHariIni']}',
              AppColors.success,
            ),
            _buildOverviewCard(
              'Kehadiran',
              '${stats['tingkatKehadiran']}%',
              AppColors.warning,
            ),
          ],
        );
      },
    );
  }

  Widget _buildOverviewCard(String label, String value, Color valueColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x19000000), blurRadius: 12, spreadRadius: -6),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
    );
  }

  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '1 mahasiswa mendekati batas alpha (Rina Amelia — 4/5 alpha)',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.warning.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow() {
    final menus = [
      {'icon': Icons.people, 'label': 'Users'},
      {'icon': Icons.domain_verification, 'label': 'Approval'},
      {'icon': Icons.calendar_month, 'label': 'Jadwal'},
      {'icon': Icons.bar_chart, 'label': 'Rekap'},
    ];

    return Row(
      children: menus.map((menu) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: menu == menus.last ? 0 : 10),
            child: GestureDetector(
              onTap: () {
                if (menu['label'] == 'Approval') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ApprovalJadwalScreen(),
                    ),
                  );
                } else if (menu['label'] == 'Users') {
                  setState(() => _currentNavIndex = 1);
                } else if (menu['label'] == 'Jadwal') {
                  setState(() => _currentNavIndex = 2);
                } else if (menu['label'] == 'Rekap') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RekapAdminScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur ini belum tersedia'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      menu['icon'] as IconData,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    menu['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActivityLog() {
    return ValueListenableBuilder<List<Map<String, String>>>(
      valueListenable: _vm.logAktivitas,
      builder: (_, logs, child) {
        if (logs.isEmpty) return const SizedBox.shrink();
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: logs.asMap().entries.map((entry) {
              final log = entry.value;
              final isLast = entry.key == logs.length - 1;
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    dense: true,
                    leading: const Icon(
                      Icons.circle,
                      size: 10,
                      color: AppColors.primaryBlue,
                    ),
                    title: Text(
                      log['aksi'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    trailing: Text(
                      log['waktu'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(double bottomInset) {
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Dashboard'},
      {'icon': Icons.people, 'label': 'Users'},
      {'icon': Icons.calendar_today, 'label': 'Jadwal'},
      {'icon': Icons.account_circle_outlined, 'label': 'Profil'},
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(24, 14, 24, 14 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _currentNavIndex = i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 24,
                    color: _currentNavIndex == i
                        ? AppColors.primaryBlue
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: _currentNavIndex == i
                          ? AppColors.primaryBlue
                          : const Color(0xFF9CA3AF),
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
