import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/local/models/user.dart';
import '../viewmodel/pergantian_jadwal_viewmodel.dart';
import 'pilih_ruangan_screen.dart';

class FormPengajuanScreen extends StatefulWidget {
  final User user;
  final PergantianJadwalViewModel vm;
  final Map<String, dynamic> jadwalTerpilih;

  const FormPengajuanScreen({
    super.key,
    required this.user,
    required this.vm,
    required this.jadwalTerpilih,
  });

  @override
  State<FormPengajuanScreen> createState() => _FormPengajuanScreenState();
}

class _FormPengajuanScreenState extends State<FormPengajuanScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _jamMulai;

  // Durasi asli dalam menit, dihitung dari jadwal asli
  late int _durasiMenit;
  late String _jamSelesaiAsli;
  late String _jamMulaiAsli;

  @override
  void initState() {
    super.initState();
    final j = widget.jadwalTerpilih;
    _jamMulaiAsli = j['jamMulai'] ?? '07:00';
    _jamSelesaiAsli = j['jamSelesai'] ?? '08:40';
    _durasiMenit = _hitungDurasi(_jamMulaiAsli, _jamSelesaiAsli);
  }

  int _hitungDurasi(String mulai, String selesai) {
    final mulaiParts = mulai.split(':');
    final selesaiParts = selesai.split(':');
    final mulaiMenit = int.parse(mulaiParts[0]) * 60 + int.parse(mulaiParts[1]);
    final selesaiMenit =
        int.parse(selesaiParts[0]) * 60 + int.parse(selesaiParts[1]);
    return selesaiMenit - mulaiMenit;
  }

  /// Hitung jam selesai otomatis berdasarkan jam mulai + durasi asli
  String _hitungJamSelesai(TimeOfDay mulai) {
    final totalMenit = mulai.hour * 60 + mulai.minute + _durasiMenit;
    final h = (totalMenit ~/ 60).toString().padLeft(2, '0');
    final m = (totalMenit % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _pilihJamMulai() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_jamMulaiAsli.split(':')[0]),
        minute: int.parse(_jamMulaiAsli.split(':')[1]),
      ),
    );
    if (picked != null) setState(() => _jamMulai = picked);
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.jadwalTerpilih;
    final jamSelesaiOtomatis = _jamMulai != null
        ? _hitungJamSelesai(_jamMulai!)
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Ajukan Pergantian Jadwal',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info jadwal asli (read-only)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jadwal Asli',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(Icons.book_outlined, j['namaMK'] ?? '-'),
                  const SizedBox(height: 6),
                  _infoRow(Icons.people_outline, 'Kelas ${j['kelas'] ?? '-'}'),
                  const SizedBox(height: 6),
                  _infoRow(
                    Icons.schedule_outlined,
                    '${j['hari'] ?? '-'}  •  $_jamMulaiAsli - $_jamSelesaiAsli ($_durasiMenit menit)',
                  ),
                  const SizedBox(height: 6),
                  _infoRow(Icons.room_outlined, j['ruangan'] ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'Pilih Jadwal Pengganti',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // Tanggal
            _pilihCard(
              icon: Icons.calendar_today,
              label: 'Tanggal Pengganti',
              value: _selectedDate == null
                  ? 'Pilih tanggal'
                  : DateFormat(
                      'EEEE, dd MMMM yyyy',
                      'id',
                    ).format(_selectedDate!),
              onTap: _pilihTanggal,
              isEmpty: _selectedDate == null,
            ),
            const SizedBox(height: 12),

            // Jam Mulai
            _pilihCard(
              icon: Icons.access_time,
              label: 'Jam Mulai Pengganti',
              value: _formatTime(_jamMulai),
              onTap: _pilihJamMulai,
              isEmpty: _jamMulai == null,
            ),
            const SizedBox(height: 12),

            // Jam Selesai (otomatis)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.access_time_filled,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jam Selesai (otomatis)',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        jamSelesaiOtomatis ?? '--:--  (isi jam mulai dulu)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: jamSelesaiOtomatis != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$_durasiMenit menit',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: (_selectedDate == null || _jamMulai == null)
                    ? null
                    : () async {
                        final jamMulaiStr = _formatTime(_jamMulai);
                        final jamSelesaiStr = _hitungJamSelesai(_jamMulai!);

                        await widget.vm.cariRuangan(
                          _selectedDate!,
                          jamMulaiStr,
                          jamSelesaiStr,
                        );

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PilihRuanganScreen(
                                user: widget.user,
                                vm: widget.vm,
                                jadwalAsli: widget.jadwalTerpilih,
                                tanggal: _selectedDate!,
                                jamMulai: jamMulaiStr,
                                jamSelesai: jamSelesaiStr,
                              ),
                            ),
                          );
                        }
                      },
                child: widget.vm.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Cari Ruangan Kosong',
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
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _pilihCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isEmpty,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isEmpty ? AppColors.textSecondary : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isEmpty
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
