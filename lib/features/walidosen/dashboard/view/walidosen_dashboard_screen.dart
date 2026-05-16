import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Setujui (approve)'),
              onTap: () => Navigator.pop(ctx, 'approve'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
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
              backgroundColor: action == 'approve' ? Colors.green : Colors.red,
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
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppBar(
        title: Text('Wali Dosen — ${widget.user.kelasWali ?? "-"}${widget.user.program != null ? "-${widget.user.program}" : ""}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.grayMedium,
          indicatorColor: AppColors.primaryBlue,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _vm.isLoading,
        builder: (_, loading, __) {
          if (loading) return const Center(child: CircularProgressIndicator());
          return TabBarView(
            controller: _tabCtrl,
            children: [
              _buildPendingTab(),
              _buildRiwayatTab(),
            ],
          );
        },
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
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: Colors.grey[600])),
        ],
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
      if (parsed != null) tglStr = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(parsed);
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
                      color: jenis == 'sakit' ? Colors.red[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      jenis.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: jenis == 'sakit' ? Colors.red[700] : Colors.blue[700],
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
                const Icon(Icons.calendar_view_day, size: 16, color: AppColors.grayMedium),
                const SizedBox(width: 6),
                Text('${jadwalIds.length} jadwal terdampak',
                    style: const TextStyle(fontSize: 13)),
              ]),
              const SizedBox(height: 8),
              Text(
                keterangan,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
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
}
