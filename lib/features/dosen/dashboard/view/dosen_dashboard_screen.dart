import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../dashboard/viewmodel/dosen_dashboard_viewmodel.dart';
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
  int _selectedDayIndex = DateTime.now().weekday - 1; // 0=Sen, 1=Sel, dst

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const _dayNames  = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  static const _dayKeys   = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

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
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildDashboardContent(bottomInset),
            _buildJadwalContent(bottomInset),
            const ApprovalScreen(),
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
            color: const Color(0xFFF6F6F6),
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

  Widget _buildJadwalContent(double bottomInset) {
    return Column(
      children: [
        _buildJadwalHeader(),
        Expanded(
          child: Container(
            color: const Color(0xFFF6F6F6),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 124 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDaySelectorMock(),
                  const SizedBox(height: 16),
                  _buildDayLabelMock(),
                  const SizedBox(height: 12),
                  _buildJadwalList(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopHeader() {
    return _buildTopHeaderWithTitle('Halo,\n${widget.user.nama}!');
  }

  Widget _buildJadwalHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF01018B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Jadwal',
            style: TextStyle(
              color: Color(0xFFF6F6F6),
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 30,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Color(0xFF4CAF50)),
                SizedBox(width: 6),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Color(0xFFF6F6F6),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelectorMock() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE4E8F0))),
      ),
      child: Row(
        children: List.generate(_dayLabels.length, (index) {
          final bool active = _selectedDayIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedDayIndex = index;
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF01018B) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _dayLabels[index],
                    style: TextStyle(
                      color: active ? Colors.white : const Color(0xFF9CA3AF),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayLabelMock() {
    final isToday = _selectedDayIndex == DateTime.now().weekday - 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Text(
            _dayNames[_selectedDayIndex],
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          if (isToday) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF0FB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Hari Ini',
                style: TextStyle(
                  color: Color(0xFF01018B),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopHeaderWithTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 48),
      decoration: const BoxDecoration(
        color: Color(0xFF01018B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x3F000000),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF6F6F6),
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    fontSize: 28,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFF6F6F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    widget.user.roleLabel,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
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
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xFFF6F6F6),
              size: 26,
            ),
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
                _buildStatCard('Izin Pending', '$pending', Color(0xFFFF8003)),
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
        color: Color(0xFF1A1A1A),
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
        // ── DUMMY DATA (hapus kalau backend sudah siap) ──
        final dummyJadwal = <Map<String, String>>[
          {
            'mataKuliah': 'Pemrograman Mobile',
            'jam': '08:00 - 10.00',
            'ruang': 'D105-Kelas · TI-3A',
            'hari': 'Selasa',
            'badge': 'Berlangsung',
            'state': 'active',
          },
          {
            'mataKuliah': 'Basis Data Lanjut',
            'jam': '13.00 - 15.00',
            'ruang': 'D106-Lab · TI-3B',
            'hari': 'Selasa',
            'badge': '13.00',
            'state': 'default',
          },
          {
            'mataKuliah': 'Rekayasa PL',
            'jam': '11:30 - 13:10',
            'ruang': 'Ruang 301',
            'hari': 'Rabu',
            'badge': '10.30',
            'state': 'blocked',
          },
          {
            'mataKuliah': 'Statistika & Prob',
            'jam': '13:00 - 14:40',
            'ruang': 'Ruang 105',
            'hari': 'Jumat',
            'badge': '13.00',
            'state': 'default',
          },
        ];
        // pakai dummy kalau DB kosong
        final sourceData = jadwal.isEmpty ? dummyJadwal : jadwal;

        final selectedHari = _dayKeys[_selectedDayIndex];
        final filtered = sourceData.where((j) {
          final hari = j['hari'] ?? '';
          if (hari.isEmpty) return true;
          return hari.toLowerCase() == selectedHari.toLowerCase();
        }).toList();

        if (filtered.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
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
          children: List.generate(filtered.length, (index) {
            final j = filtered[index];
            final state = (j['state'] ?? '').toLowerCase();
            final bool isActive = state == 'active';
            final bool isBlocked = state == 'blocked';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildJadwalDummyCard(
                jadwal: j,
                isActive: isActive,
                isBlocked: isBlocked,
                fallbackBadge: j['badge'] ?? _extractJamAwal(j['jam']),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildJadwalDummyCard({
    required Map<String, String> jadwal,
    required bool isActive,
    required bool isBlocked,
    required String fallbackBadge,
  }) {
    final badgeText = jadwal['badge'] ?? fallbackBadge;
    final sessionTitle = jadwal['mataKuliah'] ?? '-';
    final jam = jadwal['jam'] ?? '-';
    final ruang = jadwal['ruang'] ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6EAF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.class_outlined,
                  color: Color(0xFF1D237E),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            sessionTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0F1B4D),
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildMiniBadge(
                          text: badgeText,
                          active: isActive,
                          blocked: isBlocked,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildScheduleMetaRow(
                      Icons.schedule_rounded,
                      jam,
                    ),
                    const SizedBox(height: 4),
                    _buildScheduleMetaRow(
                      Icons.location_on_outlined,
                      ruang,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F3E2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 10, color: Color(0xFF9CCC9A)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sesi absen aktif · 08 menit tersisa',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Sesi Aktif'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F2F7),
                  disabledBackgroundColor: const Color(0xFFF0F2F7),
                  disabledForegroundColor: const Color(0xFF9AA3B2),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFE8EBF2)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dummy: Buka Sesi ditekan'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.schedule_rounded, size: 18),
                      label: const Text('Buka Sesi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D237E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Dummy: Berhalangan ditekan'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.error_outline_rounded, size: 18),
                      label: const Text('Berhalangan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE53935),
                        side: const BorderSide(color: Color(0xFFFFC9C9)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniBadge({
    required String text,
    required bool active,
    required bool blocked,
  }) {
    Color backgroundColor;
    Color textColor;

    if (active) {
      backgroundColor = const Color(0xFFE5F4E5);
      textColor = const Color(0xFF2E7D32);
    } else if (blocked) {
      backgroundColor = const Color(0xFFFFF1F1);
      textColor = const Color(0xFFE53935);
    } else {
      backgroundColor = const Color(0xFFF0F2FF);
      textColor = const Color(0xFF3D4DB7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildScheduleMetaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF90A0C0)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF6D7A99),
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  String _extractJamAwal(String? jam) {
    if (jam == null || jam.trim().isEmpty) return '13.00';
    final parts = jam.split('-');
    return parts.isNotEmpty ? parts.first.trim() : jam.trim();
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PergantianJadwalScreen(user: widget.user),
                    ),
                  );
                } else if (menu['label'] == 'Rekap') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RekapDosenScreen(user: widget.user),
                    ),
                  );
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
                      color: Color(0xFF01018B),
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
      {'icon': Icons.calendar_month_outlined, 'label': 'Jadwal'},
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
                        ? const Color(0xFF01018B)
                        : const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: _currentNavIndex == i
                          ? const Color(0xFF01018B)
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
