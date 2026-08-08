-- ============================================================
--  ГРА «Цифровий світ» — Підсумкова робота ГР 1 та ГР 4 (6 клас)
--  Куди: Supabase → SQL Editor → New query → вставити ВСЕ → Run.
--  Безпечно запускати повторно (upsert за slug).
--  max_score = 25 (6 + 6 + 4 + 5 + 4 правильних дій у 5 раундах) —
--  сервер рахує % = score / max_score, а pct_to_grade() → бал 1–12.
--  Раунди: 1) цифрове/нецифрове (ГР 1); 2) групи за основним процесом (ГР 1);
--          3) етапи створення презентації по порядку (ГР 1);
--          4) пасивний/активний цифровий слід (ГР 4); 5) розумні дії (ГР 4).
-- ============================================================

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

-- ПЕРЕВІРКА: має повернути рядок гри з max_score = 25
select slug, title, max_score, active from public.games where slug = 'cyfrovyi-svit-6';
