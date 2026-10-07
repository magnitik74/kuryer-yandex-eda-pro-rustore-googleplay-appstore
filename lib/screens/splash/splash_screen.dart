import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../main_screen.dart';
import '../onboarding/onboarding_screen_v2.dart';

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
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // 1. Icon Pop & Settle (0 to 500ms)
    _iconScaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOutCubic),
      ),
    );
    _iconOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.30, curve: Curves.easeIn),
      ),
    );

    // 2. Appearing Text: "Работа курьером" (250ms to 650ms)
    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.25, 0.60, curve: Curves.easeOut),
      ),
    );
    _textSlideAnim = Tween<Offset>(
      begin: const Offset(0.0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.25, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Subtle Subtitle / Badge (450ms to 800ms)
    _subFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.45, 0.80, curve: Curves.easeIn),
      ),
    );

    _animController.forward();

    // After animation finishes, smoothly navigate to the target screen
    _timer = Timer(const Duration(milliseconds: 2000), _navigateToNextScreen);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    final locale = LocaleService();
    Widget target;
    if (locale.hasRegisteredCabinet) {
      target = const MainScreen();
    } else {
      // New unified onboarding (geo + format + name/phone)
      target = const OnboardingScreenV2();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => target,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brandPrimary, // Signature #FCE000
      body: SafeArea(
        child: SizedBox.expand(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Brand Icon with Scale & Opacity
                  Transform.scale(
                    scale: _iconScaleAnim.value,
                    child: Opacity(
                      opacity: _iconOpacityAnim.value,
                      child: Container(
                        width: 132,
                        height: 132,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: Image.asset(
                            'assets/app_icon_pro_eda.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Appearing Animated Text: "Работа курьером"
                  SlideTransition(
                    position: _textSlideAnim,
                    child: FadeTransition(
                      opacity: _textFadeAnim,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Работа курьером',
                            textAlign: TextAlign.center,
                            style: AppTypography.headingL.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                              color: const Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Opacity(
                            opacity: _subFadeAnim.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF111111),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Text(
                                'Ежедневный доход • Свободный график',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Bottom loader / version indicator
                  Opacity(
                    opacity: _subFadeAnim.value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF111111),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Официальный сервис подключения',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF111111),
                              fontWeight: FontWeight.w600,
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
