# 🔄 Инструкция по работе с нескольких устройств (ПК + Гермес)
### Зеркальная синхронизация: GitHub (США) + GitVerse (Россия)

Этот документ — твой **главный чек-лист** для ежедневной работы над проектом «Курьер PRO Еда». Следуй ему, чтобы изменения никогда не затирались, не возникало конфликтов веток, а код мгновенно появлялся на всех твоих устройствах.

---

## ⚡ Экспресс-памятка (2 главные команды)

* **Сел за работу:** `git pull origin main`
* **Закончил работу:** `git add . && git commit -m "update: прогресс" && git push origin main`

> [!NOTE]
> Команда `git push origin main` настроена на **двойной параллельный пуш**: она одновременно отправляет изменения и на **GitHub**, и на **GitVerse**.

---

## 🚦 ЧЕК-ЛИСТ 1: Начало рабочей сессии (на ПК или Гермесе)

Каждый раз, когда садишься за работу (на любом компьютере):

- [ ] **1. Открыть терминал** в папке проекта:
  ```bash
  cd D:\projects\Eda_Go_Rustor_GooglePM\fast_courier_app
  ```
- [ ] **2. Скачать последние изменения**, сделанные с другого устройства:
  ```bash
  git pull origin main
  ```
- [ ] **3. Проверить, что рабочая ветка чистая**:
  ```bash
  git status
  ```
  *(Должно быть написано: `nothing to commit, working tree clean`)*
- [ ] **4. Готово!** Можно писать код, запускать Flutter и давать задачи ИИ.

---

## 🏁 ЧЕК-ЛИСТ 2: Завершение рабочей сессии (перед уходом)

Перед тем как выключить компьютер или переключиться на другое устройство:

- [ ] **1. Проверить список изменённых файлов**:
  ```bash
  git status
  ```
- [ ] **2. Добавить все файлы в коммит**:
  ```bash
  git add .
  ```
- [ ] **3. Зафиксировать изменения с понятным описанием**:
  ```bash
  git commit -m "feat: описание того что сделал"
  ```
- [ ] **4. Отправить в ОБА облака (GitHub + GitVerse)**:
  ```bash
  git push origin main
  ```
- [ ] **5. Убедиться, что терминал вывел подтверждение для обоих серверов**:
  ```text
  To gitverse.ru:delivery-apps/kuryer-yandex-eda-pro-rustore-googleplay-appstore.git
  To github.com/magnitik74/kuryer-yandex-eda-pro-rustore-googleplay-appstore.git
  ```
- [ ] **6. Готово!** Теперь код зарезервирован в двух странах, и его можно открыть на любом другом ПК.

---

## 🖥️ ЧЕК-ЛИСТ 3: Первоначальная настройка на Гермесе (с нуля)

Когда ты впервые открываешь проект на Гермесе:

### Шаг 1. Склонировать репозиторий
```bash
git clone https://github.com/magnitik74/kuryer-yandex-eda-pro-rustore-googleplay-appstore.git
cd kuryer-yandex-eda-pro-rustore-googleplay-appstore
```

### Шаг 2. Настроить двойной пуш (Dual Push) на Гермесе
Чтобы Гермес тоже отправлял код сразу в оба облака:
```bash
git remote set-url --add --push origin git@gitverse.ru:delivery-apps/kuryer-yandex-eda-pro-rustore-googleplay-appstore.git
git remote set-url --add --push origin https://github.com/magnitik74/kuryer-yandex-eda-pro-rustore-googleplay-appstore.git
```

### Шаг 3. Проверить настройки пуша:
```bash
git remote -v
```
Должно показать 1 адрес на скачивание (fetch) и 2 адреса на отправку (push: gitverse + github).

---

## 🔍 Инструмент: Страница-просмотрщик синхронизации (Code & Sync Viewer)

В проект встроен интерактивный дашборд для мгновенной проверки изменений:

### Как открыть:
1. **Способ 1 (через локальный сервер):**
   - Запусти в терминале: `node dev_server.js`
   - Открой в браузере: 👉 **`http://localhost:8081/viewer`**
2. **Способ 2 (напрямую файлом без сервера):**
   - Просто дважды кликни на файл:
     [`tools/code_sync_viewer.html`](file:///D:/projects/Eda_Go_Rustor_GooglePM/fast_courier_app/tools/code_sync_viewer.html)

### Что показывает просмотрщик:
* 🟢 **Статус синхронизации:** сравнивает последний хеш коммита на GitHub и GitVerse.
* 📜 **История последних коммитов:** сообщение, автор, дата и время.
* 🔍 **Кнопки Diff в 1 клик:** мгновенный переход к просмотру изменённых строк кода на GitHub и на GitVerse.
* 📋 **Интерактивные кнопки копирования команд** (`git pull`, `git push`) прямо в буфер обмена.

---

## 🛠️ Скорая помощь: Что делать, если возник конфликт?

Если ты забыл сделать `git pull` в начале работы и `git push` ругается:

1. **Сохрани текущие изменения во временный карман:**
   ```bash
   git stash
   ```
2. **Скачай свежий код из облака:**
   ```bash
   git pull origin main
   ```
3. **Верни свои изменения обратно:**
   ```bash
   git stash pop
   ```
4. **Теперь закоммить и запушь:**
   ```bash
   git add .
   git commit -m "fix: смерджил изменения"
   git push origin main
   ```

---

## 🔗 Быстрые ссылки на репозитории:

* 🐙 **GitHub (США):**  
  [https://github.com/magnitik74/kuryer-yandex-eda-pro-rustore-googleplay-appstore](https://github.com/magnitik74/kuryer-yandex-eda-pro-rustore-googleplay-appstore)
* 🇷🇺 **GitVerse (Россия):**  
  [https://gitverse.ru/delivery-apps/kuryer-yandex-eda-pro-rustore-googleplay-appstore](https://gitverse.ru/delivery-apps/kuryer-yandex-eda-pro-rustore-googleplay-appstore)
* 📑 **Политика конфиденциальности (Pages):**  
  [https://magnitik74.github.io/privacy-policy/](https://magnitik74.github.io/privacy-policy/)
