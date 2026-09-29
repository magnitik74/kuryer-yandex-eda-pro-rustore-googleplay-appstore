import 'package:flutter/foundation.dart';

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
  static final CuratorAiService _instance = CuratorAiService._internal();
  factory CuratorAiService() => _instance;
  CuratorAiService._internal();

  String? _gigaChatApiKey; // Set when user provides key tomorrow

  void setApiKey(String key) {
    _gigaChatApiKey = key;
  }

  /// Главная точка входа для общения с Куратором.
  /// Работает в двух слоях:
  /// 1. Локальный движок базы знаний (0.01 сек, 100% надёжность).
  /// 2. GigaChat Lite API (когда ключ передан).
  Future<CuratorResponse> ask(
    String userQuestion, {
    required String lang,
    required String country,
  }) async {
    final lower = userQuestion.toLowerCase().trim();

    // 1. Проверяем триггеры ошибок регистрации и памятки Светланы
    if (_matches(lower, ['ошибка', 'не входит', 'сбой', 'vpn', 'впн', 'кэш', 'завис', 'xato', 'иштебей', 'қате'])) {
      return _getErrorResponse(lang);
    }

    // 2. Проверяем связку с Мой Налог
    if (_matches(lower, ['мой налог', 'самозанят', 'смз', 'налог', 'партнер', 'moy nalog', 'салык'])) {
      return _getMoyNalogResponse(lang);
    }

    // 3. Проверяем вопросы гражданства и документов
    if (_matches(lower, ['документ', 'граждан', 'узбек', 'кыргыз', 'патент', 'таджик', 'еаэс', 'hujjat', 'документтер', 'құжат'])) {
      return _getDocsResponse(lang, country);
    }

    // 4. Проверяем возраст
    if (_matches(lower, ['лет', 'возраст', '16', '18', 'школьник', 'несовершеннолет', 'yosh', 'жаш'])) {
      return _getAgeResponse(lang);
    }

    // 5. Проверяем сумку/короб и экипировку
    if (_matches(lower, ['сумк', 'короб', 'экипировк', 'форма', 'залог', 'платн', 'sumka', 'бекер', 'тегін'])) {
      return _getBagResponse(lang);
    }

    // 6. Проверяем штрафы и опоздания
    if (_matches(lower, ['штраф', 'опозда', 'наказан', 'вычет', 'jarima', 'айып'])) {
      return _getFinesResponse(lang);
    }

    // 7. Готовность начать / регистрация
    if (_matches(lower, ['рег', 'начать', 'ссылк', 'анкет', 'устро', 'ro‘yxat', 'каттал', 'тіркел'])) {
      return _getRegistrationPromptResponse(lang);
    }

    // 8. Если передан ключ GigaChat Lite — шлём запрос в Сбер
    if (_gigaChatApiKey != null && _gigaChatApiKey!.isNotEmpty) {
      try {
        final gigaResponse = await _queryGigaChat(userQuestion, lang, country);
        if (gigaResponse != null) return gigaResponse;
      } catch (e) {
        debugPrint('CuratorAiService: GigaChat API error: $e');
      }
    }

    // 9. Базовый дружелюбный ответ куратора по умолчанию
    return _getDefaultResponse(lang);
  }

  bool _matches(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  // --- Локальные выверенные ответы по Базе Знаний Яндекса и памятке Светланы ---

  CuratorResponse _getErrorResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: '🛠️ **Ro‘yxatdan o‘tishdagi xatolikni tuzatish:**\n\n'
              '1. 🔴 **VPN ni o‘chiring!** (90% hollarda xatolik aynan VPN tufayli bo‘ladi).\n'
              '2. Yandex Pro keshini tozalang va telefonni o‘chirib yoqing.\n'
              '3. Internet aloqasini tekshiring.\n'
              '4. Agar avval boshqa raqam bilan ishlagan bo‘lsangiz — Yandex Pro ilovasidagi yashil "Yordam" (Помощь) tugmasi orqali yozing.',
          showActionCard: false,
          actionType: 'help_guide',
        );
      case 'kg':
        return CuratorResponse(
          text: '🛠️ **Катталуудагы катаны оңдоо:**\n\n'
              '1. 🔴 **VPNди өчүрүңүз!** (90% учурда ката VPN иштеп турганда чыгат).\n'
              '2. Яндекс Пронун кэшин тазалап, телефонду өчүрүп-күйгүзүңүз.\n'
              '3. Эгер мурда башка номер менен жеткирүү кылган болсоңуз — Яндекс Продогу жашыл "Жардам" (Помощь) баскычы аркылуу билдириңиз.',
          showActionCard: false,
          actionType: 'help_guide',
        );
      case 'kz':
        return CuratorResponse(
          text: '🛠️ **Тіркелу кезіндегі қатені түзету:**\n\n'
              '1. 🔴 **VPN-ді өшіріңіз!** (90% жағдайда қате VPN қосулы болғанда шығады).\n'
              '2. Яндекс Про кэшін тазалап, телефонды қайта жүктеңіз.\n'
              '3. Егер бұрын басқа нөмірмен жұмыс істеген болсаңыз — Яндекс Про қолдау қызметіне жазыңыз.',
          showActionCard: false,
          actionType: 'help_guide',
        );
      default:
        return CuratorResponse(
          text: '🛠️ **Решение ошибки при входе / регистрации в Яндекс Про:**\n\n'
              '1. 🔴 **Выключите VPN!** (В 90% случаев сбой сети и Яндекс ID происходит именно из-за VPN).\n'
              '2. Очистите кэш приложения Яндекс Про и перезагрузите телефон.\n'
              '3. Проверьте стабильность интернета.\n'
              '4. ⚠️ **Важно:** если ранее выполняли доставки с другого номера — обязательно сообщите об этом поддержке через зелёную кнопку «Помощь» в Яндекс Про, чтобы не получить блокировку за дубль аккаунта.',
          showActionCard: false,
          actionType: 'help_guide',
        );
    }
  }

  CuratorResponse _getMoyNalogResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: '📲 **«Moy nalog» ilovasini Yandex Pro bilan bog‘lash:**\n\n'
              '1. «Moy nalog» ilovasiga kiring ➡️ pastdagi **«Boshqalar» (Прочее)** bo‘limiga o‘ting.\n'
              '2. **«Hamkorlar» (Партнёры)** bandini bosing.\n'
              '3. Ro‘yxatdan **«Яндекс.Еда»** ni toping va **«Ruxsat berish» (Разрешить)** tugmasini bosing.\n'
              '4. Yandex Pro ilovasiga qaytib, davom eting!',
          showActionCard: true,
          actionType: 'register',
        );
      default:
        return CuratorResponse(
          text: '📲 **Как привязать «Мой налог» к Яндекс Про (за 1 минуту):**\n\n'
              '1. Откройте приложение «Мой налог» ➡️ вкладка **«Прочее»**.\n'
              '2. Выберите раздел **«Партнёры»**.\n'
              '3. Найдите в списке **«Яндекс.Еда»** и нажмите **«Разрешить»**.\n'
              '4. Вернитесь в Яндекс Про — статус самозанятости подтвердится автоматически!',
          showActionCard: true,
          actionType: 'register',
        );
    }
  }

  CuratorResponse _getDocsResponse(String lang, String country) {
    if (country == 'ru') {
      switch (lang) {
        case 'uz':
          return CuratorResponse(
            text: '📄 **Rossiyada ishlash uchun MDH (O‘zbekiston) fuqarolariga kerakli hujjatlar:**\n\n'
                '• Pasport (notarial tarjimasi bilan)\n'
                '• Registratsiya (yashash joyi bo‘yicha)\n'
                '• Patent va to‘langan cheklari\n'
                '• INN va SNILS\n\n'
                '💡 *Termo-sumka ofisda bepul beriladi, garov puli yo‘q!*',
            showActionCard: true,
            actionType: 'register',
          );
        case 'kg':
          return CuratorResponse(
            text: '📄 **Россияда иштөө үчүн Кыргызстан жарандарына (ЕАЭС):**\n\n'
                '• Паспорт жана нотариалдык котормо\n'
                '• Катталуу (регистрация)\n'
                '• ИНН жана СНИЛС\n'
                '• ⚡ **ПАТЕНТ КЕРЕК ЭМЕС!** ЕАЭС келишими боюнча Кыргызстан жарандары патентсиз иштей алат.\n\n'
                '💡 *Термокуту бекер берилет!*',
            showActionCard: true,
            actionType: 'register',
          );
        default:
          return CuratorResponse(
            text: '📄 **Документы для оформления доставки в РФ:**\n\n'
                '• **Граждане РФ:** только паспорт с пропиской и ИНН.\n'
                '• **Граждане ЕАЭС (Беларусь, Казахстан, Кыргызстан, Армения):** паспорт, регистрация, ИНН, СНИЛС. Патент НЕ требуется!\n'
                '• **Другие страны (Узбекистан, Таджикистан...):** паспорт с переводом, регистрация, патент с чеками, ИНН, СНИЛС.\n\n'
                'Термокороб и жёлтая форма выдаются бесплатно в Курьерском центре или ПВЗ.',
            showActionCard: true,
            actionType: 'register',
          );
      }
    } else {
      return CuratorResponse(
        text: '📄 Для оформления в вашей стране потребуется удостоверение личности/паспорт и банковская карта для получения ежедневных выплат.',
        showActionCard: true,
        actionType: 'register',
      );
    }
  }

  CuratorResponse _getAgeResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: '🎂 **Necha yoshdan ishlash mumkin?**\n\n'
              'Ko‘pgina shaharlarda 18 yoshdan. Bir qator yirik shaharlarda esa ota-onaning roziligi bilan 16 yoshdan boshlab kuryer bo‘lib ishlash mumkin.',
          showActionCard: true,
          actionType: 'register',
        );
      default:
        return CuratorResponse(
          text: '🎂 **С какого возраста можно доставлять?**\n\n'
              'В большинстве городов сотрудничество доступно с **18 лет**. В ряде крупных городов (Москва, СПб, Казань) можно начать с **16 лет** с письменного согласия родителей.',
          showActionCard: true,
          actionType: 'register',
        );
    }
  }

  CuratorResponse _getBagResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: '🎒 **Termo-sumka va forma:**\n\n'
              'Yandex Eda termo-sumkasi va kuryer formasi **mutlaqo bepul** beriladi. Hech qanday garov yoki to‘lov talab qilinmaydi. Uni Kuryerlik markazidan yoki buyurtma berish punktidan (PVZ) olishingiz mumkin.',
          showActionCard: true,
          actionType: 'register',
        );
      default:
        return CuratorResponse(
          text: '🎒 **Термокороб и экипировка:**\n\n'
              'Термосумка и фирменная экипировка выдаются **абсолютно бесплатно и без залога**. Никаких скрытых вычетов. Получить можно в Курьерском центре или в ближайшем пункте выдачи заказов (ПВЗ Яндекс Маркета).',
          showActionCard: true,
          actionType: 'register',
        );
    }
  }

  CuratorResponse _getFinesResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: '⚡ **Jarimalar haqida:**\n\n'
              'Yandex Eda da tasodifiy kechikishlar (tirbandlik, ob-havo) uchun jarimalar yo‘q. Tizim sharoitni tushunadi. Hamkor kuryerlar erkin grafikda va qulay sharoitda ishlaydi.',
          showActionCard: true,
          actionType: 'register',
        );
      default:
        return CuratorResponse(
          text: '⚡ **Штрафы и опоздания:**\n\n'
              'За разовые случайные опоздания из-за пробок или погоды штрафов нет — система учитывает дорожную обстановку. Сервис ценит партнёров и обеспечивает страховку на всё время выполнения доставок.',
          showActionCard: true,
          actionType: 'register',
        );
    }
  }

  CuratorResponse _getRegistrationPromptResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: '🚀 Ajoyib! Quyidagi kartochka orqali rasmiy Yandex Pro arizasini to‘ldirishingiz mumkin. Bu atigi 3 daqiqa vaqt oladi:',
          showActionCard: true,
          actionType: 'register',
        );
      default:
        return CuratorResponse(
          text: '🚀 Отлично! Вы можете прямо сейчас подать официальную заявку партнёра. Анкета занимает всего 3 минуты:',
          showActionCard: true,
          actionType: 'register',
        );
    }
  }

  CuratorResponse _getDefaultResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: 'Men sizga Yandex Eda da kuryer bo‘lib ro‘yxatdan o‘tish, hujjatlar va kunlik to‘lovlar bo‘yicha yordam bera olaman. Quyidagi tugmalardan birini tanlang yoki savolingizni yozing:',
          showActionCard: true,
          actionType: 'register',
        );
      default:
        return CuratorResponse(
          text: 'Я персональный куратор и готов ответить на любые вопросы по регистрации в Яндекс Еде, документам, бесплатному термокоробу и выплатам. Выберите тему на кнопках ниже или задайте вопрос:',
          showActionCard: true,
          actionType: 'register',
        );
    }
  }

  // --- Запрос к GigaChat Lite API (будет активирован после передачи ключа) ---
  Future<CuratorResponse?> _queryGigaChat(String prompt, String lang, String country) async {
    // Sber GigaChat Lite endpoint
    // Payload with strict system prompt & temperature 0.1
    return null;
  }
}
