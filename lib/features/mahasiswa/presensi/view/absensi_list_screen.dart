import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../../../data/local/models/record_presensi.dart';
import '../../../../data/local/hive_helper.dart';
import '../../../../data/remote/database_service.dart';

class AbsensiListScreen extends StatefulWidget {
  final User user;

  const AbsensiListScreen({super.key, required this.user});

  @override
  State<AbsensiListScreen> createState() => _AbsensiListScreenState();
}

class _AbsensiListScreenState extends State<AbsensiListScreen> {
  List<Map<String, dynamic>> _jadwalHariIni = [];
  bool _isLoading = true;
  String? _error;

  // Per-jadwal state
  final Map<String, bool> _isHadir = {};
  final Map<String, bool> _isSubmitting = {};
  final Map<String, bool> _isKelasBuka = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final kelas = widget.user.kelas ?? '';
      if (kelas.isEmpty) throw Exception('Data kelas tidak ditemukan.');

      // 1. Ambil jadwal reguler
      final reguler = await DatabaseService().getJadwalMahasiswa(kelas);

      // 2. Ambil jadwal pengganti yang sudah disetujui
      final pengganti =
          await DatabaseService().getJadwalPenggantiMahasiswa(kelas);

      // 3. Gabungkan dan petakan (map) agar formatnya seragam
      final List<Map<String, dynamic>> gabungan = [];

      // Masukkan reguler
      gabungan.addAll(reguler);

      // Masukkan pengganti (dengan pemetaan field)
      for (var p in pengganti) {
        gabungan.add({
          '_id': p['_id'],
          'namaMK': p['namaMK'] ?? 'Mata Kuliah (Pengganti)',
          'tipe': 'Pengganti',
          'jamMulai': p['jamMulaiPengganti'] ?? '',
          'jamSelesai': p['jamSelesaiPengganti'] ?? '',
          'ruangan': p['ruanganPengganti'] ?? '',
          'dosenId': p['dosenId'] ?? '',
          'isPengganti': true,
        });
      }

      // 4. Urutkan berdasarkan jam mulai
      gabungan.sort(
        (a, b) => (a['jamMulai'] as String? ?? '').compareTo(
          b['jamMulai'] as String? ?? '',
        ),
      );

      if (!mounted) return;
      setState(() {
        _jadwalHariIni = gabungan;
        _isLoading = false;
      });

      // Check status presensi & kelas untuk setiap jadwal secara paralel
      for (final j in gabungan) {
        final id = j['_id']?.toString() ?? '';
        if (id.isEmpty) continue;
        _checkStatus(id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _checkStatus(String jadwalId) async {
    try {
      // Cek kelas buka dari laporan_dosen
      final buka = await DatabaseService().isKelasBerjalan(jadwalId);
      if (!mounted) return;
      setState(() => _isKelasBuka[jadwalId] = buka);

      // Cek sudah hadir (lokal dulu, lalu online)
      final presensiBox = HiveHelper.recordPresensiBoxInstance;
      final now = DateTime.now();
      final localHadir = presensiBox.values.any(
        (r) =>
            r.sesiId == jadwalId &&
            r.mahasiswaId == widget.user.id &&
            r.timestamp.day == now.day &&
            r.timestamp.month == now.month &&
            r.timestamp.year == now.year,
      );

      if (localHadir) {
        if (!mounted) return;
        setState(() => _isHadir[jadwalId] = true);
        return;
      }

      final online = await ConnectivityService().checkNow();
      if (online) {
        final exists = await DatabaseService().checkPresensiExists(
          jadwalId,
          widget.user.id,
        );
        if (!mounted) return;
        setState(() => _isHadir[jadwalId] = exists);
      }
    } catch (_) {}
  }

  Future<void> _doCheckIn(String jadwalId) async {
    if (_isSubmitting[jadwalId] == true) return;

    // Re-check status kelas dari server sebelum submit (agar tidak stale)
    try {
      final buka = await DatabaseService().isKelasBerjalan(jadwalId);
      if (mounted) setState(() => _isKelasBuka[jadwalId] = buka);
    } catch (_) {}

    if (_isKelasBuka[jadwalId] != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Absen ditolak: Sesi kelas belum dibuka atau sudah diakhiri oleh dosen.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting[jadwalId] = true);

    try {
      final isOnline = await ConnectivityService().checkNow();

      final record = RecordPresensi(
        clientUuid: const Uuid().v4(),
        sesiId: jadwalId,
        mahasiswaId: widget.user.id,
        timestamp: DateTime.now(),
        statusHadir: true,
        metode: 'manual',
        syncStatus: isOnline ? 'synced' : 'pending',
      );

      if (isOnline) {
        await DatabaseService().insertRecordPresensi(record.toMap());
      }
      final box = HiveHelper.recordPresensiBoxInstance;
      await box.put(record.clientUuid, record);

      if (!mounted) return;
      setState(() {
        _isHadir[jadwalId] = true;
        _isSubmitting[jadwalId] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isOnline
                ? '✅ Presensi berhasil disimpan!'
                : '📶 Presensi offline dicatat, akan disinkronkan.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting[jadwalId] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan presensi: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Tentukan apakah jadwal sedang berlangsung berdasarkan waktu
  bool _isBerlangsung(Map<String, dynamic> jadwal) {
    final now = DateTime.now();
    try {
      final mulaiParts = (jadwal['jamMulai'] as String).split(':');
      final selesaiParts = (jadwal['jamSelesai'] as String).split(':');
      final mulai = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(mulaiParts[0]),
        int.parse(mulaiParts[1]),
      );
      final selesai = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(selesaiParts[0]),
        int.parse(selesaiParts[1]),
      );
      final bolehMulai = mulai.subtract(const Duration(minutes: 15));
      return !now.isBefore(bolehMulai) && now.isBefore(selesai);
    } catch (_) {
      return false;
    }
  }

  bool _isSelesai(Map<String, dynamic> jadwal) {
    final now = DateTime.now();
    try {
      final selesaiParts = (jadwal['jamSelesai'] as String).split(':');
      final selesai = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(selesaiParts[0]),
        int.parse(selesaiParts[1]),
      );
      return now.isAfter(selesai);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(dateStr),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String dateStr) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.29, -0.41),
          end: Alignment(0.71, 1.41),
          colors: [Color(0xFF1A237E), Color(0xFF1E3A8A), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Presensi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white.withOpacity(0.20)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF69F0AE),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: const [
                      BoxShadow(color: Color(0xFF69F0AE), blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 12,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1A237E)),
      );
    }
    if (_error != null) return _buildErrorState();
    if (_jadwalHariIni.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      color: AppColors.primaryBlue,
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          // ── Active / upcoming class cards ──
          ..._jadwalHariIni.map((jadwal) {
            final id = jadwal['_id']?.toString() ?? '';
            final berlangsung = _isBerlangsung(jadwal);
            if (berlangsung) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildActiveCard(jadwal, id),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSimpleCard(jadwal, id),
            );
          }),
        ],
      ),
    );
  }

  // ── Big card for current / active class ──────────────────────────────────
  Widget _buildActiveCard(Map<String, dynamic> jadwal, String id) {
    final namaMK = jadwal['namaMK']?.toString() ?? '-';
    final tipe = jadwal['tipe']?.toString() ?? '';
    final jamMulai = jadwal['jamMulai']?.toString() ?? '-';
    final jamSelesai = jadwal['jamSelesai']?.toString() ?? '-';
    final ruangan = jadwal['ruangan']?.toString() ?? '-';
    final dosenId = jadwal['dosenId']?.toString() ?? '-';
    final hadir = _isHadir[id] ?? false;
    final submitting = _isSubmitting[id] ?? false;
    final kelasBuka = _isKelasBuka[id];

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment(0.08, -0.12),
          end: Alignment(0.92, 1.12),
          colors: [Color(0xFF1A237E), Color(0xFF1565C0)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x591A237E),
            blurRadius: 28,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge — dynamic berdasarkan kelasBuka
          Builder(
            builder: (_) {
              final buka = kelasBuka;
              String badgeLabel;
              Color badgeColor;
              Color badgeBorder;
              if (buka == true) {
                badgeLabel = 'BERLANGSUNG';
                badgeColor = const Color(0xFF69F0AE);
                badgeBorder = const Color(0x5969F0AE);
              } else {
                badgeLabel = 'BELUM DIMULAI';
                badgeColor = const Color(0xFFFFB74D);
                badgeBorder = const Color(0x59FFB74D);
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.18),
                  border: Border.all(color: badgeBorder),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radio_button_on, size: 6, color: badgeColor),
                    const SizedBox(width: 8),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10.5,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Mata kuliah
          Text(
            tipe.isNotEmpty ? '$namaMK ($tipe)' : namaMK,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),

          // Jam & Ruangan
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                '$jamMulai – $jamSelesai',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12.5,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.location_on, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                ruangan,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 12.5,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white54, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dosenId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Attendance status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: hadir
                  ? const Color(0x2D69F0AE)
                  : Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  hadir ? Icons.check_circle : Icons.info_outline,
                  color: hadir ? const Color(0xFF69F0AE) : Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  hadir
                      ? 'Anda sudah tercatat hadir'
                      : 'Belum melakukan absensi',
                  style: TextStyle(
                    color: hadir ? const Color(0xFF69F0AE) : Colors.white70,
                    fontSize: 13,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Warning jika dosen belum membuka sesi
          if (!hadir && kelasBuka != true) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    color: Colors.orange,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Menunggu dosen membuka sesi kelas',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Check-in button — hanya muncul jika kelas sudah dibuka dosen
          if (!hadir && kelasBuka == true) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: submitting ? null : () => _doCheckIn(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: submitting
                      ? Colors.white.withOpacity(0.6)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (submitting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1A237E),
                        ),
                      )
                    else
                      const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF1A237E),
                        size: 20,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      submitting ? 'Menyimpan...' : 'Tandai Hadir Sekarang',
                      style: const TextStyle(
                        color: Color(0xFF1A237E),
                        fontSize: 15,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Simple card for past / upcoming classes ────────────────────────────
  Widget _buildSimpleCard(Map<String, dynamic> jadwal, String id) {
    final namaMK = jadwal['namaMK']?.toString() ?? '-';
    final tipe = jadwal['tipe']?.toString() ?? '';
    final jamMulai = jadwal['jamMulai']?.toString() ?? '-';
    final jamSelesai = jadwal['jamSelesai']?.toString() ?? '-';
    final ruangan = jadwal['ruangan']?.toString() ?? '-';
    final selesai = _isSelesai(jadwal);
    final hadir = _isHadir[id] ?? false;

    Color statusBg;
    Color statusFg;
    String statusLabel;
    if (selesai) {
      statusBg = const Color(0xFFF3F4F6);
      statusFg = const Color(0xFF9CA3AF);
      statusLabel = hadir ? '✓ Hadir' : 'Selesai';
    } else {
      statusBg = const Color(0xFFEEF2FF);
      statusFg = const Color(0xFF3949AB);
      statusLabel = 'Upcoming';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                jamMulai,
                style: const TextStyle(
                  color: Color(0xFF1A237E),
                  fontSize: 13,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                jamSelesai,
                style: const TextStyle(
                  color: Color(0xFFA0AAB4),
                  fontSize: 10.5,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 2,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0F5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tipe.isNotEmpty ? '$namaMK ($tipe)' : namaMK,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1A2030),
                    fontSize: 13.5,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ruangan,
                  style: const TextStyle(
                    color: Color(0xFFA0AAB4),
                    fontSize: 11.5,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusFg,
                fontSize: 10.5,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 72,
            color: AppColors.border,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada jadwal hari ini',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nikmati hari liburmu 🎉',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontFamily: 'Plus Jakarta Sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 72,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat jadwal',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
