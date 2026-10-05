import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/locale_service.dart';
import '../services/ab_test_service.dart';

class LocalPushService {
  static final LocalPushService _instance = LocalPushService._internal();
  factory LocalPushService() => _instance;
  LocalPushService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Флаг для тестирования: если true, интервал будет 1 минута, иначе реальные часы.
  static const bool kTestPushIntervals = false; 

  bool _isInitialized = false;

  Future<void> init() async {
    if (kIsWeb || _isInitialized) return;
    
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
        // Логика по клику на пуш
      },
    );

    _isInitialized = true;
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Event-driven: вызывается после нажатия кнопки регистрации / отправки анкеты
  Future<void> onRegistrationSent() async {
    await cancelAllNotifications();

    final List<Map<String, dynamic>> followUps = [
      {
        'delayMinutes': kTestPushIntervals ? 1 : 30,
        'title': 'Курьер PRO Еда • Помощник',
        'body': '👋 Получилось отправить анкету? Если возник вопрос по фотоконтролю — напишите Помощнику в чат!',
      },
      {
        'delayMinutes': kTestPushIntervals ? 2 : 180, // 3 часа
        'title': 'Помощь с регистрацией',
        'body': '⚠️ Ошибка входа в приложение? В 90% случаев мешает включённый VPN! Выключите VPN и повторите.',
      },
      {
        'delayMinutes': kTestPushIntervals ? 3 : 1440, // 24 часа
        'title': 'Связка с «Мой налог»',
        'body': '📲 Не подтверждается статус? Откройте подсказку куратора: покажем, как привязать "Мой налог" за 1 минуту.',
      },
      {
        'delayMinutes': kTestPushIntervals ? 4 : 4320, // 3 дня
        'title': 'Бесплатная экипировка 🎒',
        'body': 'Термокороб ждёт вас! Завершите оформление, чтобы забрать форму без залога в курьерском центре.',
      },
      {
        'delayMinutes': kTestPushIntervals ? 5 : 7200, // 5 дней
        'title': 'Первые 5 заказов 🎁',
        'body': 'Выполните 5 доставок, чтобы получить максимальные бонусы новичка и закрепить статус партнёра!',
      },
    ];

    tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < followUps.length; i++) {
      final item = followUps[i];
      final delay = item['delayMinutes'] as int;
      tz.TZDateTime scheduledDate = now.add(Duration(minutes: delay));

      // Перенос ночных пушей (22:00 - 08:00)
      if (!kTestPushIntervals && (scheduledDate.hour >= 22 || scheduledDate.hour < 8)) {
        int daysToAdd = scheduledDate.hour >= 22 ? 1 : 0;
        scheduledDate = tz.TZDateTime(
          tz.local,
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day + daysToAdd,
          9,
          Random().nextInt(20),
        );
      }

      await _scheduleNotification(
        id: 100 + i,
        title: item['title'] as String,
        body: item['body'] as String,
        scheduledDate: scheduledDate,
      );
    }
  }

  /// Event-driven: получена сумка → новые пуши для активного курьера
  Future<void> onBagReceived() async {
    await cancelAllNotifications();

    final List<Map<String, dynamic>> activeCourierPushes = [
      {
        'delayMinutes': kTestPushIntervals ? 1 : 60, // 1 час
        'title': 'Курьер PRO Еда',
        'body': '🎒 Сумка получена! Выходи на первый слот. Совет: начни с 2-3 часов вечером, почувствуй ритм.',
      },
      {
        'delayMinutes': kTestPushIntervals ? 2 : 1440, // 1 день
        'title': 'Первый заказ',
        'body': '🚀 Как прошёл первый заказ? Если есть вопросы по тарифам или зоне — пиши в чат, помогу.',
      },
      {
        'delayMinutes': kTestPushIntervals ? 3 : 4320, // 3 дня
        'title': 'Бонусы новичка',
        'body': '🎁 Выполни 5 доставок — получи максимум бонусов новичка и закрепи статус партнёра!',
      },
      {
        'delayMinutes': kTestPushIntervals ? 4 : 10080, // 7 дней
        'title': 'Твои цели',
        'body': '📈 Хочешь новый iPhone / самокат / отпуск? В калькуляторе (вкладка Доход) посчитай, сколько смен нужно.',
      },
    ];

    tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < activeCourierPushes.length; i++) {
      final item = activeCourierPushes[i];
      final delay = item['delayMinutes'] as int;
      tz.TZDateTime scheduledDate = now.add(Duration(minutes: delay));

      if (!kTestPushIntervals && (scheduledDate.hour >= 22 || scheduledDate.hour < 8)) {
        int daysToAdd = scheduledDate.hour >= 22 ? 1 : 0;
        scheduledDate = tz.TZDateTime(
          tz.local,
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day + daysToAdd,
          9,
          Random().nextInt(20),
        );
      }

      await _scheduleNotification(
        id: 200 + i,
        title: item['title'] as String,
        body: item['body'] as String,
        scheduledDate: scheduledDate,
      );
    }
  }

  /// Event-driven: первый заказ выполнен
  Future<void> onFirstOrderDone() async {
    await cancelAllNotifications();
    
    final List<Map<String, dynamic>> pushes = [
      {
        'delayMinutes': kTestPushIntervals ? 1 : 60,
        'title': 'Курьер PRO Еда',
        'body': '🎉 Первый заказ выполнен! Молодец. Продолжай в том же духе — к бонусам новичка близко.',
      },
      {
        'delayMinutes': kTestPushIntervals ? 2 : 4320, // 3 дня
        'title': '5 заказов = бонус',
        'body': 'Осталось немного до 5 доставок. Выполни их — и откроются макс. тарифы и бонусы!',
      },
    ];

    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    for (int i = 0; i < pushes.length; i++) {
      final delay = pushes[i]['delayMinutes'] as int;
      tz.TZDateTime scheduledDate = now.add(Duration(minutes: delay));
      if (!kTestPushIntervals && (scheduledDate.hour >= 22 || scheduledDate.hour < 8)) {
        int daysToAdd = scheduledDate.hour >= 22 ? 1 : 0;
        scheduledDate = tz.TZDateTime(tz.local, scheduledDate.year, scheduledDate.month, scheduledDate.day + daysToAdd, 9, Random().nextInt(20));
      }
      await _scheduleNotification(id: 300 + i, title: pushes[i]['title'] as String, body: pushes[i]['body'] as String, scheduledDate: scheduledDate);
    }
  }

  /// Event-driven: Мой налог привязан
    Future<void> onMoyNalogLinked() async {
      // Отменяем конкретный пуш про Мой налог (id 102)
      await flutterLocalNotificationsPlugin.cancel(102);
    }

    /// Goal reminder pushes: вызывается при обновлении прогресса цели (80% и 100%)
    Future<void> scheduleGoalReminders({
      required String goalName,
      required int shiftsLeft,
      required String shiftsWord,
      required double progress,
    }) async {
      final locale = LocaleService();
      final abTest = ABTestService();
      final delays = abTest.getPushDelaysMinutes(); // A/B test timing
    
      tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      List<Map<String, dynamic>> reminders = [];

      if (progress >= 0.8 && progress < 1.0) {
        // 80% reminder
        reminders.add({
          'id': 400,
          'delayMinutes': delays[0], // First delay from A/B config
          'title': locale.tr('appName'),
          'body': locale.tr('goalReminder80')
            .replaceAll('{shifts}', shiftsLeft.toString())
            .replaceAll('{shiftsWord}', shiftsWord),
        });
      } else if (progress >= 1.0) {
        // 100% achievement
        reminders.add({
          'id': 401,
          'delayMinutes': 0, // Immediate
          'title': '🎉 Цель достигнута!',
          'body': locale.tr('goalReminder100').replaceAll('{goalName}', goalName),
        });
      }

      for (var reminder in reminders) {
        final delay = reminder['delayMinutes'] as int;
        tz.TZDateTime scheduledDate = now.add(Duration(minutes: delay));
      
        // Перенос ночных пушей
        if (!kTestPushIntervals && (scheduledDate.hour >= 22 || scheduledDate.hour < 8)) {
          int daysToAdd = scheduledDate.hour >= 22 ? 1 : 0;
          scheduledDate = tz.TZDateTime(
            tz.local,
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day + daysToAdd,
            9,
            Random().nextInt(20),
          );
        }

        await _scheduleNotification(
          id: reminder['id'] as int,
          title: reminder['title'] as String,
          body: reminder['body'] as String,
          scheduledDate: scheduledDate,
        );
      }
    }

    /// Cancel goal reminders
    Future<void> cancelGoalReminders() async {
      await flutterLocalNotificationsPlugin.cancel(400);
      await flutterLocalNotificationsPlugin.cancel(401);
    }

  /// Стандартная воронка подогрева (для холодных лидов)
  Future<void> scheduleFunnelNotifications({int startIndex = 0}) async {
    await cancelAllNotifications();

    const int totalPushes = 15;
    final List<String> texts = [
      "🔥 Кэфы горят! Сейчас заказов больше, чем курьеров. Отличный момент для старта!",
      "💸 Оформляйтесь и начните получать регулярные выплаты на карту.",
      "💳 Ежедневный доход. Заработали сегодня — получили деньги сразу!",
      "⏳ Свободный график: работайте пару часов вечером или полные выходные.",
      "🚀 Приветственные бонусы активны! Успейте забрать премию за первые доставки.",
      "🎒 Термосумка и форма выдаются бесплатно и без залога.",
      "🚴‍♂️ Доставляйте пешком, на вело или авто. Выбирайте любимый район!",
      "📈 Доход зависит от вас. Чем больше доставок, тем выше заработок.",
      "💼 Идеальная подработка: легко совмещать с учебой или другой работой.",
      "💰 Тысячи курьеров уже вышли на линию. Присоединяйтесь!"
    ];

    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = now;

    for (int i = 0; i < totalPushes; i++) {
      if (kTestPushIntervals) {
        scheduledDate = scheduledDate.add(const Duration(minutes: 1));
      } else {
        scheduledDate = scheduledDate.add(Duration(hours: (i == 0) ? 1 : 4));
        if (scheduledDate.hour >= 22 || scheduledDate.hour < 8) {
          int daysToAdd = scheduledDate.hour >= 22 ? 1 : 0;
          scheduledDate = tz.TZDateTime(
            tz.local,
            scheduledDate.year,
            scheduledDate.month,
            scheduledDate.day + daysToAdd,
            8,
            Random().nextInt(30),
          );
        }
      }

      int textIndex = (startIndex + i) % texts.length;
      String message = texts[textIndex];

      await _scheduleNotification(
        id: i,
        title: "Курьер PRO Еда • Помощник",
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
          channelDescription: 'Уведомления куратора о регистрации',
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
