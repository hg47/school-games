-- ============================================================
--  ГРА «Дані та інформація» — Підсумкова робота ГР 1 (5 клас)
--  Куди: Supabase → SQL Editor → New query → вставити ВСЕ → Run.
--  Безпечно запускати повторно (upsert за slug).
--  max_score = 21 (6 + 4 + 5 + 6 правильних дій у 4 раундах) —
--  сервер рахує % = score / max_score, а pct_to_grade() → бал 1–12.
-- ============================================================

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

-- ПЕРЕВІРКА: має повернути рядок гри з max_score = 21
select slug, title, max_score, active from public.games where slug = 'dani-ta-informatsiya';
