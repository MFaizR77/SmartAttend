import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/remote/database_service.dart';

/// Mode promosi: semester saja atau kelas + semester.
enum PromosiMode { semester, kelas }

/// Screen admin untuk kenaikan kelas/semester secara batch.
///
/// Dua mode:
///   - **Kenaikan Semester**: kelas tetap, semester naik, auto-enroll jadwal baru.
///   - **Kenaikan Kelas**: kelas berubah + semester naik, auto-enroll jadwal baru.
class KenaikanKelasScreen extends StatefulWidget {
  const KenaikanKelasScreen({super.key});

  @override
  State<KenaikanKelasScreen> createState() => _KenaikanKelasScreenState();
}

class _KenaikanKelasScreenState extends State<KenaikanKelasScreen> {
  final _db = DatabaseService();

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;
  PromosiMode _mode = PromosiMode.semester;

  List<Map<String, dynamic>> _kelasList = [];
  Map<String, dynamic>? _selectedKelas;
  final _kelasBaruCtl = TextEditingController();
  final _semesterBaruCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKelas();
  }

  @override
  void dispose() {
    _kelasBaruCtl.dispose();
    _semesterBaruCtl.dispose();
    super.dispose();
  }

  Future<void> _loadKelas() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final list = await _db.getDistinctKelas();
      setState(() { _kelasList = list; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _selectKelas(Map<String, dynamic> kelas) {
    setState(() => _selectedKelas = kelas);
    final kelasLama = kelas['kelas'] as String;
    final angka = int.tryParse(kelasLama.replaceAll(RegExp(r'[^0-9]'), ''));

    if (_mode == PromosiMode.kelas) {
      // Auto-suggest: 2B → 3B
      final match = RegExp(r'^(\d+)(.*)$').firstMatch(kelasLama);
      if (match != null) {
        _kelasBaruCtl.text = '${int.parse(match.group(1)!) + 1}${match.group(2) ?? ''}';
      }
      if (angka != null) _semesterBaruCtl.text = '${angka * 2 + 1}';
    } else {
      // Kenaikan semester: kelas tetap
      _kelasBaruCtl.text = kelasLama;
      if (angka != null) _semesterBaruCtl.text = '${angka * 2}';
    }
  }

  Future<void> _executePromosi() async {
    if (_selectedKelas == null) return;
    final kelasBaru = _kelasBaruCtl.text.trim();
    final semesterStr = _semesterBaruCtl.text.trim();
    final semesterBaru = semesterStr.isNotEmpty ? int.tryParse(semesterStr) : null;

    if (_mode == PromosiMode.kelas && kelasBaru.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kelas baru harus diisi')),
      );
      return;
    }

    final kelasLama = _selectedKelas!['kelas'] as String;
    final program = _selectedKelas!['program'] as String;
    final jumlah = _selectedKelas!['jumlah'] as int;
    final actualKelasBaru = _mode == PromosiMode.semester ? kelasLama : kelasBaru;

    final modeLabel = _mode == PromosiMode.semester ? 'Kenaikan Semester' : 'Kenaikan Kelas';

    // Confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(modeLabel,
          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_mode == PromosiMode.kelas) ...[
              _infoRow('Kelas', '$kelasLama → $actualKelasBaru'),
            ] else ...[
              _infoRow('Kelas', '$kelasLama (tetap)'),
            ],
            const SizedBox(height: 8),
            if (semesterBaru != null) _infoRow('Semester Baru', '$semesterBaru'),
            const SizedBox(height: 8),
            _infoRow('Program', program),
            const SizedBox(height: 8),
            _infoRow('Jumlah Mahasiswa', '$jumlah orang'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Aksi ini akan mengubah data $jumlah mahasiswa dan otomatis membuat enrollment ke jadwal baru di periode aktif.',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12,
                        fontWeight: FontWeight.w600, color: AppColors.warning.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontFamily: 'Plus Jakarta Sans'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Lanjutkan',
              style: TextStyle(color: Colors.white, fontFamily: 'Plus Jakarta Sans')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      final result = await _db.promosikanKelas(
        kelasLama: kelasLama,
        programFilter: program,
        kelasBaru: actualKelasBaru,
        semesterBaru: semesterBaru,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 28),
            const SizedBox(width: 8),
            const Text('Berhasil!', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _mode == PromosiMode.kelas
                    ? '${result['mahasiswa']} mahasiswa dinaikkan dari $kelasLama ke $actualKelasBaru.'
                    : '${result['mahasiswa']} mahasiswa semester diperbarui (kelas $kelasLama tetap).',
                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14),
              ),
              if ((result['waliDosen'] ?? 0) > 0) ...[
                const SizedBox(height: 8),
                Text('${result['waliDosen']} akun wali dosen diperbarui.',
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, color: AppColors.textSecondary)),
              ],
              if ((result['enrollments'] ?? 0) > 0) ...[
                const SizedBox(height: 8),
                Text('${result['enrollments']} enrollment otomatis dibuat.',
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, color: AppColors.textSecondary)),
              ],
              if ((result['enrollments'] ?? 0) == 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline, color: AppColors.warning, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Belum ada jadwal untuk kelas $actualKelasBaru di periode aktif. Upload jadwal dulu agar enrollment bisa dibuat.',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, color: AppColors.warning.withValues(alpha: 0.9)),
                    )),
                  ]),
                ),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white, fontFamily: 'Plus Jakarta Sans')),
            ),
          ],
        ),
      );

      _selectedKelas = null;
      _kelasBaruCtl.clear();
      _semesterBaruCtl.clear();
      await _loadKelas();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, color: AppColors.textSecondary)),
        Flexible(child: Text(value, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, fontWeight: FontWeight.w700))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Kenaikan Kelas & Semester',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(fontFamily: 'Plus Jakarta Sans')),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _loadKelas, child: const Text('Coba Lagi')),
                ]))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mode selector
                      _buildModeSelector(),
                      const SizedBox(height: 20),

                      // Info banner
                      _buildInfoBanner(),
                      const SizedBox(height: 24),

                      // Step 1: Pilih kelas
                      _buildStepHeader('1', 'Pilih Kelas'),
                      const SizedBox(height: 12),
                      _buildKelasGrid(),

                      // Step 2: Form
                      if (_selectedKelas != null) ...[
                        const SizedBox(height: 28),
                        _buildStepHeader('2', _mode == PromosiMode.kelas
                            ? 'Tentukan Kelas & Semester Baru'
                            : 'Tentukan Semester Baru'),
                        const SizedBox(height: 12),
                        _buildFormCard(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: PromosiMode.values.map((mode) {
          final isActive = _mode == mode;
          final label = mode == PromosiMode.semester ? 'Kenaikan Semester' : 'Kenaikan Kelas';
          final icon = mode == PromosiMode.semester ? Icons.arrow_upward_rounded : Icons.school_rounded;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _mode = mode;
                  _selectedKelas = null;
                  _kelasBaruCtl.clear();
                  _semesterBaruCtl.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive ? [
                    BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2)),
                  ] : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: isActive ? Colors.white : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(label, style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans', fontSize: 13, fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoBanner() {
    final isSemester = _mode == PromosiMode.semester;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: isSemester
            ? [const Color(0xFF0D47A1), const Color(0xFF1976D2)]
            : [const Color(0xFF1A237E), const Color(0xFF1565C0)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(isSemester ? Icons.arrow_upward_rounded : Icons.school_rounded,
              color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isSemester ? 'Kenaikan Semester' : 'Kenaikan Kelas & Semester',
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 4),
            Text(
              isSemester
                  ? 'Kelas tetap, semester naik. Enrollment baru otomatis dibuat untuk jadwal di periode aktif.'
                  : 'Kelas & semester berubah. Mahasiswa, wali dosen, dan enrollment otomatis diperbarui.',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        )),
      ]),
    );
  }

  Widget _buildKelasGrid() {
    if (_kelasList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Text('Tidak ada data kelas.', style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: AppColors.textSecondary))),
      );
    }
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: _kelasList.map((k) {
        final kelas = k['kelas'] as String;
        final program = k['program'] as String;
        final jumlah = k['jumlah'] as int;
        final isSelected = _selectedKelas != null && _selectedKelas!['kelas'] == kelas && _selectedKelas!['program'] == program;
        return GestureDetector(
          onTap: () => _selectKelas(k),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppColors.primaryBlue : AppColors.border, width: isSelected ? 2 : 1),
              boxShadow: isSelected ? [BoxShadow(color: AppColors.primaryBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
            ),
            child: Column(children: [
              Text('$kelas-$program', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.primary)),
              const SizedBox(height: 2),
              Text('$jumlah mhs', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white70 : AppColors.textSecondary)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormCard() {
    final isSemester = _mode == PromosiMode.semester;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(children: [
        // Preview
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _buildKelasChip(
            '${_selectedKelas!['kelas']}-${_selectedKelas!['program']}',
            AppColors.error.withValues(alpha: 0.1), AppColors.error,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward_rounded, color: AppColors.primaryBlue, size: 28),
          ),
          _buildKelasChip(
            _kelasBaruCtl.text.isNotEmpty
                ? '${_kelasBaruCtl.text}-${_selectedKelas!['program']}'
                : '?',
            AppColors.success.withValues(alpha: 0.1), AppColors.success,
          ),
        ]),
        const SizedBox(height: 20),

        // Input kelas baru (hanya untuk mode kelas)
        if (!isSemester) ...[
          TextField(
            controller: _kelasBaruCtl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Kelas Baru', hintText: 'Contoh: 3B',
              labelStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
              prefixIcon: const Icon(Icons.class_rounded),
            ),
            style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 16),
        ],

        // Input semester baru
        TextField(
          controller: _semesterBaruCtl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Semester Baru',
            hintText: isSemester ? 'Contoh: 4' : 'Contoh: 5',
            labelStyle: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
            prefixIcon: const Icon(Icons.format_list_numbered),
          ),
          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 24),

        // Button
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _executePromosi,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              disabledBackgroundColor: AppColors.primaryBlue.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            icon: _isProcessing
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Icon(Icons.upgrade_rounded, color: Colors.white),
            label: Text(
              _isProcessing ? 'Memproses...' : (isSemester ? 'Naikkan Semester' : 'Naikkan Kelas'),
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildStepHeader(String number, String title) {
    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(8)),
        child: Center(child: Text(number, style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans', fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white))),
      ),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
    ]);
  }

  Widget _buildKelasChip(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(
        fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
    );
  }
}
