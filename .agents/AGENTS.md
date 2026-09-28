# Правила проекта и архитектура

## Package Names
- **Google Play and RuStore (Android):** fast.courier.job

## Дизайн и Конверсия
- Цель №1 — МАКСИМАЛЬНАЯ КОНВЕРСИЯ и доходимость до реферальной ссылки.
- ЗАПРЕЩЕНО добавлять лишние клики или экраны перед целевой кнопкой.
- Онбординги и прелендинги должны быть на одном экране.

## Архитектура оценки приложения (RatingService) — ОБЯЗАТЕЛЬНОЕ ПРАВИЛО

Оценка реализуется ТОЛЬКО через RatingService (lib/services/rating_service.dart).

### Логика (Review Gate):
1. Сначала показываем СВОЙ кастомный диалог со звёздами (не нативный).
2. Оценка 1-3 звезды -> тихо сохраняем в Firebase (коллекция ratings), показываем Спасибо, НЕ открываем стор.
3. Оценка 4-5 звезд -> открываем НАТИВНОЕ окно стора.

### Нативные окна (изолированы по сборкам):
- RuStore (STORE=rustore) -> строго `review_rustore.dart` (RustoreReviewClient)
- Google Play (STORE=googleplay) -> строго `review_googleplay.dart` (InAppReview)

### ЗАПРЕЩЕНО:
- Вызывать нативный диалог оценки напрямую без кастомного диалога.
- Отправлять оценки 1-3 в стор.
- Смешивать вызовы отзывов: сборка RuStore никогда не должна вызывать Google Play, а Google Play никогда не должен вызывать RuStore.

## Сборка Релизов (Build Outputs)
- Всегда собирайте 2 варианта для Android: `.apk` (для RuStore) и `.aab` (для Google Play).
- Сборка выполняется скриптом `build_releases.ps1`.
- Итоговые файлы раскладываются по изолированным папкам в корне:
  - `releases\RuStore\fast_courier_rustore.apk`
  - `releases\GooglePlay\fast_courier_googleplay.aab`

## Управление Firebase (Прямой доступ через Service Account)
Агент может управлять Firebase проектом `courier-f5652` напрямую через скрипт `D:\projects\tools\firebase_manager\manage_firebase.js`:
- Посмотреть статус модерации и ссылки:
  `node D:\projects\tools\firebase_manager\manage_firebase.js status`
- Переключить режим Google Play (0 - рефералки, 1 - модерация):
  `node D:\projects\tools\firebase_manager\manage_firebase.js set-googleplay 0` (или 1)
- Переключить режим RuStore:
  `node D:\projects\tools\firebase_manager\manage_firebase.js set-rustore 0` (или 1)
- Изменить любое поле в `testAdmin/showTest`:
  `node D:\projects\tools\firebase_manager\manage_firebase.js set <fieldName> <value>`


