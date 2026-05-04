import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/local/models/user.dart';
import '../../dashboard/viewmodel/mahasiswa_dashboard_viewmodel.dart';
import '../../presensi/view/presensi_screen.dart';

class JadwalScreen extends StatefulWidget {
  final User user;
  
  const JadwalScreen({super.key, required this.user});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final _vm = MahasiswaDashboardViewModel();

  @override
  void initState() {
    super.initState();
    _vm.loadData(widget.user);
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
            'Jadwal\nHari Ini',
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
          child: ValueListenableBuilder<List<Map<String, String>>>(
            valueListenable: _vm.jadwalHariIni,
            builder: (context, jadwal, _) {
              if (jadwal.isEmpty) {
                return const Center(
                  child: Text(
                    'Belum ada jadwal yang tersedia',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: jadwal.length,
                itemBuilder: (context, index) {
                  final j = jadwal[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildJadwalCard(context, j),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildJadwalCard(BuildContext context, Map<String, String> jadwal) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PresensiScreen(jadwal: jadwal, user: widget.user)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.class_outlined, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jadwal['mataKuliah'] ?? '-',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${jadwal['jam']} • ${jadwal['ruang']}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
