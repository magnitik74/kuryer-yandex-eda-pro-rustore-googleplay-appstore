import 'package:flutter/material.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class IncomeCalculatorTab extends StatefulWidget {
  const IncomeCalculatorTab({super.key});

  @override
  State<IncomeCalculatorTab> createState() => _IncomeCalculatorTabState();
}

class _IncomeCalculatorTabState extends State<IncomeCalculatorTab> with SingleTickerProviderStateMixin {
  String _selectedCountry = 'ru';
  int _transportIndex = 0; // 0=авто, 1=вело, 2=пеший
  double _hoursPerDay = 8;
  double _daysPerWeek = 5;
  int _referralCount = 1;

  late AnimationController _controller;
  late Animation<double> _animation;

  final Map<String, Map<String, dynamic>> _countries = {
    'ru': {'name': 'Россия', 'abbr': 'RU', 'ratePedestrian': 650, 'rateBike': 750, 'rateAuto': 950, 'currency': '₽', 'referralBonus': 90000},
    'kz': {'name': 'Казахстан', 'abbr': 'KZ', 'ratePedestrian': 4000, 'rateBike': 4800, 'rateAuto': 6000, 'currency': '₸', 'referralBonus': 50000},
    'uz': {'name': 'Узбекистан', 'abbr': 'UZ', 'ratePedestrian': 50000, 'rateBike': 60000, 'rateAuto': 80000, 'currency': 'UZS', 'referralBonus': 500000},
    'by': {'name': 'Беларусь', 'abbr': 'BY', 'ratePedestrian': 15, 'rateBike': 18, 'rateAuto': 25, 'currency': 'BYN', 'referralBonus': 150},
    'kg': {'name': 'Кыргызстан', 'abbr': 'KG', 'ratePedestrian': 500, 'rateBike': 600, 'rateAuto': 800, 'currency': 'сом', 'referralBonus': 5000},
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _updateIncome(animate: false);
  }

  int _getRate() {
    final c = _countries[_selectedCountry]!;
    switch (_transportIndex) {
      case 0: return c['rateAuto'] as int;
      case 1: return c['rateBike'] as int;
      default: return c['ratePedestrian'] as int;
    }
  }

  void _updateIncome({bool animate = true}) {
    final rate = _getRate();
    final targetIncome = (rate * _hoursPerDay * _daysPerWeek * 4).toDouble();

    if (animate) {
      _animation = Tween<double>(begin: _animation.value, end: targetIncome).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.forward(from: 0);
    } else {
      _animation = Tween<double>(begin: targetIncome, end: targetIncome).animate(_controller);
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
  }

  @override
  Widget build(BuildContext context) {
    final countryData = _countries[_selectedCountry]!;
    final currency = countryData['currency'] as String;
    final referralBonus = countryData['referralBonus'] as int;

    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFF5F4F2),
        child: Column(
          children: [
            // === HEADER ===
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.only(top: 24, bottom: 32, left: 24, right: 24),
              child: Column(
                children: [
                  Text(
                    "рассчитайте доход курьера",
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w600, fontSize: 16, color: const Color(0xFF1A1A1A), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Text(
                        "${_formatCurrency(_animation.value.toInt())} $currency",
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 40,
                          color: const Color(0xFF211B15),
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ваш доход в месяц:",
                    style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF6B6560), fontWeight: FontWeight.w500, height: 1.5),
                  ),
                ],
              ),
            ),

            // === BODY ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Country Dropdown ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCountry,
                        isExpanded: true,
                        icon: Icon(PhosphorIcons.caretDown, color: const Color(0xFF1A1A1A), size: 20),
                        style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF1A1A1A)),
                        items: _countries.entries.map((e) {
                          return DropdownMenuItem(
                            value: e.key,
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: CountryFlag.fromCountryCode(
                                      e.value['abbr'],
                                      height: 24,
                                      width: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(e.value['name']),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedCountry = val;
                              _updateIncome();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Transport type ---
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildTransportButton(0, "авто", PhosphorIcons.car),
                        _buildTransportButton(1, "вело", PhosphorIcons.bicycle),
                        _buildTransportButton(2, "пеший", PhosphorIcons.person),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Days slider ---
                  _buildSliderLabel("Дней в неделю", _daysPerWeek.toInt().toString()),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.0,
                      thumbShape: const _NumberThumbShape(),
                      activeTrackColor: const Color(0xFF211B15),
                      inactiveTrackColor: const Color(0xFFF5F4F2),
                      overlayColor: const Color(0x10211B15),
                    ),
                    child: Slider(
                      value: _daysPerWeek,
                      min: 1,
                      max: 7,
                      divisions: 6,
                      label: _daysPerWeek.toInt().toString(),
                      onChanged: (val) {
                        if (_daysPerWeek.toInt() != val.toInt()) {
                          HapticFeedback.selectionClick();
                        }
                        setState(() {
                          _daysPerWeek = val;
                          _updateIncome();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Hours slider ---
                  _buildSliderLabel("Часов в день", _hoursPerDay.toInt().toString()),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.0,
                      thumbShape: const _NumberThumbShape(),
                      activeTrackColor: const Color(0xFF211B15),
                      inactiveTrackColor: const Color(0xFFF5F4F2),
                      overlayColor: const Color(0x10211B15),
                    ),
                    child: Slider(
                      value: _hoursPerDay,
                      min: 1,
                      max: 12,
                      divisions: 11,
                      label: _hoursPerDay.toInt().toString(),
                      onChanged: (val) {
                        if (_hoursPerDay.toInt() != val.toInt()) {
                          HapticFeedback.selectionClick();
                        }
                        setState(() {
                          _hoursPerDay = val;
                          _updateIncome();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Referral bonus ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "бонус за друзей",
                                    style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF6B6560), height: 1.5),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(PhosphorIcons.info, size: 16, color: const Color(0xFF6B6560)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "+ ${_formatCurrency(referralBonus * _referralCount)} $currency",
                                style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF4CAF50), letterSpacing: -0.5),
                              ),
                            ],
                          ),
                        ),
                        // Counter
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFF5F4F2), width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              _buildCounterButton(PhosphorIcons.minus, () {
                                if (_referralCount > 1) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _referralCount--);
                                }
                              }),
                              Container(
                                width: 44,
                                alignment: Alignment.center,
                                child: Text(
                                  "$_referralCount",
                                  style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
                                ),
                              ),
                              _buildCounterButton(PhosphorIcons.plus, () {
                                HapticFeedback.selectionClick();
                                setState(() => _referralCount++);
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportButton(int index, String label, IconData icon) {
    final isSelected = _transportIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_transportIndex != index) {
            HapticFeedback.selectionClick();
            setState(() {
              _transportIndex = index;
              _updateIncome();
            });
          }
        },
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFCE000) : Colors.transparent, // Brand accent
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? const Color(0xFF211B15) : const Color(0xFF6B6560)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  color: isSelected ? const Color(0xFF211B15) : const Color(0xFF6B6560),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderLabel(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF6B6560), height: 1.5),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
        ),
      ],
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: const Color(0xFF1A1A1A)),
      ),
    );
  }
}

// Custom thumb shape that shows the number inside a yellow circle
class _NumberThumbShape extends SliderComponentShape {
  const _NumberThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(28, 28);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Drop Shadow
    final shadowPath = Path()..addOval(Rect.fromCircle(center: center.translate(0, 2), radius: 14));
    canvas.drawShadow(shadowPath, Colors.black.withOpacity(0.03), 8, true);

    // Thumb background
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 14, paint);

    // Number text
    labelPainter.paint(
      canvas,
      Offset(center.dx - labelPainter.width / 2, center.dy - labelPainter.height / 2),
    );
  }
}





