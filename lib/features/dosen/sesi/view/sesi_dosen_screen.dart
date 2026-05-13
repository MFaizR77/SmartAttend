import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../viewmodel/sesi_dosen_viewmodel.dart';

class SesiDosenScreen extends StatefulWidget {
  final User user;
  final Map<String, String> jadwal;

  const SesiDosenScreen({super.key, required this.user, required this.jadwal});

  @override
  State<SesiDosenScreen> createState() => _SesiDosenScreenState();
}

class _SesiDosenScreenState extends State<SesiDosenScreen> {
  late SesiDosenViewModel _vm;

  @override
  void initState() {
    super.initState();
    // Gunakan 'mataKuliah' dan 'jam' gabungan sebagai identifier jadwal sementara jika id tidak ada
    final jadwalId =
        widget.jadwal['id'] ??
        '${widget.jadwal["mataKuliah"]}_${widget.jadwal["jam"]}';
    _vm = SesiDosenViewModel(jadwalId: jadwalId, dosenId: widget.user.id);
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
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        title: const Text(
          'Sesi Perkuliahan',
          style: TextStyle(
            color: Color(0xFFF6F6F6),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF01018B),
        iconTheme: const IconThemeData(color: Color(0xFFF6F6F6)),
        elevation: 0,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _vm.isLoading,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF01018B)),
            );
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
                  decoration: BoxDecoration(
                    color: const Color(0x333434A2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.class_, color: Color(0xFF01018B)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.jadwal['mataKuliah'] ?? '-',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ruang: ${widget.jadwal["ruang"]}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
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
                    const Text(
                      'Waktu Kelas',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.jadwal['jam'] ?? '-',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                          statusColor = const Color(0xFF01018B);
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
            final bool showActiveState = isBerjalan && !isSelesai;

            return Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showActiveState) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.fiber_manual_record,
                              size: 12,
                              color: Color(0xFF81C784),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sesi absen aktif · 08 menit tersisa',
                                style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Sesi Aktif'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F3F7),
                            disabledBackgroundColor: const Color(0xFFF1F3F7),
                            disabledForegroundColor: const Color(0xFF9AA3B2),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ] else if (isSelesai) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Sesi Selesai'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F3F7),
                            disabledBackgroundColor: const Color(0xFFF1F3F7),
                            disabledForegroundColor: const Color(0xFF9AA3B2),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
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
                                  side: const BorderSide(color: Color(0xFFFFCDD2)),
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
              ),
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
                    Icon(Icons.edit_note, color: Color(0xFF01018B)),
                    SizedBox(width: 8),
                    Text(
                      'Laporan Materi Dosen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silakan isi materi yang telah diajarkan pada sesi kelas ini. Anda dapat mengisinya sekarang atau sebelum pukul 23:59 hari ini.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _vm.materiController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan materi di sini...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_vm.materiController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Materi tidak boleh kosong'),
                          ),
                        );
                        return;
                      }
                      await _vm.simpanMateri();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Laporan materi berhasil disimpan',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF01018B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan Laporan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
