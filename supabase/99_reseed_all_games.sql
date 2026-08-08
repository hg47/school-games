-- ============================================================
--  РЕЄСТРАЦІЯ ВСІХ ІГОР у public.games — один запуск
--  Куди: Supabase -> SQL Editor -> New query -> вставити ВСЕ -> Run.
--
--  НАВІЩО ЦЕ ПОТРІБНО:
--  Адмінка (admin.html) бере список ігор НЕ з GitHub, а з таблиці public.games:
--      select slug, title from games where active = true order by title
--  Тому залитий на GitHub Pages файл games/<slug>.html робить гру такою, що
--  ВІДКРИВАЄТЬСЯ, а цей SQL — такою, що ВИДНА в адмінці й на неї можна
--  створити коди учням.
--
--  Безпечно запускати повторно: on conflict (slug) do update.
--  ⚠️ naved-lad тут НЕМАЄ — він засіяний у 01_schema.sql.
--
--  ⚠️ max_score мусить збігатися з константою MAX у games/<slug>.html.
--     Значення нижче взяті з файлів NN_game_*.sql БЕЗ ЗМІН і зведені з HTML —
--     розбіжностей немає (перевірено скриптом).
-- ============================================================

-- 04_game_dani.sql  (max_score = 21)
insert into public.games (slug, title, description, max_score)
values (
  'dani-ta-informatsiya',
  'Дані та інформація',
  'Види повідомлень, зорова інформація, інформаційні процеси, типи даних — ГР 1, 5 клас',
  21
)
on conflict (slug) do update
  set title       = excluded.title,
      description = excluded.description,
      max_score   = excluded.max_score;

-- 05_game_bezpeka.sql  (max_score = 20)
insert into public.games (slug, title, description, max_score)
values (
  'bezpeka-internet',
  'Безпека в Інтернеті',
  'Правила безпеки, мережевий етикет, факт/судження, надійність сайту — ГР 4, 5 клас',
  20
)
on conflict (slug) do update
  set title       = excluded.title,
      description = excluded.description,
      max_score   = excluded.max_score;

-- 06_game_cyfrovyi_svit.sql  (max_score = 25)
insert into public.games (slug, title, description, max_score)
values (
  'cyfrovyi-svit-6',
  'Цифровий світ',
  'Цифрові пристрої та їх класифікація, етапи створення презентації, цифровий слід і безпека — ГР 1 та ГР 4, 6 клас',
  25
)
on conflict (slug) do update
  set title       = excluded.title,
      description = excluded.description,
      max_score   = excluded.max_score;

-- 07_game_grafika.sql  (max_score = 27)
insert into public.games (slug, title, description, max_score)
values (
  'grafika-6',
  'Графіка: свідомий вибір',
  'Растр чи вектор під задачу, вибір інструмента під елемент, порядок створення, точність засобами програми, формати файлів — ГР 3, 6 клас',
  27
)
on conflict (slug) do update
  set title       = excluded.title,
      description = excluded.description,
      max_score   = excluded.max_score;

-- 08_game_koduvannya.sql  (max_score = 18)
insert into public.games (slug, title, description, max_score)
values (
  'koduvannya-8',
  'Кодування даних',
  'Двійковий код і байт, число ↔ байт, переходи між одиницями (Б, б, кБ, МБ), довжина двійкового коду тексту, розмір файлу BMP із вирівнюванням — ГР 1, 8 клас',
  18
)
on conflict (slug) do update
  set title       = excluded.title,
      description = excluded.description,
      max_score   = excluded.max_score;

-- 09_game_bezpeka_tehnika.sql  (max_score = 24)
insert into public.games (slug, title, description, max_score)
values (
  'bezpeka-tehnika-8',
  'Безпека й технології',
  'Розпізнавання шахрайської реклами, вибір типу комп''ютера під задачу, етика й безпека цифрової взаємодії, дії при неполадках, державні послуги в смартфоні — ГР 4, 8 клас',
  24
)
on conflict (slug) do update
  set title       = excluded.title,
      description = excluded.description,
      max_score   = excluded.max_score;

-- 10_game_svidomyi_vybir.sql  (max_score = 26)
insert into public.games (slug, title, description, max_score)
values (
  'svidomyi-vybir-7',
  'Свідомий вибір',
  'Що дає хмарний сервіс, вибір інструмента для монтажу звуку, коли розгалуження в презентації потрібне, керування показом і маршрут показу під аудиторію — ГР 3, 7 клас',
  26
)
on conflict (slug) do update
  set title       = excluded.title,
      description = excluded.description,
      max_score   = excluded.max_score;

-- 11_game_alhorytmy.sql  (max_score = 26)
insert into public.games (slug, title, description, max_score)
values (
  'alhorytmy-8',
  'Алгоритми та програми',
  'Яка форма розгалуження потрібна, or чи and у складній умові, обчислення за математичною моделлю, коли варто писати програму і логіка у фільтрах та пошуку — ГР 2 та ГР 3, 8 клас, Тема 3',
  26
)
on conflict (slug) do update
  set title       = excluded.title,
      description = excluded.description,
      max_score   = excluded.max_score;

-- ПЕРЕВІРКА: має повернути 9 рядків (8 звідси + naved-lad зі схеми)
select slug, title, max_score, active
from public.games
order by slug;
