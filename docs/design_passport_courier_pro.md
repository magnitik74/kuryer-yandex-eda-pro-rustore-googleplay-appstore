# 🎨 Design Passport — Работа курьером — курьер PRO Еда
### Техническая спецификация дизайн-системы · v1.0

> **Источник:** Визуальный аудит референсного суперприложения доставки (iOS, Sep 2026)
> **Целевое приложение:** Работа курьером — курьер PRO Еда (`fast_courier_app`)
> **Токены JSON:** [`design_tokens/courier_pro_tokens.json`](file:///D:/projects/Eda_Go_Rustor_GooglePM/fast_courier_app/design_tokens/courier_pro_tokens.json)

---

## 📸 Референсные экраны

````carousel
![Главный экран + сервисы + поиск + чипсы локаций](/C:/Users/Александр/.gemini/antigravity/brain/4387edf5-3774-4426-9b01-aa97563b968a/yandex_go_ref_1.png)
<!-- slide -->
![Карта + маршрут + тарифы + нижний лист](/C:/Users/Александр/.gemini/antigravity/brain/4387edf5-3774-4426-9b01-aa97563b968a/yandex_go_ref_2.png)
<!-- slide -->
![Детальный выбор тарифа + список цен](/C:/Users/Александр/.gemini/antigravity/brain/4387edf5-3774-4426-9b01-aa97563b968a/yandex_go_ref_3.png)
<!-- slide -->
![Экран регистрации + карточки сервисов](/C:/Users/Александр/.gemini/antigravity/brain/4387edf5-3774-4426-9b01-aa97563b968a/yandex_go_ref_4.png)
<!-- slide -->
![Опции заказа + переключатели](/C:/Users/Александр/.gemini/antigravity/brain/4387edf5-3774-4426-9b01-aa97563b968a/yandex_go_ref_5.png)
````

---

## 1. Цветовая Палитра

### 1.1 Бренд

| Токен | HEX | Swatch | Назначение |
|-------|-----|--------|-----------|
| `brand.primary` | `#FCE000` | 🟡 | CTA-кнопки, активные табы, бейджи, toggle ON, цена-акцент |
| `brand.primaryPressed` | `#E8CC00` | 🟡 | Нажатое состояние жёлтых кнопок (−8% яркости) |
| `brand.primaryMuted` | `#FFF9CC` | 🟨 | Фон выделенной строки тарифа |
| `brand.primarySurface` | `#FFFBE6` | 🟨 | Лёгкая жёлтая заливка карточек-акцентов |

> [!IMPORTANT]
> **Текст на жёлтой кнопке ВСЕГДА `#21201F` (тёмный), НИКОГДА белый.** Жёлтый фон + тёмный текст = максимальная читаемость и узнаваемость.

### 1.2 Фоны

| Токен | HEX | Назначение |
|-------|-----|-----------|
| `background.primary` | `#FFFFFF` | Основной фон экранов, карточки, bottom sheet |
| `background.secondary` | `#F6F5F3` | Канвас под карточками, группированный фон (как iOS grouped table) |
| `background.tertiary` | `#EBEBEB` | Разделители, неактивные слайдеры, поля ввода |

### 1.3 Текст

| Токен | HEX | Применение |
|-------|-----|-----------|
| `text.primary` | `#21201F` | Заголовки, названия, цены — тёплый чёрный (НЕ чистый `#000000`!) |
| `text.secondary` | `#6D6B69` | Подписи, описания карточек, подзаголовки |
| `text.tertiary` | `#9E9B98` | Плейсхолдеры, отключённые лейблы, время в чипсах |
| `text.onPrimary` | `#21201F` | Текст на жёлтых кнопках (тёмный!) |

### 1.4 Фидбэк

| Токен | HEX | Применение |
|-------|-----|-----------|
| `feedback.success` | `#00B341` | Зелёная галочка в списке (✓ selected) |
| `feedback.error` | `#F5222D` | Ошибки валидации |
| `icon.metro` | `#E42313` | Красный значок метро |
| `icon.plus` | `#8B3FFD` | Фиолетовый бейдж лояльности |

---

## 2. Типографика

> **Шрифт референса:** `YS Text` (проприетарный). **Наш маппинг:** `Inter` (через `google_fonts`) или бандл `MontFamily`.

### 2.1 Шкала типов (Type Scale)

```
Display     34/40  Bold(700)   ls:-0.4   →  Героическая цена ("до 442₽")
Heading XL  28/34  Bold(700)   ls:-0.3   →  Заголовки страниц ("Регистрация")
Heading L   22/28  Bold(700)   ls:-0.2   →  Заголовки секций ("Выберите сервис")
Heading M   18/24  Semi(600)   ls: 0     →  Подзаголовки ("Самый быстрый")
Heading S   16/22  Semi(600)   ls: 0     →  Названия карточек ("Водитель такси")
Body L      16/22  Reg(400)    ls: 0     →  Опции в списке ("Комментарий")
Body M      14/20  Reg(400)    ls: 0     →  Описания, подписи
Body S      13/18  Reg(400)    ls: 0     →  Время в чипсах ("25 мин")
Caption     12/16  Reg(400)    ls:+0.1   →  Лейблы иконок, бейджи
Caption B   12/16  Semi(600)   ls:+0.1   →  Активный чип, цена в карусели
Overline    11/14  Med(500)    ls:+0.5   →  Label над полем ("Город")
Button      16/22  Semi(600)   ls: 0     →  CTA текст ("Заказать", "Готово")
```

### 2.2 Ключевые паттерны

> [!TIP]
> **Правило «600 vs 400»:** Используется **SemiBold (600)** только для заголовков, кнопок и акцентов. Основной текст — строго **Regular (400)**. Никакого Bold (700) в body, никакого Black (900) нигде. Это даёт воздух и лёгкость.

---

## 3. Сетка и Отступы (4px Grid)

### 3.1 Spacing Scale

```
xxs   2px    Иконка ↔ бейдж
xs    4px    Tight inline
s     8px    Между чипсами, компактный padding
m    12px    Внутренний padding карточки, gap элементов
l    16px    ← КЛЮЧЕВОЙ: горизонтальный margin страницы
xl   20px    Padding bottom sheet сверху
xxl  24px    Вертикальный gap между секциями
xxxl 32px    Top padding под status bar
huge 48px    Hero-секция вертикальный padding
```

### 3.2 Анатомия страницы

```
┌──────────────────────────────┐
│     STATUS BAR (system)      │
├── 16px ────────────── 16px ──┤  ← pageMarginH: 16
│                              │
│  [HEADER BAR h=56]           │
│                              │
│  ┌────── SECTION ──────┐     │
│  │ Heading L (22px w700)│     │  ← 24px gap above
│  │                      │     │
│  │  ┌─────┐  ┌─────┐   │     │  ← 12px gap between cards
│  │  │CARD │  │CARD │   │     │  ← card padding: 16
│  │  │r=16 │  │r=16 │   │     │  ← borderRadius: 16
│  │  └─────┘  └─────┘   │     │
│  └──────────────────────┘     │
│                              │
│  24px gap                     │  ← sectionGap: 24
│                              │
│  ┌────── SECTION ──────┐     │
│  │ ...                  │     │
│  └──────────────────────┘     │
│                              │
├──────────────────────────────┤
│  [BOTTOM NAV BAR h=83]      │
│     + safe area bottom 34    │
└──────────────────────────────┘
```

---

## 4. Border Radius

| Токен | Значение | Применение |
|-------|---------|-----------|
| `radius.xs` | 4px | Мелкие бейджи, теги цен |
| `radius.s` | 8px | Бейдж ETA на карте, инпуты |
| `radius.m` | 12px | Контейнер иконки сервиса, чипы, карточка тарифа |
| `radius.l` | 16px | **Стандартная карточка** (сервисы, контент-карты) |
| `radius.xl` | 20px | Промо-карточки в ленте |
| `radius.xxl` | 24px | **Верхние углы bottom sheet** |
| `radius.pill` | 100px | **CTA-кнопки**, search bar, чипы, бейдж ETA |

> [!NOTE]
> **НИКОГДА не используются острые углы (0px) на карточках.** Минимум — 8px. Bottom sheet — всегда 24px сверху. CTA — всегда pill.

---

## 5. Тени (Elevation)

Предельно сдержанные тени — почти плоский дизайн:

| Уровень | offsetY | blur | color | Применение |
|---------|---------|------|-------|-----------|
| `shadow.none` | — | — | — | Сетка иконок (контраст фоном, не тенью!) |
| `shadow.xs` | 1px | 4px | `rgba(0,0,0,0.04)` | Карточки в горизонтальной карусели |
| `shadow.s` | 2px | 8px | `rgba(0,0,0,0.06)` | Карточки сервисов, плавающая кнопка «Назад» |
| `shadow.m` | 4px | 16px | `rgba(0,0,0,0.08)` | Bottom sheet, плавающие панели |
| `shadow.l` | 8px | 24px | `rgba(0,0,0,0.10)` | Модальные окна |
| `shadow.top` | −2px | 12px | `rgba(0,0,0,0.06)` | Тень сверху от bottom nav bar |

> [!WARNING]
> **Нулевая толерантность к «тяжёлым» теням.** Если тень видна невооружённым глазом — она слишком жирная. Тени — это ощущение, а не графический элемент.

---

## 6. Анатомия ключевых компонентов

### 6.1 CTA-кнопка «Заказать»

```
┌─────────────────────────────────────┐
│  h=52  radius=pill(100)  bg=#FCE000 │
│                                     │
│   [Я]  16px  «Заказать»  16px  [⚙]  │
│    ↑          ↑                 ↑   │
│  icon       button text      icon   │
│  24px       16/22 w600       24px   │
│             color=#21201F           │
│                                     │
│  paddingH=24   shadow=s             │
└─────────────────────────────────────┘
    pressed → bg=#E8CC00
```

### 6.2 Bottom Sheet (Нижний лист)

```
        ┌── radius.xxl = 24px ──┐
╭───────┤                        ├───────╮
│       │   ┌──handle──┐         │       │
│  8px  │   │ 36×4 r=2 │         │       │
│       │   │ #D4D2CF  │         │       │
│       │   └──────────┘         │       │
│ 20px  │                        │       │
│       │  [CONTENT]             │       │
│       │  paddingH=16           │       │
│       │                        │       │
│       │  shadow.m (upward)     │       │
╰───────┴────────────────────────┴───────╯
```

### 6.3 Строка списка (List Item)

```
┌────────────────────────────────────────────────┐
│  16px  │  [icon 20]  12px  Title (16/w400)     │  h=56
│        │                   Subtitle (13/w400)  │  paddingV=14
│        │                              [›] 16px │  chevron=#9E9B98
├────────│───────────────────────────────────────-│  divider 0.5px
│  16px indent                          #E8E6E3  │
└────────────────────────────────────────────────┘
```

### 6.4 Toggle Switch

```
      OFF state                    ON state
┌─────────────────┐          ┌─────────────────┐
│ ████████████░░░░ │  51×31   │ ░░░░████████████ │
│ track=#D4D2CF   │          │ track=#FCE000    │
│ thumb=#FFFFFF   │  r=16    │ thumb=#FFFFFF    │
│ thumbSize=27    │          │ + shadow.xs      │
└─────────────────┘          └─────────────────┘
```

### 6.5 Карточка сервиса (Регистрация)

```
┌──────────────────────┐
│  padding=16   r=16   │  bg=#F6F5F3
│                      │
│  ┌────────┐          │
│  │ icon   │ 44×44    │  iconBorderRadius=12
│  │ r=12   │          │
│  └────────┘          │
│  8px gap             │
│  Title (15/w600)     │  color=#21201F
│  Description         │
│  (13/w400)           │  color=#6D6B69
│  max 3 lines         │
│                      │
└──────────────────────┘
  shadow: none (контраст через bg #F6F5F3 vs #FFFFFF)
```

### 6.6 Search Bar

```
┌──────────────────────────────────────────┐
│  h=48  radius=pill(100)  bg=#F6F5F3      │
│                                          │
│  16px  🔍(20px, #9E9B98)  12px  «Поиск»  │
│        placeholder (16/w400, #9E9B98)    │
│                                          │
└──────────────────────────────────────────┘
  На фокус: bg=#FFFFFF, border=1px #21201F
```

---

## 7. Motion & Animation

| Токен | Длительность | Easing | Применение |
|-------|-------------|--------|-----------|
| `instant` | 100ms | — | Haptic feedback, toggle flip |
| `fast` | 200ms | `easeInOut` | Нажатие кнопки, выбор чипа |
| `normal` | 300ms | `easeOut` | Раскрытие карточки, слайд bottom sheet |
| `slow` | 450ms | `easeOut` | Snap-to-position bottom sheet |
| `gentle` | 600ms | `easeInOut` | Анимация счётчика цены, прогресс-бар |

---

## 8. Маппинг на наше приложение

| Экран-референс | Наш экран | Ключевые токены |
|---------------|-----------|-----------------|
| Главный экран (сетка сервисов) | Welcome Curator Screen | `serviceGridIcon`, `searchBar`, `promoCard` |
| Экран регистрации (карточки) | Welcome Curator Screen (преимущества) | `serviceCard`, `formField`, `headingXL` |
| Bottom sheet с тарифами | Curator Tab (чат + action card) | `bottomSheet`, `listItem`, `ctaButton` |
| Список опций с toggle | Roadmap Tab (чеклист шагов) | `listItem`, `toggleSwitch`, `categoryFilter` |
| CTA-кнопка «Заказать» | Кнопка «Начать путь» / «Зарегистрироваться» | `ctaButton` (h=52, pill, #FCE000, text #21201F) |
| Чипы локаций | Curator Tab quick chips | `locationChip`, `chipScrollGap` |

---

## 9. Чеклист внедрения

- [ ] Заменить все `Colors.black` на `#21201F` (тёплый графит)
- [ ] Заменить все `Color(0xFF6B6560)` на `#6D6B69` (точный secondary)
- [ ] Все CTA-кнопки: `height: 52`, `borderRadius: 100` (pill), текст `w600` 16px
- [ ] Все карточки: `borderRadius: 16`, тень `shadow.s` или `shadow.none` + фоновый контраст
- [ ] Bottom sheet corners: `borderRadius: 24` (topLeft + topRight)
- [ ] Toggle: жёлтый `#FCE000` ON, серый `#D4D2CF` OFF (не зелёный!)
- [ ] Убрать все `w700/w900` из body текста — только `w400`
- [ ] Заголовки секций: Heading L (22px, w700)
- [ ] Горизонтальные margins всех страниц: строго `16px`
- [ ] Тени: убавить до `rgba(0,0,0,0.04-0.08)`, не более

---

> **JSON-файл с полными токенами:**
> [`design_tokens/courier_pro_tokens.json`](file:///D:/projects/Eda_Go_Rustor_GooglePM/fast_courier_app/design_tokens/courier_pro_tokens.json)
>
> Готов к импорту в Flutter через `ThemeData` или кастомный `AppTheme` класс.
