-- ============================================================
--  ДОДАЄМО КЛАС У НАЗВУ ГРИ (title) — щоб в адмінці одразу було видно,
--  для якого класу гра, а не тільки загальна назва.
--  Куди: Supabase -> SQL Editor -> New query -> вставити ВСЕ -> Run.
--  Безпечно запускати повторно: якщо клас уже дописано, UPDATE просто
--  перезапише тим самим значенням.
--
--  ⚠️ Тему (§ / ГР / урок) у сам title НЕ додаємо — там і так довго читати
--     у випадному списку. Повний опис теми лишається в description і тепер
--     показується під випадним списком у admin.html (окрема правка файлу).
-- ============================================================

update public.games set title = '5 клас · Наведи лад'                 where slug = 'naved-lad';
update public.games set title = '5 клас · Дані та інформація'         where slug = 'dani-ta-informatsiya';
update public.games set title = '5 клас · Безпека в Інтернеті'        where slug = 'bezpeka-internet';
update public.games set title = '6 клас · Цифровий світ'              where slug = 'cyfrovyi-svit-6';
update public.games set title = '6 клас · Графіка: свідомий вибір'    where slug = 'grafika-6';
update public.games set title = '7 клас · Свідомий вибір'             where slug = 'svidomyi-vybir-7';
update public.games set title = '8 клас · Кодування даних'            where slug = 'koduvannya-8';
update public.games set title = '8 клас · Безпека й технології'       where slug = 'bezpeka-tehnika-8';
update public.games set title = '8 клас · Алгоритми та програми'      where slug = 'alhorytmy-8';

-- ============================================================
--  ПЕРЕВІРКА: мусить повернути 9 рядків, усі title з префіксом "N клас · "
-- ============================================================
select slug, title, max_score, active
from public.games
order by slug;
