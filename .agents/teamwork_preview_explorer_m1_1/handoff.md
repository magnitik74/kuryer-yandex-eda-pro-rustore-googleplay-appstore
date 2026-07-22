# Handoff Report — Conversion Funnel Audit (`fast_courier_app`)

## 1. Observation
Direct evidence gathered from analyzing `fast_courier_app` codebase files:

- **App Initialization & Route Path**:
  - `lib/main.dart`: `InitializationScreen` (lines 52–144) delays 2000 ms, calls `LocalPushService().init()`, then transitions to `PermissionScreen` (lines 97–105).
  - `lib/screens/onboarding/permission_screen.dart`: `_requestPermission` (lines 9–25) requests Firebase messaging permissions, calls `LocalPushService().scheduleFunnelNotifications()`, then navigates to `MainScreen`.
- **Main Dashboard & CTA Elements**:
  - `lib/screens/main_screen.dart`:
    - `MainTabContent` (lines 179–267) contains primary CTA button `"ПОДКЛЮЧИТЬСЯ"` at lines 228–250 (`ElevatedButton`, background `Color(0xFFFCE000)`, text color `Color(0xFF211B15)`).
    - Lines 251–258 contain 4 `_TransportCard` widgets ("Пеший курьер", "Велокурьер", "Автокурьер", "На самокате").
    - Clicking any of these triggers `onAction` -> `_startOnboarding()` (lines 18–30), which opens `PrelandingScreen`.
- **Prelanding Screen CTA**:
  - `lib/screens/onboarding/prelanding_screen.dart`:
    - CTA button `"СТАТЬ КУРЬЕРОМ"` at lines 142–177 (`ElevatedButton` inside pulsing `_scaleAnimation`).
    - Clicking button executes `_next()` (lines 74–79), which navigates to `CountryScreen`.
- **Country Selection & Partner Link Routing**:
  - `lib/screens/onboarding/country_screen.dart`:
    - Country selection at lines 150–213 supports 5 countries (`ru`, `kz`, `uz`, `by`, `kg`).
    - `_handleCountrySelection` (lines 29–84) saves `countryRef` to `SharedPreferences`, queries Firestore `testAdmin/showTest`.
    - If `testValue != 1`, calls `_showRating()` (`inAppReview.requestReview()`) and opens `StatWebViewScreen(url: url)` (line 68) with partner referral URL (`refRU`, `refKZ`, etc.).
    - If `testValue == 1` or URL missing, opens `QuizScreen` (line 70).
- **Secondary Screens & Services**:
  - `lib/screens/onboarding/stat_webview_screen.dart`: Loads partner URL in `WebViewWidget` (lines 62–68).
  - `lib/screens/onboarding/quiz_screen.dart`: Candidate survey ending in `_buildFinishedScreen` (lines 195–258) with `"ПОЗВОНИТЬ СЕЙЧАС"` CTA to phone `88005553535`.
  - `lib/screens/calculator_tab.dart`: Interactive income calculator (lines 4–407) with sliders and referral bonus counter, but lacks any CTA button.
  - `lib/services/local_push_service.dart`: Schedules 20 local pushes every 3 hours (lines 60–107).

---

## 2. Logic Chain

1. **Step 1 (Observation: `lib/main.dart`, `permission_screen.dart`, `main_screen.dart`, `prelanding_screen.dart`, `country_screen.dart`):** Candidate must navigate through Initialization -> Permission -> MainScreen -> PrelandingScreen -> CountryScreen -> Rating Dialog -> StatWebViewScreen.
   - *Inference:* The conversion funnel has 5 distinct interaction layers before presenting the actual partner web registration form. In mobile user acquisition, each additional step reduces conversion by 15-30%.

2. **Step 2 (Observation: `lib/screens/calculator_tab.dart` lines 80-340):** The `IncomeCalculatorTab` calculates monthly earnings (e.g. 150k+ ₽) and referral bonuses, engaging users at high commercial intent. However, it contains zero CTA buttons or navigation triggers.
   - *Inference:* Interested users who spend time calculating income are left at a dead end on Tab 2 and must manually navigate back to Tab 0 to find a registration button, causing high intent leakage.

3. **Step 3 (Observation: `lib/screens/onboarding/country_screen.dart` lines 66-68):** `_showRating()` calls `inAppReview.requestReview()` immediately upon country selection *before* pushing `StatWebViewScreen`.
   - *Inference:* Prompting candidates for an app store review prior to completing courier registration interrupts the conversion momentum with a native system popup.

4. **Step 4 (Observation: `main_screen.dart:242`, `prelanding_screen.dart:166`, `quiz_screen.dart:243`):** CTA text varies between `"ПОДКЛЮЧИТЬСЯ"`, `"СТАТЬ КУРЬЕРОМ"`, `"ПОЗВОНИТЬ СЕЙЧАС"`.
   - *Inference:* Inconsistent CTA microcopy across screens reduces visual expectation and intent clarity.

---

## 3. Caveats
- Firestore Remote Config document `testAdmin/showTest` content and live referral URLs (`refRU`, `refKZ`, etc.) are hosted on Firebase and were not dynamically fetched during static audit.
- iOS `inAppReview` behavior depends on StoreKit quotas and operating system state.
- No source code modifications were performed during this audit (read-only investigation).

---

## 4. Conclusion
The `fast_courier_app` recruitment conversion funnel is structurally sound and includes key onboarding assets (interactive income calculator, country-based referral link routing, push notification re-engagement). However, conversion efficiency is degraded by:
1. Multi-step funnel friction (4-5 steps prior to WebView registration).
2. A complete absence of conversion CTAs on the high-intent `IncomeCalculatorTab`.
3. Premature rating dialog interruption during country selection.
4. CTA microcopy fragmentation across screens.

---

## 5. Verification Method
To independently verify these findings:
1. Inspect `lib/screens/main_screen.dart` lines 228–250 (`MainTabContent` CTA button `"ПОДКЛЮЧИТЬСЯ"`).
2. Inspect `lib/screens/onboarding/prelanding_screen.dart` lines 142–177 (`PrelandingScreen` CTA button `"СТАТЬ КУРЬЕРОМ"`).
3. Inspect `lib/screens/onboarding/country_screen.dart` lines 29–84 (`_handleCountrySelection` routing logic to `StatWebViewScreen` vs `QuizScreen`).
4. Inspect `lib/screens/calculator_tab.dart` lines 1–407 to confirm absence of any `ElevatedButton` or CTA.
5. Verification analysis report saved at: `D:\projects\Eda_Go_Rustor_GooglePM\fast_courier_app\.agents\teamwork_preview_explorer_m1_1\analysis.md`.
