import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/locale_service.dart';
import '../../services/registration_helper.dart';
import '../../services/local_push_service.dart';
import '../../services/ab_test_service.dart';
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

  // Goals
  String? _selectedGoal;
  double _customGoalAmount = 0;
  final TextEditingController _customGoalController = TextEditingController();

  final Map<String, double> _goalPresets = {
    'iphone': 120000,
    'scooter': 60000,
    'vacation': 150000,
  };

  final Map<String, String> _goalNames = {
    'iphone': 'goalIphone',
    'scooter': 'goalScooter',
    'vacation': 'goalVacation',
    'custom': 'goalCustom',
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
    _loadSavedGoal();
  }

  Future<void> _loadSavedGoal() async {
    final prefs = await SharedPreferences.getInstance();
    final goalKey = 'selected_goal_${_locale.workCountry}';
    setState(() {
      _selectedGoal = prefs.getString(goalKey);
      if (_selectedGoal == 'custom') {
        _customGoalAmount = prefs.getDouble('custom_goal_amount_${_locale.workCountry}') ?? 0;
        _customGoalController.text = _customGoalAmount.toInt().toString();
      }
    });
  }

  Future<void> _saveGoal(String goal) async {
      final prefs = await SharedPreferences.getInstance();
      final goalKey = 'selected_goal_${_locale.workCountry}';
      await prefs.setString(goalKey, goal);
      if (goal == 'custom') {
        await prefs.setDouble('custom_goal_amount_${_locale.workCountry}', _customGoalAmount);
      }
    
      // Track goal selection in AppMetrica
      if (goal.isNotEmpty) {
        double goalAmount = goal == 'custom' ? _customGoalAmount : _goalPresets[goal] ?? 0;
        await _locale.trackEvent('goal_selected', params: {
          'goal': goal,
          'goal_amount': goalAmount.round(),
          'country': _locale.workCountry,
          'format': _locale.courierType,
        });
      }
    
      setState(() {
        _selectedGoal = goal;
      });
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
    _customGoalController.dispose();
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) {
      _syncTransportFromLocale();
      _updateIncome(animate: false);
      _loadSavedGoal();
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

      // Check goal progress and schedule reminders
      _checkGoalProgress();
    }

    String _formatNumber(int number) {
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );
    }

    // Track last notified progress to avoid spam
    double _lastNotifiedProgress = 0;
    bool _goalAchievedNotified = false;

    void _checkGoalProgress() {
      if (_selectedGoal == null || _selectedGoal!.isEmpty) {
        _lastNotifiedProgress = 0;
        _goalAchievedNotified = false;
        return;
      }

      double goalAmount = _selectedGoal == 'custom' ? _customGoalAmount : _goalPresets[_selectedGoal] ?? 0;
      if (goalAmount <= 0) return;

      double progress = (_monthlyIncome / goalAmount).clamp(0.0, 1.0);
      int shiftsNeeded = _calculateShiftsNeeded(goalAmount);
      int shiftsCompleted = ((_monthlyIncome / goalAmount) * shiftsNeeded).floor();
      String shiftsWord = _getShiftsWord(shiftsNeeded, _locale.currentLang);

      // 80% reminder - notify once when crossing 80%
      if (progress >= 0.8 && progress < 1.0 && _lastNotifiedProgress < 0.8) {
        _lastNotifiedProgress = progress;
        LocalPushService().scheduleGoalReminders(
          goalName: _locale.tr(_goalNames[_selectedGoal]!),
          shiftsLeft: shiftsNeeded - shiftsCompleted,
          shiftsWord: shiftsWord,
          progress: progress,
        );
      }
      // 100% achievement - notify once
      else if (progress >= 1.0 && !_goalAchievedNotified) {
        _goalAchievedNotified = true;
        LocalPushService().scheduleGoalReminders(
          goalName: _locale.tr(_goalNames[_selectedGoal]!),
          shiftsLeft: 0,
          shiftsWord: shiftsWord,
          progress: progress,
        );

        // Track goal achievement
        _locale.trackEvent('goal_achieved', params: {
          'goal': _selectedGoal,
          'goal_amount': goalAmount.round(),
          'country': _locale.workCountry,
        });
      }
      // Reset flags when progress drops
      else if (progress < 0.8) {
        _lastNotifiedProgress = progress;
        _goalAchievedNotified = false;
      }
    }

    // Goals calculation
      double get _monthlyIncome => _calculateTotalIncome();

      int get _weeklyIncome => (_monthlyIncome / 4.3).round();

      int get _shiftIncome {
        final rate = _getHourlyRate();
        int hoursPerShift = _hoursPerWeek ~/ 4; // Assuming 4 shifts per week average
        if (hoursPerShift < 2) hoursPerShift = 2;
        if (hoursPerShift > 12) hoursPerShift = 12;
        int shiftIncome = rate * hoursPerShift;
        if (_isFastBonus) shiftIncome = (shiftIncome * 1.1).round();
        return shiftIncome;
      }

      int _calculateShiftsNeeded(double goalAmount) {
        if (_shiftIncome <= 0) return 0;
        return (goalAmount / _shiftIncome).ceil();
      }

      String _getShiftsWord(int count, String lang) {
        // Russian pluralization: 1 смена, 2-4 смены, 5+ смен
        if (lang == 'ru') {
          if (count % 10 == 1 && count % 100 != 11) return 'смена';
          if (count % 10 >= 2 && count % 10 <= 4 && (count % 100 < 10 || count % 100 >= 20)) return 'смены';
          return 'смен';
        }
        // For other languages, use generic form
        return _locale.tr('shifts');
      }

      double get _goalProgress {
        if (_selectedGoal == null) return 0;
        double goalAmount = _selectedGoal == 'custom' ? _customGoalAmount : _goalPresets[_selectedGoal] ?? 0;
        if (goalAmount <= 0) return 0;
        return (_monthlyIncome / goalAmount).clamp(0.0, 1.0);
      }

      bool get _showGoalReminder80 => _goalProgress >= 0.8 && _goalProgress < 1.0;
      bool get _showGoalReminder100 => _goalProgress >= 1.0;

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

  void _showGoalPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgWarm,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _locale.tr('goals'),
                      style: AppTypography.cardHeader.copyWith(fontSize: 20),
                    ),
                  ),
                ),
                ..._goalPresets.entries.map((entry) {
                  final key = entry.key;
                  final amount = entry.value;
                  final isSel = _selectedGoal == key;
                  final shiftsNeeded = _calculateShiftsNeeded(amount);
                  final shiftsWord = _getShiftsWord(shiftsNeeded, _locale.currentLang);
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.brandPrimary.withValues(alpha: 0.15) : AppColors.chipLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSel ? AppColors.brandPrimary : AppColors.chipBorder,
                          width: isSel ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        _getGoalIcon(key),
                        color: isSel ? AppColors.brandPrimary : AppColors.textDarkWarm,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      _locale.tr(_goalNames[key]!),
                      style: AppTypography.bodyL.copyWith(
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? AppColors.textDarkWarm : AppColors.textSecondary,
                      ),
                    ),
                    subtitle: Text(
                      _locale.tr('shiftsNeeded').replaceAll('{shifts}', shiftsNeeded.toString())
                        .replaceAll('{shiftsWord}', shiftsWord)
                        .replaceAll('{hours}', (_hoursPerWeek ~/ 4).toString()),
                      style: AppTypography.bodyM.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    trailing: isSel
                        ? const Icon(Icons.check_circle, color: AppColors.brandPrimary, size: 24)
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _saveGoal(key);
                      Navigator.pop(context);
                    },
                  );
                }),
                // Custom goal
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _selectedGoal == 'custom' ? AppColors.brandPrimary.withValues(alpha: 0.15) : AppColors.chipLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedGoal == 'custom' ? AppColors.brandPrimary : AppColors.chipBorder,
                                width: _selectedGoal == 'custom' ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              PhosphorIconsRegular.plusCircle,
                              color: _selectedGoal == 'custom' ? AppColors.brandPrimary : AppColors.textDarkWarm,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _locale.tr('goalCustom'),
                              style: AppTypography.bodyL.copyWith(
                                fontWeight: _selectedGoal == 'custom' ? FontWeight.w700 : FontWeight.w500,
                                color: _selectedGoal == 'custom' ? AppColors.textDarkWarm : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedGoal == 'custom') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _customGoalController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            hintText: 'Сумма цели',
                            hintStyle: AppTypography.bodyM.copyWith(color: AppColors.textMutedWarm),
                            filled: true,
                            fillColor: AppColors.chipLight,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            suffixText: _locale.currency,
                          ),
                          style: AppTypography.bodyL.copyWith(color: AppColors.textDarkWarm),
                          onChanged: (val) {
                            final amount = double.tryParse(val) ?? 0;
                            setState(() {
                              _customGoalAmount = amount;
                            });
                          },
                          onSubmitted: (_) {
                            if (_customGoalAmount > 0) {
                              _saveGoal('custom');
                              Navigator.pop(context);
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _customGoalAmount > 0
                                ? () {
                                    _saveGoal('custom');
                                    Navigator.pop(context);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandPrimary,
                              foregroundColor: AppColors.textDarkWarm,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Сохранить цель',
                              style: AppTypography.button.copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _selectedGoal = 'custom';
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.brandPrimary,
                              side: const BorderSide(color: AppColors.brandPrimary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Задать свою сумму',
                              style: AppTypography.button.copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Clear goal button
                if (_selectedGoal != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          _saveGoal('');
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Убрать цель',
                          style: AppTypography.bodyM.copyWith(
                            color: AppColors.textMutedWarm,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getGoalIcon(String key) {
    switch (key) {
      case 'iphone':
        return PhosphorIconsRegular.deviceMobile;
      case 'scooter':
        return PhosphorIconsRegular.scooter;
      case 'vacation':
        return PhosphorIconsRegular.airplane;
      default:
        return PhosphorIconsRegular.plusCircle;
    }
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
              icon: Icon(PhosphorIcons.userCircle, color: AppColors.textDarkWarm, size: 26),
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
          // 1. Top Controls: City Dropdown + Transport Chips
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

          // 2. Single Slider Section: "часов на слотах в неделю"
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

                // Bonus Checkbox: "доставляю быстрее 2,5 заказа в час"
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

          // 3. Huge Income Result Card
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

                    // Giant Display Number
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

          // 4. GOALS SECTION
          _buildGoalsSection(currency),

          const SizedBox(height: 20),

          // 5. Feature Perks
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

          // 6. CTA Section
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
                    _locale.abTest.getCtaText(_locale),
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

  Widget _buildGoalsSection(String currency) {
    final hasGoal = _selectedGoal != null && _selectedGoal!.isNotEmpty;
    double goalAmount = 0;
    String goalName = '';
    int shiftsNeeded = 0;

    if (hasGoal) {
      if (_selectedGoal == 'custom') {
        goalAmount = _customGoalAmount;
        goalName = _locale.tr('goalCustom');
      } else {
        goalAmount = _goalPresets[_selectedGoal] ?? 0;
        goalName = _locale.tr(_goalNames[_selectedGoal]!);
      }
      shiftsNeeded = _calculateShiftsNeeded(goalAmount);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCardWarm,
        borderRadius: AppRadius.r24,
        border: Border.all(color: AppColors.chipBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with goal picker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _locale.tr('goals'),
                style: AppTypography.cardHeader.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDarkWarm,
                ),
              ),
              GestureDetector(
                onTap: _showGoalPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.chipLight,
                    borderRadius: AppRadius.rPill,
                    border: Border.all(color: AppColors.chipBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasGoal ? PhosphorIconsRegular.pencilSimple : PhosphorIconsRegular.plus,
                        size: 14,
                        color: AppColors.textDarkWarm,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hasGoal ? 'изменить' : 'добавить цель',
                        style: AppTypography.chipLabel.copyWith(
                          color: AppColors.textDarkWarm,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (!hasGoal) ...[
            const SizedBox(height: 16),
            // Empty state - show preset goals as cards
            Column(
              children: _goalPresets.entries.map((entry) {
                final key = entry.key;
                final amount = entry.value;
                final shifts = _calculateShiftsNeeded(amount);
                final shiftsWord = _getShiftsWord(shifts, _locale.currentLang);
                return _buildGoalPresetCard(
                  key: key,
                  icon: _getGoalIcon(key),
                  name: _locale.tr(_goalNames[key]!),
                  amount: amount,
                  shifts: shifts,
                  shiftsWord: shiftsWord,
                  currency: currency,
                );
              }).toList(),
            ),
          ] else ...[
            // Active goal with progress
            const SizedBox(height: 16),
            _buildActiveGoalCard(
              goalName: goalName,
              goalAmount: goalAmount,
              shiftsNeeded: shiftsNeeded,
              currency: currency,
            ),
            
            // Progress bar
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _locale.tr('progressToGoal'),
                      style: AppTypography.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDarkWarm,
                      ),
                    ),
                    Text(
                      '${(_goalProgress * 100).toInt()}%',
                      style: AppTypography.bodyM.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _goalProgress,
                    minHeight: 10,
                    backgroundColor: AppColors.chipLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _goalProgress >= 1.0 ? AppColors.feedbackSuccess : AppColors.brandPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _locale.tr('shiftsNeeded')
                    .replaceAll('{shifts}', shiftsNeeded.toString())
                    .replaceAll('{shiftsWord}', _getShiftsWord(shiftsNeeded, _locale.currentLang))
                    .replaceAll('{hours}', (_hoursPerWeek ~/ 4).toString()),
                  style: AppTypography.bodyM.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            // Reminder messages
            if (_showGoalReminder80) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.bell,
                      color: AppColors.brandPrimary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _locale.tr('goalReminder80')
                          .replaceAll('{shifts}', shiftsNeeded.toString())
                          .replaceAll('{shiftsWord}', _getShiftsWord(shiftsNeeded, _locale.currentLang)),
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.textDarkWarm,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_showGoalReminder100) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.feedbackSuccess.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.feedbackSuccess.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIconsRegular.trophy,
                      color: AppColors.feedbackSuccess,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _locale.tr('goalReminder100').replaceAll('{goalName}', goalName),
                        style: AppTypography.bodyL.copyWith(
                          color: AppColors.feedbackSuccess,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildGoalPresetCard({
    required String key,
    required IconData icon,
    required String name,
    required double amount,
    required int shifts,
    required String shiftsWord,
    required String currency,
  }) {
    final formattedAmount = _formatNumber(amount.round());
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.chipLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.chipBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceCardWarm,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.textDarkWarm, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.bodyL.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDarkWarm,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$formattedAmount $currency',
                  style: AppTypography.bodyM.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$shifts $shiftsWord',
                style: AppTypography.bodyM.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandPrimary,
                ),
              ),
              Text(
                'по ${_hoursPerWeek ~/ 4}ч',
                style: AppTypography.captionBold.copyWith(
                  fontSize: 11,
                  color: AppColors.textMutedWarm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGoalCard({
    required String goalName,
    required double goalAmount,
    required int shiftsNeeded,
    required String currency,
  }) {
    final formattedAmount = _formatNumber(goalAmount.round());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getGoalIcon(_selectedGoal!),
              color: AppColors.brandPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goalName,
                  style: AppTypography.bodyL.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDarkWarm,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Цель: $formattedAmount $currency',
                  style: AppTypography.bodyM.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$shiftsNeeded ${_getShiftsWord(shiftsNeeded, _locale.currentLang)}',
                style: AppTypography.bodyL.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandPrimary,
                ),
              ),
              Text(
                'по ${_hoursPerWeek ~/ 4}ч',
                style: AppTypography.captionBold.copyWith(
                  fontSize: 11,
                  color: AppColors.textMutedWarm,
                ),
              ),
            ],
          ),
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
