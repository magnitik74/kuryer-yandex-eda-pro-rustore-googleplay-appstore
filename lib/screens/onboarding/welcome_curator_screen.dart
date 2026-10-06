import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/locale_service.dart';
import '../main_screen.dart';

class WelcomeCuratorScreen extends StatefulWidget {
  const WelcomeCuratorScreen({super.key});

  @override
  State<WelcomeCuratorScreen> createState() => _WelcomeCuratorScreenState();
}

class _WelcomeCuratorScreenState extends State<WelcomeCuratorScreen> {
  final LocaleService _locale = LocaleService();

  @override
  void initState() {
    super.initState();
    _locale.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    _locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _proceedToApp() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF5F4F2);
    const primaryYellow = Color(0xFFFCE000);
    const textDark = Color(0xFF1A1A1A);
    const textGray = Color(0xFF6B6560);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Language Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryYellow.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIcons.sparkle(), size: 14, color: textDark),
                        SizedBox(width: 4),
                        Text(
                          'Yandex Eda Partner',
                          style: TextStyle(
                            fontFamily: 'MontFamily',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildLanguagePicker(),
                ],
              ),

              const SizedBox(height: 24),

              // Title & Subtitle
              Text(
                _locale.tr('onboardingTitle'),
                style: const TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _locale.tr('onboardingSubtitle'),
                style: const TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: textGray,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // 3 Elevated Feature Cards
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildFeatureCard(
                      icon: PhosphorIcons.robot(),
                      iconBg: const Color(0xFFFFF3B0),
                      title: _locale.tr('card1Title'),
                      desc: _locale.tr('card1Desc'),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: PhosphorIcons.creditCard(),
                      iconBg: const Color(0xFFE2F3E5),
                      title: _locale.tr('card2Title'),
                      desc: _locale.tr('card2Desc'),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: PhosphorIcons.tShirt(),
                      iconBg: const Color(0xFFFFE8E0),
                      title: _locale.tr('card3Title'),
                      desc: _locale.tr('card3Desc'),
                    ),
                  ],
                ),
              ),

              // Big Yellow CTA Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _proceedToApp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    foregroundColor: textDark,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(
                    _locale.tr('onboardingBtn'),
                    style: const TextStyle(
                      fontFamily: 'MontFamily',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguagePicker() {
    final current = _locale.currentLang;
    final langs = [
      {'code': 'ru', 'label': '🇷🇺 RU'},
      {'code': 'uz', 'label': '🇺🇿 UZ'},
      {'code': 'kg', 'label': '🇰🇬 KG'},
      {'code': 'kz', 'label': '🇰🇿 KZ'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: langs.map((l) {
          final isSelected = l['code'] == current;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _locale.setLanguage(l['code']!);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFCE000) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                l['label']!,
                style: TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF1A1A1A), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B6560),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
