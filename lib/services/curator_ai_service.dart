import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/ai_config.dart';
import '../services/locale_service.dart';

class CuratorMessage {
  final String text;
  final bool isUser;
  final bool isActionCard;
  final String? actionType;
  final DateTime timestamp;

  CuratorMessage({
    required this.text,
    required this.isUser,
    this.isActionCard = false,
    this.actionType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class CuratorResponse {
  final String text;
  final bool showActionCard;
  final String? actionType;

  CuratorResponse({
    required this.text,
    this.showActionCard = false,
    this.actionType,
  });
}

class CuratorAiService {
  static const String defaultVercelEndpoint =
      'https://kuryer-yandex-eda-pro-rustore-googleplay-appstore-magnitik74.vercel.app/api/askCurator';

  static final CuratorAiService _instance = CuratorAiService._internal();
  factory CuratorAiService() => _instance;
  CuratorAiService._internal();

  String? _cloudEndpoint;
  bool _isInit = false;

  Future<void> _ensureInitialized() async {
    if (_isInit) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEndpoint = prefs.getString('curator_cloud_endpoint');
      if (storedEndpoint != null &&
          storedEndpoint.isNotEmpty &&
          !storedEndpoint.contains('localhost') &&
          !storedEndpoint.contains('cloudfunctions.net')) {
        _cloudEndpoint = storedEndpoint;
      } else {
        _cloudEndpoint = defaultVercelEndpoint;
        await prefs.setString('curator_cloud_endpoint', defaultVercelEndpoint);
      }

      // Динамически подтягиваем защищённые настройки из Firestore
      try {
        if (!kIsWeb) {
          final doc = await FirebaseFirestore.instance.collection('app_config').doc('ai_settings').get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            final cloudEp = data['cloud_endpoint'] as String?;
            if (cloudEp != null &&
                cloudEp.isNotEmpty &&
                !cloudEp.contains('cloudfunctions.net')) {
              _cloudEndpoint = cloudEp;
            }
          }
        } else {
          // В Web-превью загружаем через REST API Firestore
          const url = 'https://firestore.googleapis.com/v1/projects/courier-f5652/databases/(default)/documents/app_config/ai_settings?key=«redacted:AIza…»';
          final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
          if (res.statusCode == 200) {
            final data = jsonDecode(utf8.decode(res.bodyBytes));
            // cloud_endpoint если есть
          }
        }
      } catch (e) {
        debugPrint('CuratorAiService: Firestore fetch error: $e');
      }
    } catch (_) {}
    _isInit = true;
  }

  Future<void> setCloudEndpoint(String endpoint) async {
    _cloudEndpoint = endpoint.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('curator_cloud_endpoint', _cloudEndpoint!);
    } catch (_) {}
  }

  /// Главная точка входа для общения с Персональным помощником.
    /// Архитектура: Local KB (мгновенно) → Vercel Gateway (GigaChat) fallback
    Future<CuratorResponse> ask(
      String userQuestion, {
      List<Map<String, String>> history = const [],
      required String lang,
      required String country,
    }) async {
      await _ensureInitialized();
      final locale = LocaleService();
      final cfg = locale; // доступ к countryConfig через LocaleService
      final lower = userQuestion.toLowerCase().trim();

      // Track question topic
      final topic = _classifyTopic(lower);
      if (topic != null) {
        await locale.trackEvent('chat_question_asked', params: {
          'topic': topic,
          'country': country,
        });
      }

      // 1. Проверяем кто ты / куратор / робот
      if (_matches(lower, ['кто ты', 'ты кто', 'как звать', 'как зовут', 'сен кімсің', 'кимсиң', 'kimsan', 'робот', 'бот', 'нейросеть', 'gigachat', 'сбер'])) {
        return _getWhoAreYouResponse(lang);
      }

      // 2. Ошибки регистрации / VPN
      if (_matches(lower, ['ошибка', 'не входит', 'сбой', 'vpn', 'впн', 'кэш', 'завис', 'xato', 'иштебей', 'қате'])) {
        return _buildResponse(cfg.faq['vpn_error'] ?? '');
      }

      // 3. Мой налог / самозанятость
      if (_matches(lower, ['мой налог', 'самозанят', 'смз', 'налог', 'партнер', 'moy nalog', 'салык', 'e-salyq', 'солиқ', 'түндүк', 'пдн'])) {
        return _buildResponse(cfg.faq['moy_nalog'] ?? '');
      }

      // 4. Документы / гражданство
      if (_matches(lower, ['документ', 'паспорт', 'граждан', 'узбек', 'кыргыз', 'патент', 'таджик', 'еаэс', 'hujjat', 'документтер', 'құжат', 'пинфл', 'унп', 'виза', 'внж', 'рвп'])) {
        return _getDocsResponse(lang, country, cfg);
      }

      // 5. Возраст
      if (_matches(lower, ['лет', 'возраст', '16', '18', 'школьник', 'несовершеннолет', 'yosh', 'жаш'])) {
        return _buildResponse(cfg.faq['age'] ?? '');
      }

      // 6. Сумка / экипировка
      if (_matches(lower, ['сумк', 'короб', 'экипировк', 'форма', 'залог', 'платн', 'sumka', 'тегін', 'термо'])) {
        return _buildResponse(cfg.faq['bag'] ?? '');
      }

      // 7. Штрафы и опоздания
      if (_matches(lower, ['штраф', 'опозда', 'наказан', 'вычет', 'jarima', 'айып'])) {
        return _buildResponse(cfg.faq['fines'] ?? '');
      }

      // 8. Фотоконтроль
      if (_matches(lower, ['фотоконтроль', 'фото', 'селфи', 'диагностика'])) {
        return _buildResponse(cfg.faq['photo_control'] ?? '');
      }

      // 9. Видео обучение
      if (_matches(lower, ['видео', 'обучен', 'не грузит', 'не работает', 'видео не'])) {
        return _buildResponse(cfg.faq['video_training'] ?? '');
      }

      // 10. Доход / тарифы
      if (_matches(lower, ['доход', 'зарплат', 'заработ', 'сколько платят', 'тариф', 'ставк', 'платит'])) {
        return _getIncomeResponse(lang, country, cfg);
      }

      // 11. Готовность начать / регистрация
      if (_matches(lower, ['рег', 'хочу', 'давай', 'готов', 'начать', 'ссылк', 'анкет', 'устро', 'ro\'yxat', 'каттал', 'тіркел', 'заполнить', 'анкету'])) {
        return _getRegistrationPromptResponse(lang);
      }

      // 12. Попытка через Vercel Gateway (GigaChat на сервере)
      final cloudResponse = await _queryCloudCurator(userQuestion, history, lang, country);
      if (cloudResponse != null) return cloudResponse;

      // 13. Фоллбек: базовый дружелюбный ответ
      return _getDefaultResponse(lang);
    }

    String? _classifyTopic(String lower) {
      if (_matches(lower, ['ошибка', 'не входит', 'сбой', 'vpn', 'впн', 'кэш', 'завис'])) return 'vpn_error';
      if (_matches(lower, ['мой налог', 'самозанят', 'смз', 'налог', 'партнер', 'moy nalog', 'салык'])) return 'moy_nalog';
      if (_matches(lower, ['документ', 'паспорт', 'граждан', 'патент', 'виза', 'внж', 'рвп'])) return 'docs';
      if (_matches(lower, ['возраст', 'лет', '16', '18', 'школьник'])) return 'age';
      if (_matches(lower, ['сумк', 'короб', 'экипировк', 'форма', 'залог', 'термо'])) return 'bag';
      if (_matches(lower, ['штраф', 'опозда', 'наказан', 'вычет'])) return 'fines';
      if (_matches(lower, ['фотоконтроль', 'фото', 'селфи', 'диагностика'])) return 'photo_control';
      if (_matches(lower, ['видео', 'обучен', 'не грузит'])) return 'video_training';
      if (_matches(lower, ['доход', 'зарплат', 'заработ', 'сколько платят', 'тариф'])) return 'income';
      if (_matches(lower, ['рег', 'хочу', 'давай', 'готов', 'начать', 'ссылк', 'анкет', 'устро'])) return 'registration';
      if (_matches(lower, ['кто ты', 'ты кто', 'робот', 'бот', 'нейросеть', 'gigachat', 'сбер'])) return 'identity';
      return null;
    }

    bool _matches(String text, List<String> keywords) {
      return keywords.any((k) => text.contains(k));
    }

    CuratorResponse _buildResponse(String text, {bool showActionCard = false, String? actionType}) {
      return CuratorResponse(
        text: text,
        showActionCard: showActionCard,
        actionType: actionType,
      );
    }

    // --- Локальные ответы по Базе Знаний ---

    CuratorResponse _getWhoAreYouResponse(String lang) {
      switch (lang) {
        case 'uz':
          return _buildResponse('Men yetkazib berish xizmatidagi shaxsiy kuratoringizman. Kuryer bo\'lib ishga kirish, daromad, erkin grafik va zarur narsalarni olishda yordam beraman. Shartlar bo\'yicha savolingiz bormi yoki rasmiylashtirishga tayyormisiz?');
        case 'kg':
          return _buildResponse('Мен жеткирүү кызматындагы жеке кураторуңузмун. Курьер болуп орношуу, киреше, график жана керектүү нерселерди алууда жардам берем. Шарттар боюнча сурооңуз барбы же катталууга даярсызбы?');
        case 'kz':
          return _buildResponse('Мен жеткізу қызметіндегі жеке кураторыңызбын. Курьер ретінде тіркелуге, табыс, икемді график және қажетті жабдықтарды алуда көмектесемін. Шарттар бойынша көмектесейін бе немесе тіркелуге дайынсыз ба?');
        default:
          return _buildResponse('Я твой личный куратор и наставник в сервисе доставки. Помогаю соискателям устроиться курьером: рассказываю про доход, график, документы и получение экипировки. Тебе подсказать по условиям или хочешь оформиться?');
      }
    }

    CuratorResponse _getDocsResponse(String lang, String country, LocaleService cfg) {
      if (country == 'ru') {
        // Подробный ответ для РФ из конфига
        final docs = cfg.documents;
        final allDocs = <String>[];
        docs.forEach((_, list) => allDocs.addAll(list));
        final unique = allDocs.toSet().toList().join('\n• ');
      
        switch (lang) {
          case 'uz':
            return _buildResponse('📄 **Rossiyada ishlash uchun MDH (O\'zbekiston) fuqarolariga kerakli hujjatlar:**\n\n• $unique\n\n💡 *Termo-sumka va forma Kuryerlik markazidan beriladi.*');
          case 'kg':
            return _buildResponse('📄 **Россияда иштөө үчүн Кыргызстан жарандарына (ЕАЭС):**\n\n• $unique\n\n⚡ **ПАТЕНТ КЕРЕК ЭМЕС!** ЕАЭС келишими боюнча Кыргызстан жарандары патентсиз иштей алат.\n\n💡 *Термокуту жана экипировка Курьердик борбордон берилет.*');
          default:
            return _buildResponse('📄 **Документы для оформления доставки в РФ:**\n\n• $unique\n\nТермокороб и экипировка выдаются в Курьерском центре или ПВЗ.');
        }
      } else {
        // Для других стран — унифицированный ответ
        final docs = cfg.documents['all'] ?? [];
        final list = docs.join('\n• ');
        return _buildResponse('📄 **Для оформления в ${cfg.countryName} нужны:**\n\n• $list\n\n${cfg.operatorGreeting}');
      }
    }

    CuratorResponse _getIncomeResponse(String lang, String country, LocaleService cfg) {
      final rates = cfg.rates;
      final currency = cfg.currency;
      final maxAuto = cfg.maxMonthlyIncome['auto'] ?? 0;
      final formatLabels = {'auto': 'Авто 🚗', 'moto': 'Мото 🛵', 'bike': 'Вело 🚲', 'walk': 'Пеший 🚶'};
    
      final lines = rates.entries.map((e) {
        final label = formatLabels[e.key] ?? e.key;
        return '$label: ${e.value} $currency/час';
      }).join('\n');
    
      switch (lang) {
        case 'uz':
          return _buildResponse('💰 **Taxminiy daromad (${currency}):**\n\n$lines\n\nMaksimal avto: $maxAuto $currency/ой.\n\nBatafsil hisob — "Доход" бўлимида.');
        case 'kg':
          return _buildResponse('💰 **Тактык киреше (${currency}):**\n\n$lines\n\nМакс. авто: $maxAuto $currency/ай.\n\nБатаптал эсеп — "Киреше" бөлүмдө.');
        case 'kz':
          return _buildResponse('💰 **Болжамды табыс (${currency}):**\n\n$lines\n\nМакс. авто: $maxAuto $currency/ай.\n\nЕгжей-тегжейлі есеп — "Табыс" бөлімінде.');
        default:
          return _buildResponse('💰 **Примерные ставки (${currency}/час):**\n\n$lines\n\nМакс. авто: ${_formatNumber(maxAuto)} $currency/мес.\n\nТочный расчёт — во вкладке "Доход".');
      }
    }

    String _formatNumber(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );

    CuratorResponse _getRegistrationPromptResponse(String lang) {
      switch (lang) {
        case 'uz':
          return _buildResponse(
            '🚀 Ajoyib! Hamkorlik arizasini to\'ldirish uchun quyidagi "Anketani to\'ldirish" tugmasini bosing — bu faqat 2-3 daqiqa vaqt oladi. Keyin darhol kuryerlik markaziga borishingiz mumkin. Savollaringiz bo\'lsa, men shu yerdaman!',
            showActionCard: true,
            actionType: 'register',
          );
        case 'kg':
          return _buildResponse(
            '🚀 Абдан! Төмөнкү "Анкетасын толтуруу" баскычын басыңыз — бул 2-3 мүнөт алат. Андан кийинchstку курьердик борборго барууңуз мумкүн. Суроолор болсо, мен мындам!',
            showActionCard: true,
            actionType: 'register',
          );
        case 'kz':
          return _buildResponse(
            '🚀 Тамаша! Төмендегі "Анкетасын толтыру" батырмасын басыңыз — бұл тек 2-3 минутты алады. Соңында дарقى курьерлік орталыққа бара аласыз. Сұрақтар болса — мұндамын!',
            showActionCard: true,
            actionType: 'register',
          );
        default:
          return _buildResponse(
            '🚀 Отлично! Нажми кнопку «Заполнить Анкету» прямо под этим сообщением и заполни официальную анкету партнёра — это займёт всего 2-3 минуты. Сразу после этого сможешь получить экипировку и выйти на первые заказы. Если возникнут вопросы — пиши сюда, я на связи!',
            showActionCard: true,
            actionType: 'register',
          );
      }
    }

    CuratorResponse _getDefaultResponse(String lang) {
      switch (lang) {
        case 'uz':
          return _buildResponse('Men sizga kuryer bo\'lib ro\'yxatdan o\'tish, hujjatlar va kunlik to\'lovlar bo\'yicha yordam beruvchi shaxsiy kuratorman. Savolingizni yozing yoki kerakli mavzuni tanlang:');
        case 'kg':
          return _buildResponse('Мен сизге курьер болуп катталууга, документтерге, экипировкага жана төлөмдөргө жардам бериши керек жеке куратормун. Сурооңузу жазыңыз же теманы тандаңыз:');
        case 'kz':
          return _buildResponse('Мен сізге курьер ретінде тіркелуге, құжаттарға, жабдықтарға және төлемдерге көмектесетін жеке кураторпын. Сұрағыңызды жазыңыз немесе тапсырмасын таңдаңыз:');
        default:
          return _buildResponse('Я твой личный куратор и готов ответить на любые вопросы по доставке, документам, экипировке и выплатам. Напиши свой вопрос или выбери тему на кнопках:');
      }
    }

      /// Запрос через защищенный шлюз Vercel Serverless (24/7)
      Future<CuratorResponse?> _queryCloudCurator(
        String prompt,
        List<Map<String, String>> history,
        String lang,
        String country,
      ) async {
        final endpoint = (_cloudEndpoint != null &&
                !_cloudEndpoint!.contains('localhost') &&
                !_cloudEndpoint!.contains('cloudfunctions.net'))
            ? _cloudEndpoint!
            : defaultVercelEndpoint;
        try {
          final response = await http.post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({
              'question': prompt,
              'history': history,
              'lang': lang,
              'country': country,
            }),
          ).timeout(const Duration(seconds: 15));

          if (response.statusCode == 200) {
            final data = jsonDecode(utf8.decode(response.bodyBytes));
            if (data['success'] == true && data['text'] != null) {
              return CuratorResponse(
                text: (data['text'] as String).trim(),
                showActionCard: data['showActionCard'] ?? false,
                actionType: data['actionType'] ?? 'register',
              );
            }
          }
        } catch (_) {
          // Gateway is offline or not deployed yet, smoothly fallback
        }
        return null;
      }

      bool _shouldShowActionCard(String userQuestion, String aiReply) {
        final q = userQuestion.toLowerCase().trim();
        final a = aiReply.toLowerCase().trim();

        // 1. Информационные вопросы и смолток — НИКОГДА не показывать карточку
        final nonActionPatterns = [
          RegExp(r'кто ты', caseSensitive: false),
          RegExp(r'ты кто', caseSensitive: false),
          RegExp(r'как звать', caseSensitive: false),
          RegExp(r'как зовут', caseSensitive: false),
          RegExp(r'как дела', caseSensitive: false),
          RegExp(r'\bпривет\b', caseSensitive: false),
          RegExp(r'\bсалют\b', caseSensitive: false),
          RegExp(r'\bхай\b', caseSensitive: false),
          RegExp(r'\bку\b', caseSensitive: false),
          RegExp(r'\bспасибо\b', caseSensitive: false),
          RegExp(r'\bпонял\b', caseSensitive: false),
          RegExp(r'\bясно\b', caseSensitive: false),
          RegExp(r'\bок\b', caseSensitive: false),
          RegExp(r'\bхорошо\b', caseSensitive: false),
          RegExp(r'рахмат', caseSensitive: false),
          RegExp(r'документ', caseSensitive: false),
          RegExp(r'паспорт', caseSensitive: false),
          RegExp(r'возраст', caseSensitive: false),
          RegExp(r'\bлет\b', caseSensitive: false),
          RegExp(r'штраф', caseSensitive: false),
          RegExp(r'налог', caseSensitive: false),
          RegExp(r'робот', caseSensitive: false),
        ];
        if (nonActionPatterns.any((p) => p.hasMatch(q))) {
          return false;
        }

        // 2. Прямое намерение регистрации или запрос ссылки
        final intentPatterns = [
          RegExp(r'хочу', caseSensitive: false),
          RegExp(r'давай', caseSensitive: false),
          RegExp(r'готов', caseSensitive: false),
          RegExp(r'начать', caseSensitive: false),
          RegExp(r'ссылк', caseSensitive: false),
          RegExp(r'анкет', caseSensitive: false),
          RegExp(r'куда нажать', caseSensitive: false),
          RegExp(r'как устроиться', caseSensitive: false),
          RegExp(r'оформить', caseSensitive: false),
          RegExp(r'зарегистр', caseSensitive: false),
          RegExp(r'ro\'yxat', caseSensitive: false),
          RegExp(r'каттал', caseSensitive: false),
          RegExp(r'тіркел', caseSensitive: false),
        ];
        if (intentPatterns.any((p) => p.hasMatch(q))) {
          return true;
        }

        // 3. Если ответ ассистента явно указывает нажать на кнопку регистрации
        if (a.contains('кнопк') && (a.contains('регистрац') || a.contains('анкет'))) {
          return true;
        }

        return false;
      }
    }
