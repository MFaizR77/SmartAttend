import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../../auth/view/widgets/logout_confirm_dialog.dart';
import '../viewmodel/kaprodi_dashboard_viewmodel.dart';

/// Dashboard untuk akun Kaprodi.
/// Tampilkan jadwal per hari dengan status sesi absensi dosen.
class KaprodiDashboardScreen extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const KaprodiDashboardScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<KaprodiDashboardScreen> createState() => _KaprodiDashboardScreenState();
}

class _KaprodiDashboardScreenState extends State<KaprodiDashboardScreen> {
  late final KaprodiDashboardViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = KaprodiDashboardViewModel();
    _vm.loadData(widget.user);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  Future<void> _refresh() => _vm.loadData(widget.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildHariSelector(),
              const SizedBox(height: 16),
              Expanded(child: _buildJadwalList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Halo,\n${widget.user.nama}!',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                    fontSize: 28,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) =>
                        LogoutConfirmDialog(onConfirm: widget.onLogout),
                  );
                },
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KEPALA PROGRAM STUDI',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Plus Jakarta Sans',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.user.program ?? '-',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHariSelector() {
    return ValueListenableBuilder<String>(
      valueListenable: _vm.selectedHari,
      builder: (context, selected, _) {
        return SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _vm.hariList.length,
            itemBuilder: (context, index) {
              final hari = _vm.hariList[index];
              final isSelected = hari == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _vm.selectedHari.value = hari,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : const Color(0xFFE5E7EB),
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      hari,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.grayDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildJadwalList() {
    return ValueListenableBuilder<bool>(
      valueListenable: _vm.isLoading,
      builder: (context, loading, _) {
        if (loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ValueListenableBuilder<String?>(
          valueListenable: _vm.errorMessage,
          builder: (context, error, _) {
            if (error != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.grayMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ValueListenableBuilder<Map<String, List<Map<String, dynamic>>>>(
              valueListenable: _vm.jadwalPerHari,
              builder: (context, jadwalMap, _) {
                return ValueListenableBuilder<String>(
                  valueListenable: _vm.selectedHari,
                  builder: (context, selectedHari, _) {
                    final jadwalList = jadwalMap[selectedHari] ?? [];

                    if (jadwalList.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 64,
                              color: AppColors.grayMedium.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada jadwal pada hari $selectedHari',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.grayMedium.withOpacity(0.7),
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: jadwalList.length,
                      itemBuilder: (context, index) {
                        final jadwal = jadwalList[index];
                        return _buildJadwalCard(jadwal);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildJadwalCard(Map<String, dynamic> jadwal) {
    final statusSesi = jadwal['statusSesi'] ?? 'not_opened';
    final namaDosen = jadwal['namaDosen'] ?? '-';
    final namaMK = jadwal['namaMK'] ?? '-';
    final kelas = jadwal['kelas'] ?? '-';
    final jamMulai = jadwal['jamMulai'] ?? '-';
    final jamSelesai = jadwal['jamSelesai'] ?? '-';
    final ruangan = jadwal['kodeRuangan'] ?? '-';
    final jadwalId = jadwal['_id']?.toString() ?? '';
    final laporanId = jadwal['laporanId'];

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (statusSesi) {
      case 'open':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle;
        statusText = 'Sesi Dibuka';
        break;
      case 'closed':
        statusColor = const Color(0xFF6B7280);
        statusIcon = Icons.lock;
        statusText = 'Sesi Ditutup';
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.warning_amber_rounded;
        statusText = 'Belum Dibuka';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaMK,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Plus Jakarta Sans',
                          color: AppColors.grayDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kelas $kelas',
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
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
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
          ),

          // Body Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(Icons.person, 'Dosen', namaDosen),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.access_time, 'Waktu', '$jamMulai - $jamSelesai'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.room, 'Ruangan', ruangan),
                
                if (jadwal['waktuMulai'] != null) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.login,
                    'Dibuka',
                    _formatDateTime(jadwal['waktuMulai']),
                  ),
                  if (jadwal['waktuSelesai'] != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.logout,
                      'Ditutup',
                      _formatDateTime(jadwal['waktuSelesai']),
                    ),
                  ],
                ],

                // Action Buttons
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (statusSesi == 'not_opened') ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleBukaSesi(jadwalId),
                          icon: const Icon(Icons.play_arrow, size: 18),
                          label: const Text('Buka Sesi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (statusSesi == 'open' && laporanId != null) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleTutupSesi(laporanId),
                          icon: const Icon(Icons.stop, size: 18),
                          label: const Text('Tutup Sesi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (statusSesi == 'closed') ...[
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 18,
                                color: Color(0xFF6B7280),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Sesi Selesai',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.grayMedium,
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Plus Jakarta Sans',
            color: AppColors.grayMedium.withOpacity(0.8),
          ),
        ),
        const SizedBox(width: 8),
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
    );
  }

  String _formatDateTime(dynamic dt) {
    if (dt == null) return '-';
    DateTime dateTime;
    if (dt is DateTime) {
      dateTime = dt;
    } else if (dt is String) {
      dateTime = DateTime.tryParse(dt) ?? DateTime.now();
    } else {
      return '-';
    }
    // Convert to local timezone (WIB/GMT+7)
    final localDateTime = dateTime.toLocal();
    return DateFormat('HH:mm', 'id_ID').format(localDateTime);
  }

  Future<void> _handleBukaSesi(String jadwalId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Buka Sesi Absensi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        content: const Text(
          'Anda akan membuka sesi absensi untuk dosen yang lupa membuka. Lanjutkan?',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
          ),
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
            child: const Text('Buka Sesi'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await _vm.bukaSesiAbsensi(
      jadwalId: jadwalId,
      kaprodiId: widget.user.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Sesi absensi berhasil dibuka'
              : 'Gagal membuka sesi absensi',
        ),
        backgroundColor: success ? const Color(0xFF10B981) : AppColors.error,
      ),
    );

    if (success) await _refresh();
  }

  Future<void> _handleTutupSesi(String laporanId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Tutup Sesi Absensi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        content: const Text(
          'Anda akan menutup sesi absensi untuk dosen yang lupa menutup. Lanjutkan?',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7280),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tutup Sesi'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final success = await _vm.tutupSesiAbsensi(
      laporanId: laporanId,
      kaprodiId: widget.user.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Sesi absensi berhasil ditutup'
              : 'Gagal menutup sesi absensi',
        ),
        backgroundColor: success ? const Color(0xFF10B981) : AppColors.error,
      ),
    );

    if (success) await _refresh();
  }
}
