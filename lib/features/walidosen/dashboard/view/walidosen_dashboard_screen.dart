import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../data/local/models/user.dart';
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
  State<WaliDosenDashboardScreen> createState() => _WaliDosenDashboardScreenState();
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
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tindak Lanjut Izin\n${izin['namaMahasiswa'] ?? izin['mahasiswaId'] ?? ''}',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.success),
              title: const Text('Setujui (approve)'),
              onTap: () => Navigator.pop(ctx, 'approve'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.error),
              title: const Text('Tolak (reject)'),
              onTap: () => Navigator.pop(ctx, 'reject'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    final catatanCtrl = TextEditingController();
    final konfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(action == 'approve' ? 'Setujui izin?' : 'Tolak izin?'),
        content: TextField(
          controller: catatanCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Catatan (opsional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve' ? AppColors.success : AppColors.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action == 'approve' ? 'Setujui' : 'Tolak'),
          ),
        ],
      ),
    );

    if (konfirm != true || !mounted) return;

    final ok = action == 'approve'
        ? await _vm.approveIzin(
            izinId: id,
            walidosenId: widget.user.id,
            catatan: catatanCtrl.text.trim().isEmpty ? null : catatanCtrl.text.trim(),
          )
        : await _vm.rejectIzin(
            izinId: id,
            walidosenId: widget.user.id,
            catatan: catatanCtrl.text.trim().isEmpty ? null : catatanCtrl.text.trim(),
          );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? (action == 'approve' ? 'Izin disetujui.' : 'Izin ditolak.')
            : 'Aksi gagal, coba lagi.'),
      ),
    );
    if (ok) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
              child: Container(
                color: AppColors.surface,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: _buildOverviewCards(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildFilterTabs(),
                    ),
                    const SizedBox(height: 8),
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

                          return ValueListenableBuilder<String?>(
                            valueListenable: _vm.errorMessage,
                            builder: (_, error, __) {
                              if (error != null && error.isNotEmpty) {
                                return _emptyState(error);
                              }
                              return TabBarView(
                                controller: _tabCtrl,
                                children: [
                                  _buildPendingTab(),
                                  _buildRiwayatTab(),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    final kelas = widget.user.kelasWali ?? '-';
    final program = widget.user.program;
    final labelKelas = program == null || program.isEmpty
        ? 'Kelas $kelas'
        : 'Kelas $kelas • $program';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildHeaderBadge(widget.user.roleLabel),
                    _buildHeaderBadge(labelKelas),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ValueListenableBuilder<bool>(
                valueListenable: ConnectivityService().isOnline,
                builder: (_, isOnline, __) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? Colors.white.withValues(alpha: 0.24)
                        : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOnline
                          ? AppColors.surface
                          : Colors.red.withValues(alpha: 0.5),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionIcon(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onTap: _refresh,
              ),
              const SizedBox(width: 8),
              _buildActionIcon(
                icon: Icons.logout_rounded,
                tooltip: 'Logout',
                onTap: widget.onLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.grayDark,
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        Expanded(
          child: ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _vm.izinPending,
            builder: (_, list, __) => _buildStatCard(
              'Pending',
              '${list.length}',
              AppColors.warning,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _vm.izinSemua,
            builder: (_, list, __) => _buildStatCard(
              'Riwayat',
              '${list.length}',
              AppColors.primaryBlue,
            ),
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
                fontSize: 34,
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabCtrl,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        labelColor: AppColors.primaryBlue,
        unselectedLabelColor: AppColors.grayMedium,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(4),
        tabs: const [
          Tab(text: 'Pending'),
          Tab(text: 'Riwayat'),
        ],
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
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
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
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 56,
            color: AppColors.grayLight,
          ),
          const SizedBox(height: 12),
          Text(
            msg,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initials = _initials(name);
    return Container(
      width: 52,
      height: 52,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8003),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              fontSize: 17,
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

  Widget _buildIzinCard(Map<String, dynamic> izin, {required bool canAct}) {
    final status = izin['status']?.toString() ?? 'pending_wali';
    final jenis = izin['jenis']?.toString() ?? 'izin';
    final mahasiswaId = izin['mahasiswaId']?.toString() ?? '-';
    final namaMhs = izin['namaMahasiswa']?.toString() ?? mahasiswaId;
    final keterangan = izin['keterangan']?.toString() ?? '-';
    final tgl = izin['tanggalIzin'];
    String tglStr = '-';
    DateTime? parsed;
    if (tgl is DateTime) {
      parsed = tgl;
    } else if (tgl is String) {
      parsed = DateTime.tryParse(tgl);
    }
    if (parsed != null) {
      // Tanggal disimpan UTC midnight (date-only) — format pakai UTC supaya
      // tidak ter-shift -1 hari di timezone WIB.
      tglStr = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(parsed.toUtc());
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
        statusColor = Colors.blue;
        statusLabel = 'APPROVED — menunggu dosen';
        break;
      case 'rejected_wali':
        statusColor = Colors.red;
        statusLabel = 'DITOLAK';
        break;
      case 'closed':
        statusColor = Colors.green;
        statusLabel = 'SELESAI';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status.toUpperCase();
    }

    return Card(
      child: InkWell(
        onTap: canAct ? () => _showActionSheet(izin) : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: jenis == 'sakit'
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      jenis.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: jenis == 'sakit' ? AppColors.error : AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                namaMhs,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              Text(
                'NIM: $mahasiswaId',
                style: const TextStyle(fontSize: 12, color: AppColors.grayMedium),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.event, size: 16, color: AppColors.grayMedium),
                const SizedBox(width: 6),
                Expanded(child: Text(tglStr, style: const TextStyle(fontSize: 13))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                Icon(
                  (izin['cakupan']?.toString() == 'sebagian')
                      ? Icons.splitscreen_rounded
                      : Icons.calendar_view_day,
                  size: 16,
                  color: AppColors.grayMedium,
                ),
                const SizedBox(width: 6),
                Text(
                  izin['cakupan']?.toString() == 'sebagian'
                      ? '${jadwalIds.length} mata kuliah (izin sebagian)'
                      : '${jadwalIds.length} jadwal terdampak',
                  style: const TextStyle(fontSize: 13),
                ),
              ]),
              const SizedBox(height: 8),
              Text(
                keterangan,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              _buildFotoBuktiThumbnail(izin),
              if (canAct) ...[
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Tap untuk approve/reject →',
                    style: TextStyle(fontSize: 12, color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Thumbnail foto bukti yang tap-able. Return empty kalau tidak ada foto.
  Widget _buildFotoBuktiThumbnail(Map<String, dynamic> izin) {
    final raw = izin['fotoBase64']?.toString();
    if (raw == null || raw.isEmpty) return const SizedBox.shrink();
    Uint8List bytes;
    try {
      bytes = base64Decode(raw);
    } catch (_) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        onTap: () => _showFotoFullscreen(bytes),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.memory(
                bytes,
                width: double.infinity,
                height: 140,
                fit: BoxFit.cover,
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.image, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Foto Bukti — Tap untuk perbesar',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFotoFullscreen(Uint8List bytes) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
