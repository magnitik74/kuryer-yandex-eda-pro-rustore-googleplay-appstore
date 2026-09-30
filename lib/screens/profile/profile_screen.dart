import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_flags/country_flags.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import '../../services/locale_service.dart';
import '../../theme/app_theme.dart';
import '../onboarding/onboarding_flow_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    {'id': 'auto', 'name': 'Автокурьер', 'icon': PhosphorIcons.car},
    {'id': 'walk', 'name': 'Пеший курьер', 'icon': PhosphorIcons.person},
    {'id': 'moto', 'name': 'Мотокурьер', 'icon': PhosphorIcons.moped},
    {'id': 'bike', 'name': 'Велокурьер', 'icon': PhosphorIcons.bicycle},
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Данные сохранены'),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.r20),
        title: Text(
          _locale.tr('deleteAccount'),
          style: AppTypography.headingM.copyWith(color: AppColors.feedbackError),
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        title: Text(
          _locale.tr('profile'),
          style: AppTypography.headingM,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              _locale.tr('save'),
              style: AppTypography.bodyL.copyWith(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Status Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: AppRadius.r16,
                  boxShadow: AppShadows.xs,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.brandPrimarySurface,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: AppColors.brandPrimary, width: 2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : 'К',
                          style: AppTypography.headingL.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _locale.userName.isNotEmpty ? _locale.userName : 'Курьер PRO',
                            style: AppTypography.headingS,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_selectedDialCode ${_locale.userPhone}',
                            style: AppTypography.bodyM.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimarySurface,
                              borderRadius: AppRadius.rPill,
                              border: Border.all(color: AppColors.brandPrimary),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  PhosphorIcons.checkCircle,
                                  size: 14,
                                  color: AppColors.textPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Кандидат PRO',
                                  style: AppTypography.captionBold.copyWith(
                                    color: AppColors.textPrimary,
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

              const SizedBox(height: 20),

              // Edit Info Section
              Text('Данные профиля', style: AppTypography.headingS),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: AppRadius.r16,
                  boxShadow: AppShadows.xs,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: _locale.tr('name'),
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.surfaceInput,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.r12,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: _locale.tr('phone'),
                        labelStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixText: '$_selectedDialCode ',
                        prefixStyle: AppTypography.bodyL.copyWith(fontWeight: FontWeight.w600),
                        filled: true,
                        fillColor: AppColors.surfaceInput,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.r12,
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Format Selection
              Text(_locale.tr('format'), style: AppTypography.headingS),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: AppRadius.r16,
                  boxShadow: AppShadows.xs,
                ),
                child: Column(
                  children: List.generate(_formats.length, (idx) {
                    final item = _formats[idx];
                    final isSelected = _selectedFormat == item['id'];
                    return ListTile(
                      leading: Icon(
                        item['icon'] as IconData,
                        color: isSelected ? AppColors.brandPrimary : AppColors.textSecondary,
                      ),
                      title: Text(item['name'] as String, style: AppTypography.bodyM),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.brandPrimary)
                          : null,
                      onTap: () {
                        setState(() => _selectedFormat = item['id'] as String);
                      },
                    );
                  }),
                ),
              ),

              const SizedBox(height: 20),

              // Country Selection
              Text(_locale.tr('workCountry'), style: AppTypography.headingS),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: AppRadius.r16,
                  boxShadow: AppShadows.xs,
                ),
                child: Column(
                  children: List.generate(_countries.length, (idx) {
                    final item = _countries[idx];
                    final isSelected = _selectedCountry == item['id'];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CountryFlag.fromCountryCode(
                          item['flag']!,
                          height: 18,
                          width: 26,
                        ),
                      ),
                      title: Text(item['name']!, style: AppTypography.bodyM),
                      subtitle: Text(item['code']!, style: AppTypography.caption),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: AppColors.brandPrimary)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCountry = item['id']!;
                          _selectedDialCode = item['code']!;
                        });
                      },
                    );
                  }),
                ),
              ),

              const SizedBox(height: 24),

              // Reopen Onboarding for testing
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OnboardingFlowScreen()),
                    );
                  },
                  icon: const Icon(PhosphorIcons.sparkle, color: AppColors.textSecondary, size: 16),
                  label: Text(
                    'Посмотреть 3D Онбординг заново',
                    style: AppTypography.captionBold.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Danger Zone: Delete Account Button
              Center(
                child: TextButton.icon(
                  onPressed: _confirmDeleteAccount,
                  icon: const Icon(PhosphorIcons.trash, color: AppColors.feedbackError, size: 18),
                  label: Text(
                    _locale.tr('deleteAccount'),
                    style: AppTypography.bodyM.copyWith(
                      color: AppColors.feedbackError,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
