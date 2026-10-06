import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStateService extends ChangeNotifier {
  static final UserStateService _instance = UserStateService._internal();
  factory UserStateService() => _instance;
  UserStateService._internal();

  String _userName = '';
  String _userPhone = '';
  String _phoneDialCode = '+7';
  bool _hasCompletedOnboarding = false;
  bool _hasRegisteredCabinet = false;

  String get userName => _userName;
  String get userPhone => _userPhone;
  String get phoneDialCode => _phoneDialCode;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get hasRegisteredCabinet => _hasRegisteredCabinet;

  Future<void> init(SharedPreferences prefs, String defaultDialCode) async {
    _userName = prefs.getString('user_name') ?? '';
    _userPhone = prefs.getString('user_phone') ?? '';
    _phoneDialCode = prefs.getString('phone_dial_code') ?? defaultDialCode;
    _hasCompletedOnboarding = prefs.getBool('onboarding_completed') ?? false;
    _hasRegisteredCabinet = prefs.getBool('cabinet_registered') ?? false;

    if (_userName.isNotEmpty && _userPhone.isNotEmpty) {
      _hasRegisteredCabinet = true;
    }
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
  }) async {
    _userName = name;
    _userPhone = phone;
    _phoneDialCode = dialCode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_phone', phone);
    await prefs.setString('phone_dial_code', dialCode);
    notifyListeners();
  }

  Future<void> logout(String defaultDialCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    await prefs.remove('phone_dial_code');
    await prefs.remove('cabinet_registered');

    _userName = '';
    _userPhone = '';
    _phoneDialCode = defaultDialCode;
    _hasRegisteredCabinet = false;
    notifyListeners();
  }

  Future<void> clearAll() async {
    _userName = '';
    _userPhone = '';
    _phoneDialCode = '+7';
    _hasCompletedOnboarding = false;
    _hasRegisteredCabinet = false;
    notifyListeners();
  }
}
