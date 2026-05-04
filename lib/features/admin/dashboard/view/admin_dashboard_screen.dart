import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildDashboardContent(bottomInset),
            const ManajemenUserScreen(),
            const ManajemenJadwalScreen(),
            ProfilScreen(user: widget.user, onLogout: widget.onLogout),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(bottomInset),
    );
  }

  Widget _buildDashboardContent(double bottomInset) {
    return Column(
      children: [
        _buildTopHeader(),
        Expanded(
          child: Container(
            color: AppColors.surface,
            child: SingleChildScrollView(
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
      ],
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      decoration: const BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo,\n${widget.user.nama}!',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    fontSize: 28,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.user.roleLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: widget.onLogout,
            splashRadius: 22,
            icon: const Icon(Icons.logout_rounded, color: AppColors.primary, size: 26),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: _vm.statistik,
      builder: (_, stats, child) {
        if (stats.isEmpty) return const SizedBox.shrink();
        return GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
          children: [
            _buildOverviewCard('Total Mahasiswa', '${stats['totalMahasiswa']}', AppColors.accent),
            _buildOverviewCard('Total Dosen', '${stats['totalDosen']}', AppColors.primary),
            _buildOverviewCard('Sesi Hari Ini', '${stats['sesiHariIni']}', AppColors.success),
            _buildOverviewCard('Kehadiran', '${stats['tingkatKehadiran']}%', AppColors.warning),
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
        boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 12, spreadRadius: -6)],
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
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
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
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ApprovalJadwalScreen()));
                } else if (menu['label'] == 'Users') {
                  setState(() => _currentNavIndex = 1);
                } else if (menu['label'] == 'Jadwal') {
                  setState(() => _currentNavIndex = 2);
                } else if (menu['label'] == 'Rekap') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RekapAdminScreen()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur ini belum tersedia'), duration: Duration(seconds: 1)));
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
                      boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 2, offset: Offset(0, 1))],
                    ),
                    child: Icon(menu['icon'] as IconData, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    menu['label'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Plus Jakarta Sans', fontSize: 13, fontWeight: FontWeight.w700),
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
            boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Column(
            children: logs.asMap().entries.map((entry) {
              final log = entry.value;
              final isLast = entry.key == logs.length - 1;
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    dense: true,
                    leading: const Icon(Icons.circle, size: 10, color: AppColors.brand),
                    title: Text(
                      log['aksi'] ?? '',
                      style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    trailing: Text(
                      log['waktu'] ?? '',
                      style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
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
      {'icon': Icons.dashboard, 'label': 'Dashboard'},
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
                    color: _currentNavIndex == i ? AppColors.brand : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: _currentNavIndex == i ? AppColors.brand : const Color(0xFF9CA3AF),
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
