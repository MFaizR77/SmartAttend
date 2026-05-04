import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../viewmodel/approval_jadwal_viewmodel.dart';

class ApprovalJadwalScreen extends StatefulWidget {
  const ApprovalJadwalScreen({super.key});

  @override
  State<ApprovalJadwalScreen> createState() => _ApprovalJadwalScreenState();
}

class _ApprovalJadwalScreenState extends State<ApprovalJadwalScreen> {
  final _vm = ApprovalJadwalViewModel();

  @override
  void initState() {
    super.initState();
    _vm.addListener(() => setState(() {}));
    _vm.loadPengajuan();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  void _proses(dynamic id, String status) async {
    final success = await _vm.prosesPengajuan(id, status);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengajuan berhasil di-$status!'), backgroundColor: _getStatusColor(status)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memproses: ${_vm.errorMessage}'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approval Ruangan & Jadwal')),
      body: _vm.isLoading && _vm.daftarPengajuan.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _vm.loadPengajuan(),
              child: _vm.daftarPengajuan.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('Belum ada pengajuan masuk', style: TextStyle(color: AppColors.textSecondary))),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vm.daftarPengajuan.length,
                      itemBuilder: (context, index) {
                        final p = _vm.daftarPengajuan[index];
                        final tgl = DateTime.tryParse(p['tanggalPengganti'] ?? '');
                        final tglStr = tgl != null ? DateFormat('dd MMM yyyy').format(tgl) : '-';
                        final isPending = p['status'] == 'pending';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p['namaMK'] ?? 'Jadwal Kuliah',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(p['status']).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        (p['status'] as String).toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(p['status']),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Dosen ID: ${p['dosenId']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('Kelas: ${p['kelas']}'),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pengajuan Jadwal Baru:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Text('Tanggal: $tglStr', style: const TextStyle(fontWeight: FontWeight.w500)),
                                      Text('Jam: ${p['jamMulaiPengganti']} - ${p['jamSelesaiPengganti']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                                      Text('Ruangan: ${p['ruanganPengganti']}', style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.primary)),
                                    ],
                                  ),
                                ),
                                if (isPending) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                          onPressed: () => _proses(p['_id'], 'rejected'),
                                          child: const Text('Reject'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                                          onPressed: () => _proses(p['_id'], 'approved'),
                                          child: const Text('Approve', style: TextStyle(color: Colors.white)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
