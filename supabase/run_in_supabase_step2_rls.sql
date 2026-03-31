-- ============================================================
--  STEP 2 OF 3 — Paste this into Supabase SQL Editor and run
-- ============================================================

alter table public.profiles enable row level security; alter table public.zones enable row level security; alter table public.centres enable row level security; alter table public.students enable row level security; alter table public.attendance enable row level security; alter table public.exam_results enable row level security; alter table public.leaves enable row level security; alter table public.diary_entries enable row level security; alter table public.resources enable row level security; alter table public.announcements enable row level security;
create or replace function public.my_role() returns text language sql security definer stable as $$ select role from public.profiles where id = auth.uid() $$;
create or replace function public.my_zone() returns text language sql security definer stable as $$ select zone from public.profiles where id = auth.uid() $$;
create or replace function public.my_centre() returns text language sql security definer stable as $$ select centre from public.profiles where id = auth.uid() $$;
create policy "profiles_select" on public.profiles for select using (id = auth.uid() or public.my_role() = 'admin' or (public.my_role() = 'coordinator' and zone = public.my_zone()));
create policy "profiles_update" on public.profiles for update using (id = auth.uid() or public.my_role() = 'admin');
create policy "profiles_insert" on public.profiles for insert with check (public.my_role() = 'admin');
create policy "zones_select" on public.zones for select using (auth.uid() is not null);
create policy "zones_insert" on public.zones for insert with check (public.my_role() = 'admin');
create policy "zones_update" on public.zones for update using (public.my_role() = 'admin');
create policy "zones_delete" on public.zones for delete using (public.my_role() = 'admin');
create policy "centres_select" on public.centres for select using (auth.uid() is not null);
create policy "centres_insert" on public.centres for insert with check (public.my_role() in ('admin', 'coordinator'));
create policy "centres_update" on public.centres for update using (public.my_role() = 'admin' or (public.my_role() = 'coordinator' and zone = public.my_zone()));
create policy "centres_delete" on public.centres for delete using (public.my_role() = 'admin');
create policy "students_select" on public.students for select using (public.my_role() = 'admin' or (public.my_role() = 'coordinator' and zone = public.my_zone()) or (public.my_role() = 'teacher' and teacher_id = auth.uid()));
create policy "students_insert" on public.students for insert with check (public.my_role() in ('admin', 'coordinator', 'teacher'));
create policy "students_update" on public.students for update using (public.my_role() = 'admin' or (public.my_role() = 'coordinator' and zone = public.my_zone()) or (public.my_role() = 'teacher' and teacher_id = auth.uid()));
create policy "students_delete" on public.students for delete using (public.my_role() = 'admin' or (public.my_role() = 'coordinator' and zone = public.my_zone()));
create policy "attendance_select" on public.attendance for select using (public.my_role() = 'admin' or teacher_id = auth.uid() or exists (select 1 from public.students s where s.id = student_id and s.zone = public.my_zone() and public.my_role() = 'coordinator'));
create policy "attendance_insert" on public.attendance for insert with check (teacher_id = auth.uid() or public.my_role() = 'admin');
create policy "attendance_update" on public.attendance for update using (teacher_id = auth.uid() or public.my_role() = 'admin');
create policy "exam_results_select" on public.exam_results for select using (public.my_role() = 'admin' or teacher_id = auth.uid() or (public.my_role() = 'coordinator' and zone = public.my_zone()));
create policy "exam_results_insert" on public.exam_results for insert with check (teacher_id = auth.uid() or public.my_role() = 'admin');
create policy "exam_results_update" on public.exam_results for update using (teacher_id = auth.uid() or public.my_role() = 'admin');
create policy "leaves_select" on public.leaves for select using (public.my_role() = 'admin' or user_id = auth.uid() or (public.my_role() = 'coordinator' and zone = public.my_zone()));
create policy "leaves_insert" on public.leaves for insert with check (user_id = auth.uid());
create policy "leaves_update" on public.leaves for update using (user_id = auth.uid() or public.my_role() in ('admin', 'coordinator'));
create policy "diary_select" on public.diary_entries for select using (teacher_id = auth.uid() or public.my_role() = 'admin' or (public.my_role() = 'coordinator' and zone = public.my_zone()));
create policy "diary_insert" on public.diary_entries for insert with check (teacher_id = auth.uid());
create policy "diary_update" on public.diary_entries for update using (teacher_id = auth.uid());
create policy "diary_delete" on public.diary_entries for delete using (teacher_id = auth.uid() or public.my_role() = 'admin');
create policy "resources_select" on public.resources for select using (teacher_id = auth.uid() or public.my_role() = 'admin');
create policy "resources_insert" on public.resources for insert with check (teacher_id = auth.uid());
create policy "resources_delete" on public.resources for delete using (teacher_id = auth.uid() or public.my_role() = 'admin');
create policy "announcements_select" on public.announcements for select using (auth.uid() is not null and (zone is null or public.my_role() = 'admin' or zone = public.my_zone()));
create policy "announcements_insert" on public.announcements for insert with check (public.my_role() in ('admin', 'coordinator'));
create policy "announcements_delete" on public.announcements for delete using (author_id = auth.uid() or public.my_role() = 'admin');
