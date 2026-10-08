import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'local_push_service.dart';
import 'locale_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('FCM Background message: ${message.messageId}');
  } catch (e) {
    debugPrint('FCM Background handler error: $e');
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (kIsWeb || _isInitialized) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // 1. Запрос прав на удалённые уведомления
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('FCM: Authorization status: ${settings.authorizationStatus}');

      // 2. Настройки для iOS (отображение баннеров на переднем плане)
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 3. Получение токена устройства
      try {
        final token = await messaging.getToken();
        debugPrint('FCM Registration Token: $token');
      } catch (e) {
        debugPrint('FCM getToken error: $e');
      }

      // 4. Подписка на общий топик всех курьеров
      try {
        await messaging.subscribeToTopic('all_couriers');
        final country = LocaleService().workCountry.toLowerCase();
        if (country.isNotEmpty) {
          await messaging.subscribeToTopic('couriers_$country');
        }
      } catch (e) {
        debugPrint('FCM subscribe topic error: $e');
      }

      // 5. Обработка входящих сообщений на переднем плане (Foreground)
      // На Android и iOS баннер отображается через LocalPushService
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.messageId}');
        final notification = message.notification;
        if (notification != null) {
          LocalPushService().showInstantPush(
            id: message.hashCode,
            title: notification.title ?? 'Курьер PRO Еда',
            body: notification.body ?? '',
          );
        }
      });

      // 6. Обработка нажатия на уведомление при открытии приложения
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Notification tapped by user: ${message.messageId}');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('FCM initialization failed: $e');
    }
  }

  /// Обновление подписки на топик при смене страны
  Future<void> updateCountryTopic(String newCountry) async {
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic('couriers_${newCountry.toLowerCase()}');
    } catch (e) {
      debugPrint('FCM update country topic error: $e');
    }
  }
}
