import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_flags/country_flags.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import 'onboarding_flow_screen.dart';

class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  final LocaleService _locale = LocaleService();
  late String _selectedLang;

  final List<Map<String, String>> _languages = [
    {
      'code': 'ru',
      'name': 'Русский',
      'native': 'Русский',
      'countryCode': 'RU',
    },
    {
      'code': 'uz',
      'name': "O'zbekcha",
      'native': "O'zbek",
      'countryCode': 'UZ',
    },
    {
      'code': 'kg',
      'name': 'Кыргызча',
      'native': 'Кыргыз',
      'countryCode': 'KG',
    },
    {
      'code': 'kz',
      'name': 'Қазақша',
      'native': 'Қазақ',
      'countryCode': 'KZ',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedLang = _locale.currentLang;
  }

  void _onSelect(String code) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedLang = code;
    });
    _locale.setLanguage(code);
  }

  void _onNext() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Title & Subtitle (strict typography tokens)
              Text(
                _locale.tr('selectLanguage'),
                style: AppTypography.headingXL,
              ),
              const SizedBox(height: 8),
              Text(
                _locale.tr('selectLanguageSub'),
                style: AppTypography.bodyM,
              ),

              const SizedBox(height: 32),

              // 2x2 Language Cards Grid
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _languages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    final isSelected = lang['code'] == _selectedLang;

                    return GestureDetector(
                      onTap: () => _onSelect(lang['code']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: AppRadius.r16,
                          border: Border.all(
                            color: isSelected ? AppColors.brandPrimary : AppColors.borderDefault,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: isSelected ? AppShadows.s : AppShadows.xs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: CountryFlag.fromCountryCode(
                                    lang['countryCode']!,
                                    height: 24,
                                    width: 32,
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: AppColors.brandPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['name']!,
                                  style: AppTypography.headingS.copyWith(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lang['native']!,
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom CTA Button (Yandex Go Pill)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.rPill,
                    ),
                  ),
                  child: Text(
                    _locale.tr('next'),
                    style: AppTypography.button,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
