import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../services/locale_service.dart';
import '../services/rating_service.dart';
import 'curator/curator_tab.dart';
import 'calculator_tab.dart';
import 'roadmap/roadmap_tab.dart';
import 'profile/profile_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final LocaleService _locale = LocaleService();
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _locale.addListener(_onLocaleChanged);
    _checkAppRating();
  }

  @override
  void dispose() {
    _locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  void _checkAppRating() {
    // Ненавязчивый показ оценки через 3 секунды после открытия
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        RatingService().showRating(context);
      }
    });
  }

  void _openProfile() {
    ProfileDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F2),
      bottomNavigationBar: isKeyboardOpen ? null : _buildBottomNavBar(),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            CuratorTab(onOpenProfile: _openProfile),
            IncomeCalculatorTab(onOpenProfile: _openProfile),
            RoadmapTab(onOpenProfile: _openProfile),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    const textDark = Color(0xFF1A1A1A);
    const textGray = Color(0xFF8E8B86);
    const primaryYellow = Color(0xFFFCE000);

    final tabs = [
      {'label': _locale.tr('curator'), 'icon': PhosphorIconsRegular.robot, 'activeIcon': PhosphorIconsFill.robot},
      {'label': _locale.tr('income'), 'icon': PhosphorIconsRegular.calculator, 'activeIcon': PhosphorIconsFill.calculator},
      {'label': _locale.tr('myPath'), 'icon': PhosphorIconsRegular.trendUp, 'activeIcon': PhosphorIconsBold.trendUp},
    ];

    return Container(
      padding: EdgeInsets.only(
        top: 6,
        bottom: 6 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = _selectedTab == idx;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_selectedTab != idx) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedTab = idx);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryYellow.withValues(alpha: 0.3) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        (isSelected ? tabs[idx]['activeIcon'] : tabs[idx]['icon']) as IconData,
                        size: 22,
                        color: isSelected ? textDark : textGray,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tabs[idx]['label'] as String,
                      style: TextStyle(
                        fontFamily: 'MontFamily',
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? textDark : textGray,
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
}
