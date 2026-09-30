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

  // --- Beautiful Native Illustrations (Courier PRO Design System) ---

  Widget _buildIllustration1() {
    return Container(
      width: 280,
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.r24,
        boxShadow: AppShadows.s,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Decorative background circle
          Positioned(
            top: 20,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: AppColors.brandPrimarySurface,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Delivery backpack icon
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: AppRadius.r20,
                  boxShadow: AppShadows.m,
                ),
                child: const Icon(
                  PhosphorIcons.bag,
                  size: 48,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // Floating rate badge pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: AppRadius.rPill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(PhosphorIcons.lightning, size: 16, color: AppColors.brandPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'до 750 ₽/час',
                      style: AppTypography.captionBold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration2() {
    return Container(
      width: 280,
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.r24,
        boxShadow: AppShadows.s,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCheckItem('1. Сбор документов', true),
          const SizedBox(height: 12),
          _buildCheckItem('2. Онлайн-оформление', true),
          const SizedBox(height: 12),
          _buildCheckItem('3. Первая доставка', false),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.feedbackSuccessLight,
              borderRadius: AppRadius.rPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 14, color: AppColors.feedbackSuccess),
                const SizedBox(width: 6),
                Text(
                  'Выход на смену уже завтра',
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.feedbackSuccess,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, bool done) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: AppRadius.r12,
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: done ? AppColors.feedbackSuccess : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: done ? null : Border.all(color: AppColors.borderStrong, width: 1.5),
            ),
            child: done
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTypography.bodyM.copyWith(
              color: done ? AppColors.textPrimary : AppColors.textTertiary,
              fontWeight: done ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration3() {
    return Container(
      width: 280,
      height: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.r24,
        boxShadow: AppShadows.s,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.brandPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  PhosphorIcons.chatTeardropDots,
                  size: 24,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Помощник',
                      style: AppTypography.headingS,
                    ),
                    Text(
                      'Онлайн 24/7',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.feedbackSuccess,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius: AppRadius.r16,
            ),
            child: Text(
              '«Помогу быстро зарегистрироваться и подскажу, как избежать ошибок при тесте!»',
              style: AppTypography.bodyS,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: [
              _buildChipPreview('Документы'),
              _buildChipPreview('Мой налог'),
              _buildChipPreview('VPN'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChipPreview(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.rPill,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
