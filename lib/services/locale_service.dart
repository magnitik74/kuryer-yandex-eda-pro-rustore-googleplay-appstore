import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_strings.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  String _currentLang = 'ru';
  String _workCountry = 'ru'; // ru, kz, uz, kg, by
  String _userName = '';
  String _userPhone = '';
  String _phoneDialCode = '+7';
  bool _isInitialized = false;

  String get currentLang => _currentLang;
  String get workCountry => _workCountry;
  String get userName => _userName;
  String get userPhone => _userPhone;
  String get phoneDialCode => _phoneDialCode;
  bool get isInitialized => _isInitialized;

  String tr(String key) => AppStrings.get(key, _currentLang);

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();

    // 1. Language detection
    final savedLang = prefs.getString('app_lang');
    if (savedLang != null) {
      _currentLang = savedLang;
    } else {
      // Auto-detect from system locale
      final systemLocale = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      if (['ru', 'uz', 'kg', 'kz'].contains(systemLocale)) {
        _currentLang = systemLocale;
      } else {
        _currentLang = 'ru';
      }
    }

    // 2. Profile & work country
    _workCountry = prefs.getString('work_country') ?? prefs.getString('countryId') ?? 'ru';
    _userName = prefs.getString('user_name') ?? '';
    _userPhone = prefs.getString('user_phone') ?? '';
    _phoneDialCode = prefs.getString('phone_dial_code') ?? '+7';

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    _currentLang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
    notifyListeners();
  }

  Future<void> setWorkCountry(String country) async {
    _workCountry = country;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('work_country', country);
    await prefs.setString('countryId', country);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String dialCode,
    required String country,
  }) async {
    _userName = name;
    _userPhone = phone;
    _phoneDialCode = dialCode;
    _workCountry = country;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_phone', phone);
    await prefs.setString('phone_dial_code', dialCode);
    await prefs.setString('work_country', country);
    await prefs.setString('countryId', country);

    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    await prefs.remove('phone_dial_code');
    await prefs.remove('work_country');
    await prefs.remove('countryId');
    await prefs.remove('onboarding_completed');
    await prefs.remove('roadmap_step');

    _userName = '';
    _userPhone = '';
    _phoneDialCode = '+7';
    _workCountry = 'ru';

    notifyListeners();
  }
}
