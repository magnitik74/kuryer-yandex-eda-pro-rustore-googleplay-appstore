import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';

class HomeHubTab extends StatefulWidget {
  final VoidCallback onOpenProfile;
  final Function(String courierType) onSelectFormat;
  final VoidCallback onOpenAssistant;

  const HomeHubTab({
    super.key,
    required this.onOpenProfile,
    required this.onSelectFormat,
    required this.onOpenAssistant,
  });

  @override
  State<HomeHubTab> createState() => _HomeHubTabState();
}

class _HomeHubTabState extends State<HomeHubTab> {
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

  void _openFormat(String type) {
    HapticFeedback.mediumImpact();
    _locale.setCourierType(type);
    widget.onSelectFormat(type);
  }

  @override
  Widget build(BuildContext context) {
    final name = _locale.userName.isNotEmpty ? _locale.userName : 'Партнёр';

    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 24.0),
          children: [
            // Top Bar: Brand & Profile Avatar (Yandex Go header standard)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _locale.tr('appName'),
                      style: AppTypography.headingL.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Привет, $name! 👋',
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onOpenProfile();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimarySurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.brandPrimary, width: 2),
                      boxShadow: AppShadows.xs,
                    ),
                    child: Center(
                      child: Text(
                        _locale.userName.isNotEmpty ? _locale.userName[0].toUpperCase() : 'П',
                        style: AppTypography.headingS.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Section Headline (as in Reference 4)
            Text(
              'Выберите сервис',
              style: AppTypography.headingM.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Официальное подключение курьеров с ежедневными выплатами',
              style: AppTypography.bodyS.copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 14),

            // --- 1. SERVICE CARD: АВТОКУРЬЕР ---
            _buildServiceCard(
              title: _locale.tr('autoCourier'),
              tag: 'Высокий доход',
              tagBg: AppColors.brandPrimarySurface,
              tagTextColor: AppColors.textPrimary,
              desc: 'На своем автомобиле или аренда со скидкой',
              icon: PhosphorIcons.car,
              onTap: () => _openFormat('auto'),
            ),

            const SizedBox(height: 10),

            // --- 2. SERVICE CARD: ПЕШИЙ И ВЕЛОКУРЬЕР ---
            _buildServiceCard(
              title: 'Пеший и Велокурьер',
              tag: 'Быстрый старт',
              tagBg: AppColors.feedbackSuccessLight,
              tagTextColor: AppColors.feedbackSuccess,
              desc: 'Свободный график от 2 часов возле дома',
              icon: PhosphorIcons.bicycle,
              onTap: () => _openFormat('bike'),
            ),

            const SizedBox(height: 10),

            // --- 3. SERVICE CARD: МОТОКУРЬЕР ---
            _buildServiceCard(
              title: _locale.tr('motoCourier'),
              tag: 'Без пробок',
              tagBg: const Color(0xFFEFF6FF),
              tagTextColor: const Color(0xFF2563EB),
              desc: 'Быстрая доставка на скутере или мотоцикле',
              icon: PhosphorIcons.moped,
              onTap: () => _openFormat('moto'),
            ),

            const SizedBox(height: 16),

            // --- 4. CONCIERGE ASSISTANT CARD (Yandex Go Banner) ---
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                widget.onOpenAssistant();
              },
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.r20,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary,
                              borderRadius: AppRadius.rPill,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(PhosphorIcons.sparkle, size: 12, color: AppColors.textDarkWarm),
                                const SizedBox(width: 4),
                                Text(
                                  'Помощник 24/7',
                                  style: AppTypography.captionBold.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textDarkWarm,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Персональный помощник',
                            style: AppTypography.headingS.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDarkWarm,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ответит на вопросы в чате и поможет с регистрацией 24/7',
                            style: AppTypography.bodyS.copyWith(
                              color: AppColors.textMutedWarm,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Написать помощнику',
                                style: AppTypography.captionBold.copyWith(
                                  color: AppColors.textDarkWarm,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                PhosphorIcons.arrowRight,
                                size: 14,
                                color: AppColors.textDarkWarm,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 90,
                        child: Image.asset(
                          'assets/onboarding/onb_support_24_7.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- Large Service Card Blueprint (Reference 4 Style) ---
  Widget _buildServiceCard({
    required String title,
    required String tag,
    required Color tagBg,
    required Color tagTextColor,
    required String desc,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.r16,
          boxShadow: AppShadows.xs,
        ),
        child: Row(
          children: [
            // Left Icon Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tagBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 24,
                color: tagTextColor == AppColors.textPrimary ? AppColors.textPrimary : tagTextColor,
              ),
            ),
            const SizedBox(width: 14),

            // Middle Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: AppRadius.rPill,
                        ),
                        child: Text(
                          tag,
                          style: AppTypography.captionBold.copyWith(
                            fontSize: 10,
                            color: tagTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    style: AppTypography.headingS.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: AppTypography.bodyS.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right Chevron
            const Icon(
              PhosphorIcons.caretRight,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
