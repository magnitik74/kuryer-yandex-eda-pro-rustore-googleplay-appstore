import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';

class HomeHubTab extends StatefulWidget {
  final VoidCallback onOpenProfile;
  final Function(String courierType) onSelectFormat;
  final VoidCallback onOpenAssistant;

  const HomeHubTab({
    super.key,
    required this.onOpenProfile,
    required this.onSelectFormat,
    required this.onOpenAssistant,
  });

  @override
  State<HomeHubTab> createState() => _HomeHubTabState();
}

class _HomeHubTabState extends State<HomeHubTab> {
  final LocaleService _locale = LocaleService();

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

  @override
  Widget build(BuildContext context) {
    final name = _locale.userName.isNotEmpty ? _locale.userName : 'Партнёр';

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _locale.tr('appName'),
          style: AppTypography.headingM.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              PhosphorIcons.userCircle,
              color: AppColors.textPrimary,
              size: 26,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              widget.onOpenProfile();
            },
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        children: [
          // Greeting & Prompt
          Text(
            '${_locale.tr('greeting')}, $name! 👋',
            style: AppTypography.headingL,
          ),
          const SizedBox(height: 4),
          Text(
            _locale.tr('chooseFormat'),
            style: AppTypography.bodyM,
          ),

          const SizedBox(height: 20),

          // 2x2 Courier Transport Formats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
            children: [
              _buildCourierCard(
                type: 'auto',
                title: _locale.tr('autoCourier'),
                income: _locale.tr('autoCourierIncome'),
                desc: _locale.tr('autoCourierDesc'),
                icon: PhosphorIcons.car,
              ),
              _buildCourierCard(
                type: 'walk',
                title: _locale.tr('walkCourier'),
                income: _locale.tr('walkCourierIncome'),
                desc: _locale.tr('walkCourierDesc'),
                icon: PhosphorIcons.person,
              ),
              _buildCourierCard(
                type: 'moto',
                title: _locale.tr('motoCourier'),
                income: _locale.tr('motoCourierIncome'),
                desc: _locale.tr('motoCourierDesc'),
                icon: PhosphorIcons.moped,
              ),
              _buildCourierCard(
                type: 'bike',
                title: _locale.tr('bikeCourier'),
                income: _locale.tr('bikeCourierIncome'),
                desc: _locale.tr('bikeCourierDesc'),
                icon: PhosphorIcons.bicycle,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Assistant Snippet Card (Yandex Go chatAssistantRow token)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onOpenAssistant();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: AppRadius.r16,
                boxShadow: AppShadows.s,
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: AppRadius.r12,
                    ),
                    child: const Icon(
                      PhosphorIcons.chatTeardropDots,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _locale.tr('needHelpSnippet'),
                          style: AppTypography.headingS,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _locale.tr('needHelpSubtitle'),
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showFormatBottomSheet({
    required String type,
    required String title,
    required String income,
    required String desc,
    required IconData icon,
  }) {
    HapticFeedback.mediumImpact();
    _locale.setCourierType(type);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimarySurface,
                        borderRadius: AppRadius.r12,
                        border: Border.all(color: AppColors.brandPrimary),
                      ),
                      child: Icon(icon, color: AppColors.textPrimary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: AppTypography.headingM),
                          Text(income, style: AppTypography.bodyM.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: AppRadius.r16,
                  ),
                  child: Row(
                    children: [
                      const Icon(PhosphorIcons.sparkle, color: AppColors.brandPrimary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Персональный помощник готов помочь с оформлением и получением термокороба.',
                          style: AppTypography.bodyS,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      widget.onSelectFormat(type);
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
                      'Перейти к диалогу с помощником',
                      style: AppTypography.button,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourierCard({
    required String type,
    required String title,
    required String income,
    required String desc,
    required IconData icon,
  }) {
    final bool isSelected = _locale.courierType == type;

    return GestureDetector(
      onTap: () {
        _showFormatBottomSheet(
          type: type,
          title: title,
          income: income,
          desc: desc,
          icon: icon,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.r16,
          border: Border.all(
            color: isSelected ? AppColors.brandPrimary : AppColors.borderDefault,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? AppShadows.s : AppShadows.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.brandPrimary : AppColors.bgSecondary,
                    borderRadius: AppRadius.r12,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.brandPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headingS.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  income,
                  style: AppTypography.bodyS.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
