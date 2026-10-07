import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:country_flags/country_flags.dart';
import '../../services/locale_service.dart';
import '../../services/geo_detection_service.dart';
import '../../theme/app_theme.dart';
import '../curator/curator_tab.dart';

class OnboardingScreenV2 extends StatefulWidget {
  const OnboardingScreenV2({super.key});

  @override
  State<OnboardingScreenV2> createState() => _OnboardingScreenV2State();
}

class _OnboardingScreenV2State extends State<OnboardingScreenV2> {
  final LocaleService _locale = LocaleService();
  final GeoDetectionService _geo = GeoDetectionService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedFormat = 'auto';
  String _selectedCity = '';
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Format options
  final List<_FormatOption> _formats = [
    _FormatOption('auto', 'Авто', PhosphorIcons.car, 'До 250 000 ₽/мес'),
    _FormatOption('moto', 'Мото', PhosphorIcons.moped, 'До 180 000 ₽/мес'),
    _FormatOption('bike', 'Вело', PhosphorIcons.bicycle, 'До 120 000 ₽/мес'),
    _FormatOption('walk', 'Пеший', PhosphorIcons.person, 'До 80 000 ₽/мес'),
  ];

  @override
  void initState() {
    super.initState();
    _locale.addListener(_onLocaleChanged);
    _initData();
    // Track onboarding start
    _locale.trackEvent('onboarding_start', params: {
      'country': _locale.workCountry,
    });
  }

  @override
  void dispose() {
    _locale.removeListener(_onLocaleChanged);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _initData() async {
    // Try to get saved country or detect
    String country = _locale.workCountry;
    if (country == 'ru' && _locale.userName.isEmpty) {
      // First launch - try geo detection
      final detected = await _geo.detectCountry();
      if (detected != 'ru') {
        await _locale.setWorkCountry(detected);
        country = detected;
      }
    }
    _selectedCity = _getDefaultCity(country);
    setState(() => _isLoading = false);
  }

  String _getDefaultCity(String country) {
    final offlineCities = _locale.offlineCities;
    if (offlineCities.isNotEmpty) return offlineCities.first;
    switch (country) {
      case 'kz': return 'Алматы';
      case 'uz': return 'Ташкент';
      case 'kg': return 'Бишкек';
      case 'by': return 'Минск';
      default: return 'Москва';
    }
  }

  _FormatOption get _currentFormat => _formats.firstWhere(
    (f) => f.id == _selectedFormat,
    orElse: () => _formats[0],
  );

  bool get _isOfflineCity => _locale.hasOfflineInCity(_selectedCity);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgWarm,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.brandPrimary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Курьер PRO Еда',
                    style: AppTypography.headingL.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  _buildCountryPicker(),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        'Стань курьером за 3 минуты',
                        style: AppTypography.headingXL.copyWith(
                          fontSize: 26,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Официальный партнёр доставки. Выплаты ежедневно, свободный график.',
                        style: AppTypography.bodyM,
                      ),

                      const SizedBox(height: 24),

                      // 1. Format Selection
                      _buildSectionTitle('Выбери формат'),
                      const SizedBox(height: 12),
                      _buildFormatChips(),

                      const SizedBox(height: 28),

                      // 2. Personal Data
                      _buildSectionTitle('Твои данные'),
                      const SizedBox(height: 12),
                      _buildNameField(),
                      const SizedBox(height: 12),
                      _buildPhoneField(),

                      const SizedBox(height: 32),

                      // 5. CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandPrimary,
                            foregroundColor: AppColors.textOnPrimary,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.rPill,
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(AppColors.textOnPrimary),
                                  ),
                                )
                              : Text(
                                  'Стать курьером',
                                  style: AppTypography.button.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Footer note
                      Center(
                        child: Text(
                          'Нажимая кнопку, вы соглашаетесь с обработкой персональных данных',
                          style: AppTypography.caption.copyWith(fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryPicker() {
    final config = _locale;
    return GestureDetector(
      onTap: _showCountryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.rPill,
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CountryFlag.fromCountryCode(
              _getCountryFlagCode(config.workCountry),
              height: 20,
              width: 30,
            ),
            const SizedBox(width: 6),
            Text(
              config.workCountry.toUpperCase(),
              style: AppTypography.captionBold.copyWith(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(PhosphorIcons.caretDown, size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  String _getCountryFlagCode(String country) {
    switch (country) {
      case 'kz': return 'KZ';
      case 'uz': return 'UZ';
      case 'kg': return 'KG';
      case 'by': return 'BY';
      default: return 'RU';
    }
  }

  void _showCountryPicker() {
    HapticFeedback.selectionClick();
    final countries = [
      {'code': 'ru', 'name': 'Россия', 'flag': 'RU'},
      {'code': 'kz', 'name': 'Казахстан', 'flag': 'KZ'},
      {'code': 'uz', 'name': 'Узбекистан', 'flag': 'UZ'},
      {'code': 'kg', 'name': 'Кыргызстан', 'flag': 'KG'},
      {'code': 'by', 'name': 'Беларусь', 'flag': 'BY'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgWarm,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: countries.map((c) {
            final isSelected = c['code'] == _locale.workCountry;
            return ListTile(
              leading: CountryFlag.fromCountryCode(
                c['flag']!,
                height: 24,
                width: 36,
              ),
              title: Text(
                c['name']!,
                style: AppTypography.bodyL.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check, color: AppColors.textDarkWarm) : null,
              onTap: () async {
                await _locale.setWorkCountry(c['code']!);
                _selectedCity = _getDefaultCity(c['code']!);
                if (mounted) setState(() {});
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.headingM.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildFormatChips() {
    return Row(
      children: _formats.map((format) {
        final isSelected = _selectedFormat == format.id;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFormat = format.id);
                _locale.trackEvent('onboarding_format_selected', params: {
                  'format': format.id,
                  'country': _locale.workCountry,
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.chipDark : AppColors.chipLight,
                  borderRadius: AppRadius.r16,
                  border: Border.all(
                    color: isSelected ? AppColors.chipDark : AppColors.chipBorder,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      format.icon,
                      size: 24,
                      color: isSelected ? Colors.white : AppColors.textDarkWarm,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      format.label,
                      style: AppTypography.chipLabel.copyWith(
                        color: isSelected ? Colors.white : AppColors.textDarkWarm,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFormatBenefit() {
    final fmt = _currentFormat;
    final rates = _locale.rates;
    final rate = rates[fmt.id] ?? 0;
    final currency = _locale.currency;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandPrimarySurface,
        borderRadius: AppRadius.r16,
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(fmt.icon, color: AppColors.textDarkWarm, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '≈ ${rate} ₽/час • ${_formatNumber(rate * 60 * 4)} $currency/мес при 4 ч/день',
                  style: AppTypography.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDarkWarm,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fmt.benefit,
                  style: AppTypography.caption.copyWith(color: AppColors.textMutedWarm),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]} ',
  );

  Widget _buildDocumentsList() {
    final docs = _locale.documents;
    final allDocs = <String>[];
    docs.forEach((_, list) => allDocs.addAll(list));
    // Deduplicate
    final uniqueDocs = allDocs.toSet().toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.r16,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: uniqueDocs.asMap().entries.map((entry) {
          final idx = entry.key;
          final doc = entry.value;
          final isLast = idx == uniqueDocs.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        doc,
                        style: AppTypography.bodyM.copyWith(
                          color: AppColors.textDarkWarm,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, color: AppColors.borderDefault, indent: 32),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCityPicker() {
    return GestureDetector(
      onTap: _showCityPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.r16,
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedCity,
                    style: AppTypography.bodyL.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDarkWarm,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _isOfflineCity ? PhosphorIcons.mapPin : PhosphorIcons.package,
                        size: 14,
                        color: _isOfflineCity ? AppColors.feedbackSuccess : AppColors.textMutedWarm,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _isOfflineCity
                              ? 'Офлайн-оформление в Курьерском центре'
                              : 'Онлайн-оформление, сумка в ПВЗ',
                          style: AppTypography.caption.copyWith(
                            color: _isOfflineCity ? AppColors.feedbackSuccess : AppColors.textMutedWarm,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(PhosphorIcons.caretRight, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showCityPicker() {
    HapticFeedback.selectionClick();
    final offlineCities = _locale.offlineCities;
    final allCities = <String>[];
    allCities.addAll(offlineCities);
    // Add major cities for the country
    final majorCities = _getMajorCities(_locale.workCountry);
    for (final c in majorCities) {
      if (!allCities.contains(c)) allCities.add(c);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgWarm,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('выбери город', style: AppTypography.cardHeader.copyWith(fontSize: 18)),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allCities.length,
                itemBuilder: (_, i) {
                  final city = allCities[i];
                  final isOffline = offlineCities.contains(city);
                  final isSel = city == _selectedCity;
                  return ListTile(
                    title: Text(
                      city,
                      style: AppTypography.bodyL.copyWith(
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel ? AppColors.textDarkWarm : AppColors.textSecondary,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isOffline)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.feedbackSuccessLight,
                              borderRadius: AppRadius.rPill,
                            ),
                            child: Text(
                              'ЦО',
                              style: AppTypography.captionBold.copyWith(
                                fontSize: 10,
                                color: AppColors.feedbackSuccess,
                              ),
                            ),
                          ),
                        if (isSel) const Icon(Icons.check, color: AppColors.textDarkWarm),
                      ],
                    ),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedCity = city);
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getMajorCities(String country) {
    switch (country) {
      case 'ru': return ['Москва', 'Санкт-Петербург', 'Казань', 'Новосибирск', 'Екатеринбург', 'Нижний Новгород', 'Краснодар', 'Ростов-на-Дону', 'Тюмень'];
      case 'kz': return ['Алматы', 'Астана', 'Шымкент', 'Караганда', 'Актобе'];
      case 'uz': return ['Ташкент', 'Самарканд', 'Бухара', 'Наманган', 'Фергана'];
      case 'kg': return ['Бишкек', 'Ош', 'Джалал-Абад'];
      case 'by': return ['Минск', 'Гомель', 'Могилёв', 'Витебск', 'Гродно', 'Брест'];
      default: return [];
    }
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      style: AppTypography.bodyL,
      decoration: InputDecoration(
        labelText: 'Имя',
        hintText: _locale.tr('nameHint'),
        hintStyle: AppTypography.bodyL.copyWith(
          color: AppColors.textTertiary,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: AppRadius.r16,
          borderSide: BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.r16,
          borderSide: BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.r16,
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) => (v?.trim().isEmpty ?? true) ? 'Введи имя' : null,
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.phone,
      style: AppTypography.bodyL,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _PhoneFormatter(_locale.dialCode),
      ],
      decoration: InputDecoration(
        labelText: 'Телефон',
        hintText: 'XXX XXX XX XX',
        hintStyle: AppTypography.bodyL.copyWith(
          color: AppColors.textTertiary,
        ),
        prefixText: '${_locale.dialCode} ',
        prefixStyle: AppTypography.bodyL.copyWith(color: AppColors.textDarkWarm),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: AppColors.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: AppRadius.r16,
          borderSide: BorderSide(color: AppColors.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.r16,
          borderSide: BorderSide(color: AppColors.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.r16,
          borderSide: BorderSide(color: AppColors.brandPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: (v) {
        final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
        if (digits.length < 10) return 'Введи полный номер';
        return null;
      },
      onFieldSubmitted: (_) => _onSubmit(),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    HapticFeedback.mediumImpact();
    
    // Track registration click
    await _locale.trackEvent('registration_clicked', params: {
      'format': _selectedFormat,
      'country': _locale.workCountry,
      'city': _selectedCity,
    });
    
    setState(() => _isSubmitting = true);

    try {
          // Save format
          await _locale.setCourierType(_selectedFormat);
          // Save city
          await _locale.setWorkCountry(_locale.workCountry); // triggers dialCode update
          // Register cabinet (name + phone)
          final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
          await _locale.registerCabinet(
            name: _nameController.text.trim(),
            phone: phoneDigits,
            dialCode: _locale.dialCode,
          );

          // Mark registration as sent
          await _locale.setRegistrationSent(true);

          // Track onboarding complete + registration sent
          await _locale.trackEvent('onboarding_complete', params: {
            'format': _selectedFormat,
            'country': _locale.workCountry,
            'has_name': true,
            'has_phone': true,
          });
          await _locale.trackEvent('registration_sent', params: {
            'format': _selectedFormat,
            'country': _locale.workCountry,
            'city': _selectedCity,
          });

          if (!mounted) return;

          // Navigate to CuratorTab with fresh lead context
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => CuratorTab(
                initialCourierFormat: _selectedFormat,
                isFreshLead: true,
              ),
            ),
          );
        } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.feedbackError),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class _FormatOption {
  final String id;
  final String label;
  final IconData icon;
  final String benefit;
  const _FormatOption(this.id, this.label, this.icon, this.benefit);
}

class _PhoneFormatter extends TextInputFormatter {
  final String dialCode;
  _PhoneFormatter(this.dialCode);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return newValue.copyWith(text: '');
    
    String formatted = '';
    // Russian format: 9XX XXX XX XX
    if (dialCode == '+7') {
      for (int i = 0; i < digits.length && i < 10; i++) {
        if (i == 0) formatted += digits[i];
        else if (i == 3) formatted += ' ${digits[i]}';
        else if (i == 6) formatted += ' ${digits[i]}';
        else if (i == 8) formatted += ' ${digits[i]}';
        else formatted += digits[i];
      }
    } else {
      // Generic: groups of 3-3-4
      for (int i = 0; i < digits.length; i++) {
        if (i > 0 && (i % 3 == 0 || (i == 3 && digits.length > 6))) {
          formatted += ' ';
        }
        formatted += digits[i];
      }
    }
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
