-- ============================================================
--  ГРА «Безпека в Інтернеті» — Підсумкова робота ГР 4 (5 клас)
--  Куди: Supabase → SQL Editor → New query → вставити ВСЕ → Run.
--  Безпечно запускати повторно (upsert за slug).
--  max_score = 20 (6 + 5 + 4 + 5 правильних дій у 4 раундах) —
--  сервер рахує % = score / max_score, а pct_to_grade() → бал 1–12.
-- ============================================================

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

-- ПЕРЕВІРКА: має повернути рядок гри з max_score = 20
select slug, title, max_score, active from public.games where slug = 'bezpeka-internet';
