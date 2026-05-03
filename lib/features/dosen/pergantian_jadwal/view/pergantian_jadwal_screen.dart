import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/local/models/user.dart';
import '../viewmodel/pergantian_jadwal_viewmodel.dart';
import 'form_pengajuan_screen.dart';

class PergantianJadwalScreen extends StatefulWidget {
  final User user;

  const PergantianJadwalScreen({super.key, required this.user});

  @override
  State<PergantianJadwalScreen> createState() => _PergantianJadwalScreenState();
}

class _PergantianJadwalScreenState extends State<PergantianJadwalScreen> {
  final _vm = PergantianJadwalViewModel();

  @override
  void initState() {
    super.initState();
    _vm.addListener(() => setState(() {}));
    _loadData();
  }

  void _loadData() {
    _vm.loadRiwayat(widget.user.id);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pergantian Jadwal'),
      ),
      body: _vm.isLoading && _vm.riwayatPengajuan.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: _vm.riwayatPengajuan.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                            child: Text('Belum ada riwayat pengajuan',
                                style: TextStyle(color: AppColors.textSecondary))),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _vm.riwayatPengajuan.length,
                      itemBuilder: (context, index) {
                        final p = _vm.riwayatPengajuan[index];
                        final tgl = DateTime.tryParse(p['tanggalPengganti'] ?? '');
                        final tglStr = tgl != null ? DateFormat('dd MMM yyyy').format(tgl) : '-';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                Text('Kelas: ${p['kelas']}'),
                                const SizedBox(height: 4),
                                Text('Jadwal Pengganti:', style: TextStyle(color: AppColors.textSecondary)),
                                Text('$tglStr, ${p['jamMulaiPengganti']} - ${p['jamSelesaiPengganti']}'),
                                Text('Ruangan: ${p['ruanganPengganti']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => FormPengajuanScreen(user: widget.user, vm: _vm)),
          );
          if (result == true) {
            _loadData(); // reload after submit
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajukan'),
      ),
    );
  }
}
