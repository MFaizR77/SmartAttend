import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../dashboard/viewmodel/mahasiswa_dashboard_viewmodel.dart';
import '../../presensi/view/presensi_screen.dart';

/// Dashboard utama mahasiswa.
/// Menampilkan jadwal hari ini, statistik kehadiran, dan menu cepat.
class MahasiswaDashboardScreen extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const MahasiswaDashboardScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<MahasiswaDashboardScreen> createState() =>
      _MahasiswaDashboardScreenState();
}

class _MahasiswaDashboardScreenState extends State<MahasiswaDashboardScreen> {
  final _vm = MahasiswaDashboardViewModel();
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _vm.loadData(widget.user);
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
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — salam + nama
            _buildHeader(context),
            const SizedBox(height: 20),

            // Statistik kehadiran
            _buildStatistik(context),
            const SizedBox(height: 20),

            // Jadwal hari ini
            _buildSectionTitle(context, 'Jadwal Hari Ini'),
            const SizedBox(height: 8),
            _buildJadwalList(),
            const SizedBox(height: 20),

            // Menu cepat
            _buildSectionTitle(context, 'Menu Cepat'),
            const SizedBox(height: 8),
            _buildMenuGrid(context),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          if (index == 0) {
            setState(() => _currentNavIndex = index);
          } else {
            _showComingSoon(context);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Jadwal'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline), label: 'Presensi'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.accent,
              child: Text(
                widget.user.nama[0].toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${widget.user.nama}!',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.user.roleLabel,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
            ),
            // Status offline
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 14, color: AppColors.warning),
                  SizedBox(width: 4),
                  Text('Offline',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.warning)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistik(BuildContext context) {
    return ValueListenableBuilder<Map<String, int>>(
      valueListenable: _vm.statistik,
      builder: (context, stats, _) {
        if (stats.isEmpty) return const SizedBox.shrink();
        return Row(
          children: [
            _buildStatCard(
                context, 'Hadir', '${stats['hadir']}', AppColors.success),
            const SizedBox(width: 8),
            _buildStatCard(
                context, 'Izin', '${stats['izin']}', AppColors.warning),
            const SizedBox(width: 8),
            _buildStatCard(
                context, 'Alpha', '${stats['alpha']}', AppColors.error),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildJadwalList() {
    return ValueListenableBuilder<List<Map<String, String>>>(
      valueListenable: _vm.jadwalHariIni,
      builder: (context, jadwal, _) {
        if (jadwal.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Tidak ada jadwal hari ini',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          );
        }
        return Column(
          children: jadwal.map((j) => _buildJadwalCard(j)).toList(),
        );
      },
    );
  }

  Widget _buildJadwalCard(Map<String, String> jadwal) {
    return Card(
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PresensiScreen(
                jadwal: jadwal,
                user: widget.user,
              ),
            ),
          );
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.book, color: AppColors.accent, size: 20),
        ),
        title: Text(jadwal['mataKuliah'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('${jadwal['jam']}  •  ${jadwal['ruang']}',
            style:
                const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        trailing:
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    final menus = [
      {'icon': Icons.check_circle_outline, 'label': 'Presensi'},
      {'icon': Icons.calendar_today, 'label': 'Jadwal'},
      {'icon': Icons.description_outlined, 'label': 'Izin/Sakit'},
      {'icon': Icons.bar_chart, 'label': 'Rekap'},
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: menus.map((menu) {
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showComingSoon(context),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(menu['icon'] as IconData,
                    color: AppColors.accent, size: 28),
                const SizedBox(height: 8),
                Text(menu['label'] as String,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur ini belum tersedia'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
