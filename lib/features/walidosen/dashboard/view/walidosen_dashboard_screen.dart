import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../../auth/view/widgets/logout_confirm_dialog.dart';
import '../viewmodel/walidosen_dashboard_viewmodel.dart';

/// Dashboard untuk akun Wali Dosen.
/// Tampilkan pending izin mahasiswa di kelas walinya, approve/reject.
class WaliDosenDashboardScreen extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const WaliDosenDashboardScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<WaliDosenDashboardScreen> createState() =>
      _WaliDosenDashboardScreenState();
}

class _WaliDosenDashboardScreenState extends State<WaliDosenDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final WaliDosenDashboardViewModel _vm;
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _vm = WaliDosenDashboardViewModel();
    _tabCtrl = TabController(length: 2, vsync: this);
    _vm.loadData(widget.user);
  }

  @override
  void dispose() {
    _vm.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _vm.loadData(widget.user);

  Future<void> _showActionSheet(Map<String, dynamic> izin) async {
    final id = izin['_id'];
    final namaMhs = izin['namaMahasiswa'] ?? izin['mahasiswaId'] ?? '';
    final catatanCtrl = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Dialog
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              color: AppColors.primaryBlue.withOpacity(0.05),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fact_check_rounded,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tinjau Izin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Plus Jakarta Sans',
                            color: AppColors.grayDark,
                          ),
                        ),
                        Text(
                          namaMhs,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Plus Jakarta Sans',
                            color: AppColors.grayMedium,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Berikan catatan (opsional):',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Plus Jakarta Sans',
                      color: AppColors.grayDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: catatanCtrl,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tulis alasan atau catatan tambahan...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: AppColors.grayMedium.withOpacity(0.6),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.black.withOpacity(0.06),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, {
                            'action': 'reject',
                            'catatan': catatanCtrl.text,
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFFCDD2),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Tolak',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(ctx, {
                            'action': 'approve',
                            'catatan': catatanCtrl.text,
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFC8E6C9),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Setujui',
                                style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Kembali',
                        style: TextStyle(
                          color: AppColors.grayMedium,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    final action = result['action']!;
    final note = result['catatan']?.trim();
    final catatan = note != null && note.isNotEmpty ? note : null;

    final ok = action == 'approve'
        ? await _vm.approveIzin(
            izinId: id,
            walidosenId: widget.user.id,
            catatan: catatan,
          )
        : await _vm.rejectIzin(
            izinId: id,
            walidosenId: widget.user.id,
            catatan: catatan,
          );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (action == 'approve' ? 'Izin disetujui.' : 'Izin ditolak.')
              : 'Aksi gagal, coba lagi.',
        ),
      ),
    );
    if (ok) await _refresh();
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.29, -0.41),
          end: Alignment(0.71, 1.41),
          colors: [Color(0xFF1A237E), Color(0xFF1E3A8A), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) =>
                            LogoutConfirmDialog(onConfirm: widget.onLogout),
                      );
                    },
                    child: Container(
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.supervisor_account_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KELAS WALI DOSEN',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kelas ${widget.user.kelasWali ?? "-"} • ${widget.user.program ?? "-"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabCtrl,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: const Color(0xFF6B7280),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          fontFamily: 'Plus Jakarta Sans',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Plus Jakarta Sans',
        ),
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Riwayat'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    side: const BorderSide(
                      color: AppColors.primaryBlue,
                      width: 1.5,
                    ),
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
        backgroundColor: AppColors.dashboardSurface,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBarSection(),
              Expanded(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _vm.isLoading,
                  builder: (_, loading, __) {
                    if (loading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryBlue,
                        ),
                      );
                    }
                    return TabBarView(
                      controller: _tabCtrl,
                      children: [_buildPendingTab(), _buildRiwayatTab()],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingTab() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: _vm.izinPending,
      builder: (_, list, __) {
        if (list.isEmpty) {
          return _emptyState('Tidak ada izin pending.');
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryBlue,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemBuilder: (_, i) => _buildIzinCard(list[i], canAct: true),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: list.length,
          ),
        );
      },
    );
  }

  Widget _buildRiwayatTab() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: _vm.izinSemua,
      builder: (_, list, __) {
        if (list.isEmpty) {
          return _emptyState('Belum ada riwayat izin.');
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.primaryBlue,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemBuilder: (_, i) => _buildIzinCard(list[i], canAct: false),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: list.length,
          ),
        );
      },
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 48,
                color: AppColors.primaryBlue.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              msg,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.grayDark,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tarik layar ke bawah untuk memuat ulang.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIzinCard(Map<String, dynamic> izin, {required bool canAct}) {
    final status = izin['status']?.toString() ?? 'pending_wali';
    final jenis = izin['jenis']?.toString() ?? 'izin';
    final mahasiswaId = izin['mahasiswaId']?.toString() ?? '-';
    final namaMhs = izin['namaMahasiswa']?.toString() ?? mahasiswaId;
    final keterangan = izin['keterangan']?.toString() ?? '-';
    final tgl = izin['tanggalIzin'];
    String tglStr = '-';
    if (tgl is DateTime) {
      tglStr = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(tgl);
    } else if (tgl is String) {
      final parsed = DateTime.tryParse(tgl);
      if (parsed != null)
        tglStr = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(parsed);
    }
    final jadwalIds = (izin['jadwalIdsTerdampak'] as List?) ?? [];

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'pending_wali':
        statusColor = Colors.orange;
        statusLabel = 'PENDING WALI';
        break;
      case 'approved_wali':
        statusColor = AppColors.primaryBlue;
        statusLabel = 'APPROVED';
        break;
      case 'rejected_wali':
        statusColor = Colors.red;
        statusLabel = 'DITOLAK';
        break;
      case 'closed':
        statusColor = const Color(0xFF2E7D32);
        statusLabel = 'SELESAI';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status.toUpperCase();
    }

    final isSakit = jenis.toLowerCase() == 'sakit';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canAct ? () => _showActionSheet(izin) : null,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSakit
                            ? const Color(0xFFFFEBEE)
                            : const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSakit
                              ? const Color(0xFFFFCDD2)
                              : const Color(0xFFBBDEFB),
                        ),
                      ),
                      child: Text(
                        jenis.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isSakit ? Colors.red[800] : Colors.blue[800],
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.2)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          namaMhs.isNotEmpty ? namaMhs[0].toUpperCase() : 'M',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            namaMhs,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.grayDark,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'NIM: $mahasiswaId',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grayMedium,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.event_note_rounded,
                      size: 15,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tglStr,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.class_rounded,
                      size: 15,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${jadwalIds.length} jadwal',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF3F4F6)),
                  ),
                  child: Text(
                    keterangan,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canAct) ...[
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Tinjau Permohonan',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
