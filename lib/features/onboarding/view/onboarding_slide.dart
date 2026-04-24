import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

/// Widget satu slide onboarding.
/// Hanya menampilkan ilustrasi + judul + deskripsi.
/// Tombol & dot indikator dikelola di OnboardingScreen (di luar PageView)
/// agar animasinya berjalan smooth dan tidak ikut slide.
class OnboardingSlide extends StatelessWidget {
  final OnboardingData data;

  const OnboardingSlide({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Area ilustrasi (mengisi sisa ruang yang tersedia) ────────────
        Expanded(
          child: Container(
            width: double.infinity,
            color: const Color(0xFFF3F7F8),
            child: Stack(
              children: [
                // Latar gradien hijau tipis
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  child: Opacity(
                    opacity: 0.60,
                    child: Container(
                      height: 420,
                      decoration: const ShapeDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0.50, 0.00),
                          end: Alignment(0.50, 1.00),
                          colors: [Color(0x7FD9EDDB), Color(0x00D9EDDB)],
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(60),
                            bottomRight: Radius.circular(60),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Gambar ilustrasi ditengah
                Center(child: _IllustrationArea(imagePath: data.imagePath)),
              ],
            ),
          ),
        ),

        // ── Area teks (judul + deskripsi) ────────────────────────────────
        Container(
          width: double.infinity,
          color: const Color(0xFFF3F7F8),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Judul
              SizedBox(
                width: 312,
                child: Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Deskripsi
              SizedBox(
                width: 312,
                child: Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF414941),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.80,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
/// Area ilustrasi: lingkaran latar kuning-hijau + gambar onboarding.
// ────────────────────────────────────────────────────────────────────────────
class _IllustrationArea extends StatelessWidget {
  final String imagePath;

  const _IllustrationArea({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lingkaran besar kuning-hijau (latar)
          Container(
            width: 320,
            height: 320,
            decoration: const ShapeDecoration(
              color: Color(0x4CD4FF00),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(9999)),
              ),
            ),
          ),

          // Gambar onboarding
          Image.asset(imagePath, width: 280, height: 280, fit: BoxFit.contain),
        ],
      ),
    );
  }
}
