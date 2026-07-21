import 'package:flutter/material.dart';

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
    'az': {'name': 'Азербайджан', 'abbr': 'AZ', 'ratePedestrian': 10, 'rateBike': 12, 'rateAuto': 15, 'currency': '₼', 'referralBonus': 100},
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
      child: Column(
        children: [
          // === HEADER ===
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F0E8),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.only(top: 20, bottom: 28, left: 24, right: 24),
            child: Column(
              children: [
                const Text(
                  "рассчитайте доход курьера",
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF3D3228), letterSpacing: -0.3),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Text(
                      "${_formatCurrency(_animation.value.toInt())} $currency",
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 44,
                        color: Color(0xFF211B15),
                        height: 1.1,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                const Text(
                  "ваш доход в месяц:",
                  style: TextStyle(fontSize: 14, color: Color(0xFF8A7D6B)),
                ),
              ],
            ),
          ),

          // === BODY ===
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Country Dropdown ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCountry,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF3D3228)),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF211B15)),
                      items: _countries.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFFFCE000).withOpacity(0.2),
                                child: Text(
                                  e.value['abbr'],
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF211B15)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(e.value['name']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCountry = val;
                            _updateIncome();
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // --- Transport type ---
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _buildTransportButton(0, "авто", Icons.directions_car),
                      _buildTransportButton(1, "вело", Icons.directions_bike),
                      _buildTransportButton(2, "пеший", Icons.directions_walk),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // --- Days slider ---
                _buildSliderLabel("1–7 дней в неделю", _daysPerWeek.toInt().toString()),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.0,
                    thumbShape: const _NumberThumbShape(),
                    activeTrackColor: const Color(0xFF211B15),
                    inactiveTrackColor: const Color(0xFFE8E0D6),
                    overlayColor: const Color(0x10211B15),
                  ),
                  child: Slider(
                    value: _daysPerWeek,
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: _daysPerWeek.toInt().toString(),
                    onChanged: (val) {
                      setState(() {
                        _daysPerWeek = val;
                        _updateIncome();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // --- Hours slider ---
                _buildSliderLabel("1–12 часов в день", _hoursPerDay.toInt().toString()),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.0,
                    thumbShape: const _NumberThumbShape(),
                    activeTrackColor: const Color(0xFF211B15),
                    inactiveTrackColor: const Color(0xFFE8E0D6),
                    overlayColor: const Color(0x10211B15),
                  ),
                  child: Slider(
                    value: _hoursPerDay,
                    min: 1,
                    max: 12,
                    divisions: 11,
                    label: _hoursPerDay.toInt().toString(),
                    onChanged: (val) {
                      setState(() {
                        _hoursPerDay = val;
                        _updateIncome();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // --- Referral bonus ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
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
                                const Text(
                                  "бонус за друзей",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF8A7D6B)),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.info_outline, size: 16, color: Colors.grey[400]),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "+ ${_formatCurrency(referralBonus * _referralCount)} $currency",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF4CAF50)),
                            ),
                          ],
                        ),
                      ),
                      // Counter
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE8E0D6)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildCounterButton(Icons.remove, () {
                              if (_referralCount > 1) {
                                setState(() => _referralCount--);
                              }
                            }),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                "$_referralCount",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF211B15)),
                              ),
                            ),
                            _buildCounterButton(Icons.add, () {
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
    );
  }

  Widget _buildTransportButton(int index, String label, IconData icon) {
    final isSelected = _transportIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _transportIndex = index;
            _updateIncome();
          });
        },
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF211B15) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : const Color(0xFF8A7D6B)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isSelected ? Colors.white : const Color(0xFF8A7D6B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderLabel(String title, String value) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF8A7D6B)),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: const Color(0xFF3D3228)),
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
    canvas.drawShadow(shadowPath, Colors.black, 4, true);

    // White circle
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
