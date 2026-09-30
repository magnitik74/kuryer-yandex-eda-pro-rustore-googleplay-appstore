import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../auth/register_cabinet_screen.dart';
import '../main_screen.dart';
import '../onboarding/language_select_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _iconScaleAnim;
  late Animation<double> _iconOpacityAnim;
  late Animation<double> _textFadeAnim;
  late Animation<Offset> _textSlideAnim;
  late Animation<double> _subFadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // 1. Icon Pop & Settle (0 to 600ms)
    _iconScaleAnim = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _iconOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // 2. Appearing Text: "Работа курьером" (350ms to 850ms)
    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 0.70, curve: Curves.easeOut),
      ),
    );
    _textSlideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Subtle Subtitle / Badge (650ms to 1000ms)
    _subFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.65, 0.90, curve: Curves.easeIn),
      ),
    );

    _animController.forward();

    // After animation finishes, smoothly navigate to the target screen
    Timer(const Duration(milliseconds: 2200), _navigateToNextScreen);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    final locale = LocaleService();
    Widget target;
    if (locale.hasRegisteredCabinet) {
      target = const MainScreen();
    } else if (locale.hasCompletedOnboarding) {
      target = const RegisterCabinetScreen();
    } else {
      target = const LanguageSelectScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => target,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandPrimary, // Signature #FCE000
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Brand Icon with Scale & Opacity
                  Transform.scale(
                    scale: _iconScaleAnim.value,
                    child: Opacity(
                      opacity: _iconOpacityAnim.value,
                      child: Container(
                        width: 136,
                        height: 136,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 28,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: Image.asset(
                            'assets/app_icon.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Appearing Animated Text: "Работа курьером"
                  SlideTransition(
                    position: _textSlideAnim,
                    child: FadeTransition(
                      opacity: _textFadeAnim,
                      child: Column(
                        children: [
                          Text(
                            'Работа курьером',
                            style: AppTypography.headingL.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Opacity(
                            opacity: _subFadeAnim.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.08),
                                borderRadius: AppRadius.rPill,
                              ),
                              child: Text(
                                'ЕЖЕДНЕВНЫЙ ДОХОД И СВОБОДНЫЙ ГРАФИК',
                                style: AppTypography.captionBold.copyWith(
                                  fontSize: 10,
                                  letterSpacing: 0.8,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 4),

                  // Bottom subtle loader / version indicator
                  Opacity(
                    opacity: _subFadeAnim.value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textPrimary.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Официальный сервис подключения',
                            style: AppTypography.caption.copyWith(
                              fontSize: 12,
                              color: AppColors.textPrimary.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
