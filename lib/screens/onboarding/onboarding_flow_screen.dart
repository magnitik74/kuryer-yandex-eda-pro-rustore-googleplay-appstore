import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../auth/register_cabinet_screen.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  final LocaleService _locale = LocaleService();
  int _currentPage = 0;

  @override
  void dispose() {
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
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Brand text & Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _locale.tr('appName'),
                    style: AppTypography.headingS.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: Text(
                      'Пропустить',
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Carousel Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildPage(
                    title: _locale.tr('onb1Title'),
                    subtitle: _locale.tr('onb1Subtitle'),
                    illustration: _buildIllustration1(),
                  ),
                  _buildPage(
                    title: _locale.tr('onb2Title'),
                    subtitle: _locale.tr('onb2Subtitle'),
                    illustration: _buildIllustration2(),
                  ),
                  _buildPage(
                    title: _locale.tr('onb3Title'),
                    subtitle: _locale.tr('onb3Subtitle'),
                    illustration: _buildIllustration3(),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Area: Dots + Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                children: [
                  // Smooth Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.brandPrimary : AppColors.borderStrong,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),

                  // Action Button: Ghost text on 1-2, Solid Yellow Pill on 3
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: AppColors.textOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.rPill,
                        ),
                      ),
                      child: Text(
                        _currentPage == 2 ? _locale.tr('start') : _locale.tr('next'),
                        style: AppTypography.button,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String subtitle,
    required Widget illustration,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Card
          Expanded(
            flex: 5,
            child: Center(child: illustration),
          ),

          const SizedBox(height: 16),

          // Title & Subtitle
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headingXL,
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: AppTypography.bodyL.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Seamless 3D Render Illustrations (Courier PRO Design System) ---

  Widget _buildIllustration1() {
    return _buildIllustrationCard('assets/onboarding/onboarding_1.jpg');
  }

  Widget _buildIllustration2() {
    return _buildIllustrationCard('assets/onboarding/onboarding_2.jpg');
  }

  Widget _buildIllustration3() {
    return _buildIllustrationCard('assets/onboarding/onboarding_3.jpg');
  }

  Widget _buildIllustrationCard(String assetPath) {
    return Container(
      width: 290,
      height: 290,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.r24,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadius.r24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Soft background glow
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F5F3),
              ),
            ),
            // The 3D Render with ShaderMask soft fade at the bottom edges
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Colors.black,
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.88, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        PhosphorIcons.cube,
                        size: 48,
                        color: AppColors.brandPrimary,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
