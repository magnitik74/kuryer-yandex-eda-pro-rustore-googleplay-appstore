import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/locale_service.dart';
import '../../services/registration_helper.dart';
import '../../theme/app_theme.dart';

class RoadmapTab extends StatefulWidget {
  final VoidCallback? onOpenProfile;
  const RoadmapTab({super.key, this.onOpenProfile});

  @override
  State<RoadmapTab> createState() => _RoadmapTabState();
}

class _RoadmapTabState extends State<RoadmapTab> {
  final LocaleService _locale = LocaleService();
  int _currentStep = 2; // Default to step 2 (Связка с сервисом)

  @override
  void initState() {
    super.initState();
    _locale.addListener(_onLocaleChanged);
    _loadProgress();
  }

  @override
  void dispose() {
    _locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentStep = prefs.getInt('roadmap_step') ?? 2;
    });
  }

  Future<void> _saveStep(int step) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('roadmap_step', step);
    setState(() {
      _currentStep = step;
    });
  }

  void _showMoyNalogGuideDialog() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(PhosphorIcons.lightbulbFilament(), color: AppColors.brandPrimary, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'Шпаргалка: Мой налог',
                    style: AppTypography.headingM,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Большинство задержек происходят из-за того, что сервис доставки не подключен в приложении «Мой налог». Вот как сделать это за 1 минуту:',
                style: AppTypography.bodyM.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildGuideStep('1', 'Откройте «Мой налог»', 'Войдите под тем же номером телефона, что и в анкете курьера.'),
                    _buildGuideStep('2', 'Перейдите в «Прочее»', 'В правом нижнем углу нажмите кнопку «Прочее» (три точки).'),
                    _buildGuideStep('3', 'Откройте «Партнёры»', 'Найдите список доступных партнёров сервиса.'),
                    _buildGuideStep('4', 'Нажмите «Сервис доставки»', 'В списке найдите сервис доставки (Еда) и нажмите на него.'),
                    _buildGuideStep('5', 'Нажмите «Разрешить»', 'Подтвердите базовые права. Теперь статус самозанятости подтвержден!'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimarySurface,
                        borderRadius: AppRadius.r16,
                        border: Border.all(color: AppColors.brandPrimary),
                      ),
                      child: Row(
                        children: [
                          Icon(PhosphorIcons.warningCircle(), color: AppColors.textPrimary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Если в приложении ошибка сети — обязательно выключите VPN!',
                              style: AppTypography.bodyS.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.rPill),
                  ),
                  child: Text(
                    'Понятно, продолжить',
                    style: AppTypography.button,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuideStep(String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.brandPrimarySurface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              num,
              style: AppTypography.captionBold.copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyM.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = (_currentStep / 5.0).clamp(0.1, 1.0);

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _locale.tr('roadmapTitle'),
          style: AppTypography.headingM.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (widget.onOpenProfile != null)
            IconButton(
              icon: Icon(PhosphorIcons.userCircle(), color: AppColors.textPrimary, size: 26),
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onOpenProfile!();
              },
            ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. Overall Progress Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: AppRadius.r16,
              boxShadow: AppShadows.xs,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Прогресс пути',
                      style: AppTypography.bodyM.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimarySurface,
                        borderRadius: AppRadius.rPill,
                      ),
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: AppTypography.captionBold.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.borderDefault,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _locale.tr('roadmapSubtitle'),
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. VPN warning helper
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.brandPrimarySurface,
              borderRadius: AppRadius.r16,
              border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.shieldWarning(), color: AppColors.textPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locale.tr('vpnWarning'),
                    style: AppTypography.captionBold.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. 5 Roadmap Steps Cards
          _buildStepCard(
            stepNumber: 1,
            title: _locale.tr('step1'),
            desc: _locale.tr('step1Desc'),
            actionLabel: 'Заполнить анкету →',
            onAction: () => RegistrationHelper.startRegistration(context),
          ),
          const SizedBox(height: 10),
          _buildStepCard(
            stepNumber: 2,
            title: _locale.tr('step2'),
            desc: _locale.tr('step2Desc'),
            actionLabel: _locale.tr('openGuide'),
            onAction: _showMoyNalogGuideDialog,
          ),
          const SizedBox(height: 10),
          _buildStepCard(
            stepNumber: 3,
            title: _locale.tr('step3'),
            desc: _locale.tr('step3Desc'),
          ),
          const SizedBox(height: 10),
          _buildStepCard(
            stepNumber: 4,
            title: _locale.tr('step4'),
            desc: _locale.tr('step4Desc'),
          ),
          const SizedBox(height: 10),
          _buildStepCard(
            stepNumber: 5,
            title: _locale.tr('step5'),
            desc: _locale.tr('step5Desc'),
            isBonusStep: true,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String desc,
    String? actionLabel,
    VoidCallback? onAction,
    bool isBonusStep = false,
  }) {
    final isDone = _currentStep > stepNumber;
    final isCurrent = _currentStep == stepNumber;

    return GestureDetector(
      onTap: () => _saveStep(stepNumber),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.r16,
          border: Border.all(
            color: isCurrent ? AppColors.brandPrimary : Colors.transparent,
            width: isCurrent ? 2.0 : 1.0,
          ),
          boxShadow: isCurrent ? AppShadows.s : AppShadows.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Icon Indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDone
                    ? AppColors.feedbackSuccess
                    : isCurrent
                        ? AppColors.brandPrimary
                        : AppColors.bgSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDone
                    ? PhosphorIcons.check()
                    : isBonusStep
                        ? PhosphorIcons.gift()
                        : PhosphorIcons.circle(),
                size: 16,
                color: isDone
                    ? Colors.white
                    : isCurrent
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 14),
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$stepNumber. $title',
                    style: AppTypography.bodyL.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: onAction,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.brandPrimarySurface,
                          borderRadius: AppRadius.rPill,
                          border: Border.all(color: AppColors.brandPrimary),
                        ),
                        child: Text(
                          actionLabel,
                          style: AppTypography.captionBold.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
