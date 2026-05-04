import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';

class LogoutConfirmDialog extends StatefulWidget {
  final VoidCallback onConfirm;

  const LogoutConfirmDialog({super.key, required this.onConfirm});

  @override
  State<LogoutConfirmDialog> createState() => _LogoutConfirmDialogState();
}

class _LogoutConfirmDialogState extends State<LogoutConfirmDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller animasi
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -0.20,
      end: 0.20,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _shakeIcon();
  }

  void _shakeIcon() async {
    for (int i = 0; i < 3; i++) {
      await _controller.forward();
      await _controller.reverse();
    }
    // Tambahkan ini agar kembali ke tengah (0.0)
    _controller.animateTo(0.5);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: 329,
        padding: const EdgeInsets.all(32),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 4, color: AppColors.grayDark),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Area dengan Animasi Goyang
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animation.value, // Nilai rotasi dari animasi
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: ShapeDecoration(
                      color: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 4,
                          color: AppColors.orange,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Icon(
                      Icons.power_settings_new,
                      color: AppColors.orange,
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Yakin ingin keluar?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grayDark,
                fontSize: 18,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            const Text(
              'Sesi Anda akan diakhiri. Pastikan semua\npresensi hari ini telah tersinkronisasi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.grayMedium,
                fontSize: 12,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Buttons
            Column(
              children: [
                // Button Keluar
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    widget.onConfirm();
                  },
                  child: Container(
                    width: 180,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: AppColors.error,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 4,
                          color: AppColors.error,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'KELUAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Button Batal
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 180,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 2,
                          color: AppColors.grayDark.withValues(alpha: 0.2),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'BATAL',
                      style: TextStyle(
                        color: AppColors.grayDark,
                        fontSize: 12,
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.45,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
