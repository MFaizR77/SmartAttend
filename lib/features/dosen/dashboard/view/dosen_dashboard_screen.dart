import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../dashboard/viewmodel/dosen_dashboard_viewmodel.dart';
import '../../sesi/view/sesi_dosen_screen.dart';
import '../../pergantian_jadwal/view/pergantian_jadwal_screen.dart';

class DosenDashboardScreen extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const DosenDashboardScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<DosenDashboardScreen> createState() => _DosenDashboardScreenState();
}

class _DosenDashboardScreenState extends State<DosenDashboardScreen> {
  final _vm = DosenDashboardViewModel();
  int _navIndex = 0;

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
        title: const Text('Dashboard Dosen'),
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
            _statsRow(context),
            const SizedBox(height: 20),
            Text('Jadwal Mengajar Hari Ini',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _jadwalList(),
            const SizedBox(height: 20),
            Text('Menu Cepat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _menuGrid(context),
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
                const SnackBar(content: Text('Fitur ini belum tersedia'), duration: Duration(seconds: 1)));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: 'Sesi'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), label: 'Approval'),
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
              backgroundColor: AppColors.primary,
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
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(widget.user.roleLabel, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: _vm.mahasiswaHadir,
            builder: (_, hadir, child) => ValueListenableBuilder<int>(
              valueListenable: _vm.totalMahasiswa,
              builder: (_, total, child) => _statCard(context, 'Kehadiran', '$hadir/$total', AppColors.success, Icons.people),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: _vm.izinPending,
            builder: (_, pending, child) => _statCard(context, 'Izin Pending', '$pending', AppColors.warning, Icons.pending_actions),
          ),
        ),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _jadwalList() {
    return ValueListenableBuilder<List<Map<String, String>>>(
      valueListenable: _vm.jadwalMengajar,
      builder: (_, jadwal, child) {
        if (jadwal.isEmpty) {
          return const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Tidak ada jadwal', style: TextStyle(color: AppColors.textSecondary)))));
        }
        return Column(
          children: jadwal.map((j) => Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SesiDosenScreen(
                      user: widget.user,
                      jadwal: j,
                    ),
                  ),
                );
              },
              child: ListTile(
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.class_, color: AppColors.primary, size: 20),
                ),
                title: Text(j['mataKuliah'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('${j["jam"]}  •  ${j["ruang"]}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _menuGrid(BuildContext context) {
    final menus = [
      {'icon': Icons.play_circle_outline, 'label': 'Buka Sesi'},
      {'icon': Icons.fact_check_outlined, 'label': 'Approval Izin'},
      {'icon': Icons.edit_calendar, 'label': 'Ganti Jadwal'},
      {'icon': Icons.bar_chart, 'label': 'Rekap'},
    ];
    return GridView.count(
      crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.1,
      children: menus.map((m) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (m['label'] == 'Ganti Jadwal') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => PergantianJadwalScreen(user: widget.user)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur ini belum tersedia'), duration: Duration(seconds: 1)));
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(m['icon'] as IconData, color: AppColors.primary, size: 28),
              const SizedBox(height: 8),
              Text(m['label'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            ],
          ),
        ),
      )).toList(),
    );
  }
}
