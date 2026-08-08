-- ============================================================
--  ФАЗА 1 — СХЕМА БД + RLS (стійка версія, безпечно запускати повторно)
--  Куди: Supabase → SQL Editor → New query → вставити ВСЕ → Run.
--  gen_random_uuid() у Postgres 15 вбудований (розширення не потрібне).
-- ============================================================

-- 1) Каталог ігор
create table if not exists public.games (
  id          uuid primary key default gen_random_uuid(),
  slug        text unique not null,
  title       text not null,
  description text,
  max_score   int  not null default 0,
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);

-- 2) Учні (ростер).  teacher_id = хто створив (auth.uid()), без FK на auth.users
create table if not exists public.students (
  id          uuid primary key default gen_random_uuid(),
  teacher_id  uuid not null default auth.uid(),
  full_name   text not null,
  class_label text not null,
  created_at  timestamptz not null default now()
);

-- 3) Коди доступу: конкретний учень × конкретна гра
create table if not exists public.codes (
  id           uuid primary key default gen_random_uuid(),
  teacher_id   uuid not null default auth.uid(),
  code         text unique not null,
  student_id   uuid not null references public.students(id) on delete cascade,
  game_id      uuid not null references public.games(id)    on delete cascade,
  max_attempts int  not null default 2,
  active       boolean not null default true,
  created_at   timestamptz not null default now()
);

-- 4) Результати проходжень
create table if not exists public.results (
  id          uuid primary key default gen_random_uuid(),
  teacher_id  uuid,
  code_id     uuid references public.codes(id)    on delete set null,
  student_id  uuid references public.students(id) on delete set null,
  game_id     uuid references public.games(id)    on delete set null,
  score       int,
  max_score   int,
  pct         int,
  grade       int,
  attempt_no  int,
  created_at  timestamptz not null default now()
);

create index if not exists idx_codes_code          on public.codes(code);
create index if not exists idx_results_student_game on public.results(student_id, game_id);

-- ============================================================
--  RLS — доступ лише до своїх даних (teacher_id = auth.uid())
-- ============================================================
alter table public.games    enable row level security;
alter table public.students enable row level security;
alter table public.codes    enable row level security;
alter table public.results  enable row level security;

drop policy if exists games_read  on public.games;
drop policy if exists games_write on public.games;
create policy games_read  on public.games for select to authenticated using (true);
create policy games_write on public.games for all    to authenticated using (true) with check (true);

drop policy if exists students_own on public.students;
create policy students_own on public.students for all to authenticated
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists codes_own on public.codes;
create policy codes_own on public.codes for all to authenticated
  using (teacher_id = auth.uid()) with check (teacher_id = auth.uid());

drop policy if exists results_own on public.results;
create policy results_own on public.results for select to authenticated
  using (teacher_id = auth.uid());

-- ============================================================
--  Перша гра в каталозі
-- ============================================================
insert into public.games (slug, title, description, max_score)
values ('naved-lad', 'Наведи лад', 'Файли, папки, Кошик — 5 клас', 17)
on conflict (slug) do nothing;

-- ПЕРЕВІРКА: після Run має повернути 4 рядки (назви таблиць)
select table_name from information_schema.tables
where table_schema = 'public' and table_name in ('games','students','codes','results')
order by table_name;
