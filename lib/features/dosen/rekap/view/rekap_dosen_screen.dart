import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../viewmodel/rekap_dosen_viewmodel.dart';
import 'package:intl/intl.dart';

class RekapDosenScreen extends StatefulWidget {
  final User user;

  const RekapDosenScreen({super.key, required this.user});

  @override
  State<RekapDosenScreen> createState() => _RekapDosenScreenState();
}

class _RekapDosenScreenState extends State<RekapDosenScreen> {
  final _vm = RekapDosenViewModel();

  @override
  void initState() {
    super.initState();
    _vm.loadRekap(widget.user);
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF01018B),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: const Text(
            'Rekap\nPerkuliahan',
            style: TextStyle(
              color: Color(0xFFF6F6F6),
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              height: 1.1,
              fontSize: 28,
              letterSpacing: -0.6,
            ),
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _vm,
            builder: (context, _) {
              if (_vm.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF01018B)),
                );
              }

              if (_vm.errorMessage != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wifi_off_rounded,
                            color: AppColors.warning,
                            size: 42,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Data rekap belum bisa dimuat',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Periksa koneksi internet atau server, lalu coba lagi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: () => _vm.loadRekap(widget.user),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Coba lagi'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Color(0xFF01018B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (_vm.rekapPerKelas.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_edu,
                        size: 80,
                        color: AppColors.border,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada BAP / Rekap yang tersimpan',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final groups = _vm.rekapPerKelas.keys.toList();

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final groupName = groups[index];
                  final listLaporan = _vm.rekapPerKelas[groupName]!;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...listLaporan.map((laporan) {
                          final date = laporan['tanggal'] as DateTime;
                          final dateStr = DateFormat(
                            'dd MMM yyyy',
                          ).format(date);
                          final materi =
                              laporan['materi'] ?? 'Tidak ada materi';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFEEF0FB),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        dateStr,
                                        style: const TextStyle(
                                          color: Color(0xFF01018B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.success,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Materi yang diajarkan:',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  materi,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
      ),
    );
  }
}
