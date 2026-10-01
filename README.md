<div align="center">

<img src="assets/courier_pro_hero_banner.jpg" alt="Курьер PRO Еда Banner" width="100%" />

# ⚡ Курьер PRO Еда

### Флагманское кроссплатформенное приложение для курьеров-партнёров Яндекс Еда
**RuStore • Google Play • Apple App Store • Web**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![RuStore](https://img.shields.io/badge/RuStore-Verified-0077FF?style=for-the-badge)](https://rustore.ru)
[![Google Play](https://img.shields.io/badge/Google_Play-Ready-34A853?style=for-the-badge&logo=googleplay&logoColor=white)](https://play.google.com)
[![App Store](https://img.shields.io/badge/App_Store-Ready-000000?style=for-the-badge&logo=apple&logoColor=white)](https://apple.com/app-store)
[![Live Viewer](https://img.shields.io/badge/Live_Viewer-Salesforce_Enterprise-0176D3?style=for-the-badge&logo=salesforce&logoColor=white)](https://magnitik74.github.io/privacy-policy/sync.html)
[![Dual Cloud](https://img.shields.io/badge/Dual_Cloud-GitHub_%2B_GitVerse-7B2CBF?style=for-the-badge)](https://gitverse.ru/delivery-apps/kuryer-yandex-eda-pro-rustore-googleplay-appstore)

<p align="center" style="font-size: 15px; margin-top: 10px;">
  <a href="https://magnitik74.github.io/privacy-policy/sync.html"><b>🌐 Онлайн-Просмотрщик изменений (24/7)</b></a> &nbsp;•&nbsp;
  <a href="WORKFLOW_MULTI_DEVICE.md"><b>🔄 Инструкция и Чек-лист (ПК + Гермес)</b></a> &nbsp;•&nbsp;
  <a href="https://gitverse.ru/delivery-apps/kuryer-yandex-eda-pro-rustore-googleplay-appstore"><b>🇷🇺 Российское зеркало GitVerse</b></a>
</p>

</div>

---

## 📱 О проекте

**«Курьер PRO Еда»** — высококонверсионное нативное приложение для привлечения, онбординга и консультирования соискателей в сервис Яндекс Еда и Яндекс Доставка. Разработано с фокусом на максимальный CTR партнерских CPA-ссылок в странах СНГ.

<div align="center">
  <img src="assets/app_icon.png" width="160" alt="App Icon" style="border-radius: 36px;" />
  <p><i>Официальная иконка приложения «Курьер PRO Еда»</i></p>
</div>

---

## ✨ Ключевые возможности

* 🚀 **Премиальный 8-шаговый онбординг:** Авторские иллюстрации, интерактивный опрос соискателя, тёмная тема (`#0E0E10`) с фирменным акцентом Яндекс Еды (`#FFDD2D`), типографика **Golos Text**.
* 🤖 **Персональный ИИ-куратор (GigaChat AI):** Встроенный помощник для кандидатов. Автоматически отвечает на вопросы о графике, выплатах, транспорте и документах. Выдаёт карточку регистрации только при готовности пользователя.
* 💰 **Калькулятор дохода курьера:** Динамический расчёт заработка в зависимости от типа передвижения (пешком 🚶, велосипед 🚲, авто 🚗, мото 🛵), рабочих часов и дней недели.
* 🌍 **Мультирегиональная CPA-воронка (5 стран):** Поддержка кандидатов из России (RU), Казахстана (KZ), Узбекистана (UZ), Кыргызстана (KG) и Беларуси (BY) с автоматической маршрутизацией реферальных кодов.
* 🛡️ **Zero-Trust Security:** API-ключи нейросети изолированы в серверных Firebase Cloud Functions (`functions/index.js`), клиентский код полностью защищён от реверс-инжиниринга.
* ⭐ **RuStore In-App Review SDK:** Нативная интеграция официального SDK отзывов RuStore для органического роста рейтинга приложения.

---

## 🛠️ Стек технологий

* **Фреймворк:** Flutter (Channel stable)
* **Язык:** Dart 3.x
* **Шрифты:** Golos Text (локальный вариативный ttf)
* **Иконки:** Phosphor Flutter Icons + авторский 3D UI Pack
* **Бэкенд:** Firebase Cloud Functions / Node.js
* **ИИ:** GigaChat API (Сбер) через защищённый шлюз
* **Ревью:** `flutter_rustore_review` 10.0.0

---

## 📁 Структура экосистемы

| Репозиторий | Платформа | Назначение |
| :--- | :--- | :--- |
| **`kuryer-yandex-eda-pro-rustore-googleplay-appstore`** | Flutter | Главный флагман (Android + iOS + Web) |
| **`kuryer-pro-eda-ios`** | Swift | Нативная iOS-сборка под App Store |
| **`kuryer-dostavka-pro-android`** | React Native | Клиент сервиса доставки и грузовых тарифов |
| **`kuryer-pro-eda-web-portal`** | HTML/JS | Международный веб-портал привлечения курьеров |
| **`privacy-policy`** | GitHub Pages | Юридический хаб (Политика конфиденциальности и поддержка) |

---

## 🚀 Запуск и сборка

### Локальный запуск (Debug):
```bash
flutter run
```

### Сборка релизного APK под RuStore:
```bash
flutter build apk --release
```

### Сборка App Bundle (AAB) под Google Play:
```bash
flutter build appbundle --release
```

---

## 🌐 Просмотрщик изменений (Онлайн-Дашборд)

Интерактивный веб-дашборд в корпоративном стиле **Salesforce Agentic Enterprise** для мгновенной проверки кода, синхронизации и diff-изменений между GitHub и GitVerse:

👉 **[Открыть Онлайн-Просмотрщик изменений (24/7)](https://magnitik74.github.io/privacy-policy/sync.html)**

* 🟢 **Монитор синхронизации:** Сравнение хешей коммитов GitHub (США) и GitVerse (РФ) в реальном времени.
* 🔍 **Мгновенный Live Diff:** Кнопки прямого перехода к просмотру изменённых строк кода для каждого коммита.
* 📋 **Интерактивные кнопки копирования:** Быстрый запуск команд `git pull` и `git push`.
* 💻 **Локальная копия:** [`tools/code_sync_viewer.html`](tools/code_sync_viewer.html) (доступна даже без интернета).

---

## 🔄 Инструкция работы с двух устройств (ПК + Гермес)

Подробное руководство и пошаговый чек-лист для параллельной работы без конфликтов и потери кода:

👉 **[Открыть полный Чек-лист: WORKFLOW_MULTI_DEVICE.md](WORKFLOW_MULTI_DEVICE.md)**

### Краткий чек-лист сессии:
* 🌅 **Сел за работу (на ПК или Гермесе):**
  ```bash
  git pull origin main
  ```
* 🌇 **Завершил работу (перед уходом или сменой устройства):**
  ```bash
  git add .
  git commit -m "update: описание прогресса"
  git push origin main
  ```
  *(Команда отправляет изменения **одновременно и в GitHub, и в GitVerse**).*

* 💻 **Настройка Гермеса с нуля (в 3 команды):**
  ```bash
  git clone https://github.com/magnitik74/kuryer-yandex-eda-pro-rustore-googleplay-appstore.git
  cd kuryer-yandex-eda-pro-rustore-googleplay-appstore
  git remote set-url --add --push origin git@gitverse.ru:delivery-apps/kuryer-yandex-eda-pro-rustore-googleplay-appstore.git
  git remote set-url --add --push origin https://github.com/magnitik74/kuryer-yandex-eda-pro-rustore-googleplay-appstore.git
  ```

---

<div align="center">
  <sub>Разработано для экосистемы партнёрских сервисов «Курьер PRO Еда» • 2026</sub>
</div>

