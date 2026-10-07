import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../auth/register_cabinet_screen.dart';

class OnboardingItem {
  final String title;
  final String subtitle;
  final String imagePath;

  const OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  final LocaleService _locale = LocaleService();
  int _currentPage = 0;

  List<OnboardingItem> get _slides => [
    OnboardingItem(
      title: _locale.tr('onb1Title'),
      subtitle: _locale.tr('onb1Subtitle'),
      imagePath: 'assets/onboarding/onb_coins_100pct.png',
    ),
    OnboardingItem(
      title: _locale.tr('onb2Title'),
      subtitle: _locale.tr('onb2Subtitle'),
      imagePath: 'assets/onboarding/onb_timer_walk.png',
    ),
    OnboardingItem(
      title: _locale.tr('onb3Title'),
      subtitle: _locale.tr('onb3Subtitle'),
      imagePath: 'assets/onboarding/onb_wallet_coins.webp',
    ),
    OnboardingItem(
      title: _locale.tr('onb4Title'),
      subtitle: _locale.tr('onb4Subtitle'),
      imagePath: 'assets/onboarding/onb_support_24_7.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _locale.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _locale.removeListener(_onLocaleChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _finishOnboarding() {
    HapticFeedback.mediumImpact();
    _locale.completeOnboarding();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RegisterCabinetScreen()),
    );
  }

  void _nextPage() {
    HapticFeedback.selectionClick();
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Clean lowercase brand & Skip action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _locale.tr('appName').toLowerCase(),
                    style: GoogleFonts.golosText(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      color: AppColors.textDarkWarm,
                    ),
                  ),
                  GestureDetector(
                    onTap: _finishOnboarding,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        _locale.tr('skip'),
                        style: GoogleFonts.golosText(
                          fontSize: 14,
                          color: AppColors.textMutedWarm,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Carousel with warm Yandex Go styled cards
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCardWarm,
                        borderRadius: AppRadius.r28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Text Block on Top
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slide.title,
                                  style: GoogleFonts.golosText(
                                    fontSize: 26,
                                    height: 1.12,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.8,
                                    color: AppColors.textDarkWarm,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  slide.subtitle,
                                  style: GoogleFonts.golosText(
                                    fontSize: 14,
                                    height: 1.35,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: -0.2,
                                    color: AppColors.textMutedWarm,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 2. 3D Render sitting naturally at the BOTTOM of the card
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Image.asset(
                                  slide.imagePath,
                                  fit: BoxFit.contain,
                                  alignment: Alignment.bottomCenter,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.check_circle_outline,
                                        size: 64,
                                        color: AppColors.brandPrimary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Area: Smooth Dots & Primary Yellow Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                children: [
                  // Smooth Indicator Dots (Yandex Go style)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.textDarkWarm : const Color(0xFFD8D4CC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 20),

                  // Action Button (Yellow Pill, dark lowercase text)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: AppColors.textDarkWarm,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.rPill,
                        ),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1 ? _locale.tr('becomeCourier') : _locale.tr('nextBtn'),
                        style: GoogleFonts.golosText(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.textDarkWarm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
