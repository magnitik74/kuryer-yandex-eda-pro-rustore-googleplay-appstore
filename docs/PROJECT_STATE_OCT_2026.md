# Фиксация состояния проекта: «Курьер PRO Еда» и всей экосистемы репозиториев

**Дата обновления:** 1 октября 2026 г.  
**Основной аккаунт:** `magnitik74`  
**Статус экосистемы:** 100% порядок, единый стандарт именования, полные описания на русском языке, настроенные теги.

---

## 1. Карта репозиториев на GitHub (`magnitik74`)

Все репозитории выстроены в единую стройную систему:

| # | Имя репозитория | Доступ | Стек | Роль в проекте |
| :--- | :--- | :--- | :--- | :--- |
| 1 | **`kuryer-yandex-eda-pro-rustore-googleplay-appstore`** | Private | Flutter / Dart | **Главный флагман** (RuStore + Google Play + App Store) |
| 2 | **`kuryer-pro-eda-ios`** | Private | Swift / Xcode | **Нативная iOS-сборка** под Apple App Store |
| 3 | **`kuryer-dostavka-pro-android`** | Private | TypeScript / Expo | **Android-клиент** сервиса доставки и грузовых тарифов |
| 4 | **`kuryer-pro-eda-web-portal`** | Private | HTML / JS | **Мультирегиональный веб-портал** привлечения курьеров (СНГ) |
| 5 | **`privacy-policy`** | Public | HTML / CSS | **Юридический хаб** (GitHub Pages для модерации в маркетах) |

---

## 2. Подробная информация по каждому репозиторию

### 1. `kuryer-yandex-eda-pro-rustore-googleplay-appstore`
* **URL:** `https://github.com/magnitik74/kuryer-yandex-eda-pro-rustore-googleplay-appstore`
* **Видимость:** Private
* **Стек:** Flutter / Dart / Firebase
* **Теги (Topics):** `flutter`, `dart`, `rustore`, `google-play`, `app-store`, `courier`, `yandex-eda`
* **Описание:** 
  > Курьер PRO Еда — Флагманское кроссплатформенное приложение (Flutter). Калькулятор заработка, ИИ-куратор GigaChat, онбординг, мультиязычность СНГ и сборки для RuStore, Google Play и App Store.

### 2. `kuryer-pro-eda-ios` *(бывший `pro-eda-ios-`)*
* **URL:** `https://github.com/magnitik74/kuryer-pro-eda-ios`
* **Видимость:** Private
* **Стек:** Swift / Xcode / Codemagic
* **Теги (Topics):** `ios`, `swift`, `xcode`, `app-store`, `courier`, `yandex-eda`
* **Описание:** 
  > Курьер PRO Еда (iOS) — Нативное мобильное приложение для курьеров Яндекс Еда под Apple iOS (Swift / Xcode). Подготовка к публикации в App Store.

### 3. `kuryer-dostavka-pro-android` *(бывший `dostavka-pro-android`)*
* **URL:** `https://github.com/magnitik74/kuryer-dostavka-pro-android`
* **Видимость:** Private
* **Стек:** TypeScript / React Native / Expo (package `com.fastjob.dostavka.gruzovoi`)
* **Теги (Topics):** `android`, `expo`, `react-native`, `typescript`, `yandex-dostavka`
* **Описание:** 
  > Доставка ПРО (Android) — Мобильное приложение сервиса курьерской доставки и грузовых перевозок Яндекс Еда / Доставка (React Native / Expo).

### 4. `kuryer-pro-eda-web-portal` *(бывший `pro-eda-portal`)*
* **URL:** `https://github.com/magnitik74/kuryer-pro-eda-web-portal`
* **Видимость:** Private
* **Стек:** HTML5 / CSS3 / JavaScript (региональные лендинги: `/ru/`, `/kz/`, `/uz/`, `/kg/`, `/by/`)
* **Теги (Topics):** `courier`, `cpa`, `landing-page`, `web`, `yandex-eda`
* **Описание:** 
  > Курьер PRO Еда (Web Portal) — Мультирегиональный веб-портал партнёрской программы привлечения курьеров (РФ, Казахстан, Узбекистан, Кыргызстан, Беларусь).

### 5. `privacy-policy` *(Имя сохранено для стабильности ссылок в маркетах)*
* **URL репозитория:** `https://github.com/magnitik74/privacy-policy`
* **Публичный сайт (GitHub Pages):** `https://magnitik74.github.io/privacy-policy/` (страницы `index.html` и `support.html`)
* **Видимость:** Public
* **Теги (Topics):** `github-pages`, `privacy-policy`, `support`, `terms-of-service`
* **Описание:** 
  > Курьер PRO Еда: Legal & Support — Официальная Политика Конфиденциальности, Условия использования и Служба поддержки для RuStore, Google Play и App Store (GitHub Pages).

---

## 3. Сторонние проекты (профиль `magnit74`)

Репозитории также приведены в порядок и снабжены точными описаниями:
1. **`magnit74/120_80_bp_tracker`**  
   *Описание:* `120/80 BP Tracker — Мобильное приложение для трекинга артериального давления и пульса (React Native / Expo)`
2. **`magnit74/fcn-novostroek`**  
   *Описание:* `ФЦН Новостройки — Мобильный каталог жилых комплексов и подбора недвижимости (React Native / Expo)`

---

## 4. Локальная синхронизация на ПК

- Локальный Git Remote в проекте `D:\projects\Eda_Go_Rustor_GooglePM\fast_courier_app`:
  - `origin`: `https://github.com/magnitik74/kuryer-yandex-eda-pro-rustore-googleplay-appstore.git`
  - Токен доступа: сохранён и настроен непосредственно для аккаунта `magnitik74`.
  - Все будущие `git push` и `git pull` выполняются мгновенно без паролей и ошибок.
