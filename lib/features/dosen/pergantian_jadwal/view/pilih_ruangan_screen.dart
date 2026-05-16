import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/local/models/user.dart';
import '../viewmodel/pergantian_jadwal_viewmodel.dart';
import 'package:intl/intl.dart';

class PilihRuanganScreen extends StatelessWidget {
  final User user;
  final PergantianJadwalViewModel vm;
  final Map<String, dynamic> jadwalAsli;
  final DateTime tanggal;
  final String jamMulai;
  final String jamSelesai;

  const PilihRuanganScreen({
    super.key,
    required this.user,
    required this.vm,
    required this.jadwalAsli,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
  });

  void _konfirmasiPilih(BuildContext context, String namaRuang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pengajuan'),
        content: Text('Anda yakin ingin mengajukan pergantian jadwal ke ruangan $namaRuang pada tanggal ${DateFormat('dd MMM yyyy').format(tanggal)} jam $jamMulai-$jamSelesai?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // tutup dialog
              final success = await vm.ajukan(user.id, jadwalAsli, tanggal, jamMulai, jamSelesai, namaRuang);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Berhasil mengajukan ganti jadwal!'), backgroundColor: AppColors.success),
                );
                // Pop dua kali kembali ke layar utama riwayat
                Navigator.pop(context);
                Navigator.pop(context, true); 
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal mengajukan: ${vm.errorMessage}'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Ya, Ajukan'),
          ),
        ],
      ),
    );
  }

  void _tampilkanDetailRuangan(BuildContext context, String namaRuang) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Detail Jadwal Ruang $namaRuang', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(DateFormat('EEEE, dd MMMM yyyy').format(tanggal), style: const TextStyle(color: AppColors.textSecondary)),
              const Divider(height: 24),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: vm.getDetailRuangan(tanggal, namaRuang),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Gagal memuat jadwal: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
                    }
                    final list = snapshot.data ?? [];
                    if (list.isEmpty) {
                      return const Center(child: Text('Tidak ada jadwal pada hari ini (Mungkin sedang di-booking untuk kegiatan lain).', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)));
                    }
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final j = list[index];
                        final isPengganti = j['jenis'] == 'Pengganti';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: isPengganti ? Colors.orange.shade50 : AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isPengganti ? Colors.orange.shade200 : AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('${j['jamMulai']} - ${j['jamSelesai']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(j['namaMK'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Text('Kelas: ${j['kelas']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                      if (isPengganti)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                                          child: const Text('Kelas Pengganti', style: TextStyle(color: Colors.deepOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
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
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Ruangan Kosong')),
      body: ListenableBuilder(
        listenable: vm,
        builder: (context, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.daftarRuangan.isEmpty) {
            return const Center(child: Text('Tidak ada data ruangan master.'));
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.blue.withValues(alpha: 0.1),
                width: double.infinity,
                child: Column(
                  children: [
                    Text(DateFormat('EEEE, dd MMMM yyyy').format(tanggal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('$jamMulai - $jamSelesai', style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendItem(Colors.white, 'Kosong', borderColor: Colors.grey),
                    const SizedBox(width: 24),
                    _legendItem(Colors.red.shade400, 'Terpakai'),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // 4 kursi sebaris
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: vm.daftarRuangan.length,
                  itemBuilder: (context, index) {
                    final r = vm.daftarRuangan[index];
                    final nama = r['nama'] as String;
                    final isTerpakai = r['isTerpakai'] as bool;

                    return InkWell(
                      onTap: isTerpakai ? () => _tampilkanDetailRuangan(context, nama) : () => _konfirmasiPilih(context, nama),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isTerpakai ? Colors.red.shade400 : Colors.white,
                          border: Border.all(color: isTerpakai ? Colors.red.shade600 : Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chair_alt,
                              color: isTerpakai ? Colors.white : Colors.blueGrey,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nama,
                              style: TextStyle(
                                color: isTerpakai ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _legendItem(Color color, String label, {Color? borderColor}) {
    return Row(
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: borderColor ?? color),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
