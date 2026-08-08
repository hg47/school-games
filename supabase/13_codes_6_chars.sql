-- ============================================================
--  КОДИ ДОСТУПУ: 4 -> 6 СИМВОЛІВ
--  Куди: Supabase -> SQL Editor -> New query -> вставити ВСЕ -> Run.
--  Безпечно запускати повторно.
--
--  НАВІЩО:
--  ⚠️ Було 4 символи з алфавіту в 31 знак = 31^4 = 923 521 комбінація.
--     На redeem_code немає обмеження частоти запитів, тому скрипт міг
--     перебрати весь простір і зібрати ПІБ та клас усіх учнів — а маючи
--     чужий код, ще й записати за нього оцінку (submit_result перевіряє
--     лише код). Автор такого скрипта — восьмикласник на інформатиці,
--     тобто цілком реальна людина.
--  ⭐ Стало 6 символів: 31^6 = 887 503 681 — у 960 разів більше.
--
--  ⚠️ ЩО НЕ ЛАМАЄТЬСЯ:
--     • Уже видані 4-символьні коди працюють далі — redeem_code шукає
--       за точним значенням, довжина йому байдужа.
--     • Поле введення на index.html має maxlength="8" — 6 символів влазять.
--     • Алфавіт той самий, без 0 O 1 I L — щоб учень не плутав символи.
--
--  ⚠️ ЩО ЛИШАЄТЬСЯ НЕЗАКРИТИМ: обмеження частоти викликів redeem_code.
--     Довжина коду робить перебір дорогим, але не забороняє його.
-- ============================================================

create or replace function public.admin_create_codes(
  p_game_slug text, p_student_ids uuid[], p_max_attempts int default 2)
returns table(r_student_id uuid, r_name text, r_code text)
language plpgsql security definer set search_path = public as $$
declare
  v_teacher uuid; v_game uuid; sid uuid; c text;
  alph text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';  -- без 0,O,1,I,L
  v_len int := 6;                                  -- ⭐ було 4
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
    -- унікальний код заданої довжини
    loop
      c := '';
      for i in 1..v_len loop
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
grant  execute on function public.admin_create_codes(text, uuid[], int) to authenticated;

-- ============================================================
--  ПЕРЕВІРКА 1: у тілі функції мусить стояти v_len int := 6
-- ============================================================
select
  case when prosrc like '%v_len int := 6%' then 'OK: коди тепер 6 символів'
       else 'УВАГА: у функції не 6 символів' end as stan
from pg_proc
where proname = 'admin_create_codes';

-- ============================================================
--  ПЕРЕВІРКА 2: розподіл довжин уже виданих кодів.
--  Старі 4-символьні лишаються робочими — це нормально.
--  Після наступної генерації тут зʼявиться рядок із length = 6.
-- ============================================================
select length(code) as dovzhyna, count(*) as skilky
from public.codes
group by length(code)
order by dovzhyna;
