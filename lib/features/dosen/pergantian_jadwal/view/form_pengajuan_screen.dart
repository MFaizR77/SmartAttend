import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/local/models/user.dart';
import '../viewmodel/pergantian_jadwal_viewmodel.dart';
import 'pilih_ruangan_screen.dart';

class FormPengajuanScreen extends StatefulWidget {
  final User user;
  final PergantianJadwalViewModel vm;

  const FormPengajuanScreen({super.key, required this.user, required this.vm});

  @override
  State<FormPengajuanScreen> createState() => _FormPengajuanScreenState();
}

class _FormPengajuanScreenState extends State<FormPengajuanScreen> {
  Map<String, dynamic>? _selectedJadwal;
  DateTime? _selectedDate;
  TimeOfDay? _jamMulai;
  TimeOfDay? _jamSelesai;

  @override
  void initState() {
    super.initState();
    widget.vm.loadJadwalAsli(widget.user.id);
  }

  void _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _pilihJamMulai() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked != null) {
      setState(() => _jamMulai = picked);
    }
  }

  void _pilihJamSelesai() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _jamMulai ?? const TimeOfDay(hour: 8, minute: 40),
    );
    if (picked != null) {
      setState(() => _jamSelesai = picked);
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pengajuan')),
      body: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, _) {
          if (widget.vm.isLoading && widget.vm.daftarJadwalAsli.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih Jadwal Reguler', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<Map<String, dynamic>>(
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  hint: const Text('Pilih mata kuliah & kelas'),
                  value: _selectedJadwal,
                  items: widget.vm.daftarJadwalAsli.map((j) {
                    return DropdownMenuItem(
                      value: j,
                      child: Text('${j['namaMK']} - ${j['kelas']} (${j['hari']})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedJadwal = val;
                      // Autofill durasi aslinya untuk mempermudah
                      if (val != null) {
                        final startParts = (val['jamMulai'] as String).split(':');
                        final endParts = (val['jamSelesai'] as String).split(':');
                        _jamMulai = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
                        _jamSelesai = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
                      }
                    });
                  },
                ),
                const SizedBox(height: 24),

                const Text('Pilih Waktu Pengganti', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.grey)),
                  leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                  title: Text(_selectedDate == null ? 'Pilih Tanggal' : DateFormat('dd MMMM yyyy').format(_selectedDate!)),
                  onTap: _pilihTanggal,
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.grey)),
                        leading: const Icon(Icons.access_time, color: AppColors.primary),
                        title: Text('Mulai: ${_formatTime(_jamMulai)}', style: const TextStyle(fontSize: 14)),
                        onTap: _pilihJamMulai,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.grey)),
                        leading: const Icon(Icons.access_time_filled, color: AppColors.primary),
                        title: Text('Selesai: ${_formatTime(_jamSelesai)}', style: const TextStyle(fontSize: 14)),
                        onTap: _pilihJamSelesai,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_selectedJadwal == null || _selectedDate == null || _jamMulai == null || _jamSelesai == null)
                        ? null
                        : () async {
                            final jamMulaiStr = _formatTime(_jamMulai);
                            final jamSelesaiStr = _formatTime(_jamSelesai);
                            
                            // Cari ruangan kosong
                            await widget.vm.cariRuangan(_selectedDate!, jamMulaiStr, jamSelesaiStr);
                            
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PilihRuanganScreen(
                                    user: widget.user,
                                    vm: widget.vm,
                                    jadwalAsli: _selectedJadwal!,
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
                        : const Text('Cari Ruangan Kosong', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
