import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// Layar admin untuk upload jadwal via CSV file.
///
/// Format kolom (header wajib):
/// kodeMK,namaMK,sks,semester,kelas,program,kodeDosen,hari,jamMulai,jamSelesai,kodeRuangan,tipe
class UploadJadwalScreen extends StatefulWidget {
  final User user;
  const UploadJadwalScreen({super.key, required this.user});

  @override
  State<UploadJadwalScreen> createState() => _UploadJadwalScreenState();
}

class _UploadJadwalScreenState extends State<UploadJadwalScreen> {
  // ── Header & contoh data CSV (template) ────────────────────────────
  static const String _csvHeader =
      'kodeMK,namaMK,sks,semester,kelas,program,kodeDosen,hari,jamMulai,jamSelesai,kodeRuangan,tipe';
  static const List<String> _csvSampleRows = [
    '25IF2117,Pengantar Sistem Informasi,2,4,2B,D3,KO019N,Selasa,08:40,12:20,D105,TE',
    '25IF2118,Pengembangan Perangkat Lunak,2,4,2B,D3,KO006N,Kamis,07:00,08:40,D105,TE',
    '25IF2119,Pengolahan Citra Digital,2,4,2B,D3,KO048N,Kamis,13:00,14:40,D105,TE',
    '25TI2112,Komputer Grafik,2,4,2B,D4,KO013N,Senin,10:40,12:20,D223,TE',
  ];

  String? _selectedPeriode;
  List<Map<String, dynamic>> _periodeList = [];
  List<Map<String, dynamic>> _parsedRows = [];
  List<String> _errors = [];
  String? _pickedFileName;
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _summaryMsg;

  @override
  void initState() {
    super.initState();
    _loadPeriode();
  }

  // ─────────────────────────────────────────────────────
  // PERIODE
  // ─────────────────────────────────────────────────────

  Future<void> _loadPeriode() async {
    setState(() => _isLoading = true);
    try {
      _periodeList = await DatabaseService().getAllPeriode();
      final aktif = _periodeList.firstWhere(
        (p) => p['aktif'] == true,
        orElse: () =>
            _periodeList.isEmpty ? <String, dynamic>{} : _periodeList.first,
      );
      _selectedPeriode = aktif['kode']?.toString();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal load periode: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────
  // DOWNLOAD TEMPLATE CSV
  //   Generate file template dengan header + 4 contoh baris,
  //   simpan ke temp dir, lalu share (user pilih simpan/kirim).
  // ─────────────────────────────────────────────────────

  Future<void> _downloadTemplate() async {
    setState(() => _isDownloading = true);
    try {
      final csv = '$_csvHeader\n${_csvSampleRows.join("\n")}\n';
      final dir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final path = '${dir.path}/template_jadwal_$ts.csv';
      final file = File(path);
      await file.writeAsString(csv);

      if (!mounted) return;

      // Anchor share sheet ke widget context (penting untuk iPad & beberapa iOS).
      final box = context.findRenderObject() as RenderBox?;
      final origin = (box != null && box.hasSize)
          ? (box.localToGlobal(Offset.zero) & box.size)
          : Rect.fromLTWH(0, 0, 100, 100);

      final params = ShareParams(
        files: [XFile(path)],
        text: 'Template Upload Jadwal SmartAttend',
        subject: 'Template Jadwal CSV',
        sharePositionOrigin: origin,
      );
      await SharePlus.instance.share(params);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal generate template: $e')));
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ─────────────────────────────────────────────────────
  // PICK FILE → PARSE
  // ─────────────────────────────────────────────────────

  Future<void> _pickAndParseFile() async {
    setState(() {
      _summaryMsg = null;
      _errors = [];
      _parsedRows = [];
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      _pickedFileName = picked.name;

      String text;
      if (picked.bytes != null) {
        text = utf8.decode(picked.bytes!, allowMalformed: true);
      } else if (picked.path != null) {
        text = await File(picked.path!).readAsString();
      } else {
        setState(() => _errors = ['Tidak bisa baca isi file.']);
        return;
      }

      _parseCsvText(text);
    } catch (e) {
      setState(() => _errors = ['Gagal load file: $e']);
    }
  }

  void _parseCsvText(String text) {
    text = text.trim();
    if (text.isEmpty) {
      setState(() => _errors = ['File kosong.']);
      return;
    }

    final lines = text.split(RegExp(r'\r?\n'));
    if (lines.length < 2) {
      setState(
        () => _errors = ['CSV minimal harus punya 1 header + 1 baris data.'],
      );
      return;
    }

    final header = lines.first.split(',').map((s) => s.trim()).toList();
    final required = [
      'kodeMK',
      'namaMK',
      'kelas',
      'program',
      'kodeDosen',
      'hari',
      'jamMulai',
      'jamSelesai',
      'kodeRuangan',
      'tipe',
    ];
    final missing = required.where((f) => !header.contains(f)).toList();
    if (missing.isNotEmpty) {
      setState(() => _errors = ['Header kurang field: ${missing.join(", ")}']);
      return;
    }

    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(',').map((s) => s.trim()).toList();
      if (parts.length < header.length) {
        setState(
          () => _errors = [
            'Baris ${i + 1}: jumlah kolom tidak cocok dengan header.',
          ],
        );
        return;
      }
      final row = <String, dynamic>{};
      for (var j = 0; j < header.length; j++) {
        row[header[j]] = parts[j];
      }
      rows.add(row);
    }
    setState(() => _parsedRows = rows);
  }

  // ─────────────────────────────────────────────────────
  // VALIDATE & COMMIT
  // ─────────────────────────────────────────────────────

  Future<void> _validate() async {
    if (_parsedRows.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pilih file CSV dulu.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final errs = await DatabaseService().validateJadwalRows(_parsedRows);
      setState(() => _errors = errs);
      if (mounted && errs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Semua baris valid.')));
      }
    } catch (e) {
      setState(() => _errors = ['Validasi gagal: $e']);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _commit() async {
    if (_parsedRows.isEmpty || _selectedPeriode == null) return;
    if (_errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perbaiki error dulu sebelum commit.')),
      );
      return;
    }
    final konfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi commit'),
        content: Text(
          'Akan upsert ${_parsedRows.length} jadwal ke periode "$_selectedPeriode".\n\n'
          'Existing jadwal dengan ID sama akan di-update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Commit'),
          ),
        ],
      ),
    );
    if (konfirm != true) return;

    setState(() => _isLoading = true);
    try {
      final summary = await DatabaseService().commitJadwalRows(
        adminId: widget.user.id,
        periodeKode: _selectedPeriode!,
        rows: _parsedRows,
        fileName: _pickedFileName ?? 'upload',
      );
      setState(() {
        _summaryMsg =
            'Sukses: ${summary['jadwalCreated']} baru, ${summary['jadwalUpdated']} update, ${summary['matkulCreated']} matkul baru.';
        _parsedRows = [];
        _pickedFileName = null;
      });
    } catch (e) {
      setState(() => _errors = ['Commit gagal: $e']);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.29, -0.41),
          end: Alignment(0.71, 1.41),
          colors: [Color(0xFF1A237E), Color(0xFF1E3A8A), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Kembali',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Upload Jadwal Kuliah',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSection({
    required String title,
    required IconData icon,
    required Widget child,
    String? subtitle,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF1E3A8A), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B1B19),
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -- Summary success message --
                    if (_summaryMsg != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFFFF5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD1FAE5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF10B981),
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Unggah Berhasil',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF065F46),
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _summaryMsg!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF047857),
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // -- Errors list --
                    if (_errors.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFEE2E2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Ditemukan ${_errors.length} Masalah',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF991B1B),
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ..._errors
                                .take(8)
                                .map(
                                  (e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '• ',
                                          style: TextStyle(
                                            color: Color(0xFFB91C1C),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            e,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFFB91C1C),
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Plus Jakarta Sans',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            if (_errors.length > 8)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  left: 10,
                                ),
                                child: Text(
                                  '...dan ${_errors.length - 8} masalah lainnya.',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF991B1B),
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    // -- 1. Periode tujuan --
                    _buildCardSection(
                      title: 'Periode Tujuan',
                      icon: Icons.calendar_month_rounded,
                      subtitle:
                          'Pilih periode akademik untuk jadwal yang akan diunggah',
                      child: DropdownButtonFormField<String>(
                        value: _selectedPeriode,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1B1B19),
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                        decoration: InputDecoration(
                          fillColor: const Color(0xFFF9FAFB),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E3A8A),
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: _periodeList.map((p) {
                          final aktif = p['aktif'] == true;
                          return DropdownMenuItem(
                            value: p['kode']?.toString(),
                            child: Text(
                              '${p['kode']}${aktif ? " (Periode Aktif)" : ""}',
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedPeriode = v),
                      ),
                    ),

                    // -- 2. Template CSV --
                    _buildCardSection(
                      title: 'Format Berkas & Template',
                      icon: Icons.description_rounded,
                      subtitle:
                          'Unggah berkas berformat .csv dengan struktur header berikut',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SelectableText(
                                _csvHeader,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Color(0xFF38BDF8),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1E3A8A),
                                side: const BorderSide(
                                  color: Color(0xFF1E3A8A),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _isDownloading
                                  ? null
                                  : _downloadTemplate,
                              icon: _isDownloading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF1E3A8A),
                                            ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.download_rounded,
                                      size: 20,
                                    ),
                              label: const Text(
                                'Download Template CSV',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // -- 3. Pilih file CSV --
                    _buildCardSection(
                      title: 'Pilih Berkas Jadwal',
                      icon: Icons.upload_file_rounded,
                      subtitle: 'Pilih berkas dari penyimpanan perangkat Anda',
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _isLoading ? null : _pickAndParseFile,
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                vertical: 24,
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF1E3A8A).withOpacity(
                                    _pickedFileName != null ? 0.4 : 0.15,
                                  ),
                                  style: BorderStyle.solid,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _pickedFileName != null
                                        ? Icons.insert_drive_file_rounded
                                        : Icons.cloud_upload_rounded,
                                    size: 40,
                                    color: const Color(0xFF1E3A8A),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _pickedFileName ??
                                        'Ketuk untuk memilih file CSV',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _pickedFileName != null
                                          ? const Color(0xFF1A1A1A)
                                          : const Color(0xFF6B7280),
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                  if (_pickedFileName != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '${_parsedRows.length} baris data terdeteksi',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF22C55E),
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Format file: .csv atau .txt',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9CA3AF),
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (_parsedRows.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF1E3A8A,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF1E3A8A),
                                          width: 1.5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: _isLoading ? null : _validate,
                                      icon: const Icon(
                                        Icons.fact_check_outlined,
                                        size: 20,
                                      ),
                                      label: const Text(
                                        'Validasi',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Plus Jakarta Sans',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SizedBox(
                                    height: 48,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient:
                                            _isLoading || _errors.isNotEmpty
                                            ? null
                                            : const LinearGradient(
                                                colors: [
                                                  Color(0xFF1A237E),
                                                  Color(0xFF1E3A8A),
                                                ],
                                              ),
                                        color: _isLoading || _errors.isNotEmpty
                                            ? Colors.grey
                                            : null,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed:
                                            _isLoading || _errors.isNotEmpty
                                            ? null
                                            : _commit,
                                        icon: const Icon(
                                          Icons.cloud_upload_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        label: const Text(
                                          'Commit',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            fontFamily: 'Plus Jakarta Sans',
                                          ),
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

                    // -- 4. Preview rows --
                    if (_parsedRows.isNotEmpty) ...[
                      _buildCardSection(
                        title: 'Pratinjau Data',
                        icon: Icons.preview_rounded,
                        subtitle:
                            'Menampilkan hingga 5 baris pertama dari data yang diproses',
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.04),
                            ),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _parsedRows.length > 5
                                ? 5
                                : _parsedRows.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: Colors.black.withOpacity(0.04),
                            ),
                            itemBuilder: (context, index) {
                              final r = _parsedRows[index];
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            r['namaMK']?.toString() ?? '-',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B1B19),
                                              fontFamily: 'Plus Jakarta Sans',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF1E3A8A,
                                            ).withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            '${r['program'] ?? '-'} ${r['kelas'] ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E3A8A),
                                              fontFamily: 'Plus Jakarta Sans',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          size: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${r['hari'] ?? '-'}, ${r['jamMulai'] ?? '-'} - ${r['jamSelesai'] ?? '-'}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280),
                                            fontFamily: 'Plus Jakarta Sans',
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.room_rounded,
                                          size: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          r['kodeRuangan']?.toString() ?? '-',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280),
                                            fontFamily: 'Plus Jakarta Sans',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
