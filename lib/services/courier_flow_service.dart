import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'appmetrica_service.dart';
import 'local_push_service.dart';
import 'curator_dialogue_engine.dart';

class CourierFlowService extends ChangeNotifier {
  static final CourierFlowService _instance = CourierFlowService._internal();
  factory CourierFlowService() => _instance;
  CourierFlowService._internal();

  String _workCountry = 'ru';
  String _courierType = 'walk';
  bool _registrationSent = false;
  bool _hasReceivedBag = false;
  bool _isActiveCourier = false;
  bool _moyNalogLinked = false;
  CuratorStage _curatorStage = CuratorStage.preRegistration;

  String get workCountry => _workCountry;
  String get courierType => _courierType;
  bool get registrationSent => _registrationSent;
  bool get hasReceivedBag => _hasReceivedBag;
  bool get isActiveCourier => _isActiveCourier;
  bool get moyNalogLinked => _moyNalogLinked;
  CuratorStage get curatorStage => _curatorStage;

  Future<void> init(SharedPreferences prefs) async {
    _workCountry = prefs.getString('work_country') ?? prefs.getString('countryId') ?? 'ru';
    _courierType = prefs.getString('courier_type') ?? 'walk';
    _registrationSent = prefs.getBool('registration_sent') ?? false;
    _hasReceivedBag = prefs.getBool('bag_received') ?? false;
    _isActiveCourier = prefs.getBool('active_courier') ?? false;
    _moyNalogLinked = prefs.getBool('moy_nalog_linked') ?? false;
    _curatorStage = CuratorStage.values.firstWhere(
      (e) => e.name == prefs.getString('curator_stage'),
      orElse: () => CuratorStage.preRegistration,
    );
  }

  Future<void> setWorkCountry(String country) async {
    _workCountry = country;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('work_country', country);
    await prefs.setString('countryId', country);
    notifyListeners();
  }

  Future<void> setCourierType(String type) async {
    _courierType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('courier_type', type);
    notifyListeners();
  }

  Future<void> setRegistrationSent(bool sent) async {
    final oldStage = _curatorStage;
    _registrationSent = sent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('registration_sent', sent);
    if (sent) {
      _curatorStage = CuratorStage.registrationSent;
      await prefs.setString('curator_stage', _curatorStage.name);
      await AppMetricaService().trackEvent('registration_sent', params: {'country': _workCountry, 'format': _courierType});
      await LocalPushService().onRegistrationSent();
    }
    notifyListeners();
    if (_curatorStage != oldStage) {
      await AppMetricaService().trackEvent('stage_changed', params: {'from': oldStage.name, 'to': _curatorStage.name});
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
      await AppMetricaService().trackEvent('bag_received', params: {'country': _workCountry, 'city': ''});
      await LocalPushService().onBagReceived();
    }
    notifyListeners();
    if (_curatorStage != oldStage) {
      await AppMetricaService().trackEvent('stage_changed', params: {'from': oldStage.name, 'to': _curatorStage.name});
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
      await AppMetricaService().trackEvent('first_order_completed', params: {'country': _workCountry, 'format': _courierType});
      await LocalPushService().onFirstOrderDone();
    }
    notifyListeners();
    if (_curatorStage != oldStage) {
      await AppMetricaService().trackEvent('stage_changed', params: {'from': oldStage.name, 'to': _curatorStage.name});
    }
  }

  Future<void> setMoyNalogLinked(bool linked) async {
    final oldStage = _curatorStage;
    _moyNalogLinked = linked;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('moy_nalog_linked', linked);
    if (linked) {
      await AppMetricaService().trackEvent('moy_nalog_linked', params: {'country': _workCountry});
      await LocalPushService().onMoyNalogLinked();
    }
    notifyListeners();
    if (_curatorStage != oldStage) {
      await AppMetricaService().trackEvent('stage_changed', params: {'from': oldStage.name, 'to': _curatorStage.name});
    }
  }

  Future<void> syncCuratorStage(CuratorStage stage) async {
    if (_curatorStage != stage) {
      final oldStage = _curatorStage;
      _curatorStage = stage;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('curator_stage', stage.name);
      notifyListeners();
      await AppMetricaService().trackEvent('stage_changed', params: {'from': oldStage.name, 'to': stage.name});
    }
  }

  Future<void> clearAll() async {
    _workCountry = 'ru';
    _courierType = 'walk';
    _registrationSent = false;
    _hasReceivedBag = false;
    _isActiveCourier = false;
    _moyNalogLinked = false;
    _curatorStage = CuratorStage.preRegistration;
    notifyListeners();
  }
}
