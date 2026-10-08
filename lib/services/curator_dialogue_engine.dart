import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'country_config_service.dart';
import 'locale_service.dart';

/// Стадии воронки куратора
enum CuratorStage {
  fresh(0),           // Только вошёл / онбординг
  formSubmitted(1),   // Анкета отправлена, ожидает звонка/проверки
  taxLinked(2),       // «Мой налог» привязан к сервису
  gearReceived(3),    // Термосумка получена в ЦД или ПВЗ
  firstShiftReady(4), // Готов к первой смене, проверка чек-листа
  completedBonus(5);  // Выполнил первые заказы, забрал бонус

  final int value;
  const CuratorStage(this.value);

  static CuratorStage fromInt(int val) {
    return CuratorStage.values.firstWhere(
      (s) => s.value == val,
      orElse: () => CuratorStage.formSubmitted,
    );
  }
}

/// Контекст соискателя для куратора (обогащение запроса без PII)
class CuratorContext {
  final String country;
  final String format;
  final String userName;
  final CuratorStage stage;
  final bool hasRegistered;
  final int daysSinceReg;
  final bool moyNalogLinked;
  final bool bagReceived;
  final String? currentCity;
  final String lang;

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

  factory CuratorContext.fromLocale(LocaleService locale) {
    return CuratorContext(
      country: locale.workCountry,
      format: locale.courierType,
      userName: locale.userName.isNotEmpty ? locale.userName : 'друг',
      stage: CuratorStage.fromInt(locale.curatorStage),
      hasRegistered: locale.hasRegisteredCabinet,
      daysSinceReg: 1,
      moyNalogLinked: locale.curatorStage >= 2,
      bagReceived: locale.curatorStage >= 3,
      currentCity: null,
      lang: locale.currentLang,
    );
  }

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
}

/// Ответ куратора
class CuratorResponse {
  final String text;
  final bool showActionCard;
  final String? actionType;
  final String? proactiveQuestion;

  const CuratorResponse({
    required this.text,
    this.showActionCard = false,
    this.actionType,
    this.proactiveQuestion,
  });

  CuratorResponse withProactiveQuestion(String question) {
    return CuratorResponse(
      text: '$text\n\n$question',
      showActionCard: showActionCard,
      actionType: actionType,
      proactiveQuestion: question,
    );
  }
}

/// Двухуровневый диалоговый движок:
/// 1. Локальная база знаний (0.01 сек, 100% надёжность, офлайн)
/// 2. Серверный Vercel Serverless Gateway (24/7 GigaChat)
class CuratorDialogueEngine {
  static final CuratorDialogueEngine _instance = CuratorDialogueEngine._internal();
  factory CuratorDialogueEngine() => _instance;
  CuratorDialogueEngine._internal();

  final CountryConfigService _countryConfig = CountryConfigService();

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
      }
    } catch (_) {
      _cloudEndpoint = defaultVercelEndpoint;
    }
  }

  /// Главная точка входа: первым делом опрашиваем умный ИИ с контекстом диалога
  Future<CuratorResponse> processQuery(String userQuery, CuratorContext ctx) async {
    // 1. Опрашиваем облачный умный ИИ-шлюз (GigaChat с пониманием контекста диалога)
    final cloudResponse = await _queryCloudCurator(userQuery, ctx);
    if (cloudResponse != null) return cloudResponse;

    // 2. Если сети нет (офлайн/таймаут) — проверяем локальную базу знаний
    final lower = userQuery.toLowerCase().trim();
    final localMatch = _matchLocalKnowledgeBase(lower, ctx);
    if (localMatch != null) return localMatch;

    // 3. Аварийный fallback ответ по умолчанию
    return _getDefaultResponse(ctx);
  }

  CuratorResponse? _matchLocalKnowledgeBase(String lower, CuratorContext ctx) {
    final lang = ctx.lang;
    final country = ctx.country;

    // Если кандидат УЖЕ заполнил анкету и спрашивает что дальше
    if (_matches(lower, ['заполнил', 'отправил', 'что дальше', 'дальше то что', 'сдал анкету'])) {
      return CuratorResponse(
        text: 'Супер, что анкета уже заполнена! 🎉\n\n'
            'Следующий шаг — дождаться звонка оператора или СМС (обычно в течение 10–15 минут), чтобы подтвердить данные.\n\n'
            'После подтверждения ты сможешь забрать фирменный термокороб и форму без залога в ближайшем Курьерском центре (ЦД) или ПВЗ и выйти на первый слот!\n\n'
            '${country == 'ru' ? 'Не забудь привязать партнёрство в приложении «Мой налог» для ежедневных выплат на карту.' : ''}',
        showActionCard: false,
      );
    }

    // Процесс / как устроиться / с чего начать
    if (_matches(lower, ['процесс', 'как происходит', 'как устроиться', 'с чего начать', 'этапы', 'порядок'])) {
      return _getProcessWalkthroughResponse(lang);
    }

    // Автокурьер / есть авто
    if (_matches(lower, ['свое авто', 'своя машина', 'на машине', 'на авто'])) {
      return _getAutoFormatResponse(lang);
    }

    // Велокурьер / есть транспорт / свой
    if (lower == 'есть' || lower == 'свой' || lower == 'мой' || lower == 'да' || lower.contains('свой велик') || lower.contains('свой велосипед')) {
      return _getBikeFormatResponse(lang);
    }

    // Пеший курьер / самокат
    if (_matches(lower, ['пешком', 'пеший', 'на самокате', 'ходить'])) {
      return _getWalkFormatResponse(lang);
    }

    // Мотокурьер / скутер
    if (_matches(lower, ['на скутере', 'на мопеде', 'на мото'])) {
      return _getMotoFormatResponse(lang);
    }

    // Аренда транспорта
    if (_matches(lower, ['нужна аренда', 'прокат', 'нет велика', 'нет машины'])) {
      return _getRentalResponse(lang);
    }

    // Кто ты / помощник
    if (_matches(lower, ['кто ты', 'ты кто', 'как зовут', 'сен кімсің', 'кимсиң', 'kimsan', 'помощник', 'робот'])) {
      return _getWhoAreYouResponse(lang);
    }

    // Решение ошибок / VPN
    if (_matches(lower, ['ошибка', 'не входит', 'сбой', 'vpn', 'впн', 'кэш', 'завис', 'xato', 'иштебей', 'қате'])) {
      return _getErrorResponse(lang);
    }

    // Связка с Мой налог / Звонок оператора
    if (_matches(lower, ['мой налог', 'самозанят', 'смз', 'налог', 'партнер', 'moy nalog', 'салык', 'звонок', 'оператор'])) {
      return _getMoyNalogResponse(lang, country);
    }

    // Центр Доставки / термокороб / экипировка
    if (_matches(lower, ['цд', 'центр доставки', 'курьерский центр', 'где забрать', 'сумк', 'короб', 'термокороб', 'экипировк', 'форма'])) {
      return _getBagAndCenterResponse(lang, country);
    }

    // Чек-лист перед первой сменой / первый заказ
    if (_matches(lower, ['первый заказ', 'первая смена', 'как проходит заказ', 'чек-лист', 'чеклист', '1-й заказ', '1 заказ'])) {
      return _getFirstOrderWalkthroughResponse(lang);
    }

    // Документы и гражданство
    if (_matches(lower, ['документ', 'граждан', 'узбек', 'кыргыз', 'патент', 'таджик', 'еаэс', 'hujjat', 'документтер', 'құжат'])) {
      return _getDocsResponse(lang, country);
    }

    // Доход / ставки / заработок
    if (_matches(lower, ['сколько платят', 'доход', 'ставка', 'деньги', 'зарплат', 'выплат'])) {
      return _getIncomeResponse(ctx);
    }

    // Возраст
    if (_matches(lower, ['лет', 'возраст', '16', '18', 'школьник'])) {
      return _getAgeResponse(lang);
    }

    // Штрафы
    if (_matches(lower, ['штраф', 'опозда', 'наказан', 'вычет'])) {
      return _getFinesResponse(lang);
    }

    // Явный запрос на ссылку регистрации
    if (lower == 'хочу' || lower == 'давай' || lower == 'готов' || lower == 'анкета' || lower == 'дай ссылку' || lower == 'скинь анкету') {
      return _getRegistrationPromptResponse(lang);
    }

    return null;
  }

  bool _matches(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  // --- Формирование локальных ответов ---

  CuratorResponse _getWhoAreYouResponse(String lang) {
    switch (lang) {
      case 'uz':
        return const CuratorResponse(
          text: 'Men yetkazib berish xizmatidagi shaxsiy kuratoringizman. Kuryer bo‘lib ishga kirish, erkin grafik, hujjatlar va bepul uskunalar olishda 24/7 yordam beraman!',
        );
      case 'kg':
        return const CuratorResponse(
          text: 'Мен жеткирүү кызматындагы жеке кураторуңузмун. Курьер болуп орношуу, киреше, график жана керектүү нерселерди алууда 24/7 жардам берем!',
        );
      case 'kz':
        return const CuratorResponse(
          text: 'Мен жеткізу қызметіндегі жеке кураторыңызбын. Курьер болып орналасу, табыс, икемді график және қажетті жабдықтарды алуда 24/7 көмектесемін!',
        );
      default:
        return const CuratorResponse(
          text: 'Я твой персональный куратор и помощник в доставке! 🚴‍♂️\n\nПомогу быстро оформиться, подключить самозанятость за 1 минуту, забрать термокороб в ЦД без залога и выйти на первый доход. Я на связи 24/7!',
        );
    }
  }

  CuratorResponse _getErrorResponse(String lang) {
    switch (lang) {
      case 'uz':
        return const CuratorResponse(
          text: '🛠️ **Ro‘yxatdan o‘tishdagi xatolikni tuzatish:**\n\n'
              '1. 🔴 **VPN ni o‘chiring!** (90% hollarda xatolik aynan VPN tufayli bo‘ladi).\n'
              '2. Ilova keshini tozalang va telefonni qayta yoqing.\n'
              '3. Internet aloqasini tekshiring.\n'
              '4. Agar avval boshqa raqam bilan ishlagan bo‘lsangiz — ilovadagi "Yordam" orqali yozing.',
        );
      default:
        return const CuratorResponse(
          text: '🛠️ **Решение ошибки при входе / регистрации:**\n\n'
              '1. 🔴 **Выключите VPN!** (В 90% случаев сбой сети и авторизации происходит из-за активного VPN).\n'
              '2. Очистите кэш приложения и перезагрузите телефон.\n'
              '3. Проверьте стабильность мобильного интернета.\n'
              '4. ⚠️ **Важно:** если ранее выполняли доставки с другого номера — обязательно сообщите поддержке, чтобы не было дубля аккаунта.',
        );
    }
  }

  CuratorResponse _getMoyNalogResponse(String lang, String country) {
    if (country != 'ru') {
      switch (lang) {
        case 'uz':
          return const CuratorResponse(
            text: '📞 **Operator qo‘ng‘irog‘i va arizani tasdiqlash:**\n\n'
                '1. Arizani yuborganingizdan so‘ng aloqa markazi operatori bir necha soat ichida qo‘ng‘iroq qiladi.\n'
                '2. Operator ismingiz va shahringizni tekshiradi, savollarga javob beradi.\n'
                '3. Shundan so‘ng termosumka va formani olish uchun kuryerlik markaziga borishingiz mumkin bo‘ladi!\n\n'
                '✅ O‘zbekistonda Rossiyaning «Мой налог» ilovasiga ulanish talab etilmaydi.',
          );
        case 'kg':
          return const CuratorResponse(
            text: '📞 **Оператордун чалуусу жана ырастоо:**\n\n'
                '1. Анкета жөнөтүлгөндөн кийин байланыш борборунун оператору бир нече саат ичинде чалат.\n'
                '2. Оператор маалыматтарды текшерип, курьердик борбордун дарегин айтат.\n\n'
                '✅ Кыргызстанда «Мой налог» тиркемесине кошуу талап кылынбайт, баары оператор аркылуу ишке ашат.',
          );
        case 'kz':
          return const CuratorResponse(
            text: '📞 **Оператор қоңырауы және растау:**\n\n'
                '1. Сауалнама жібергеннен кейін байланыс орталығының операторы бірнеше сағат ішінде хабарласады.\n'
                '2. Оператор деректерді тексеріп, термосумка алу үшін мекенжайды айтады.\n\n'
                '✅ Қазақстанда «Мой налог» қосымшасына қосылу қажет емес.',
          );
        default:
          return const CuratorResponse(
            text: '📞 **Звонок оператора и оформление:**\n\n'
                '1. В вашей стране статус подтверждается через звонок оператора контакт-центра.\n'
                '2. Оператор свяжется в течение нескольких часов после отправки анкеты и проверит данные.\n'
                '3. Затем вам назовут точный адрес для получения термосумки и формы без залога.\n\n'
                '✅ Российское приложение «Мой налог» подключать не нужно — активация проходит напрямую через оператора.',
          );
      }
    }

    switch (lang) {
      case 'uz':
        return const CuratorResponse(
          text: '📲 **«Mening solig‘im» (Мой налог) ni 1 daqiqada ulash:**\n\n'
              '1. «Мой налог» ilovasini oching → «Прочее» (Boshqa)\n'
              '2. «Партнёры» (Hamkorlar) bo‘limiga kiring\n'
              '3. Yetkazib berish xizmatini (Яндекс Еда) toping va «Разрешить» ni bosing\n'
              '4. Holat tasdiqlandi! To‘lovlar to‘g‘ridan-to‘g‘ri kartangizga tushadi.',
        );
      default:
        return const CuratorResponse(
          text: '📲 **Шпаргалка: связка с «Мой налог» за 1 минуту:**\n\n'
              '1. Открой приложение «Мой налог» (номер должен совпадать с анкетой).\n'
              '2. В правом нижнем углу нажми «Прочее» (три точки).\n'
              '3. Раздел «Партнёры» → найди сервис Яндекс Еда.\n'
              '4. Нажми «Разрешить».\n\n'
              '✅ Готово! Статус подтвердится автоматически, и ежедневные выплаты будут приходить на твою карту.',
        );
    }
  }

  CuratorResponse _getBagAndCenterResponse(String lang, String country) {
    final centers = _countryConfig.courierCenters(country);
    String centersText = '';
    if (centers.isNotEmpty) {
      final list = centers.take(4).map((c) => '• ${c['city']}: ${c['address']}').join('\n');
      centersText = '\n\n📍 **Курьерские центры (ЦД):**\n$list';
    }

    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: '🎒 **Termosumka va kiyim-kechak:**\n\n'
              '• Bepul va garovsiz (залог йўқ) beriladi.\n'
              '• Kuryerlik markazida yoki eng yaqin topshirish punktida (ПВЗ) olinadi.\n'
              '• O‘zingiz bilan pasport va telefon bo‘lishi kifoya.$centersText',
        );
      default:
        return CuratorResponse(
          text: '🎒 **Экипировка и термокороб:**\n\n'
              '• **0 ₽, без залога!** За термокороб и яркую форму платить не нужно.\n'
              '• В крупных городах выдача проходит в Курьерском центре (ЦД).\n'
              '• В других городах — в ближайшем ПВЗ Яндекс Маркета после онлайн-фотоконтроля.\n'
              '• С собой нужны только паспорт и телефон.$centersText',
        );
    }
  }

  CuratorResponse _getFirstOrderWalkthroughResponse(String lang) {
    return const CuratorResponse(
      text: '🚴‍♂️ **Как проходит твой 1-й заказ (шаг за шагом):**\n\n'
          '1. **Включил линию** в приложении Яндекс Про в своём районе.\n'
          '2. **Принял заказ** — на карте появится маршрут до ресторана.\n'
          '3. **Прибыл в ресторан** — назови сотруднику номер заказа (на экране), проверь состав и положи в термокороб.\n'
          '4. **Доехал до клиента** — позвони в домофон, передай заказ и нажми «Доставлено».\n\n'
          '✨ Оплата за заказ и чаевые сразу зачислятся на баланс!',
    );
  }

  CuratorResponse _getDocsResponse(String lang, String country) {
    final docs = _countryConfig.documents(country);
    final rfList = docs['rf_citizens']?.join('\n• ') ?? 'Паспорт с регистрацией, ИНН';
    final eaeuList = docs['eaeu_citizens']?.join('\n• ') ?? 'Паспорт, миграционная карта, ИНН';

    return CuratorResponse(
      text: '📄 **Документы для оформления доставки:**\n\n'
          '**Граждане РФ:**\n• $rfList\n\n'
          '**Граждане ЕАЭС (Беларусь, Казахстан, Кыргызстан, Армения):**\n• $eaeuList\n\n'
          'Оформление занимает от 2 минут онлайн.',
    );
  }

  CuratorResponse _getIncomeResponse(CuratorContext ctx) {
    final currency = _countryConfig.currency(ctx.country);
    final rates = _countryConfig.rates(ctx.country);

    final auto = rates['auto'] ?? 694;
    final moto = rates['moto'] ?? 520;
    final bike = rates['bike'] ?? 420;
    final walk = rates['walk'] ?? 330;

    return CuratorResponse(
      text: '💰 **Примерные ставки ($currency/час):**\n\n'
          '• Авто 🚗: от $auto $currency/час\n'
          '• Мото 🛵: от $moto $currency/час\n'
          '• Вело 🚲: от $bike $currency/час\n'
          '• Пеший 🚶: от $walk $currency/час\n\n'
          'Выплаты ежедневные на карту, 100% чаевых остаются курьеру. Подробный расчёт доступен во вкладке «Доход».',
    );
  }

  CuratorResponse _getAgeResponse(String lang) {
    return const CuratorResponse(
      text: '🎂 **Возраст курьера:**\n\n'
          '• В большинстве городов РФ и СНГ: с 18 лет.\n'
          '• В Москве, Санкт-Петербурге и Казани: можно с 16 лет (с письменным согласием родителей).\n'
          '• Студентам доставка отлично подходит как подработка со свободным графиком от 2 часов в день!',
    );
  }

  CuratorResponse _getFinesResponse(String lang) {
    return const CuratorResponse(
      text: '⚡ **Штрафы и страхование:**\n\n'
          '• За разовые опоздания из-за непогоды или пробок штрафов нет — система автоматически учитывает дорожную ситуацию.\n'
          '• На время всех доставок действует бесплатная страховка жизни и здоровья партнёра.',
    );
  }

  CuratorResponse _getRegistrationPromptResponse(String lang) {
    switch (lang) {
      case 'uz':
        return const CuratorResponse(
          text: '🚀 Ajoyib! Xabar ostidagi «Anketa» tugmasini bosing va rasmiy hamkor anketasini to‘ldiring — bu 2-3 daqiqa oladi. Shundan so‘ng darhol uskunalar olib, smenaga chiqishingiz mumkin!',
          showActionCard: true,
          actionType: 'register',
        );
      case 'kg':
        return const CuratorResponse(
          text: '🚀 Абдан жакшы! Билдирүүнүн алдындагы «Анкета» баскычын басып, расмий шериктеш анкетасын толтуруңуз — бул 2-3 мүнөт алат. Андан кийин дароо экипировка алып, сменге чыга аласыз!',
          showActionCard: true,
          actionType: 'register',
        );
      case 'kz':
        return const CuratorResponse(
          text: '🚀 Керемет! Хабарламаның астындағы «Анкета» батырмасын басып, серіктестің ресми сауалнамасын толтырыңыз — бұл 2-3 минут уақыт алады. Одан кейін бірден жабдықтарды алып, ауысымға шыға аласыз!',
          showActionCard: true,
          actionType: 'register',
        );
      default:
        return const CuratorResponse(
          text: '🚀 Отлично! Нажми кнопку «Анкета» прямо под этим сообщением и заполни официальную анкету партнёра — это займёт 2-3 минуты. Сразу после этого сможешь получить экипировку и выйти на слот!',
          showActionCard: true,
          actionType: 'register',
        );
    }
  }

  CuratorResponse _getProcessWalkthroughResponse(String lang) {
    return const CuratorResponse(
      text: '🚀 **Процесс оформления курьером — всего 3 простых шага:**\n\n'
          '1. **Онлайн-анкета (2-3 минуты)** — нажми кнопку «Заполнить анкету» ниже, выбери город и введи телефон.\n'
          '2. **Экипировка** — в Курьерском центре (ЦД) или ПВЗ получаешь термокороб и форму без залога.\n'
          '3. **Выход на линию** — скачиваешь приложение Яндекс Про, включаешь линию в своём районе и забираешь первый доход уже сегодня!\n\n'
          'Начнём прямо сейчас? Жми кнопку ниже и заполняй анкету!',
      showActionCard: true,
      actionType: 'register',
    );
  }

  CuratorResponse _getAutoFormatResponse(String lang) {
    return const CuratorResponse(
      text: 'Пушка! 🚗 На авто курьеры зарабатывают максимум — **до 250 000 ₽/мес** благодаря повышенным тарифам и доставке крупных заказов.\n\n'
          'Давай прямо сейчас оформим официальную анкету партнёра (2-3 минуты), чтобы закрепить за тобой город и повышенную ставку. Термокороб получишь без залога в курьерском центре или ПВЗ!\n\n'
          'Жми кнопку «Заполнить анкету» прямо под этим сообщением 🚀',
      showActionCard: true,
      actionType: 'register',
    );
  }

  CuratorResponse _getBikeFormatResponse(String lang) {
    return const CuratorResponse(
      text: 'Огонь! Со своим транспортом ты зарабатываешь максимум (до +30%) без лишних расходов на прокат. 🚴‍♂️💨\n\n'
          'Давай прямо сейчас оформим официальную анкету партнёра (это займёт всего 2 минуты), а я пока забронирую за тобой термокороб и экипировку в твоём городе!\n\n'
          'Жми кнопку «Заполнить анкету» прямо под этим сообщением 🚀',
      showActionCard: true,
      actionType: 'register',
    );
  }

  CuratorResponse _getWalkFormatResponse(String lang) {
    return const CuratorResponse(
      text: 'Отличный выбор! 🚶‍♂️ Пеший формат — самый простой и быстрый старт: никаких прав, залогов и трат на бензин. Заказы распределяются рядом с домом или метро (до 1.5–2 км).\n\n'
          'Давай оформим официальную анкету партнёра за 2 минуты — и ты сможешь забрать экипировку и выйти на первый слот уже сегодня!\n\n'
          'Жми кнопку «Заполнить анкету» ниже 🚀',
      showActionCard: true,
      actionType: 'register',
    );
  }

  CuratorResponse _getMotoFormatResponse(String lang) {
    return const CuratorResponse(
      text: 'Супер! 🛵 На скутере или мопеде скорость доставки максимальная, а пробки не страшны. Доход почти как у авто, а расходы минимальные!\n\n'
          'Давай оформим базовую анкету партнёра (2 минуты) — и ты сразу сможешь забрать экипировку и выйти на линию!\n\n'
          'Жми кнопку «Заполнить анкету» прямо под этим сообщением 🚀',
      showActionCard: true,
      actionType: 'register',
    );
  }

  CuratorResponse _getRentalResponse(String lang) {
    return const CuratorResponse(
      text: 'Отлично! У партнёров сервиса действует спецтариф на аренду электровелосипедов и авто со скидкой до 50% и бесплатным техобслуживанием. ⚡\n\n'
          'Скидка на аренду активируется сразу в твоём профиле курьера после заполнения базовой анкеты партнёра. Давай оформим её прямо сейчас (2-3 минуты)?\n\n'
          'Жми кнопку «Заполнить анкету» ниже 🚀',
      showActionCard: true,
      actionType: 'register',
    );
  }

  CuratorResponse _getDefaultResponse(CuratorContext ctx) {
    return const CuratorResponse(
      text: 'Я на связи 24/7! 🚀 Давай прямо сейчас оформим официальную анкету партнёра (2-3 минуты), чтобы закрепить за тобой город, повышенный тариф и термокороб. А любые вопросы по заказам и графику разберём по ходу оформления!\n\n'
          'Жми кнопку «Заполнить анкету» ниже:',
      showActionCard: true,
      actionType: 'register',
    );
  }

  // --- Vercel Serverless Gateway ---

  Future<CuratorResponse?> _queryCloudCurator(String prompt, CuratorContext ctx) async {
    await _ensureInitialized();
    final endpoint = _cloudEndpoint ?? defaultVercelEndpoint;

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'question': prompt,
          'lang': ctx.lang,
          'country': ctx.country,
          'stage': ctx.stage.name,
          'format': ctx.format,
          'hasRegistered': ctx.hasRegistered,
          'daysSinceReg': ctx.daysSinceReg,
          'moyNalogLinked': ctx.moyNalogLinked,
          'bagReceived': ctx.bagReceived,
        }),
      ).timeout(const Duration(seconds: 18));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data['success'] == true && data['text'] != null) {
          return CuratorResponse(
            text: (data['text'] as String).trim(),
            showActionCard: data['showActionCard'] ?? true,
            actionType: data['actionType'] ?? 'register',
            proactiveQuestion: data['proactiveQuestion'],
          );
        }
      }
    } catch (_) {
      // Gateway offline or timeout — gracefully return null to use fallback
    }
    return null;
  }
}
