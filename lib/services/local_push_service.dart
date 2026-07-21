import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'dart:math';

class LocalPushService {
  static final LocalPushService _instance = LocalPushService._internal();
  factory LocalPushService() => _instance;
  LocalPushService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Флаг для тестирования: если true, интервал будет 1 минута, иначе 3 часа.
  static const bool kTestPushIntervals = false; 

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Логика по клику на пуш (если нужна)
      },
    );

    _isInitialized = true;
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Планирует воронку уведомлений.
  /// Вызывайте эту функцию после получения разрешений на уведомления
  /// (например, на PermissionScreen) или при запуске приложения, если курьер еще не сделал заказ.
  Future<void> scheduleFunnelNotifications({int startIndex = 0}) async {
    await cancelAllNotifications();

    const int totalPushes = 20;
    
    final List<String> texts = [
      "Вы прошли регистрацию?",
      "Вы собрали доки для регистрации?",
      "Вы записались на выдачу рюкзака и формы?",
      "Очень много заказов, нужны курьеры. Кэфы горят! 🔥",
    ];

    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = now;

    for (int i = 0; i < totalPushes; i++) {
      // Расчет следующего времени
      if (kTestPushIntervals) {
        scheduledDate = scheduledDate.add(const Duration(minutes: 1));
      } else {
        if (i == 0) {
          scheduledDate = scheduledDate.add(const Duration(minutes: 15));
        } else {
          scheduledDate = scheduledDate.add(const Duration(hours: 3));
        }
        
        // Перенос ночных пушей (22:00 - 08:00)
        if (scheduledDate.hour >= 22 || scheduledDate.hour < 8) {
          int daysToAdd = scheduledDate.hour >= 22 ? 1 : 0;
          scheduledDate = tz.TZDateTime(
            tz.local,
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day + daysToAdd,
            8, // переносим на 8 утра
            Random().nextInt(30), // добавляем немного случайности (0-30 мин)
          );
        }
      }

      int textIndex = (startIndex + i) % texts.length;
      String message = texts[textIndex];

      await _scheduleNotification(
        id: i,
        title: "ЕдаGo",
        body: message,
        scheduledDate: scheduledDate,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'funnel_channel_id',
          'Системные уведомления',
          channelDescription: 'Уведомления о этапах регистрации',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
