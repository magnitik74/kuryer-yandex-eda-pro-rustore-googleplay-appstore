import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../services/locale_service.dart';
import '../../services/registration_helper.dart';

class IncomeCalculatorTab extends StatefulWidget {
  final VoidCallback? onOpenProfile;
  const IncomeCalculatorTab({super.key, this.onOpenProfile});

  @override
  State<IncomeCalculatorTab> createState() => _IncomeCalculatorTabState();
}

class _IncomeCalculatorTabState extends State<IncomeCalculatorTab> with SingleTickerProviderStateMixin {
  final LocaleService _locale = LocaleService();

  int _transportIndex = 1; // 0=Авто, 1=Велосипед, 2=Пеший
  double _hoursPerDay = 8;
  double _daysPerWeek = 5;

  late AnimationController _animController;
  late Animation<double> _incomeAnimation;

  // Почасовые ставки (руб/тенге/сум/сом)
  final Map<String, Map<String, dynamic>> _rates = {
    'ru': {'auto': 950, 'bike': 750, 'walk': 650, 'curr': '₽'},
    'kz': {'auto': 6000, 'bike': 4800, 'walk': 4000, 'curr': '₸'},
    'uz': {'auto': 80000, 'bike': 60000, 'walk': 50000, 'curr': 'UZS'},
    'kg': {'auto': 800, 'bike': 600, 'walk': 500, 'curr': 'сом'},
    'by': {'auto': 25, 'bike': 18, 'walk': 15, 'curr': 'BYN'},
  };

  @override
  void initState() {
    super.initState();
    _locale.addListener(_onLocaleChanged);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _incomeAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _updateIncome(animate: false);
  }

  @override
  void dispose() {
    _locale.removeListener(_onLocaleChanged);
    _animController.dispose();
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) {
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
      _incomeAnimation = Tween<double>(begin: monthlyTotal, end: monthlyTotal).animate(_animController);
      _animController.value = 1.0;
    }
  }

  String _formatNumber(int num) {
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF5F4F2);
    const primaryYellow = Color(0xFFFCE000);
    const textDark = Color(0xFF1A1A1A);

    final country = _locale.workCountry;
    final currency = (_rates[country] ?? _rates['ru']!)['curr'] as String;

    final dailyIncome = _getHourlyRate() * _hoursPerDay;
    // Смен на iPhone 16 (~100 000 руб или эквивалент)
    final int shiftsIphone = dailyIncome > 0 ? (100000 / (country == 'ru' ? dailyIncome : dailyIncome / 10)).clamp(6, 40).round() : 15;
    // Смен на электросамокат (~35 000 руб)
    final int shiftsScooter = dailyIncome > 0 ? (35000 / (country == 'ru' ? dailyIncome : dailyIncome / 10)).clamp(3, 20).round() : 6;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _locale.tr('calcTitle'),
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
          // 1. Segmented Transport Selector
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
            style: const TextStyle(
              fontFamily: 'MontFamily',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: textDark,
            ),
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

          // 5. Sticky Action Button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                RegistrationHelper.startRegistration(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryYellow,
                foregroundColor: textDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(
                _locale.tr('startEarning'),
                style: const TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTransportSelector() {
    const textDark = Color(0xFF1A1A1A);
    const primaryYellow = Color(0xFFFCE000);

    final items = [
      {'label': _locale.tr('chipCar'), 'icon': PhosphorIcons.car},
      {'label': _locale.tr('chipBike'), 'icon': PhosphorIcons.bicycle},
      {'label': _locale.tr('chipWalk'), 'icon': PhosphorIcons.person},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
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
                  color: isSelected ? primaryYellow : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      items[idx]['icon'] as IconData,
                      size: 18,
                      color: textDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      items[idx]['label'] as String,
                      style: TextStyle(
                        fontFamily: 'MontFamily',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: textDark,
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
    const textDark = Color(0xFF1A1A1A);
    const primaryYellow = Color(0xFFFCE000);

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          // Days slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _locale.tr('daysPerWeek'),
                style: const TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F4F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_daysPerWeek.toInt()} дн.',
                  style: const TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryYellow,
              inactiveTrackColor: const Color(0xFFE5E3DF),
              thumbColor: primaryYellow,
              overlayColor: primaryYellow.withValues(alpha: 0.2),
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

          const SizedBox(height: 10),

          // Hours slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _locale.tr('hoursPerDay'),
                style: const TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F4F2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_hoursPerDay.toInt()} ч.',
                  style: const TextStyle(
                    fontFamily: 'MontFamily',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: primaryYellow,
              inactiveTrackColor: const Color(0xFFE5E3DF),
              thumbColor: primaryYellow,
              overlayColor: primaryYellow.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 6,
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

  Widget _buildIncomeDisplayCard(String currency) {
    const textDark = Color(0xFF1A1A1A);
    const textGray = Color(0xFF6B6560);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _locale.tr('approxIncome'),
            style: const TextStyle(
              fontFamily: 'MontFamily',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: textGray,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _incomeAnimation,
            builder: (context, _) {
              final formatted = _formatNumber(_incomeAnimation.value.round());
              return Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$formatted $currency',
                    style: const TextStyle(
                      fontFamily: 'MontFamily',
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '/${_locale.tr('month')}',
                    style: const TextStyle(
                      fontFamily: 'MontFamily',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textGray,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required int shiftsCount,
    required double progress,
  }) {
    const textDark = Color(0xFF1A1A1A);
    const textGray = Color(0xFF6B6560);
    const primaryYellow = Color(0xFFFCE000);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              Text(
                '~ $shiftsCount ${_locale.tr('shifts')}',
                style: const TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: const Color(0xFFF0EFEA),
              valueColor: const AlwaysStoppedAnimation<Color>(primaryYellow),
            ),
          ),
        ],
      ),
    );
  }
}
