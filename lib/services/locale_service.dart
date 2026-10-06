import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'country_config_service.dart';
import 'geo_detection_service.dart';
import 'appmetrica_service.dart';
import 'ab_test_service.dart';
import 'curator_dialogue_engine.dart';
import 'localization_service.dart';
import 'user_state_service.dart';
import 'courier_flow_service.dart';

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal() {
    // Add listeners to notify UI when internal services update
    _localization.addListener(notifyListeners);
    _userState.addListener(notifyListeners);
    _courierFlow.addListener(notifyListeners);
  }

  bool _isInitialized = false;

  // New Modular Services
  final LocalizationService _localization = LocalizationService();
  final UserStateService _userState = UserStateService();
  final CourierFlowService _courierFlow = CourierFlowService();
  
  // Existing Services
  final CountryConfigService _countryConfig = CountryConfigService();
  final GeoDetectionService _geoDetection = GeoDetectionService();
  final AppMetricaService _appMetrica = AppMetricaService();
  final ABTestService _abTest = ABTestService();

  // Getters mapped to modules
  String get currentLang => _localization.currentLang;
  String get workCountry => _courierFlow.workCountry;
  String get userName => _userState.userName;
  String get userPhone => _userState.userPhone;
  String get phoneDialCode => _userState.phoneDialCode;
  String get courierType => _courierFlow.courierType;
  
  bool get hasCompletedOnboarding => _userState.hasCompletedOnboarding;
  bool get hasRegisteredCabinet => _userState.hasRegisteredCabinet;
  bool get registrationSent => _courierFlow.registrationSent;
  bool get hasReceivedBag => _courierFlow.hasReceivedBag;
  bool get isActiveCourier => _courierFlow.isActiveCourier;
  bool get moyNalogLinked => _courierFlow.moyNalogLinked;
  CuratorStage get curatorStage => _courierFlow.curatorStage;
  bool get isInitialized => _isInitialized;
  ABTestService get abTest => _abTest;

  // Country config getters
  String get currency => _countryConfig.currency(workCountry);
  String get currencyCode => _countryConfig.currencyCode(workCountry);
  String get dialCode => _countryConfig.dialCode(workCountry);
  String get refCode => _countryConfig.refCode(workCountry);
  String get defaultRefUrl => _countryConfig.defaultRefUrl(workCountry);
  String get timezone => _countryConfig.timezone(workCountry);
  List<String> get languages => _countryConfig.languages(workCountry);
  List<String> get offlineCities => _countryConfig.offlineCities(workCountry);
  Map<String, List<String>> get documents => _countryConfig.documents(workCountry);
  String get supportPhone => _countryConfig.supportPhone(workCountry);
  List<Map<String, dynamic>> get courierCenters => _countryConfig.courierCenters(workCountry);
  String get pvzNote => _countryConfig.pvzNote(workCountry);
  List<String> get photoControlSteps => _countryConfig.photoControlSteps(workCountry);
  Map<String, String> get faq => _countryConfig.faq(workCountry);
  String get operatorGreeting => _countryConfig.operatorGreeting(workCountry);
  Map<String, int> get rates => _countryConfig.rates(workCountry);
  Map<String, int> get maxMonthlyIncome => _countryConfig.maxMonthlyIncome(workCountry);
  String get countryName => _countryConfig.countryName(workCountry);

  bool hasOfflineInCity(String city) => _countryConfig.hasOfflineInCity(workCountry, city);

  String tr(String key) => _localization.tr(key);

  Future<void> init() async {
    if (_isInitialized) return;
    
    await _countryConfig.loadAll();
    final prefs = await SharedPreferences.getInstance();

    await _localization.init(prefs);
    await _courierFlow.init(prefs);
    
    final defaultDialCode = _countryConfig.dialCode(_courierFlow.workCountry);
    await _userState.init(prefs, defaultDialCode);

    await _appMetrica.init();
    await _abTest.init();

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(String lang) => _localization.setLanguage(lang);
  
  Future<void> setWorkCountry(String country) async {
    await _courierFlow.setWorkCountry(country);
    final dialCode = _countryConfig.dialCode(country);
    await _userState.updateProfile(
      name: _userState.userName, 
      phone: _userState.userPhone, 
      dialCode: dialCode
    );
  }

  Future<void> setCourierType(String type) => _courierFlow.setCourierType(type);
  Future<void> completeOnboarding() => _userState.completeOnboarding();
  
  Future<void> registerCabinet({required String name, required String phone, required String dialCode}) =>
      _userState.registerCabinet(name: name, phone: phone, dialCode: dialCode);

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String dialCode,
    required String country,
    String? courierType,
  }) async {
    await _userState.updateProfile(name: name, phone: phone, dialCode: dialCode);
    await _courierFlow.setWorkCountry(country);
    if (courierType != null) {
      await _courierFlow.setCourierType(courierType);
    }
  }

  Future<void> logout() async {
    final dialCode = _countryConfig.dialCode(workCountry);
    await _userState.logout(dialCode);
  }

  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('countryId');
    await prefs.remove('roadmap_step');

    await _userState.clearAll();
    await _courierFlow.clearAll();
    
    final dialCode = _countryConfig.dialCode('ru');
    await _userState.updateProfile(name: '', phone: '', dialCode: dialCode);
  }

  Future<void> detectAndSetCountry() async {
    final detected = await _geoDetection.detectCountry();
    if (detected != workCountry) {
      await setWorkCountry(detected);
    }
  }

  Future<void> trackEvent(String name, {Map<String, dynamic>? params}) =>
      _appMetrica.trackEvent(name, params: params);

  Future<void> setRegistrationSent(bool sent) => _courierFlow.setRegistrationSent(sent);
  Future<void> setBagReceived(bool received) => _courierFlow.setBagReceived(received);
  Future<void> setActiveCourier(bool active) => _courierFlow.setActiveCourier(active);
  Future<void> setMoyNalogLinked(bool linked) => _courierFlow.setMoyNalogLinked(linked);
  Future<void> syncCuratorStage(CuratorStage stage) => _courierFlow.syncCuratorStage(stage);
}
