import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? _cloudEndpoint;
  String? _accessToken;
  DateTime? _tokenExpiresAt;
  bool _isInit = false;

  Future<void> _ensureInitialized() async {
    if (_isInit) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _gigaChatApiKey = prefs.getString('gigachat_api_key') ?? AiConfig.defaultGigaChatKey;
      _cloudEndpoint = prefs.getString('curator_cloud_endpoint') ??
          'https://us-central1-courier-f5652.cloudfunctions.net/askCurator';

      // Динамически подтягиваем защищённые настройки из Firestore
      try {
        if (!kIsWeb) {
          final doc = await FirebaseFirestore.instance.collection('app_config').doc('ai_settings').get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            if (data['cloud_endpoint'] != null && (data['cloud_endpoint'] as String).isNotEmpty) {
              _cloudEndpoint = data['cloud_endpoint'] as String;
            }
            if (data['gigachat_key'] != null && (data['gigachat_key'] as String).isNotEmpty) {
              _gigaChatApiKey = data['gigachat_key'] as String;
            }
          }
        } else {
          // В Web-превью загружаем через REST API Firestore
          const url = 'https://firestore.googleapis.com/v1/projects/courier-f5652/databases/(default)/documents/app_config/ai_settings?key=AIzaSyDXwODJZEWsUpPnBC4E9x-GpuWadhBTUSg';
          final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
          if (res.statusCode == 200) {
            final data = jsonDecode(utf8.decode(res.bodyBytes));
            final keyVal = data['fields']?['gigachat_key']?['stringValue'] as String?;
            if (keyVal != null && keyVal.isNotEmpty) {
              _gigaChatApiKey = keyVal;
            }
          }
        }
      } catch (e) {
        debugPrint('CuratorAiService: Firestore fetch error: $e');
      }
    } catch (_) {
      _gigaChatApiKey = AiConfig.defaultGigaChatKey;
    }
    _isInit = true;
  }

  Future<void> setApiKey(String key) async {
    _gigaChatApiKey = key.trim();
    _accessToken = null;
    _tokenExpiresAt = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gigachat_api_key', _gigaChatApiKey!);
    } catch (_) {}
  }

  Future<void> setCloudEndpoint(String endpoint) async {
    _cloudEndpoint = endpoint.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('curator_cloud_endpoint', _cloudEndpoint!);
    } catch (_) {}
  }

  String get currentApiKey => _gigaChatApiKey ?? AiConfig.defaultGigaChatKey;

  /// Главная точка входа для общения с Персональным помощником.
  /// Работает в двух слоях:
  /// 1. Локальный движок базы знаний (0.01 сек, 100% надёжность).
  /// 2. GigaChat Lite API (когда ключ передан).
  Future<CuratorResponse> ask(
    String userQuestion, {
    List<Map<String, String>> history = const [],
    required String lang,
    required String country,
  }) async {
    await _ensureInitialized();
    final lower = userQuestion.toLowerCase().trim();

    // 1. Проверяем кто ты / куратор / робот
    if (_matches(lower, ['кто ты', 'ты кто', 'как звать', 'как зовут', 'сен кімсің', 'кимсиң', 'kimsan', 'робот'])) {
      return _getWhoAreYouResponse(lang);
    }

    // 2. Проверяем триггеры ошибок регистрации и памятки
    if (_matches(lower, ['ошибка', 'не входит', 'сбой', 'vpn', 'впн', 'кэш', 'завис', 'xato', 'иштебей', 'қате'])) {
      return _getErrorResponse(lang);
    }

    // 3. Проверяем связку с Мой Налог
    if (_matches(lower, ['мой налог', 'самозанят', 'смз', 'налог', 'партнер', 'moy nalog', 'салык'])) {
      return _getMoyNalogResponse(lang);
    }

    // 4. Проверяем вопросы гражданства и документов
    if (_matches(lower, ['документ', 'граждан', 'узбек', 'кыргыз', 'патент', 'таджик', 'еаэс', 'hujjat', 'документтер', 'құжат'])) {
      return _getDocsResponse(lang, country);
    }

    // 5. Проверяем возраст
    if (_matches(lower, ['лет', 'возраст', '16', '18', 'школьник', 'несовершеннолет', 'yosh', 'жаш'])) {
      return _getAgeResponse(lang);
    }

    // 6. Проверяем сумку/короб и экипировку
    if (_matches(lower, ['сумк', 'короб', 'экипировк', 'форма', 'залог', 'платн', 'sumka', 'тегін'])) {
      return _getBagResponse(lang);
    }

    // 7. Проверяем штрафы и опоздания
    if (_matches(lower, ['штраф', 'опозда', 'наказан', 'вычет', 'jarima', 'айып'])) {
      return _getFinesResponse(lang);
    }

    // 8. Готовность начать / регистрация
    if (_matches(lower, ['рег', 'хочу', 'давай', 'готов', 'начать', 'ссылк', 'анкет', 'устро', 'ro‘yxat', 'каттал', 'тіркел'])) {
      return _getRegistrationPromptResponse(lang);
    }

    // 9. Сначала пробуем защищённый шлюз Cloud Functions (Zero-Trust безопасность)
    final cloudResponse = await _queryCloudCurator(userQuestion, history, lang, country);
    if (cloudResponse != null) return cloudResponse;

    // 10. Если шлюз недоступен, но есть динамический ключ — прямой вызов
    if (_gigaChatApiKey != null && _gigaChatApiKey!.isNotEmpty) {
      try {
        final gigaResponse = await _queryGigaChat(userQuestion, history, lang, country);
        if (gigaResponse != null) return gigaResponse;
      } catch (e) {
        debugPrint('CuratorAiService: API error: $e');
      }
    }

    // 11. Базовый дружелюбный ответ помощника по умолчанию (без навязчивых кнопок)
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

  CuratorResponse _getWhoAreYouResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: 'Men yetkazib berish xizmatidagi shaxsiy kuratoringizman. Kuryer bo‘lib ishga kirish, daromad, erkin grafik va zarur narsalarni olishda yordam beraman. Shartlar bo‘yicha savolingiz bormi yoki rasmiylashtirishga tayyormisiz?',
          showActionCard: false,
        );
      case 'kg':
        return CuratorResponse(
          text: 'Мен жеткирүү кызматындагы жеке кураторуңузмун. Курьер болуп орношуу, киреше, график жана керектүү нерселерди алууда жардам берем. Шарттар боюнча сурооңуз барбы же катталууга даярсызбы?',
          showActionCard: false,
        );
      case 'kz':
        return CuratorResponse(
          text: 'Мен жеткізу қызметіндегі жеке кураторыңызбын. Курьер болып орналасу, табыс, икемді график және қажетті жабдықтарды алуда көмектесемін. Шарттар бойынша көмектесейін бе немесе тіркелуге дайынсыз ба?',
          showActionCard: false,
        );
      default:
        return CuratorResponse(
          text: 'Я твой личный куратор и наставник в сервисе доставки. Помогаю соискателям устроиться курьером: рассказываю про доход, график, документы и получение экипировки. Тебе подсказать по условиям или хочешь оформиться?',
          showActionCard: false,
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
          showActionCard: false,
          actionType: 'help_guide',
        );
      default:
        return CuratorResponse(
          text: '📲 **Как привязать «Мой налог» к сервису доставки (за 1 минуту):**\n\n'
              '1. Откройте приложение «Мой налог» ➡️ вкладка **«Прочее»**.\n'
              '2. Выберите раздел **«Партнёры»**.\n'
              '3. Найдите в списке сервис доставки и нажмите **«Разрешить»**.\n'
              '4. Вернитесь в приложение — статус самозанятости подтвердится автоматически!',
          showActionCard: false,
          actionType: 'help_guide',
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
                '💡 *Termo-sumka va forma Kuryerlik markazidan beriladi.*',
            showActionCard: false,
          );
        case 'kg':
          return CuratorResponse(
            text: '📄 **Россияда иштөө үчүн Кыргызстан жарандарына (ЕАЭС):**\n\n'
                '• Паспорт жана нотариалдык котормо\n'
                '• Катталуу (регистрация)\n'
                '• ИНН жана СНИЛС\n'
                '• ⚡ **ПАТЕНТ КЕРЕК ЭМЕС!** ЕАЭС келишими боюнча Кыргызстан жарандары патентсиз иштей алат.\n\n'
                '💡 *Термокуту жана экипировка Курьердик борбордон берилет.*',
            showActionCard: false,
          );
        default:
          return CuratorResponse(
            text: '📄 **Документы для оформления доставки в РФ:**\n\n'
                '• **Граждане РФ:** только паспорт с пропиской и ИНН.\n'
                '• **Граждане ЕАЭС (Беларусь, Казахстан, Кыргызстан, Армения):** паспорт, регистрация, ИНН, СНИЛС. Патент НЕ требуется!\n'
                '• **Другие страны (Узбекистан, Таджикистан...):** паспорт с переводом, регистрация, патент с чеками, ИНН, СНИЛС.\n\n'
                'Термокороб и экипировка выдаются в Курьерском центре или ПВЗ.',
            showActionCard: false,
          );
      }
    } else {
      return CuratorResponse(
        text: '📄 Для оформления в вашей стране потребуется удостоверение личности/паспорт и банковская карта для получения ежедневных выплат.',
        showActionCard: false,
      );
    }
  }

  CuratorResponse _getAgeResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: '🎂 **Necha yoshdan ishlash mumkin?**\n\n'
              'Ko‘pgina shaharlarda 18 yoshdan. Bir qator yirik shaharlarda esa ota-onaning roziligi bilan 16 yoshdan boshlab kuryer bo‘lib ishlash mumkin.',
          showActionCard: false,
        );
      default:
        return CuratorResponse(
          text: '🎂 **С какого возраста можно доставлять?**\n\n'
              'В большинстве городов сотрудничество доступно с **18 лет**. В ряде крупных городов (Москва, СПб, Казань) можно начать с **16 лет** с письменного согласия родителей.',
          showActionCard: false,
        );
    }
  }

  CuratorResponse _getBagResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: '🎒 **Termo-sumka va forma:**\n\n'
              'Termo-sumka va kuryer formasini Kuryerlik markazidan yoki berish punktidan (PVZ) olishingiz mumkin. Kurator sizga aniq manzilni beradi.',
          showActionCard: false,
        );
      default:
        return CuratorResponse(
          text: '🎒 **Термокороб и экипировка:**\n\n'
              'Термосумка и экипировка выдаются в Курьерском центре или в ближайшем пункте выдачи заказов (ПВЗ). Куратор подскажет точный адрес и выдаст направление.',
          showActionCard: false,
        );
    }
  }

  CuratorResponse _getFinesResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: '⚡ **Jarimalar haqida:**\n\n'
              'Tasodifiy kechikishlar (tirbandlik, ob-havo) uchun jarimalar yo‘q. Tizim sharoitni tushunadi. Hamkor kuryerlar erkin grafikda va qulay sharoitda ishlaydi.',
          showActionCard: false,
        );
      default:
        return CuratorResponse(
          text: '⚡ **Штрафы и опоздания:**\n\n'
              'За разовые случайные опоздания из-за пробок или погоды штрафов нет — система учитывает дорожную обстановку. Сервис ценит партнёров и обеспечивает страховку на всё время выполнения доставок.',
          showActionCard: false,
        );
    }
  }

  CuratorResponse _getRegistrationPromptResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: '🚀 Ajoyib! Hamkorlik arizasini to‘ldirish uchun quyidagi «Ro‘yxatdan o‘tish» tugmasini bosing — bu atigi 2-3 daqiqa vaqt oladi. Shundan so‘ng darhol kuryerlik markaziga borishingiz mumkin. Savollaringiz bo‘lsa, men shu yerdaman!',
          showActionCard: true,
          actionType: 'register',
        );
      default:
        return CuratorResponse(
          text: '🚀 Отлично! Нажимай кнопку «Регистрация» прямо под этим сообщением и заполни официальную анкету партнёра — это займёт всего 2-3 минуты. Сразу после этого сможешь получить экипировку и выйти на первые заказы. Если возникнут вопросы — пиши сюда, я на связи!',
          showActionCard: true,
          actionType: 'register',
        );
    }
  }

  CuratorResponse _getDefaultResponse(String lang) {
    switch (lang) {
      case 'uz':
        return CuratorResponse(
          text: 'Men sizga kuryer bo‘lib ro‘yxatdan o‘tish, hujjatlar va kunlik to‘lovlar bo‘yicha yordam beruvchi shaxsiy kuratorman. Savolingizni yozing yoki kerakli mavzuni tanlang:',
          showActionCard: false,
        );
      default:
        return CuratorResponse(
          text: 'Я твой личный куратор и готов ответить на любые вопросы по доставке, документам, экипировке и выплатам. Напиши свой вопрос или выбери тему на кнопках:',
          showActionCard: false,
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
      final rqUid = _generateUuidV4();

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

  Future<CuratorResponse?> _queryGigaChat(
    String prompt,
    List<Map<String, String>> history,
    String lang,
    String country,
  ) async {
    if (_gigaChatApiKey == null || _gigaChatApiKey!.isEmpty) return null;

    final token = await _getAccessToken(_gigaChatApiKey!);
    if (token == null) return null;

    try {
      final systemContext = '${AiConfig.systemPrompt}\n[Текущий контекст пользователя]: Язык приложения: $lang. Страна трудоустройства: $country.';

      final messagesList = <Map<String, dynamic>>[
        {'role': 'system', 'content': systemContext},
        ...history.take(6).map((h) => {
              'role': h['role'] ?? 'user',
              'content': h['content'] ?? '',
            }),
        {'role': 'user', 'content': prompt},
      ];

      final response = await http.post(
        Uri.parse('https://gigachat.devices.sberbank.ru/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'model': AiConfig.gigaChatModel,
          'messages': messagesList,
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
            final showCard = _shouldShowActionCard(prompt, replyText);
            return CuratorResponse(
              text: replyText.trim(),
              showActionCard: showCard,
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

  String _generateUuidV4() {
    final rnd = Random();
    String hex(int length) =>
        List.generate(length, (_) => rnd.nextInt(16).toRadixString(16)).join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';
  }

  /// Запрос через защищенный шлюз Firebase Cloud Function (ключ не покидает сервер Google)
  Future<CuratorResponse?> _queryCloudCurator(
    String prompt,
    List<Map<String, String>> history,
    String lang,
    String country,
  ) async {
    final endpoint = kIsWeb
        ? 'http://localhost:8081/askCurator'
        : (_cloudEndpoint ?? 'https://us-central1-courier-f5652.cloudfunctions.net/askCurator');
    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
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
      RegExp(r'ro‘yxat', caseSensitive: false),
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
