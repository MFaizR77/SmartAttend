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
    // 1. Validasi Jendela Waktu Lokal (Local Time-Window)
    if (!_vm.isWithinTimeWindow(widget.jadwal['jam'] ?? '')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Absen ditolak: Di luar jam perkuliahan (${widget.jadwal['jam']})'),
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
      appBar: AppBar(
        title: const Text('Presensi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Jadwal Info Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.class_, size: 48, color: AppColors.accent),
                    const SizedBox(height: 16),
                    Text(
                      widget.jadwal['mataKuliah'] ?? 'Mata Kuliah',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      todayStr,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(Icons.access_time, widget.jadwal['jam'] ?? '-'),
                        _buildInfoItem(Icons.room, widget.jadwal['ruang'] ?? '-'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Status & Check-in Area
            ValueListenableBuilder<bool>(
              valueListenable: _vm.isHadir,
              builder: (context, isHadir, _) {
                return Column(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isHadir ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHadir ? Icons.check_circle : Icons.info_outline,
                            color: isHadir ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isHadir ? 'SUDAH HADIR' : 'BELUM HADIR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isHadir ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Big Action Button
                    ValueListenableBuilder<bool>(
                      valueListenable: _vm.isLoading,
                      builder: (context, isLoading, _) {
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isHadir || isLoading ? null : _handleCheckIn,
                            borderRadius: BorderRadius.circular(100),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isHadir
                                    ? AppColors.success
                                    : (isLoading ? AppColors.accentLight : AppColors.accent),
                                boxShadow: [
                                  if (!isHadir && !isLoading)
                                    BoxShadow(
                                      color: AppColors.accent.withValues(alpha: 0.4),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                ],
                              ),
                              child: Center(
                                child: isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isHadir ? Icons.check : Icons.fingerprint,
                                            size: 64,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            isHadir ? 'Selesai' : 'Tap untuk\nCheck-In',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
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