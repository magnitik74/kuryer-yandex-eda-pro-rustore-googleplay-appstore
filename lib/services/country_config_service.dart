import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

/// Сервис загрузки и доступа к конфигурациям стран (assets/country_config/*.json)
class CountryConfigService {
  static final CountryConfigService _instance = CountryConfigService._internal();
  factory CountryConfigService() => _instance;
  CountryConfigService._internal();

  final Map<String, Map<String, dynamic>> _configs = {};
  bool _isLoaded = false;

  Future<void> loadAll() async {
    if (_isLoaded) return;
    final countries = ['ru', 'kz', 'uz', 'kg', 'by'];
    for (final code in countries) {
      try {
        final jsonStr = await rootBundle.loadString('assets/country_config/$code.json');
        _configs[code] = jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('CountryConfigService: failed to load $code.json: $e');
      }
    }
    _isLoaded = true;
    debugPrint('CountryConfigService: loaded ${_configs.length} countries');
  }

  /// Получить конфиг страны (синхронно, после loadAll)
  Map<String, dynamic>? getConfig(String countryCode) {
    return _configs[countryCode.toLowerCase()];
  }

  /// Валюта
  String currency(String countryCode) => getConfig(countryCode)?['currency'] as String? ?? '₽';
  String currencyCode(String countryCode) => getConfig(countryCode)?['currencyCode'] as String? ?? 'RUB';

  /// Диал-код телефона
  String dialCode(String countryCode) => getConfig(countryCode)?['dialCode'] as String? ?? '+7';

  /// Реф-код
  String refCode(String countryCode) => getConfig(countryCode)?['refCode'] as String? ?? 'refRU';

  /// Дефолтная реф-ссылка
  String defaultRefUrl(String countryCode) => getConfig(countryCode)?['defaultRefUrl'] as String? ?? '';

  /// Часовой пояс
  String timezone(String countryCode) => getConfig(countryCode)?['timezone'] as String? ?? 'Europe/Moscow';

  /// Языки
  List<String> languages(String countryCode) {
    final list = getConfig(countryCode)?['languages'] as List?;
    return list?.cast<String>() ?? ['ru'];
  }

  /// Офлайн-города (доступно офлайн-оформление)
  List<String> offlineCities(String countryCode) {
    final list = getConfig(countryCode)?['offlineCities'] as List?;
    return list?.cast<String>() ?? [];
  }

  /// Документы по категориям
  Map<String, List<String>> documents(String countryCode) {
    final docs = getConfig(countryCode)?['documents'] as Map?;
    if (docs == null) return {};
    return docs.map((k, v) => MapEntry(k as String, (v as List).cast<String>()));
  }

  /// Телефон поддержки
  String supportPhone(String countryCode) => getConfig(countryCode)?['supportPhone'] as String? ?? '8 800 555 35 35';

  /// Курьерские центры
  List<Map<String, dynamic>> courierCenters(String countryCode) {
    final list = getConfig(countryCode)?['courierCenters'] as List?;
    return list?.cast<Map<String, dynamic>>() ?? [];
  }

  /// ПВЗ примечание
  String pvzNote(String countryCode) => getConfig(countryCode)?['pvzNote'] as String? ?? '';

  /// Шаги фотоконтроля
  List<String> photoControlSteps(String countryCode) {
    final list = getConfig(countryCode)?['photoControlSteps'] as List?;
    return list?.cast<String>() ?? [];
  }

  /// FAQ
  Map<String, String> faq(String countryCode) {
    final map = getConfig(countryCode)?['faq'] as Map?;
    return map?.cast<String, String>() ?? {};
  }

  /// Приветствие оператора
  String operatorGreeting(String countryCode) => getConfig(countryCode)?['operatorGreeting'] as String? ?? '';

  /// Тарифы (часовые ставки)
  Map<String, int> rates(String countryCode) {
    final map = getConfig(countryCode)?['rates'] as Map?;
    return map?.cast<String, int>() ?? {'auto': 694, 'bike': 420, 'walk': 330};
  }

  /// Макс доход в месяц
  Map<String, int> maxMonthlyIncome(String countryCode) {
    final map = getConfig(countryCode)?['maxMonthlyIncome'] as Map?;
    return map?.cast<String, int>() ?? {'auto': 250000};
  }

  /// Название страны
  String countryName(String countryCode) => getConfig(countryCode)?['name'] as String? ?? countryCode.toUpperCase();

  /// Проверка: есть ли офлайн-оформление в городе
  bool hasOfflineInCity(String countryCode, String city) {
    return offlineCities(countryCode).any((c) => c.toLowerCase() == city.toLowerCase());
  }
}