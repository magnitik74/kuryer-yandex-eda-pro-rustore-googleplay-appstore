# Handoff Report — fast_courier_app Audit

## 1. Observation
Direct codebase analysis of `fast_courier_app` (`d:\projects\Eda_Go_Rustor_GooglePM\fast_courier_app\`) yielded the following observations:
- **Version & Dependencies (`pubspec.yaml`)**:
  - App version `3.5.0+21` (line 4).
  - SDK: `>=3.6.0 <4.0.0` (line 7).
  - Dependencies (lines 9-27): `flutter`, `cupertino_icons`, `in_app_review`, `firebase_core`, `firebase_messaging`, `firebase_analytics`, `shared_preferences`, `provider`, `flutter_rustore_review: 10.0.0`, `cloud_firestore`, `webview_flutter`, `url_launcher`, `intl`, `flutter_local_notifications`, `timezone`, `country_flags: ^3.2.0`.
- **Navigation & Startup (`lib/main.dart`)**:
  - Line 91-107: `_initApp()` calls `await LocalPushService().init();`, delays 2000 ms, then unconditionally navigates to `PermissionScreen()`. No `SharedPreferences` persistent onboarding flag check exists.
  - Lines 29-46: `ThemeData` uses `seedColor: Color(0xFFFCE000)`, `scaffoldBackgroundColor: Color(0xFFF7F7F7)`, `useMaterial3: true`. No dark mode/theme switching configured.
- **Local Notifications (`lib/services/local_push_service.dart`)**:
  - Lines 57-107: `scheduleFunnelNotifications()` schedules 20 local notifications with texts ("Вы прошли регистрацию?", "Вы собрали доки...", "Вы записались...", "Очень много заказов..."). Pushes scheduled between 22:00 and 08:00 are shifted to 08:00 (+0-30 min delay).
- **Push & Remote Messaging (`lib/screens/onboarding/permission_screen.dart`)**:
  - Line 10-19: Calls `FirebaseMessaging.instance.requestPermission()`. No `onMessage` or `onBackgroundMessage` handlers exist anywhere in `lib/`.
- **Chat & Storage (`lib/screens/chat/chat_tab.dart`)**:
  - Lines 24-45: Uses `SharedPreferences.getInstance()` to read/write `nickname`. Real-time messaging uses `FirebaseFirestore.instance.collection('chat')`.
- **Country Selector & Cloaking (`lib/screens/onboarding/country_screen.dart`)**:
  - Lines 40-58: Checks Firestore `testAdmin/showTest`. Branching checks `Platform.isIOS` for `test_ios` vs `test` field to direct to `QuizScreen` or `StatWebViewScreen`.
- **Candidate Survey (`lib/screens/onboarding/quiz_screen.dart`)**:
  - Lines 62-70: Calls `url_launcher` `launchUrl(Uri(scheme: 'tel', path: '88005553535'))` on finish screen.
- **Analytics**:
  - Zero calls to `FirebaseAnalytics.instance.logEvent()` in any file in `lib/`.

## 2. Logic Chain
1. **Observation**: `pubspec.yaml` lists `firebase_analytics`, `firebase_messaging`, and `provider`.
   **Reasoning**: These libraries were added during project setup, but examination of `lib/` shows zero calls to `FirebaseAnalytics`, no FCM background/foreground message handlers, and no state management providers wrapping widgets in `main.dart`.
   **Conclusion**: Features for FCM push handling, analytics conversion tracking, and state management are scaffolding/incomplete.

2. **Observation**: `main.dart` `_initApp()` unconditionally opens `PermissionScreen()`.
   **Reasoning**: Every app cold start forces the user into `PermissionScreen()`, which then navigates to `MainScreen()`. `SharedPreferences` is only checked inside `ChatTabContent` for nickname and `CountryScreen` for region ref code.
   **Conclusion**: Onboarding state persistence is absent in the app launch lifecycle.

3. **Observation**: Colors are defined inline as `#FCE000` (yellow), `#211B15` (charcoal), and `#F7F7F7` (grey), and `ThemeData` only specifies light scaffold background.
   **Reasoning**: Colors are duplicated across individual screen files rather than centralized in a theme palette module, and no `darkTheme` configuration is passed to `MaterialApp`.
   **Conclusion**: App styling is currently locked to a hardcoded light theme with custom inline color constants.

4. **Observation**: `LocalPushService` handles 20 funnel pushes with night deferral logic, but has no hook to cancel when registration completes.
   **Reasoning**: The notification engine runs on a static schedule without observing user actions (e.g. completing `QuizScreen` or opening `StatWebViewScreen`).
   **Conclusion**: Local push funnel is static and uncoupled from real-time retention triggers.

## 3. Caveats
- Android native manifest (`android/app/src/main/AndroidManifest.xml`) and iOS Info.plist (`ios/Runner/Info.plist`) were not audited for background mode permissions or custom channel metadata, as investigation focused on Dart architecture and technical hooks in `lib/`.
- Live Firebase Firestore database rules and `testAdmin/showTest` document values were not queried directly via network (Code-Only mode restriction).

## 4. Conclusion
`fast_courier_app` (`v3.5.0+21`) has a clean foundation for courier recruitment with working local push funnel scheduling, a multi-country income calculator, Firestore public chat, candidate quiz, and review-cloaking webview navigation. To prepare for upcoming version releases (v3.6 through v4.0), the project requires:
- **v3.6**: Persistent onboarding state check in `main.dart` & `Provider` state management.
- **v3.7**: FCM remote message handlers & `FirebaseAnalytics` event logging across conversion funnel.
- **v3.8**: Daily streak retention service & referral link share triggers.
- **v4.0**: Dynamic Dark Mode theme support & centralized `AppColors`/`AppTheme` refactoring.

All detailed findings, code references, and technical integration roadmaps are saved in:
`D:\projects\Eda_Go_Rustor_GooglePM\fast_courier_app\.agents\teamwork_preview_explorer_m1_3\analysis.md`

## 5. Verification Method
- **File Inspection**:
  - `lib/main.dart` — Check `_initApp()` navigation logic.
  - `lib/services/local_push_service.dart` — Inspect notification funnel scheduling.
  - `lib/screens/onboarding/country_screen.dart` — Inspect platform branching for App Store moderation cloak.
  - `pubspec.yaml` — Verify current version (`3.5.0+21`) and dependencies.
- **Build / Test Verification**:
  - Run `flutter test` in `D:\projects\Eda_Go_Rustor_GooglePM\fast_courier_app` to verify widget tests baseline.
- **Invalidation Conditions**:
  - Adding persistent onboarding checks to `main.dart` invalidates the observation that returning users see `PermissionScreen` on every launch.
  - Adding `FirebaseAnalytics.instance.logEvent()` calls invalidates the missing analytics finding.
