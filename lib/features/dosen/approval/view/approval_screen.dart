import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ApprovalScreen extends StatelessWidget {
  const ApprovalScreen({super.key});

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
            'Approval\nIzin & Sakit',
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
                Icon(Icons.fact_check, size: 80, color: AppColors.border),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada pengajuan dari mahasiswa',
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
