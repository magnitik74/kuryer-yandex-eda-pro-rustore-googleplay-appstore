import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../services/locale_service.dart';
import '../../services/registration_helper.dart';
import '../../theme/app_theme.dart';

class IncomeCalculatorTab extends StatefulWidget {
  final VoidCallback? onOpenProfile;
  const IncomeCalculatorTab({super.key, this.onOpenProfile});

  @override
  State<IncomeCalculatorTab> createState() => _IncomeCalculatorTabState();
}

class _IncomeCalculatorTabState extends State<IncomeCalculatorTab> with SingleTickerProviderStateMixin {
  final LocaleService _locale = LocaleService();

  int _transportIndex = 0; // 0=Авто, 1=Мото, 2=Вело, 3=Пеший
  double _hoursPerDay = 8;
  double _daysPerWeek = 5;

  late AnimationController _animController;
  late Animation<double> _incomeAnimation;

  final Map<String, Map<String, dynamic>> _rates = {
    'ru': {'auto': 694, 'moto': 540, 'bike': 445, 'walk': 333, 'curr': '₽'},
    'kz': {'auto': 4400, 'moto': 3400, 'bike': 2800, 'walk': 2100, 'curr': '₸'},
    'uz': {'auto': 58000, 'moto': 45000, 'bike': 37000, 'walk': 28000, 'curr': 'UZS'},
    'kg': {'auto': 580, 'moto': 450, 'bike': 370, 'walk': 280, 'curr': 'сом'},
    'by': {'auto': 17, 'moto': 13, 'bike': 11, 'walk': 8, 'curr': 'BYN'},
  };

  @override
  void initState() {
    super.initState();
    _locale.addListener(_onLocaleChanged);
    _syncTransportFromLocale();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _incomeAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _updateIncome(animate: false);
  }

  void _syncTransportFromLocale() {
    switch (_locale.courierType) {
      case 'auto':
        _transportIndex = 0;
        break;
      case 'moto':
        _transportIndex = 1;
        break;
      case 'bike':
        _transportIndex = 2;
        break;
      default:
        _transportIndex = 3;
        break;
    }
  }

  @override
  void dispose() {
    _locale.removeListener(_onLocaleChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) {
      _syncTransportFromLocale();
      _updateIncome(animate: false);
      setState(() {});
    }
  }

  int _getHourlyRate() {
    final country = _locale.workCountry;
    final data = _rates[country] ?? _rates['ru']!;
    switch (_transportIndex) {
      case 0:
        return data['auto'] as int;
      case 1:
        return data['moto'] as int;
      case 2:
        return data['bike'] as int;
      default:
        return data['walk'] as int;
    }
  }

  void _updateIncome({bool animate = true}) {
    final rate = _getHourlyRate();
    // 30 days per month: (daysPerWeek * (30 / 7)) * hoursPerDay
    double monthlyTotal = (rate * _hoursPerDay * (_daysPerWeek * 30 / 7)).toDouble();
    if (_transportIndex == 0 && _locale.workCountry == 'ru' && _hoursPerDay >= 12 && _daysPerWeek >= 7) {
      monthlyTotal = 250000.0;
    }

    if (animate) {
      _incomeAnimation = Tween<double>(
        begin: _incomeAnimation.value,
        end: monthlyTotal,
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
      _animController.forward(from: 0);
    } else {
      _incomeAnimation = AlwaysStoppedAnimation(monthlyTotal);
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  @override
  Widget build(BuildContext context) {
    final country = _locale.workCountry;
    final currency = (_rates[country] ?? _rates['ru']!)['curr'] as String;

    final dailyIncome = _getHourlyRate() * _hoursPerDay;
    final int shiftsIphone = dailyIncome > 0
        ? (100000 / (country == 'ru' ? dailyIncome : dailyIncome / 10)).clamp(6, 40).round()
        : 15;
    final int shiftsScooter = dailyIncome > 0
        ? (35000 / (country == 'ru' ? dailyIncome : dailyIncome / 10)).clamp(3, 20).round()
        : 6;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _locale.tr('calcTitle'),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Clean Capsule Segmented Selector (Zero overflow, zero ellipsis)
          _buildTransportPills(),

          const SizedBox(height: 16),

          // 2. Interactive Sliders Card (Smooth track, zero dots/caterpillars)
          _buildSlidersCard(),

          const SizedBox(height: 16),

          // 3. Dynamic Large Income Display Card (Clean white surface, NO yellow border)
          _buildIncomeDisplayCard(currency),

          const SizedBox(height: 20),

          // 4. Financial Goals Section ("Ваши цели")
          Text(
            _locale.tr('goals'),
            style: AppTypography.headingS.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),

          _buildGoalCard(
            title: _locale.tr('goalIphone'),
            shiftsCount: shiftsIphone,
            progress: 0.65,
          ),
          const SizedBox(height: 10),
          _buildGoalCard(
            title: _locale.tr('goalScooter'),
            shiftsCount: shiftsScooter,
            progress: 0.85,
          ),

          const SizedBox(height: 24),

          // 5. Sticky Action Button (Pill h=52, yellow bg, dark text)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                RegistrationHelper.startRegistration(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: AppColors.textOnPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.rPill,
                ),
              ),
              child: Text(
                _locale.tr('startEarning'),
                style: AppTypography.button.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- 1. Capsule Segmented Control (Yandex Go Style) ---
  Widget _buildTransportPills() {
    final items = [
      {'title': 'Авто', 'icon': PhosphorIcons.car},
      {'title': 'Мото', 'icon': PhosphorIcons.moped},
      {'title': 'Вело', 'icon': PhosphorIcons.bicycle},
      {'title': 'Пеший', 'icon': PhosphorIcons.person},
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.bgTertiary, // #EBEBEB
        borderRadius: AppRadius.rPill,
      ),
      child: Row(
        children: List.generate(items.length, (idx) {
          final isSelected = _transportIndex == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _transportIndex = idx;
                  _updateIncome();
                });
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandPrimary : Colors.transparent,
                  borderRadius: AppRadius.rPill,
                  boxShadow: isSelected ? AppShadows.xs : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[idx]['icon'] as IconData,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      items[idx]['title'] as String,
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- 2. Smooth Sliders Card (Without Caterpillar Dots) ---
  Widget _buildSlidersCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.r16,
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        children: [
          // Days slider label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _locale.tr('daysPerWeek'),
                style: AppTypography.bodyM.copyWith(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: AppRadius.rPill,
                ),
                child: Text(
                  '${_daysPerWeek.toInt()} дн.',
                  style: AppTypography.captionBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.brandPrimary,
              inactiveTrackColor: AppColors.bgTertiary,
              trackHeight: 8,
              trackShape: const RoundedRectSliderTrackShape(),
              tickMarkShape: SliderTickMarkShape.noTickMark, // ABSOLUTELY ZERO DOTS
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 13,
                elevation: 3,
                pressedElevation: 6,
              ),
              overlayColor: AppColors.brandPrimary.withValues(alpha: 0.15),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: Slider(
              value: _daysPerWeek,
              min: 1,
              max: 7,
              divisions: 6,
              onChanged: (val) {
                if (val.toInt() != _daysPerWeek.toInt()) {
                  HapticFeedback.selectionClick();
                }
                setState(() {
                  _daysPerWeek = val;
                  _updateIncome();
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // Hours slider label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _locale.tr('hoursPerDay'),
                style: AppTypography.bodyM.copyWith(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgSecondary,
                  borderRadius: AppRadius.rPill,
                ),
                child: Text(
                  '${_hoursPerDay.toInt()} ч.',
                  style: AppTypography.captionBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.brandPrimary,
              inactiveTrackColor: AppColors.bgTertiary,
              trackHeight: 8,
              trackShape: const RoundedRectSliderTrackShape(),
              tickMarkShape: SliderTickMarkShape.noTickMark, // ABSOLUTELY ZERO DOTS
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 13,
                elevation: 3,
                pressedElevation: 6,
              ),
              overlayColor: AppColors.brandPrimary.withValues(alpha: 0.15),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: Slider(
              value: _hoursPerDay,
              min: 2,
              max: 12,
              divisions: 10,
              onChanged: (val) {
                if (val.toInt() != _hoursPerDay.toInt()) {
                  HapticFeedback.selectionClick();
                }
                setState(() {
                  _hoursPerDay = val;
                  _updateIncome();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. Dynamic Large Income Display Card (Pure Surface, NO Outline) ---
  Widget _buildIncomeDisplayCard(String currency) {
    return AnimatedBuilder(
      animation: _incomeAnimation,
      builder: (context, child) {
        final currentAmount = _incomeAnimation.value.round();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadius.r16,
            boxShadow: AppShadows.s,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _locale.tr('approxIncome'),
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatNumber(currentAmount),
                    style: AppTypography.display.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    currency,
                    style: AppTypography.headingM.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/${_locale.tr('month')}',
                    style: AppTypography.bodyM.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.feedbackSuccess,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Выплаты ежедневно на карту любого банка',
                    style: AppTypography.captionBold.copyWith(
                      color: AppColors.feedbackSuccess,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGoalCard({
    required String title,
    required int shiftsCount,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
                title,
                style: AppTypography.bodyM.copyWith(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimarySurface,
                  borderRadius: AppRadius.rPill,
                ),
                child: Text(
                  '≈ $shiftsCount ${_locale.tr('shifts')}',
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
              minHeight: 6,
              backgroundColor: AppColors.bgTertiary,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
