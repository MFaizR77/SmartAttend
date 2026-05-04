import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class RekapAdminScreen extends StatelessWidget {
  const RekapAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Global'),
        backgroundColor: AppColors.brand,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: AppColors.border),
            const SizedBox(height: 16),
            const Text(
              'Fitur Rekap Sistem',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
