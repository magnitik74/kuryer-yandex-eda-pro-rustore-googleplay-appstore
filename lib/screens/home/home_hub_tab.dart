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
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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

            // --- 1. HERO SERVICE CARD: АВТОКУРЬЕР (Reference 4 Style) ---
            _buildServiceCard(
              title: _locale.tr('autoCourier'),
              tag: 'Высокий доход',
              tagBg: AppColors.brandPrimarySurface,
              tagTextColor: AppColors.textPrimary,
              income: 'до 180 000 ₽ / мес',
              desc: 'На своем автомобиле или аренда со скидкой',
              assetImage: 'assets/onboarding/onboarding_2.jpg',
              onTap: () => _openFormat('auto'),
            ),

            const SizedBox(height: 12),

            // --- 2. SERVICE CARD: ПЕШИЙ И ВЕЛОКУРЬЕР ---
            _buildServiceCard(
              title: 'Пеший и Велокурьер',
              tag: 'Быстрый старт',
              tagBg: AppColors.feedbackSuccessLight,
              tagTextColor: AppColors.feedbackSuccess,
              income: 'до 120 000 ₽ / мес',
              desc: 'Свободный график от 2 часов возле дома',
              assetImage: 'assets/onboarding/onboarding_1.jpg',
              onTap: () => _openFormat('bike'),
            ),

            const SizedBox(height: 12),

            // --- 3. SERVICE CARD: МОТОКУРЬЕР ---
            _buildServiceCard(
              title: _locale.tr('motoCourier'),
              tag: 'Без пробок',
              tagBg: const Color(0xFFEFF6FF),
              tagTextColor: const Color(0xFF2563EB),
              income: 'до 150 000 ₽ / мес',
              desc: 'Быстрая доставка на скутере или мотоцикле',
              assetImage: 'assets/onboarding/onboarding_2.jpg',
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
                  borderRadius: AppRadius.r16,
                  boxShadow: AppShadows.s,
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
                                const Icon(PhosphorIcons.sparkle, size: 12, color: AppColors.textPrimary),
                                const SizedBox(width: 4),
                                Text(
                                  'Помощник 24/7',
                                  style: AppTypography.captionBold.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Нужна помощь с анкетой?',
                            style: AppTypography.headingS.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Персональный куратор подскажет, как пройти регистрацию без ошибок.',
                            style: AppTypography.bodyS.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Написать помощнику →',
                            style: AppTypography.captionBold.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 100,
                        child: ClipRRect(
                          borderRadius: AppRadius.r12,
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Colors.transparent, Colors.black, Colors.black],
                                stops: [0.0, 0.25, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: Image.asset(
                              'assets/onboarding/onboarding_3.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
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
    required String income,
    required String desc,
    required String assetImage,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppRadius.r16,
          boxShadow: AppShadows.xs,
        ),
        child: Row(
          children: [
            // Left Content
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pill Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tagBg,
                      borderRadius: AppRadius.rPill,
                    ),
                    child: Text(
                      tag,
                      style: AppTypography.captionBold.copyWith(
                        fontSize: 11,
                        color: tagTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: AppTypography.headingS.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    income,
                    style: AppTypography.bodyM.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Оформить заявку',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.textPrimary),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Right 3D Visual with soft dissolve
            Expanded(
              flex: 4,
              child: SizedBox(
                height: 110,
                child: ClipRRect(
                  borderRadius: AppRadius.r12,
                  child: ShaderMask(
                    shaderCallback: (Rect bounds) {
                      return const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Colors.transparent, Colors.black, Colors.black],
                        stops: [0.0, 0.2, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image.asset(
                      assetImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
