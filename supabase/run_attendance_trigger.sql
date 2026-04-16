-- ============================================================
--  Run this in Supabase SQL Editor.
--  It creates a trigger that automatically keeps
--  present_count, absent_count, total_classes, consecutive_absences
--  in sync on every INSERT / UPDATE / DELETE on the attendance table.
--
--  After running this, all existing attendance data will also be
--  recomputed by the final UPDATE statement at the bottom.
-- ============================================================

-- ─── STEP 1: Create the trigger function ─────────────────────
CREATE OR REPLACE FUNCTION public.sync_student_attendance_counters()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  affected_student_id UUID;
BEGIN
  -- Determine which student was affected
  IF TG_OP = 'DELETE' THEN
    affected_student_id := OLD.student_id;
  ELSE
    affected_student_id := NEW.student_id;
  END IF;

  -- Recompute all counters from scratch for that student
  UPDATE public.students
  SET
    present_count = (
      SELECT COUNT(*) FROM public.attendance
      WHERE student_id = affected_student_id AND status = 'present'
    ),
    absent_count = (
      SELECT COUNT(*) FROM public.attendance
      WHERE student_id = affected_student_id AND status IN ('absent', 'dropout', 'late')
    ),
    total_classes = (
      SELECT COUNT(*) FROM public.attendance
      WHERE student_id = affected_student_id
    ),
    consecutive_absences = (
      -- Count the streak of absences from the most recent date backwards
      SELECT COALESCE(
        (
          SELECT COUNT(*)
          FROM (
            SELECT status,
                   ROW_NUMBER() OVER (ORDER BY date DESC) AS rn
            FROM public.attendance
            WHERE student_id = affected_student_id
            ORDER BY date DESC
          ) ranked
          WHERE ranked.rn <= (
            SELECT MIN(sub.rn)
            FROM (
              SELECT status,
                     ROW_NUMBER() OVER (ORDER BY date DESC) as rn
              FROM public.attendance
              WHERE student_id = affected_student_id
            ) sub
            WHERE sub.status NOT IN ('absent', 'dropout')
          )
          AND ranked.status IN ('absent', 'dropout')
        ),
        (
          -- All records are absences
          SELECT COUNT(*) FROM public.attendance
          WHERE student_id = affected_student_id AND status IN ('absent', 'dropout')
        )
      )
    )
  WHERE id = affected_student_id;

  RETURN NEW;
END;
$$;

-- ─── STEP 2: Drop old trigger if it exists ────────────────────
DROP TRIGGER IF EXISTS trg_sync_attendance_counters ON public.attendance;

-- ─── STEP 3: Create the trigger ──────────────────────────────
CREATE TRIGGER trg_sync_attendance_counters
AFTER INSERT OR UPDATE OR DELETE ON public.attendance
FOR EACH ROW
EXECUTE FUNCTION public.sync_student_attendance_counters();

-- ─── STEP 4: Backfill existing data ──────────────────────────
-- This recomputes counters for ALL students that already have
-- attendance records (e.g. from manual marks or the import script).
UPDATE public.students s
SET
  present_count = (
    SELECT COUNT(*) FROM public.attendance a
    WHERE a.student_id = s.id AND a.status = 'present'
  ),
  absent_count = (
    SELECT COUNT(*) FROM public.attendance a
    WHERE a.student_id = s.id AND a.status IN ('absent', 'dropout', 'late')
  ),
  total_classes = (
    SELECT COUNT(*) FROM public.attendance a
    WHERE a.student_id = s.id
  )
WHERE EXISTS (
  SELECT 1 FROM public.attendance a WHERE a.student_id = s.id
);

-- ─── STEP 5: Verify ──────────────────────────────────────────
SELECT
  s.name,
  s.roll,
  s.present_count,
  s.absent_count,
  s.total_classes,
  CASE WHEN s.total_classes > 0
    THEN ROUND(s.present_count::numeric / s.total_classes * 100, 1)
    ELSE 0
  END AS attendance_pct
FROM public.students s
WHERE s.total_classes > 0
ORDER BY attendance_pct DESC
LIMIT 20;
