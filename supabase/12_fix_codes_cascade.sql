-- ============================================================
--  ГАРАНТУЄМО ON DELETE CASCADE для codes.student_id і codes.game_id
--  Куди: Supabase -> SQL Editor -> New query -> вставити ВСЕ -> Run.
--  Безпечно запускати повторно.
--
--  НАВІЩО, якщо в 01_schema.sql cascade уже написаний:
--  ⚠️ 01_schema.sql створює таблиці через "create table IF NOT EXISTS".
--     Якщо таблиця codes зʼявилася в базі ще ДО того, як у схему додали
--     "on delete cascade", то повторний запуск 01_schema.sql констрейнт
--     НЕ оновить — create просто пропуститься. У такій базі видалення учня
--     впало б із помилкою FK, а привʼязка до коду залишилася б.
--     Цей файл переставляє констрейнт напевно.
--
--  ⭐ Що це дає: видалення учня автоматично прибирає ВСІ його коди.
--     В adminpanel коди видаляються ще й явно (окремим запитом) — щоб
--     працювало навіть у базі без cascade. Одне одному не суперечить.
--
--  ⚠️ results НЕ чіпаємо: там свідомо "on delete set null" — оцінки мусять
--     лишатися в історії навіть після видалення учня з ростера.
-- ============================================================

-- 1) codes.student_id -> students.id  (CASCADE)
alter table public.codes drop constraint if exists codes_student_id_fkey;
alter table public.codes
  add constraint codes_student_id_fkey
  foreign key (student_id) references public.students(id) on delete cascade;

-- 2) codes.game_id -> games.id  (CASCADE)
alter table public.codes drop constraint if exists codes_game_id_fkey;
alter table public.codes
  add constraint codes_game_id_fkey
  foreign key (game_id) references public.games(id) on delete cascade;

-- ============================================================
--  ПЕРЕВІРКА: обидва рядки мусять мати delete_rule = CASCADE
--  (а для results — SET NULL, і це правильно)
-- ============================================================
select
  tc.table_name,
  kcu.column_name,
  tc.constraint_name,
  rc.delete_rule
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu
  on kcu.constraint_name = tc.constraint_name
 and kcu.constraint_schema = tc.constraint_schema
join information_schema.referential_constraints rc
  on rc.constraint_name = tc.constraint_name
 and rc.constraint_schema = tc.constraint_schema
where tc.constraint_type = 'FOREIGN KEY'
  and tc.table_schema = 'public'
  and tc.table_name in ('codes','results')
order by tc.table_name, kcu.column_name;
