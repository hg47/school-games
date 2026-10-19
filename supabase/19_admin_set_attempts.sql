-- ═══════════════════════════════════════════════════════════════════════
--  19 · Вчитель змінює кількість спроб за кодом (19.10.2026)
--
--  ⭐ НАВІЩО. Досі в адмінці можна було лише ДОДАТИ спробу (+1,
--     18_attempt_start.sql). Тепер за замовчуванням коди створюються
--     з ОДНІЄЮ спробою, а вчитель може і збільшити, і зменшити число
--     для окремого коду або для всіх показаних у таблиці.
--
--  • admin_set_attempts(код, n) — встановити рівно n спроб (1–10).
--    ⚠️ Якщо n менше за вже використані спроби, нових спроб просто
--       не буде; зіграні спроби і бали НЕ видаляються.
--  • за замовчуванням у таблиці codes — 1 спроба.
--
--  Запуск: Supabase → SQL Editor → вставити все → Run. Повторно — без шкоди.
-- ═══════════════════════════════════════════════════════════════════════

alter table public.codes alter column max_attempts set default 1;

create or replace function public.admin_set_attempts(p_code text, p_n int)
returns int language plpgsql security definer set search_path = public as $$
declare v int;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  if p_n is null or p_n < 1 or p_n > 10 then raise exception 'спроб може бути від 1 до 10'; end if;
  update codes set max_attempts = p_n
   where upper(code) = upper(p_code) and teacher_id = auth.uid()
  returning max_attempts into v;
  if v is null then raise exception 'code not found'; end if;
  return v;
end $$;

revoke all on function public.admin_set_attempts(text, int) from public;
grant execute on function public.admin_set_attempts(text, int) to authenticated;

notify pgrst, 'reload schema';

-- перевірка: має повернути 1 рядок
select proname from pg_proc where proname = 'admin_set_attempts';
