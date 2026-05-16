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
          child: const Text(
            'Manajemen\nJadwal',
            style: TextStyle(
              color: Colors.white,
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
