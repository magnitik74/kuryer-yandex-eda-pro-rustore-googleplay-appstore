import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/locale_service.dart';

/// Единый контекст диалога для куратора — знает этап пользователя, страну, формат, профиль.
class CuratorContext {
  final String country;           // ru/kz/uz/kg/by
  final String format;            // auto/moto/bike/walk
  final String userName;
  final CuratorStage stage;       // Текущая стадия воронки
  final bool hasRegistered;       // LocaleService.hasRegisteredCabinet
  final int daysSinceReg;         // дней с момента регистрации (0 если только что)
  final bool moyNalogLinked;      // Привязан ли «Мой налог»
  final bool bagReceived;         // Получена ли сумка
  final String? currentCity;      // Текущий город (если известен)
  final String lang;              // ru/uz/kg/kz

  const CuratorContext({
    required this.country,
    required this.format,
    required this.userName,
    required this.stage,
    required this.hasRegistered,
    required this.daysSinceReg,
    required this.moyNalogLinked,
    required this.bagReceived,
    this.currentCity,
    required this.lang,
  });

  /// Фабричный конструктор из LocaleService (читает стадию из LocaleService.curatorStage)
  factory CuratorContext.fromLocale(LocaleService locale, {bool isFreshLead = false}) {
    CuratorStage stage;

    if (isFreshLead) {
      stage = CuratorStage.greeting;
    } else {
      // Use the synced stage from LocaleService (updated by self-reports)
      stage = locale.curatorStage;
    }

    // Приблизительный расчёт дней с регистрации
    int daysSinceReg = 0;
    if (locale.registrationSent) {
      // TODO: сохранять дату регистрации в prefs для точного расчёта
      daysSinceReg = 1; // placeholder
    }

    return CuratorContext(
      country: locale.workCountry,
      format: locale.courierType,
      userName: locale.userName.isNotEmpty ? locale.userName : 'друг',
      stage: stage,
      hasRegistered: locale.hasRegisteredCabinet,
      daysSinceReg: daysSinceReg,
      moyNalogLinked: locale.moyNalogLinked,
      bagReceived: locale.hasReceivedBag,
      currentCity: null, // TODO: из гео или профиля
      lang: locale.currentLang,
    );
  }

  /// Создаёт копию с изменённой стадией
  CuratorContext copyWith({CuratorStage? stage}) {
    return CuratorContext(
      country: country,
      format: format,
      userName: userName,
      stage: stage ?? this.stage,
      hasRegistered: hasRegistered,
      daysSinceReg: daysSinceReg,
      moyNalogLinked: moyNalogLinked,
      bagReceived: bagReceived,
      currentCity: currentCity,
      lang: lang,
    );
  }

  /// Возвращает проактивный вопрос для текущей стадии (если предусмотрен)
  String? getProactiveQuestion(LocaleService locale) {
    final cfg = locale;
    
    switch (stage) {
      case CuratorStage.greeting:
        return null; // Welcome сообщение уже содержит CTA
      
      case CuratorStage.preRegistration:
        return locale.tr('proactive_pre_registration'); // «Какой район тебе ближе для старта?»
      
      case CuratorStage.registrationSent:
        return locale.tr('proactive_registration_sent'); // «Нужна инструкция по «Мой налог» прямо сейчас?»
      
      case CuratorStage.postRegistration:
        final centers = cfg.courierCenters;
        if (centers.length >= 2) {
          final c1 = centers[0]['address'] as String? ?? '';
          final c2 = centers[1]['address'] as String? ?? '';
          return 'Какой ЦО тебе удобнее — $c1 или $c2?';
        } else if (centers.isNotEmpty) {
          final c1 = centers[0]['address'] as String? ?? '';
          return 'ЦО по адресу: $c1. Нужна навигация?';
        }
        return locale.tr('proactive_post_registration');
      
      case CuratorStage.activeCourier:
        return locale.tr('proactive_active_courier'); // «Как заказы вчера? Есть вопросы по тарифам?»
      
      case CuratorStage.churnedRisk:
        return locale.tr('proactive_churned_risk'); // «Что мешает выйти на линию? Могу помочь с документами/зоной.»
    }
  }
}

/// Стадии диалога (воронки) — соответствует архитектуре из CURATOR_AI_ARCHITECTURE.md
enum CuratorStage {
  greeting,           // только вошёл в чат (isFreshLead)
  preRegistration,    // отвечает на вопросы ДО регистрации
  registrationSent,   // анкета отправлена, ждёт звонка
  postRegistration,   // оператор перезвонил, идёт в ЦО / получил сумку
  activeCourier,      // на линии, делает заказы
  churnedRisk,        // 3+ дня нет активности
}

/// Ответ куратора с поддержкой проактивных вопросов
class CuratorResponse {
  final String text;
  final bool showActionCard;
  final String? actionType;
  final String? proactiveQuestion; // Проактивный вопрос в конце ответа

  const CuratorResponse({
    required this.text,
    this.showActionCard = false,
    this.actionType,
    this.proactiveQuestion,
  });

  /// Добавляет проактивный вопрос к тексту ответа
  CuratorResponse withProactiveQuestion(String question) {
    if (proactiveQuestion != null) return this; // уже есть
    return CuratorResponse(
      text: '$text\n\n$question',
      showActionCard: showActionCard,
      actionType: actionType,
      proactiveQuestion: question,
    );
  }
}

/// Движок диалога: классификация намерений → Local KB ответ → Vercel фоллбек
class CuratorDialogueEngine {
  final LocaleService _locale = LocaleService();

  /// Главная точка входа: принимает вопрос пользователя и контекст, возвращает ответ
  Future<CuratorResponse> ask(String userQuestion, CuratorContext ctx) async {
    final lower = userQuestion.toLowerCase().trim();
    final cfg = _locale; // доступ к countryConfig через LocaleService
    
    // Трекер темы вопроса для аналитики
    final topic = _classifyTopic(lower);
    if (topic != null) {
      await _locale.trackEvent('chat_question_asked', params: {
        'topic': topic,
        'country': ctx.country,
        'stage': ctx.stage.name,
      });
    }

    // 1. Local KB — упорядоченные проверки по приоритету
    CuratorResponse? localResponse;

    // Identity
    if (_matches(lower, ['кто ты', 'ты кто', 'как звать', 'как зовут', 'сен кімсің', 'кимсиң', 'kimsan', 'робот', 'бот', 'нейросеть', 'gigachat', 'сбер'])) {
      localResponse = _getWhoAreYouResponse(ctx.lang);
    }
    // VPN / ошибки входа
    else if (_matches(lower, ['ошибка', 'не входит', 'сбой', 'vpn', 'впн', 'кэш', 'завис', 'xato', 'иштебей', 'қате'])) {
      localResponse = _buildResponse(cfg.faq['vpn_error'] ?? '');
    }
    // Мой налог / самозанятость
    else if (_matches(lower, ['мой налог', 'самозанят', 'смз', 'налог', 'партнер', 'moy nalog', 'салык', 'e-salyq', 'солиқ', 'түндүк', 'пдн'])) {
      localResponse = _buildResponse(cfg.faq['moy_nalog'] ?? '');
      // Если стадия позволяет — добавляем проактивный вопрос про привязку
      if (ctx.stage == CuratorStage.registrationSent || ctx.stage == CuratorStage.postRegistration) {
        localResponse = localResponse.withProactiveQuestion(
          ctx.lang == 'ru' ? 'Нужна пошаговая инструкция по привязке «Мой налог»?' :
          ctx.lang == 'uz' ? '"Moy nalog" ni qanday ulash kerakligini ko\'rsataymi?' :
          ctx.lang == 'kg' ? 'Мой налог кайсылдаш кошулгону тууралунча көйгөй керекпи?' :
          'Қосымша нұсқаулық керек пе?',
        );
      }
    }
    // Документы / гражданство
    else if (_matches(lower, ['документ', 'паспорт', 'граждан', 'узбек', 'кыргыз', 'патент', 'таджик', 'еаэс', 'hujjat', 'документтер', 'құжат', 'пинфл', 'унп', 'виза', 'внж', 'рвп'])) {
      localResponse = _getDocsResponse(ctx);
      if (ctx.stage == CuratorStage.preRegistration) {
        localResponse = localResponse.withProactiveQuestion(ctx.getProactiveQuestion(_locale) ?? '');
      }
    }
    // Возраст
    else if (_matches(lower, ['лет', 'возраст', '16', '18', 'школьник', 'несовершеннолет', 'yosh', 'жаш'])) {
      localResponse = _buildResponse(cfg.faq['age'] ?? '');
    }
    // Сумка / экипировка
    else if (_matches(lower, ['сумк', 'короб', 'экипировк', 'форма', 'залог', 'платн', 'sumka', 'тегін', 'термо'])) {
      localResponse = _buildResponse(cfg.faq['bag'] ?? '');
      if (ctx.stage == CuratorStage.postRegistration && !ctx.bagReceived) {
        localResponse = localResponse.withProactiveQuestion(
          ctx.lang == 'ru' ? 'Узнать адрес и график твоего ЦО для получения сумки?' :
          ctx.lang == 'uz' ? 'Termo-sumka olish uchun Kuryerlik markaz manzili va grafigini aytaymi?' :
          ctx.lang == 'kg' ? 'Термокуту алуу үчүн Курьердик борбордун дареги жана графигин билгиңиз келеби?' :
          'Термокороб алу үшін ЦО мекенжайы мен кестесін білгіңіз келе ме?',
        );
      }
    }
    // Штрафы и опоздания
    else if (_matches(lower, ['штраф', 'опозда', 'наказан', 'вычет', 'jarima', 'айып'])) {
      localResponse = _buildResponse(cfg.faq['fines'] ?? '');
    }
    // Фотоконтроль
    else if (_matches(lower, ['фотоконтроль', 'фото', 'селфи', 'диагностика'])) {
      localResponse = _buildResponse(cfg.faq['photo_control'] ?? '');
    }
    // Видео обучение
    else if (_matches(lower, ['видео', 'обучен', 'не грузит', 'не работает', 'видео не'])) {
      localResponse = _buildResponse(cfg.faq['video_training'] ?? '');
    }
    // Доход / тарифы
    else if (_matches(lower, ['доход', 'зарплат', 'заработ', 'сколько платят', 'тариф', 'ставк', 'платит'])) {
      localResponse = _getIncomeResponse(ctx);
    }
    // Регистрация / готовность начать
    else if (_matches(lower, ['рег', 'хочу', 'давай', 'готов', 'начать', 'ссылк', 'анкет', 'устро', 'ro\'yxat', 'каттал', 'тіркел', 'заполнить', 'анкету'])) {
      localResponse = _getRegistrationPromptResponse(ctx.lang, showActionCard: true);
    }
    // Проактивный вопрос для стадии preRegistration (если вопрос не попал в FAQ)
    else if (ctx.stage == CuratorStage.preRegistration) {
      // Не нашли match — но стадия preReg, даём общий ответ + проактивный вопрос
      localResponse = _getDefaultResponse(ctx.lang).withProactiveQuestion(ctx.getProactiveQuestion(_locale) ?? '');
    }

    if (localResponse != null) {
      return localResponse;
    }

    // 2. No match → Vercel Gateway (GigaChat)
    final cloudResponse = await _queryCloudCurator(userQuestion, ctx);
    if (cloudResponse != null) {
      // Добавляем проактивный вопрос если стадия позволяет и его нет в ответе
      if (cloudResponse.proactiveQuestion == null) {
        final pq = ctx.getProactiveQuestion(_locale);
        if (pq != null) {
          return cloudResponse.withProactiveQuestion(pq);
        }
      }
      return cloudResponse;
    }

    // 3. Фоллбек: базовый дружелюбный ответ + проактивный вопрос по стадии
    final fallback = _getDefaultResponse(ctx.lang);
    final pq = ctx.getProactiveQuestion(_locale);
    if (pq != null) {
      return fallback.withProactiveQuestion(pq);
    }
    return fallback;
  }

  // --- Helpers ---

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
    return CuratorResponse(text: text, showActionCard: showActionCard, actionType: actionType);
  }

  // --- Local KB ответы ---

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

  CuratorResponse _getDocsResponse(CuratorContext ctx) {
    final cfg = _locale;
    if (ctx.country == 'ru') {
      final docs = cfg.documents;
      final allDocs = <String>[];
      docs.forEach((_, list) => allDocs.addAll(list));
      final unique = allDocs.toSet().toList().join('\n• ');
     
      switch (ctx.lang) {
        case 'uz':
          return _buildResponse('📄 **Rossiyada ishlash uchun MDH (O\'zbekiston) fuqarolariga kerakli hujjatlar:**\n\n• $unique\n\n💡 *Termo-sumka va forma Kuryerlik markazidan beriladi.*');
        case 'kg':
          return _buildResponse('📄 **Россияда иштөө үчүн Кыргызстан жарандарына (ЕАЭС):**\n\n• $unique\n\n⚡ **ПАТЕНТ КЕРЕК ЭМЕС!** ЕАЭС келишими боюнча Кыргызстан жарандары патентсиз иштей алат.\n\n💡 *Термокуту жана экипировка Курьердик борбордон берилет.*');
        default:
          return _buildResponse('📄 **Документы для оформления доставки в РФ:**\n\n• $unique\n\nТермокороб и экипировка выдаются в Курьерском центре или ПВЗ.');
      }
    } else {
      final docs = cfg.documents['all'] ?? [];
      final list = docs.join('\n• ');
      return _buildResponse('📄 **Для оформления в ${cfg.countryName} нужны:**\n\n• $list\n\n${cfg.operatorGreeting}');
    }
  }

  CuratorResponse _getIncomeResponse(CuratorContext ctx) {
    final cfg = _locale;
    final rates = cfg.rates;
    final currency = cfg.currency;
    final maxAuto = cfg.maxMonthlyIncome['auto'] ?? 0;
    final formatLabels = {'auto': 'Авто 🚗', 'moto': 'Мото 🛵', 'bike': 'Вело 🚲', 'walk': 'Пеший 🚶'};
   
    final lines = rates.entries.map((e) {
      final label = formatLabels[e.key] ?? e.key;
      return '$label: ${e.value} $currency/час';
    }).join('\n');
   
    switch (ctx.lang) {
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

  CuratorResponse _getRegistrationPromptResponse(String lang, {bool showActionCard = true}) {
    switch (lang) {
      case 'uz':
        return _buildResponse(
          '🚀 Ajoyib! Hamkorlik arizasini to\'ldirish uchun quyidagi "Anketani to\'ldirish" tugmasini bosing — bu faqat 2-3 daqiqa vaqt oladi. Keyin darhol kuryerlik markaziga borishingiz mumkin. Savollaringiz bo\'lsa, men shu yerdaman!',
          showActionCard: showActionCard,
          actionType: 'register',
        );
      case 'kg':
        return _buildResponse(
          '🚀 Абдан! Төмөнкү "Анкетасын толтуруу" баскычын басыңыз — бул 2-3 мүнөт алат. Андан кийинchstку курьердик борборго барууңуз мумкүн. Суроолор болсо, мен мындам!',
          showActionCard: showActionCard,
          actionType: 'register',
        );
      case 'kz':
        return _buildResponse(
          '🚀 Тамаша! Төмендегі "Анкетасын толтыру" батырмасын басыңыз — бұл тек 2-3 минутты алады. Соңында дарқы курьерлік орталыққа бара аласыз. Сұрақтар болса — мұндамын!',
          showActionCard: showActionCard,
          actionType: 'register',
        );
      default:
        return _buildResponse(
          '🚀 Отлично! Нажми кнопку «Заполнить Анкету» прямо под этим сообщением и заполни официальную анкету партнёра — это займёт всего 2-3 минуты. Сразу после этого сможешь получить экипировку и выйти на первые заказы. Если возникнут вопросы — пиши сюда, я на связи!',
          showActionCard: showActionCard,
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

  // --- Vercel Gateway (GigaChat на сервере) ---

  static const String defaultVercelEndpoint =
      'https://kuryer-yandex-eda-pro-rustore-googleplay-appstore-magnitik74.vercel.app/api/askCurator';

  String? _cloudEndpoint;

  Future<void> _ensureInitialized() async {
    if (_cloudEndpoint != null) return;
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
    } catch (_) {
      _cloudEndpoint = defaultVercelEndpoint;
    }
  }

  Future<CuratorResponse?> _queryCloudCurator(String prompt, CuratorContext ctx) async {
    await _ensureInitialized();
    final endpoint = (_cloudEndpoint != null &&
            !_cloudEndpoint!.contains('localhost') &&
            !_cloudEndpoint!.contains('cloudfunctions.net'))
        ? _cloudEndpoint!
        : defaultVercelEndpoint;

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer ${const String.fromEnvironment("VERCEL_API_KEY")}',
        },
        body: jsonEncode({
          'question': prompt,
          'history': [], // История передается отдельно если нужно
          'lang': ctx.lang,
          'country': ctx.country,
          'stage': ctx.stage.name,
          'format': ctx.format,
          // 'userName': ctx.userName, // Убрали PII для безопасности
          'hasRegistered': ctx.hasRegistered,
          'daysSinceReg': ctx.daysSinceReg,
          'moyNalogLinked': ctx.moyNalogLinked,
          'bagReceived': ctx.bagReceived,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['text'] != null) {
          return CuratorResponse(
            text: (data['text'] as String).trim(),
            showActionCard: data['showActionCard'] ?? false,
            actionType: data['actionType'] ?? 'register',
            proactiveQuestion: data['proactiveQuestion'], // сервер может вернуть свой
          );
        }
      }
    } catch (_) {
      // Gateway offline — fallback to local
    }
    return null;
  }
}