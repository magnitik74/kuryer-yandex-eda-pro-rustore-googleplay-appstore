import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'country_screen.dart';

class PrelandingScreen extends StatefulWidget {
  const PrelandingScreen({super.key});

  @override
  State<PrelandingScreen> createState() => _PrelandingScreenState();
}

class _PrelandingScreenState extends State<PrelandingScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  
  // Staggered visibility
  bool _showStep1 = false;
  bool _showStep2 = false;
  bool _showStep3 = false;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': "Оставьте заявку",
      'desc': "Заполните анкету онлайн за пару минут",
      'icon': PhosphorIcons.fileText,
    },
    {
      'title': "Заберите сумку",
      'desc': "Выберите удобное время и адрес курьерского центра",
      'icon': PhosphorIcons.briefcase,
    },
    {
      'title': "Начните зарабатывать",
      'desc': "Активируйте приложение партнера и выходите на первый заказ",
      'icon': PhosphorIcons.money,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startStaggeredAnimation();
  }

  void _startStaggeredAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _showStep1 = true);
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _showStep2 = true);
    
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _showStep3 = true);
      HapticFeedback.mediumImpact(); // Light vibration when all loaded
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CountryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F2),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF211B15),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.only(top: 40, bottom: 20, left: 8, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(PhosphorIcons.arrowLeft, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Всего 3 шага\nк первому доходу",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      color: Colors.white,
                      height: 1.4,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Steps list (Centered vertically with Expanded)
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStepCard(0, _showStep1),
                    const SizedBox(height: 16),
                    _buildStepCard(1, _showStep2),
                    const SizedBox(height: 16),
                    _buildStepCard(2, _showStep3),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFCE000),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFFFCE000).withOpacity(0.5),
                  ),
                  child: Text(
                    "СТАТЬ КУРЬЕРОМ",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: const Color(0xFF1A1A1A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(int index, bool isVisible) {
    final step = _steps[index];
    
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: isVisible ? Offset.zero : const Offset(0, 0.5),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon circle
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE000).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(step['icon'] as IconData, color: const Color(0xFF211B15), size: 24),
                ),
                const SizedBox(width: 16),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step['title'] as String,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step['desc'] as String,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: const Color(0xFF6B6560),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}





