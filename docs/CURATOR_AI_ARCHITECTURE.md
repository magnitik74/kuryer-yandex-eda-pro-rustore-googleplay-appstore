# Curator AI Architecture Manifest
## «Курьер PRO Еда» — Гибридный ИИ-куратор (Local KB + Vercel/GigaChat)

**Версия:** 1.0  
**Дата:** 02.10.2026  
**Статус:** Approved for implementation

---

## 1. Архитектурные принципы

| Принцип | Реализация |
|---------|------------|
| **Security First** | API ключи (GigaChat, Firebase) только на сервере (Vercel). Клиент не знает секретов. |
| **Speed First** | 95% вопросов → Local KB (0.01с). Никакой латентности на типовые вопросы. |
| **Reliability** | Local KB работает офлайн, 100% аптайм. Vercel — фоллбек. |
| **Control** | Юристы/ПМ правят JSON-конфиги стран без деплоя приложения. |
| **Observability** | Каждое событие воронки в AppMetrica (API Key: `4ff9cec0-7d1c-4824-a335-c44f16c0ec47`). |
| **Proactive** | Бот ведёт диалог, знает этап пользователя, задаёт открытые вопросы. |

---

## 2. Двухслойная схема ответа (Hybrid Engine)

```
┌─────────────────────────────────────────────────────────────┐
│                    USER QUESTION                              │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  LAYER 1: LOCAL KNOWLEDGE BASE (assets/country_config/)     │
│  • Regex/keyword intent classification                      │
│  • Country-specific FAQ (VPN, docs, Moy Nalog, bag, age...) │
│  • Stage-aware responses (pre-reg / post-reg / active)      │
│  • Proactive question at end if stage allows                │
│  • ActionCard ONLY on registration intent                   │
│  • Response time: < 0.01s                                   │
└─────────────────────────┬───────────────────────────────────┘
                          ▼ (no match / low confidence)
┌─────────────────────────────────────────────────────────────┐
│  LAYER 2: VERCEL GATEWAY → GIGACHAT                         │
│  • Endpoint: https://<project>.vercel.app/api/askCurator    │
│  • Server-side: OAuth token → GigaChat completion           │
│  • System prompt injected with CuratorContext               │
│  • Response time: 2-5s                                      │
│  • Fallback to Local KB friendly message on error           │
└─────────────────────────────────────────────────────────────┘
```

**Правило:** Local KB **всегда** первый. Vercel вызывается только если:
- Нет совпадения по ключевым словам/регекспам
- Конфиденс Local KB < порога (не реализовано в MVP, просто "нет совпадения")
- Пользователь спрашивает что-то вне FAQ (free-text)

---

## 3. CuratorContext — единый контекст диалога

```dart
class CuratorContext {
  final String country;           // ru/kz/uz/kg/by
  final String format;            // auto/moto/bike/walk
  final String userName;
  final CuratorStage stage;       // см. ниже
  final bool hasRegistered;       // LocaleService.hasRegisteredCabinet
  final int daysSinceReg;
  final bool moyNalogLinked;
  final bool bagReceived;
  final String? currentCity;
}

enum CuratorStage {
  greeting,           // только вошёл в чат (isFreshLead)
  preRegistration,    // отвечает на вопросы ДО регистрации
  registrationSent,   // анкета отправлена, ждёт звонка
  postRegistration,   // оператор перезвонил, идёт в ЦО
  activeCourier,      // на линии, делает заказы
  churnedRisk,        // 3+ дня нет активности
}
```

**Переходы стадий:**
| Триггер | Новая стадия | Действие бота |
|---------|--------------|---------------|
| `isFreshLead == true` | `greeting` → `preRegistration` | Welcome + ActionCard регистрации |
| `RegistrationHelper.startRegistration()` called | `preRegistration` → `registrationSent` | «Анкета улетела! Оператор перезвонит за 15 мин. Тут же отвечу на вопросы про VPN, Мой налог, документы.» + пуш-планировщик |
| Юзер пишет «заполнил/отправил/сделал» | `registrationSent` | «Супер! Жди звонка. Хочешь, покажу как привязать Мой налог?» |
| `LocaleService.hasRegisteredCabinet == true` | `registrationSent` → `postRegistration` | «Ты в системе! 1) Привяжи Мой налог, 2) Запишись на сумку в ЦО {адрес}. Нужна помощь?» |
| Юзер подтвердил получение сумки | `postRegistration` → `activeCourier` | «Сумка получена! 🎒 Выходи на первый слот. Совет: начни с 2-3 часов вечером.» |
| 7 дней без активности | `activeCourier` → `churnedRisk` | Пуш: «Давно не виделись. Всё ок? Нужен разбор по заказам?» |

---

## 4. Country Config — единственный источник правды

**Файлы:** `assets/country_config/{ru,kz,uz,kg,by}.json`

Каждый содержит:
```json
{
  "country": "ru",
  "name": "Россия",
  "currency": "₽", "currencyCode": "RUB", "dialCode": "+7",
  "refCode": "refRU", "defaultRefUrl": "...",
  "timezone": "Europe/Moscow", "languages": ["ru"],
  "offlineCities": ["Москва", "СПб", ...],
  "documents": { "rf_citizens": [...], "eaeu_citizens": [...], ... },
  "supportPhone": "8 800 555 35 35",
  "courierCenters": [{"city": "Москва", "address": "...", "type": "offline"}],
  "pvzNote": "...", "photoControlSteps": [...],
  "faq": { "vpn_error": "...", "moy_nalog": "...", "bag": "...", "age": "...", "fines": "...", "photo_control": "...", "video_training": "..." },
  "operatorGreeting": "...",
  "rates": { "auto": 694, "moto": 520, "bike": 420, "walk": 330 },
  "maxMonthlyIncome": { "auto": 250000 }
}
```

**Доступ в коде:** `LocaleService().faq['vpn_error']`, `LocaleService().rates['auto']` и т.д. — никаких хардкодов.

---

## 5. Local KB — логика ответа (псевдокод)

```dart
CuratorResponse ask(String question, CuratorContext ctx) {
  final lower = question.toLowerCase().trim();
  final cfg = countryConfig[ctx.country];
  
  // 1. Intent classification (ordered by priority)
  if (matches(lower, ['кто ты', 'ты кто', 'робот', 'бот', 'нейросеть', 'gigachat', 'сбер'])) {
    return whoAreYouResponse(ctx.lang);
  }
  if (matches(lower, ['ошибка', 'не входит', 'сбой', 'vpn', 'впн', 'кэш', 'завис'])) {
    return CuratorResponse(text: cfg.faq['vpn_error']!, showActionCard: false);
  }
  if (matches(lower, ['мой налог', 'самозанят', 'налог', 'партнер', 'e-salyq', 'солиқ', 'түндүк', 'пдн'])) {
    return CuratorResponse(text: cfg.faq['moy_nalog']!, showActionCard: false);
  }
  if (matches(lower, ['документ', 'паспорт', 'граждан', 'патент', 'виза', 'внж', 'рвп', 'пинфл', 'унп'])) {
    return docsResponse(ctx); // строит ответ из cfg.documents
  }
  if (matches(lower, ['возраст', 'лет', '16', '18', 'школьник', 'несовершеннолет'])) {
    return CuratorResponse(text: cfg.faq['age']!, showActionCard: false);
  }
  if (matches(lower, ['сумк', 'короб', 'экипировк', 'форма', 'залог', 'термо'])) {
    return CuratorResponse(text: cfg.faq['bag']!, showActionCard: false);
  }
  if (matches(lower, ['штраф', 'опозда', 'наказан', 'вычет'])) {
    return CuratorResponse(text: cfg.faq['fines']!, showActionCard: false);
  }
  if (matches(lower, ['фотоконтроль', 'фото', 'селфи', 'диагностика'])) {
    return CuratorResponse(text: cfg.faq['photo_control']!, showActionCard: false);
  }
  if (matches(lower, ['видео', 'обучен', 'не грузит', 'не работает'])) {
    return CuratorResponse(text: cfg.faq['video_training']!, showActionCard: false);
  }
  if (matches(lower, ['доход', 'зарплат', 'заработ', 'сколько платят', 'тариф', 'ставк'])) {
    return incomeResponse(ctx); // показывает мини-калькулятор или чип с суммой
  }
  
  // 2. Registration intent → ActionCard
  if (matches(lower, ['хочу', 'давай', 'готов', 'начать', 'ссылк', 'анкет', 'куда нажать', 'как устроиться', 'оформить', 'зарегистр'])) {
    return registrationPromptResponse(ctx.lang, showActionCard: true);
  }
  
  // 3. No match → Vercel Gateway
  return await queryVercelGateway(question, ctx);
}
```

---

## 6. Proactive Questions (по стадиям)

| Стадия | Проактивный вопрос (в конце ответа) |
|--------|--------------------------------------|
| `preRegistration` | «Какой район тебе ближе для старта?» |
| `registrationSent` | «Нужна инструкция по «Мой налог» прямо сейчас?» |
| `postRegistration` | «Какой ЦО тебе удобнее — {адрес1} или {адрес2}?» |
| `activeCourier` | «Как заказы вчера? Есть вопросы по тарифам?» |
| `churnedRisk` | «Что мешает выйти на линию? Могу помочь с документами/зоной.» |

**Правило:** Один открытый вопрос в конце сообщения, если стадия позволяет. Не навязывать.

---

## 7. Воронка и события (AppMetrica Goals)

| Событие | Параметры | Вызов |
|---------|-----------|-------|
| `onboarding_start` | `country`, `lang` | `LanguageSelectScreen` / `OnboardingScreenV2` |
| `onboarding_format_selected` | `format`, `country` | Тап на чип формата |
| `onboarding_complete` | `format`, `country`, `has_name`, `has_phone` | Сабмит имени/телефона |
| `chat_opened` | `stage`, `format`, `country` | `CuratorTab.initState` |
| `chat_question_asked` | `topic`, `country` | `CuratorAiService.ask()` |
| `registration_clicked` | `country`, `format`, `source` | `RegistrationHelper.startRegistration()` |
| `registration_sent` | `country`, `format` | После открытия WebView/Quiz |
| `push_received` | `push_type` | `LocalPushService` |
| `push_clicked` | `push_type` | `onDidReceiveNotificationResponse` |
| `moy_nalog_linked` | `country` | Детекция intent в чате |
| `bag_received` | `country`, `city` | Профиль / чат / пуш-клик |
| `first_order_done` | `country`, `format` | Пуш-клик / профиль |
| `rating_shown` | `store`, `rating` | `RatingService.showRating()` |
| `rating_sent_to_store` | `store` | `RatingService._openNativeStoreReview()` |
| `app_open` | `cold_start`, `country` | `main.dart` / `SplashScreen` |

---

## 8. Онбординг v2 — Single Screen Flow

```
┌─────────────────────────────────────────┐
│  🇷🇺 Россия          [Сменить]           │  ← Geo-detect + изменяемо
├─────────────────────────────────────────┤
│  Курьер PRO Еда — Официальный партнёр   │
├─────────────────────────────────────────┤
│  🎯  Выбери формат:                     │
│  [Авто 🚗] [Мото 🛵] [Вело 🚲] [Пеший 🚶]│
│                                         │
│  💰  Доход до 250 000 ₽/мес (под формат)│
│  ⏰  График: свободный, от 2 ч/день     │
│  💳  Выплаты ежедневно на карту         │
│  🎒  Сумка и форма — в курьерском центре│
├─────────────────────────────────────────┤
│  👋  Меня зовут ______                  │
│  📞  Телефон: +7 ___ ___ ____           │
│                                         │
│  [  Стать курьером  ]  ← Yellow Pill    │
└─────────────────────────────────────────┘
```

**Хендофф в чат:**
```dart
await _locale.setCourierType(selectedFormat);
await _locale.registerCabinet(name: name, phone: phone, dialCode: dialCode);
Navigator.pushReplacement(context, MaterialPageRoute(
  builder: (_) => CuratorTab(
    initialCourierFormat: selectedFormat,
    isFreshLead: true,  // ← триггерит greeting + ActionCard
  ),
));
```

---

## 9. Sticky CTA — Persistent Registration Banner

Виден на всех табах `MainScreen` (кроме чата), меняется по стадии:

| Стадия | Заголовок | Подзаголовок | Кнопка |
|--------|-----------|--------------|--------|
| `pre` | «Не упусти старт» | «Анкета 3 мин → сумка в ЦО → заказы» | «Заполнить анкету» |
| `sent` | «Анкета отправлена» | «Оператор перезвонит за 15 мин» | «Помощь с регистрацией» → чат |
| `post` | «Забери сумку» | «ЦО: {адрес}. Покажи смс от оператора» | «Открыть чат с куратором» |

---

## 10. Event-Driven Push Notifications

Не таймеры, а триггеры:
```dart
// В RegistrationHelper.startRegistration()
await LocalPushService().onRegistrationSent(); // планирует VPN (30м), MoyNalog (3ч), Bag (24ч)

// В CuratorTab при детекте "заполнил/отправил"
await LocalPushService().onRegistrationSent();

// В профиле кнопка "Получил сумку"
await LocalPushService().onBagReceived();

// В профиле кнопка "Первый заказ выполнен"
await LocalPushService().onFirstOrderDone();
```

**Пуши в очереди (после регистрации):**
1. 30 мин — «Получилось отправить анкету? Вопрос по фотоконтролю — пиши в чат!»
2. 3 часа — «Ошибка входа? В 90% случаев мешает VPN! Выключи и повтори.»
3. 24 часа — «Не подтверждается статус? Подсказка куратора: как привязать «Мой налог» за 1 мин.»
4. 3 дня — «Термокороб ждёт! Заверши оформление, забери форму в ЦО.»
5. 5 дней — «Выполни 5 доставок → макс. бонусы новичка + закрепи статус партнёра!»

---

## 11. Стек и зависимости (новые)

```yaml
dependencies:
  device_info_plus: ^10.1.0      # Geo detection (SIM)
  yandex_metrica: ^4.0.0         # AppMetrica tracking
  # existing: firebase_core, cloud_firestore, shared_preferences, 
  # flutter_local_notifications, timezone, http, url_launcher, etc.
```

**Assets:** `assets/country_config/` (5 JSON файлов)

---

## 12. Файлы к изменению / созданию (Implementation Checklist)

### Sprint 0: Foundation ✅ DONE
- [x] `assets/country_config/ru.json`
- [x] `assets/country_config/kz.json`
- [x] `assets/country_config/uz.json`
- [x] `assets/country_config/kg.json`
- [x] `assets/country_config/by.json`
- [x] `lib/services/geo_detection_service.dart`
- [x] `lib/services/appmetrica_service.dart`
- [x] `lib/services/country_config_service.dart`
- [x] `lib/services/locale_service.dart` (updated)
- [x] `pubspec.yaml` (deps + assets)
- [x] Git remotes: dual-push to GitHub + GitVerse

### Sprint 1: Onboarding v2
- [ ] `lib/screens/onboarding/onboarding_screen_v2.dart` (new)
- [ ] Update `lib/screens/splash/splash_screen.dart` → route to `OnboardingScreenV2`
- [ ] `CuratorTab` — `isFreshLead` handling + welcome message

### Sprint 2: Chat Engine v2
- [ ] `lib/services/curator_dialogue_engine.dart` (new) — `CuratorContext`, `CuratorStage`, state machine
- [ ] `lib/services/curator_ai_service.dart` — rewrite `ask()`: Local KB first → Vercel fallback
- [ ] Remove `_queryGigaChat()` (direct client call, insecure)
- [ ] Keep `_queryCloudCurator()` (Vercel gateway)
- [ ] Dynamic system prompt injection with `CuratorContext`
- [ ] Proactive questions per stage

### Sprint 3: Sticky CTA + Event Push
- [ ] `lib/widgets/sticky_registration_banner.dart` (new)
- [ ] Integrate into `MainScreen`
- [ ] `LocalPushService` v2 — event methods (`onRegistrationSent`, `onBagReceived`, `onFirstOrderDone`)

### Sprint 4: Post-Reg + Polish
- [ ] In-chat nudges after registration (Moy Nalog, ЦО, сумка)
- [ ] Profile screen: buttons «Получил сумку», «Первый заказ выполнен»
- [ ] A/B flags via Remote Config for copy experiments
- [ ] Integration tests for funnel events

---

## 13. Риски и митигации

| Риск | Вероятность | Влияние | Митигация |
|------|-------------|---------|-----------|
| Vercel gateway downtime | Low | Medium | Local KB covers 95%, friendly fallback message |
| GigaChat quota exceeded | Medium | Low | Local KB primary; Vercel only for free-text |
| Country config outdated | Medium | Medium | JSON в assets, обновление через релиз; можно вынести в Remote Config позже |
| Geo detection wrong country | Low | Low | User может сменить страну в онбординге/профиле |
| AppMetrica events missing | Low | High | Unit-тесты для каждого события; CI check |

---

## 14. Принципы поддержки (Maintenance)

1. **Новая страна** → добавить `xx.json` в `assets/country_config/` + обновить `GeoDetectionService._isSupportedCountry()`
2. **Новый FAQ вопрос** → добавить в `faq` секцию JSON + регекс в `CuratorAiService.ask()`
3. **Изменился тариф** → поправить `rates` в JSON
4. **Новый ЦО** → добавить в `courierCenters` в JSON
5. **Новый стор** → добавить `STORE` env + соответствующий review SDK (уже готово в `RatingService`)

---

**Подписи:**
- Product: _______________
- Tech Lead: _______________
- Security: _______________
- Analytics: _______________