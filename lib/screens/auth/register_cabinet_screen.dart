import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_flags/country_flags.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/locale_service.dart';
import '../../services/local_push_service.dart';
import '../../theme/app_theme.dart';
import '../main_screen.dart';

class RegisterCabinetScreen extends StatefulWidget {
  const RegisterCabinetScreen({super.key});

  @override
  State<RegisterCabinetScreen> createState() => _RegisterCabinetScreenState();
}

class _RegisterCabinetScreenState extends State<RegisterCabinetScreen> {
  final LocaleService _locale = LocaleService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _dialCode = '+7';
  String _flagCountryCode = 'RU';

  final List<Map<String, String>> _countryDialCodes = [
    {'code': '+7', 'flag': 'RU', 'name': 'Россия (+7)'},
    {'code': '+998', 'flag': 'UZ', 'name': 'Узбекистан (+998)'},
    {'code': '+996', 'flag': 'KG', 'name': 'Кыргызстан (+996)'},
    {'code': '+7', 'flag': 'KZ', 'name': 'Казахстан (+7)'},
    {'code': '+375', 'flag': 'BY', 'name': 'Беларусь (+375)'},
  ];

  @override
  void initState() {
    super.initState();
    // Default country based on current selected language
    switch (_locale.currentLang) {
      case 'uz':
        _dialCode = '+998';
        _flagCountryCode = 'UZ';
        break;
      case 'kg':
        _dialCode = '+996';
        _flagCountryCode = 'KG';
        break;
      case 'kz':
        _dialCode = '+7';
        _flagCountryCode = 'KZ';
        break;
      default:
        _dialCode = '+7';
        _flagCountryCode = 'RU';
        break;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    if (phone.isEmpty || phone.length < 7) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Введите корректный номер телефона'),
          backgroundColor: AppColors.feedbackError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.r12),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    _locale.registerCabinet(
      name: name.isNotEmpty ? name : 'Курьер',
      phone: phone,
      dialCode: _dialCode,
    );

    // Request notifications and schedule follow-ups
    try {
      FirebaseMessaging.instance.requestPermission();
      LocalPushService().scheduleFunnelNotifications();
    } catch (_) {}

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _openDialCodePicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                const SizedBox(height: 16),
                Text('Выберите код страны', style: AppTypography.headingM),
                const SizedBox(height: 12),
                ...List.generate(_countryDialCodes.length, (idx) {
                  final item = _countryDialCodes[idx];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CountryFlag.fromCountryCode(
                        item['flag']!,
                        height: 20,
                        width: 28,
                      ),
                    ),
                    title: Text(item['name']!, style: AppTypography.bodyL),
                    trailing: _dialCode == item['code'] && _flagCountryCode == item['flag']
                        ? const Icon(Icons.check, color: AppColors.brandPrimary)
                        : null,
                    onTap: () {
                      setState(() {
                        _dialCode = item['code']!;
                        _flagCountryCode = item['flag']!;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _locale.tr('regCabinetTitle'),
                style: AppTypography.headingXL,
              ),
              const SizedBox(height: 8),
              Text(
                _locale.tr('regCabinetSubtitle'),
                style: AppTypography.bodyM,
              ),

              const SizedBox(height: 28),

              // Inputs Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: AppRadius.r16,
                  boxShadow: AppShadows.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phone Number Field
                    Text(
                      _locale.tr('phone'),
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceInput,
                        borderRadius: AppRadius.r12,
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _openDialCodePicker,
                            behavior: HitTestBehavior.opaque,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: CountryFlag.fromCountryCode(
                                    _flagCountryCode,
                                    height: 20,
                                    width: 28,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _dialCode,
                                  style: AppTypography.bodyL.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: AppColors.borderDefault,
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: AppTypography.bodyL,
                              decoration: const InputDecoration(
                                hintText: '9XX XXX XX XX',
                                hintStyle: TextStyle(color: AppColors.textTertiary),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Name Field
                    Text(
                      _locale.tr('name'),
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceInput,
                        borderRadius: AppRadius.r12,
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: AppTypography.bodyL,
                        decoration: InputDecoration(
                          hintText: _locale.tr('nameHint'),
                          hintStyle: const TextStyle(color: AppColors.textTertiary),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Privacy Disclaimer
              Center(
                child: Text(
                  _locale.tr('privacyNotice'),
                  textAlign: TextAlign.center,
                  style: AppTypography.caption,
                ),
              ),
              const SizedBox(height: 12),

              // Yellow CTA Pill
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.rPill,
                    ),
                  ),
                  child: Text(
                    _locale.tr('continueBtn'),
                    style: AppTypography.button,
                  ),
                ),
              ),
              SizedBox(height: isKeyboardOpen ? 12 : 24),
            ],
          ),
        ),
      ),
    );
  }
}
