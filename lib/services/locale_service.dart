import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_strings.dart';
import 'country_config_service.dart';
import 'geo_detection_service.dart';
import 'appmetrica_service.dart';
import 'local_push_service.dart';
import 'curator_dialogue_engine.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  String _currentLang = 'ru';
  String _workCountry = 'ru'; // ru, kz, uz, kg, by
  String _userName = '';
  String _userPhone = '';
  String _phoneDialCode = '+7';
  String _courierType = 'walk'; // auto, walk, moto, bike
  bool _hasCompletedOnboarding = false;
  bool _hasRegisteredCabinet = false;
  bool _registrationSent = false;
  bool _hasReceivedBag = false;
  bool _isActiveCourier = false;
  bool _moyNalogLinked = false;
  CuratorStage _curatorStage = CuratorStage.preRegistration;
  bool _isInitialized = false;

  // Services
  final CountryConfigService _countryConfig = CountryConfigService();
  final GeoDetectionService _geoDetection = GeoDetectionService();
  final AppMetricaService _appMetrica = AppMetricaService();

  String get currentLang => _currentLang;
  String get workCountry => _workCountry;
  String get userName => _userName;
  String get userPhone => _userPhone;
  String get phoneDialCode => _phoneDialCode;
  String get courierType => _courierType;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get hasRegisteredCabinet => _hasRegisteredCabinet;
  bool get registrationSent => _registrationSent;
  bool get hasReceivedBag => _hasReceivedBag;
  bool get isActiveCourier => _isActiveCourier;
    bool get moyNalogLinked => _moyNalogLinked;
    CuratorStage get curatorStage => _curatorStage;
    bool get isInitialized => _isInitialized;

  // Country config getters
  String get currency => _countryConfig.currency(_workCountry);
  String get currencyCode => _countryConfig.currencyCode(_workCountry);
  String get dialCode => _countryConfig.dialCode(_workCountry);
  String get refCode => _countryConfig.refCode(_workCountry);
  String get defaultRefUrl => _countryConfig.defaultRefUrl(_workCountry);
  String get timezone => _countryConfig.timezone(_workCountry);
  List<String> get languages => _countryConfig.languages(_workCountry);
  List<String> get offlineCities => _countryConfig.offlineCities(_workCountry);
  Map<String, List<String>> get documents => _countryConfig.documents(_workCountry);
  String get supportPhone => _countryConfig.supportPhone(_workCountry);
  List<Map<String, dynamic>> get courierCenters => _countryConfig.courierCenters(_workCountry);
  String get pvzNote => _countryConfig.pvzNote(_workCountry);
  List<String> get photoControlSteps => _countryConfig.photoControlSteps(_workCountry);
  Map<String, String> get faq => _countryConfig.faq(_workCountry);
  String get operatorGreeting => _countryConfig.operatorGreeting(_workCountry);
  Map<String, int> get rates => _countryConfig.rates(_workCountry);
  Map<String, int> get maxMonthlyIncome => _countryConfig.maxMonthlyIncome(_workCountry);
  String get countryName => _countryConfig.countryName(_workCountry);

  bool hasOfflineInCity(String city) => _countryConfig.hasOfflineInCity(_workCountry, city);

  String tr(String key) => AppStrings.get(key, _currentLang);

  Future<void> init() async {
    if (_isInitialized) return;
    
    // Load country configs first
    await _countryConfig.loadAll();
    
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
            _phoneDialCode = prefs.getString('phone_dial_code') ?? _countryConfig.dialCode(_workCountry);
            _courierType = prefs.getString('courier_type') ?? 'walk';
            _hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
            _hasRegisteredCabinet = prefs.getBool('cabinet_registered') ?? false;
            _registrationSent = prefs.getBool('registration_sent') ?? false;
            _hasReceivedBag = prefs.getBool('bag_received') ?? false;
            _isActiveCourier = prefs.getBool('active_courier') ?? false;
            _moyNalogLinked = prefs.getBool('moy_nalog_linked') ?? false;
            _curatorStage = CuratorStage.values.firstWhere(
              (e) => e.name == prefs.getString('curator_stage'),
              orElse: () => CuratorStage.preRegistration,
            );

            // If username and phone exist, cabinet is considered registered
            if (_userName.isNotEmpty && _userPhone.isNotEmpty) {
              _hasRegisteredCabinet = true;
            }

    // 3. Init services
    await _appMetrica.init();

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
    _phoneDialCode = _countryConfig.dialCode(country);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('work_country', country);
    await prefs.setString('countryId', country);
    await prefs.setString('phone_dial_code', _phoneDialCode);
    notifyListeners();
  }

  Future<void> setCourierType(String type) async {
    _courierType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('courier_type', type);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _hasCompletedOnboarding = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    notifyListeners();
  }

  Future<void> registerCabinet({
    required String name,
    required String phone,
    required String dialCode,
  }) async {
    _userName = name;
    _userPhone = phone;
    _phoneDialCode = dialCode;
    _hasRegisteredCabinet = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_phone', phone);
    await prefs.setString('phone_dial_code', dialCode);
    await prefs.setBool('cabinet_registered', true);
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String dialCode,
    required String country,
    String? courierType,
  }) async {
    _userName = name;
    _userPhone = phone;
    _phoneDialCode = dialCode;
    _workCountry = country;
    if (courierType != null) {
      _courierType = courierType;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_phone', phone);
    await prefs.setString('phone_dial_code', dialCode);
    await prefs.setString('work_country', country);
    await prefs.setString('countryId', country);
    if (courierType != null) {
      await prefs.setString('courier_type', courierType);
    }

    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    await prefs.remove('phone_dial_code');
    await prefs.remove('cabinet_registered');

    _userName = '';
    _userPhone = '';
    _phoneDialCode = _countryConfig.dialCode(_workCountry);
    _hasRegisteredCabinet = false;

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
    await prefs.remove('cabinet_registered');
    await prefs.remove('courier_type');
    await prefs.remove('roadmap_step');

    _userName = '';
    _userPhone = '';
    _phoneDialCode = _countryConfig.dialCode('ru');
    _workCountry = 'ru';
    _courierType = 'walk';
    _hasCompletedOnboarding = false;
    _hasRegisteredCabinet = false;

    notifyListeners();
  }

  /// Auto-detect country and set it
  Future<void> detectAndSetCountry() async {
    final detected = await _geoDetection.detectCountry();
    if (detected != _workCountry) {
      await setWorkCountry(detected);
    }
  }

  /// Track event via AppMetrica
      Future<void> trackEvent(String name, {Map<String, dynamic>? params}) async {
        await _appMetrica.trackEvent(name, params: params);
      }

      // Registration flow state setters
      Future<void> setRegistrationSent(bool sent) async {
        final oldStage = _curatorStage;
        _registrationSent = sent;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('registration_sent', sent);
        if (sent) {
          _curatorStage = CuratorStage.registrationSent;
          await prefs.setString('curator_stage', _curatorStage.name);
          await _appMetrica.trackEvent('registration_sent', params: {'country': _workCountry, 'format': _courierType});
          await LocalPushService().onRegistrationSent();
        }
        notifyListeners();
        if (_curatorStage != oldStage) {
          await _appMetrica.trackEvent('stage_changed', params: {'from': oldStage.name, 'to': _curatorStage.name});
        }
      }

      Future<void> setBagReceived(bool received) async {
        final oldStage = _curatorStage;
        _hasReceivedBag = received;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('bag_received', received);
        if (received) {
          if (!_isActiveCourier) {
            _curatorStage = CuratorStage.postRegistration;
          }
          await prefs.setString('curator_stage', _curatorStage.name);
          await _appMetrica.trackEvent('bag_received', params: {'country': _workCountry, 'city': ''});
          await LocalPushService().onBagReceived();
        }
        notifyListeners();
        if (_curatorStage != oldStage) {
          await _appMetrica.trackEvent('stage_changed', params: {'from': oldStage.name, 'to': _curatorStage.name});
        }
      }

      Future<void> setActiveCourier(bool active) async {
        final oldStage = _curatorStage;
        _isActiveCourier = active;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('active_courier', active);
        if (active) {
          _curatorStage = CuratorStage.activeCourier;
          await prefs.setString('curator_stage', _curatorStage.name);
          await _appMetrica.trackEvent('first_order_completed', params: {'country': _workCountry, 'format': _courierType});
          await LocalPushService().onFirstOrderDone();
        }
        notifyListeners();
        if (_curatorStage != oldStage) {
          await _appMetrica.trackEvent('stage_changed', params: {'from': oldStage.name, 'to': _curatorStage.name});
        }
      }

      Future<void> setMoyNalogLinked(bool linked) async {
        final oldStage = _curatorStage;
        _moyNalogLinked = linked;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('moy_nalog_linked', linked);
        if (linked) {
          await _appMetrica.trackEvent('moy_nalog_linked', params: {'country': _workCountry});
          await LocalPushService().onMoyNalogLinked();
        }
        notifyListeners();
        if (_curatorStage != oldStage) {
          await _appMetrica.trackEvent('stage_changed', params: {'from': oldStage.name, 'to': _curatorStage.name});
        }
      }

      /// Internal method to sync stage from CuratorDialogueEngine
      Future<void> syncCuratorStage(CuratorStage stage) async {
        if (_curatorStage != stage) {
          final oldStage = _curatorStage;
          _curatorStage = stage;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('curator_stage', stage.name);
          notifyListeners();
          await _appMetrica.trackEvent('stage_changed', params: {'from': oldStage.name, 'to': stage.name});
        }
      }
    }
