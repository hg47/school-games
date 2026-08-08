-- ============================================================
--  ФАЗА 3 — генерація кодів для адмінки (виклик з-під входу вчителя)
--  Куди: Supabase → SQL Editor → New query → вставити ВСЕ → Run.
-- ============================================================

create or replace function public.admin_create_codes(
  p_game_slug text, p_student_ids uuid[], p_max_attempts int default 2)
returns table(r_student_id uuid, r_name text, r_code text)
language plpgsql security definer set search_path = public as $$
declare
  v_teacher uuid; v_game uuid; sid uuid; c text;
  alph text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';  -- без 0,O,1,I,L
begin
  v_teacher := auth.uid();
  if v_teacher is null then raise exception 'not authenticated'; end if;

  select id into v_game from games where slug = p_game_slug and active;
  if v_game is null then raise exception 'game not found'; end if;

  foreach sid in array p_student_ids loop
    -- лише свої учні
    if not exists (select 1 from students s where s.id = sid and s.teacher_id = v_teacher) then
      continue;
    end if;
    -- унікальний 4-символьний код
    loop
      c := '';
      for i in 1..4 loop
        c := c || substr(alph, 1 + floor(random()*length(alph))::int, 1);
      end loop;
      exit when not exists (select 1 from codes where code = c);
    end loop;
    insert into codes (teacher_id, code, student_id, game_id, max_attempts)
    values (v_teacher, c, sid, v_game, coalesce(p_max_attempts, 2));
    r_student_id := sid;
    select s.full_name into r_name from students s where s.id = sid;
    r_code := c;
    return next;
  end loop;
end $$;

revoke all on function public.admin_create_codes(text, uuid[], int) from public;
grant execute on function public.admin_create_codes(text, uuid[], int) to authenticated;
