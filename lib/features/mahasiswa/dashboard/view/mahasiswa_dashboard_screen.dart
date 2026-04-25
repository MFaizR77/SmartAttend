import 'package:flutter/material.dart';
import '../../../../data/local/models/user.dart';
import '../../dashboard/viewmodel/mahasiswa_dashboard_viewmodel.dart';
import '../../presensi/view/presensi_screen.dart';

/// Dashboard utama mahasiswa.
/// Menampilkan statistik, jadwal hari ini, dan menu cepat.
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

  static const Color _ink = Color(0xFF1A1A1A);
  static const Color _softText = Color(0xFF6B7280);
  static const Color _surface = Color(0xFFF8F8F8);
  static const Color _stroke = Color(0xFFF3F4F6);
  static const Color _brand = Color(0xFFD0FF00);

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
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopHeader(),
                Expanded(
                  child: Container(
                    color: _surface,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        78,
                        24,
                        124 + bottomInset,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Jadwal Hari Ini'),
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
            ),
            Positioned(
              top: 180,
              left: 24,
              right: 24,
              child: _buildStatistik(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(bottomInset),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 84),
      decoration: const BoxDecoration(
        color: _brand,
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
                    color: _ink,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    fontSize: 40,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: _ink,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: widget.onLogout,
                splashRadius: 22,
                icon: const Icon(Icons.logout_rounded, color: _ink, size: 26),
                tooltip: 'Logout',
              ),
              const SizedBox(height: 34),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _ink, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: _ink, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Offline',
                      style: TextStyle(
                        color: _ink,
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatistik() {
    return ValueListenableBuilder<Map<String, int>>(
      valueListenable: _vm.statistik,
      builder: (context, stats, _) {
        if (stats.isEmpty) {
          return const SizedBox(height: 112);
        }

        return Row(
          children: [
            _buildStatCard('Hadir', '${stats['hadir'] ?? 0}'),
            const SizedBox(width: 12),
            _buildStatCard('Izin', '${stats['izin'] ?? 0}'),
            const SizedBox(width: 12),
            _buildStatCard('Alpha', '${stats['alpha'] ?? 0}'),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _ink, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x19000000),
              blurRadius: 12,
              offset: Offset(0, 6),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: _ink,
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 50,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _ink,
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
    );
  }

  Widget _buildJadwalList() {
    return ValueListenableBuilder<List<Map<String, String>>>(
      valueListenable: _vm.jadwalHariIni,
      builder: (context, jadwal, _) {
        if (jadwal.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _stroke),
            ),
            child: const Text(
              'Tidak ada jadwal hari ini',
              style: TextStyle(
                color: _softText,
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        return Column(
          children: [
            for (var i = 0; i < jadwal.length; i++) ...[
              _buildJadwalCard(jadwal[i]),
              if (i != jadwal.length - 1) const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildJadwalCard(Map<String, String> jadwal) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _stroke),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x33D0FF00),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.computer_outlined, color: _ink, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jadwal['mataKuliah'] ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${jadwal['jam'] ?? '-'} • ${jadwal['ruang'] ?? '-'}',
                      style: const TextStyle(
                        color: _softText,
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _ink, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuRow() {
    final menus = [
      {'icon': Icons.person_outline_rounded, 'label': 'Presensi'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Jadwal'},
      {'icon': Icons.shield_outlined, 'label': 'Izin/Sakit'},
      {'icon': Icons.bar_chart, 'label': 'Rekap'},
    ];

    return Row(
      children: [
        for (final menu in menus)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: menu == menus.last ? 0 : 10),
              child: GestureDetector(
                onTap: () => _showComingSoon(context),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _stroke),
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
                        color: _ink,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      menu['label'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF4B5563),
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNav(double bottomInset) {
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Dashboard'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Jadwal'},
      {'icon': Icons.person_outline_rounded, 'label': 'Presensi'},
      {'icon': Icons.account_circle_outlined, 'label': 'Profil'},
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(24, 14, 24, 14 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _stroke)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (i == 0) {
                    setState(() => _currentNavIndex = i);
                    return;
                  }
                  setState(() => _currentNavIndex = i);
                  _showComingSoon(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i]['icon'] as IconData,
                      size: 24,
                      color:
                          _currentNavIndex == i ? _brand : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i]['label'] as String,
                      style: TextStyle(
                        color: _currentNavIndex == i
                            ? _brand
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
            ),
        ],
      ),
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
