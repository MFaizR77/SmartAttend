import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../tindak_lanjut_izin/viewmodel/tindak_lanjut_viewmodel.dart';

/// Tab Approval di dashboard dosen.
///
/// Menampilkan izin mahasiswa yang sudah approved wali dosen, terbatas ke
/// jadwal-jadwal yang dosen ini ampu. Dosen bisa tandai status final per
/// jadwal: izin / sakit / alpha.
class ApprovalScreen extends StatefulWidget {
  final User user;

  const ApprovalScreen({super.key, required this.user});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  late final TindakLanjutIzinViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = TindakLanjutIzinViewModel();
    _vm.load(widget.user);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _vm.load(widget.user);

  Future<void> _tandai(
    Map<String, dynamic> izin,
    Map<String, dynamic> tindak,
  ) async {
    final catatanCtrl = TextEditingController();
    final statusFinal = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih status final'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.event_note, color: Colors.blue),
              title: const Text('Izin'),
              onTap: () => Navigator.pop(ctx, 'izin'),
            ),
            ListTile(
              leading: const Icon(Icons.healing, color: Colors.red),
              title: const Text('Sakit'),
              onTap: () => Navigator.pop(ctx, 'sakit'),
            ),
            ListTile(
              leading: const Icon(Icons.warning, color: Colors.orange),
              title: const Text('Alpha (tidak diterima)'),
              onTap: () => Navigator.pop(ctx, 'alpha'),
            ),
          ],
        ),
      ),
    );
    if (statusFinal == null || !mounted) return;

    final konfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tandai sebagai: ${statusFinal.toUpperCase()}?'),
        content: TextField(
          controller: catatanCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            hintText: 'Catatan (opsional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (konfirm != true || !mounted) return;

    final ok = await _vm.tandai(
      izinId: izin['_id'],
      jadwalId: tindak['jadwalId']?.toString() ?? '',
      dosenKode: widget.user.id,
      statusFinal: statusFinal,
      catatan: catatanCtrl.text.trim().isEmpty
          ? null
          : catatanCtrl.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Status disimpan.' : 'Gagal menyimpan.')),
    );
    if (ok) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _vm.isLoading,
            builder: (_, loading, __) {
              if (loading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryBlue),
                );
              }
              return ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _vm.izinList,
                builder: (_, list, __) {
                  if (list.isEmpty) return _buildEmpty();
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.primaryBlue,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (_, i) => _buildIzinCard(list[i]),
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemCount: list.length,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.29, -0.41),
          end: Alignment(0.71, 1.41),
          colors: [
            Color(0xFF1A237E),
            Color(0xFF1E3A8A),
            Color(0xFF1565C0),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: const Text(
        'Approval\nIzin & Sakit',
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w800,
          height: 1.1,
          fontSize: 28,
          letterSpacing: -0.6,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      // ListView agar tetap bisa pull-to-refresh saat empty
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.fact_check, size: 80, color: AppColors.border),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada pengajuan dari mahasiswa',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIzinCard(Map<String, dynamic> izin) {
    final namaMhs = izin['namaMahasiswa']?.toString() ??
        izin['mahasiswaId']?.toString() ??
        '-';
    final mahasiswaId = izin['mahasiswaId']?.toString() ?? '-';
    final jenis = izin['jenis']?.toString() ?? 'izin';
    final tgl = izin['tanggalIzin'];
    String tglStr = '-';
    if (tgl is DateTime) {
      tglStr = DateFormat('d MMM yyyy', 'id_ID').format(tgl);
    } else if (tgl is String) {
      final p = DateTime.tryParse(tgl);
      if (p != null) tglStr = DateFormat('d MMM yyyy', 'id_ID').format(p);
    }
    final tindakList = (izin['tindakLanjutDosen'] as List?) ?? const [];

    // Hanya tampilkan jadwal yang dosen ini yang ampu.
    final myTindak = tindakList
        .map((t) => Map<String, dynamic>.from(t as Map))
        .where((t) => (t['dosenId']?.toString() ?? '') == widget.user.id)
        .toList();

    if (myTindak.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: jenis == 'sakit' ? Colors.red[50] : Colors.blue[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    jenis.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: jenis == 'sakit'
                          ? Colors.red[700]
                          : Colors.blue[700],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  tglStr,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              namaMhs,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'NIM: $mahasiswaId',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.grayMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              izin['keterangan']?.toString() ?? '-',
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 24),
            const Text(
              'Jadwal yang Anda ampu:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...myTindak.map((t) => _tindakTile(izin, t)),
          ],
        ),
      ),
    );
  }

  Widget _tindakTile(Map<String, dynamic> izin, Map<String, dynamic> tindak) {
    final statusFinal = tindak['statusFinal']?.toString() ?? 'pending';
    Color color;
    String label;
    switch (statusFinal) {
      case 'izin':
        color = Colors.blue;
        label = 'IZIN';
        break;
      case 'sakit':
        color = Colors.red;
        label = 'SAKIT';
        break;
      case 'alpha':
        color = Colors.orange;
        label = 'ALPHA';
        break;
      default:
        color = Colors.grey;
        label = 'BELUM';
    }
    final clickable = statusFinal == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tindak['namaMK']?.toString() ??
                      tindak['jadwalId']?.toString() ??
                      '-',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${tindak['jamMulai'] ?? ''} - ${tindak['jamSelesai'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.grayMedium,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: clickable ? () => _tandai(izin, tindak) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (clickable) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.edit, size: 12, color: color),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
