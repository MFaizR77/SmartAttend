import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/remote/database_service.dart';

/// Layar admin: list periode akademik + tombol aktivasi + tombol buat baru.
class ManajemenPeriodeScreen extends StatefulWidget {
  final User user;
  const ManajemenPeriodeScreen({super.key, required this.user});

  @override
  State<ManajemenPeriodeScreen> createState() => _ManajemenPeriodeScreenState();
}

class _ManajemenPeriodeScreenState extends State<ManajemenPeriodeScreen> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _list = await DatabaseService().getAllPeriode();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal load: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _aktivasi(String kode) async {
    final konfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actionsAlignment: MainAxisAlignment.center,
        title: const Text(
          'Aktifkan Periode?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
          ),
        ),
        content: Text(
          'Periode "$kode" akan jadi aktif. Periode lain otomatis non-aktif.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        actions: [
          SizedBox(
            width: 110,
            height: 40,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: AppColors.primaryBlue,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            height: 40,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
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
                'Aktifkan',
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
    if (konfirm != true) return;
    try {
      await DatabaseService().setAktifPeriode(kode);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Periode "$kode" diaktifkan.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  Future<void> _buatBaru() async {
    final tahunCtrl = TextEditingController();
    String jenis = 'Ganjil';

    final konfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          actionsAlignment: MainAxisAlignment.center,
          title: const Text(
            'Buat Periode Baru',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tahunCtrl,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Plus Jakarta Sans',
                ),
                decoration: InputDecoration(
                  labelText: 'Tahun ajaran (mis. 2026/2027)',
                  labelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
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
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: jenis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1B1B19),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Plus Jakarta Sans',
                ),
                decoration: InputDecoration(
                  labelText: 'Jenis Semester',
                  labelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
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
                items: const [
                  DropdownMenuItem(value: 'Ganjil', child: Text('Ganjil')),
                  DropdownMenuItem(value: 'Genap', child: Text('Genap')),
                ],
                onChanged: (v) => setStateDialog(() => jenis = v ?? 'Ganjil'),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: 110,
              height: 40,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 110,
              height: 40,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
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
                  'Buat',
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
      ),
    );
    if (konfirm != true) return;
    final tahun = tahunCtrl.text.trim();
    final tahunNorm = tahun.replaceAll('/', '-');
    final kode = '$tahunNorm-$jenis';
    try {
      await DatabaseService().createPeriode(
        kode: kode,
        tahunAjaran: tahun,
        jenis: jenis,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Periode "$kode" dibuat (non-aktif).')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
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
            'Manajemen Periode',
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

  Widget _buildPeriodeCard(Map<String, dynamic> p) {
    final aktif = p['aktif'] == true;
    final String kode = p['kode']?.toString() ?? '-';
    final String tahunAjaran = p['tahunAjaran']?.toString() ?? '-';
    final String jenis = p['jenis']?.toString() ?? '-';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: aktif
              ? const Color(0xFF22C55E).withOpacity(0.2)
              : Colors.black.withOpacity(0.04),
          width: aktif ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: aktif
                ? const Color(0xFF22C55E).withOpacity(0.05)
                : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: aktif
                  ? const Color(0xFF22C55E).withOpacity(0.08)
                  : const Color(0xFF1E3A8A).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.date_range_rounded,
              color: aktif ? const Color(0xFF22C55E) : const Color(0xFF1E3A8A),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kode,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1B1B19),
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      size: 12,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tahunAjaran,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.class_rounded,
                      size: 12,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      jenis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (aktif)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFFFF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD1FAE5)),
              ),
              child: const Text(
                'AKTIF',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF047857),
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            )
          else
            SizedBox(
              height: 36,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E3A8A),
                  side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                onPressed: () => _aktivasi(kode),
                child: const Text(
                  'Aktifkan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF1E3A8A)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _buatBaru,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Periode Baru',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _list.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 64,
                                      color: Colors.grey.withOpacity(0.4),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Belum ada periode akademik',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6B7280),
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Ketuk tombol + di bawah untuk membuat baru.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9CA3AF),
                                        fontFamily: 'Plus Jakarta Sans',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                              itemCount: _list.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) =>
                                  _buildPeriodeCard(_list[i]),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
