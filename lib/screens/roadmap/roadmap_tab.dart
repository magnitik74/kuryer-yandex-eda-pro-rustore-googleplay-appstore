import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/locale_service.dart';
import '../../services/registration_helper.dart';

class RoadmapTab extends StatefulWidget {
  final VoidCallback? onOpenProfile;
  const RoadmapTab({super.key, this.onOpenProfile});

  @override
  State<RoadmapTab> createState() => _RoadmapTabState();
}

class _RoadmapTabState extends State<RoadmapTab> {
  final LocaleService _locale = LocaleService();
  int _currentStep = 2; // По умолчанию на шаге 2 (Связка с Мой налог)

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
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E3DF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(PhosphorIcons.lightbulbFilament, color: Color(0xFFFCE000), size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Шпаргалка: Мой налог',
                    style: TextStyle(
                      fontFamily: 'MontFamily',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Большинство ошибок происходят из-за того, что сервис доставки не подключен в приложении «Мой налог». Вот как сделать это за 1 минуту:',
                style: TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 13,
                  color: Color(0xFF6B6560),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildGuideStep('1', 'Откройте «Мой налог»', 'Войдите под тем же номером телефона, что и в анкете курьера.'),
                    _buildGuideStep('2', 'Перейдите в «Прочее»', 'В правом нижнем углу нажмите кнопку «Прочее» (иконка трёх точек).'),
                    _buildGuideStep('3', 'Откройте «Партнёры»', 'Найдите список доступных партнёров.'),
                    _buildGuideStep('4', 'Нажмите «Сервис доставки»', 'В списке найдите сервис доставки (Еда) и нажмите на него.'),
                    _buildGuideStep('5', 'Нажмите «Разрешить»', 'Подтвердите базовые права. Теперь статус самозанятости подтвержден!'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3B0).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(PhosphorIcons.warningCircle, color: Color(0xFF1A1A1A), size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Если в приложении ошибка сети — обязательно выключите VPN!',
                              style: TextStyle(
                                fontFamily: 'MontFamily',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
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
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFCE000),
                    foregroundColor: const Color(0xFF1A1A1A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text(
                    'Понятно, продолжить',
                    style: TextStyle(
                      fontFamily: 'MontFamily',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
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
            decoration: BoxDecoration(
              color: const Color(0xFFFCE000).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              num,
              style: const TextStyle(
                fontFamily: 'MontFamily',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 12,
                    color: Color(0xFF6B6560),
                    height: 1.3,
                  ),
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
    const bgColor = Color(0xFFF5F4F2);
    const primaryYellow = Color(0xFFFCE000);
    const textDark = Color(0xFF1A1A1A);
    const textGray = Color(0xFF6B6560);

    final double progress = (_currentStep / 5.0).clamp(0.1, 1.0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _locale.tr('roadmapTitle'),
          style: const TextStyle(
            fontFamily: 'MontFamily',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
        actions: [
          if (widget.onOpenProfile != null)
            IconButton(
              icon: const Icon(PhosphorIcons.userCircle, color: textDark, size: 26),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Прогресс пути',
                      style: TextStyle(
                        fontFamily: 'MontFamily',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontFamily: 'MontFamily',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF0EFEA),
                    valueColor: const AlwaysStoppedAnimation<Color>(primaryYellow),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _locale.tr('roadmapSubtitle'),
                  style: const TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 12,
                    color: textGray,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. VPN warning helper
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3B0).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIcons.shieldWarning, color: textDark, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _locale.tr('vpnWarning'),
                    style: const TextStyle(
                      fontFamily: 'MontFamily',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
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
    const textDark = Color(0xFF1A1A1A);
    const textGray = Color(0xFF6B6560);
    const primaryYellow = Color(0xFFFCE000);

    final isDone = _currentStep > stepNumber;
    final isCurrent = _currentStep == stepNumber;

    return GestureDetector(
      onTap: () => _saveStep(stepNumber),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: isCurrent
              ? Border.all(color: primaryYellow, width: 2)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
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
                    ? const Color(0xFF28C76F)
                    : isCurrent
                        ? primaryYellow
                        : const Color(0xFFF5F4F2),
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
                        ? textDark
                        : textGray,
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
                    style: const TextStyle(
                      fontFamily: 'MontFamily',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontFamily: 'MontFamily',
                      fontSize: 12,
                      color: textGray,
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: onAction,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryYellow.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          actionLabel,
                          style: const TextStyle(
                            fontFamily: 'MontFamily',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: textDark,
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
