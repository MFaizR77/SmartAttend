import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_back_button.dart';

// Design tokens
const _kPrimary = Color(0xFF01018B);
const _kAccent = Color(0xFFFF8003);
const _kBgPage = Color(0xFFF6F6F6);
const _kCardBg = Color(0xFFFFFFFF);
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextMuted = Color(0xFF9CA3AF);
const _kGreen = Color(0xFF16A34A);
const _kGreenBg = Color(0xFFF0FDF4);
const _kGreenBorder = Color(0xFFBBF7D0);
const _kRed = Color(0xFFEF4444);
const _kRedBg = Color(0xFFFFF5F5);
const _kRedBorder = Color(0xFFFECACA);

class IzinTindakLanjut {
  final String namaInisial;
  final String namaMahasiswa;
  final String nim;
  final String jenis; // Izin / Sakit
  final String matkul;
  final String tanggal; // e.g. "Senin, 18 Mei 2026"
  final String keterangan;
  final String? namaFile;
  final String? ukuranFile;
  final String? catatanDosen;
  final String? alasanTolak;
  final String diprosesPada; // e.g. "18 Mei 2026"
  final String diprosesDosen;

  IzinTindakLanjut({
    required this.namaInisial,
    required this.namaMahasiswa,
    required this.nim,
    required this.jenis,
    required this.matkul,
    required this.tanggal,
    required this.keterangan,
    this.namaFile,
    this.ukuranFile,
    this.catatanDosen,
    this.alasanTolak,
    required this.diprosesPada,
    required this.diprosesDosen,
  });
}

class TindakLanjutIzinScreen extends StatefulWidget {
  const TindakLanjutIzinScreen({super.key});

  @override
  State<TindakLanjutIzinScreen> createState() => _TindakLanjutIzinScreenState();
}

class _TindakLanjutIzinScreenState extends State<TindakLanjutIzinScreen> {
  int _tabIndex = 0; // 0 = Disetujui, 1 = Ditolak
  DateTime _selectedDate = DateTime(2026, 5, 18);

  late final List<IzinTindakLanjut> _approved;
  late final List<IzinTindakLanjut> _rejected;

  @override
  void initState() {
    super.initState();
    _approved = [
      IzinTindakLanjut(
        namaInisial: 'IK',
        namaMahasiswa: 'Idham Khalid',
        nim: '241511046',
        jenis: 'Izin',
        matkul: 'Pemrograman Mobile',
        tanggal: 'Senin, 18 Mei 2026',
        keterangan: 'Izin menghadiri pernikahan kakak kandung.',
        namaFile: 'surat_izin.pdf',
        ukuranFile: '325 KB',
        catatanDosen: 'Disetujui. Harap hubungi teman untuk melengkapi catatan.',
        diprosesPada: '18 Mei 2026',
        diprosesDosen: 'Santi Sundari',
      ),
      IzinTindakLanjut(
        namaInisial: 'SR',
        namaMahasiswa: 'Siti Rahmawati',
        nim: '241511052',
        jenis: 'Sakit',
        matkul: 'Basis Data Lanjut',
        tanggal: 'Selasa, 19 Mei 2026',
        keterangan: 'Demam tinggi 39°C. Surat keterangan dokter terlampir.',
        namaFile: 'surat_sakit.jpg',
        ukuranFile: '410 KB',
        catatanDosen: null,
        diprosesPada: '19 Mei 2026',
        diprosesDosen: 'Santi Sundari',
      ),
      IzinTindakLanjut(
        namaInisial: 'BP',
        namaMahasiswa: 'Budi Pratama',
        nim: '241511033',
        jenis: 'Izin',
        matkul: 'Rekayasa PL',
        tanggal: 'Jumat, 16 Mei 2026',
        keterangan: 'Mengikuti lomba hackathon nasional mewakili kampus.',
        namaFile: 'undangan_hackathon.pdf',
        ukuranFile: '512 KB',
        catatanDosen: 'Disetujui. Kumpulkan tugas pengganti minggu depan.',
        diprosesPada: '16 Mei 2026',
        diprosesDosen: 'Santi Sundari',
      ),
    ];

    _rejected = [
      IzinTindakLanjut(
        namaInisial: 'AN',
        namaMahasiswa: 'Ayu Nurfadillah',
        nim: '241511061',
        jenis: 'Izin',
        matkul: 'Pemrograman Mobile',
        tanggal: 'Senin, 18 Mei 2026',
        keterangan: 'Izin acara keluarga yang tidak bisa ditinggalkan.',
        namaFile: 'surat_izin.pdf',
        ukuranFile: '280 KB',
        alasanTolak: 'Alasan tidak cukup kuat. Kehadiran sangat diperlukan karena ada presentasi kelompok.',
        diprosesPada: '18 Mei 2026',
        diprosesDosen: 'Santi Sundari',
      ),
      IzinTindakLanjut(
        namaInisial: 'RF',
        namaMahasiswa: 'Rizky Firmansyah',
        nim: '241511077',
        jenis: 'Sakit',
        matkul: 'Basis Data Lanjut',
        tanggal: 'Selasa, 19 Mei 2026',
        keterangan: 'Tidak enak badan dan tidak bisa hadir ke kampus.',
        namaFile: null,
        ukuranFile: null,
        alasanTolak: 'Tidak melampirkan surat keterangan sakit dari dokter yang valid.',
        diprosesPada: '19 Mei 2026',
        diprosesDosen: 'Santi Sundari',
      ),
    ];
  }

  List<IzinTindakLanjut> get _filteredItems {
    final dateKey = DateFormat('dd MMM yyyy', 'id').format(_selectedDate);
    final source = _tabIndex == 0 ? _approved : _rejected;
    return source.where((e) => e.diprosesPada == dateKey).toList();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _prevDate() {
    setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
  }

  void _nextDate() {
    setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgPage,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final dateDisplay = DateFormat('EEEE, dd MMMM yyyy', 'id').format(_selectedDate);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: const BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
      child: Column(
        children: [
          Row(
            children: [
              CustomBackButton(color: _kAccent),
              const SizedBox(width: 12),
              const Expanded(
                child: Center(
                  child: Text('Tindak Lanjut Izin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 56), // keep centered title (no right action)
            ],
          ),
          const SizedBox(height: 12),

          // Tab container
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(child: _tabPill('✓ Disetujui', 0)),
                const SizedBox(width: 8),
                Expanded(child: _tabPill('✕ Ditolak', 1)),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Date navigator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _prevDate,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_left, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white, size: 13),
                      const SizedBox(width: 8),
                      Text(dateDisplay, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      const Icon(Icons.expand_more, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _nextDate,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_right, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabPill(String label, int index) {
    final selected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kBgPage : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? _kPrimary : Colors.white.withOpacity(0.5),
              fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final items = _filteredItems;
    if (items.isEmpty) {
      return Container(
        color: _kBgPage,
        child: const Center(
          child: Text('Tidak ada data pada tanggal ini', style: TextStyle(color: _kTextMuted)),
        ),
      );
    }

    return Container(
      color: _kBgPage,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final it = items[index];
          return _buildCardItem(it);
        },
      ),
    );
  }

  Widget _buildCardItem(IzinTindakLanjut it) {
    final approved = _tabIndex == 0;
    return Container(
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 2))]),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(color: const Color(0xFF3434A2).withOpacity(0.13), borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text(it.namaInisial, style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 12))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.namaMahasiswa, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _kTextPrimary)),
                          const SizedBox(height: 4),
                          Text(it.nim, style: const TextStyle(fontSize: 11, color: _kTextMuted, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge jenis
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: it.jenis == 'Izin' ? const Color(0xFFFFF8E1) : const Color(0xFFFDECEA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(it.jenis, style: TextStyle(color: it.jenis == 'Izin' ? const Color(0xFFC07000) : const Color(0xFFC0392B), fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
                      child: Text(it.matkul, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563), fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                    Text('· ${it.tanggal}', style: const TextStyle(fontSize: 11, color: _kTextMuted)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('KETERANGAN', style: TextStyle(fontSize: 10, color: _kTextMuted, letterSpacing: 1, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(it.keterangan, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.55)),

                if (it.namaFile != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: const Color(0xFFF6F6F6), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, color: _kTextMuted, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(it.namaFile!, style: const TextStyle(color: _kTextMuted))),
                        if (it.ukuranFile != null) Text(it.ukuranFile!, style: const TextStyle(color: _kTextMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Catatan dosen / alasan penolakan
                if (approved && (it.catatanDosen != null && it.catatanDosen!.isNotEmpty)) ...[
                  Container(
                    decoration: BoxDecoration(color: _kGreenBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kGreenBorder, width: 1.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 28, height: 28, decoration: BoxDecoration(color: _kGreenBg, shape: BoxShape.circle), child: const Icon(Icons.check, color: _kGreen, size: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('CATATAN DOSEN', style: TextStyle(fontSize: 10, color: _kGreen, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(it.catatanDosen!, style: const TextStyle(fontSize: 13, color: Color(0xFF14532D))),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],

                if (!approved && (it.alasanTolak != null && it.alasanTolak!.isNotEmpty)) ...[
                  Container(
                    decoration: BoxDecoration(color: _kRedBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kRedBorder, width: 1.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 28, height: 28, decoration: BoxDecoration(color: _kRedBg, shape: BoxShape.circle), child: const Icon(Icons.close, color: _kRed, size: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('ALASAN PENOLAKAN', style: TextStyle(fontSize: 10, color: _kRed, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(it.alasanTolak!, style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D))),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Divider + status bar
          Container(
            width: double.infinity,
            decoration: BoxDecoration(color: approved ? _kGreenBg : _kRedBg, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)), border: Border(top: BorderSide(color: approved ? _kGreenBorder : _kRedBorder, width: 1))),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: approved ? _kGreen : _kRed, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text('${approved ? 'Disetujui' : 'Ditolak'} oleh ${it.diprosesDosen}', style: TextStyle(color: approved ? _kGreen : _kRed, fontWeight: FontWeight.w700, fontSize: 12))),
                Text(it.diprosesPada, style: const TextStyle(color: _kTextMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
