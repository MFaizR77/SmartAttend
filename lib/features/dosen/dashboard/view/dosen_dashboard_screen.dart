import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../dashboard/viewmodel/dosen_dashboard_viewmodel.dart';
import '../../sesi/view/sesi_dosen_screen.dart';
import '../../pergantian_jadwal/view/pergantian_jadwal_screen.dart';
import '../../../profil/view/profil_screen.dart';
import '../../rekap/view/rekap_dosen_screen.dart'; // We will create this
import '../../approval/view/approval_screen.dart';

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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildDashboardContent(bottomInset),
            _currentNavIndex == 1 ? RekapDosenScreen(user: widget.user) : const SizedBox(),
            _currentNavIndex == 2 ? const ApprovalScreen() : const SizedBox(),
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
                  _buildStatistik(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Jadwal Mengajar'),
                  const SizedBox(height: 16),
                  _buildJadwalList(),
                  const SizedBox(height: 34),
                  _buildSectionTitle('Menu Cepat'),
                  const SizedBox(height: 16),
                  _buildMenuRow(),
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

  Widget _buildStatistik() {
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: _vm.mahasiswaHadir,
            builder: (_, hadir, child) => ValueListenableBuilder<int>(
              valueListenable: _vm.totalMahasiswa,
              builder: (_, total, child) => _buildStatCard('Kehadiran', '$hadir/$total', AppColors.success),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: _vm.izinPending,
            builder: (_, pending, child) => _buildStatCard('Izin Pending', '$pending', AppColors.warning),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x19000000), blurRadius: 12, spreadRadius: -6),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 40,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
    );
  }

  Widget _buildJadwalList() {
    return ValueListenableBuilder<List<Map<String, String>>>(
      valueListenable: _vm.jadwalMengajar,
      builder: (_, jadwal, child) {
        if (jadwal.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'Tidak ada jadwal mengajar',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }
        return Column(
          children: jadwal.map((j) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SesiDosenScreen(user: widget.user, jadwal: j),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 2, offset: Offset(0, 1))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.class_outlined, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              j['mataKuliah'] ?? '-',
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.primary, fontFamily: 'Plus Jakarta Sans', fontSize: 15, fontWeight: FontWeight.w700, height: 1.4),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${j['jam']} • ${j['ruang']}',
                              style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Plus Jakarta Sans', fontSize: 13, fontWeight: FontWeight.w500, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildMenuRow() {
    final menus = [
      {'icon': Icons.play_circle_outline, 'label': 'Sesi'},
      {'icon': Icons.fact_check_outlined, 'label': 'Approval'},
      {'icon': Icons.edit_calendar, 'label': 'Ganti Jadwal'},
      {'icon': Icons.bar_chart, 'label': 'Rekap'},
    ];

    return Row(
      children: menus.map((menu) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: menu == menus.last ? 0 : 10),
            child: GestureDetector(
              onTap: () {
                if (menu['label'] == 'Ganti Jadwal') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PergantianJadwalScreen(user: widget.user)));
                } else if (menu['label'] == 'Rekap') {
                  setState(() => _currentNavIndex = 1);
                } else if (menu['label'] == 'Approval') {
                  setState(() => _currentNavIndex = 2);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Sesi harus dipilih dari Jadwal'), duration: Duration(seconds: 1)));
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

  Widget _buildBottomNav(double bottomInset) {
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Dashboard'},
      {'icon': Icons.bar_chart, 'label': 'Rekap'},
      {'icon': Icons.fact_check_outlined, 'label': 'Approval'},
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
