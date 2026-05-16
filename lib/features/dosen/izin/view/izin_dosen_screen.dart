import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../viewmodel/izin_dosen_viewmodel.dart';

class IzinDosenScreen extends StatefulWidget {
  final User user;

  const IzinDosenScreen({super.key, required this.user});

  @override
  State<IzinDosenScreen> createState() => _IzinDosenScreenState();
}

class _IzinDosenScreenState extends State<IzinDosenScreen> {
  final _vm = IzinDosenViewModel();

  DateTime? _selectedDate;
  Map<String, dynamic>? _selectedJadwal;
  String _jenis = 'izin'; // 'izin' atau 'sakit'
  final _keteranganController = TextEditingController();

  @override
  void dispose() {
    _vm.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedJadwal = null; // reset pilihan jadwal
      });
      await _vm.loadJadwalByTanggal(widget.user.id, picked);
      setState(() {}); // refresh setelah load
    }
  }

  Future<void> _submit() async {
    if (_selectedDate == null || _selectedJadwal == null) return;

    final messenger = ScaffoldMessenger.of(context);

    final success = await _vm.submitIzin(
      dosenId: widget.user.id,
      tanggal: _selectedDate!,
      jadwal: _selectedJadwal!,
      jenis: _jenis,
      keterangan: _keteranganController.text.trim(),
    );

    if (success && mounted) {
      messenger.showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 10),
          Text('Pengajuan ${_jenis == 'sakit' ? 'sakit' : 'izin'} berhasil dikirim'),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      if (mounted) Navigator.pop(context, true);
    } else if (mounted) {
      messenger.showSnackBar(SnackBar(
        content: Text('Gagal: ${_vm.errorMessage ?? 'Terjadi kesalahan'}'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengajuan Izin / Sakit',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pilih Jenis
                const Text('Jenis Pengajuan',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _jenisCard(
                        label: 'Izin',
                        icon: Icons.event_busy_outlined,
                        value: 'izin',
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _jenisCard(
                        label: 'Sakit',
                        icon: Icons.sick_outlined,
                        value: 'sakit',
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pilih Tanggal
                const Text('Tanggal',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _pilihTanggal,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: _selectedDate == null
                                ? AppColors.textSecondary
                                : AppColors.primary,
                            size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Pilih tanggal'
                              : DateFormat('EEEE, dd MMMM yyyy', 'id')
                                  .format(_selectedDate!),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _selectedDate == null
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Pilih Mata Kuliah
                const Text('Mata Kuliah',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                if (_selectedDate == null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.textSecondary, size: 18),
                        SizedBox(width: 8),
                        Text('Pilih tanggal terlebih dahulu',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                else if (_vm.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_vm.jadwalHariIni.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_outlined,
                            color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                'Tidak ada jadwal mengajar di hari tersebut',
                                style: TextStyle(color: Colors.deepOrange))),
                      ],
                    ),
                  )
                else
                  Column(
                    children: _vm.jadwalHariIni.map((j) {
                      final isSelected = _selectedJadwal == j;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () =>
                              setState(() => _selectedJadwal = isSelected ? null : j),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.07)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: isSelected ? 2 : 1),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(j['namaMK'] ?? '-',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.primary)),
                                      Text(
                                          'Kelas ${j['kelas'] ?? '-'}  •  ${j['jamMulai']} - ${j['jamSelesai']}',
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),

                // Keterangan (opsional)
                const Text('Keterangan (opsional)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 10),
                TextField(
                  controller: _keteranganController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tulis keterangan tambahan jika diperlukan...',
                    hintStyle:
                        const TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol submit
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: (_selectedDate == null ||
                            _selectedJadwal == null ||
                            _vm.isLoading)
                        ? null
                        : _submit,
                    child: _vm.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Kirim Pengajuan ${_jenis == 'sakit' ? 'Sakit' : 'Izin'}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _jenisCard({
    required String label,
    required IconData icon,
    required String value,
    required Color color,
  }) {
    final isSelected = _jenis == value;
    return GestureDetector(
      onTap: () => setState(() => _jenis = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? color : AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
