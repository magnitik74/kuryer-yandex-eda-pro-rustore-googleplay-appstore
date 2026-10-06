import 'dart:async';
import 'package:flutter/foundation.dart';

// TODO: подключить appmetrica_plugin после публикации на pub.dev

/// Сервис AppMetrica для трекинга событий воронки
/// API Key: 4ff9cec0-7d1c-4824-a335-c44f16c0ec47
/// Post API Key: 5acd9c81-2676-422e-9ce8-d6176cd29178
class AppMetricaService {
  static final AppMetricaService _instance = AppMetricaService._internal();
  factory AppMetricaService() => _instance;
  AppMetricaService._internal();

  static const String _apiKey = '4ff9cec0-7d1c-4824-a335-c44f16c0ec47';
  static const String _postApiKey = '5acd9c81-2676-422e-9ce8-d6176cd29178';
  bool _isInitialized = false;
  DateTime? _sessionStartTime;
  String? _lastScreen;

  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;
    try {
      _isInitialized = true;
      debugPrint('AppMetrica: initialized (stub)');
    } catch (e) {
      debugPrint('AppMetrica: init error: $e');
    }
  }

  /// Трекинг события с параметрами
  Future<void> trackEvent(String name, {Map<String, dynamic>? params}) async {
    if (!_isInitialized || kIsWeb) return;
    try {
      debugPrint('AppMetrica: $name ${params ?? ''}');
    } catch (e) {
      debugPrint('AppMetrica: trackEvent error: $e');
    }
  }

  /// Трекинг ошибки
  Future<void> reportError(String message, {String? stackTrace}) async {
    if (!_isInitialized || kIsWeb) return;
    try {
    } catch (_) {}
  }

  // ===== Session / Screen tracking =====

  Future<void> sessionStart({required String country, required String format}) async {
    _sessionStartTime = DateTime.now();
    await trackEvent('session_start', params: {
      'country': country,
      'format': format,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> sessionEnd({required String country, required String format}) async {
    final duration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;
    await trackEvent('session_end', params: {
      'country': country,
      'format': format,
      'duration_seconds': duration,
    });
    _sessionStartTime = null;
  }

  Future<void> screenView({
    required String screenName,
    required String country,
    required String format,
    String? previousScreen,
  }) async {
    _lastScreen = screenName;
    await trackEvent('screen_view', params: {
      'screen': screenName,
      'country': country,
      'format': format,
      'previous_screen': previousScreen,
    });
  }

  // ===== A/B Experiment tracking =====

  Future<void> trackExperimentVariant({
    required String experimentKey,
    required String variant, // 'A' or 'B'
    required String country,
  }) async {
    await trackEvent('experiment_variant', params: {
      'experiment': experimentKey,
      'variant': variant,
      'country': country,
    });
  }

  Future<void> trackAllExperimentVariants({
    required Map<String, String> variants,
    required String country,
  }) async {
    for (final entry in variants.entries) {
      await trackExperimentVariant(
        experimentKey: entry.key,
        variant: entry.value,
        country: country,
      );
    }
  }

  // ===== Funnel events =====

  Future<void> onboardingStart({required String country, required String lang}) async {
    await trackEvent('onboarding_start', params: {'country': country, 'lang': lang});
  }

  Future<void> onboardingFormatSelected({required String format, required String country}) async {
    await trackEvent('onboarding_format_selected', params: {'format': format, 'country': country});
  }

  Future<void> onboardingComplete({required String format, required String country, required bool hasName, required bool hasPhone}) async {
    await trackEvent('onboarding_complete', params: {
      'format': format, 'country': country, 'has_name': hasName, 'has_phone': hasPhone
    });
  }

  Future<void> chatOpened({required String stage, required String format, required String country}) async {
    await trackEvent('chat_opened', params: {'stage': stage, 'format': format, 'country': country});
  }

  Future<void> chatQuestionAsked({required String topic, required String country}) async {
    await trackEvent('chat_question_asked', params: {'topic': topic, 'country': country});
  }

  Future<void> registrationClicked({required String country, required String format, required String source}) async {
    await trackEvent('registration_clicked', params: {'country': country, 'format': format, 'source': source});
  }

  Future<void> registrationSent({required String country, required String format}) async {
    await trackEvent('registration_sent', params: {'country': country, 'format': format});
  }

  Future<void> pushReceived({required String pushType}) async {
    await trackEvent('push_received', params: {'push_type': pushType});
  }

  Future<void> pushClicked({required String pushType}) async {
    await trackEvent('push_clicked', params: {'push_type': pushType});
  }

  Future<void> moyNalogLinked({required String country}) async {
    await trackEvent('moy_nalog_linked', params: {'country': country});
  }

  Future<void> bagReceived({required String country, required String city}) async {
    await trackEvent('bag_received', params: {'country': country, 'city': city});
  }

  Future<void> firstOrderDone({required String country, required String format}) async {
    await trackEvent('first_order_done', params: {'country': country, 'format': format});
  }

  Future<void> ratingShown({required String store, required int rating}) async {
    await trackEvent('rating_shown', params: {'store': store, 'rating': rating});
  }

  Future<void> ratingSentToStore({required String store}) async {
    await trackEvent('rating_sent_to_store', params: {'store': store});
  }

  Future<void> appOpen({required bool coldStart, required String country}) async {
    await trackEvent('app_open', params: {'cold_start': coldStart, 'country': country});
  }

  // ===== Goals events =====

  Future<void> goalSelected({
    required String goalKey, // 'iphone', 'scooter', 'vacation', 'custom'
    required double goalAmount,
    required String country,
    required String format,
  }) async {
    await trackEvent('goal_selected', params: {
      'goal': goalKey,
      'goal_amount': goalAmount.round(),
      'country': country,
      'format': format,
    });
  }

  Future<void> goalProgressUpdated({
    required String goalKey,
    required double goalAmount,
    required double currentProgress, // 0.0 - 1.0
    required int shiftsCompleted,
    required int shiftsNeeded,
    required String country,
  }) async {
    await trackEvent('goal_progress', params: {
      'goal': goalKey,
      'goal_amount': goalAmount.round(),
      'progress_pct': (currentProgress * 100).round(),
      'shifts_completed': shiftsCompleted,
      'shifts_needed': shiftsNeeded,
      'country': country,
    });
  }

  Future<void> goalAchieved({
    required String goalKey,
    required double goalAmount,
    required String country,
  }) async {
    await trackEvent('goal_achieved', params: {
      'goal': goalKey,
      'goal_amount': goalAmount.round(),
      'country': country,
    });
  }
}
