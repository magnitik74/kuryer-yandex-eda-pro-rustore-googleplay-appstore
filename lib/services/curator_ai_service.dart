import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/ai_config.dart';

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

  String? _gigaChatApiKey;
  String? _accessToken;
  DateTime? _tokenExpiresAt;
  bool _isInit = false;

  Future<void> _ensureInitialized() async {
    if (_isInit) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _gigaChatApiKey = prefs.getString('gigachat_api_key') ?? AiConfig.defaultGigaChatKey;
    } catch (_) {
      _gigaChatApiKey = AiConfig.defaultGigaChatKey;
    }
    _isInit = true;
  }

  Future<void> setApiKey(String key) async {
    _gigaChatApiKey = key.trim();
    _accessToken = null; // Invalidate cached token
    _tokenExpiresAt = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gigachat_api_key', _gigaChatApiKey!);
    } catch (_) {}
  }

  String get currentApiKey => _gigaChatApiKey ?? AiConfig.defaultGigaChatKey;

  /// Главная точка входа для общения с Персональным помощником.
  /// Работает в двух слоях:
  /// 1. Локальный движок базы знаний (0.01 сек, 100% надёжность).
  /// 2. GigaChat Lite API (когда ключ передан).
  Future<CuratorResponse> ask(
    String userQuestion, {
    required String lang,
    required String country,
  }) async {
    await _ensureInitialized();
    final lower = userQuestion.toLowerCase().trim();

    // 1. Проверяем триггеры ошибок регистрации и памятки
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

    // 8. Если передан ключ GigaChat Lite — запрос к API
    if (_gigaChatApiKey != null && _gigaChatApiKey!.isNotEmpty) {
      try {
        final gigaResponse = await _queryGigaChat(userQuestion, lang, country);
        if (gigaResponse != null) return gigaResponse;
      } catch (e) {
        debugPrint('CuratorAiService: API error: $e');
      }
    }

    // 9. Базовый дружелюбный ответ помощника по умолчанию
    return _getDefaultResponse(lang);
  }

  bool _matches(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  // --- Локальные выверенные ответы по Базе Знаний ---

  CuratorResponse _getErrorResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: '🛠️ **Ro‘yxatdan o‘tishdagi xatolikni tuzatish:**\n\n'
              '1. 🔴 **VPN ni o‘chiring!** (90% hollarda xatolik aynan VPN tufayli bo‘ladi).\n'
              '2. Ilova keshini tozalang va telefonni qayta yoqing.\n'
              '3. Internet aloqasini tekshiring.\n'
              '4. Agar avval boshqa raqam bilan ishlagan bo‘lsangiz — ilovadagi "Yordam" bo‘limi orqali yozing.',
          showActionCard: false,
          actionType: 'help_guide',
        );
      case 'kg':
        return CuratorResponse(
          text: '🛠️ **Катталуудагы катаны оңдоо:**\n\n'
              '1. 🔴 **VPNди өчүрүңүз!** (90% учурда ката VPN иштеп турганда чыгат).\n'
              '2. Тиркеменин кэшин тазалап, телефонду өчүрүп-күйгүзүңүз.\n'
              '3. Эгер мурда башка номер менен жеткирүү кылган болсоңуз — "Жардам" баскычы аркылуу билдириңиз.',
          showActionCard: false,
          actionType: 'help_guide',
        );
      case 'kz':
        return CuratorResponse(
          text: '🛠️ **Тіркелу кезіндегі қатені түзету:**\n\n'
              '1. 🔴 **VPN-ді өшіріңіз!** (90% жағдайда қате VPN қосулы болғанда шығады).\n'
              '2. Қолданба кэшін тазалап, телефонды қайта жүктеңіз.\n'
              '3. Егер бұрын басқа нөмірмен жұмыс істеген болсаңыз — қолдау қызметіне жазыңыз.',
          showActionCard: false,
          actionType: 'help_guide',
        );
      default:
        return CuratorResponse(
          text: '🛠️ **Решение ошибки при входе / регистрации:**\n\n'
              '1. 🔴 **Выключите VPN!** (В 90% случаев сбой сети и авторизации происходит именно из-за VPN).\n'
              '2. Очистите кэш приложения и перезагрузите телефон.\n'
              '3. Проверьте стабильность мобильного интернета.\n'
              '4. ⚠️ **Важно:** если ранее выполняли доставки с другого номера — обязательно сообщите об этом поддержке через кнопку «Помощь», чтобы не получить блокировку за дубль аккаунта.',
          showActionCard: false,
          actionType: 'help_guide',
        );
    }
  }

  CuratorResponse _getMoyNalogResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: '📲 **«Moy nalog» ilovasini yetkazib berish xizmati bilan bog‘lash:**\n\n'
              '1. «Moy nalog» ilovasiga kiring ➡️ pastdagi **«Boshqalar» (Прочее)** bo‘limiga o‘ting.\n'
              '2. **«Hamkorlar» (Партнёры)** bandini bosing.\n'
              '3. Ro‘yxatdan **«Yetkazib berish xizmati»** ni toping va **«Ruxsat berish»** tugmasini bosing.\n'
              '4. Ilovaga qaytib, davom eting!',
          showActionCard: true,
          actionType: 'register',
        );
      default:
        return CuratorResponse(
          text: '📲 **Как привязать «Мой налог» к сервису доставки (за 1 минуту):**\n\n'
              '1. Откройте приложение «Мой налог» ➡️ вкладка **«Прочее»**.\n'
              '2. Выберите раздел **«Партнёры»**.\n'
              '3. Найдите в списке сервис доставки и нажмите **«Разрешить»**.\n'
              '4. Вернитесь в приложение — статус самозанятости подтвердится автоматически!',
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
              'Termo-sumka va kuryer formasi **mutlaqo bepul** beriladi. Hech qanday garov yoki to‘lov talab qilinmaydi. Uni Kuryerlik markazidan yoki berish punktidan olishingiz mumkin.',
          showActionCard: true,
          actionType: 'register',
        );
      default:
        return CuratorResponse(
          text: '🎒 **Термокороб и экипировка:**\n\n'
              'Термосумка и фирменная экипировка выдаются **абсолютно бесплатно и без залога**. Никаких скрытых вычетов. Получить можно в Курьерском центре или в ближайшем пункте выдачи заказов (ПВЗ).',
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
              'Tasodifiy kechikishlar (tirbandlik, ob-havo) uchun jarimalar yo‘q. Tizim sharoitni tushunadi. Hamkor kuryerlar erkin grafikda va qulay sharoitda ishlaydi.',
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
          text: '🚀 Ajoyib! Quyidagi kartochka orqali rasmiy arizani to‘ldirishingiz mumkin. Bu atigi 3 daqiqa vaqt oladi:',
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
          text: 'Men sizga kuryer bo‘lib ro‘yxatdan o‘tish, hujjatlar va kunlik to‘lovlar bo‘yicha yordam bera olaman. Quyidagi tugmalardan birini tanlang yoki savolingizni yozing:',
          showActionCard: true,
          actionType: 'register',
        );
      default:
        return CuratorResponse(
          text: 'Я персональный помощник и готов ответить на любые вопросы по регистрации в доставке, документам, бесплатному термокоробу и выплатам. Выберите тему на кнопках ниже или задайте вопрос:',
          showActionCard: true,
          actionType: 'register',
        );
    }
  }

  Future<String?> _getAccessToken(String authData) async {
    if (_accessToken != null &&
        _tokenExpiresAt != null &&
        DateTime.now().isBefore(_tokenExpiresAt!)) {
      return _accessToken;
    }

    try {
      final formattedAuth = authData.trim().startsWith('Basic ')
          ? authData.trim()
          : 'Basic ${authData.trim()}';
      final rqUid = 'eda-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';

      final response = await http.post(
        Uri.parse('https://ngw.devices.sberbank.ru:9443/api/v2/oauth'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'RqUID': rqUid,
          'Authorization': formattedAuth,
        },
        body: 'scope=GIGACHAT_API_PERS',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'] as String?;
        final expiresAtMs = data['expires_at'] as int?;
        if (expiresAtMs != null) {
          _tokenExpiresAt = DateTime.fromMillisecondsSinceEpoch(expiresAtMs)
              .subtract(const Duration(minutes: 2));
        }
        return _accessToken;
      } else {
        debugPrint('GigaChat OAuth error: ${response.statusCode} -> ${response.body}');
      }
    } catch (e) {
      debugPrint('GigaChat OAuth exception: $e');
    }
    return null;
  }

  Future<CuratorResponse?> _queryGigaChat(String prompt, String lang, String country) async {
    if (_gigaChatApiKey == null || _gigaChatApiKey!.isEmpty) return null;

    final token = await _getAccessToken(_gigaChatApiKey!);
    if (token == null) return null;

    try {
      final systemContext = '${AiConfig.systemPrompt}\n[Текущий контекст пользователя]: Язык приложения: $lang. Страна трудоустройства: $country.';

      final response = await http.post(
        Uri.parse('https://gigachat.devices.sberbank.ru/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'model': AiConfig.gigaChatModel,
          'messages': [
            {'role': 'system', 'content': systemContext},
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 512,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choices = data['choices'] as List<dynamic>?;
        if (choices != null && choices.isNotEmpty) {
          final replyText = choices[0]['message']?['content'] as String?;
          if (replyText != null && replyText.trim().isNotEmpty) {
            return CuratorResponse(
              text: replyText.trim(),
              showActionCard: true,
              actionType: 'register',
            );
          }
        }
      } else {
        debugPrint('GigaChat completions error: ${response.statusCode} -> ${response.body}');
      }
    } catch (e) {
      debugPrint('GigaChat completions exception: $e');
    }
    return null;
  }
}
