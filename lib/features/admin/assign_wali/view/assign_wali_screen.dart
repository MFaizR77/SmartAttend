import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// Layar admin: assign wali dosen untuk kelas tertentu.
class AssignWaliScreen extends StatefulWidget {
  final User user;
  const AssignWaliScreen({super.key, required this.user});

  @override
  State<AssignWaliScreen> createState() => _AssignWaliScreenState();
}

class _AssignWaliScreenState extends State<AssignWaliScreen> {
  List<Map<String, dynamic>> _dosenList = [];
  List<Map<String, dynamic>> _waliList = [];
  bool _loading = false;

  // Form state
  final _kelasCtrl = TextEditingController();
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
    _kelasCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _dosenList = await DatabaseService().getAllDosen();
      _waliList = await DatabaseService().getAllWaliDosen();
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
    final kelas = _kelasCtrl.text.trim();
    if (kelas.isEmpty ||
        _selectedDosenKode == null ||
        _passwordCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Isi semua field.')));
      return;
    }

    setState(() => _loading = true);
    try {
      final wali = await DatabaseService().assignWaliDosen(
        adminId: widget.user.id,
        kelas: kelas,
        program: _program,
        dosenKode: _selectedDosenKode!,
        passwordPlain: _passwordCtrl.text,
      );
      if (!mounted) return;

      final passValue = _passwordCtrl.text;

      // Reset form fields
      _kelasCtrl.clear();
      _passwordCtrl.text = 'pass123';
      setState(() => _selectedDosenKode = null);

      // Load data terbaru
      await _load();

      // Tampilkan Dialog Sukses
      if (mounted) {
        _showSuccessDialog(wali, passValue);
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

  void _showSuccessDialog(Map<String, dynamic> wali, String password) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actionsAlignment: MainAxisAlignment.center,
        title: const Text(
          'Penugasan Berhasil!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF2E7D32),
            fontWeight: FontWeight.w800,
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF2E7D32),
              size: 54,
            ),
            const SizedBox(height: 18),
            const Text(
              'Akun Wali Dosen berhasil dibuat dengan kredensial berikut:',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Username (NIP)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${wali['_id']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.grayDark,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        password,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.orange,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: 110,
            height: 40,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
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
            'Assign Wali Dosen',
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

          // ── KELAS ─────────────────────────────────────────────
          const Text('KELAS', style: _labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _kelasCtrl,
            style: _inputStyle,
            decoration: _inputDecoration(
              'Masukkan kelas (mis. 2B, 1A)',
              Icons.class_outlined,
            ),
          ),
          const SizedBox(height: 20),

          // ── PROGRAM ───────────────────────────────────────────
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
            onChanged: (v) => setState(() => _program = v ?? 'D3'),
          ),
          const SizedBox(height: 20),

          // ── DOSEN ─────────────────────────────────────────────
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

          // ── PASSWORD ──────────────────────────────────────────
          const Text('PASSWORD WALI DOSEN', style: _labelStyle),
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

          // Submit Button (Gradient)
          GestureDetector(
            onTap: _submit,
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
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 8),
                    Text(
                      'Assign Wali Dosen',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaliCard(Map<String, dynamic> w) {
    final String id = w['_id']?.toString() ?? '-';
    final String nama = w['nama']?.toString() ?? '-';
    final String kelas = w['kelasWali']?.toString() ?? '-';
    final String program = w['program']?.toString() ?? '-';
    final String pass = w['passwordPlain']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.supervisor_account_rounded,
              color: AppColors.primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    color: AppColors.grayDark,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'NIP: $id',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1D5DB),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pass: $pass',
                      style: const TextStyle(
                        color: AppColors.orange,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
            ),
            child: Text(
              '$kelas-$program',
              style: const TextStyle(
                color: Color(0xFF2E7D32),
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.supervisor_account_outlined,
              color: AppColors.primaryBlue,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada Wali Dosen',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.grayDark,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Gunakan form di atas untuk menugaskan wali dosen.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardSurface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildFormSection(),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daftar Wali Dosen (${_waliList.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Plus Jakarta Sans',
                                color: AppColors.grayDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (_waliList.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withOpacity(
                                    0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Total: ${_waliList.length}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_waliList.isEmpty)
                          _buildEmptyState()
                        else
                          ..._waliList.map((w) => _buildWaliCard(w)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
