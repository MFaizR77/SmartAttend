import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'onboarding_slide.dart';

/// Layar onboarding utama — mengelola 3 slide dengan PageView.
/// Dot indikator & tombol diletakkan di LUAR PageView agar tidak ikut slide
/// dan animasinya berjalan smooth mengikuti offset scroll secara realtime.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<OnboardingData> _slides = [
    OnboardingData(
      imagePath: 'assets/images/onboarding_1.png',
      title: 'Absensi Jadi Lebih\nSat-Set',
      description:
          'Lupakan absen manual yang ribet. Catat kehadiranmu dalam hitungan detik langsung dari genggaman.',
    ),
    OnboardingData(
      imagePath: 'assets/images/onboarding_2.png',
      title: 'Pantau Kehadiran\nReal-Time',
      description:
          'Lihat rekap absensi secara langsung. Transparansi penuh, data akurat, kapan saja dan di mana saja.',
    ),
    OnboardingData(
      imagePath: 'assets/images/onboarding_3.png',
      title: 'Kelola Kelas\nLebih Mudah',
      description:
          'Dosen dan admin dapat mengelola jadwal, kelas, dan laporan kehadiran hanya dalam satu platform.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  // ── Smooth dot indicators menggunakan AnimatedBuilder ─────────────────────
  // Membaca _pageController.page (double) sehingga lebar & warna dot
  // berubah secara continuous mengikuti posisi jari, bukan loncat per-integer.
  Widget _buildDots() {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, _) {
        final double page =
            _pageController.hasClients && _pageController.page != null
            ? _pageController.page!
            : _currentPage.toDouble();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            // seberapa "aktif" dot ini — 1.0 tepat di halaman ini, 0.0 jauh
            final double selected = (1.0 - (page - i).abs()).clamp(0.0, 1.0);
            final double dotWidth = 6.0 + (18.0 * selected); // 6 → 24 px

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: dotWidth,
              height: 8,
              decoration: BoxDecoration(
                color: Color.lerp(
                  AppColors.onboardingDotInactive,
                  AppColors.charcoal,
                  selected,
                ),
                borderRadius: BorderRadius.circular(9999),
              ),
            );
          }),
        );
      },
    );
  }

  // ── Tombol dengan AnimatedSwitcher untuk teks ─────────────────────────────
  Widget _buildButton() {
    final bool isLast = _currentPage == _slides.length - 1;

    return GestureDetector(
      onTap: _onNext,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: ShapeDecoration(
          color: AppColors.brandLime,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x263D6846),
              blurRadius: 30,
              offset: Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 0.25),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: child,
              ),
            );
          },
          child: Text(
            isLast ? 'Mulai Sekarang' : 'Lanjut',
            // key berbeda agar AnimatedSwitcher mendeteksi perubahan
            key: ValueKey<bool>(isLast),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.charcoal,
              fontSize: 20,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.40,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onboardingBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Konten slide (gambar + judul + deskripsi) ────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return OnboardingSlide(data: _slides[index]);
                },
              ),
            ),

            // ── Area bawah tetap (dot + tombol) ──────────────────────────
            // Tidak ikut PageView sehingga animasinya halus & kontinu
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDots(),
                  const SizedBox(height: 20),
                  _buildButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data model sederhana untuk tiap slide onboarding.
class OnboardingData {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingData({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}
