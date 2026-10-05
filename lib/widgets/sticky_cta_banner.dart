import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';

/// Стадии пользователя для определения текста CTA
enum CTAStage {
  preRegistration,   // до регистрации
  registrationSent,  // анкета отправлена
  postRegistration,  // после регистрации, до получения сумки
  activeCourier,     // активный курьер
}

/// Persistent Sticky CTA Banner — висит внизу всех табов (кроме чата)
class StickyCTABanner extends StatefulWidget {
  final CTAStage stage;
  final VoidCallback onTap;
  final LocaleService locale;

  const StickyCTABanner({
    super.key,
    required this.stage,
    required this.onTap,
    required this.locale,
  });

  @override
  State<StickyCTABanner> createState() => _StickyCTABannerState();
}

class _StickyCTABannerState extends State<StickyCTABanner> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  CTAStage _previousStage = CTAStage.preRegistration;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant StickyCTABanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage) {
      _previousStage = oldWidget.stage;
      _animController.reset();
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getTitle() {
    // Use A/B test variant for preRegistration stage
    if (widget.stage == CTAStage.preRegistration) {
      return widget.locale.abTest.getCtaText(widget.locale);
    }
    switch (widget.stage) {
      case CTAStage.preRegistration:
        return widget.locale.tr('cta_fill_anketa'); // «Заполнить Анкету»
      case CTAStage.registrationSent:
        return widget.locale.tr('cta_continue_reg'); // «Продолжить регистрацию»
      case CTAStage.postRegistration:
        return widget.locale.tr('cta_get_bag'); // «Забрать сумку»
      case CTAStage.activeCourier:
        return widget.locale.tr('cta_open_income'); // «Открыть Доход»
    }
  }

  String _getSubtitle() {
    if (widget.stage == CTAStage.preRegistration) {
      final variant = widget.locale.abTest.getVariant(ABTestService.EXP_CTA_TEXT);
      if (variant == 'B') {
        return widget.locale.tr('cta_become_courier_sub');
      }
    }
    switch (widget.stage) {
      case CTAStage.preRegistration:
        return widget.locale.tr('cta_fill_anketa_sub'); // «Официальная анкета партнёра — 2 минуты»
      case CTAStage.registrationSent:
        return widget.locale.tr('cta_continue_reg_sub'); // «Куратор поможет пройти оставшиеся шаги»
      case CTAStage.postRegistration:
        return widget.locale.tr('cta_get_bag_sub'); // «Получи термосумку и выходи на линию»
      case CTAStage.activeCourier:
        return widget.locale.tr('cta_open_income_sub'); // «Посчитай заработок за смену»
    }
  }

  IconData _getIcon() {
    switch (widget.stage) {
      case CTAStage.preRegistration:
        return PhosphorIconsRegular.plusCircle;
      case CTAStage.registrationSent:
        return PhosphorIconsRegular.arrowRight;
      case CTAStage.postRegistration:
        return PhosphorIconsRegular.package;
      case CTAStage.activeCourier:
        return PhosphorIconsRegular.calculator;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: 10 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary,
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getTitle(),
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _getSubtitle(),
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  PhosphorIconsRegular.caretRight,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}