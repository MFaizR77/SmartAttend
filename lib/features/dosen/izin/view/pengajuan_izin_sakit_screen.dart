import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';

class PengajuanIzinSakitScreen extends StatefulWidget {
  final User user;
  const PengajuanIzinSakitScreen({super.key, required this.user});

  @override
  State<PengajuanIzinSakitScreen> createState() => _PengajuanIzinSakitScreenState();
}

class _PengajuanIzinSakitScreenState extends State<PengajuanIzinSakitScreen> {
  bool _isIzin = true;
  DateTime? _tanggal;
  int? _selectedMatkulIndex;
  final _keteranganCtrl = TextEditingController();

  final _matkulList = [
    {'nama': 'Pemrograman Mobile', 'meta': '07:30 – 09:10 · Ruang 204'},
    {'nama': 'Basis Data Lanjut', 'meta': '09:30 – 11:10 · Lab DB'},
    {'nama': 'Rekayasa Perangkat Lunak', 'meta': '11:30 – 13:10 · Ruang 301'},
  ];

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    super.dispose();
  }

  void _setType(bool isIzin) => setState(() => _isIzin = isIzin);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  void _selectMatkul(int idx) => setState(() => _selectedMatkulIndex = idx);

  bool get _ready => _tanggal != null && _selectedMatkulIndex != null;

  void _submit() {
    if (!_ready) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pengajuan Terkirim!'),
        content: const Text('Pengajuan telah dikirim dan sedang menunggu persetujuan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tanggalText = _tanggal == null
        ? 'Pilih tanggal'
        : DateFormat('d MMMM yyyy', 'id_ID').format(_tanggal!);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF01018B),
        title: const Text(
          'Pengajuan Izin / Sakit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFFF8003),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Jenis Pengajuan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setType(true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _isIzin ? const Color(0xFFFF8003) : const Color(0xFFE5E7EB), width: 2),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _isIzin ? const Color(0xFFFF8003).withOpacity(0.12) : const Color(0xFF3434A2).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.event_note, color: Color(0xFFFF8003)),
                          ),
                          const SizedBox(height: 8),
                          Text('Izin', style: TextStyle(fontWeight: FontWeight.w700, color: _isIzin ? const Color(0xFFFF8003) : const Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setType(false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: !_isIzin ? const Color(0xFFFF8003) : const Color(0xFFE5E7EB), width: 2),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: !_isIzin ? const Color(0xFFFF8003).withOpacity(0.12) : const Color(0xFF3434A2).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.healing, color: Color(0xFF9CA3AF)),
                          ),
                          const SizedBox(height: 8),
                          Text('Sakit', style: TextStyle(fontWeight: FontWeight.w700, color: !_isIzin ? const Color(0xFFFF8003) : const Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            const Text('Tanggal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tanggalText,
                        style: TextStyle(
                          color: _tanggal == null ? const Color(0xFF9CA3AF) : const Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFFD1D5DB)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            const Text('Mata Kuliah', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (_tanggal == null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                ),
                child: const Text('Pilih tanggal terlebih dahulu', style: TextStyle(color: Color(0xFF9CA3AF))),
              )
            else ...[
              for (var i = 0; i < _matkulList.length; i++)
                GestureDetector(
                  onTap: () => _selectMatkul(i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _selectedMatkulIndex == i ? const Color(0xFFF5F5FF) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _selectedMatkulIndex == i ? const Color(0xFF01018B) : const Color(0xFFE5E7EB), width: 2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3434A2).withOpacity(0.13),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.book_outlined, color: Color(0xFF01018B)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_matkulList[i]['nama']!, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(_matkulList[i]['meta']!, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                            ],
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _selectedMatkulIndex == i ? const Color(0xFF01018B) : const Color(0xFFD1D5DB), width: 2),
                            color: _selectedMatkulIndex == i ? const Color(0xFF01018B) : Colors.transparent,
                          ),
                          child: _selectedMatkulIndex == i
                              ? const Icon(Icons.check, size: 12, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 18),
            const Text('Keterangan (opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _keteranganCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Tulis keterangan tambahan jika diperlukan...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(14, 12, 14, 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${_keteranganCtrl.text.length}/300', style: const TextStyle(color: Color(0xFFD1D5DB), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _ready ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ready ? const Color(0xFF01018B) : const Color(0xFFE5E7EB),
                  foregroundColor: _ready ? Colors.white : const Color(0xFF9CA3AF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(_isIzin ? 'Kirim Pengajuan Izin' : 'Kirim Pengajuan Sakit', style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
