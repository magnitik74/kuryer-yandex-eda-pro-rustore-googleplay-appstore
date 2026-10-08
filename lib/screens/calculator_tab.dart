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

  // 0 = авто, 1 = вело, 2 = пеший
  int _transportIndex = 0;
  double _hoursPerWeek = 60;
  bool _isFastBonus = false;
  String _selectedCity = 'Москва';

  late AnimationController _animController;
  late Animation<double> _incomeAnimation;

  final List<String> _cities = const [
    'Москва',
    'Санкт-Петербург',
    'Казань',
    'Новосибирск',
    'Екатеринбург',
    'Нижний Новгород',
    'Самара',
    'Ростов-на-Дону',
    'Ташкент',
    'Алматы',
    'Минск',
    'Бишкек',
  ];

  final Map<String, Map<String, dynamic>> _rates = {
    'ru': {'auto': 694, 'bike': 420, 'walk': 330, 'curr': '₽'},
    'kz': {'auto': 4400, 'bike': 2800, 'walk': 2100, 'curr': '₸'},
    'uz': {'auto': 58000, 'bike': 37000, 'walk': 28000, 'curr': 'UZS'},
    'kg': {'auto': 580, 'bike': 370, 'walk': 280, 'curr': 'сом'},
    'by': {'auto': 17, 'bike': 11, 'walk': 8, 'curr': 'BYN'},
  };

  @override
  void initState() {
    super.initState();
    _locale.addListener(_onLocaleChanged);
    _syncTransportFromLocale();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
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
      case 'bike':
      case 'moto':
        _transportIndex = 1;
        break;
      default:
        _transportIndex = 2;
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
        return data['bike'] as int;
      default:
        return data['walk'] as int;
    }
  }

  double _calculateTotalIncome() {
    final rate = _getHourlyRate();
    // 30 days per month: hoursPerWeek * (30 / 7)
    double monthly = rate * _hoursPerWeek * (30.0 / 7.0);

    if (_isFastBonus) {
      monthly *= 1.10;
    }

    // Strict cap 250 000 ₽ for Auto in RF (12h/day * 7d = 84h/week)
    if (_transportIndex == 0 && _locale.workCountry == 'ru') {
      if (monthly > 250000.0) {
        monthly = 250000.0;
      }
    }

    return monthly;
  }

  void _updateIncome({bool animate = true}) {
    final total = _calculateTotalIncome();
    if (animate) {
      _incomeAnimation = Tween<double>(
        begin: _incomeAnimation.value,
        end: total,
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
      _animController.forward(from: 0);
    } else {
      _incomeAnimation = AlwaysStoppedAnimation(total);
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  void _showCityPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgWarm,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'выберите город',
                    style: AppTypography.cardHeader.copyWith(fontSize: 18),
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _cities.length,
                  itemBuilder: (ctx, idx) {
                    final city = _cities[idx];
                    final isSel = city == _selectedCity;
                    return ListTile(
                      title: Text(
                        city,
                        style: AppTypography.bodyL.copyWith(
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                          color: isSel ? AppColors.textDarkWarm : AppColors.textSecondary,
                        ),
                      ),
                      trailing: isSel
                          ? const Icon(Icons.check, color: AppColors.textDarkWarm)
                          : null,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedCity = city;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final country = _locale.workCountry;
    final currency = (_rates[country] ?? _rates['ru']!)['curr'] as String;

    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'калькулятор дохода',
          style: AppTypography.cardHeader.copyWith(
            fontSize: 20,
            color: AppColors.textDarkWarm,
          ),
        ),
        actions: [
          if (widget.onOpenProfile != null)
            IconButton(
              icon: const Icon(PhosphorIcons.userCircle, color: AppColors.textDarkWarm, size: 26),
              onPressed: () {
                HapticFeedback.selectionClick();
                widget.onOpenProfile!();
              },
            ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // 1. Top Controls: City Dropdown + Transport Chips (Screenshot 2)
          Row(
            children: [
              // City Picker Pill
              GestureDetector(
                onTap: _showCityPicker,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.chipLight,
                    borderRadius: AppRadius.rPill,
                    border: Border.all(color: AppColors.chipBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCity,
                        style: AppTypography.chipLabel.copyWith(
                          color: AppColors.textDarkWarm,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        PhosphorIcons.caretDown,
                        size: 14,
                        color: AppColors.textDarkWarm,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Transport Chips
              Expanded(
                child: Row(
                  children: [
                    _buildTransportChip(
                      idx: 0,
                      label: 'авто',
                      icon: PhosphorIcons.car,
                    ),
                    const SizedBox(width: 6),
                    _buildTransportChip(
                      idx: 1,
                      label: 'вело',
                      icon: PhosphorIcons.bicycle,
                    ),
                    const SizedBox(width: 6),
                    _buildTransportChip(
                      idx: 2,
                      label: 'пеший',
                      icon: PhosphorIcons.person,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Single Slider Section: "часов на слотах в неделю" (Screenshot 2)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: AppColors.chipLight,
              borderRadius: AppRadius.r24,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label + Active Pill Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'часов на слотах в неделю',
                      style: AppTypography.cardSubtitle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDarkWarm,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        borderRadius: AppRadius.rPill,
                      ),
                      child: Text(
                        '${_hoursPerWeek.toInt()} ч.',
                        style: AppTypography.captionBold.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDarkWarm,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Clean Yellow Slider without dots
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.sliderTrackActive,
                    inactiveTrackColor: AppColors.sliderTrackInactive,
                    trackHeight: 8,
                    trackShape: const RoundedRectSliderTrackShape(),
                    tickMarkShape: SliderTickMarkShape.noTickMark,
                    thumbColor: Colors.white,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 13,
                      elevation: 3,
                      pressedElevation: 6,
                    ),
                    overlayColor: AppColors.brandPrimary.withValues(alpha: 0.2),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
                  ),
                  child: Slider(
                    value: _hoursPerWeek,
                    min: 10,
                    max: 84,
                    divisions: 74,
                    onChanged: (val) {
                      if (val.toInt() != _hoursPerWeek.toInt()) {
                        HapticFeedback.selectionClick();
                      }
                      setState(() {
                        _hoursPerWeek = val;
                        _updateIncome();
                      });
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Bonus Checkbox: "доставляю быстрее 2,5 заказа в час" (Screenshot 2)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _isFastBonus = !_isFastBonus;
                      _updateIncome();
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _isFastBonus ? AppColors.textDarkWarm : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _isFastBonus ? AppColors.textDarkWarm : AppColors.chipBorder,
                            width: 1.5,
                          ),
                        ),
                        child: _isFastBonus
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'доставляю быстрее 2,5 заказа в час (+10%)',
                          style: AppTypography.bodyM.copyWith(
                            fontSize: 13,
                            color: AppColors.textDarkWarm,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Huge Income Result Card (Screenshot 2)
          AnimatedBuilder(
            animation: _incomeAnimation,
            builder: (context, child) {
              final currentAmount = _incomeAnimation.value.round();
              final baseAmount = (_getHourlyRate() * _hoursPerWeek * (30.0 / 7.0)).round();

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCardWarm,
                  borderRadius: AppRadius.r28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header (lowercase, clean)
                    Text(
                      'зафиксированный доход в месяц',
                      style: AppTypography.cardSubtitle.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDarkWarm,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Giant Display Number: 108 000 ₽ / 250 000 ₽
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatNumber(currentAmount),
                          style: AppTypography.incomeDisplay.copyWith(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: AppColors.textDarkWarm,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currency,
                          style: AppTypography.cardHeader.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDarkWarm,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE5E2DA), height: 1),
                    const SizedBox(height: 14),

                    // Base sum breakdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'базовая сумма',
                          style: AppTypography.bodyM.copyWith(
                            color: AppColors.textMutedWarm,
                          ),
                        ),
                        Text(
                          '${_formatNumber(baseAmount)} $currency',
                          style: AppTypography.bodyM.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDarkWarm,
                          ),
                        ),
                      ],
                    ),

                    if (_isFastBonus) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'бонус за скорость (+10%)',
                            style: AppTypography.bodyM.copyWith(
                              color: AppColors.feedbackSuccess,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '+${_formatNumber((currentAmount - baseAmount).clamp(0, 50000))} $currency',
                            style: AppTypography.bodyM.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.feedbackSuccess,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Daily payouts highlight
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'выплаты ежедневно на карту любого банка',
                            style: AppTypography.captionBold.copyWith(
                              fontSize: 12,
                              color: AppColors.feedbackSuccess,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // 4. Feature Perks from Screenshot 3
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.chipLight,
              borderRadius: AppRadius.r24,
            ),
            child: Column(
              children: [
                _buildPerkRow(
                  icon: PhosphorIcons.calendarBlank,
                  title: 'свободное расписание',
                  subtitle: 'доставляйте в любое удобное время',
                ),
                const SizedBox(height: 16),
                _buildPerkRow(
                  icon: PhosphorIcons.wallet,
                  title: 'выплаты каждый день',
                  subtitle: 'или каждую неделю — без статуса самозанятого',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 5. CTA Section: "начать зарабатывать прямо сейчас" (Screenshot 3)
          Column(
            children: [
              Text(
                'начать зарабатывать прямо сейчас',
                textAlign: TextAlign.center,
                style: AppTypography.cardHeader.copyWith(
                  fontSize: 20,
                  letterSpacing: -0.4,
                  color: AppColors.textDarkWarm,
                ),
              ),
              const SizedBox(height: 14),

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
                    foregroundColor: AppColors.textDarkWarm,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.rPill,
                    ),
                  ),
                  child: Text(
                    _locale.tr('becomeCourier'),
                    style: AppTypography.button.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textDarkWarm,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTransportChip({
    required int idx,
    required String label,
    required IconData icon,
  }) {
    final isSel = _transportIndex == idx;
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
          height: 44,
          decoration: BoxDecoration(
            color: isSel ? AppColors.chipDark : AppColors.chipLight,
            borderRadius: AppRadius.rPill,
            border: Border.all(
              color: isSel ? AppColors.chipDark : AppColors.chipBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSel ? Colors.white : AppColors.textDarkWarm,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.chipLabel.copyWith(
                  color: isSel ? Colors.white : AppColors.textDarkWarm,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerkRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceCardWarm,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textDarkWarm, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.cardHeader.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.cardSubtitle.copyWith(
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
