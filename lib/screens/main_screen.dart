import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sticky_cta_banner.dart';
import '../services/curator_dialogue_engine.dart';
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

  void _onCTATap() {
    final stage = _locale.curatorStage;
    switch (stage) {
      case CuratorStage.greeting:
      case CuratorStage.preRegistration:
      case CuratorStage.registrationSent:
        _openAssistant();
        break;
      case CuratorStage.postRegistration:
        // Открыть чат с контекстом получения сумки
        _openAssistant();
        break;
      case CuratorStage.activeCourier:
      case CuratorStage.churnedRisk:
        setState(() {
          _selectedTab = 1; // Calculator tab
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final showCTA = _selectedTab != 2; // Скрываем на вкладке "Мой путь" (Roadmap) и в чате (CuratorTab открывается как страница)

    // Map CuratorStage to CTAStage
    CTAStage ctaStage;
    switch (_locale.curatorStage) {
      case CuratorStage.greeting:
      case CuratorStage.preRegistration:
        ctaStage = CTAStage.preRegistration;
        break;
      case CuratorStage.registrationSent:
        ctaStage = CTAStage.registrationSent;
        break;
      case CuratorStage.postRegistration:
        ctaStage = CTAStage.postRegistration;
        break;
      case CuratorStage.activeCourier:
      case CuratorStage.churnedRisk:
        ctaStage = CTAStage.activeCourier;
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      bottomNavigationBar: isKeyboardOpen ? null : _buildBottomNavBar(),
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
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
            // Sticky CTA Banner
            if (showCTA && !isKeyboardOpen)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: StickyCTABanner(
                  stage: ctaStage,
                  onTap: _onCTATap,
                  locale: _locale,
                ),
              ),
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
        'label': _locale.tr('profile'),
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