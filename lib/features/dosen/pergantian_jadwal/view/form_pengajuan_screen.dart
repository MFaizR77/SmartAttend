import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          ListenableBuilder(
        listenable: widget.vm,
        builder: (context, _) {
            if (widget.vm.isLoading && widget.vm.daftarJadwalAsli.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF01018B)));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 100, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PILIH JADWAL REGULER',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Plus Jakarta Sans',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedJadwal != null ? const Color(0xFF01018B) : const Color(0xFFE5E7EB),
                        width: _selectedJadwal != null ? 1.5 : 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        isExpanded: true,
                        hint: const Text(
                          'Pilih mata kuliah',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 14,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                        value: _selectedJadwal,
                        items: widget.vm.daftarJadwalAsli.map((j) {
                          return DropdownMenuItem(
                            value: j,
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0x213434A2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.class_outlined,
                                    color: Color(0xFF01018B),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        j['namaMK'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A1A),
                                          fontFamily: 'Plus Jakarta Sans',
                                        ),
                                      ),
                                      Text(
                                        'Kelas ${j['kelas']} - ${j['hari']}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF9CA3AF),
                                          fontFamily: 'Plus Jakarta Sans',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedJadwal = val;
                            if (val != null) {
                              final startParts = (val['jamMulai'] as String).split(':');
                              final endParts = (val['jamSelesai'] as String).split(':');
                              _jamMulai = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
                              _jamSelesai = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
                            }
                          });
                        },
                        icon: const Icon(Icons.expand_more, color: Color(0xFF9CA3AF)),
                        style: const TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 14,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ),
                  if (_selectedJadwal != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF01018B), width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedJadwal!['namaMK'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A1A),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedJadwal!['hari']} - ${_selectedJadwal!['jamMulai']}-${_selectedJadwal!['jamSelesai']} | ${_selectedJadwal!['ruangan']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF01018B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Dipilih',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'PILIH WAKTU PENGGANTI',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Plus Jakarta Sans',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pilihTanggal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedDate != null ? const Color(0xFF01018B) : const Color(0xFFE5E7EB),
                          width: _selectedDate != null ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: Color(0xFF01018B),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? 'Pilih tanggal'
                                  : DateFormat('dd MMMM yyyy').format(_selectedDate!),
                              style: TextStyle(
                                color: _selectedDate == null ? const Color(0xFF9CA3AF) : const Color(0xFF1A1A1A),
                                fontSize: 14,
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: _selectedDate == null ? FontWeight.w400 : FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pilihJamMulai,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _jamMulai != null ? const Color(0xFF01018B) : const Color(0xFFE5E7EB),
                                width: _jamMulai != null ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.schedule_outlined,
                                  color: Color(0xFF01018B),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _jamMulai == null ? 'Mulai' : _formatTime(_jamMulai),
                                    style: TextStyle(
                                      color: _jamMulai == null ? const Color(0xFF9CA3AF) : const Color(0xFF1A1A1A),
                                      fontSize: 14,
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: _jamMulai == null ? FontWeight.w400 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pilihJamSelesai,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _jamSelesai != null ? const Color(0xFF01018B) : const Color(0xFFE5E7EB),
                                width: _jamSelesai != null ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.schedule_outlined,
                                  color: Color(0xFF01018B),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _jamSelesai == null ? 'Selesai' : _formatTime(_jamSelesai),
                                    style: TextStyle(
                                      color: _jamSelesai == null ? const Color(0xFF9CA3AF) : const Color(0xFF1A1A1A),
                                      fontSize: 14,
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: _jamSelesai == null ? FontWeight.w400 : FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'ALASAN GANTI JADWAL',
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Plus Jakarta Sans',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                    ),
                    child: TextField(
                      maxLines: 4,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tuliskan alasan mengapa jadwal perlu diganti...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_selectedJadwal != null && _selectedDate != null && _jamMulai != null && _jamSelesai != null) ...[
                    Text(
                      'RINGKASAN PERUBAHAN',
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Plus Jakarta Sans',
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF3F4F6), width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Color(0xFFDC2626),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Jadwal Reguler',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9CA3AF),
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                    Text(
                                      '${_selectedJadwal!['hari']}, ${_selectedJadwal!['jamMulai']}-${_selectedJadwal!['jamSelesai']}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Icon(
                              Icons.expand_more,
                              color: const Color(0xFF01018B),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0FDF4),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calendar_today_outlined,
                                  color: Color(0xFF16A34A),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Jadwal Pengganti',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9CA3AF),
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                    Text(
                                      '${DateFormat('EEEE').format(_selectedDate!)}, ${_formatTime(_jamMulai)}-${_formatTime(_jamSelesai)}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A1A1A),
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (_selectedJadwal == null || _selectedDate == null || _jamMulai == null || _jamSelesai == null)
                              ? null
                              : () async {
                                  final jamMulaiStr = _formatTime(_jamMulai);
                                  final jamSelesaiStr = _formatTime(_jamSelesai);
                                  
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF01018B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            shadowColor: const Color(0x4D01018B),
                            disabledBackgroundColor: const Color(0xFFE5E7EB),
                          ),
                          child: widget.vm.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Cari Ruangan Kosong',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                color: Color(0xFF01018B),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3F000000),
                    blurRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Buat Pengajuan',
                      style: TextStyle(
                        color: Color(0xFFF6F6F6),
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
