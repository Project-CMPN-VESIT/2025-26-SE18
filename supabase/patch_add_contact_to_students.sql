-- Fix for "Could not find the 'contact' column of 'students' in the schema cache"
-- Run this in the Supabase SQL Editor:
ALTER TABLE public.students ADD COLUMN IF NOT EXISTS contact text;
