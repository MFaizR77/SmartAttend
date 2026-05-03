import 'package:flutter/material.dart';

/// Palet warna SmartAttend.
/// Netral-profesional: charcoal, putih, biru aksen.
class AppColors {
  AppColors._();

  // Background & Surface
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F8F8);
  static const Color surfaceVariant = Color(0xFFFFFFFF);

  // Primary (Ink & Brand)
  static const Color primary = Color(0xFF1A1A1A); // _ink
  static const Color primaryLight = Color(0xFF2D2D3F);
  static const Color brand = Color(0xFFD0FF00); // Lime Green

  // Accent
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentLight = Color(0xFFDBEAFE);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A); // _ink
  static const Color textSecondary = Color(0xFF6B7280); // _softText
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnBrand = Color(0xFF1A1A1A);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Border & Divider
  static const Color border = Color(0xFFF3F4F6); // _stroke
  static const Color divider = Color(0xFFF3F4F6);
}
