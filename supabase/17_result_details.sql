-- Журнал помилок у результатах: на яких питаннях учень помилився.
-- Гра надсилає p_details = {"mistakes":[{"r":раунд,"q":"питання","v":"що обрав/ввів"}, ...]}.
--
-- ⭐ Безпечно запускати посеред навчального дня і повторно:
--    • стара функція submit_result(text, int) лишається й працює як раніше
--      (тепер вона просто викликає нову з p_details = null);
--    • нова — submit_result(text, int, jsonb): PostgREST розрізняє їх за
--      набором імен аргументів, тож неоднозначності немає.
--    • гра (assets/db.js), якщо нової функції ще немає, сама повторює запис
--      старим способом — бал не губиться.

alter table public.results add column if not exists details jsonb;

create or replace function public.submit_result(p_code text, p_score int, p_details jsonb)
returns json language plpgsql security definer set search_path = public as $$
declare c record; used int; a int; v_pct int; v_grade int; v_score int; v_det jsonb;
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
  -- Журнал — лише довідка для вчителя, на бал не впливає. Завеликий не зберігаємо.
  v_det := case when p_details is not null and pg_column_size(p_details) <= 60000 then p_details end;

  insert into results (teacher_id, code_id, student_id, game_id, score, max_score, pct, grade, attempt_no, details)
  values (c.teacher_id, c.code_id, c.student_id, c.game_id, v_score, c.max_score, v_pct, v_grade, a, v_det);

  return json_build_object('ok', true, 'grade', v_grade, 'pct', v_pct,
    'attempt_no', a, 'remaining', greatest(0, c.max_attempts - a));
end $$;

create or replace function public.submit_result(p_code text, p_score int)
returns json language sql security definer set search_path = public as $$
  select public.submit_result(p_code, p_score, null::jsonb);
$$;

revoke all on function public.submit_result(text, int, jsonb) from public;
grant execute on function public.submit_result(text, int, jsonb) to anon, authenticated;
grant execute on function public.submit_result(text, int)        to anon, authenticated;

notify pgrst, 'reload schema';

select column_name from information_schema.columns
where table_schema = 'public' and table_name = 'results' and column_name = 'details';
