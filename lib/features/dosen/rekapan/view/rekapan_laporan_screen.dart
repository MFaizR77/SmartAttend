import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../viewmodel/rekapan_laporan_viewmodel.dart';
import 'package:intl/intl.dart';

class RekapanLaporanScreen extends StatefulWidget {
  final User user;
  const RekapanLaporanScreen({super.key, required this.user});

  @override
  State<RekapanLaporanScreen> createState() => _RekapanLaporanScreenState();
}

class _RekapanLaporanScreenState extends State<RekapanLaporanScreen> {
  final _vm = RekapanLaporanViewModel();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vm.loadRekapan(widget.user.id);
    });
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _showLaporanDialog(Map<String, dynamic> lap) {
    final namaMK = lap['namaMK'] ?? '-';
    final kelas = lap['kelas'] ?? '-';
    final materi = lap['materi'] ?? 'Belum ada materi yang diisi.';
    final dateStr = lap['tanggal']?.toString() ?? '';
    final formattedDate = dateStr.isNotEmpty && dateStr.length >= 10 ? dateStr.substring(0, 10) : '-';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.assignment, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Isi Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$namaMK - Kelas $kelas', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Tanggal: $formattedDate', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(materi, style: const TextStyle(fontSize: 14, height: 1.5)),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Tutup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekapan Laporan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (_vm.laporanList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('Belum ada laporan mengajar.', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _vm.laporanList.length,
            itemBuilder: (context, index) {
              final lap = _vm.laporanList[index];
              final namaMK = lap['namaMK'] ?? '-';
              final kelas = lap['kelas'] ?? '-';
              final hari = lap['hari'] ?? '-';
              
              // Format tanggal (YYYY-MM-DD)
              final dateStr = lap['tanggal']?.toString() ?? '';
              final formattedDate = dateStr.isNotEmpty && dateStr.length >= 10 ? dateStr.substring(0, 10) : '-';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('$hari, $formattedDate', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          if (lap['syncStatus'] == 'synced')
                            const Icon(Icons.cloud_done, color: AppColors.success, size: 16)
                          else
                            const Icon(Icons.cloud_upload, color: Colors.orange, size: 16),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(namaMK, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Kelas: $kelas', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showLaporanDialog(lap),
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text('Lihat Laporan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
