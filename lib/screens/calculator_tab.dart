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

  int _transportIndex = 2; // 0=Авто, 1=Мото, 2=Велосипед, 3=Пеший
  double _hoursPerDay = 8;
  double _daysPerWeek = 5;

  late AnimationController _animController;
  late Animation<double> _incomeAnimation;

  final Map<String, Map<String, dynamic>> _rates = {
    'ru': {'auto': 950, 'moto': 850, 'bike': 750, 'walk': 650, 'curr': '₽'},
    'kz': {'auto': 6000, 'moto': 5400, 'bike': 4800, 'walk': 4000, 'curr': '₸'},
    'uz': {'auto': 80000, 'moto': 70000, 'bike': 60000, 'walk': 50000, 'curr': 'UZS'},
    'kg': {'auto': 800, 'moto': 700, 'bike': 600, 'walk': 500, 'curr': 'сом'},
    'by': {'auto': 25, 'moto': 22, 'bike': 18, 'walk': 15, 'curr': 'BYN'},
  };

  @override
  void initState() {
    super.initState();
    _locale.addListener(_onLocaleChanged);
    _syncTransportFromLocale();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    final monthlyTotal = (rate * _hoursPerDay * _daysPerWeek * 4).toDouble();

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
    final int shiftsIphone = dailyIncome > 0 ? (100000 / (country == 'ru' ? dailyIncome : dailyIncome / 10)).clamp(6, 40).round() : 15;
    final int shiftsScooter = dailyIncome > 0 ? (35000 / (country == 'ru' ? dailyIncome : dailyIncome / 10)).clamp(3, 20).round() : 6;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // 1. Segmented Transport Selector (Auto, Moto, Bike, Walk)
          _buildTransportSelector(),

          const SizedBox(height: 16),

          // 2. Interactive Sliders Card (Days & Hours)
          _buildSlidersCard(),

          const SizedBox(height: 16),

          // 3. Dynamic Large Income Display Card
          _buildIncomeDisplayCard(currency),

          const SizedBox(height: 20),

          // 4. Financial Goals Section ("Цели")
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

          const SizedBox(height: 20),

          // 5. Sticky Action Button (Pill token)
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
                style: AppTypography.button,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTransportSelector() {
    final items = [
      {'label': _locale.tr('chipCar'), 'icon': PhosphorIcons.car},
      {'label': _locale.tr('chipMoto'), 'icon': PhosphorIcons.moped},
      {'label': _locale.tr('chipBike'), 'icon': PhosphorIcons.bicycle},
      {'label': _locale.tr('chipWalk'), 'icon': PhosphorIcons.person},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.r16,
        boxShadow: AppShadows.xs,
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.brandPrimary : Colors.transparent,
                  borderRadius: AppRadius.r12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[idx]['icon'] as IconData,
                      size: 16,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        items[idx]['label'] as String,
                        style: TextStyle(
                          fontFamily: 'MontFamily',
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildSlidersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.r16,
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        children: [
          // Days slider
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
                  borderRadius: AppRadius.r12,
                ),
                child: Text(
                  '${_daysPerWeek.toInt()} дн.',
                  style: AppTypography.captionBold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.brandPrimary,
              inactiveTrackColor: AppColors.borderDefault,
              thumbColor: AppColors.brandPrimary,
              overlayColor: AppColors.brandPrimary.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 6,
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

          const SizedBox(height: 12),

          // Hours slider
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
                  borderRadius: AppRadius.r12,
                ),
                child: Text(
                  '${_hoursPerDay.toInt()} ч.',
                  style: AppTypography.captionBold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.brandPrimary,
              inactiveTrackColor: AppColors.borderDefault,
              thumbColor: AppColors.brandPrimary,
              overlayColor: AppColors.brandPrimary.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 6,
            ),
            child: Slider(
              value: _hoursPerDay,
              min: 2,
              max: 14,
              divisions: 12,
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
            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _locale.tr('approxIncome'),
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatNumber(currentAmount),
                    style: AppTypography.display.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 6),
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
              const SizedBox(height: 8),
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
                    style: AppTypography.caption.copyWith(color: AppColors.feedbackSuccess),
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
              Text(title, style: AppTypography.headingS),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimarySurface,
                  borderRadius: AppRadius.rPill,
                ),
                child: Text(
                  '≈ $shiftsCount ${_locale.tr('shifts')}',
                  style: AppTypography.captionBold.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.bgSecondary,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
