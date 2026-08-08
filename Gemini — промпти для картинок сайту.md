# Gemini — промпти для картинок сайту ігор

**Сайт:** `https://strykers79.github.io/school-games/`
**Гама:** оранж `#ff7a2f` → рожевий `#ff5f8a` → фіалковий `#7c5cff`, темна база `#07070c`

---

## ⚠️ Спочатку — чого генерувати НЕ треба

| Не генеруємо | Чому |
|---|---|
| ⛔ **favicon** | ✅ **уже зроблено кодом** — `favicon.svg`. SVG чіткий і на 16 px, і на 512 px, важить 600 байт, і його можна правити текстом. Згенерований PNG у цьому гірший за визначенням |
| ⛔ **фон із плямами** | це **CSS-градієнти**: масштабуються під будь-який екран, реагують на тему, важать 0 байт. Картинка тут була б кроком назад |
| ⛔ **іконку джойстика** замість emoji 🎮 | ⭐ emoji чіткий на **кожному** пристрої, працює у світлій і темній темі, не потребує файлу. Свій логотип має сенс лише якщо він **справді** відрізняє сайт — інакше це заміна кращого на гірше |
| ⛔ **іконки для плиток у грі** | вони змістові (🔺 трикутник, 🌊 вода) і мусять читатися в один рядок тексту. Emoji тут доречніші за картинки |

⭐ **Тобто генерувати треба всього дві речі** — і обидві не для краси, а для конкретної технічної потреби.

---

## IMG-1 · Превью посилання (og:image) — 1200 × 630 ⭐ *головне*

**Навіщо.** Коли ви кидаєте посилання на сайт у Google Classroom, Viber або Telegram,
зараз показується **гола адреса**. З цією картинкою буде картка з зображенням — і посилання
читається як продукт, а не як «сторінка на гітхабі».

**Файл:** `og-cover.png` (або `.jpg`), покласти в корінь сайту поруч з `index.html`.

⚠️ **ГОЛОВНЕ ОБМЕЖЕННЯ: у промпті НЕ просимо жодного тексту.** Генератори псують
кирилицю — виходять неіснуючі літери. Назву сайту, якщо захочете, додасте потім у будь-якому
редакторі (Canva, Paint.NET, Figma) — або лишіть без тексту, назва все одно підтягується
з `<title>` сторінки.

**Укр.** Горизонтальна композиція **1200 × 630** на **дуже темному** тлі (майже чорному,
`#07070c`). У центрі — **три великі розмиті світлові плями**, що м'яко перетікають одна
в одну: **оранжева** ліворуч-угорі, **рожева** в центрі, **фіалкова** праворуч-унизу.
Плями сильно розмиті, як підсвітка за склом.

**Поверх них**, по центру композиції — **велика п'ятикутна зірка** з чистими рівними
променями, залита **білим** із легким світінням по краю. Зірка займає приблизно **третину
висоти** кадру.

Навколо зірки — **три-чотири округлені прямокутники** різного розміру, розставлені
асиметрично, **напівпрозорі**, лише з тонкою світлою межею й без вмісту (натяк на картки
інтерфейсу). Вони **не перекривають** зірку.

⚠️ **Обов'язково:**
- **жодного тексту, літер і цифр** — узагалі;
- усе важливе **в центральних 80 %** кадру: превью обрізають по-різному;
- ⭐ **великі форми, високий контраст** — у Viber ця картинка буде розміром із нігтик;
- ніяких дрібних деталей, тонких ліній, градієнтних сіток.

**EN prompt:**
> A horizontal 1200×630 composition on a very dark near-black background (#07070c). Three large,
> heavily blurred glowing light blobs flow softly into each other: orange in the upper left, pink in
> the centre, violet in the lower right, like backlight behind frosted glass. Centred on top of them,
> one large clean five-pointed star with even rays, filled white with a soft glow along its edge,
> occupying roughly one third of the frame height. Around the star, three or four rounded rectangles of
> different sizes are placed asymmetrically, semi-transparent, with only a thin light outline and no
> content, hinting at interface cards; they must not cover the star. Absolutely no text, no letters and
> no numbers anywhere. Keep everything important inside the central 80% of the frame. Use large shapes
> and high contrast — this will be viewed as a thumbnail the size of a fingernail. No small details, no
> thin lines, no gradient meshes. Flat modern vector look, clean and uncluttered, no drop shadows.

---

## IMG-2 · Іконка для домашнього екрана телефона — 180 × 180

**Навіщо.** Якщо учень додає сайт на головний екран телефона, iOS бере **не** `favicon.svg`,
а окремий PNG. Без нього буде сірий квадрат зі скріншотом сторінки.

**Файл:** `apple-touch-icon.png`, у корінь сайту.

**Укр.** Квадрат **180 × 180**, залитий **діагональним градієнтом** зліва-вгорі
праворуч-униз: **оранж `#ff7a2f` → рожевий `#ff5f8a` → фіалковий `#7c5cff`**.
По центру — **велика біла п'ятикутна зірка** з рівними променями, що займає приблизно
**55 %** ширини квадрата.

⚠️ **Обов'язково:**
- **без прозорості** — фон залитий до самих країв;
- **без скруглених кутів** — iOS обрізає їх сам, інакше вийде подвійна рамка;
- **без тексту й без обведення** зірки;
- ⭐ зірка **точно по центру** — iOS не центрує.

💡 **Це та сама зірка, що у `favicon.svg`** — так іконка в закладці й іконка на
домашньому екрані виглядають однією родиною.

**EN prompt:**
> A perfectly square 180×180 icon filled edge to edge with a diagonal gradient from top-left to
> bottom-right: orange #ff7a2f to pink #ff5f8a to violet #7c5cff. Centred on it, one large white
> five-pointed star with even rays, occupying about 55% of the square's width. No transparency — the
> background must fill the whole square. No rounded corners. No text, no outline around the star. The
> star must be exactly centred. Flat vector, clean, no shadows, no extra decoration.

---

## Що зробити після генерації

1. Покласти `og-cover.png` і `apple-touch-icon.png` у **корінь** сайту (там, де `index.html`).
2. Сказати мені — я допишу в `<head>` усіх публічних сторінок:
   ```html
   <link rel="icon" href="favicon.svg" type="image/svg+xml">
   <link rel="apple-touch-icon" href="apple-touch-icon.png">
   <meta property="og:title" content="Навчальні ігри">
   <meta property="og:description" content="…">
   <meta property="og:image" content="https://strykers79.github.io/school-games/og-cover.png">
   ```
   ⚠️ **`og:image` мусить бути ПОВНОЮ адресою** (`https://…`), а не `og-cover.png` —
   з відносним шляхом превью не працює ні в Viber, ні в Telegram, ні в Classroom.
3. ⚠️ **Перевірити превью після заливання.** Viber і Telegram кешують картку **надовго**:
   якщо перший раз показалося без картинки, потім воно таким і лишиться. Найпростіше —
   перевіряти на посиланні з «хвостиком»: `…/school-games/?v=1`, потім `?v=2`.

---

## 💡 Якщо захочеться більше (не обов'язково)

| Що | Коли має сенс |
|---|---|
| **Ілюстрації на екрани демо** («що вміє сайт») | якщо показуватимете сайт на педраді як презентацію продукту. Зараз там текст із emoji — і це працює |
| **Своя іконка-логотип** замість 🎮 | якщо захочете, щоб сайт мав пізнаваний знак поза межами школи |
| **Картинка-заголовок для гри** | ⚠️ **не радив би**: на контрольній кожен зайвий елемент відтягує увагу від завдання |
