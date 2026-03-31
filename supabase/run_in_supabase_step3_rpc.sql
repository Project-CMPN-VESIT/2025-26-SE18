-- ============================================================
--  STEP 3 OF 3 — Paste this into Supabase SQL Editor and run
-- ============================================================

create or replace function public.increment_student_present(student_uuid uuid) returns void language plpgsql security definer as $$ begin update public.students set present_count = present_count + 1, total_classes = total_classes + 1, consecutive_absences = 0 where id = student_uuid; end; $$;
create or replace function public.increment_student_absent(student_uuid uuid) returns void language plpgsql security definer as $$ begin update public.students set absent_count = absent_count + 1, total_classes = total_classes + 1, consecutive_absences = consecutive_absences + 1 where id = student_uuid; end; $$;
create or replace function public.increment_zone_centres(zone_name text) returns void language plpgsql security definer as $$ begin update public.zones set centres = centres + 1 where name = zone_name; end; $$;
