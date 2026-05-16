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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal load periode: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal generate template: $e')),
      );
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
      setState(() => _errors = ['CSV minimal harus punya 1 header + 1 baris data.']);
      return;
    }

    final header = lines.first.split(',').map((s) => s.trim()).toList();
    final required = [
      'kodeMK', 'namaMK', 'kelas', 'program', 'kodeDosen',
      'hari', 'jamMulai', 'jamSelesai', 'kodeRuangan', 'tipe',
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
        setState(() => _errors = [
          'Baris ${i + 1}: jumlah kolom tidak cocok dengan header.',
        ]);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih file CSV dulu.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final errs = await DatabaseService().validateJadwalRows(_parsedRows);
      setState(() => _errors = errs);
      if (mounted && errs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua baris valid.')),
        );
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
            'Existing jadwal dengan ID sama akan di-update.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Commit')),
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

  // ─────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      appBar: AppBar(title: const Text('Upload Jadwal (CSV)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Periode tujuan ─────────────────────────────────
            const Text('1. Periode tujuan',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedPeriode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _periodeList.map((p) {
                final aktif = p['aktif'] == true;
                return DropdownMenuItem(
                  value: p['kode']?.toString(),
                  child: Text('${p['kode']}${aktif ? "  (aktif)" : ""}'),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedPeriode = v),
            ),

            const SizedBox(height: 24),

            // ── 2. Download template ──────────────────────────────
            const Text('2. Template CSV',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              'Belum tahu format-nya? Download template berikut, '
              'isi datanya, lalu upload kembali.',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                _csvHeader,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isDownloading ? null : _downloadTemplate,
                icon: _isDownloading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_outlined),
                label: const Text('Download Template CSV'),
              ),
            ),

            const SizedBox(height: 24),

            // ── 3. Pilih file ─────────────────────────────────────
            const Text('3. Pilih file CSV',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickAndParseFile,
                icon: const Icon(Icons.upload_file),
                label: Text(_pickedFileName ?? 'Pilih file dari device'),
              ),
            ),

            const SizedBox(height: 16),

            if (_pickedFileName != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.skyBlue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description, color: AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _pickedFileName!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${_parsedRows.length} baris',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Action buttons ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoading || _parsedRows.isEmpty ? null : _validate,
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Validate'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _parsedRows.isEmpty ? null : _commit,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Commit'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Summary success ───────────────────────────────────
            if (_summaryMsg != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_summaryMsg!,
                          style: const TextStyle(color: Colors.green)),
                    ),
                  ],
                ),
              ),

            // ── Preview rows ──────────────────────────────────────
            if (_parsedRows.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Preview ${_parsedRows.length} baris (max 10):',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: _parsedRows
                      .take(10)
                      .map((r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text(
                              '${r['program']} ${r['kelas']} • ${r['kodeMK']} ${r['namaMK']} '
                              '• ${r['hari']} ${r['jamMulai']}-${r['jamSelesai']} '
                              '• ${r['tipe']} • ${r['kodeDosen']} • ${r['kodeRuangan']}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],

            // ── Errors ────────────────────────────────────────────
            if (_errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Error (${_errors.length}):',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _errors
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $e',
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12)),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
