# Раздельные рубильники модерации (Split Moderation)

Эта фича была запланирована, но отложена. Когда пользователь произнесет кодовое слово (например, "Раздельные рубильники"), нужно реализовать этот план.

## Цель
Заменить единый флаг `test` в Firebase на три независимых флага для каждого стора:
- `test_ios`
- `test_googleplay`
- `test_rustore`

## Реализация

1. **Модификация скриптов сборки**:
   - В файле `build_releases.ps1` нужно добавить флаги `--dart-define=STORE=rustore` при сборке APK и `--dart-define=STORE=googleplay` при сборке AAB.
   - (Если Codemagic тоже собирает Android, обновить `codemagic.yaml` соответствующим образом. Сейчас он собирает только iOS).

2. **Модификация Dart кода**:
   - В файле `lib/screens/onboarding/country_screen.dart` (и везде, где проверяется Firebase Remote Config/Firestore для модерации).
   - Логика проверки:
     ```dart
     int testValue = 0;
     if (Platform.isIOS) {
         testValue = data['test_ios'] ?? 0;
     } else {
         const String store = String.fromEnvironment('STORE', defaultValue: 'googleplay');
         if (store == 'rustore') {
             testValue = data['test_rustore'] ?? 0;
         } else {
             testValue = data['test_googleplay'] ?? 0;
         }
     }
     ```

После реализации попросить пользователя создать эти три поля в Firebase.
