-- ============================================================
--  СПРОБА ПОЧИНАЄТЬСЯ НА СТАРТІ ГРИ, А НЕ В КІНЦІ  (03.10.2026)
--  Куди: Supabase → SQL Editor → New query → вставити ВСЕ → Run.
--
--  ⚠️ НАВІЩО. Раніше спроба рахувалася лише тоді, коли гра надсилала
--     результат (submit_result). Тож оновлення сторінки посеред гри давало
--     нову безкоштовну «спробу»: правильні відповіді учень уже бачив,
--     помилки нікуди не записались. Те саме — друга вкладка / інший пристрій.
--
--  ⭐ ЯК ТЕПЕР.
--     • start_attempt(код, токен) — гра викликає на кнопці «Почати».
--       Сервер одразу записує спробу зі статусом 'started'.
--     • Той самий пристрій (той самий токен) після оновлення сторінки —
--       ТА САМА спроба продовжується, нова не витрачається.
--     • Інший пристрій / інший браузер — попередня незавершена спроба
--       стає 'abandoned' (перервана), а нова рахується як наступна.
--     • submit_result завершує ВІДКРИТУ спробу ('done'). Без розпочатої
--       спроби результат не приймається — оминути старт неможливо.
--     • admin_add_attempt(код) — кнопка вчителя «+1 спроба» (технічний збій).
--
--  ⭐ Безпечно запускати повторно. Старі результати отримують статус 'done'.
--  ⭐ Сайт працює і ДО запуску цього файла (гра бачить, що start_attempt
--     ще немає, і поводиться по-старому), і ПІСЛЯ.
-- ============================================================

alter table public.results add column if not exists status      text not null default 'done';
alter table public.results add column if not exists token       uuid;
alter table public.results add column if not exists finished_at timestamptz;
create index if not exists idx_results_code_status on public.results(code_id, status);

-- ── старт / продовження спроби ──────────────────────────────────────────
create or replace function public.start_attempt(p_code text, p_token uuid)
returns json language plpgsql security definer set search_path = public as $$
declare c record; r record; used int;
begin
  select co.id as code_id, co.teacher_id, co.max_attempts,
         co.student_id, co.game_id, g.max_score
    into c
  from codes co
  join games g on g.id = co.game_id
  where upper(co.code) = upper(p_code) and co.active and g.active;

  if not found then
    return json_build_object('ok', false, 'error', 'Код не знайдено або вимкнено');
  end if;

  -- той самий пристрій: продовжуємо відкриту спробу
  if p_token is not null then
    select id, attempt_no into r from results
     where code_id = c.code_id and status = 'started' and token = p_token
     order by created_at desc limit 1;
    if found then
      select count(*) into used from results where code_id = c.code_id;
      return json_build_object('ok', true, 'resumed', true, 'attempt_no', r.attempt_no,
        'remaining', greatest(0, c.max_attempts - used));
    end if;
  end if;

  -- інший пристрій: попередня незавершена спроба вважається перерваною
  update results set status = 'abandoned', finished_at = now()
   where code_id = c.code_id and status = 'started';

  select count(*) into used from results where code_id = c.code_id;
  if used >= c.max_attempts then
    return json_build_object('ok', false, 'error', 'Спроби вичерпано',
      'attempts_used', used, 'max_attempts', c.max_attempts);
  end if;

  insert into results (teacher_id, code_id, student_id, game_id, max_score, attempt_no, status, token)
  values (c.teacher_id, c.code_id, c.student_id, c.game_id, c.max_score, used + 1, 'started', p_token);

  return json_build_object('ok', true, 'resumed', false, 'attempt_no', used + 1,
    'remaining', greatest(0, c.max_attempts - used - 1));
end $$;

-- ── завершення спроби ───────────────────────────────────────────────────
create or replace function public.submit_result(p_code text, p_score int, p_details jsonb, p_token uuid)
returns json language plpgsql security definer set search_path = public as $$
declare c record; r record; used int; v_pct int; v_grade int; v_score int; v_det jsonb;
begin
  select co.id as code_id, co.max_attempts, g.max_score
    into c
  from codes co
  join games g on g.id = co.game_id
  where upper(co.code) = upper(p_code) and co.active and g.active;

  if not found then
    return json_build_object('ok', false, 'error', 'Код не знайдено');
  end if;

  select id, attempt_no into r from results
   where code_id = c.code_id and status = 'started'
     and (p_token is null or token = p_token)
   order by created_at desc limit 1
   for update;

  if not found then
    return json_build_object('ok', false,
      'error', 'Спробу не розпочато або її перервано на іншому пристрої');
  end if;

  v_score := greatest(0, least(coalesce(p_score, 0), c.max_score));
  v_pct   := case when c.max_score > 0 then round(100.0 * v_score / c.max_score)::int else 0 end;
  v_grade := pct_to_grade(v_pct);
  -- Журнал — лише довідка для вчителя, на бал не впливає. Завеликий не зберігаємо.
  v_det := case when p_details is not null and pg_column_size(p_details) <= 60000 then p_details end;

  update results
     set score = v_score, max_score = c.max_score, pct = v_pct, grade = v_grade,
         details = v_det, status = 'done', finished_at = now()
   where id = r.id;

  select count(*) into used from results where code_id = c.code_id;
  return json_build_object('ok', true, 'grade', v_grade, 'pct', v_pct,
    'attempt_no', r.attempt_no, 'remaining', greatest(0, c.max_attempts - used));
end $$;

-- старі форми виклику — теж лише через розпочату спробу
create or replace function public.submit_result(p_code text, p_score int, p_details jsonb)
returns json language sql security definer set search_path = public as $$
  select public.submit_result(p_code, p_score, p_details, null::uuid);
$$;

create or replace function public.submit_result(p_code text, p_score int)
returns json language sql security definer set search_path = public as $$
  select public.submit_result(p_code, p_score, null::jsonb, null::uuid);
$$;

-- ── вчитель: «+1 спроба» ────────────────────────────────────────────────
create or replace function public.admin_add_attempt(p_code text)
returns int language plpgsql security definer set search_path = public as $$
declare v int;
begin
  if auth.uid() is null then raise exception 'not authenticated'; end if;
  update codes set max_attempts = max_attempts + 1
   where upper(code) = upper(p_code) and teacher_id = auth.uid()
  returning max_attempts into v;
  if v is null then raise exception 'code not found'; end if;
  return v;
end $$;

revoke all on function public.start_attempt(text, uuid)                 from public;
revoke all on function public.submit_result(text, int, jsonb, uuid)     from public;
revoke all on function public.admin_add_attempt(text)                   from public;
grant execute on function public.start_attempt(text, uuid)               to anon, authenticated;
grant execute on function public.submit_result(text, int, jsonb, uuid)   to anon, authenticated;
grant execute on function public.submit_result(text, int, jsonb)         to anon, authenticated;
grant execute on function public.submit_result(text, int)                to anon, authenticated;
grant execute on function public.admin_add_attempt(text)                 to authenticated;

notify pgrst, 'reload schema';

-- перевірка: має повернути 3 рядки (status, token, finished_at)
select column_name from information_schema.columns
where table_schema = 'public' and table_name = 'results'
  and column_name in ('status', 'token', 'finished_at');
