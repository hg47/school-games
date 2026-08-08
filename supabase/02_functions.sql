-- ============================================================
--  ФАЗА 2 — СЕРВЕРНІ ФУНКЦІЇ (перевірка коду + запис результату)
--  Куди: Supabase → SQL Editor → New query → вставити все → Run.
--  Логіка виконується на сервері (SECURITY DEFINER), учень її не бачить.
-- ============================================================

-- Шкала % → оцінка 1-12 (той самий поріг, що й на клієнті)
create or replace function public.pct_to_grade(p int)
returns int language sql immutable as $$
  select case
    when p >= 90 then 12 when p >= 82 then 11 when p >= 74 then 10
    when p >= 66 then 9  when p >= 58 then 8  when p >= 50 then 7
    when p >= 42 then 6  when p >= 34 then 5  when p >= 25 then 4
    when p >= 17 then 3  when p >= 8  then 2  else 1 end;
$$;

-- Перевірка коду учнем: повертає, яка гра доступна і скільки спроб лишилось
create or replace function public.redeem_code(p_code text)
returns json language plpgsql security definer set search_path = public as $$
declare c record; used int;
begin
  select co.id as code_id, co.max_attempts, s.full_name, s.class_label,
         g.slug, g.title, g.max_score
    into c
  from codes co
  join students s on s.id = co.student_id
  join games    g on g.id = co.game_id
  where upper(co.code) = upper(p_code) and co.active and g.active;

  if not found then
    return json_build_object('ok', false, 'error', 'Код не знайдено або вимкнено');
  end if;

  select count(*) into used from results where code_id = c.code_id;

  return json_build_object(
    'ok', true,
    'game_slug', c.slug, 'game_title', c.title,
    'student_name', c.full_name, 'class', c.class_label,
    'attempts_used', used, 'max_attempts', c.max_attempts,
    'remaining', greatest(0, c.max_attempts - used)
  );
end $$;

-- Запис результату: перевіряє код і ліміт спроб, рахує оцінку на сервері
create or replace function public.submit_result(p_code text, p_score int)
returns json language plpgsql security definer set search_path = public as $$
declare c record; used int; a int; v_pct int; v_grade int; v_score int;
begin
  select co.id as code_id, co.teacher_id, co.max_attempts,
         co.student_id, co.game_id, g.max_score
    into c
  from codes co
  join games g on g.id = co.game_id
  where upper(co.code) = upper(p_code) and co.active and g.active;

  if not found then
    return json_build_object('ok', false, 'error', 'Код не знайдено');
  end if;

  select count(*) into used from results where code_id = c.code_id;
  if used >= c.max_attempts then
    return json_build_object('ok', false, 'error', 'Спроби вичерпано',
      'attempts_used', used, 'max_attempts', c.max_attempts);
  end if;

  v_score := greatest(0, least(coalesce(p_score, 0), c.max_score));
  v_pct   := case when c.max_score > 0 then round(100.0 * v_score / c.max_score)::int else 0 end;
  v_grade := pct_to_grade(v_pct);
  a := used + 1;

  insert into results (teacher_id, code_id, student_id, game_id, score, max_score, pct, grade, attempt_no)
  values (c.teacher_id, c.code_id, c.student_id, c.game_id, v_score, c.max_score, v_pct, v_grade, a);

  return json_build_object('ok', true, 'grade', v_grade, 'pct', v_pct,
    'attempt_no', a, 'remaining', greatest(0, c.max_attempts - a));
end $$;

-- Дозволити виклик цих функцій анонімним (учні без входу) та авторизованим
revoke all on function public.redeem_code(text)          from public;
revoke all on function public.submit_result(text, int)   from public;
grant execute on function public.redeem_code(text)        to anon, authenticated;
grant execute on function public.submit_result(text, int) to anon, authenticated;
