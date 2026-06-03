import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// Layar admin: assign kaprodi untuk program tertentu.
class AssignKaprodiScreen extends StatefulWidget {
  final User user;
  const AssignKaprodiScreen({super.key, required this.user});

  @override
  State<AssignKaprodiScreen> createState() => _AssignKaprodiScreenState();
}

class _AssignKaprodiScreenState extends State<AssignKaprodiScreen> {
  List<Map<String, dynamic>> _dosenList = [];
  List<Map<String, dynamic>> _kaprodiList = [];
  bool _loading = false;

  // Form state
  String _program = 'D3';
  String? _selectedDosenKode;
  final _passwordCtrl = TextEditingController(text: 'pass123');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _dosenList = await DatabaseService().getAllDosen();
      _kaprodiList = await DatabaseService().getAllKaprodi();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal load: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedDosenKode == null || _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Isi semua field.')));
      return;
    }

    setState(() => _loading = true);
    try {
      final kaprodi = await DatabaseService().assignKaprodi(
        adminId: widget.user.id,
        program: _program,
        dosenKode: _selectedDosenKode!,
        passwordPlain: _passwordCtrl.text,
      );
      if (!mounted) return;

      final passValue = _passwordCtrl.text;

      // Reset form fields
      _passwordCtrl.text = 'pass123';
      setState(() => _selectedDosenKode = null);

      // Load data terbaru
      await _load();

      // Tampilkan Dialog Sukses
      if (mounted) {
        _showSuccessDialog(kaprodi, passValue);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> kaprodi, String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 64),
                  SizedBox(height: 12),
                  Text(
                    'Kaprodi Berhasil Ditugaskan!',
                    style: TextStyle(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Akun Kaprodi:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Plus Jakarta Sans',
                      color: AppColors.grayDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Kode', kaprodi['kode'] ?? '-'),
                  _buildDetailRow('Nama', kaprodi['nama'] ?? '-'),
                  _buildDetailRow('Program', kaprodi['program'] ?? '-'),
                  _buildDetailRow('Email', kaprodi['email'] ?? '-'),
                  _buildDetailRow('Password', password),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFBBF24),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Simpan kredensial ini dan berikan kepada kaprodi.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Plus Jakarta Sans',
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Tutup',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Plus Jakarta Sans',
                color: AppColors.grayMedium.withOpacity(0.8),
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Plus Jakarta Sans',
                color: AppColors.grayDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const TextStyle _labelStyle = TextStyle(
    color: AppColors.grayDark,
    fontSize: 12,
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 1.20,
  );

  static const TextStyle _hintStyle = TextStyle(
    color: Color(0xFF6B7280),
    fontSize: 16,
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w400,
  );

  static const TextStyle _inputStyle = TextStyle(
    color: AppColors.grayDark,
    fontSize: 16,
    fontFamily: 'Plus Jakarta Sans',
    fontWeight: FontWeight.w400,
  );

  OutlineInputBorder _border({Color color = AppColors.grayDark}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(width: 2, color: color),
      );

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: _hintStyle,
      prefixIcon: Icon(
        icon,
        color: AppColors.grayDark,
        size: 20,
      ),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: _border(),
      focusedBorder: _border(color: AppColors.primaryBlue),
      errorBorder: _border(color: Colors.red),
      focusedErrorBorder: _border(color: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildFormSection(),
                          const SizedBox(height: 24),
                          _buildKaprodiList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
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
            'Assign Kaprodi',
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

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Buat Penugasan Baru',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.grayDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text('PROGRAM', style: _labelStyle),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _program,
            style: _inputStyle,
            decoration: _inputDecoration('Pilih Program', Icons.school_outlined),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.grayDark),
            items: const [
              DropdownMenuItem(value: 'D3', child: Text('D3')),
              DropdownMenuItem(value: 'D4', child: Text('D4')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _program = val);
            },
          ),
          const SizedBox(height: 20),

          const Text('DOSEN', style: _labelStyle),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedDosenKode,
            style: _inputStyle,
            decoration: _inputDecoration(
              'Pilih Dosen',
              Icons.person_outline_rounded,
            ),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.grayDark),
            isExpanded: true,
            items: _dosenList.map((d) {
              return DropdownMenuItem(
                value: d['_id']?.toString(),
                child: Text(
                  '${d['_id']} — ${d['nama']}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedDosenKode = v),
          ),
          const SizedBox(height: 20),

          const Text('PASSWORD KAPRODI', style: _labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _passwordCtrl,
            style: _inputStyle,
            decoration: _inputDecoration(
              'Masukkan password',
              Icons.lock_outline_rounded,
            ),
          ),
          const SizedBox(height: 28),

          GestureDetector(
            onTap: _loading ? null : _submit,
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF1E3A8A)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A237E).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Assign Kaprodi',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKaprodiList() {
    if (_kaprodiList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        ),
        child: const Center(
          child: Text(
            'Belum ada kaprodi yang ditugaskan.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grayMedium,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daftar Kaprodi',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.grayDark,
            ),
          ),
          const SizedBox(height: 16),
          ..._kaprodiList.map((kp) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.school,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kp['nama']?.toString() ?? '-',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Plus Jakarta Sans',
                                color: AppColors.grayDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              kp['kode']?.toString() ?? '-',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Plus Jakarta Sans',
                                color: AppColors.grayMedium.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          kp['program']?.toString() ?? '-',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
