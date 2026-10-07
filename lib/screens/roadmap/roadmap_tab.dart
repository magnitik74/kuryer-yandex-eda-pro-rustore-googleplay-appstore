import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../services/locale_service.dart';
import '../../services/country_config_service.dart';
import '../../services/rating_service.dart';
import '../../services/local_push_service.dart';
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
  int _currentStep = 1;

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
    if (mounted) {
      setState(() {
        _currentStep = _locale.curatorStage;
      });
    }
  }

  Future<void> _loadProgress() async {
    setState(() {
      _currentStep = _locale.curatorStage;
    });
  }

  Future<void> _saveStep(int step) async {
    HapticFeedback.selectionClick();
    final prevStep = _currentStep;
    setState(() {
      _currentStep = step;
    });
    await _locale.setCuratorStage(step);
    await LocalPushService().scheduleStagePushes(step);

    if (prevStep == 1 && step > 1) {
      if (mounted) {
        RatingService().checkAndPromptRating(context, triggerSource: 'roadmap_step1');
      }
    }
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
                  const Icon(PhosphorIcons.lightbulbFilament, color: AppColors.brandPrimary, size: 24),
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
                          const Icon(PhosphorIcons.warningCircle, color: AppColors.textPrimary, size: 20),
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

  void _showOperatorCallGuideDialog() {
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
                  const Icon(PhosphorIcons.phoneCall, color: AppColors.brandPrimary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _locale.tr('operatorGuideTitle'),
                      style: AppTypography.headingM,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _locale.tr('operatorGuideSub'),
                style: AppTypography.bodyM.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildGuideStep('1', _locale.tr('operatorStep1Title'), _locale.tr('operatorStep1Desc')),
                    _buildGuideStep('2', _locale.tr('operatorStep2Title'), _locale.tr('operatorStep2Desc')),
                    _buildGuideStep('3', _locale.tr('operatorStep3Title'), _locale.tr('operatorStep3Desc')),
                    _buildGuideStep('4', _locale.tr('operatorStep4Title'), _locale.tr('operatorStep4Desc')),
                    _buildGuideStep('5', _locale.tr('operatorStep5Title'), _locale.tr('operatorStep5Desc')),
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
                          const Icon(PhosphorIcons.checkCircle, color: AppColors.textPrimary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locale.tr('cdSubtitle'),
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
                    _locale.tr('gotIt'),
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

  void _showCourierCentersDialog() {
    HapticFeedback.lightImpact();
    final centers = CountryConfigService().courierCenters(_locale.workCountry);
    final pvzNote = CountryConfigService().pvzNote(_locale.workCountry);

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
                  const Icon(PhosphorIcons.tote, color: AppColors.brandPrimary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _locale.tr('cdTitle'),
                      style: AppTypography.headingM,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.feedbackSuccess.withValues(alpha: 0.15),
                      borderRadius: AppRadius.rPill,
                    ),
                    child: Text(
                      _locale.tr('cdFreeBadge'),
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.feedbackSuccess,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _locale.tr('cdSubtitle'),
                style: AppTypography.bodyM.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    if (centers.isNotEmpty) ...[
                      Text(
                        'Курьерские центры:',
                        style: AppTypography.captionBold.copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      ...centers.map((c) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceCard,
                            borderRadius: AppRadius.r12,
                            border: Border.all(color: AppColors.borderDefault),
                          ),
                          child: Row(
                            children: [
                              const Icon(PhosphorIcons.mapPin, color: AppColors.brandPrimary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['city'] as String? ?? '',
                                      style: AppTypography.bodyM.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      c['address'] as String? ?? '',
                                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimarySurface,
                        borderRadius: AppRadius.r12,
                        border: Border.all(color: AppColors.brandPrimary),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(PhosphorIcons.info, color: AppColors.textPrimary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pvzNote.isNotEmpty ? pvzNote : _locale.tr('cdPvzNotice'),
                              style: AppTypography.bodyS.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgSecondary,
                        borderRadius: AppRadius.r12,
                      ),
                      child: Row(
                        children: [
                          const Icon(PhosphorIcons.identificationCard, color: AppColors.textSecondary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _locale.tr('cdDocsRequired'),
                              style: AppTypography.captionBold.copyWith(color: AppColors.textPrimary),
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
                  child: Text('Понятно', style: AppTypography.button),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFirstShiftChecklistDialog() {
    HapticFeedback.lightImpact();
    final items = [
      _locale.tr('checkItem1'),
      _locale.tr('checkItem2'),
      _locale.tr('checkItem3'),
      _locale.tr('checkItem4'),
      _locale.tr('checkItem5'),
    ];

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
                  const Icon(PhosphorIcons.checkSquare, color: AppColors.brandPrimary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _locale.tr('checklistTitle'),
                      style: AppTypography.headingM,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _locale.tr('checklistSubtitle'),
                style: AppTypography.bodyM.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: AppRadius.r12,
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.brandPrimary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${idx + 1}',
                              style: AppTypography.captionBold.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              items[idx],
                              style: AppTypography.bodyM.copyWith(fontWeight: FontWeight.w500),
                            ),
                          ),
                          const Icon(Icons.check_circle_outline, color: AppColors.feedbackSuccess, size: 20),
                        ],
                      ),
                    );
                  },
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
                  child: Text('Готов к смене! 🚀', style: AppTypography.button),
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
              icon: const Icon(PhosphorIcons.userCircle, color: AppColors.textPrimary, size: 26),
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
                const Icon(PhosphorIcons.shieldWarning, color: AppColors.textPrimary, size: 20),
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
            actionLabel: '${_locale.tr('regCardBtn')} →',
            onAction: () => RegistrationHelper.startRegistration(context),
          ),
          const SizedBox(height: 10),
          _buildStepCard(
            stepNumber: 2,
            title: _locale.workCountry != 'ru' ? _locale.tr('cisStep2') : _locale.tr('step2'),
            desc: _locale.workCountry != 'ru' ? _locale.tr('cisStep2Desc') : _locale.tr('step2Desc'),
            actionLabel: _locale.tr('openGuide'),
            onAction: () {
              if (_locale.workCountry == 'ru') {
                _showMoyNalogGuideDialog();
              } else {
                _showOperatorCallGuideDialog();
              }
            },
          ),
          const SizedBox(height: 10),
          _buildStepCard(
            stepNumber: 3,
            title: _locale.tr('step3'),
            desc: _locale.tr('step3Desc'),
            actionLabel: 'Центры выдачи (ЦД) 📍',
            onAction: _showCourierCentersDialog,
          ),
          const SizedBox(height: 10),
          _buildStepCard(
            stepNumber: 4,
            title: _locale.tr('step4'),
            desc: _locale.tr('step4Desc'),
            actionLabel: 'Чек-лист перед сменой 📋',
            onAction: _showFirstShiftChecklistDialog,
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
                    ? PhosphorIcons.check
                    : isBonusStep
                        ? PhosphorIcons.gift
                        : PhosphorIcons.circle,
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
