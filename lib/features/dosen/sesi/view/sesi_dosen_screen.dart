import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../viewmodel/sesi_dosen_viewmodel.dart';

class SesiDosenScreen extends StatefulWidget {
  final User user;
  final Map<String, String> jadwal;

  const SesiDosenScreen({
    super.key,
    required this.user,
    required this.jadwal,
  });

  @override
  State<SesiDosenScreen> createState() => _SesiDosenScreenState();
}

class _SesiDosenScreenState extends State<SesiDosenScreen> {
  late SesiDosenViewModel _vm;

  @override
  void initState() {
    super.initState();
    // Gunakan 'mataKuliah' dan 'jam' gabungan sebagai identifier jadwal sementara jika id tidak ada
    final jadwalId = widget.jadwal['id'] ?? '${widget.jadwal["mataKuliah"]}_${widget.jadwal["jam"]}';
    _vm = SesiDosenViewModel(
      jadwalId: jadwalId,
      dosenId: widget.user.id,
    );
    _vm.loadData();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sesi Perkuliahan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _vm.isLoading,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 24),
                _buildDaftarMahasiswa(),
                _buildLaporanSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.class_, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.jadwal['mataKuliah'] ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Ruang: ${widget.jadwal["ruang"]}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Waktu Kelas', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text(widget.jadwal['jam'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _vm.isKelasBerjalan,
                  builder: (context, isBerjalan, child) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: _vm.isKelasSelesai,
                      builder: (context, isSelesai, child) {
                        String statusText = 'Belum Mulai';
                        Color statusColor = AppColors.textSecondary;

                        if (isSelesai) {
                          statusText = 'Selesai';
                          statusColor = AppColors.success;
                        } else if (isBerjalan) {
                          statusText = 'Sedang Berjalan';
                          statusColor = AppColors.primary;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return ValueListenableBuilder<bool>(
      valueListenable: _vm.isKelasBerjalan,
      builder: (context, isBerjalan, child) {
        return ValueListenableBuilder<bool>(
          valueListenable: _vm.isKelasSelesai,
          builder: (context, isSelesai, child) {
            if (isSelesai) {
              return const SizedBox.shrink(); // Sembunyikan tombol jika sudah selesai
            }

            if (isBerjalan) {
              return ElevatedButton(
                onPressed: () async {
                  await _vm.selesaiKuliah();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi kuliah diakhiri. Jangan lupa isi materi laporan!')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Akhiri Kuliah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              );
            }

            return ElevatedButton(
              onPressed: () async {
                await _vm.mulaiKuliah();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesi kuliah dimulai')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Mulai Kuliah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            );
          },
        );
      },
    );
  }

  Widget _buildLaporanSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: _vm.isKelasSelesai,
      builder: (context, isSelesai, child) {
        if (!isSelesai) {
          return const SizedBox.shrink(); // Sembunyikan form laporan jika belum selesai
        }

        return Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.edit_note, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Laporan Materi Dosen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Silakan isi materi yang telah diajarkan pada sesi kelas ini. Anda dapat mengisinya sekarang atau sebelum pukul 23:59 hari ini.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                TextField(
                  controller: _vm.materiController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan materi di sini...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<bool>(
                  valueListenable: _vm.isLaporanTerkirim,
                  builder: (context, isTerkirim, child) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isTerkirim
                            ? null
                            : () async {
                                final scaffoldMessenger = ScaffoldMessenger.of(context);
                                
                                if (_vm.materiController.text.trim().isEmpty) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: const Text('Materi tidak boleh kosong'),
                                      backgroundColor: AppColors.error,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      margin: const EdgeInsets.all(16),
                                    )
                                  );
                                  return;
                                }
                                await _vm.simpanMateri();
                                
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('Laporan materi berhasil disimpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    margin: const EdgeInsets.all(16),
                                    elevation: 4,
                                  )
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTerkirim ? Colors.grey : AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(isTerkirim ? Icons.check_circle : Icons.save, color: Colors.white),
                        label: Text(
                          isTerkirim ? 'Laporan Terkirim' : 'Simpan Laporan',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildDaftarMahasiswa() {
    return ValueListenableBuilder<bool>(
      valueListenable: _vm.isKelasBerjalan,
      builder: (context, isBerjalan, _) {
        if (!isBerjalan) return const SizedBox.shrink();

        return ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: _vm.statusMahasiswa,
          builder: (context, list, _) {
            // Hitung ringkasan
            final hadirCount = list.where((m) => m['status'] == 'hadir').length;
            final belumCount = list.where((m) => m['status'] == 'belum').length;
            final alphaCount = list.where((m) => m['status'] == 'alpha').length;
            final izinCount  = list.where((m) => m['status'] == 'izin').length;
            final sakitCount = list.where((m) => m['status'] == 'sakit').length;

            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.people_outline, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Kehadiran Mahasiswa',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        // Refresh manual
                        InkWell(
                          onTap: () => _vm.loadStatusMahasiswa(),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Ringkasan chip
                    if (list.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _summaryChip('Hadir', hadirCount, AppColors.success),
                            const SizedBox(width: 8),
                            _summaryChip('Belum', belumCount, Colors.grey),
                            const SizedBox(width: 8),
                            _summaryChip('Izin', izinCount, Colors.blue),
                            const SizedBox(width: 8),
                            _summaryChip('Sakit', sakitCount, Colors.orange),
                            const SizedBox(width: 8),
                            _summaryChip('Alpha', alphaCount, AppColors.error),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Daftar mahasiswa
                    if (list.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text('Memuat data mahasiswa...',
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    else
                      ...list.map((m) => _buildMahasiswaRow(m)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _summaryChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildMahasiswaRow(Map<String, dynamic> m) {
    final status = m['status'] as String? ?? 'belum';
    final nama = m['nama'] as String? ?? '-';
    final nim = m['nim'] as String? ?? '-';

    Color chipColor;
    String chipLabel;
    IconData chipIcon;
    switch (status) {
      case 'hadir':
        chipColor = AppColors.success;
        chipLabel = 'Hadir';
        chipIcon = Icons.check_circle_rounded;
        break;
      case 'izin':
        chipColor = Colors.blue;
        chipLabel = 'Izin';
        chipIcon = Icons.event_note_rounded;
        break;
      case 'sakit':
        chipColor = Colors.orange;
        chipLabel = 'Sakit';
        chipIcon = Icons.sick_rounded;
        break;
      case 'alpha':
        chipColor = AppColors.error;
        chipLabel = 'Alpha';
        chipIcon = Icons.cancel_rounded;
        break;
      default: // 'belum'
        chipColor = Colors.grey;
        chipLabel = 'Belum Absen';
        chipIcon = Icons.access_time_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Inisial avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: chipColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                style: TextStyle(fontWeight: FontWeight.bold, color: chipColor, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(nim, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          // Chip status — semua bisa di-tap untuk ubah status
          GestureDetector(
            onTap: () => _showStatusDialog(nim, nama, status),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: chipColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chipIcon, size: 13, color: chipColor),
                  const SizedBox(width: 4),
                  Text(chipLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: chipColor)),
                  const SizedBox(width: 4),
                  Icon(Icons.edit_rounded, size: 11, color: chipColor.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(String nim, String nama, String currentStatus) async {
    final pilihan = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('NIM: $nim', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 16),
              const Text('Ubah Status Kehadiran', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              // Opsi status
              _statusOption(ctx, label: 'Hadir', icon: Icons.check_circle_rounded, color: AppColors.success, value: 'hadir', current: currentStatus),
              _statusOption(ctx, label: 'Izin', icon: Icons.event_note_rounded, color: Colors.blue, value: 'izin', current: currentStatus),
              _statusOption(ctx, label: 'Sakit', icon: Icons.sick_rounded, color: Colors.orange, value: 'sakit', current: currentStatus),
              _statusOption(ctx, label: 'Alpha', icon: Icons.cancel_rounded, color: AppColors.error, value: 'alpha', current: currentStatus),
              if (currentStatus != 'belum') ...[
                const Divider(height: 20),
                _statusOption(ctx, label: 'Hapus Status (Kembali Belum Absen)', icon: Icons.undo_rounded, color: Colors.grey, value: 'hapus', current: currentStatus),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );

    if (pilihan == null || !mounted) return;

    try {
      await _vm.tandaiStatus(nim, pilihan);
      if (mounted) {
        final statusLabel = {
          'hadir': 'Hadir', 'izin': 'Izin', 'sakit': 'Sakit',
          'alpha': 'Alpha', 'hapus': 'dihapus',
        }[pilihan] ?? pilihan;
        final color = pilihan == 'hapus' ? Colors.grey : {
          'hadir': AppColors.success, 'izin': Colors.blue,
          'sakit': Colors.orange, 'alpha': AppColors.error,
        }[pilihan] ?? Colors.grey;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$nama → $statusLabel'),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal mengubah status, coba lagi'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Widget _statusOption(BuildContext ctx, {
    required String label, required IconData icon, required Color color,
    required String value, required String current,
  }) {
    final isActive = current == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, color: isActive ? color : Colors.grey, size: 22),
      title: Text(label, style: TextStyle(
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        color: isActive ? color : AppColors.textPrimary,
      )),
      trailing: isActive ? Icon(Icons.check_rounded, color: color, size: 18) : null,
      onTap: isActive ? null : () => Navigator.pop(ctx, value),
    );
  }
}
