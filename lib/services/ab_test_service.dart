import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'locale_service.dart';

/// A/B Test Service — remote config + local persistence
/// Supports: Firebase Remote Config fallback to JSON assets
class ABTestService {
  static final ABTestService _instance = ABTestService._internal();
  factory ABTestService() => _instance;
  ABTestService._internal();

  // Experiment keys
  static const String EXP_CTA_TEXT = 'cta_text_variant';
  static const String EXP_PUSH_TIMING = 'push_timing';
  static const String EXP_PROACTIVE_FREQ = 'proactive_frequency';

  // Variant storage keys
  static const String _prefsKey = 'ab_test_variants';
  static const String _initializedKey = 'ab_test_initialized';

  Map<String, String> _variants = {};
  Map<String, dynamic> _remoteConfig = {};
  bool _isInitialized = false;

  // Default variants (A = control)
  static const Map<String, String> _defaults = {
    EXP_CTA_TEXT: 'A',
    EXP_PUSH_TIMING: 'A',
    EXP_PROACTIVE_FREQ: 'A',
  };

  Map<String, String> get variants => Map.unmodifiable(_variants);
  bool get isInitialized => _isInitialized;

  /// Initialize: load persisted variants, then try remote config
  Future<void> init() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();

    // 1. Load persisted variants
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      _variants = Map<String, String>.from(json.decode(saved));
    }

    // 2. Try remote config (Firebase or assets)
    await _loadRemoteConfig();

    // 3. Assign variants for new experiments (50/50 randomization)
    bool changed = false;
    for (final expKey in _defaults.keys) {
      if (!_variants.containsKey(expKey)) {
        _variants[expKey] = _randomVariant();
        changed = true;
      }
    }

    // 4. Persist if new assignments
    if (changed) {
      await prefs.setString(_prefsKey, json.encode(_variants));
      await prefs.setBool(_initializedKey, true);
    }

    _isInitialized = true;
  }

  /// Load remote config from Firebase Remote Config or local JSON asset
  Future<void> _loadRemoteConfig() async {
    try {
      // Try Firebase Remote Config first (if available)
      // For now, load from assets as fallback
      final String jsonString = await rootBundle.loadString('assets/config/ab_config.json');
      _remoteConfig = json.decode(jsonString);
    } catch (e) {
      // Config not found, use defaults
      _remoteConfig = {};
    }
  }

  /// Get variant for experiment (A or B)
  String getVariant(String experimentKey) {
    return _variants[experimentKey] ?? _defaults[experimentKey] ?? 'A';
  }

  /// Get variant as bool (true = B variant)
  bool isVariantB(String experimentKey) => getVariant(experimentKey) == 'B';

  /// Get remote config value with fallback
  T? getRemoteValue<T>(String key, T fallback) {
    if (_remoteConfig.containsKey(key)) {
      return _remoteConfig[key] as T?;
    }
    return fallback;
  }

  /// Random 50/50 assignment
  String _randomVariant() => DateTime.now().millisecondsSinceEpoch % 2 == 0 ? 'A' : 'B';

  /// Force variant (for testing / remote config override)
  Future<void> setVariant(String experimentKey, String variant) async {
    _variants[experimentKey] = variant;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, json.encode(_variants));
  }

  /// Reset all variants (for testing)
  Future<void> reset() async {
    _variants.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    await prefs.remove(_initializedKey);
    await init();
  }

  /// Get experiment config for AppMetrica tracking
  Map<String, String> getAllVariantsForTracking() => Map.from(_variants);

  /// CTA Text variant: A = "Заполнить Анкету", B = "Стать курьером"
  String getCtaText(LocaleService locale) {
    final variant = getVariant(EXP_CTA_TEXT);
    if (variant == 'B') {
      return locale.tr('cta_become_courier');
    }
    return locale.tr('cta_fill_anketa');
  }

  /// Push timing variant: A = 30m/3h/24h, B = 1h/4h/48h
  List<int> getPushDelaysMinutes() {
    final variant = getVariant(EXP_PUSH_TIMING);
    if (variant == 'B') {
      return [60, 240, 2880]; // 1h, 4h, 48h
    }
    return [30, 180, 1440]; // 30m, 3h, 24h
  }

  /// Proactive frequency: A = every visit, B = every 2nd visit
  bool shouldShowProactive(int visitCount) {
    final variant = getVariant(EXP_PROACTIVE_FREQ);
    if (variant == 'B') {
      return visitCount % 2 == 0;
    }
    return true;
  }
}
