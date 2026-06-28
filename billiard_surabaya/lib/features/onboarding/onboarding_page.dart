import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_page.dart';
import '../main/main_shell.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingData> _slides = [
    _OnboardingData(
      icon: Icons.sports_bar_rounded,
      iconColor: AppColors.neonGreen,
      title: 'Temukan Tempat\nBilliard Terbaik',
      subtitle:
          'Lebih dari 15 tempat billiard di Surabaya tersedia untukmu. Cari berdasarkan lokasi, rating, atau harga.',
      gradient: [Color(0xFF0D2818), Color(0xFF0D0D0D)],
    ),
    _OnboardingData(
      icon: Icons.map_rounded,
      iconColor: AppColors.neonBlue,
      title: 'Lihat Peta\nSecara Real-Time',
      subtitle:
          'Temukan tempat billiard terdekat dari lokasimu sekarang. Navigasi langsung lewat Google Maps.',
      gradient: [Color(0xFF0A1A2E), Color(0xFF0D0D0D)],
    ),
    _OnboardingData(
      icon: Icons.favorite_rounded,
      iconColor: Color(0xFFFF6B9D),
      title: 'Simpan Favorit\n& Pantau Promo',
      subtitle:
          'Login untuk menyimpan tempat favorit, melihat riwayat kunjungan, dan mendapatkan notifikasi promo eksklusif.',
      gradient: [Color(0xFF2E0A1A), Color(0xFF0D0D0D)],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToApp({bool asGuest = false}) {
    if (asGuest) {
      // Langsung ke MainShell tanpa login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Slides ──────────────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) => _buildSlide(_slides[i]),
          ),

          // ── Bottom controls ─────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomControls(),
          ),

          // ── Skip button ──────────────────────────────────────────────────
          Positioned(
            top: 52,
            right: 20,
            child: SafeArea(
              child: TextButton(
                onPressed: () => _goToApp(asGuest: true),
                child: const Text(
                  'Lewati',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_OnboardingData data) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: data.gradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 80, 32, 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon illustration
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: data.iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: data.iconColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(data.icon, color: data.iconColor, size: 56),
              ),
              const SizedBox(height: 48),

              // Title
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final isLast = _currentPage == _slides.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, AppColors.background],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.neonGreen : AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),

          // Primary action button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isLast ? () => _goToApp() : _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                isLast ? 'Masuk / Daftar' : 'Selanjutnya',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Guest button — selalu tampil
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => _goToApp(asGuest: true),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.divider),
                ),
              ),
              child: const Text(
                'Jelajahi Tanpa Login',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardingData({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}
