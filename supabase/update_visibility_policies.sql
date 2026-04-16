-- ============================================================
--  Run this in Supabase SQL Editor.
--  It relaxes RLS policies so teachers can see imported students
--  and historical attendance records belonging to their centre.
-- ============================================================

-- ─── 1. Update Student Visibility ────────────────────────────
DROP POLICY IF EXISTS "students_select" ON public.students;

CREATE POLICY "students_select" ON public.students 
FOR SELECT USING (
  public.my_role() = 'admin' OR 
  (public.my_role() = 'coordinator' AND zone = public.my_zone()) OR 
  (public.my_role() = 'teacher' AND (teacher_id = auth.uid() OR centre = public.my_centre()))
);

-- ─── 2. Update Attendance Visibility ─────────────────────────
DROP POLICY IF EXISTS "attendance_select" ON public.attendance;

CREATE POLICY "attendance_select" ON public.attendance
FOR SELECT USING (
  public.my_role() = 'admin' OR 
  teacher_id = auth.uid() OR 
  (public.my_role() = 'coordinator' AND EXISTS (
    SELECT 1 FROM public.students s WHERE s.id = student_id AND s.zone = public.my_zone()
  )) OR
  (public.my_role() = 'teacher' AND EXISTS (
    SELECT 1 FROM public.students s WHERE s.id = student_id AND s.centre = public.my_centre()
  ))
);

-- Note: We allow teachers to see ALL attendance in their centre. 
-- This is useful for takeover/historical data review.

-- ─── 3. Update Exam Results Visibility ───────────────────────
DROP POLICY IF EXISTS "exam_results_select" ON public.exam_results;

CREATE POLICY "exam_results_select" ON public.exam_results
FOR SELECT USING (
  public.my_role() = 'admin' OR 
  teacher_id = auth.uid() OR 
  (public.my_role() = 'coordinator' AND zone = public.my_zone()) OR
  (public.my_role() = 'teacher' AND EXISTS (
    SELECT 1 FROM public.students s WHERE s.id = student_id AND s.centre = public.my_centre()
  ))
);
