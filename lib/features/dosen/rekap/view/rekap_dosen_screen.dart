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
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          decoration: const BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
          ),
          child: const Text(
            'Rekap\nPerkuliahan',
            style: TextStyle(
              color: AppColors.primary,
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
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (_vm.errorMessage != null) {
                return Center(
                  child: Text(_vm.errorMessage!, style: const TextStyle(color: AppColors.error)),
                );
              }

              if (_vm.rekapPerKelas.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_edu, size: 80, color: AppColors.border),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada BAP / Rekap yang tersimpan',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              final groups = _vm.rekapPerKelas.keys.toList();

              return RefreshIndicator(
                onRefresh: () => _vm.loadRekap(widget.user),
                child: ListView.builder(
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
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...listLaporan.map((laporan) {
                            final date = laporan['tanggal'] as DateTime;
                            final dateStr = DateFormat('dd MMM yyyy').format(date);
                            final materi = laporan['materi'] ?? 'Tidak ada materi';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          dateStr,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Materi yang diajarkan:',
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
