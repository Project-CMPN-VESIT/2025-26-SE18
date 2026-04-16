-- ============================================================
--  SEED: Zones & Centres for Seva Sahyog NGO
--  Run this in Supabase SQL Editor ONCE.
--  Safe to re-run — uses ON CONFLICT DO NOTHING / DO UPDATE.
-- ============================================================

-- ─── STEP 1: Insert the 7 Zones ───────────────────────────────
INSERT INTO public.zones (name, coordinator, centres, teachers, students, status)
VALUES
  ('Udan',       'Pending', 1, 0, 0, 'active'),
  ('Mirabai',    'Pending', 1, 0, 0, 'active'),
  ('Tejaswini',  'Pending', 1, 0, 0, 'active'),
  ('Raigad',     'Pending', 1, 0, 0, 'active'),
  ('Shivneri',   'Pending', 1, 0, 0, 'active'),
  ('Utkarsh',    'Pending', 1, 0, 0, 'active')
ON CONFLICT (name) DO UPDATE SET
  coordinator = EXCLUDED.coordinator,
  centres     = EXCLUDED.centres,
  status      = EXCLUDED.status;

-- ─── STEP 2: Insert the 7 Centres ─────────────────────────────
INSERT INTO public.centres (name, zone, address, teachers, students, status)
VALUES
  ('Udan Secondary Abhyasika',   'Udan',      '', 0, 0, 'active'),
  ('Mirabai Primary Abhyasika',  'Mirabai',   '', 0, 0, 'active'),
  ('Tejaswini Primary Abhyasika','Tejaswini', '', 0, 0, 'active'),
  ('Raigad Primary Abhyasika',   'Raigad',    '', 0, 0, 'active'),
  ('Shivneri Abhyasika',         'Shivneri',  '', 0, 0, 'active'),
  ('Utkarsh Combine Abhyasika',  'Utkarsh',   '', 0, 0, 'active')
ON CONFLICT (name, zone) DO UPDATE SET
  status = EXCLUDED.status;

-- ─── STEP 3: Create a System Import profile ────────────────────
--  This is a placeholder teacher used as teacher_id for all imported records.
--  It does NOT need a real auth.users entry — we insert directly into profiles.
--  COPY the 'id' that is returned — paste it into import_excel_data.js as SYSTEM_TEACHER_ID.

INSERT INTO public.profiles (id, email, name, role, zone, centre, status)
VALUES (
  gen_random_uuid(),
  'system@sevasahayog.import',
  'System Import',
  'teacher',
  '',
  '',
  'active'
)
ON CONFLICT DO NOTHING
RETURNING id, email, name;

-- ─── STEP 4: Verify ───────────────────────────────────────────
SELECT 'zones' AS tbl, count(*) FROM public.zones
UNION ALL
SELECT 'centres', count(*) FROM public.centres
UNION ALL
SELECT 'system profile', count(*) FROM public.profiles WHERE email = 'system@sevasahayog.import';
