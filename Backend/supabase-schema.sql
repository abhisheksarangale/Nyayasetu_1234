-- ==============================================================================
-- NYAYASETU — COMPLETE SUPABASE POSTGRESQL PRODUCTION DATABASE SCHEMA
-- ==============================================================================
-- File: Backend/supabase-schema.sql
-- Description: Complete schema for NyayaSetu with all 49 Lawyers provisioned in
-- auth.users with login emails, passwords, profiles, lawyer_profiles, directory,
-- appointments, payments, receipts, refunds, payouts, storage, RPCs, and Realtime!
--
-- DEFAULT PASSWORDS:
-- - All Lawyers (49 total): Lawyer@123
-- - Admin (admin@nyayasetu.in): Admin@NyayaSetu2026
-- - Client (client@gmail.com): Client@123
-- ==============================================================================

-- 0. ENABLE EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'client' CHECK (role IN ('client', 'lawyer', 'admin')),
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    city TEXT,
    state TEXT,
    avatar_url TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. LEGAL CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS public.legal_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    icon TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO public.legal_categories (name, slug, description, display_order, is_active)
VALUES
    ('Criminal Law', 'criminal', 'Bail matters, IPC offences, criminal defense, cybercrime & police complaints', 1, true),
    ('Family Law', 'family', 'Divorce, child custody, maintenance, domestic violence & matrimonial disputes', 2, true),
    ('Property Law', 'property', 'Land acquisition, title search, real estate disputes, RERA & registry', 3, true),
    ('Corporate Law', 'corporate', 'Company registration, commercial contracts, M&A, compliance & startup advisory', 4, true),
    ('Civil Law', 'civil', 'Recovery suits, injunctions, partition suits, contract breaches & mediation', 5, true),
    ('Financial Law', 'financial', 'Banking disputes, debt recovery tribunal (DRT), NCLT, insolvency & cheque bounce', 6, true),
    ('Cyber Law', 'cyber', 'Data privacy, online fraud, intellectual cyber breaches & IT Act violations', 7, true),
    ('Labour & Employment Law', 'labour', 'Workplace harassment, wrongful termination, gratuity, PF & labour union disputes', 8, true),
    ('Taxation & GST', 'taxation', 'Direct tax, income tax appeals, GST litigation, customs & corporate tax planning', 9, true),
    ('Constitutional Law', 'constitutional', 'Writ petitions, fundamental rights enforcement, public interest litigation (PIL) & High Court appeals', 10, true),
    ('Consumer Protection', 'consumer', 'Product liability, medical negligence, service deficiency & Consumer Forum claims', 11, true),
    ('Intellectual Property', 'intellectual_property', 'Trademarks, patents, copyrights, trade secrets & IP infringement litigation', 12, true),
    ('Environmental Law', 'environmental', 'NGT litigations, pollution control compliance, forest clearances & environmental audits', 13, true)
ON CONFLICT (slug) DO UPDATE 
SET name = EXCLUDED.name, description = EXCLUDED.description, display_order = EXCLUDED.display_order;

-- 3. LAWYER PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.lawyer_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    directory_id TEXT UNIQUE,
    full_name TEXT NOT NULL,
    display_name TEXT,
    email TEXT,
    phone TEXT,
    photo_url TEXT,
    profile_photo_path TEXT,
    category_id UUID REFERENCES public.legal_categories(id) ON DELETE SET NULL,
    legal_category TEXT NOT NULL,
    specialization TEXT,
    expertise_summary TEXT,
    education TEXT,
    college_university TEXT,
    bar_council_name TEXT,
    bar_enrollment_number TEXT,
    years_experience INTEGER NOT NULL DEFAULT 1 CHECK (years_experience >= 0),
    languages TEXT[] NOT NULL DEFAULT '{}',
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    locality TEXT,
    availability TEXT NOT NULL DEFAULT 'today',
    consultation_fee NUMERIC(10, 2) NOT NULL DEFAULT 500.00 CHECK (consultation_fee >= 0),
    approval_status TEXT NOT NULL DEFAULT 'APPROVED' CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED')),
    verification_status TEXT NOT NULL DEFAULT 'approved' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
    is_verified BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    rating_average NUMERIC(3, 2) NOT NULL DEFAULT 0.00 CHECK (rating_average >= 0.00 AND rating_average <= 5.00),
    review_count INTEGER NOT NULL DEFAULT 0 CHECK (review_count >= 0),
    rejection_reason TEXT,
    approved_at TIMESTAMPTZ DEFAULT NOW(),
    rejected_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. LAWYER DIRECTORY PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.lawyer_directory_profiles (
    id TEXT PRIMARY KEY,
    legacy_id INTEGER UNIQUE NOT NULL,
    linked_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    test_route_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    display_name TEXT NOT NULL,
    gender TEXT,
    legal_category TEXT NOT NULL,
    years_experience INTEGER NOT NULL DEFAULT 1,
    seed_rating NUMERIC(3, 2) NOT NULL DEFAULT 4.50,
    seed_review_count INTEGER NOT NULL DEFAULT 10,
    consultation_fee NUMERIC(10, 2) NOT NULL DEFAULT 500.00,
    locality TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    languages TEXT[] NOT NULL DEFAULT '{}',
    availability TEXT NOT NULL DEFAULT 'today',
    profile_photo_path TEXT,
    source TEXT NOT NULL DEFAULT 'directory',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_bookable BOOLEAN NOT NULL DEFAULT TRUE,
    is_test_bookable BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. APPOINTMENTS TABLE
CREATE TABLE IF NOT EXISTS public.appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    directory_profile_id TEXT,
    public_lawyer_name TEXT,
    public_lawyer_image TEXT,
    legal_category TEXT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TEXT NOT NULL,
    consultation_mode TEXT NOT NULL DEFAULT 'Online Video Call',
    consultation_fee NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    problem_description TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'PAYMENT_PENDING' CHECK (
        status IN (
            'PAYMENT_PENDING',
            'PENDING_ACCEPTANCE',
            'PAID',
            'ACCEPTED',
            'LAWYER_ACCEPTED',
            'CONFIRMED',
            'REJECTED',
            'LAWYER_REJECTED',
            'COMPLETED',
            'CANCELLED',
            'REFUND_PENDING',
            'REFUNDED'
        )
    ),
    rejection_category TEXT,
    rejection_comment TEXT,
    rejection_reason TEXT,
    accepted_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. PAYMENTS TABLE
CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    platform_fee NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    lawyer_share NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    payment_method TEXT NOT NULL DEFAULT 'UPI',
    upi_transaction_id TEXT,
    transaction_id TEXT,
    utr_number TEXT,
    status TEXT NOT NULL DEFAULT 'COMPLETED' CHECK (
        status IN ('PENDING_VERIFICATION', 'COMPLETED', 'SUCCESS', 'VERIFIED', 'REJECTED', 'REFUNDED')
    ),
    verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    verification_note TEXT,
    rejection_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. RECEIPTS TABLE
CREATE TABLE IF NOT EXISTS public.receipts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    receipt_number TEXT UNIQUE NOT NULL,
    payment_id UUID UNIQUE REFERENCES public.payments(id) ON DELETE CASCADE,
    appointment_id UUID UNIQUE REFERENCES public.appointments(id) ON DELETE CASCADE,
    client_name TEXT NOT NULL,
    lawyer_name TEXT NOT NULL,
    legal_category TEXT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TEXT NOT NULL,
    consultation_fee NUMERIC(10, 2) NOT NULL,
    platform_fee NUMERIC(10, 2) NOT NULL,
    lawyer_share NUMERIC(10, 2) NOT NULL,
    total_amount_paid NUMERIC(10, 2) NOT NULL,
    payment_method TEXT NOT NULL,
    transaction_id TEXT,
    receipt_pdf_path TEXT,
    status TEXT NOT NULL DEFAULT 'ISSUED',
    issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. REFUNDS TABLE
CREATE TABLE IF NOT EXISTS public.refunds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    payment_id UUID NOT NULL REFERENCES public.payments(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    refund_percentage NUMERIC(5, 2) NOT NULL DEFAULT 100.00,
    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'PROCESSING', 'COMPLETED', 'FAILED')),
    reason TEXT NOT NULL,
    processed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    processed_at TIMESTAMPTZ,
    reference_number TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. PAYOUTS TABLE
CREATE TABLE IF NOT EXISTS public.payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID UNIQUE REFERENCES public.appointments(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    platform_fee NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    status TEXT NOT NULL DEFAULT 'QUEUED' CHECK (status IN ('QUEUED', 'PENDING', 'PROCESSING', 'RELEASED', 'COMPLETED', 'FAILED', 'CANCELLED')),
    released_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    released_at TIMESTAMPTZ,
    reference_number TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. REVIEWS TABLE
CREATE TABLE IF NOT EXISTS public.reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID UNIQUE NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    client_name TEXT NOT NULL,
    rating NUMERIC(2, 1) NOT NULL CHECK (rating >= 1.0 AND rating <= 5.0),
    review_text TEXT,
    is_public BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 11. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    link_url TEXT,
    type TEXT NOT NULL DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error', 'appointment', 'payment', 'refund', 'payout')),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 12. APPOINTMENT DOCUMENTS TABLE
CREATE TABLE IF NOT EXISTS public.appointment_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id UUID NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lawyer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    mime_type TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- AUTO USER CREATION FUNCTION
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, role, full_name, email, phone, is_active)
    VALUES (
        NEW.id,
        COALESCE((NEW.raw_user_meta_data->>'role')::TEXT, 'client'),
        COALESCE((NEW.raw_user_meta_data->>'full_name')::TEXT, split_part(NEW.email, '@', 1)),
        NEW.email,
        COALESCE((NEW.raw_user_meta_data->>'phone')::TEXT, ''),
        TRUE
    )
    ON CONFLICT (id) DO UPDATE
    SET 
        role = EXCLUDED.role,
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- SEED DEMO CLIENT & ADMIN ACCOUNTS INTO auth.users & profiles
-- ==============================================================================
DO $$
DECLARE
    v_admin_id UUID := '00000000-0000-0000-0000-000000000001';
    v_client_id UUID := '00000000-0000-0000-0000-000000000002';
    v_admin_pw TEXT := crypt('Admin@NyayaSetu2026', gen_salt('bf'));
    v_client_pw TEXT := crypt('Client@123', gen_salt('bf'));
BEGIN
    -- Admin Account
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        v_admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'admin@nyayasetu.in', v_admin_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"NyayaSetu Administrator","role":"admin"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (v_admin_id::text, v_admin_id, jsonb_build_object('sub', v_admin_id::text, 'email', 'admin@nyayasetu.in'), 'email', v_admin_id::text, NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, is_active)
    VALUES (v_admin_id, 'admin', 'NyayaSetu Administrator', 'admin@nyayasetu.in', true)
    ON CONFLICT (id) DO UPDATE SET role = 'admin', full_name = EXCLUDED.full_name;

    -- Client Account
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        v_client_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'client@gmail.com', v_client_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Rahul Verma","role":"client"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES (v_client_id::text, v_client_id, jsonb_build_object('sub', v_client_id::text, 'email', 'client@gmail.com'), 'email', v_client_id::text, NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, city, state, is_active)
    VALUES (v_client_id, 'client', 'Rahul Verma', 'client@gmail.com', 'Mumbai', 'Maharashtra', true)
    ON CONFLICT (id) DO UPDATE SET role = 'client', full_name = EXCLUDED.full_name;
END;
$$;

-- ==============================================================================
-- SEED ALL 49 LAWYERS INTO auth.users, profiles, lawyer_profiles, lawyer_directory_profiles
-- ==============================================================================
DO $$
DECLARE
    v_pw TEXT := crypt('Lawyer@123', gen_salt('bf'));
BEGIN

    -- Lawyer 1: Adv. Abhishek Sarangale (abhisheksarangale@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'abhisheksarangale@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Abhishek Sarangale","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000001', 'email', 'abhisheksarangale@gmail.com'), 'email', '10000000-0000-0000-0000-000000000001', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000001', 'lawyer', 'Adv. Abhishek Sarangale', 'abhisheksarangale@gmail.com', '+91 98200 11001', 'Mumbai', 'Maharashtra', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000001', 'lawyer-1', 'Adv. Abhishek Sarangale', 'Adv. Abhishek Sarangale', 'abhisheksarangale@gmail.com', '+91 98200 11001',
        'Abhishek Sarangale.jpg', 'family', 'Matrimonial Disputes & Child Custody', 12,
        ARRAY['Hindi', 'Marathi', 'English'], 'Bandra West', 'Mumbai', 'Maharashtra', 'today', 1.00,
        'APPROVED', 'approved', true, true, 4.90, 89
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-1', 1, '10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Adv. Abhishek Sarangale', 'Male',
        'family', 12, 4.90, 89,
        1.00, 'Bandra West', 'Mumbai', 'Maharashtra', ARRAY['Hindi', 'Marathi', 'English'], 'today',
        'Abhishek Sarangale.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 2: Adv. Aaditya Verma (aaditya.verma@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'aaditya.verma@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Aaditya Verma","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000002', 'email', 'aaditya.verma@gmail.com'), 'email', '10000000-0000-0000-0000-000000000002', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000002', 'lawyer', 'Adv. Aaditya Verma', 'aaditya.verma@gmail.com', '+91 98200 11002', 'Bengaluru', 'Karnataka', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000002', 'lawyer-2', 'Adv. Aaditya Verma', 'Adv. Aaditya Verma', 'aaditya.verma@gmail.com', '+91 98200 11002',
        'Aaditya Verma.jpg', 'property', 'RERA Disputes & Real Estate Title Verification', 8,
        ARRAY['English', 'Hindi', 'Kannada'], 'Indiranagar', 'Bengaluru', 'Karnataka', 'today', 1.00,
        'APPROVED', 'approved', true, true, 4.70, 45
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-2', 2, '10000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', 'Adv. Aaditya Verma', 'Male',
        'property', 8, 4.70, 45,
        1.00, 'Indiranagar', 'Bengaluru', 'Karnataka', ARRAY['English', 'Hindi', 'Kannada'], 'today',
        'Aaditya Verma.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 3: Adv. Aditya Singh (aditya.singh@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'aditya.singh@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Aditya Singh","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000003', 'email', 'aditya.singh@gmail.com'), 'email', '10000000-0000-0000-0000-000000000003', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000003', 'lawyer', 'Adv. Aditya Singh', 'aditya.singh@gmail.com', '+91 98200 11003', 'Delhi', 'NCR', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000003', 'lawyer-3', 'Adv. Aditya Singh', 'Adv. Aditya Singh', 'aditya.singh@gmail.com', '+91 98200 11003',
        'Aditya Singh.jpg', 'criminal', 'Bail Matters & Criminal Trial Defense', 14,
        ARRAY['Hindi', 'English'], 'Connaught Place', 'Delhi', 'NCR', 'tomorrow', 1.00,
        'APPROVED', 'approved', true, true, 4.80, 52
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-3', 3, '10000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000003', 'Adv. Aditya Singh', 'Male',
        'criminal', 14, 4.80, 52,
        1.00, 'Connaught Place', 'Delhi', 'NCR', ARRAY['Hindi', 'English'], 'tomorrow',
        'Aditya Singh.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 4: Adv. Akash Reddy (akash.reddy@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'akash.reddy@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Akash Reddy","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000004', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000004', 'email', 'akash.reddy@gmail.com'), 'email', '10000000-0000-0000-0000-000000000004', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000004', 'lawyer', 'Adv. Akash Reddy', 'akash.reddy@gmail.com', '+91 98200 11004', 'Hyderabad', 'Telangana', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000004', 'lawyer-4', 'Adv. Akash Reddy', 'Adv. Akash Reddy', 'akash.reddy@gmail.com', '+91 98200 11004',
        'Akash Reddy.jpg', 'corporate', 'Startup Structuring & Commercial Contracts', 10,
        ARRAY['Telugu', 'English', 'Hindi'], 'Hitec City', 'Hyderabad', 'Telangana', 'today', 1.00,
        'APPROVED', 'approved', true, true, 4.90, 73
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-4', 4, '10000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000004', 'Adv. Akash Reddy', 'Male',
        'corporate', 10, 4.90, 73,
        1.00, 'Hitec City', 'Hyderabad', 'Telangana', ARRAY['Telugu', 'English', 'Hindi'], 'today',
        'Akash Reddy.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 5: Adv. Aman Kapoor (aman.kapoor@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'aman.kapoor@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Aman Kapoor","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000005', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000005', 'email', 'aman.kapoor@gmail.com'), 'email', '10000000-0000-0000-0000-000000000005', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000005', 'lawyer', 'Adv. Aman Kapoor', 'aman.kapoor@gmail.com', '+91 98200 11005', 'Chandigarh', 'Punjab', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000005', 'lawyer-5', 'Adv. Aman Kapoor', 'Adv. Aman Kapoor', 'aman.kapoor@gmail.com', '+91 98200 11005',
        'Aman Kapoor.jpg', 'civil', 'Partition Suits & Recovery Litigation', 9,
        ARRAY['Hindi', 'Punjabi', 'English'], 'Sector 17', 'Chandigarh', 'Punjab', 'week', 1.00,
        'APPROVED', 'approved', true, true, 4.60, 41
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-5', 5, '10000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000005', 'Adv. Aman Kapoor', 'Male',
        'civil', 9, 4.60, 41,
        1.00, 'Sector 17', 'Chandigarh', 'Punjab', ARRAY['Hindi', 'Punjabi', 'English'], 'week',
        'Aman Kapoor.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 6: Adv. Amit Desai (amit.desai@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'amit.desai@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Amit Desai","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000006', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000006', 'email', 'amit.desai@gmail.com'), 'email', '10000000-0000-0000-0000-000000000006', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000006', 'lawyer', 'Adv. Amit Desai', 'amit.desai@gmail.com', '+91 98200 11006', 'Ahmedabad', 'Gujarat', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000006', 'lawyer-6', 'Adv. Amit Desai', 'Adv. Amit Desai', 'amit.desai@gmail.com', '+91 98200 11006',
        'Amit Desai.jpg', 'financial', 'Cheque Bounce (Sec 138) & DRT Proceedings', 15,
        ARRAY['Gujarati', 'Hindi', 'English'], 'Ashram Road', 'Ahmedabad', 'Gujarat', 'today', 1.00,
        'APPROVED', 'approved', true, true, 4.80, 67
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-6', 6, '10000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000006', 'Adv. Amit Desai', 'Male',
        'financial', 15, 4.80, 67,
        1.00, 'Ashram Road', 'Ahmedabad', 'Gujarat', ARRAY['Gujarati', 'Hindi', 'English'], 'today',
        'Amit Desai.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 7: Adv. Ananya Roy (ananya.roy@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'ananya.roy@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Ananya Roy","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000007', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000007', 'email', 'ananya.roy@gmail.com'), 'email', '10000000-0000-0000-0000-000000000007', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000007', 'lawyer', 'Adv. Ananya Roy', 'ananya.roy@gmail.com', '+91 98200 11007', 'Kolkata', 'West Bengal', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000007', 'lawyer-7', 'Adv. Ananya Roy', 'Adv. Ananya Roy', 'ananya.roy@gmail.com', '+91 98200 11007',
        'Ananya Roy.jpg', 'cyber', 'Online Financial Fraud & Data Protection', 7,
        ARRAY['Bengali', 'English', 'Hindi'], 'Salt Lake', 'Kolkata', 'West Bengal', 'today', 1.00,
        'APPROVED', 'approved', true, true, 4.90, 58
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-7', 7, '10000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000007', 'Adv. Ananya Roy', 'Female',
        'cyber', 7, 4.90, 58,
        1.00, 'Salt Lake', 'Kolkata', 'West Bengal', ARRAY['Bengali', 'English', 'Hindi'], 'today',
        'Ananya Roy.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 8: Adv. Anika Sharma (anika.sharma@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'anika.sharma@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Anika Sharma","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000008', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000008', 'email', 'anika.sharma@gmail.com'), 'email', '10000000-0000-0000-0000-000000000008', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000008', 'lawyer', 'Adv. Anika Sharma', 'anika.sharma@gmail.com', '+91 98200 11008', 'Jaipur', 'Rajasthan', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000008', 'lawyer-8', 'Adv. Anika Sharma', 'Adv. Anika Sharma', 'anika.sharma@gmail.com', '+91 98200 11008',
        'Anika Sharma.jpg', 'labour', 'Wrongful Termination & POSH Compliance', 11,
        ARRAY['Hindi', 'English'], 'Civil Lines', 'Jaipur', 'Rajasthan', 'tomorrow', 1.00,
        'APPROVED', 'approved', true, true, 4.70, 49
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-8', 8, '10000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000008', 'Adv. Anika Sharma', 'Female',
        'labour', 11, 4.70, 49,
        1.00, 'Civil Lines', 'Jaipur', 'Rajasthan', ARRAY['Hindi', 'English'], 'tomorrow',
        'Anika Sharma.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 9: Adv. Aniruddh Joshi (aniruddh.joshi@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'aniruddh.joshi@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Aniruddh Joshi","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000009', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000009', 'email', 'aniruddh.joshi@gmail.com'), 'email', '10000000-0000-0000-0000-000000000009', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000009', 'lawyer', 'Adv. Aniruddh Joshi', 'aniruddh.joshi@gmail.com', '+91 98200 11009', 'Pune', 'Maharashtra', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000009', 'lawyer-9', 'Adv. Aniruddh Joshi', 'Adv. Aniruddh Joshi', 'aniruddh.joshi@gmail.com', '+91 98200 11009',
        'Aniruddh Joshi.jpg', 'taxation', 'GST Litigation & Income Tax Appeals', 13,
        ARRAY['Marathi', 'Hindi', 'English'], 'Shivaji Nagar', 'Pune', 'Maharashtra', 'today', 1.00,
        'APPROVED', 'approved', true, true, 4.80, 81
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-9', 9, '10000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000009', 'Adv. Aniruddh Joshi', 'Male',
        'taxation', 13, 4.80, 81,
        1.00, 'Shivaji Nagar', 'Pune', 'Maharashtra', ARRAY['Marathi', 'Hindi', 'English'], 'today',
        'Aniruddh Joshi.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 10: Adv. Ankita Sen (ankita.sen@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'ankita.sen@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Ankita Sen","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000010', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000010', 'email', 'ankita.sen@gmail.com'), 'email', '10000000-0000-0000-0000-000000000010', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000010', 'lawyer', 'Adv. Ankita Sen', 'ankita.sen@gmail.com', '+91 98200 11010', 'Kolkata', 'West Bengal', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000010', 'lawyer-10', 'Adv. Ankita Sen', 'Adv. Ankita Sen', 'ankita.sen@gmail.com', '+91 98200 11010',
        'Ankita Sen.jpg', 'constitutional', 'High Court Writ Petitions & Fundamental Rights', 16,
        ARRAY['Bengali', 'English', 'Hindi'], 'Alipore', 'Kolkata', 'West Bengal', 'today', 1.00,
        'APPROVED', 'approved', true, true, 4.90, 94
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-10', 10, '10000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000010', 'Adv. Ankita Sen', 'Female',
        'constitutional', 16, 4.90, 94,
        1.00, 'Alipore', 'Kolkata', 'West Bengal', ARRAY['Bengali', 'English', 'Hindi'], 'today',
        'Ankita Sen.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 11: Adv. Aravind Menon (aravind.menon@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'aravind.menon@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Aravind Menon","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000011', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000011', 'email', 'aravind.menon@gmail.com'), 'email', '10000000-0000-0000-0000-000000000011', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000011', 'lawyer', 'Adv. Aravind Menon', 'aravind.menon@gmail.com', '+91 98200 11011', 'Kochi', 'Kerala', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000011', 'lawyer-11', 'Adv. Aravind Menon', 'Adv. Aravind Menon', 'aravind.menon@gmail.com', '+91 98200 11011',
        'Aravind Menon.jpg', 'consumer', 'Consumer Court Disputes & Medical Negligence', 10,
        ARRAY['Malayalam', 'English', 'Hindi'], 'MG Road', 'Kochi', 'Kerala', 'week', 1.00,
        'APPROVED', 'approved', true, true, 4.60, 39
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-11', 11, '10000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000011', 'Adv. Aravind Menon', 'Male',
        'consumer', 10, 4.60, 39,
        1.00, 'MG Road', 'Kochi', 'Kerala', ARRAY['Malayalam', 'English', 'Hindi'], 'week',
        'Aravind Menon.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 12: Adv. Arjun Nair (arjun.nair@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'arjun.nair@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Arjun Nair","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000012', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000012', 'email', 'arjun.nair@gmail.com'), 'email', '10000000-0000-0000-0000-000000000012', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000012', 'lawyer', 'Adv. Arjun Nair', 'arjun.nair@gmail.com', '+91 98200 11012', 'Chennai', 'Tamil Nadu', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000012', 'lawyer-12', 'Adv. Arjun Nair', 'Adv. Arjun Nair', 'arjun.nair@gmail.com', '+91 98200 11012',
        'Arjun Nair.jpg', 'intellectual_property', 'Trademark Registration & Copyright Infringement', 8,
        ARRAY['Tamil', 'English', 'Hindi'], 'Anna Nagar', 'Chennai', 'Tamil Nadu', 'today', 1.00,
        'APPROVED', 'approved', true, true, 4.80, 62
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-12', 12, '10000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000012', 'Adv. Arjun Nair', 'Male',
        'intellectual_property', 8, 4.80, 62,
        1.00, 'Anna Nagar', 'Chennai', 'Tamil Nadu', ARRAY['Tamil', 'English', 'Hindi'], 'today',
        'Arjun Nair.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 13: Adv. Avani Iyer (avani.iyer@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000013', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'avani.iyer@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Avani Iyer","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000013', '10000000-0000-0000-0000-000000000013', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000013', 'email', 'avani.iyer@gmail.com'), 'email', '10000000-0000-0000-0000-000000000013', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000013', 'lawyer', 'Adv. Avani Iyer', 'avani.iyer@gmail.com', '+91 98200 11013', 'Bengaluru', 'Karnataka', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000013', 'lawyer-13', 'Adv. Avani Iyer', 'Adv. Avani Iyer', 'avani.iyer@gmail.com', '+91 98200 11013',
        'Avani Iyer.jpg', 'environmental', 'NGT Compliance & Pollution Control Board Matters', 12,
        ARRAY['Kannada', 'Tamil', 'English', 'Hindi'], 'Malleswaram', 'Bengaluru', 'Karnataka', 'today', 1.00,
        'APPROVED', 'approved', true, true, 4.90, 77
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-13', 13, '10000000-0000-0000-0000-000000000013', '10000000-0000-0000-0000-000000000013', 'Adv. Avani Iyer', 'Female',
        'environmental', 12, 4.90, 77,
        1.00, 'Malleswaram', 'Bengaluru', 'Karnataka', ARRAY['Kannada', 'Tamil', 'English', 'Hindi'], 'today',
        'Avani Iyer.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 14: Adv. Bhavna Kulkarni (bhavna.kulkarni@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000014', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'bhavna.kulkarni@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Bhavna Kulkarni","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000014', '10000000-0000-0000-0000-000000000014', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000014', 'email', 'bhavna.kulkarni@gmail.com'), 'email', '10000000-0000-0000-0000-000000000014', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000014', 'lawyer', 'Adv. Bhavna Kulkarni', 'bhavna.kulkarni@gmail.com', '+91 98200 11014', 'Pune', 'Maharashtra', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000014', 'lawyer-14', 'Adv. Bhavna Kulkarni', 'Adv. Bhavna Kulkarni', 'bhavna.kulkarni@gmail.com', '+91 98200 11014',
        'Bhavna Kulkarni.jpg', 'criminal', 'Criminal Defense & Anticipatory Bail', 11,
        ARRAY['Marathi', 'Hindi', 'English'], 'Deccan', 'Pune', 'Maharashtra', 'today', 800.00,
        'APPROVED', 'approved', true, true, 4.80, 56
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-14', 14, '10000000-0000-0000-0000-000000000014', '10000000-0000-0000-0000-000000000014', 'Adv. Bhavna Kulkarni', 'Female',
        'criminal', 11, 4.80, 56,
        800.00, 'Deccan', 'Pune', 'Maharashtra', ARRAY['Marathi', 'Hindi', 'English'], 'today',
        'Bhavna Kulkarni.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 15: Adv. Chetan Bhatt (chetan.bhatt@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000015', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'chetan.bhatt@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Chetan Bhatt","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000015', '10000000-0000-0000-0000-000000000015', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000015', 'email', 'chetan.bhatt@gmail.com'), 'email', '10000000-0000-0000-0000-000000000015', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000015', 'lawyer', 'Adv. Chetan Bhatt', 'chetan.bhatt@gmail.com', '+91 98200 11015', 'Ahmedabad', 'Gujarat', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000015', 'lawyer-15', 'Adv. Chetan Bhatt', 'Adv. Chetan Bhatt', 'chetan.bhatt@gmail.com', '+91 98200 11015',
        'Chetan Bhatt.jpg', 'family', 'Mutual Consent Divorce & Domestic Settlements', 15,
        ARRAY['Gujarati', 'Hindi', 'English'], 'Navrangpura', 'Ahmedabad', 'Gujarat', 'tomorrow', 1200.00,
        'APPROVED', 'approved', true, true, 4.70, 72
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-15', 15, '10000000-0000-0000-0000-000000000015', '10000000-0000-0000-0000-000000000015', 'Adv. Chetan Bhatt', 'Male',
        'family', 15, 4.70, 72,
        1200.00, 'Navrangpura', 'Ahmedabad', 'Gujarat', ARRAY['Gujarati', 'Hindi', 'English'], 'tomorrow',
        'Chetan Bhatt.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 16: Adv. Deepa Sundaram (deepa.sundaram@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000016', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'deepa.sundaram@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Deepa Sundaram","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000016', '10000000-0000-0000-0000-000000000016', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000016', 'email', 'deepa.sundaram@gmail.com'), 'email', '10000000-0000-0000-0000-000000000016', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000016', 'lawyer', 'Adv. Deepa Sundaram', 'deepa.sundaram@gmail.com', '+91 98200 11016', 'Chennai', 'Tamil Nadu', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000016', 'lawyer-16', 'Adv. Deepa Sundaram', 'Adv. Deepa Sundaram', 'deepa.sundaram@gmail.com', '+91 98200 11016',
        'Deepa Sundaram.jpg', 'property', 'Ancestral Property Partition & Title Opinions', 9,
        ARRAY['Tamil', 'English'], 'T. Nagar', 'Chennai', 'Tamil Nadu', 'today', 950.00,
        'APPROVED', 'approved', true, true, 4.60, 48
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-16', 16, '10000000-0000-0000-0000-000000000016', '10000000-0000-0000-0000-000000000016', 'Adv. Deepa Sundaram', 'Female',
        'property', 9, 4.60, 48,
        950.00, 'T. Nagar', 'Chennai', 'Tamil Nadu', ARRAY['Tamil', 'English'], 'today',
        'Deepa Sundaram.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 17: Adv. Devendra Rathore (devendra.rathore@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000017', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'devendra.rathore@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Devendra Rathore","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000017', '10000000-0000-0000-0000-000000000017', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000017', 'email', 'devendra.rathore@gmail.com'), 'email', '10000000-0000-0000-0000-000000000017', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000017', 'lawyer', 'Adv. Devendra Rathore', 'devendra.rathore@gmail.com', '+91 98200 11017', 'Gurugram', 'Haryana', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000017', 'lawyer-17', 'Adv. Devendra Rathore', 'Adv. Devendra Rathore', 'devendra.rathore@gmail.com', '+91 98200 11017',
        'Devendra Rathore.jpg', 'corporate', 'M&A, Venture Capital & Corporate Governance', 18,
        ARRAY['Hindi', 'English'], 'Cyber City', 'Gurugram', 'Haryana', 'today', 2500.00,
        'APPROVED', 'approved', true, true, 4.90, 110
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-17', 17, '10000000-0000-0000-0000-000000000017', '10000000-0000-0000-0000-000000000017', 'Adv. Devendra Rathore', 'Male',
        'corporate', 18, 4.90, 110,
        2500.00, 'Cyber City', 'Gurugram', 'Haryana', ARRAY['Hindi', 'English'], 'today',
        'Devendra Rathore.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 18: Adv. Divya Pillai (divya.pillai@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000018', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'divya.pillai@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Divya Pillai","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000018', '10000000-0000-0000-0000-000000000018', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000018', 'email', 'divya.pillai@gmail.com'), 'email', '10000000-0000-0000-0000-000000000018', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000018', 'lawyer', 'Adv. Divya Pillai', 'divya.pillai@gmail.com', '+91 98200 11018', 'Thiruvananthapuram', 'Kerala', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000018', 'lawyer-18', 'Adv. Divya Pillai', 'Adv. Divya Pillai', 'divya.pillai@gmail.com', '+91 98200 11018',
        'Divya Pillai.jpg', 'civil', 'Contractual Injunctions & Specific Performance', 13,
        ARRAY['Malayalam', 'English', 'Hindi'], 'Kowdiar', 'Thiruvananthapuram', 'Kerala', 'today', 1100.00,
        'APPROVED', 'approved', true, true, 4.80, 64
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-18', 18, '10000000-0000-0000-0000-000000000018', '10000000-0000-0000-0000-000000000018', 'Adv. Divya Pillai', 'Female',
        'civil', 13, 4.80, 64,
        1100.00, 'Kowdiar', 'Thiruvananthapuram', 'Kerala', ARRAY['Malayalam', 'English', 'Hindi'], 'today',
        'Divya Pillai.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 19: Adv. Farhan Qureshi (farhan.qureshi@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000019', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'farhan.qureshi@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Farhan Qureshi","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000019', '10000000-0000-0000-0000-000000000019', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000019', 'email', 'farhan.qureshi@gmail.com'), 'email', '10000000-0000-0000-0000-000000000019', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000019', 'lawyer', 'Adv. Farhan Qureshi', 'farhan.qureshi@gmail.com', '+91 98200 11019', 'Lucknow', 'Uttar Pradesh', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000019', 'lawyer-19', 'Adv. Farhan Qureshi', 'Adv. Farhan Qureshi', 'farhan.qureshi@gmail.com', '+91 98200 11019',
        'Farhan Qureshi.jpg', 'financial', 'Banking Fraud, Loan Restructuring & Recovery', 7,
        ARRAY['Hindi', 'Urdu', 'English'], 'Hazratganj', 'Lucknow', 'Uttar Pradesh', 'tomorrow', 750.00,
        'APPROVED', 'approved', true, true, 4.50, 31
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-19', 19, '10000000-0000-0000-0000-000000000019', '10000000-0000-0000-0000-000000000019', 'Adv. Farhan Qureshi', 'Male',
        'financial', 7, 4.50, 31,
        750.00, 'Hazratganj', 'Lucknow', 'Uttar Pradesh', ARRAY['Hindi', 'Urdu', 'English'], 'tomorrow',
        'Farhan Qureshi.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 20: Adv. Gautami Hegde (gautami.hegde@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'gautami.hegde@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Gautami Hegde","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000020', '10000000-0000-0000-0000-000000000020', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000020', 'email', 'gautami.hegde@gmail.com'), 'email', '10000000-0000-0000-0000-000000000020', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000020', 'lawyer', 'Adv. Gautami Hegde', 'gautami.hegde@gmail.com', '+91 98200 11020', 'Bengaluru', 'Karnataka', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000020', 'lawyer-20', 'Adv. Gautami Hegde', 'Adv. Gautami Hegde', 'gautami.hegde@gmail.com', '+91 98200 11020',
        'Gautami Hegde.jpg', 'cyber', 'IT Act Offenses & Digital IP Protection', 10,
        ARRAY['Kannada', 'English', 'Hindi'], 'Koramangala', 'Bengaluru', 'Karnataka', 'today', 1500.00,
        'APPROVED', 'approved', true, true, 4.90, 85
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-20', 20, '10000000-0000-0000-0000-000000000020', '10000000-0000-0000-0000-000000000020', 'Adv. Gautami Hegde', 'Female',
        'cyber', 10, 4.90, 85,
        1500.00, 'Koramangala', 'Bengaluru', 'Karnataka', ARRAY['Kannada', 'English', 'Hindi'], 'today',
        'Gautami Hegde.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 21: Adv. Harshvardhan Jain (harshvardhan.jain@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'harshvardhan.jain@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Harshvardhan Jain","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000021', '10000000-0000-0000-0000-000000000021', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000021', 'email', 'harshvardhan.jain@gmail.com'), 'email', '10000000-0000-0000-0000-000000000021', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000021', 'lawyer', 'Adv. Harshvardhan Jain', 'harshvardhan.jain@gmail.com', '+91 98200 11021', 'Jaipur', 'Rajasthan', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000021', 'lawyer-21', 'Adv. Harshvardhan Jain', 'Adv. Harshvardhan Jain', 'harshvardhan.jain@gmail.com', '+91 98200 11021',
        'Harshvardhan Jain.jpg', 'labour', 'Industrial Disputes & Employee Compensation', 14,
        ARRAY['Hindi', 'English'], 'Malviya Nagar', 'Jaipur', 'Rajasthan', 'today', 1000.00,
        'APPROVED', 'approved', true, true, 4.70, 59
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-21', 21, '10000000-0000-0000-0000-000000000021', '10000000-0000-0000-0000-000000000021', 'Adv. Harshvardhan Jain', 'Male',
        'labour', 14, 4.70, 59,
        1000.00, 'Malviya Nagar', 'Jaipur', 'Rajasthan', ARRAY['Hindi', 'English'], 'today',
        'Harshvardhan Jain.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 22: Adv. Ishita Mukherjee (ishita.mukherjee@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'ishita.mukherjee@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Ishita Mukherjee","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000022', '10000000-0000-0000-0000-000000000022', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000022', 'email', 'ishita.mukherjee@gmail.com'), 'email', '10000000-0000-0000-0000-000000000022', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000022', 'lawyer', 'Adv. Ishita Mukherjee', 'ishita.mukherjee@gmail.com', '+91 98200 11022', 'Kolkata', 'West Bengal', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000022', 'lawyer-22', 'Adv. Ishita Mukherjee', 'Adv. Ishita Mukherjee', 'ishita.mukherjee@gmail.com', '+91 98200 11022',
        'Ishita Mukherjee.jpg', 'taxation', 'Corporate Tax Assessment & Customs Tribunal', 12,
        ARRAY['Bengali', 'English', 'Hindi'], 'Park Street', 'Kolkata', 'West Bengal', 'today', 1400.00,
        'APPROVED', 'approved', true, true, 4.80, 78
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-22', 22, '10000000-0000-0000-0000-000000000022', '10000000-0000-0000-0000-000000000022', 'Adv. Ishita Mukherjee', 'Female',
        'taxation', 12, 4.80, 78,
        1400.00, 'Park Street', 'Kolkata', 'West Bengal', ARRAY['Bengali', 'English', 'Hindi'], 'today',
        'Ishita Mukherjee.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 23: Adv. Jayesh Patel (jayesh.patel@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'jayesh.patel@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Jayesh Patel","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000023', '10000000-0000-0000-0000-000000000023', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000023', 'email', 'jayesh.patel@gmail.com'), 'email', '10000000-0000-0000-0000-000000000023', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000023', 'lawyer', 'Adv. Jayesh Patel', 'jayesh.patel@gmail.com', '+91 98200 11023', 'Mumbai', 'Maharashtra', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000023', 'lawyer-23', 'Adv. Jayesh Patel', 'Adv. Jayesh Patel', 'jayesh.patel@gmail.com', '+91 98200 11023',
        'Jayesh Patel.jpg', 'constitutional', 'Supreme Court & High Court Appellate Practice', 20,
        ARRAY['Gujarati', 'Marathi', 'Hindi', 'English'], 'Fort', 'Mumbai', 'Maharashtra', 'today', 3000.00,
        'APPROVED', 'approved', true, true, 5.00, 142
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-23', 23, '10000000-0000-0000-0000-000000000023', '10000000-0000-0000-0000-000000000023', 'Adv. Jayesh Patel', 'Male',
        'constitutional', 20, 5.00, 142,
        3000.00, 'Fort', 'Mumbai', 'Maharashtra', ARRAY['Gujarati', 'Marathi', 'Hindi', 'English'], 'today',
        'Jayesh Patel.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 24: Adv. Kavita Deshmukh (kavita.deshmukh@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000024', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'kavita.deshmukh@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Kavita Deshmukh","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000024', '10000000-0000-0000-0000-000000000024', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000024', 'email', 'kavita.deshmukh@gmail.com'), 'email', '10000000-0000-0000-0000-000000000024', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000024', 'lawyer', 'Adv. Kavita Deshmukh', 'kavita.deshmukh@gmail.com', '+91 98200 11024', 'Nagpur', 'Maharashtra', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000024', 'lawyer-24', 'Adv. Kavita Deshmukh', 'Adv. Kavita Deshmukh', 'kavita.deshmukh@gmail.com', '+91 98200 11024',
        'Kavita Deshmukh.jpg', 'consumer', 'Insurance Claim Rejection & Product Liability', 8,
        ARRAY['Marathi', 'Hindi', 'English'], 'Dharampeth', 'Nagpur', 'Maharashtra', 'tomorrow', 650.00,
        'APPROVED', 'approved', true, true, 4.60, 36
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-24', 24, '10000000-0000-0000-0000-000000000024', '10000000-0000-0000-0000-000000000024', 'Adv. Kavita Deshmukh', 'Female',
        'consumer', 8, 4.60, 36,
        650.00, 'Dharampeth', 'Nagpur', 'Maharashtra', ARRAY['Marathi', 'Hindi', 'English'], 'tomorrow',
        'Kavita Deshmukh.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 25: Adv. Kunal Singhania (kunal.singhania@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000025', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'kunal.singhania@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Kunal Singhania","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000025', '10000000-0000-0000-0000-000000000025', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000025', 'email', 'kunal.singhania@gmail.com'), 'email', '10000000-0000-0000-0000-000000000025', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000025', 'lawyer', 'Adv. Kunal Singhania', 'kunal.singhania@gmail.com', '+91 98200 11025', 'Delhi', 'NCR', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000025', 'lawyer-25', 'Adv. Kunal Singhania', 'Adv. Kunal Singhania', 'kunal.singhania@gmail.com', '+91 98200 11025',
        'Kunal Singhania.jpg', 'intellectual_property', 'Patent Drafting & Trademark Counterfeit Suits', 11,
        ARRAY['Hindi', 'English'], 'Saket', 'Delhi', 'NCR', 'today', 1800.00,
        'APPROVED', 'approved', true, true, 4.90, 91
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-25', 25, '10000000-0000-0000-0000-000000000025', '10000000-0000-0000-0000-000000000025', 'Adv. Kunal Singhania', 'Male',
        'intellectual_property', 11, 4.90, 91,
        1800.00, 'Saket', 'Delhi', 'NCR', ARRAY['Hindi', 'English'], 'today',
        'Kunal Singhania.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 26: Adv. Madhavan Kutty (madhavan.kutty@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'madhavan.kutty@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Madhavan Kutty","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000026', '10000000-0000-0000-0000-000000000026', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000026', 'email', 'madhavan.kutty@gmail.com'), 'email', '10000000-0000-0000-0000-000000000026', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000026', 'lawyer', 'Adv. Madhavan Kutty', 'madhavan.kutty@gmail.com', '+91 98200 11026', 'Kochi', 'Kerala', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000026', 'lawyer-26', 'Adv. Madhavan Kutty', 'Adv. Madhavan Kutty', 'madhavan.kutty@gmail.com', '+91 98200 11026',
        'Madhavan Kutty.jpg', 'environmental', 'Coastal Zone Management & Forest Rights Act', 16,
        ARRAY['Malayalam', 'English'], 'Panampilly Nagar', 'Kochi', 'Kerala', 'today', 1600.00,
        'APPROVED', 'approved', true, true, 4.80, 83
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-26', 26, '10000000-0000-0000-0000-000000000026', '10000000-0000-0000-0000-000000000026', 'Adv. Madhavan Kutty', 'Male',
        'environmental', 16, 4.80, 83,
        1600.00, 'Panampilly Nagar', 'Kochi', 'Kerala', ARRAY['Malayalam', 'English'], 'today',
        'Madhavan Kutty.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 27: Adv. Meenakshi Sundaram (meenakshi.sundaram@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'meenakshi.sundaram@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Meenakshi Sundaram","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000027', '10000000-0000-0000-0000-000000000027', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000027', 'email', 'meenakshi.sundaram@gmail.com'), 'email', '10000000-0000-0000-0000-000000000027', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000027', 'lawyer', 'Adv. Meenakshi Sundaram', 'meenakshi.sundaram@gmail.com', '+91 98200 11027', 'Chennai', 'Tamil Nadu', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000027', 'lawyer-27', 'Adv. Meenakshi Sundaram', 'Adv. Meenakshi Sundaram', 'meenakshi.sundaram@gmail.com', '+91 98200 11027',
        'Meenakshi Sundaram.jpg', 'criminal', 'CBI / ED Investigations & Economic Offences', 15,
        ARRAY['Tamil', 'English', 'Hindi'], 'Mylapore', 'Chennai', 'Tamil Nadu', 'today', 1750.00,
        'APPROVED', 'approved', true, true, 4.90, 104
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-27', 27, '10000000-0000-0000-0000-000000000027', '10000000-0000-0000-0000-000000000027', 'Adv. Meenakshi Sundaram', 'Female',
        'criminal', 15, 4.90, 104,
        1750.00, 'Mylapore', 'Chennai', 'Tamil Nadu', ARRAY['Tamil', 'English', 'Hindi'], 'today',
        'Meenakshi Sundaram.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 28: Adv. Mohit Agarwal (mohit.agarwal@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000028', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'mohit.agarwal@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Mohit Agarwal","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000028', '10000000-0000-0000-0000-000000000028', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000028', 'email', 'mohit.agarwal@gmail.com'), 'email', '10000000-0000-0000-0000-000000000028', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000028', 'lawyer', 'Adv. Mohit Agarwal', 'mohit.agarwal@gmail.com', '+91 98200 11028', 'Lucknow', 'Uttar Pradesh', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000028', 'lawyer-28', 'Adv. Mohit Agarwal', 'Adv. Mohit Agarwal', 'mohit.agarwal@gmail.com', '+91 98200 11028',
        'Mohit Agarwal.jpg', 'family', 'Alimony Claims & Domestic Violence Defense', 9,
        ARRAY['Hindi', 'English'], 'Gomti Nagar', 'Lucknow', 'Uttar Pradesh', 'today', 850.00,
        'APPROVED', 'approved', true, true, 4.60, 43
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-28', 28, '10000000-0000-0000-0000-000000000028', '10000000-0000-0000-0000-000000000028', 'Adv. Mohit Agarwal', 'Male',
        'family', 9, 4.60, 43,
        850.00, 'Gomti Nagar', 'Lucknow', 'Uttar Pradesh', ARRAY['Hindi', 'English'], 'today',
        'Mohit Agarwal.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 29: Adv. Nandini Rao (nandini.rao@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000029', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'nandini.rao@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Nandini Rao","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000029', '10000000-0000-0000-0000-000000000029', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000029', 'email', 'nandini.rao@gmail.com'), 'email', '10000000-0000-0000-0000-000000000029', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000029', 'lawyer', 'Adv. Nandini Rao', 'nandini.rao@gmail.com', '+91 98200 11029', 'Hyderabad', 'Telangana', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000029', 'lawyer-29', 'Adv. Nandini Rao', 'Adv. Nandini Rao', 'nandini.rao@gmail.com', '+91 98200 11029',
        'Nandini Rao.jpg', 'property', 'Land Title Due Diligence & Commercial Leases', 17,
        ARRAY['Telugu', 'English', 'Hindi'], 'Jubilee Hills', 'Hyderabad', 'Telangana', 'today', 2200.00,
        'APPROVED', 'approved', true, true, 4.90, 118
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-29', 29, '10000000-0000-0000-0000-000000000029', '10000000-0000-0000-0000-000000000029', 'Adv. Nandini Rao', 'Female',
        'property', 17, 4.90, 118,
        2200.00, 'Jubilee Hills', 'Hyderabad', 'Telangana', ARRAY['Telugu', 'English', 'Hindi'], 'today',
        'Nandini Rao.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 30: Adv. Nikhil Choudhary (nikhil.choudhary@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'nikhil.choudhary@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Nikhil Choudhary","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000030', '10000000-0000-0000-0000-000000000030', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000030', 'email', 'nikhil.choudhary@gmail.com'), 'email', '10000000-0000-0000-0000-000000000030', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000030', 'lawyer', 'Adv. Nikhil Choudhary', 'nikhil.choudhary@gmail.com', '+91 98200 11030', 'Bengaluru', 'Karnataka', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000030', 'lawyer-30', 'Adv. Nikhil Choudhary', 'Adv. Nikhil Choudhary', 'nikhil.choudhary@gmail.com', '+91 98200 11030',
        'Nikhil Choudhary.jpg', 'corporate', 'Cross-Border Contracts & SaaS Agreement Drafting', 12,
        ARRAY['Hindi', 'English'], 'Whitefield', 'Bengaluru', 'Karnataka', 'today', 1600.00,
        'APPROVED', 'approved', true, true, 4.80, 69
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-30', 30, '10000000-0000-0000-0000-000000000030', '10000000-0000-0000-0000-000000000030', 'Adv. Nikhil Choudhary', 'Male',
        'corporate', 12, 4.80, 69,
        1600.00, 'Whitefield', 'Bengaluru', 'Karnataka', ARRAY['Hindi', 'English'], 'today',
        'Nikhil Choudhary.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 31: Adv. Pallavi Goswami (pallavi.goswami@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'pallavi.goswami@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Pallavi Goswami","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000031', '10000000-0000-0000-0000-000000000031', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000031', 'email', 'pallavi.goswami@gmail.com'), 'email', '10000000-0000-0000-0000-000000000031', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000031', 'lawyer', 'Adv. Pallavi Goswami', 'pallavi.goswami@gmail.com', '+91 98200 11031', 'Guwahati', 'Assam', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000031', 'lawyer-31', 'Adv. Pallavi Goswami', 'Adv. Pallavi Goswami', 'pallavi.goswami@gmail.com', '+91 98200 11031',
        'Pallavi Goswami.jpg', 'civil', 'Declaration Suits & Property Mutation Injunctions', 10,
        ARRAY['Assamese', 'Bengali', 'Hindi', 'English'], 'Beltola', 'Guwahati', 'Assam', 'tomorrow', 900.00,
        'APPROVED', 'approved', true, true, 4.70, 51
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-31', 31, '10000000-0000-0000-0000-000000000031', '10000000-0000-0000-0000-000000000031', 'Adv. Pallavi Goswami', 'Female',
        'civil', 10, 4.70, 51,
        900.00, 'Beltola', 'Guwahati', 'Assam', ARRAY['Assamese', 'Bengali', 'Hindi', 'English'], 'tomorrow',
        'Pallavi Goswami.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 32: Adv. Pradeep Rawat (pradeep.rawat@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'pradeep.rawat@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Pradeep Rawat","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000032', '10000000-0000-0000-0000-000000000032', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000032', 'email', 'pradeep.rawat@gmail.com'), 'email', '10000000-0000-0000-0000-000000000032', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000032', 'lawyer', 'Adv. Pradeep Rawat', 'pradeep.rawat@gmail.com', '+91 98200 11032', 'Dehradun', 'Uttarakhand', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000032', 'lawyer-32', 'Adv. Pradeep Rawat', 'Adv. Pradeep Rawat', 'pradeep.rawat@gmail.com', '+91 98200 11032',
        'Pradeep Rawat.jpg', 'financial', 'SARFAESI Appeals & Insolvency Proceedings (IBC)', 14,
        ARRAY['Hindi', 'English'], 'Rajpur Road', 'Dehradun', 'Uttarakhand', 'today', 1300.00,
        'APPROVED', 'approved', true, true, 4.70, 62
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-32', 32, '10000000-0000-0000-0000-000000000032', '10000000-0000-0000-0000-000000000032', 'Adv. Pradeep Rawat', 'Male',
        'financial', 14, 4.70, 62,
        1300.00, 'Rajpur Road', 'Dehradun', 'Uttarakhand', ARRAY['Hindi', 'English'], 'today',
        'Pradeep Rawat.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 33: Adv. Priyanka Sen (priyanka.sen@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'priyanka.sen@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Priyanka Sen","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000033', '10000000-0000-0000-0000-000000000033', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000033', 'email', 'priyanka.sen@gmail.com'), 'email', '10000000-0000-0000-0000-000000000033', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000033', 'lawyer', 'Adv. Priyanka Sen', 'priyanka.sen@gmail.com', '+91 98200 11033', 'Kolkata', 'West Bengal', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000033', 'lawyer-33', 'Adv. Priyanka Sen', 'Adv. Priyanka Sen', 'priyanka.sen@gmail.com', '+91 98200 11033',
        'Priyanka Sen.jpg', 'cyber', 'Cyber Defamation, Crypto Disputes & Identity Theft', 8,
        ARRAY['Bengali', 'English', 'Hindi'], 'Bidhannagar', 'Kolkata', 'West Bengal', 'today', 1100.00,
        'APPROVED', 'approved', true, true, 4.80, 47
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-33', 33, '10000000-0000-0000-0000-000000000033', '10000000-0000-0000-0000-000000000033', 'Adv. Priyanka Sen', 'Female',
        'cyber', 8, 4.80, 47,
        1100.00, 'Bidhannagar', 'Kolkata', 'West Bengal', ARRAY['Bengali', 'English', 'Hindi'], 'today',
        'Priyanka Sen.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 34: Adv. Rahul Bhatnagar (rahul.bhatnagar@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000034', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'rahul.bhatnagar@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Rahul Bhatnagar","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000034', '10000000-0000-0000-0000-000000000034', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000034', 'email', 'rahul.bhatnagar@gmail.com'), 'email', '10000000-0000-0000-0000-000000000034', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000034', 'lawyer', 'Adv. Rahul Bhatnagar', 'rahul.bhatnagar@gmail.com', '+91 98200 11034', 'Noida', 'Uttar Pradesh', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000034', 'lawyer-34', 'Adv. Rahul Bhatnagar', 'Adv. Rahul Bhatnagar', 'rahul.bhatnagar@gmail.com', '+91 98200 11034',
        'Rahul Bhatnagar.jpg', 'labour', 'Employment Agreements & Trade Union Negotiations', 13,
        ARRAY['Hindi', 'English'], 'Sector 62', 'Noida', 'Uttar Pradesh', 'today', 1200.00,
        'APPROVED', 'approved', true, true, 4.80, 74
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-34', 34, '10000000-0000-0000-0000-000000000034', '10000000-0000-0000-0000-000000000034', 'Adv. Rahul Bhatnagar', 'Male',
        'labour', 13, 4.80, 74,
        1200.00, 'Sector 62', 'Noida', 'Uttar Pradesh', ARRAY['Hindi', 'English'], 'today',
        'Rahul Bhatnagar.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 35: Adv. Rajeshwari Iyer (rajeshwari.iyer@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000035', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'rajeshwari.iyer@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Rajeshwari Iyer","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000035', '10000000-0000-0000-0000-000000000035', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000035', 'email', 'rajeshwari.iyer@gmail.com'), 'email', '10000000-0000-0000-0000-000000000035', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000035', 'lawyer', 'Adv. Rajeshwari Iyer', 'rajeshwari.iyer@gmail.com', '+91 98200 11035', 'Chennai', 'Tamil Nadu', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000035', 'lawyer-35', 'Adv. Rajeshwari Iyer', 'Adv. Rajeshwari Iyer', 'rajeshwari.iyer@gmail.com', '+91 98200 11035',
        'Rajeshwari Iyer.jpg', 'taxation', 'International Taxation & Transfer Pricing', 19,
        ARRAY['Tamil', 'English', 'Hindi'], 'Adyar', 'Chennai', 'Tamil Nadu', 'today', 2400.00,
        'APPROVED', 'approved', true, true, 4.90, 135
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-35', 35, '10000000-0000-0000-0000-000000000035', '10000000-0000-0000-0000-000000000035', 'Adv. Rajeshwari Iyer', 'Female',
        'taxation', 19, 4.90, 135,
        2400.00, 'Adyar', 'Chennai', 'Tamil Nadu', ARRAY['Tamil', 'English', 'Hindi'], 'today',
        'Rajeshwari Iyer.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 36: Adv. Rakesh Srivastava (rakesh.srivastava@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000036', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'rakesh.srivastava@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Rakesh Srivastava","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000036', '10000000-0000-0000-0000-000000000036', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000036', 'email', 'rakesh.srivastava@gmail.com'), 'email', '10000000-0000-0000-0000-000000000036', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000036', 'lawyer', 'Adv. Rakesh Srivastava', 'rakesh.srivastava@gmail.com', '+91 98200 11036', 'Prayagraj', 'Uttar Pradesh', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000036', 'lawyer-36', 'Adv. Rakesh Srivastava', 'Adv. Rakesh Srivastava', 'rakesh.srivastava@gmail.com', '+91 98200 11036',
        'Rakesh Srivastava.jpg', 'constitutional', 'Constitutional Bench Litigation & Administrative Law', 22,
        ARRAY['Hindi', 'English'], 'Civil Lines', 'Prayagraj', 'Uttar Pradesh', 'today', 3500.00,
        'APPROVED', 'approved', true, true, 5.00, 160
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-36', 36, '10000000-0000-0000-0000-000000000036', '10000000-0000-0000-0000-000000000036', 'Adv. Rakesh Srivastava', 'Male',
        'constitutional', 22, 5.00, 160,
        3500.00, 'Civil Lines', 'Prayagraj', 'Uttar Pradesh', ARRAY['Hindi', 'English'], 'today',
        'Rakesh Srivastava.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 37: Adv. Ritu Saxena (ritu.saxena@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000037', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'ritu.saxena@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Ritu Saxena","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000037', '10000000-0000-0000-0000-000000000037', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000037', 'email', 'ritu.saxena@gmail.com'), 'email', '10000000-0000-0000-0000-000000000037', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000037', 'lawyer', 'Adv. Ritu Saxena', 'ritu.saxena@gmail.com', '+91 98200 11037', 'Bhopal', 'Madhya Pradesh', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000037', 'lawyer-37', 'Adv. Ritu Saxena', 'Adv. Ritu Saxena', 'ritu.saxena@gmail.com', '+91 98200 11037',
        'Ritu Saxena.jpg', 'consumer', 'Deficiency of Banking Services & Builder Delay Claims', 11,
        ARRAY['Hindi', 'English'], 'Arera Colony', 'Bhopal', 'Madhya Pradesh', 'today', 850.00,
        'APPROVED', 'approved', true, true, 4.70, 58
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-37', 37, '10000000-0000-0000-0000-000000000037', '10000000-0000-0000-0000-000000000037', 'Adv. Ritu Saxena', 'Female',
        'consumer', 11, 4.70, 58,
        850.00, 'Arera Colony', 'Bhopal', 'Madhya Pradesh', ARRAY['Hindi', 'English'], 'today',
        'Ritu Saxena.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 38: Adv. Rohan Malhotra (rohan.malhotra@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000038', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'rohan.malhotra@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Rohan Malhotra","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000038', '10000000-0000-0000-0000-000000000038', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000038', 'email', 'rohan.malhotra@gmail.com'), 'email', '10000000-0000-0000-0000-000000000038', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000038', 'lawyer', 'Adv. Rohan Malhotra', 'rohan.malhotra@gmail.com', '+91 98200 11038', 'Delhi', 'NCR', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000038', 'lawyer-38', 'Adv. Rohan Malhotra', 'Adv. Rohan Malhotra', 'rohan.malhotra@gmail.com', '+91 98200 11038',
        'Rohan Malhotra.jpg', 'intellectual_property', 'Brand Protection, Domain Disputes & Design Rights', 9,
        ARRAY['Hindi', 'Punjabi', 'English'], 'Vasant Kunj', 'Delhi', 'NCR', 'today', 1400.00,
        'APPROVED', 'approved', true, true, 4.80, 63
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-38', 38, '10000000-0000-0000-0000-000000000038', '10000000-0000-0000-0000-000000000038', 'Adv. Rohan Malhotra', 'Male',
        'intellectual_property', 9, 4.80, 63,
        1400.00, 'Vasant Kunj', 'Delhi', 'NCR', ARRAY['Hindi', 'Punjabi', 'English'], 'today',
        'Rohan Malhotra.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 39: Adv. Sameer Kulkarni (sameer.kulkarni@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000039', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'sameer.kulkarni@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Sameer Kulkarni","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000039', '10000000-0000-0000-0000-000000000039', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000039', 'email', 'sameer.kulkarni@gmail.com'), 'email', '10000000-0000-0000-0000-000000000039', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000039', 'lawyer', 'Adv. Sameer Kulkarni', 'sameer.kulkarni@gmail.com', '+91 98200 11039', 'Pune', 'Maharashtra', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000039', 'lawyer-39', 'Adv. Sameer Kulkarni', 'Adv. Sameer Kulkarni', 'sameer.kulkarni@gmail.com', '+91 98200 11039',
        'Sameer Kulkarni.jpg', 'environmental', 'EIA Compliance & Industrial Waste Adjudication', 14,
        ARRAY['Marathi', 'Hindi', 'English'], 'Kothrud', 'Pune', 'Maharashtra', 'today', 1500.00,
        'APPROVED', 'approved', true, true, 4.80, 79
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-39', 39, '10000000-0000-0000-0000-000000000039', '10000000-0000-0000-0000-000000000039', 'Adv. Sameer Kulkarni', 'Male',
        'environmental', 14, 4.80, 79,
        1500.00, 'Kothrud', 'Pune', 'Maharashtra', ARRAY['Marathi', 'Hindi', 'English'], 'today',
        'Sameer Kulkarni.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 40: Adv. Sangeeta Reddy (sangeeta.reddy@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000040', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'sangeeta.reddy@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Sangeeta Reddy","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000040', '10000000-0000-0000-0000-000000000040', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000040', 'email', 'sangeeta.reddy@gmail.com'), 'email', '10000000-0000-0000-0000-000000000040', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000040', 'lawyer', 'Adv. Sangeeta Reddy', 'sangeeta.reddy@gmail.com', '+91 98200 11040', 'Hyderabad', 'Telangana', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000040', 'lawyer-40', 'Adv. Sangeeta Reddy', 'Adv. Sangeeta Reddy', 'sangeeta.reddy@gmail.com', '+91 98200 11040',
        'Sangeeta Reddy.jpg', 'criminal', 'White Collar Defense, PMLA & Trial Advocacy', 16,
        ARRAY['Telugu', 'English', 'Hindi'], 'Banjara Hills', 'Hyderabad', 'Telangana', 'today', 1900.00,
        'APPROVED', 'approved', true, true, 4.90, 112
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-40', 40, '10000000-0000-0000-0000-000000000040', '10000000-0000-0000-0000-000000000040', 'Adv. Sangeeta Reddy', 'Female',
        'criminal', 16, 4.90, 112,
        1900.00, 'Banjara Hills', 'Hyderabad', 'Telangana', ARRAY['Telugu', 'English', 'Hindi'], 'today',
        'Sangeeta Reddy.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 41: Adv. Sanjeev Nair (sanjeev.nair@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000041', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'sanjeev.nair@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Sanjeev Nair","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000041', '10000000-0000-0000-0000-000000000041', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000041', 'email', 'sanjeev.nair@gmail.com'), 'email', '10000000-0000-0000-0000-000000000041', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000041', 'lawyer', 'Adv. Sanjeev Nair', 'sanjeev.nair@gmail.com', '+91 98200 11041', 'Kochi', 'Kerala', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000041', 'lawyer-41', 'Adv. Sanjeev Nair', 'Adv. Sanjeev Nair', 'sanjeev.nair@gmail.com', '+91 98200 11041',
        'Sanjeev Nair.jpg', 'family', 'Family Mediation, Guardian & Wards Act Petitions', 12,
        ARRAY['Malayalam', 'English'], 'Edappally', 'Kochi', 'Kerala', 'today', 1100.00,
        'APPROVED', 'approved', true, true, 4.70, 67
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-41', 41, '10000000-0000-0000-0000-000000000041', '10000000-0000-0000-0000-000000000041', 'Adv. Sanjeev Nair', 'Male',
        'family', 12, 4.70, 67,
        1100.00, 'Edappally', 'Kochi', 'Kerala', ARRAY['Malayalam', 'English'], 'today',
        'Sanjeev Nair.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 42: Adv. Shalini Tripathi (shalini.tripathi@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000042', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'shalini.tripathi@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Shalini Tripathi","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000042', '10000000-0000-0000-0000-000000000042', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000042', 'email', 'shalini.tripathi@gmail.com'), 'email', '10000000-0000-0000-0000-000000000042', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000042', 'lawyer', 'Adv. Shalini Tripathi', 'shalini.tripathi@gmail.com', '+91 98200 11042', 'Lucknow', 'Uttar Pradesh', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000042', 'lawyer-42', 'Adv. Shalini Tripathi', 'Adv. Shalini Tripathi', 'shalini.tripathi@gmail.com', '+91 98200 11042',
        'Shalini Tripathi.jpg', 'property', 'Tenant Eviction, Rent Control & Succession Certificates', 10,
        ARRAY['Hindi', 'English'], 'Aliganj', 'Lucknow', 'Uttar Pradesh', 'tomorrow', 1000.00,
        'APPROVED', 'approved', true, true, 4.80, 54
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-42', 42, '10000000-0000-0000-0000-000000000042', '10000000-0000-0000-0000-000000000042', 'Adv. Shalini Tripathi', 'Female',
        'property', 10, 4.80, 54,
        1000.00, 'Aliganj', 'Lucknow', 'Uttar Pradesh', ARRAY['Hindi', 'English'], 'tomorrow',
        'Shalini Tripathi.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 43: Adv. Siddharth Bose (siddharth.bose@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000043', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'siddharth.bose@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Siddharth Bose","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000043', '10000000-0000-0000-0000-000000000043', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000043', 'email', 'siddharth.bose@gmail.com'), 'email', '10000000-0000-0000-0000-000000000043', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000043', 'lawyer', 'Adv. Siddharth Bose', 'siddharth.bose@gmail.com', '+91 98200 11043', 'Kolkata', 'West Bengal', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000043', 'lawyer-43', 'Adv. Siddharth Bose', 'Adv. Siddharth Bose', 'siddharth.bose@gmail.com', '+91 98200 11043',
        'Siddharth Bose.jpg', 'corporate', 'Shareholder Disputes & Joint Venture Agreements', 15,
        ARRAY['Bengali', 'English', 'Hindi'], 'Ballygunge', 'Kolkata', 'West Bengal', 'today', 2100.00,
        'APPROVED', 'approved', true, true, 4.90, 98
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-43', 43, '10000000-0000-0000-0000-000000000043', '10000000-0000-0000-0000-000000000043', 'Adv. Siddharth Bose', 'Male',
        'corporate', 15, 4.90, 98,
        2100.00, 'Ballygunge', 'Kolkata', 'West Bengal', ARRAY['Bengali', 'English', 'Hindi'], 'today',
        'Siddharth Bose.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 44: Adv. Sneha Nambiar (sneha.nambiar@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000044', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'sneha.nambiar@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Sneha Nambiar","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000044', '10000000-0000-0000-0000-000000000044', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000044', 'email', 'sneha.nambiar@gmail.com'), 'email', '10000000-0000-0000-0000-000000000044', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000044', 'lawyer', 'Adv. Sneha Nambiar', 'sneha.nambiar@gmail.com', '+91 98200 11044', 'Kozhikode', 'Kerala', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000044', 'lawyer-44', 'Adv. Sneha Nambiar', 'Adv. Sneha Nambiar', 'sneha.nambiar@gmail.com', '+91 98200 11044',
        'Sneha Nambiar.jpg', 'civil', 'Money Suits, Summary Suits & Arbitration', 8,
        ARRAY['Malayalam', 'English'], 'Calicut Beach', 'Kozhikode', 'Kerala', 'today', 750.00,
        'APPROVED', 'approved', true, true, 4.60, 40
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-44', 44, '10000000-0000-0000-0000-000000000044', '10000000-0000-0000-0000-000000000044', 'Adv. Sneha Nambiar', 'Female',
        'civil', 8, 4.60, 40,
        750.00, 'Calicut Beach', 'Kozhikode', 'Kerala', ARRAY['Malayalam', 'English'], 'today',
        'Sneha Nambiar.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 45: Adv. Sudhir Chavan (sudhir.chavan@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000045', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'sudhir.chavan@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Sudhir Chavan","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000045', '10000000-0000-0000-0000-000000000045', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000045', 'email', 'sudhir.chavan@gmail.com'), 'email', '10000000-0000-0000-0000-000000000045', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000045', 'lawyer', 'Adv. Sudhir Chavan', 'sudhir.chavan@gmail.com', '+91 98200 11045', 'Mumbai', 'Maharashtra', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000045', 'lawyer-45', 'Adv. Sudhir Chavan', 'Adv. Sudhir Chavan', 'sudhir.chavan@gmail.com', '+91 98200 11045',
        'Sudhir Chavan.jpg', 'financial', 'NCLT Corporate Insolvency & Banking Ombudsman', 17,
        ARRAY['Marathi', 'Hindi', 'English'], 'Dadar West', 'Mumbai', 'Maharashtra', 'today', 1700.00,
        'APPROVED', 'approved', true, true, 4.80, 88
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-45', 45, '10000000-0000-0000-0000-000000000045', '10000000-0000-0000-0000-000000000045', 'Adv. Sudhir Chavan', 'Male',
        'financial', 17, 4.80, 88,
        1700.00, 'Dadar West', 'Mumbai', 'Maharashtra', ARRAY['Marathi', 'Hindi', 'English'], 'today',
        'Sudhir Chavan.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 46: Adv. Swati Mathur (swati.mathur@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000046', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'swati.mathur@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Swati Mathur","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000046', '10000000-0000-0000-0000-000000000046', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000046', 'email', 'swati.mathur@gmail.com'), 'email', '10000000-0000-0000-0000-000000000046', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000046', 'lawyer', 'Adv. Swati Mathur', 'swati.mathur@gmail.com', '+91 98200 11046', 'Jaipur', 'Rajasthan', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000046', 'lawyer-46', 'Adv. Swati Mathur', 'Adv. Swati Mathur', 'swati.mathur@gmail.com', '+91 98200 11046',
        'Swati Mathur.jpg', 'cyber', 'Cyber Stalking, Social Media Impersonation & Evidence', 11,
        ARRAY['Hindi', 'English'], 'C-Scheme', 'Jaipur', 'Rajasthan', 'today', 1450.00,
        'APPROVED', 'approved', true, true, 4.90, 82
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-46', 46, '10000000-0000-0000-0000-000000000046', '10000000-0000-0000-0000-000000000046', 'Adv. Swati Mathur', 'Female',
        'cyber', 11, 4.90, 82,
        1450.00, 'C-Scheme', 'Jaipur', 'Rajasthan', ARRAY['Hindi', 'English'], 'today',
        'Swati Mathur.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 47: Adv. Tarun Bansal (tarun.bansal@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000047', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'tarun.bansal@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Tarun Bansal","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000047', '10000000-0000-0000-0000-000000000047', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000047', 'email', 'tarun.bansal@gmail.com'), 'email', '10000000-0000-0000-0000-000000000047', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000047', 'lawyer', 'Adv. Tarun Bansal', 'tarun.bansal@gmail.com', '+91 98200 11047', 'Ludhiana', 'Punjab', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000047', 'lawyer-47', 'Adv. Tarun Bansal', 'Adv. Tarun Bansal', 'tarun.bansal@gmail.com', '+91 98200 11047',
        'Tarun Bansal.jpg', 'labour', 'Factory Act Violations, Gratuity Disputes & Wage Recovery', 9,
        ARRAY['Punjabi', 'Hindi', 'English'], 'Model Town', 'Ludhiana', 'Punjab', 'today', 800.00,
        'APPROVED', 'approved', true, true, 4.60, 44
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-47', 47, '10000000-0000-0000-0000-000000000047', '10000000-0000-0000-0000-000000000047', 'Adv. Tarun Bansal', 'Male',
        'labour', 9, 4.60, 44,
        800.00, 'Model Town', 'Ludhiana', 'Punjab', ARRAY['Punjabi', 'Hindi', 'English'], 'today',
        'Tarun Bansal.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 48: Adv. Urvashi Mehra (urvashi.mehra@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000048', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'urvashi.mehra@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Urvashi Mehra","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000048', '10000000-0000-0000-0000-000000000048', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000048', 'email', 'urvashi.mehra@gmail.com'), 'email', '10000000-0000-0000-0000-000000000048', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000048', 'lawyer', 'Adv. Urvashi Mehra', 'urvashi.mehra@gmail.com', '+91 98200 11048', 'Delhi', 'NCR', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000048', 'lawyer-48', 'Adv. Urvashi Mehra', 'Adv. Urvashi Mehra', 'urvashi.mehra@gmail.com', '+91 98200 11048',
        'Urvashi Mehra.jpg', 'taxation', 'Search & Seizure Assessment, Income Tax Settlement', 14,
        ARRAY['Hindi', 'English'], 'Greater Kailash', 'Delhi', 'NCR', 'today', 1600.00,
        'APPROVED', 'approved', true, true, 4.80, 90
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-48', 48, '10000000-0000-0000-0000-000000000048', '10000000-0000-0000-0000-000000000048', 'Adv. Urvashi Mehra', 'Female',
        'taxation', 14, 4.80, 90,
        1600.00, 'Greater Kailash', 'Delhi', 'NCR', ARRAY['Hindi', 'English'], 'today',
        'Urvashi Mehra.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

    -- Lawyer 49: Adv. Varun Pillai (varun.pillai@gmail.com)
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at
    ) VALUES (
        '10000000-0000-0000-0000-000000000049', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'varun.pillai@gmail.com', v_pw, NOW(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        '{"full_name":"Adv. Varun Pillai","role":"lawyer"}'::jsonb,
        NOW(), NOW()
    ) ON CONFLICT (id) DO UPDATE
    SET email = EXCLUDED.email, encrypted_password = EXCLUDED.encrypted_password, email_confirmed_at = NOW();

    INSERT INTO auth.identities (id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at)
    VALUES ('10000000-0000-0000-0000-000000000049', '10000000-0000-0000-0000-000000000049', jsonb_build_object('sub', '10000000-0000-0000-0000-000000000049', 'email', 'varun.pillai@gmail.com'), 'email', '10000000-0000-0000-0000-000000000049', NOW(), NOW(), NOW())
    ON CONFLICT (provider, provider_id) DO NOTHING;

    INSERT INTO public.profiles (id, role, full_name, email, phone, city, state, is_active)
    VALUES ('10000000-0000-0000-0000-000000000049', 'lawyer', 'Adv. Varun Pillai', 'varun.pillai@gmail.com', '+91 98200 11049', 'Kochi', 'Kerala', true)
    ON CONFLICT (id) DO UPDATE SET role = 'lawyer', full_name = EXCLUDED.full_name, email = EXCLUDED.email, city = EXCLUDED.city, state = EXCLUDED.state;

    INSERT INTO public.lawyer_profiles (
        user_id, directory_id, full_name, display_name, email, phone,
        profile_photo_path, legal_category, specialization, years_experience,
        languages, locality, city, state, availability, consultation_fee,
        approval_status, verification_status, is_verified, is_active, rating_average, review_count
    ) VALUES (
        '10000000-0000-0000-0000-000000000049', 'lawyer-49', 'Adv. Varun Pillai', 'Adv. Varun Pillai', 'varun.pillai@gmail.com', '+91 98200 11049',
        'Varun Pillai.jpg', 'consumer', 'Real Estate Handover Delays & Travel Compensation Claims', 13,
        ARRAY['Malayalam', 'English', 'Hindi'], 'Vyttila', 'Kochi', 'Kerala', 'today', 1150.00,
        'APPROVED', 'approved', true, true, 4.70, 71
    ) ON CONFLICT (user_id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        display_name = EXCLUDED.display_name,
        email = EXCLUDED.email,
        profile_photo_path = EXCLUDED.profile_photo_path,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        approval_status = 'APPROVED',
        is_verified = true,
        is_active = true;

    INSERT INTO public.lawyer_directory_profiles (
        id, legacy_id, linked_user_id, test_route_user_id, display_name, gender,
        legal_category, years_experience, seed_rating, seed_review_count,
        consultation_fee, locality, city, state, languages, availability,
        profile_photo_path, source, is_active, is_bookable, is_test_bookable
    ) VALUES (
        'lawyer-49', 49, '10000000-0000-0000-0000-000000000049', '10000000-0000-0000-0000-000000000049', 'Adv. Varun Pillai', 'Male',
        'consumer', 13, 4.70, 71,
        1150.00, 'Vyttila', 'Kochi', 'Kerala', ARRAY['Malayalam', 'English', 'Hindi'], 'today',
        'Varun Pillai.jpg', 'directory', true, true, true
    ) ON CONFLICT (id) DO UPDATE SET
        linked_user_id = EXCLUDED.linked_user_id,
        test_route_user_id = EXCLUDED.test_route_user_id,
        display_name = EXCLUDED.display_name,
        legal_category = EXCLUDED.legal_category,
        consultation_fee = EXCLUDED.consultation_fee,
        locality = EXCLUDED.locality,
        city = EXCLUDED.city,
        state = EXCLUDED.state,
        languages = EXCLUDED.languages,
        profile_photo_path = EXCLUDED.profile_photo_path,
        is_bookable = true,
        is_active = true;

END;
$$;

-- ==============================================================================
-- STORED PROCEDURES & BUSINESS LOGIC RPCS
-- ==============================================================================

-- 1. SUBMIT PAYMENT FOR VERIFICATION
CREATE OR REPLACE FUNCTION public.submit_payment_for_verification(
    p_appointment_id UUID,
    p_upi_transaction_id TEXT
)
RETURNS JSONB AS $$
DECLARE
    v_apt RECORD;
    v_payment_id UUID;
    v_platform_fee NUMERIC(10, 2);
    v_lawyer_share NUMERIC(10, 2);
    v_client_name TEXT;
    v_receipt_number TEXT;
    v_res RECORD;
BEGIN
    SELECT * INTO v_apt FROM public.appointments WHERE id = p_appointment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment not found.';
    END IF;

    v_platform_fee := ROUND(v_apt.consultation_fee * 0.10, 2);
    v_lawyer_share := v_apt.consultation_fee - v_platform_fee;

    SELECT full_name INTO v_client_name FROM public.profiles WHERE id = v_apt.client_id;
    IF v_client_name IS NULL THEN
        v_client_name := 'NyayaSetu Client';
    END IF;

    -- Insert Payment
    INSERT INTO public.payments (
        appointment_id, amount, platform_fee,
        lawyer_share, payment_method, upi_transaction_id, transaction_id, status
    ) VALUES (
        p_appointment_id, v_apt.consultation_fee,
        v_platform_fee, v_lawyer_share, 'UPI', p_upi_transaction_id, p_upi_transaction_id, 'COMPLETED'
    )
    RETURNING id INTO v_payment_id;

    -- Update Appointment Status to PENDING_ACCEPTANCE
    UPDATE public.appointments
    SET status = 'PENDING_ACCEPTANCE', updated_at = NOW()
    WHERE id = p_appointment_id;

    -- Generate Receipt Number
    v_receipt_number := 'RCP-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');

    -- Insert Receipt
    INSERT INTO public.receipts (
        receipt_number, payment_id, appointment_id,
        client_name, lawyer_name, legal_category, appointment_date, appointment_time,
        consultation_fee, platform_fee, lawyer_share, total_amount_paid, payment_method, transaction_id, status
    ) VALUES (
        v_receipt_number, v_payment_id, p_appointment_id,
        v_client_name, COALESCE(v_apt.public_lawyer_name, 'Advocate'), v_apt.legal_category,
        v_apt.appointment_date, v_apt.appointment_time, v_apt.consultation_fee,
        v_platform_fee, v_lawyer_share, v_apt.consultation_fee, 'UPI', p_upi_transaction_id, 'ISSUED'
    );

    -- Notify Lawyer
    INSERT INTO public.notifications (
        recipient_user_id, title, message, link_url, type
    ) VALUES (
        v_apt.lawyer_id,
        'New Consultation Request Received',
        'You have a new paid consultation request from ' || v_client_name || ' scheduled for ' || v_apt.appointment_date || ' at ' || v_apt.appointment_time || '.',
        'lawyer-dashboard.html',
        'appointment'
    );

    -- Notify Client
    INSERT INTO public.notifications (
        recipient_user_id, title, message, link_url, type
    ) VALUES (
        v_apt.client_id,
        'Payment Successful — Consultation Requested',
        'Your consultation booking with ' || COALESCE(v_apt.public_lawyer_name, 'your Lawyer') || ' is submitted and awaiting Lawyer acceptance.',
        'client-dashboard.html',
        'payment'
    );

    SELECT * INTO v_res FROM public.payments WHERE id = v_payment_id;
    RETURN to_jsonb(v_res);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. LAWYER ACCEPT APPOINTMENT
CREATE OR REPLACE FUNCTION public.lawyer_accept_paid_appointment(
    p_appointment_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_apt RECORD;
BEGIN
    SELECT * INTO v_apt FROM public.appointments WHERE id = p_appointment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment not found.';
    END IF;

    UPDATE public.appointments
    SET 
        status = 'LAWYER_ACCEPTED',
        accepted_at = NOW(),
        updated_at = NOW()
    WHERE id = p_appointment_id;

    -- Notify Client
    INSERT INTO public.notifications (
        recipient_user_id, title, message, link_url, type
    ) VALUES (
        v_apt.client_id,
        'Appointment Accepted by Lawyer!',
        COALESCE(v_apt.public_lawyer_name, 'Your Lawyer') || ' has accepted your consultation scheduled for ' || v_apt.appointment_date || ' at ' || v_apt.appointment_time || '.',
        'client-dashboard.html',
        'appointment'
    );

    SELECT * INTO v_apt FROM public.appointments WHERE id = p_appointment_id;
    RETURN to_jsonb(v_apt);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. LAWYER REJECT APPOINTMENT
CREATE OR REPLACE FUNCTION public.lawyer_reject_paid_appointment(
    p_appointment_id UUID,
    p_rejection_category TEXT,
    p_rejection_comment TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_apt RECORD;
    v_payment RECORD;
BEGIN
    SELECT * INTO v_apt FROM public.appointments WHERE id = p_appointment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment not found.';
    END IF;

    UPDATE public.appointments
    SET 
        status = 'REJECTED',
        rejection_category = p_rejection_category,
        rejection_comment = p_rejection_comment,
        rejection_reason = p_rejection_category || COALESCE(' - ' || p_rejection_comment, ''),
        rejected_at = NOW(),
        updated_at = NOW()
    WHERE id = p_appointment_id;

    SELECT * INTO v_payment FROM public.payments WHERE appointment_id = p_appointment_id LIMIT 1;
    IF FOUND THEN
        INSERT INTO public.refunds (
            appointment_id, payment_id, client_id, lawyer_id, amount,
            refund_percentage, status, reason
        ) VALUES (
            p_appointment_id, v_payment.id, v_apt.client_id, v_apt.lawyer_id,
            v_payment.amount, 100.00, 'PENDING',
            'Lawyer rejection: ' || p_rejection_category || COALESCE(' - ' || p_rejection_comment, '')
        );
    END IF;

    -- Notify Client
    INSERT INTO public.notifications (
        recipient_user_id, title, message, link_url, type
    ) VALUES (
        v_apt.client_id,
        'Consultation Request Declined - 100% Refund Initiated',
        COALESCE(v_apt.public_lawyer_name, 'The Lawyer') || ' was unable to accept your request (' || p_rejection_category || '). A 100% full refund has been initiated.',
        'client-dashboard.html',
        'refund'
    );

    SELECT * INTO v_apt FROM public.appointments WHERE id = p_appointment_id;
    RETURN to_jsonb(v_apt);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 4. LAWYER COMPLETE CONSULTATION
CREATE OR REPLACE FUNCTION public.lawyer_complete_consultation(
    p_appointment_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_apt RECORD;
BEGIN
    SELECT * INTO v_apt FROM public.appointments WHERE id = p_appointment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment not found.';
    END IF;

    UPDATE public.appointments
    SET 
        status = 'COMPLETED',
        completed_at = NOW(),
        updated_at = NOW()
    WHERE id = p_appointment_id;

    -- Notify Client to leave review
    INSERT INTO public.notifications (
        recipient_user_id, title, message, link_url, type
    ) VALUES (
        v_apt.client_id,
        'Consultation Completed — Please Rate Your Lawyer',
        'Your legal consultation with ' || COALESCE(v_apt.public_lawyer_name, 'your Lawyer') || ' has concluded. Please rate and review your experience.',
        'client-dashboard.html',
        'info'
    );

    SELECT * INTO v_apt FROM public.appointments WHERE id = p_appointment_id;
    RETURN to_jsonb(v_apt);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. CLIENT SUBMIT REVIEW AND QUEUE PAYOUT
CREATE OR REPLACE FUNCTION public.client_submit_review_and_queue_payout(
    p_appointment_id UUID,
    p_rating NUMERIC,
    p_review_text TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_apt RECORD;
    v_payment RECORD;
    v_client_name TEXT;
    v_review RECORD;
    v_lawyer_share NUMERIC(10, 2);
    v_platform_fee NUMERIC(10, 2);
BEGIN
    SELECT * INTO v_apt FROM public.appointments WHERE id = p_appointment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Appointment not found.';
    END IF;

    SELECT full_name INTO v_client_name FROM public.profiles WHERE id = v_apt.client_id;

    -- Insert Review
    INSERT INTO public.reviews (
        appointment_id, client_id, lawyer_id, client_name, rating, review_text
    ) VALUES (
        p_appointment_id, v_apt.client_id, v_apt.lawyer_id, COALESCE(v_client_name, 'Client'), p_rating, p_review_text
    ) RETURNING * INTO v_review;

    -- Queue Lawyer Payout
    SELECT * INTO v_payment FROM public.payments WHERE appointment_id = p_appointment_id LIMIT 1;
    IF FOUND THEN
        v_lawyer_share := v_payment.lawyer_share;
        v_platform_fee := v_payment.platform_fee;
    ELSE
        v_platform_fee := ROUND(v_apt.consultation_fee * 0.10, 2);
        v_lawyer_share := v_apt.consultation_fee - v_platform_fee;
    END IF;

    INSERT INTO public.payouts (
        lawyer_id, appointment_id, amount, platform_fee, status
    ) VALUES (
        v_apt.lawyer_id, p_appointment_id, v_lawyer_share, v_platform_fee, 'QUEUED'
    ) ON CONFLICT (appointment_id) DO NOTHING;

    -- Notify Lawyer
    INSERT INTO public.notifications (
        recipient_user_id, title, message, link_url, type
    ) VALUES (
        v_apt.lawyer_id,
        'New Client Rating Received & Payout Queued',
        'Client gave you a ' || p_rating || ' star rating. Your payout of ₹' || v_lawyer_share || ' has been queued for release.',
        'lawyer-dashboard.html',
        'payout'
    );

    RETURN to_jsonb(v_review);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 6. ADMIN VERIFY PAYMENT
CREATE OR REPLACE FUNCTION public.admin_verify_payment(
    p_payment_id UUID,
    p_verification_note TEXT DEFAULT 'Verified by NyayaSetu Admin.'
)
RETURNS JSONB AS $$
DECLARE
    v_payment RECORD;
BEGIN
    SELECT * INTO v_payment FROM public.payments WHERE id = p_payment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment not found.';
    END IF;

    UPDATE public.payments
    SET 
        status = 'VERIFIED',
        verified_at = NOW(),
        verification_note = p_verification_note,
        updated_at = NOW()
    WHERE id = p_payment_id;

    UPDATE public.appointments
    SET status = 'PENDING_ACCEPTANCE', updated_at = NOW()
    WHERE id = v_payment.appointment_id;

    SELECT * INTO v_payment FROM public.payments WHERE id = p_payment_id;
    RETURN to_jsonb(v_payment);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 7. ADMIN REJECT PAYMENT
CREATE OR REPLACE FUNCTION public.admin_reject_payment(
    p_payment_id UUID,
    p_reason TEXT DEFAULT 'Payment verification failed.'
)
RETURNS JSONB AS $$
DECLARE
    v_payment RECORD;
BEGIN
    SELECT * INTO v_payment FROM public.payments WHERE id = p_payment_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payment not found.';
    END IF;

    UPDATE public.payments
    SET 
        status = 'REJECTED',
        rejection_reason = p_reason,
        updated_at = NOW()
    WHERE id = p_payment_id;

    UPDATE public.appointments
    SET status = 'REJECTED', rejection_reason = p_reason, updated_at = NOW()
    WHERE id = v_payment.appointment_id;

    SELECT * INTO v_payment FROM public.payments WHERE id = p_payment_id;
    RETURN to_jsonb(v_payment);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 8. ADMIN RELEASE PAYOUT
CREATE OR REPLACE FUNCTION public.admin_release_payout(
    p_payout_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_payout RECORD;
BEGIN
    SELECT * INTO v_payout FROM public.payouts WHERE id = p_payout_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Payout not found.';
    END IF;

    UPDATE public.payouts
    SET 
        status = 'RELEASED',
        released_at = NOW(),
        reference_number = 'PAYOUT-REF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0'),
        updated_at = NOW()
    WHERE id = p_payout_id;

    INSERT INTO public.notifications (
        recipient_user_id, title, message, link_url, type
    ) VALUES (
        v_payout.lawyer_id,
        'Payout Released to Bank Account',
        'Your consultation payout of ₹' || v_payout.amount || ' has been processed and released by NyayaSetu Admin.',
        'lawyer-dashboard.html',
        'payout'
    );

    SELECT * INTO v_payout FROM public.payouts WHERE id = p_payout_id;
    RETURN to_jsonb(v_payout);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 9. ADMIN COMPLETE REFUND
CREATE OR REPLACE FUNCTION public.admin_complete_refund(
    p_refund_id UUID
)
RETURNS JSONB AS $$
DECLARE
    v_refund RECORD;
BEGIN
    SELECT * INTO v_refund FROM public.refunds WHERE id = p_refund_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Refund not found.';
    END IF;

    UPDATE public.refunds
    SET 
        status = 'COMPLETED',
        processed_at = NOW(),
        reference_number = 'REFUND-REF-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0'),
        updated_at = NOW()
    WHERE id = p_refund_id;

    UPDATE public.appointments
    SET status = 'REFUNDED', updated_at = NOW()
    WHERE id = v_refund.appointment_id;

    UPDATE public.payments
    SET status = 'REFUNDED', updated_at = NOW()
    WHERE id = v_refund.payment_id;

    INSERT INTO public.notifications (
        recipient_user_id, title, message, link_url, type
    ) VALUES (
        v_refund.client_id,
        '100% Refund Completed',
        'Your refund of ₹' || v_refund.amount || ' has been completed and credited to your original payment method.',
        'client-dashboard.html',
        'refund'
    );

    SELECT * INTO v_refund FROM public.refunds WHERE id = p_refund_id;
    RETURN to_jsonb(v_refund);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lawyer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lawyer_directory_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_documents ENABLE ROW LEVEL SECURITY;

-- Profiles: Public read, user update
DROP POLICY IF EXISTS "Public can view profiles" ON public.profiles;
CREATE POLICY "Public can view profiles" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Legal Categories: Public read
DROP POLICY IF EXISTS "Public can view legal categories" ON public.legal_categories;
CREATE POLICY "Public can view legal categories" ON public.legal_categories FOR SELECT USING (true);

-- Lawyer Profiles: Public view approved, lawyers update own
DROP POLICY IF EXISTS "Public can view approved lawyer profiles" ON public.lawyer_profiles;
CREATE POLICY "Public can view approved lawyer profiles" ON public.lawyer_profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Lawyers can update own profile" ON public.lawyer_profiles;
CREATE POLICY "Lawyers can update own profile" ON public.lawyer_profiles FOR UPDATE USING (auth.uid() = user_id);

-- Lawyer Directory: Public read
DROP POLICY IF EXISTS "Public can view directory lawyers" ON public.lawyer_directory_profiles;
CREATE POLICY "Public can view directory lawyers" ON public.lawyer_directory_profiles FOR SELECT USING (true);

-- Appointments: Clients, Lawyers, Admins can view and manage
DROP POLICY IF EXISTS "Users can view relevant appointments" ON public.appointments;
CREATE POLICY "Users can view relevant appointments" ON public.appointments FOR SELECT
USING (auth.uid() = client_id OR auth.uid() = lawyer_id OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

DROP POLICY IF EXISTS "Clients can create appointments" ON public.appointments;
CREATE POLICY "Clients can create appointments" ON public.appointments FOR INSERT
WITH CHECK (auth.uid() = client_id);

DROP POLICY IF EXISTS "Parties can update appointments" ON public.appointments;
CREATE POLICY "Parties can update appointments" ON public.appointments FOR UPDATE
USING (auth.uid() = client_id OR auth.uid() = lawyer_id OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- Payments: Relevant parties
DROP POLICY IF EXISTS "Parties can view payments" ON public.payments;
CREATE POLICY "Parties can view payments" ON public.payments FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.appointments a 
        WHERE a.id = appointment_id 
        AND (a.client_id = auth.uid() OR a.lawyer_id = auth.uid())
    ) 
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

DROP POLICY IF EXISTS "Clients can insert payments" ON public.payments;
CREATE POLICY "Clients can insert payments" ON public.payments FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.appointments a 
        WHERE a.id = appointment_id 
        AND a.client_id = auth.uid()
    )
);

-- Receipts: Relevant parties
DROP POLICY IF EXISTS "Parties can view receipts" ON public.receipts;
CREATE POLICY "Parties can view receipts" ON public.receipts FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.appointments a 
        WHERE a.id = appointment_id 
        AND (a.client_id = auth.uid() OR a.lawyer_id = auth.uid())
    ) 
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Refunds: Relevant parties
DROP POLICY IF EXISTS "Parties can view refunds" ON public.refunds;
CREATE POLICY "Parties can view refunds" ON public.refunds FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.appointments a 
        WHERE a.id = appointment_id 
        AND (a.client_id = auth.uid() OR a.lawyer_id = auth.uid())
    ) 
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Payouts: Lawyers and Admin
DROP POLICY IF EXISTS "Lawyers and admin can view payouts" ON public.payouts;
CREATE POLICY "Lawyers and admin can view payouts" ON public.payouts FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.appointments a 
        WHERE a.id = appointment_id 
        AND a.lawyer_id = auth.uid()
    ) 
    OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
);

-- Reviews: Public view, clients insert
DROP POLICY IF EXISTS "Public can view reviews" ON public.reviews;
CREATE POLICY "Public can view reviews" ON public.reviews FOR SELECT USING (true);

DROP POLICY IF EXISTS "Clients can insert reviews" ON public.reviews;
CREATE POLICY "Clients can insert reviews" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = client_id);

-- Notifications: Recipient only
DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
CREATE POLICY "Users can view own notifications" ON public.notifications FOR SELECT USING (auth.uid() = recipient_user_id);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
CREATE POLICY "Users can update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = recipient_user_id);

-- Documents: Relevant parties
DROP POLICY IF EXISTS "Parties can view documents" ON public.appointment_documents;
CREATE POLICY "Parties can view documents" ON public.appointment_documents FOR SELECT
USING (auth.uid() = client_id OR auth.uid() = lawyer_id OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

DROP POLICY IF EXISTS "Clients can upload documents" ON public.appointment_documents;
CREATE POLICY "Clients can upload documents" ON public.appointment_documents FOR INSERT
WITH CHECK (auth.uid() = client_id);

-- ==============================================================================
-- REALTIME PUBLICATION CONFIGURATION
-- ==============================================================================
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.appointments;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.receipts;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.payouts;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.refunds;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.reviews;
EXCEPTION WHEN OTHERS THEN NULL;
END $$;

-- ==============================================================================
-- 1. Disable RLS on the appointment_documents database table
-- ==============================================================================
ALTER TABLE public.appointment_documents DISABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- 2. Drop restrictive foreign key constraints on the documents table
-- ==============================================================================
ALTER TABLE public.appointment_documents 
  DROP CONSTRAINT IF EXISTS appointment_documents_appointment_id_fkey;

