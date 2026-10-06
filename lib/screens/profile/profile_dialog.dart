import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_flags/country_flags.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileDialog(),
    );
  }

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  final LocaleService _locale = LocaleService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _selectedCountry;
  late String _selectedDialCode;
  late String _selectedFormat;

  final List<Map<String, String>> _countries = [
    {'id': 'ru', 'name': 'Россия', 'flag': 'RU', 'code': '+7'},
    {'id': 'kz', 'name': 'Казахстан', 'flag': 'KZ', 'code': '+7'},
    {'id': 'uz', 'name': 'Узбекистан', 'flag': 'UZ', 'code': '+998'},
    {'id': 'kg', 'name': 'Кыргызстан', 'flag': 'KG', 'code': '+996'},
    {'id': 'by', 'name': 'Беларусь', 'flag': 'BY', 'code': '+375'},
  ];

  final List<Map<String, dynamic>> _formats = [
    {'id': 'auto', 'name': 'Автокурьер', 'icon': PhosphorIcons.car()},
    {'id': 'walk', 'name': 'Пеший курьер', 'icon': PhosphorIcons.person()},
    {'id': 'moto', 'name': 'Мотокурьер', 'icon': PhosphorIcons.moped()},
    {'id': 'bike', 'name': 'Велокурьер', 'icon': PhosphorIcons.bicycle()},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _locale.userName);
    _phoneController = TextEditingController(text: _locale.userPhone);
    _selectedCountry = _locale.workCountry;
    _selectedDialCode = _locale.phoneDialCode;
    _selectedFormat = _locale.courierType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    HapticFeedback.lightImpact();
    await _locale.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      dialCode: _selectedDialCode,
      country: _selectedCountry,
      courierType: _selectedFormat,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r20),
        title: Text(
          _locale.tr('deleteAccount'),
          style: AppTypography.headingM,
        ),
        content: Text(
          _locale.tr('deleteConfirm'),
          style: AppTypography.bodyM,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              _locale.tr('cancel'),
              style: AppTypography.bodyM.copyWith(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.feedbackError,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
            ),
            child: Text(
              _locale.tr('delete'),
              style: AppTypography.button.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _locale.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Профиль успешно удалён'),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Handle (Token: 36x4, #D4D2CF)
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
            const SizedBox(height: 16),

            // Header Row: Profile Title + Language selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _locale.tr('profile'),
                  style: AppTypography.headingM.copyWith(fontWeight: FontWeight.w700),
                ),
                _buildLangSelector(),
              ],
            ),
            const SizedBox(height: 20),

            // 1. Страна работы (важно для реферальных ссылок)
            Text(
              _locale.tr('workCountry'),
              style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceInput,
                borderRadius: AppRadius.r12,
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountry,
                  isExpanded: true,
                  items: _countries.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['id'],
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: CountryFlag.fromCountryCode(
                              c['flag']!,
                              height: 16,
                              width: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            c['name']!,
                            style: AppTypography.bodyL,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCountry = val;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Формат доставки
            Text(
              _locale.tr('format'),
              style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceInput,
                borderRadius: AppRadius.r12,
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedFormat,
                  isExpanded: true,
                  items: _formats.map((f) {
                    return DropdownMenuItem<String>(
                      value: f['id'] as String,
                      child: Row(
                        children: [
                          Icon(f['icon'] as IconData, size: 20, color: AppColors.textPrimary),
                          const SizedBox(width: 10),
                          Text(f['name'] as String, style: AppTypography.bodyL),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedFormat = val;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. Имя
            Text(
              _locale.tr('name'),
              style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceInput,
                borderRadius: AppRadius.r12,
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Имя',
                  hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                ),
                style: AppTypography.bodyL,
              ),
            ),

            const SizedBox(height: 16),

            // 4. Телефон
            Text(
              _locale.tr('phone'),
              style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceInput,
                borderRadius: AppRadius.r12,
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  Text(
                    _selectedDialCode,
                    style: AppTypography.bodyL.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 20, color: AppColors.borderDefault),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '9XX XXX XX XX',
                        hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                      ),
                      style: AppTypography.bodyL,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Кнопка Сохранить
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.rPill),
                ),
                child: Text(
                  _locale.tr('save'),
                  style: AppTypography.button,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Удаление аккаунта (Apple Guideline 5.1.1)
            TextButton.icon(
              onPressed: _confirmDeleteAccount,
              icon: const Icon(PhosphorIcons.trash(), color: AppColors.feedbackError, size: 18),
              label: Text(
                _locale.tr('deleteAccount'),
                style: AppTypography.bodyM.copyWith(
                  color: AppColors.feedbackError,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangSelector() {
    final langs = [
      {'code': 'ru', 'label': 'RU'},
      {'code': 'uz', 'label': 'UZ'},
      {'code': 'kg', 'label': 'KG'},
      {'code': 'kz', 'label': 'KZ'},
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: AppRadius.r12,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: langs.map((l) {
          final isSelected = _locale.currentLang == l['code'];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _locale.setLanguage(l['code']!);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: isSelected ? AppShadows.xs : null,
              ),
              child: Text(
                l['label']!,
                style: TextStyle(
                  fontFamily: 'MontFamily',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.textPrimary : AppColors.textTertiary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
