import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:math';
import 'locale_service.dart';

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
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Логика по клику на пуш
      },
    );

    _isInitialized = true;
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Умная цепочка фоллоу-ап пушей после перехода на регистрацию
  /// Решает проблему 60.7% кандидатов, зависших на обучении и ошибках сети
  Future<void> scheduleCuratorFollowUps() async {
    if (kIsWeb) return;
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

  /// Персональные пуши под конкретный этап воронки (1-5)
  Future<void> scheduleStagePushes(int stage) async {
    if (kIsWeb) return;
    await cancelAllNotifications();

    final bool isCIS = LocaleService().workCountry != 'ru';
    final Map<int, List<Map<String, dynamic>>> stagePlans = {
      1: [
        {
          'delayMinutes': kTestPushIntervals ? 1 : 30,
          'title': 'Курьер PRO Еда • Помощник',
          'body': '👋 Заполнили анкету? Если возник вопрос по фотоконтролю — напишите Помощнику в чат!',
        },
        {
          'delayMinutes': kTestPushIntervals ? 2 : 180,
          'title': 'Помощь с регистрацией 📲',
          'body': '⚠️ Ошибка при входе в Яндекс Про? В 90% случаев мешает включённый VPN! Выключите VPN и повторите.',
        },
      ],
      2: isCIS
          ? [
              {
                'delayMinutes': kTestPushIntervals ? 1 : 60,
                'title': 'Звонок оператора 📞',
                'body': 'Держите телефон под рукой: оператор позвонит для проверки анкеты и активации профиля.',
              },
              {
                'delayMinutes': kTestPushIntervals ? 2 : 360,
                'title': 'Подтверждение заявки 📲',
                'body': 'Не пропустите звонок: оператор согласует удобный адрес курьерского центра для выдачи сумки.',
              },
            ]
          : [
              {
                'delayMinutes': kTestPushIntervals ? 1 : 60,
                'title': 'Связка с «Мой налог» 📲',
                'body': 'Откройте шпаргалку: покажем, как привязать статус самозанятого за 1 минуту для выплат каждый день.',
              },
              {
                'delayMinutes': kTestPushIntervals ? 2 : 360,
                'title': 'Ежедневные выплаты 💳',
                'body': 'Завершите подтверждение в «Мой налог», чтобы доход поступал на карту сразу после слота.',
              },
            ],
      3: [
        {
          'delayMinutes': kTestPushIntervals ? 1 : 120,
          'title': 'Бесплатная экипировка 🎒',
          'body': 'Термокороб и форма ждут вас в Центре Доставки! Выдаются бесплатно и без залога.',
        },
        {
          'delayMinutes': kTestPushIntervals ? 2 : 1440,
          'title': 'Адреса центров выдачи 📍',
          'body': 'Загляните в раздел «Мой путь»: там указаны точный адрес и часы работы вашего центра выдачи.',
        },
      ],
      4: [
        {
          'delayMinutes': kTestPushIntervals ? 1 : 120,
          'title': 'Горячие слоты у дома 🔥',
          'body': 'Сейчас высокий спрос! Выйдите на слот от 2 часов в любимом районе — первый заказ самый лёгкий.',
        },
      ],
      5: [
        {
          'delayMinutes': kTestPushIntervals ? 1 : 1440,
          'title': 'Бонус новичка 🎁',
          'body': 'Выполните первые 5 доставок, чтобы забрать максимальную приветственную премию партнёра!',
        },
      ],
    };

    final items = stagePlans[stage] ?? [];
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final delay = item['delayMinutes'] as int;
      tz.TZDateTime scheduledDate = now.add(Duration(minutes: delay));

      if (!kTestPushIntervals && (scheduledDate.hour >= 22 || scheduledDate.hour < 8)) {
        int daysToAdd = scheduledDate.hour >= 22 ? 1 : 0;
        scheduledDate = tz.TZDateTime(
          tz.local,
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day + daysToAdd,
          10,
          0,
        );
      }

      await _scheduleNotification(
        id: 200 + (stage * 10) + i,
        title: item['title'] as String,
        body: item['body'] as String,
        scheduledDate: scheduledDate,
      );
    }
  }

  /// Стандартная воронка подогрева
  Future<void> scheduleFunnelNotifications({int startIndex = 0}) async {
    if (kIsWeb) return;
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
    if (kIsWeb) return;
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
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
