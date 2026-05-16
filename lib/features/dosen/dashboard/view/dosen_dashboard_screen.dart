import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../dashboard/viewmodel/dosen_dashboard_viewmodel.dart';
import '../../sesi/view/sesi_dosen_screen.dart';
import '../../pergantian_jadwal/view/pergantian_jadwal_screen.dart';
import '../../../profil/view/profil_screen.dart';
import '../../rekap/view/rekap_dosen_screen.dart';
import '../../approval/view/approval_screen.dart';
import '../../izin/view/izin_dosen_screen.dart';

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
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _vm.loadData(widget.user);
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    _updateConnectionStatus(result);
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> result) {
    if (!mounted) return;
    setState(() {
      _isOnline =
          result.isNotEmpty && !result.contains(ConnectivityResult.none);
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Keluar Aplikasi?',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700)),
            content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal', style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Keluar',
                  style: TextStyle(color: Colors.white, fontFamily: 'Plus Jakarta Sans')),
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
        body: SafeArea(
          bottom: false,
          child: _buildCurrentScreen(bottomInset),
        ),
        bottomNavigationBar: _buildBottomNav(bottomInset),
      ),
    );
  }

  Widget _buildCurrentScreen(double bottomInset) {
    switch (_currentNavIndex) {
      case 0:
        return _buildDashboardContent(bottomInset);
      case 1:
        return RekapDosenScreen(user: widget.user);
      case 2:
        return const ApprovalScreen();
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
              onRefresh: () => _vm.loadData(widget.user),
              color: AppColors.primaryBlue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, 24, 24, 124 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatistik(),
                    const SizedBox(height: 24),
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? Colors.white.withOpacity(0.24)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isOnline
                        ? AppColors.surface
                        : Colors.red.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      color: _isOnline ? AppColors.surface : Colors.red,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: _isOnline ? AppColors.surface : Colors.red,
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
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

  Widget _buildStatistik() {
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: _vm.mahasiswaHadir,
            builder: (_, hadir, child) => ValueListenableBuilder<int>(
              valueListenable: _vm.totalMahasiswa,
              builder: (_, total, child) => _buildStatCard(
                'Kehadiran',
                '$hadir/$total',
                AppColors.success,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ValueListenableBuilder<int>(
            valueListenable: _vm.izinPending,
            builder: (_, pending, child) =>
                _buildStatCard('Izin Pending', '$pending', AppColors.warning),
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
        final reguler = jadwal.where((j) => j['tipe'] != 'Pengganti').toList();
        final pengganti = jadwal
            .where((j) => j['tipe'] == 'Pengganti')
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Jadwal Mengajar selalu ditampilkan
            _buildSectionTitle('Jadwal Hari Ini'),
            const SizedBox(height: 16),
            if (reguler.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Tidak ada jadwal mengajar hari ini',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              ...reguler.map((j) => _buildJadwalCard(j, isPengganti: false)),

            // Kuliah Pengganti hanya muncul jika ada
            if (pengganti.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('Kuliah Pengganti'),
              const SizedBox(height: 16),
              ...pengganti.map((j) => _buildJadwalCard(j, isPengganti: true)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildJadwalCard(Map<String, String> j, {bool isPengganti = false}) {
    final cardColor = isPengganti ? Colors.blue.shade50 : Colors.white;
    final iconBgColor = isPengganti
        ? Colors.blue.shade100
        : AppColors.primaryBlue.withValues(alpha: 0.2);
    final iconColor = isPengganti ? Colors.blue.shade700 : AppColors.primary;
    final textColor = isPengganti ? Colors.blue.shade800 : AppColors.primary;
    final borderColor = isPengganti ? Colors.blue.shade200 : AppColors.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SesiDosenScreen(user: widget.user, jadwal: j),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
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
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPengganti
                        ? Icons.swap_horiz_rounded
                        : Icons.class_outlined,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        j['mataKuliah'] ?? '-',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${j['jam']} • ${j['ruang']}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
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
                Icon(Icons.chevron_right_rounded, color: textColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuRow() {
    final menus = [
      {'icon': Icons.play_circle_outline, 'label': 'Sesi'},
      {'icon': Icons.fact_check_outlined, 'label': 'Approval'},
      {'icon': Icons.event_busy_outlined, 'label': 'Izin/Sakit'},
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
                } else if (menu['label'] == 'Izin/Sakit') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => IzinDosenScreen(user: widget.user)));
                } else if (menu['label'] == 'Rekap') {
                  setState(() => _currentNavIndex = 1);
                } else if (menu['label'] == 'Approval') {
                  setState(() => _currentNavIndex = 2);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fitur Sesi harus dipilih dari Jadwal'),
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
