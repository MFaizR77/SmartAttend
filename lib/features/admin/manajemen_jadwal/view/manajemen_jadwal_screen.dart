import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ManajemenJadwalScreen extends StatelessWidget {
  const ManajemenJadwalScreen({super.key});

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
            'Manajemen\nJadwal',
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_month, size: 80, color: AppColors.border),
                const SizedBox(height: 16),
                const Text(
                  'Fitur Daftar Jadwal Kuliah',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
