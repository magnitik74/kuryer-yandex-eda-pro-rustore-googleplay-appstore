import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:http/http.dart' as http;

/// Мультислойный гео-детект страны (SIM → Timezone → IP → Locale)
/// Приоритеты:
/// 1. SIM Card (Android) — точная страна оператора
/// 2. Timezone — надёжно, не требует пермишнов
/// 3. IP через backend — fallback
/// 4. Locale устройства — последний резерв
class GeoDetectionService {
  static final GeoDetectionService _instance = GeoDetectionService._internal();
  factory GeoDetectionService() => _instance;
  GeoDetectionService._internal();

  static const String _ipGeoEndpoint = 'https://ipapi.co/json/'; // бесплатный публичный API
  bool _timezoneInitialized = false;

  /// Главный метод: определяет страну (ru/kz/uz/kg/by)
  Future<String> detectCountry() async {
    // 1. SIM Card (Android only)
    if (!kIsWeb && Platform.isAndroid) {
      final simCountry = await _getSimCountry();
      if (simCountry != null && _isSupportedCountry(simCountry)) {
        debugPrint('GeoDetection: SIM country = $simCountry');
        return simCountry;
      }
    }

    // 2. Timezone
    final tzCountry = _getTimezoneCountry();
    if (tzCountry != null) {
      debugPrint('GeoDetection: Timezone country = $tzCountry');
      return tzCountry;
    }

    // 3. IP Geo (backend)
    final ipCountry = await _getIpCountry();
    if (ipCountry != null) {
      debugPrint('GeoDetection: IP country = $ipCountry');
      return ipCountry;
    }

    // 4. System Locale
    final localeCountry = _getLocaleCountry();
    debugPrint('GeoDetection: Locale country = $localeCountry (fallback)');
    return localeCountry;
  }

  /// SIM Card country code (ISO 3166-1 alpha-2)
  Future<String?> _getSimCountry() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      // Требует READ_PHONE_STATE permission
      // В Flutter нет прямого доступа к SIM country без плагина
      // Используем platform channel или telephony пакет
      // Пока возвращаем null — можно добавить telephony пакет позже
      return null;
    } catch (e) {
      debugPrint('GeoDetection: SIM read error: $e');
      return null;
    }
  }

  /// Timezone → Country mapping
  String? _getTimezoneCountry() {
    if (!_timezoneInitialized) {
      tz_data.initializeTimeZones();
      _timezoneInitialized = true;
    }
    
    final localLocation = tz.local;
    final tzName = localLocation.name.toLowerCase();
    
    // Маппинг таймзон на наши страны
    if (tzName.contains('moscow') || tzName.contains('irkutsk') || 
        tzName.contains('vladivostok') || tzName.contains('yekaterinburg') ||
        tzName.contains('novosibirsk') || tzName.contains('omsk') ||
        tzName.contains('krasnoyarsk') || tzName.contains('samara') ||
        tzName.contains('volgograd') || tzName.contains('kaliningrad') ||
        tzName.contains('astrakhan') || tzName.contains('saratov') ||
        tzName.contains('ulan_ude') || tzName.contains('chita') ||
        tzName.contains('magadan') || tzName.contains('sakhalin') ||
        tzName.contains('srednekolymsk') || tzName.contains('kamchatka') ||
        tzName.contains('anz')) {
      return 'ru';
    }
    if (tzName.contains('almaty') || tzName.contains('aqtau') || 
        tzName.contains('aqtobe') || tzName.contains('atyrau') ||
        tzName.contains('oral') || tzName.contains('qyzylorda')) {
      return 'kz';
    }
    if (tzName.contains('tashkent') || tzName.contains('samarkand')) {
      return 'uz';
    }
    if (tzName.contains('bishkek') || tzName.contains('frunze')) {
      return 'kg';
    }
    if (tzName.contains('minsk') || tzName.contains('minsk')) {
      return 'by';
    }
    return null;
  }

  /// IP Geo через публичный API
  Future<String?> _getIpCountry() async {
    try {
      final response = await http.get(Uri.parse(_ipGeoEndpoint))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final countryCode = (data['country_code'] as String?)?.toLowerCase();
        if (countryCode != null && _isSupportedCountry(countryCode)) {
          return countryCode;
        }
      }
    } catch (e) {
      debugPrint('GeoDetection: IP geo error: $e');
    }
    return null;
  }

  /// System Locale → Country
  String _getLocaleCountry() {
    final locale = PlatformDispatcher.instance.locale;
    final countryCode = locale.countryCode?.toLowerCase();
    if (countryCode != null && _isSupportedCountry(countryCode)) {
      return countryCode;
    }
    final langCode = locale.languageCode.toLowerCase();
    switch (langCode) {
      case 'ru': return 'ru';
      case 'kz': case 'kk': return 'kz';
      case 'uz': return 'uz';
      case 'ky': return 'kg';
      case 'be': return 'by';
      default: return 'ru';
    }
  }

  bool _isSupportedCountry(String code) {
    return {'ru', 'kz', 'uz', 'kg', 'by'}.contains(code.toLowerCase());
  }
}
