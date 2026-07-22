# Architecture, Styling, Retention & Integration Audit: fast_courier_app

## Executive Summary
`fast_courier_app` is a Flutter application (version `3.5.0+21`, Flutter SDK `>=3.6.0 <4.0.0`) designed to recruit and onboarding food delivery couriers across 5 CIS regions (RU, KZ, UZ, BY, KG). The codebase is structured simply without state management providers (despite `provider` being declared in `pubspec.yaml`). Theme styling uses a yellow/charcoal/grey palette (`#FCE000`, `#211B15`, `#F7F7F7`) with Material 3 widgets styled to mimic iOS design patterns. While local notification funnels are implemented via `flutter_local_notifications`, persistent onboarding state checks, FCM event handlers, custom Firebase analytics logging, daily streak/retention mechanisms, dark mode, and Cupertino native widgets are currently missing or unintegrated.

---

## 1. Codebase & Directory Structure

```
lib/
├── firebase_options.dart               # Auto-generated Firebase platform config
├── main.dart                           # Entry point, Firebase init, MyApp theme, InitializationScreen splash
├── services/
│   └── local_push_service.dart         # Local notification scheduling (20 funnel pushes with night quiet hours)
└── screens/
    ├── main_screen.dart                # Main screen container: 4-tab bottom navigation (Home, FAQ, Income, Chat)
    ├── calculator_tab.dart             # Income Calculator (5 countries, 3 transport modes, referral bonus counter)
    ├── chat/
    │   └── chat_tab.dart               # Firestore real-time courier chat with SharedPreferences nickname persistence
    └── onboarding/
        ├── permission_screen.dart      # FCM notification permission prompt & funnel notification trigger
        ├── prelanding_screen.dart      # 3-step value proposition pre-landing screen with pulsing CTA
        ├── country_screen.dart         # Country selector with Firestore review cloak logic (test vs test_ios)
        ├── quiz_screen.dart            # Candidate survey (4 questions) & completion screen with direct dial button
        └── stat_webview_screen.dart    # Partner registration webview using webview_flutter
```

### Key Dependencies (`pubspec.yaml`)
- `firebase_core`, `firebase_messaging`, `firebase_analytics`, `cloud_firestore`
- `flutter_local_notifications`, `timezone`
- `shared_preferences`, `provider` (declared but unutilized in UI code)
- `in_app_review`, `flutter_rustore_review: 10.0.0`
- `webview_flutter`, `url_launcher`, `intl`, `country_flags: ^3.2.0`

---

## 2. Theme Definitions, Color Palette & UI Elements

### Color Palette
- **Yellow Accent**: `Color(0xFFFCE000)` — Primary action color, button backgrounds, active navigation tab bubble background (`0xFFFCE000` with 0.2 opacity), slider thumb, progress indicators, adaptive icon background.
- **Dark Charcoal / Black**: `Color(0xFF211B15)` — AppBar titles, primary text headers, dark backdrop screens (`PermissionScreen`), dark CTA buttons (`_NicknameScreen`), active transport button background.
- **Grey Shades**:
  - Scaffold / App Background: `Color(0xFFF7F7F7)` & `Color(0xFFF5F5F7)` ("Premium iOS grey").
  - Card / Input Fill: `Color(0xFFFFFFFF)` & `Color(0xFFF7F7F7)`.
  - Header accents: `Color(0xFFF5F0E8)` (Calculator header background), `Color(0xFFEFEBE4)` (Chat wallpaper).
  - Muted Text: `Color(0xFF8A8A8E)`, `Color(0xFF8A7D6B)`, `Color(0xFFAAAAAA)`.

### Dark Mode vs Light Mode
- **Current State**: No dynamic theme mode or dark theme configuration. `ThemeData` is hardcoded for light mode (`scaffoldBackgroundColor: Color(0xFFF7F7F7)`, white `appBarTheme`).
- **Inconsistencies**: `PermissionScreen` uses `backgroundColor: Color(0xFF211B15)` and `PrelandingScreen` uses `Color(0xFF211B15)` for its header container, creating ad-hoc dark sections while the core scaffold remains light.

### Cupertino vs Material Elements & iOS Adaptations
- **Material 3 Usage**: The app uses `MaterialApp` (`useMaterial3: true`), `Scaffold`, `ElevatedButton`, `TextButton`, `DropdownButton`, `Slider`, `ListView`. No `CupertinoApp` or `Cupertino` widgets are imported or instantiated directly.
- **Custom iOS Visual Adaptations**:
  - Bottom Bar (`_buildPremiumBottomBar()`): Custom white container with top shadow (`BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: Offset(0, -4))`), animated tab item scale (`Matrix4.identity()..scale(isActive ? 1.15 : 1.0)`), and glowing active indicator.
  - Haptic Feedback: Integrated iOS haptics (`HapticFeedback.lightImpact()`, `HapticFeedback.mediumImpact()`, `HapticFeedback.selectionClick()`) across tab changes, button taps, and card transitions.
  - Platform Cloaking: `CountryScreen` inspects `Platform.isIOS` to select `test_ios` vs `test` Firestore flags for Apple App Store guidelines compliance.

---

## 3. Notifications, Onboarding, Retention & Analytics Audit

| Feature | Status | Implementation Details & Gaps |
|---|---|---|
| **Local Notifications** | **Implemented** | `LocalPushService` schedules a 20-push funnel using `flutter_local_notifications`. Rotates through 4 recruitment messages every 3 hours (+15 mins for push #1). Automatically defers night pushes (22:00-08:00) to 08:00 (+0-30 min random noise). |
| **Push Notifications (FCM)** | **Partial (Missing Handlers)** | `firebase_messaging` is imported and `FirebaseMessaging.instance.requestPermission()` is called on `PermissionScreen`. However, foreground listeners (`onMessage`), background message handlers (`onBackgroundMessage`), topic subscriptions, and FCM token retrieval are missing. |
| **Onboarding State** | **Missing Flow Control** | `SharedPreferences` saves `nickname`, `countryRef`, and `countryId`. However, `main.dart` (`InitializationScreen`) always delays 2 seconds and hard-navigates to `PermissionScreen()`. There is no stored `hasCompletedOnboarding` flag to bypass permissions/prelanding for returning users. |
| **Retention Mechanisms** | **Missing** | No daily streak counter, daily check-in rewards, inactive user return triggers, or gamification badges. Retention currently relies solely on static local push notifications. |
| **Analytics** | **Missing Integration** | `firebase_analytics` dependency is declared in `pubspec.yaml`, but zero event logging calls (`FirebaseAnalytics.instance.logEvent()`) exist in the application code. Conversion funnel steps are untracked. |

---

## 4. Technical Integration Roadmap (v3.6 - v4.0)

### Version 3.6 — Persistence, State Management & Navigation Flow
- **Goal**: Prevent redundant onboarding screens for existing users and centralize app state.
- **Integration Points**:
  - `lib/main.dart` (`_initApp()`): Read `SharedPreferences` flag `has_seen_onboarding`. Route returning users directly to `MainScreen()`.
  - `lib/providers/app_state_provider.dart`: Introduce `Provider` (already in `pubspec.yaml`) to hold user profile, country selection, registration step, and push settings.
  - `lib/services/local_push_service.dart`: Add `cancelFunnelIfRegistered()` to halt funnel pushes once candidate completes registration.

### Version 3.7 — FCM Remote Push & Full Funnel Analytics
- **Goal**: Enable remote push campaign management and end-to-end user conversion tracking.
- **Integration Points**:
  - `lib/services/fcm_service.dart`: Create dedicated FCM service initializing `FirebaseMessaging.onMessage`, `onMessageOpenedApp`, and `onBackgroundMessage`. Forward payload to `LocalPushService`.
  - `lib/services/analytics_service.dart`: Implement wrapper for `FirebaseAnalytics`.
  - Screen Hooks: Log events for `app_open`, `permission_granted`, `permission_denied`, `prelanding_cta_click`, `country_selected`, `quiz_started`, `quiz_completed`, `call_operator_click`, `webview_opened`, `chat_message_sent`.

### Version 3.8 — Gamification & Retention Engine (Daily Streak & Referrals)
- **Goal**: Drive daily active courier engagement and viral referral acquisition.
- **Integration Points**:
  - `lib/services/retention_service.dart`: Track `last_active_timestamp` and `consecutive_days_streak` in `SharedPreferences`.
  - `lib/screens/main_screen.dart` (`MainTabContent`): Add a "Daily Streak" banner widget showing current streak days and multiplier bonus.
  - `lib/screens/calculator_tab.dart`: Add "Share Referral Link" button integrated with `url_launcher` and system share sheet.
  - `lib/services/local_push_service.dart`: Schedule "Streak at risk!" local push notification if user has not opened app for 20 hours.

### Version 4.0 — Adaptive Cupertino Engine & Dark Theme Support
- **Goal**: Full iOS native widget parity and automatic dark mode support.
- **Integration Points**:
  - `lib/theme/app_theme.dart` & `app_colors.dart`: Refactor inline hardcoded colors into centralized palette (`AppColors.yellow`, `AppColors.charcoal`, `AppColors.surfaceLight`, `AppColors.surfaceDark`).
  - `lib/main.dart`: Supply `theme` and `darkTheme` to `MaterialApp` with `themeMode: ThemeMode.system`.
  - Platform Adaptation: Replace custom Material wrappers with `CupertinoSegmentedControl` for transport choices and `CupertinoAlertDialog` / `CupertinoPageScaffold` when running on iOS (`Platform.isIOS`).

---

## 5. Verification & Audit Sign-Off
- Codebase inspected: 11 Dart files in `lib/` directory reviewed line-by-line.
- Project metadata: `pubspec.yaml` and `codemagic.yaml` verified.
- Evidence chain: All conclusions backed by exact file paths and code snippets.
