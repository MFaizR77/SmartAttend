import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodel/user_list_viewmodel.dart';

/// Halaman Admin: Manajemen User â€” list, tambah, dan edit user.
class ManajemenUserScreen extends StatefulWidget {
  const ManajemenUserScreen({super.key});

  @override
  State<ManajemenUserScreen> createState() => _ManajemenUserScreenState();
}

class _ManajemenUserScreenState extends State<ManajemenUserScreen>
    with SingleTickerProviderStateMixin {
  final _vm = UserListViewModel();
  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.toLowerCase().trim()),
    );
    _vm.load();
  }

  @override
  void dispose() {
    _vm.dispose();
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // â”€â”€ Helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> list) {
    if (_query.isEmpty) return list;
    return list.where((u) {
      final id = u['_id']?.toString().toLowerCase() ?? '';
      final nama = u['nama']?.toString().toLowerCase() ?? '';
      return id.contains(_query) || nama.contains(_query);
    }).toList();
  }

  String _initial(String nama) =>
      nama.trim().isEmpty ? '?' : nama.trim()[0].toUpperCase();

  // â”€â”€ Snackbar helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Plus Jakarta Sans')),
      backgroundColor: error ? AppColors.error : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // â”€â”€ Input decoration helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  static const _labelStyle = TextStyle(
    color: AppColors.grayDark,
    fontSize: 12,
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontSize: 14,
          fontFamily: 'Plus Jakarta Sans',
        ),
        prefixIcon: Icon(icon, color: AppColors.grayMedium, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      );

  // â”€â”€ Dialog: Tambah / Edit Mahasiswa â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _showMahasiswaDialog({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final nimCtrl =
        TextEditingController(text: existing?['_id']?.toString() ?? '');
    final namaCtrl =
        TextEditingController(text: existing?['nama']?.toString() ?? '');
    final emailCtrl =
        TextEditingController(text: existing?['email']?.toString() ?? '');
    final passCtrl = TextEditingController();
    final kelasCtrl =
        TextEditingController(text: existing?['kelas']?.toString() ?? '');
    final semCtrl = TextEditingController(
        text: existing?['semester']?.toString() ?? '1');
    String program = existing?['program']?.toString() ?? 'D3';
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.school_rounded,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Edit Mahasiswa' : 'Tambah Mahasiswa',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('NIM', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: nimCtrl,
                          readOnly: isEdit,
                          style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans', fontSize: 14),
                          decoration: _inputDec('Nomor Induk Mahasiswa',
                              Icons.badge_outlined),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        const Text('NAMA', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: namaCtrl,
                          style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans', fontSize: 14),
                          decoration: _inputDec(
                              'Nama lengkap', Icons.person_outline_rounded),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        const Text('EMAIL', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans', fontSize: 14),
                          decoration:
                              _inputDec('Email', Icons.email_outlined),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isEdit
                              ? 'PASSWORD BARU (kosongkan jika tidak diubah)'
                              : 'PASSWORD',
                          style: _labelStyle,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: passCtrl,
                          obscureText: true,
                          style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans', fontSize: 14),
                          decoration: _inputDec(
                              isEdit ? 'Biarkan kosong jika tidak diubah' : 'Password',
                              Icons.lock_outline_rounded),
                          validator: (v) {
                            if (!isEdit &&
                                (v == null || v.trim().isEmpty)) {
                              return 'Wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('KELAS', style: _labelStyle),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: kelasCtrl,
                                    style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 14),
                                    decoration: _inputDec(
                                        'Contoh: 2B', Icons.class_outlined),
                                    validator: (v) => v == null ||
                                            v.trim().isEmpty
                                        ? 'Wajib diisi'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('SEMESTER', style: _labelStyle),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: semCtrl,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 14),
                                    decoration: _inputDec(
                                        '1-8', Icons.format_list_numbered),
                                    validator: (v) {
                                      final n = int.tryParse(v ?? '');
                                      if (n == null || n < 1 || n > 8) {
                                        return '1-8';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text('PROGRAM', style: _labelStyle),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: program,
                          style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: AppColors.grayDark),
                          decoration: _inputDec(
                              'Program', Icons.school_outlined),
                          items: const [
                            DropdownMenuItem(value: 'D3', child: Text('D3')),
                            DropdownMenuItem(value: 'D4', child: Text('D4')),
                          ],
                          onChanged: (v) {
                            if (v != null) setS(() => program = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Batal',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => saving = true);
                      String? err;
                      if (isEdit) {
                        err = await _vm.updateMahasiswa(
                          nim: nimCtrl.text.trim(),
                          nama: namaCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text.trim().isEmpty
                              ? null
                              : passCtrl.text.trim(),
                          kelas: kelasCtrl.text.trim(),
                          program: program,
                          semester: int.parse(semCtrl.text.trim()),
                        );
                      } else {
                        err = await _vm.insertMahasiswa(
                          nim: nimCtrl.text.trim(),
                          nama: namaCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text.trim(),
                          kelas: kelasCtrl.text.trim(),
                          program: program,
                          semester: int.parse(semCtrl.text.trim()),
                        );
                      }
                      setS(() => saving = false);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (err != null) {
                        _showSnack(err, error: true);
                      } else {
                        _showSnack(isEdit
                            ? 'Data mahasiswa berhasil diperbarui'
                            : 'Mahasiswa berhasil ditambahkan');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Simpan' : 'Tambah',
                      style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    nimCtrl.dispose();
    namaCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
    kelasCtrl.dispose();
    semCtrl.dispose();
  }

  // â”€â”€ Dialog: Tambah / Edit Dosen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _showDosenDialog({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final kodeCtrl =
        TextEditingController(text: existing?['_id']?.toString() ?? '');
    final namaCtrl =
        TextEditingController(text: existing?['nama']?.toString() ?? '');
    final emailCtrl =
        TextEditingController(text: existing?['email']?.toString() ?? '');
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF065F46), Color(0xFF10B981)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded,
                          color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? 'Edit Dosen' : 'Tambah Dosen',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('KODE DOSEN', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: kodeCtrl,
                          readOnly: isEdit,
                          style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans', fontSize: 14),
                          decoration: _inputDec(
                              'Contoh: D001', Icons.badge_outlined),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        const Text('NAMA', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: namaCtrl,
                          style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans', fontSize: 14),
                          decoration: _inputDec(
                              'Nama lengkap', Icons.person_outline_rounded),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                        const SizedBox(height: 16),
                        const Text('EMAIL', style: _labelStyle),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans', fontSize: 14),
                          decoration:
                              _inputDec('Email', Icons.email_outlined),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isEdit
                              ? 'PASSWORD BARU (kosongkan jika tidak diubah)'
                              : 'PASSWORD',
                          style: _labelStyle,
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: passCtrl,
                          obscureText: true,
                          style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans', fontSize: 14),
                          decoration: _inputDec(
                              isEdit
                                  ? 'Biarkan kosong jika tidak diubah'
                                  : 'Password',
                              Icons.lock_outline_rounded),
                          validator: (v) {
                            if (!isEdit &&
                                (v == null || v.trim().isEmpty)) {
                              return 'Wajib diisi';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Batal',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setS(() => saving = true);
                      String? err;
                      if (isEdit) {
                        err = await _vm.updateDosen(
                          kode: kodeCtrl.text.trim(),
                          nama: namaCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text.trim().isEmpty
                              ? null
                              : passCtrl.text.trim(),
                        );
                      } else {
                        err = await _vm.insertDosen(
                          kode: kodeCtrl.text.trim(),
                          nama: namaCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          password: passCtrl.text.trim(),
                        );
                      }
                      setS(() => saving = false);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (err != null) {
                        _showSnack(err, error: true);
                      } else {
                        _showSnack(isEdit
                            ? 'Data dosen berhasil diperbarui'
                            : 'Dosen berhasil ditambahkan');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isEdit ? 'Simpan' : 'Tambah',
                      style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );

    kodeCtrl.dispose();
    namaCtrl.dispose();
    emailCtrl.dispose();
    passCtrl.dispose();
  }


  // â”€â”€ FAB: show add dialog based on current tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // FAB hanya muncul di tab Mahasiswa (0) dan Dosen (1)
  void _onFabTap() {
    switch (_tabCtrl.index) {
      case 0:
        _showMahasiswaDialog();
        break;
      case 1:
        _showDosenDialog();
        break;
    }
  }

  // ── Delete confirmation ─────────────────────────────────────────────────────

  Future<void> _confirmDelete({
    required String title,
    required String nama,
    required String id,
    required Future<String?> Function() onDelete,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda yakin ingin menghapus:',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.grayMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$nama ($id)',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Data yang dihapus tidak dapat dikembalikan.',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(fontFamily: 'Plus Jakarta Sans')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hapus', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final err = await onDelete();
    if (err != null) {
      _showSnack(err, error: true);
    } else {
      _showSnack('$nama berhasil dihapus');
    }
  }

  // ── Upload Excel ────────────────────────────────────────────────────────────

  // Headers untuk template Excel Mahasiswa
  static const List<String> _mhsHeaders = ['nim', 'nama', 'email', 'password', 'kelas', 'program', 'semester'];
  static const List<List<String>> _mhsSampleRows = [
    ['2201001', 'Andi Pratama', 'andi@email.com', 'pass123', '2B', 'D3', '4'],
    ['2201002', 'Budi Santoso', 'budi@email.com', 'pass123', '2A', 'D4', '4'],
    ['2201003', 'Citra Dewi', 'citra@email.com', 'pass123', '1A', 'D3', '2'],
  ];

  // Headers untuk template Excel Dosen
  static const List<String> _dosenHeaders = ['kode', 'nama', 'email', 'password'];
  static const List<List<String>> _dosenSampleRows = [
    ['KO001N', 'Dr. Ahmad Fauzi', 'ahmad@email.com', 'pass123'],
    ['KO002N', 'Ir. Budi Wijaya', 'budi.w@email.com', 'pass123'],
    ['KO003N', 'Prof. Citra Sari', 'citra.s@email.com', 'pass123'],
  ];

  Future<void> _downloadTemplate(String type) async {
    setState(() {});
    try {
      final excel = xls.Excel.createExcel();
      final sheet = excel['Sheet1'];

      final headers = type == 'mahasiswa' ? _mhsHeaders : _dosenHeaders;
      final samples = type == 'mahasiswa' ? _mhsSampleRows : _dosenSampleRows;

      // Write headers
      for (var i = 0; i < headers.length; i++) {
        sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
            xls.TextCellValue(headers[i]);
      }

      // Write sample rows
      for (var r = 0; r < samples.length; r++) {
        for (var c = 0; c < samples[r].length; c++) {
          sheet.cell(xls.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1)).value =
              xls.TextCellValue(samples[r][c]);
        }
      }

      // Remove default Sheet1 if extra sheets exist
      if (excel.sheets.containsKey('Sheet1') && excel.sheets.length > 1) {
        excel.delete('Sheet1');
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Gagal encode Excel');

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'template_${type}_upload.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Template Upload ${type == 'mahasiswa' ? 'Mahasiswa' : 'Dosen'}');
    } catch (e) {
      _showSnack('Gagal download template: $e', error: true);
    }
  }

  Future<void> _pickAndUploadExcel(String type) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.single.path;
    if (filePath == null) return;

    try {
      final bytes = File(filePath).readAsBytesSync();
      final excel = xls.Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.rows.isEmpty) {
        _showSnack('File Excel kosong.', error: true);
        return;
      }

      // Parse header row
      final headerRow = sheet.rows.first;
      final headers = headerRow.map((c) => c?.value?.toString().trim().toLowerCase() ?? '').toList();

      // Validate headers
      final expectedHeaders = type == 'mahasiswa' ? _mhsHeaders : _dosenHeaders;
      final missingHeaders = expectedHeaders.where((h) => !headers.contains(h)).toList();
      if (missingHeaders.isNotEmpty) {
        _showSnack('Kolom tidak lengkap: ${missingHeaders.join(", ")}', error: true);
        return;
      }

      // Parse data rows
      final List<Map<String, dynamic>> rows = [];
      for (var i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        final Map<String, dynamic> map = {};
        bool isEmpty = true;
        for (var j = 0; j < headers.length; j++) {
          final val = j < row.length ? (row[j]?.value?.toString().trim() ?? '') : '';
          if (val.isNotEmpty) isEmpty = false;
          map[headers[j]] = val;
        }
        if (!isEmpty) rows.add(map);
      }

      if (rows.isEmpty) {
        _showSnack('Tidak ada data di file Excel.', error: true);
        return;
      }

      // Show confirmation dialog
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Upload ${type == 'mahasiswa' ? 'Mahasiswa' : 'Dosen'}',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Ditemukan ${rows.length} baris data dari file "${result.files.single.name}".\n\nData yang sudah ada (berdasarkan ${type == 'mahasiswa' ? 'NIM' : 'Kode'}) akan di-update.\n\nLanjutkan?',
            style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Upload'),
            ),
          ],
        ),
      );

      if (confirm != true || !mounted) return;

      // Do the upload
      String? err;
      if (type == 'mahasiswa') {
        err = await _vm.bulkInsertMahasiswa(rows);
      } else {
        err = await _vm.bulkInsertDosen(rows);
      }

      if (err != null) {
        _showSnack('Gagal upload: $err', error: true);
      } else {
        _showSnack('${rows.length} ${type == 'mahasiswa' ? 'mahasiswa' : 'dosen'} berhasil di-upload');
      }
    } catch (e) {
      _showSnack('Gagal parsing file: $e', error: true);
    }
  }

  void _showUploadOptions() {
    final type = _tabCtrl.index == 0 ? 'mahasiswa' : 'dosen';
    final label = type == 'mahasiswa' ? 'Mahasiswa' : 'Dosen';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Data $label',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload file Excel (.xlsx) untuk menambahkan data $label secara massal.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: AppColors.grayMedium,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Format kolom wajib:',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF166534),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type == 'mahasiswa'
                        ? 'nim | nama | email | password | kelas | program | semester'
                        : 'kode | nama | email | password',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _downloadTemplate(type);
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download Template'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppColors.primaryBlue),
                      foregroundColor: AppColors.primaryBlue,
                      textStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _pickAndUploadExcel(type);
                    },
                    icon: const Icon(Icons.upload_file_rounded, size: 18),
                    label: const Text('Pilih File'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildHeader(
    List<Map<String, dynamic>> mhs,
    List<Map<String, dynamic>> dos,
    List<Map<String, dynamic>> wali,
    List<Map<String, dynamic>> kp,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
          const Text(
            'Manajemen\nPengguna',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 28,
              height: 1.1,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatChip(Icons.school_rounded,
                    '${mhs.length} Mahasiswa', const Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                _buildStatChip(Icons.person_rounded,
                    '${dos.length} Dosen', const Color(0xFF10B981)),
                const SizedBox(width: 8),
                _buildStatChip(Icons.supervisor_account_rounded,
                    '${wali.length} Wali Dosen', const Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                _buildStatChip(Icons.school_rounded,
                    '${kp.length} Kaprodi', const Color(0xFF8B5CF6)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Tab bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildTabBar(int mhsCount, int dosCount, int waliCount, int kpCount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        labelColor: Colors.black,
        unselectedLabelColor: const Color(0xFF6B7280),
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          fontFamily: 'Plus Jakarta Sans',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'Plus Jakarta Sans',
        ),
        tabs: [
          _buildTab('Mahasiswa', mhsCount, const Color(0xFF3B82F6)),
          _buildTab('Dosen', dosCount, const Color(0xFF10B981)),
          _buildTab('Wali', waliCount, const Color(0xFFF59E0B)),
          _buildTab('Kaprodi', kpCount, const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Tab _buildTab(String label, int count, Color badgeColor) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Plus Jakarta Sans',
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Search bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(
          fontSize: 13.5,
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Cari nama atau ID / NIM...',
          hintStyle: const TextStyle(
            color: AppColors.grayLight,
            fontSize: 13,
            fontFamily: 'Plus Jakarta Sans',
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: AppColors.grayLight),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.grayLight),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: Colors.black.withOpacity(0.07), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppColors.primaryBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  // â”€â”€ Sort banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€


  // ── Upload banner ───────────────────────────────────────────────────────────

  Widget _buildUploadBanner(String type) {
    final label = type == 'mahasiswa' ? 'Mahasiswa' : 'Dosen';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: GestureDetector(
        onTap: _showUploadOptions,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  size: 18,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload via Table Excel',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: Color(0xFF166534),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Import data $label dari file .xlsx',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF059669),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortBanner(int count, String sortDesc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Row(
        children: [
          const Icon(Icons.sort_rounded, size: 13, color: AppColors.grayLight),
          const SizedBox(width: 4),
          Text(
            sortDesc,
            style: const TextStyle(
              color: AppColors.grayLight,
              fontSize: 11.5,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            '$count data',
            style: const TextStyle(
              color: AppColors.grayLight,
              fontSize: 11.5,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Shared chip helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _chip(String label, Color bg, Color border, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          fontFamily: 'Plus Jakarta Sans',
        ),
      ),
    );
  }

  // â”€â”€ Base user card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _userCard({
    required Color avatarColor,
    required Color avatarBg,
    required String initial,
    required Widget chips,
    required String idLabel,
    required String idValue,
    required String nama,
    String? subInfo,
    IconData? subIcon,
    VoidCallback? onEdit, // null = read-only, no edit button
    VoidCallback? onDelete, // null = no delete button
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(color: avatarBg, shape: BoxShape.circle),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  color: avatarColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    chips,
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.black.withOpacity(0.06)),
                      ),
                      child: Text(
                        '$idLabel: $idValue',
                        style: const TextStyle(
                          color: AppColors.graySlate,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  nama,
                  style: const TextStyle(
                    color: AppColors.grayDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subInfo != null && subInfo.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(subIcon ?? Icons.info_outline,
                          size: 12, color: AppColors.grayLight),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subInfo,
                          style: const TextStyle(
                            color: AppColors.grayLight,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Edit button â€” only shown when onEdit is provided
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_rounded,
                    size: 16, color: AppColors.primaryBlue),
              ),
            ),
          if (onDelete != null) const SizedBox(width: 6),
          // Delete button
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  // â”€â”€ Card builders â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildMahasiswaCard(Map<String, dynamic> m) {
    final nim = m['_id']?.toString() ?? '-';
    final nama = m['nama']?.toString() ?? '-';
    final kelas = m['kelas']?.toString() ?? '';
    final prog = m['program']?.toString() ?? '';
    final sem = m['semester']?.toString() ?? '-';
    final email = m['email']?.toString() ?? '';

    return _userCard(
      avatarColor: const Color(0xFF3B82F6),
      avatarBg: const Color(0xFFDBEAFE),
      initial: _initial(nama),
      chips: Row(
        children: [
          if (kelas.isNotEmpty)
            _chip(
              '$kelas${prog.isNotEmpty ? '-$prog' : ''}',
              const Color(0xFFDBEAFE),
              const Color(0xFFBFDBFE),
              const Color(0xFF1D4ED8),
            ),
          if (kelas.isNotEmpty) const SizedBox(width: 6),
          _chip('Sem $sem', const Color(0xFFECFDF5), const Color(0xFFA7F3D0),
              const Color(0xFF065F46)),
        ],
      ),
      idLabel: 'NIM',
      idValue: nim,
      nama: nama,
      subInfo: email.isNotEmpty ? email : null,
      subIcon: email.isNotEmpty ? Icons.email_outlined : null,
      onEdit: () => _showMahasiswaDialog(existing: m),
      onDelete: () => _confirmDelete(
        title: 'Hapus Mahasiswa',
        nama: nama,
        id: nim,
        onDelete: () => _vm.deleteMahasiswa(nim),
      ),
    );
  }

  Widget _buildDosenCard(Map<String, dynamic> d) {
    final kode = d['_id']?.toString() ?? '-';
    final nama = d['nama']?.toString() ?? '-';
    final email = d['email']?.toString() ?? '';

    return _userCard(
      avatarColor: const Color(0xFF10B981),
      avatarBg: const Color(0xFFD1FAE5),
      initial: _initial(nama),
      chips: _chip('DOSEN', const Color(0xFFD1FAE5), const Color(0xFFA7F3D0),
          const Color(0xFF065F46)),
      idLabel: 'Kode',
      idValue: kode,
      nama: nama,
      subInfo: email.isNotEmpty ? email : null,
      subIcon: email.isNotEmpty ? Icons.email_outlined : null,
      onEdit: () => _showDosenDialog(existing: d),
      onDelete: () => _confirmDelete(
        title: 'Hapus Dosen',
        nama: nama,
        id: kode,
        onDelete: () => _vm.deleteDosen(kode),
      ),
    );
  }

  Widget _buildWaliCard(Map<String, dynamic> w) {
    final id = w['_id']?.toString() ?? '-';
    final nama = w['nama']?.toString() ?? '-';
    final kelasWali = w['kelasWali']?.toString() ?? '';
    final program = w['program']?.toString() ?? '';

    return _userCard(
      avatarColor: const Color(0xFFF59E0B),
      avatarBg: const Color(0xFFFEF3C7),
      initial: _initial(nama),
      chips: _chip(
        kelasWali.isEmpty
            ? 'WALI DOSEN'
            : 'Wali $kelasWali${program.isNotEmpty ? '-$program' : ''}',
        const Color(0xFFFEF3C7),
        const Color(0xFFFDE68A),
        const Color(0xFF92400E),
      ),
      idLabel: 'ID',
      idValue: id,
      nama: nama,
      subInfo: null,
      subIcon: null,
      onEdit: null, // read-only
    );
  }

  // â”€â”€ Empty state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildEmpty(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded,
              size: 56, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€ Tab views â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildMahasiswaTab(List<Map<String, dynamic>> list) {
    final filtered = _filter(list);
    return Column(
      children: [
        _buildUploadBanner('mahasiswa'),
        _buildSortBanner(
            filtered.length, 'Diurutkan: NIM terkecil â†’ terbesar'),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty(_query.isEmpty
                  ? 'Belum ada data mahasiswa.'
                  : 'Tidak ditemukan "$_query".')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildMahasiswaCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildDosenTab(List<Map<String, dynamic>> list) {
    final filtered = _filter(list);
    return Column(
      children: [
        _buildUploadBanner('dosen'),
        _buildSortBanner(filtered.length, 'Diurutkan: Kode Dosen A â†’ Z'),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty(_query.isEmpty
                  ? 'Belum ada data dosen.'
                  : 'Tidak ditemukan "$_query".')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildDosenCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildWaliTab(List<Map<String, dynamic>> list) {
    final filtered = _filter(list);
    return Column(
      children: [
        _buildSortBanner(
            filtered.length, 'Diurutkan: ID terkecil â†’ terbesar'),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty(_query.isEmpty
                  ? 'Belum ada data wali dosen.'
                  : 'Tidak ditemukan "$_query".')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildWaliCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildKaprodiTab(List<Map<String, dynamic>> list) {
    final filtered = _filter(list);
    return Column(
      children: [
        _buildSortBanner(
            filtered.length, 'Diurutkan: ID terkecil → terbesar'),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmpty(_query.isEmpty
                  ? 'Belum ada data kaprodi.'
                  : 'Tidak ditemukan "$_query".')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _buildKaprodiCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildKaprodiCard(Map<String, dynamic> k) {
    final id = k['_id']?.toString() ?? '-';
    final nama = k['nama']?.toString() ?? '-';
    final program = k['program']?.toString() ?? '';

    return _userCard(
      avatarColor: const Color(0xFF8B5CF6),
      avatarBg: const Color(0xFFEDE9FE),
      initial: _initial(nama),
      chips: _chip(
        program.isEmpty ? 'KAPRODI' : 'Kaprodi $program',
        const Color(0xFFEDE9FE),
        const Color(0xFFDDD6FE),
        const Color(0xFF6D28D9),
      ),
      idLabel: 'ID',
      idValue: id,
      nama: nama,
      subInfo: program.isNotEmpty ? 'Program $program' : null,
      subIcon: program.isNotEmpty ? Icons.school_outlined : null,
      onEdit: null,
      onDelete: null,
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _vm.isLoading,
      builder: (_, loading, __) =>
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _vm.mahasiswa,
            builder: (_, mhs, __) =>
                ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: _vm.dosen,
                  builder: (_, dos, __) =>
                      ValueListenableBuilder<List<Map<String, dynamic>>>(
                        valueListenable: _vm.waliDosen,
                        builder: (_, wali, __) =>
                            ValueListenableBuilder<List<Map<String, dynamic>>>(
                              valueListenable: _vm.kaprodi,
                              builder: (_, kp, __) => Scaffold(
                          backgroundColor: const Color(0xFFF8F9FA),
                          floatingActionButton: ListenableBuilder(
                            listenable: _tabCtrl,
                            builder: (_, __) => _tabCtrl.index >= 2
                                ? const SizedBox.shrink()
                                : FloatingActionButton.extended(
                                    heroTag: 'add_fab',
                                    onPressed: _onFabTap,
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    icon: const Icon(Icons.person_add_rounded),
                                    label: const Text(
                                      'Tambah',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                          ),
                          body: Column(
                            children: [
                              _buildHeader(mhs, dos, wali, kp),
                              _buildTabBar(
                                _filter(mhs).length,
                                _filter(dos).length,
                                _filter(wali).length,
                                _filter(kp).length,
                              ),
                              _buildSearchBar(),
                              Expanded(
                                child: loading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primaryBlue,
                                        ),
                                      )
                                    : ValueListenableBuilder<String?>(
                                        valueListenable: _vm.errorMessage,
                                        builder: (_, err, __) {
                                          if (err != null) {
                                            return Center(
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(32),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.error_outline,
                                                      color: AppColors.error,
                                                      size: 48,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      err,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        color: AppColors.error,
                                                        fontFamily:
                                                            'Plus Jakarta Sans',
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    TextButton.icon(
                                                      onPressed: _vm.load,
                                                      icon: const Icon(
                                                          Icons.refresh),
                                                      label: const Text(
                                                        'Coba Lagi',
                                                        style: TextStyle(
                                                          fontFamily:
                                                              'Plus Jakarta Sans',
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }
                                          return TabBarView(
                                            controller: _tabCtrl,
                                            children: [
                                              _buildMahasiswaTab(mhs),
                                              _buildDosenTab(dos),
                                              _buildWaliTab(wali),
                                              _buildKaprodiTab(kp),
                                            ],
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ),
              ),
          ),
    );
  }
}