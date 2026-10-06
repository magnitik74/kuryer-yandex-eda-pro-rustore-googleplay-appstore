import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import '../localization/app_strings.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  String _currentLang = 'ru';
  String get currentLang => _currentLang;

  Future<void> init(SharedPreferences prefs) async {
    final savedLang = prefs.getString('app_lang');
    if (savedLang != null) {
      _currentLang = savedLang;
    } else {
      final systemLocale = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
      if (['ru', 'uz', 'kg', 'kz'].contains(systemLocale)) {
        _currentLang = systemLocale;
      } else {
        _currentLang = 'ru';
      }
    }
  }

  Future<void> setLanguage(String lang) async {
    _currentLang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
    notifyListeners();
  }

  String tr(String key) => AppStrings.get(key, _currentLang);
}
