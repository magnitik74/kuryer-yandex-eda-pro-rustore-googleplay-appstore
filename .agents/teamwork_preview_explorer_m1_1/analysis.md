# Conversion Funnel Audit & Technical Codebase Analysis
**Target Application:** `fast_courier_app`
**Working Directory:** `D:\projects\Eda_Go_Rustor_GooglePM\fast_courier_app\.agents\teamwork_preview_explorer_m1_1\`
**Audit Date:** July 22, 2026

---

## 1. Executive Summary & Funnel Architecture

The `fast_courier_app` Flutter codebase is a courier recruitment funnel app ("ЕдаGo") designed to convert job seekers into active couriers by directing them either to an external partner referral registration link (loaded via WebView) or an internal offline quiz funnel with phone call conversion.

### Full Conversion Funnel Flow
1. **App Initialization** (`lib/main.dart`): `InitializationScreen` shows logo animation (2000 ms delay) -> Navigates to `PermissionScreen`.
2. **Push Permission Gate** (`lib/screens/onboarding/permission_screen.dart`): Prompts push permissions ("Активация профиля"), schedules 20 engagement push notifications (`LocalPushService`), then navigates to `MainScreen`.
3. **Main Dashboard** (`lib/screens/main_screen.dart`):
   - **Tab 0 ("Главная")**: Main banner + primary CTA button (`"ПОДКЛЮЧИТЬСЯ"`) + 4 transport cards (Walk, Bike, Auto, Scooter).
   - **Tab 1 ("FAQ")**: Expandable Q&A accordion items.
   - **Tab 2 ("Доход")**: Interactive income & referral calculator (`IncomeCalculatorTab`).
   - **Tab 3 ("Чат")**: Courier community chat (`ChatTabContent`) backed by Firebase Firestore.
4. **Pre-landing Step** (`lib/screens/onboarding/prelanding_screen.dart`): Clicking any CTA on Main Screen opens `PrelandingScreen`. Displays 3 animated step cards and pulsing CTA button (`"СТАТЬ КУРЬЕРОМ"`).
5. **Country & Referral Link Router** (`lib/screens/onboarding/country_screen.dart`): User selects target country (RU, KZ, UZ, BY, KG). Checks Remote Config / Firestore (`testAdmin/showTest`):
   - **If `testValue != 1` and partner URL exists:** Triggers rating dialog (`inAppReview`), then opens `StatWebViewScreen` loaded with the country-specific partner referral link (e.g. `refRU`, `refKZ`). **[Primary Conversion Target]**
   - **If `testValue == 1` or URL missing:** Redirects to `QuizScreen` (4-question candidate survey ending with `"ПОЗВОНИТЬ СЕЙЧАС"` CTA to phone `88005553535`). **[Fallback Reviewer/Offline Route]**

---

## 2. Detailed Technical Audit by File & Widget

### 2.1 App Theme & Entry (`lib/main.dart`)
* **File Path:** `lib/main.dart`
* **Classes & Widgets:** `MyApp` (lines 21–50), `InitializationScreen` (lines 52–144), `_InitializationScreenState` (lines 59–143).
* **Theme Implementation:**
  * `fontFamily`: `'MontFamily'` (maps in `pubspec.yaml` to Inter font family: SemiBold 600, Bold 700, Black 900).
  * `colorScheme`: Seeded from `Color(0xFFFCE000)` (Yandex Yellow brand color).
  * `scaffoldBackgroundColor`: `Color(0xFFF7F7F7)` (Light neutral gray).
  * `appBarTheme`: White background (`Colors.white`), dark brown-black text/icons (`Color(0xFF211B15)`), MontFamily w900, size 18, elevation 0.
* **Transition Logic (lines 91–107):** `_initApp()` waits 2000 ms, initializes `LocalPushService()`, then pushes `PermissionScreen` via a 600 ms `FadeTransition`.

---

### 2.2 Main Screen & Main Tab Content (`lib/screens/main_screen.dart`)
* **File Path:** `lib/screens/main_screen.dart`
* **Classes & Widgets:**
  * `MainScreen` (lines 8–30) / `_MainScreenState` (lines 15–176)
  * `MainTabContent` (lines 179–267)
  * `_TransportCard` (lines 269–327)
  * `FaqTabContent` (lines 330–375)
  * `_FaqItem` (lines 377–459)

#### Bottom Navigation Bar (`_buildPremiumBottomBar`, lines 52–156):
* Custom 4-item bottom navigation (`"Главная"`, `"FAQ"`, `"Доход"`, `"Чат"`).
* Active color: `Color(0xFF211B15)` with yellow highlight bubble `Color(0xFFFCE000).withOpacity(0.2)`. Inactive color: `Color(0xFFAAAAAA)`. Light haptic feedback on tab change.

#### CTA Button #1 ("ПОДКЛЮЧИТЬСЯ"):
* **Location:** `MainTabContent`, lines 228–250.
* **Widget Structure:** `SizedBox(width: double.infinity, height: 56)` containing `ElevatedButton`.
* **Visual Implementation:**
  * Background Color: `Color(0xFFFCE000)` (Bright Yellow).
  * Text Color: `Color(0xFF211B15)` (Dark Charcoal/Black).
  * Font Style: MontFamily, `FontWeight.w900`, `fontSize: 16`, `letterSpacing: 0.5`.
  * Shape: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))`. Elevation: 0.
* **Click Handler:** `onPressed: onAction`. Invokes `_startOnboarding()` in `_MainScreenState` (lines 18–30), which unfocuses text input and opens `PrelandingScreen()` via `PageRouteBuilder` with `FadeTransition` (300 ms).

#### CTA Elements #2–5 (Transport Cards):
* **Location:** `MainTabContent`, lines 251–258 (instantiations) and `_TransportCard`, lines 269–327.
* **Items:** `"Пеший курьер"` (Icons.directions_walk), `"Велокурьер"` (Icons.directions_bike), `"Автокурьер"` (Icons.directions_car), `"На самокате"` (Icons.electric_scooter).
* **Visual Implementation:** White container, `borderRadius: 16`, box shadow (`color: black.withOpacity(0.04)`, `blurRadius: 16`, `offset: (0, 4)`). Icon box: 48x48 `Color(0xFFF7F7F7)` with dark icon `Color(0xFF211B15)`. Title font: `FontWeight.w800`, `fontSize: 16`. Trailing arrow icon `Icons.arrow_forward_ios` (`Color(0xFFCCCCCC)`).
* **Click Handler:** `onTap: onClick` -> triggers `onAction` -> `_startOnboarding()`.

---

### 2.3 Prelanding Screen (`lib/screens/onboarding/prelanding_screen.dart`)
* **File Path:** `lib/screens/onboarding/prelanding_screen.dart`
* **Classes & Widgets:** `PrelandingScreen` (lines 5–10), `_PrelandingScreenState` (lines 12–255).
* **Visual & Theme Implementation:**
  * Background: `Color(0xFFF5F5F7)` (Premium iOS Light Gray).
  * Dark Header (lines 88–120): `Color(0xFF211B15)` with bottom rounded corners (radius 32), back arrow icon button, white title `"Всего 3 шага\nк первому доходу"` (`FontWeight.w900`, `fontSize: 22`, `height: 1.2`).
  * Staggered Step Cards (lines 183–254): 3 animated opacity/slide cards (`"Оставьте заявку"`, `"Заберите сумку"`, `"Начните зарабатывать"`). White cards with circular yellow icon background `Color(0xFFFCE000).withOpacity(0.2)`.

#### CTA Button #6 ("СТАТЬ КУРЬЕРОМ"):
* **Location:** `PrelandingScreen`, lines 142–177.
* **Widget Structure:** `AnimatedBuilder` with pulsing `_scaleAnimation` (Tween 1.0 to 1.03 over 800 ms repeating reverse) wrapping `SizedBox(width: double.infinity, height: 64)` and `ElevatedButton`.
* **Visual Implementation:**
  * Background Color: `Color(0xFFFCE000)`.
  * Text Color: `Colors.black`. Text: `"СТАТЬ КУРЬЕРОМ"` (`FontWeight.w900`, `fontSize: 18`, `letterSpacing: 0.5`).
  * Shape: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))`.
  * Elevation: 8, Shadow Color: `Color(0xFFFCE000).withOpacity(0.5)`.
* **Click Handler:** `onPressed: _next` (lines 74–79). Triggers `HapticFeedback.lightImpact()` and calls `Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const CountryScreen()))`.

---

### 2.4 Country Screen & Partner Referral Link Routing (`lib/screens/onboarding/country_screen.dart`)
* **File Path:** `lib/screens/onboarding/country_screen.dart`
* **Classes & Widgets:** `CountryScreen` (lines 11–16), `_CountryScreenState` (lines 18–228).
* **Country Options:**
  1. Russia (`id: 'ru'`, `refCode: 'refRU'`)
  2. Kazakhstan (`id: 'kz'`, `refCode: 'refKZ'`)
  3. Uzbekistan (`id: 'uz'`, `refCode: 'refUZ'`)
  4. Belarus (`id: 'by'`, `refCode: 'refBY'`)
  5. Kyrgyzstan (`id: 'kg'`, `refCode: 'refKG'`)

#### CTA Elements #7 (Country Item Cards):
* **Location:** Lines 150–213 in `ListView.separated`.
* **Visuals:** White card, circular flag (`CountryFlag.fromCountryCode`), country name (`FontWeight.bold`, `fontSize: 18`, `color: Color(0xFF211B15)`), `Icons.chevron_right`.
* **Handler:** `onTap: () => _handleCountrySelection(country)`.

#### Partner Referral Link & Remote Config Execution Logic (`_handleCountrySelection`, lines 29–84):
1. Saves selected country ref code to `SharedPreferences` (`countryRef` and `countryId`).
2. Queries Firebase Firestore collection `testAdmin` document `showTest` (line 40).
3. Reads platform-specific test flag:
   * iOS: `data['test_ios']`
   * Android: `data['test']`
4. Reads partner referral URL for selected country: `url = data[country['refCode']] as String? ?? ""`.
5. **Funnel Decision Logic:**
   * **If `testValue == 1`:** Routes to `QuizScreen` (App Store / Google Play reviewer bypass).
   * **If `testValue != 1`:** Calls `_showRating()` (`inAppReview.requestReview()`).
     * If `url.isNotEmpty`: Navigates to `StatWebViewScreen(url: url)` (line 68). **[Loads Partner Referral Registration Web Page]**
     * If `url.isEmpty`: Navigates to `QuizScreen()` (line 70).

---

### 2.5 Secondary & Web Conversion Screens

#### StatWebViewScreen (`lib/screens/onboarding/stat_webview_screen.dart`)
* Loads partner registration URL in `WebViewWidget` with JavaScript enabled (`JavaScriptMode.unrestricted`).
* Shows white AppBar with `"Регистрация"` title and `IconButton(icon: Icon(Icons.close))` close button.

#### QuizScreen (`lib/screens/onboarding/quiz_screen.dart`)
* 4-question candidate survey (Age, Transport, Experience, Schedule).
* Completion view `_buildFinishedScreen()` (lines 195–258):
  * Success banner: `"Поздравляем! Вы нам подходите! 🎉"`.
  * CTA Button #8 (`"ПОЗВОНИТЬ СЕЙЧАС"`): Lines 233–247. `ElevatedButton.icon`, background `Color(0xFFFCE000)`, text `"ПОЗВОНИТЬ СЕЙЧАС"`, calls `_makePhoneCall()` (`tel:88005553535`).

#### IncomeCalculatorTab (`lib/screens/calculator_tab.dart`)
* Class: `IncomeCalculatorTab` (lines 4–407).
* Features: Dynamic income calculation based on country rates, transport type (Auto, Bike, Walk), days/week slider, hours/day slider, and referral bonus counter.
* Top display shows calculated monthly income in animated bold digits (e.g. `"152 000 ₽"`).
* **Conversion Gap:** Lacks any direct CTA button to start registration from this tab.

#### ChatTabContent (`lib/screens/chat/chat_tab.dart`)
* Class: `ChatTabContent` (lines 6–58), `_NicknameScreen` (lines 60–168), `_ChatContent` (lines 170–372).
* Stores courier nickname in `SharedPreferences`, listens to Firestore `chat` collection.

#### LocalPushService (`lib/services/local_push_service.dart`)
* Class: `LocalPushService` (lines 7–135).
* Triggered in `PermissionScreen._requestPermission()`. Schedules up to 20 local push notifications spaced every 3 hours (suppressing 22:00–08:00 night hours).
* Notification messages focus on funnel activation: `"Вы прошли регистрацию?"`, `"Вы собрали доки для регистрации?"`, `"Вы записались на выдачу рюкзака и формы?"`, `"Очень много заказов, нужны курьеры. Кэфы горят! 🔥"`.

---

## 3. Conversion Funnel Audit & Friction Points Summary

| # | Component / Screen | Exact File Path & Lines | Current Implementation | Identified Friction Point / Conversion Gap | Impact Level |
|---|---|---|---|---|---|
| **1** | **Funnel Depth** | `lib/screens/main_screen.dart` -> `prelanding_screen.dart` -> `country_screen.dart` -> `stat_webview_screen.dart` | User must click through 4 sequential screens (Main -> Prelanding -> Country -> Rating -> WebView) | **Excessive Steps Before Web Registration:** 4–5 manual interactions before reaching the partner form causing candidate drop-off. | **HIGH** |
| **2** | **Income Calculator CTA** | `lib/screens/calculator_tab.dart` (lines 80–340) | Shows calculated income up to ~200k ₽ and referral bonus, but ends without any action button | **Missing Conversion CTA:** Users who calculate high earnings have no direct button to apply and must figure out how to navigate back to Tab 0. | **HIGH** |
| **3** | **In-App Review Timing** | `lib/screens/onboarding/country_screen.dart` (lines 66–68) | `_showRating()` (`inAppReview`) is called immediately after country tap before opening WebView | **Premature Rating Interruption:** Requesting an app review before candidate completes registration breaks conversion momentum. | **MEDIUM** |
| **4** | **CTA Microcopy Consistency** | `main_screen.dart:242`<br>`prelanding_screen.dart:166`<br>`permission_screen.dart:95`<br>`quiz_screen.dart:243` | Buttons use varying labels: `"ПОДКЛЮЧИТЬСЯ"`, `"СТАТЬ КУРЬЕРОМ"`, `"РАЗРЕШИТЬ"`, `"ПОЗВОНИТЬ СЕЙЧАС"` | **Inconsistent Action Cue:** Changing button text across screens reduces brand/intent alignment. | **MEDIUM** |
| **5** | **Banner & Value Prop Urgency** | `lib/screens/main_screen.dart` (lines 191–226) | Static banner image (`assets/main_banner.png`) + basic subtitle `"Доставляйте заказы..."` | **Lack of Trust & Urgency Signals:** Missing income guarantees (e.g. "До 150 000 ₽/мес"), daily payout badges, or "Places limited today" urgency triggers. | **MEDIUM** |
| **6** | **Main CTA Tactile Feedback** | `lib/screens/main_screen.dart` (lines 231–249) | `ElevatedButton` has `onPressed: onAction` without explicit `HapticFeedback` | **Lack of Tactile Feedback:** Unlike bottom nav and country list, main button lacks haptic click response. | **LOW** |

---

## 4. Recommendations for Conversion Rate Optimization (CRO)

1. **Direct Fast-Track Registration on Main Screen:**
   * Allow clicking a transport card or primary CTA on `MainScreen` to jump directly to `CountryScreen` or open `StatWebViewScreen` if country is already selected in `SharedPreferences`.
2. **Add "Стать курьером" Sticky CTA to Income Calculator:**
   * Place a prominent yellow `ElevatedButton` (`"ОФОРМИТЬСЯ НА [INCOME] ₽"`) at the bottom of `IncomeCalculatorTab` (around line 335) that triggers the onboarding/registration flow with calculated parameters.
3. **Defer Rating Prompt Post-Conversion:**
   * Move `inAppReview.requestReview()` to trigger only after the user returns from `StatWebViewScreen` or completes the `QuizScreen`.
4. **Unify CTA Wording & Add Urgency Badges:**
   * Standardize primary CTA text across screens to `"СТАТЬ КУРЬЕРОМ ЕДАGO"`.
   * Add a visual badge on `MainTabContent` above the main button (e.g. `"🔥 Доход до 150 000 ₽ • Выплаты каждый день"`).
5. **Add Tactile Feedback & Micro-animations:**
   * Add `HapticFeedback.mediumImpact()` to `MainTabContent` button clicks.
