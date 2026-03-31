-- ─── PHASE 1 SCHEMA PATCH ─────────────────────────────────────
-- Run this in the Supabase SQL Editor.

-- Enable pgcrypto for industry-standard encryption
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Add missing 'contact' column to students table
ALTER TABLE public.students 
ADD COLUMN IF NOT EXISTS contact text;

-- 2. Add Aadhaar Encryption Logic
-- Using a secret key (replace 'YOUR_AES_KEY' with a strong key in prod)
CREATE OR REPLACE FUNCTION public.encrypt_aadhaar(aadhaar text, secret_key text DEFAULT 'seva_sahyog_secret') 
RETURNS text AS $$
BEGIN
    RETURN encode(pgp_sym_encrypt(aadhaar, secret_key), 'base64');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.decrypt_aadhaar(encrypted_aadhaar text, secret_key text DEFAULT 'seva_sahyog_secret') 
RETURNS text AS $$
BEGIN
    RETURN pgp_sym_decrypt(decode(encrypted_aadhaar, 'base64'), secret_key);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Fix profiles table (ensure name is mandatory for new users)
ALTER TABLE public.profiles 
ALTER COLUMN name SET NOT NULL;

-- 4. Update the handle_new_user trigger to better handle incoming metadata
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger 
LANGUAGE plpgsql 
SECURITY DEFINER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, name, role)
    VALUES (
        new.id, 
        new.email, 
        COALESCE(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)), 
        COALESCE(new.raw_user_meta_data->>'role', 'teacher')
    )
    ON CONFLICT (id) DO UPDATE 
    SET 
        name = EXCLUDED.name,
        role = EXCLUDED.role;
    RETURN new;
END;
$$;
