import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:yandex_metrica/yandex_metrica.dart';

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

  Future<void> init() async {
    if (_isInitialized || kIsWeb) return;
    
    try {
      await YandexMetrica.activate(
        YandexMetricaConfig(_apiKey)
          ..handleFirstActivationAsUpdateEnabled = true
          ..statisticsSending = StatisticsSending.Auto
          ..crashReporting = CrashReporting.Auto,
      );
      _isInitialized = true;
      debugPrint('AppMetrica: initialized');
    } catch (e) {
      debugPrint('AppMetrica: init error: $e');
    }
  }

  /// Трекинг события с параметрами
  Future<void> trackEvent(String name, {Map<String, dynamic>? params}) async {
    if (!_isInitialized || kIsWeb) return;
    try {
      await YandexMetrica.reportEvent(name, params);
      debugPrint('AppMetrica: $name ${params ?? ''}');
    } catch (e) {
      debugPrint('AppMetrica: trackEvent error: $e');
    }
  }

  /// Трекинг ошибки
  Future<void> reportError(String message, {String? stackTrace}) async {
    if (!_isInitialized || kIsWeb) return;
    try {
      await YandexMetrica.reportError(message, stackTrace: stackTrace);
    } catch (_) {}
  }

  // ===== События воронки ( Goals ) =====
  
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
}