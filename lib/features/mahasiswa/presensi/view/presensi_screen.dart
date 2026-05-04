import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../viewmodel/presensi_viewmodel.dart';
import 'package:intl/intl.dart';

class PresensiScreen extends StatefulWidget {
  final Map<String, String> jadwal;
  final User user;

  const PresensiScreen({
    super.key,
    required this.jadwal,
    required this.user,
  });

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  final _vm = PresensiViewModel();

  @override
  void initState() {
    super.initState();
    final jadwalId = widget.jadwal['id'] ?? '';
    if (jadwalId.isNotEmpty) {
      _vm.checkInitialStatus(jadwalId, widget.user);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _handleCheckIn() async {
    // 1. Validasi Kelas sudah dimulai oleh Dosen
    if (!_vm.isKelasBuka.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absen ditolak: Sesi kelas belum dimulai atau sudah diakhiri oleh dosen.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final jadwalId = widget.jadwal['id'] ?? '';
    if (jadwalId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Jadwal tidak valid')),
      );
      return;
    }

    await _vm.doCheckIn(jadwalId, widget.user);
    
    if (_vm.errorMessage.value != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_vm.errorMessage.value!)),
        );
      }
    } else if (_vm.isHadir.value) {
      if (mounted) {
        final isOffline = _vm.isOfflineMode.value;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOffline 
              ? 'Presensi offline dicatat ke Hive. Akan disinkronkan.' 
              : 'Presensi berhasil disimpan ke MongoDB.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
    final todayStr = dateFormat.format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(todayStr),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildCurrentSessionCard(),
                    const SizedBox(height: 16),
                    _buildCheckInSection(),
                    const SizedBox(height: 20),
                    _buildUpcomingSessionsSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
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
          colors: [
            Color(0xFF1A237E),
            Color(0xFF1E3A8A),
            Color(0xFF1565C0),
          ],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Absensi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              letterSpacing: 0.20,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
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
                      BoxShadow(
                        color: Color(0xFF69F0AE),
                        blurRadius: 6,
                      ),
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

  Widget _buildCurrentSessionCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x2D69F0AE),
              border: Border.all(
                color: const Color(0x5969F0AE),
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.radio_button_on,
                  size: 6,
                  color: Color(0xFF69F0AE),
                ),
                SizedBox(width: 8),
                Text(
                  'BERLANGSUNG',
                  style: TextStyle(
                    color: Color(0xFF69F0AE),
                    fontSize: 10.50,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.50,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.jadwal['mataKuliah'] ?? 'Mata Kuliah',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                widget.jadwal['jam'] ?? '-',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12.50,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '·',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.30),
                  fontSize: 12.50,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.location_on, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                widget.jadwal['ruang'] ?? '-',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 12.50,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white, size: 14),
                const SizedBox(width: 10),
                Text(
                  'Batas absen tersisa',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 12,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                ValueListenableBuilder<bool>(
                  valueListenable: _vm.isLoading,
                  builder: (context, isLoading, _) {
                    final remaining = isLoading ? '--:--' : '14:22';
                    return Text(
                      remaining,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInSection() {
    return ValueListenableBuilder<bool>(
      valueListenable: _vm.isHadir,
      builder: (context, isHadir, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: _vm.isLoading,
          builder: (context, isLoading, _) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isHadir
                        ? const Color(0xFFE6F9F0)
                        : const Color(0xFFEEF0F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isHadir ? Icons.check_circle : Icons.info_outline,
                        color: isHadir
                            ? const Color(0xFF1B8A5A)
                            : const Color(0xFF8892A4),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isHadir ? '✓ Hadir' : 'Belum Hadir',
                        style: TextStyle(
                          color: isHadir
                              ? const Color(0xFF1B8A5A)
                              : const Color(0xFF8892A4),
                          fontSize: 12,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (!isHadir)
                  GestureDetector(
                    onTap: isLoading ? null : _handleCheckIn,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 12,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLoading)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          else
                            const Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF1A237E),
                              size: 18,
                            ),
                          const SizedBox(width: 12),
                          Text(
                            'Tandai Hadir Sekarang',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF1A237E),
                              fontSize: 15,
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.30,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUpcomingSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Text(
            'JADWAL HARI INI',
            style: TextStyle(
              color: Color(0xFF8892A4),
              fontSize: 11,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              letterSpacing: 1.40,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildSessionCard(index),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSessionCard(int index) {
    final sessions = [
      {
        'time': '07:30',
        'endTime': '09:10',
        'title': 'Pemrograman Mobile',
        'room': 'Ruang 204',
        'status': '✓ Hadir',
        'statusColor': const Color(0xFFE6F9F0),
        'statusTextColor': const Color(0xFF1B8A5A),
      },
      {
        'time': '09:30',
        'endTime': '11:10',
        'title': 'Basis Data Lanjut',
        'room': 'Lab DB',
        'status': 'Belum',
        'statusColor': const Color(0xFFEEF0F5),
        'statusTextColor': const Color(0xFF8892A4),
      },
      {
        'time': '13:30',
        'endTime': '15:10',
        'title': 'Kecerdasan Buatan',
        'room': 'Ruang 102',
        'status': 'Belum',
        'statusColor': const Color(0xFFEEF0F5),
        'statusTextColor': const Color(0xFF8892A4),
      },
    ];

    final session = sessions[index];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: Colors.black.withOpacity(0.04),
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 6,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                session['time'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1A237E),
                  fontSize: 13,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  height: 1.10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                session['endTime'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFA0AAB4),
                  fontSize: 10.50,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 2,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0F5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session['title'] as String,
                  style: const TextStyle(
                    color: Color(0xFF1A2030),
                    fontSize: 13.50,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    height: 1.30,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  session['room'] as String,
                  style: const TextStyle(
                    color: Color(0xFFA0AAB4),
                    fontSize: 11.50,
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
              color: session['statusColor'] as Color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              session['status'] as String,
              style: TextStyle(
                color: session['statusTextColor'] as Color,
                fontSize: 11,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}