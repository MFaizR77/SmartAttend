import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../dashboard/viewmodel/admin_dashboard_viewmodel.dart';
import '../../approval_jadwal/view/approval_jadwal_screen.dart';

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
  int _navIndex = 0;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(context),
            const SizedBox(height: 20),
            _overviewCards(context),
            const SizedBox(height: 16),
            _alertBanner(context),
            const SizedBox(height: 20),
            Text('Menu Cepat', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _menuGrid(context),
            const SizedBox(height: 20),
            Text('Aktivitas Terbaru', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _activityLog(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 0) {
            setState(() => _navIndex = i);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur ini belum tersedia'), duration: Duration(seconds: 1)),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _headerCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.error,
              child: Text(widget.user.nama[0], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Halo, ${widget.user.nama}!', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(widget.user.roleLabel, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overviewCards(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: _vm.statistik,
      builder: (_, stats, child) {
        if (stats.isEmpty) return const SizedBox.shrink();
        return GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.6,
          children: [
            _overviewCard(context, 'Total Mahasiswa', '${stats['totalMahasiswa']}', Icons.school, AppColors.accent),
            _overviewCard(context, 'Total Dosen', '${stats['totalDosen']}', Icons.person, AppColors.primary),
            _overviewCard(context, 'Sesi Hari Ini', '${stats['sesiHariIni']}', Icons.event, AppColors.success),
            _overviewCard(context, 'Kehadiran', '${stats['tingkatKehadiran']}%', Icons.trending_up, AppColors.warning),
          ],
        );
      },
    );
  }

  Widget _overviewCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _alertBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '1 mahasiswa mendekati batas alpha (Rina Amelia — 4/5 alpha)',
              style: TextStyle(fontSize: 13, color: AppColors.warning.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuGrid(BuildContext context) {
    final menus = [
      {'icon': Icons.people, 'label': 'Manajemen User'},
      {'icon': Icons.domain_verification, 'label': 'Approval Ruangan'},
      {'icon': Icons.calendar_month, 'label': 'Manajemen Jadwal'},
      {'icon': Icons.bar_chart, 'label': 'Rekap'},
      {'icon': Icons.download, 'label': 'Export'},
    ];
    return GridView.count(
      crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85,
      children: menus.map((m) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (m['label'] == 'Approval Ruangan') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ApprovalJadwalScreen()));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur ini belum tersedia'), duration: Duration(seconds: 1)));
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(m['icon'] as IconData, color: AppColors.primary, size: 24),
              const SizedBox(height: 6),
              Text(m['label'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _activityLog() {
    return ValueListenableBuilder<List<Map<String, String>>>(
      valueListenable: _vm.logAktivitas,
      builder: (_, logs, child) {
        if (logs.isEmpty) return const SizedBox.shrink();
        return Card(
          child: Column(
            children: logs.asMap().entries.map((entry) {
              final log = entry.value;
              final isLast = entry.key == logs.length - 1;
              return Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.circle, size: 8, color: AppColors.accent),
                    title: Text(log['aksi'] ?? '', style: const TextStyle(fontSize: 13)),
                    trailing: Text(log['waktu'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
}
