import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import 'home/home_hub_tab.dart';
import 'curator/curator_tab.dart';
import 'calculator_tab.dart';
import 'roadmap/roadmap_tab.dart';
import 'profile/profile_screen.dart';

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
  }

  @override
  void dispose() {
    _locale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  void _openProfile() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTab = 3;
    });
  }

  void _openAssistant({String? courierFormat}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CuratorTab(
          onOpenProfile: _openProfile,
          initialCourierFormat: courierFormat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      bottomNavigationBar: isKeyboardOpen ? null : _buildBottomNavBar(),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            HomeHubTab(
              onOpenProfile: _openProfile,
              onSelectFormat: (format) => _openAssistant(courierFormat: format),
              onOpenAssistant: () => _openAssistant(),
            ),
            IncomeCalculatorTab(onOpenProfile: _openProfile),
            RoadmapTab(onOpenProfile: _openProfile),
            const ProfileScreen(isTab: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final tabs = [
      {
        'label': _locale.tr('home'),
        'icon': PhosphorIconsRegular.house,
        'activeIcon': PhosphorIconsFill.house,
      },
      {
        'label': _locale.tr('income'),
        'icon': PhosphorIconsRegular.calculator,
        'activeIcon': PhosphorIconsFill.calculator,
      },
      {
        'label': _locale.tr('myPath'),
        'icon': PhosphorIconsRegular.trendUp,
        'activeIcon': PhosphorIconsBold.trendUp,
      },
      {
        'label': 'Профиль',
        'icon': PhosphorIconsRegular.user,
        'activeIcon': PhosphorIconsFill.user,
      },
    ];

    return Container(
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: AppShadows.top,
      ),
      child: Row(
        children: List.generate(tabs.length, (idx) {
          final isSelected = _selectedTab == idx;
          final tab = tabs[idx];

          return Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedTab = idx;
                });
              },
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brandPrimary : Colors.transparent,
                        borderRadius: AppRadius.rPill,
                      ),
                      child: Icon(
                        isSelected
                            ? (tab['activeIcon'] as IconData)
                            : (tab['icon'] as IconData),
                        size: 22,
                        color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tab['label'] as String,
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
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
