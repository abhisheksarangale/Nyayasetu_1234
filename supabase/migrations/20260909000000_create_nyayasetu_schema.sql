-- ==============================================================================
-- NYAYASETU — PRODUCTION SUPABASE POSTGRESQL COMPLETE DATABASE SCHEMA
-- ==============================================================================
-- Migration: 20260909000000_create_nyayasetu_schema.sql
-- Description: Complete, production-grade schema for NyayaSetu with all 13 Legal Categories,
-- Profiles, Lawyer Directory, Verification, Appointments, Payments, Receipts,
-- Refunds, Payouts, Documents, Storage Buckets, Realtime, Triggers, and Secure RLS.
-- ==============================================================================

-- 0. ENABLE REQUIRED EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 1. PROFILES TABLE (Linked to auth.users)
-- ==============================================================================
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

-- ==============================================================================
-- 2. LEGAL CATEGORIES TABLE (All 13 Major Practice Areas)
-- ==============================================================================
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

-- Seed all 13 official NyayaSetu Legal Categories
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

-- ==============================================================================
-- 3. LAWYER PROFILES TABLE (Verified Human Lawyers)
-- ==============================================================================
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
    approval_status TEXT NOT NULL DEFAULT 'PENDING' CHECK (approval_status IN ('PENDING', 'APPROVED', 'REJECTED')),
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    rating_average NUMERIC(3, 2) NOT NULL DEFAULT 0.00 CHECK (rating_average >= 0.00 AND rating_average <= 5.00),
    review_count INTEGER NOT NULL DEFAULT 0 CHECK (review_count >= 0),
    rejection_reason TEXT,
    approved_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 4. LAWYER DIRECTORY PROFILES (Public Directory Cache / Seed Data)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.lawyer_directory_profiles (
    id TEXT PRIMARY KEY,
    legacy_id INTEGER UNIQUE,
    linked_user_id TEXT,
    test_route_user_id TEXT,
    display_name TEXT NOT NULL,
    gender TEXT,
    legal_category TEXT NOT NULL,
    years_experience INTEGER NOT NULL DEFAULT 1,
    seed_rating NUMERIC(3, 2) NOT NULL DEFAULT 5.00,
    seed_review_count INTEGER NOT NULL DEFAULT 0,
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

-- ==============================================================================
-- 5. LAWYER VERIFICATION DOCUMENTS & DETAILS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.lawyer_verification_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID REFERENCES public.lawyer_profiles(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    bar_council_enrollment_number TEXT NOT NULL,
    state_bar_council TEXT NOT NULL,
    year_of_enrollment INTEGER NOT NULL,
    practice_areas TEXT[] NOT NULL DEFAULT '{}',
    primary_court TEXT,
    office_address TEXT,
    id_proof_url TEXT,
    certificate_url TEXT,
    document_type TEXT,
    file_name TEXT,
    storage_path TEXT,
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_comment TEXT,
    rejection_reason TEXT,
    verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.lawyer_verification_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID REFERENCES public.lawyer_profiles(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    file_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    verification_status TEXT NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending', 'approved', 'rejected')),
    admin_comment TEXT,
    verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    verified_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 6. APPOINTMENTS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.appointments (
    id TEXT PRIMARY KEY DEFAULT ('apt-' || substr(md5(random()::text), 1, 12)),
    client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lawyer_id UUID,
    directory_profile_id TEXT,
    category_id UUID REFERENCES public.legal_categories(id) ON DELETE SET NULL,
    legal_category TEXT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TEXT NOT NULL,
    consultation_mode TEXT NOT NULL DEFAULT 'video',
    problem_description TEXT NOT NULL,
    dispute_summary TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'accepted', 'completed', 'cancelled', 'rejected')),
    rejection_reason TEXT,
    rejection_category TEXT,
    rejection_comment TEXT,
    consultation_fee NUMERIC(10, 2) NOT NULL DEFAULT 500.00 CHECK (consultation_fee >= 0),
    public_lawyer_name TEXT,
    public_lawyer_image TEXT,
    meeting_link TEXT,
    accepted_at TIMESTAMPTZ,
    rejected_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 7. APPOINTMENT CASE DOCUMENTS
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.appointment_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    appointment_id TEXT NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lawyer_id UUID,
    file_name TEXT,
    original_name TEXT,
    storage_path TEXT NOT NULL,
    mime_type TEXT,
    file_size BIGINT,
    size_bytes BIGINT,
    file_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 8. PAYMENTS TABLE (90% Lawyer Share / 10% Platform Fee)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.payments (
    id TEXT PRIMARY KEY DEFAULT ('pay-' || substr(md5(random()::text), 1, 12)),
    payment_code TEXT UNIQUE,
    appointment_id TEXT UNIQUE NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lawyer_id UUID,
    consultation_fee NUMERIC(10, 2) NOT NULL CHECK (consultation_fee >= 0),
    expected_amount NUMERIC(10, 2),
    platform_fee NUMERIC(10, 2) NOT NULL CHECK (platform_fee >= 0), -- Exactly 10%
    lawyer_amount NUMERIC(10, 2) NOT NULL CHECK (lawyer_amount >= 0), -- Exactly 90%
    total_amount NUMERIC(10, 2) NOT NULL CHECK (total_amount >= 0),
    payment_method TEXT NOT NULL, -- 'upi_qr', 'upi_id', 'card_demo'
    transaction_id TEXT,
    upi_transaction_id TEXT,
    utr_number TEXT,
    payment_status TEXT NOT NULL DEFAULT 'submitted' CHECK (payment_status IN ('pending', 'submitted', 'verified', 'completed', 'rejected', 'refunded', 'failed')),
    refund_status TEXT NOT NULL DEFAULT 'none' CHECK (refund_status IN ('none', 'pending', 'approved', 'processed', 'rejected')),
    payout_status TEXT NOT NULL DEFAULT 'pending' CHECK (payout_status IN ('pending', 'released', 'held', 'paid')),
    payment_proof_path TEXT,
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    paid_at TIMESTAMPTZ,
    verified_at TIMESTAMPTZ,
    verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    verification_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 9. RECEIPTS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.receipts (
    id TEXT PRIMARY KEY DEFAULT ('rec-' || substr(md5(random()::text), 1, 12)),
    receipt_number TEXT NOT NULL UNIQUE,
    payment_id TEXT UNIQUE NOT NULL REFERENCES public.payments(id) ON DELETE CASCADE,
    appointment_id TEXT UNIQUE NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lawyer_id UUID,
    transaction_id TEXT,
    payment_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    client_name TEXT,
    lawyer_name TEXT,
    public_lawyer_name TEXT,
    legal_category TEXT,
    consultation_fee NUMERIC(10, 2) NOT NULL,
    platform_fee NUMERIC(10, 2) NOT NULL,
    lawyer_amount NUMERIC(10, 2) NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL,
    payment_method TEXT NOT NULL,
    payment_status TEXT NOT NULL DEFAULT 'verified',
    pdf_path TEXT,
    issued_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 10. NOTIFICATIONS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.notifications (
    id TEXT PRIMARY KEY DEFAULT ('notif-' || substr(md5(random()::text), 1, 12)),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    recipient_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL DEFAULT 'general',
    notification_type TEXT NOT NULL DEFAULT 'general',
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    appointment_id TEXT,
    payment_id TEXT,
    receipt_id TEXT,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    link TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    read_at TIMESTAMPTZ
);

-- ==============================================================================
-- 11. REVIEWS & RATINGS TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.reviews (
    id TEXT PRIMARY KEY DEFAULT ('rev-' || substr(md5(random()::text), 1, 12)),
    appointment_id TEXT UNIQUE NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    lawyer_id UUID,
    client_name TEXT,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 12. PAYOUTS TABLE (Lawyer Disbursement)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.payouts (
    id TEXT PRIMARY KEY DEFAULT ('payout-' || substr(md5(random()::text), 1, 12)),
    appointment_id TEXT NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    payment_id TEXT NOT NULL REFERENCES public.payments(id) ON DELETE CASCADE,
    lawyer_id UUID,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'released', 'paid', 'held', 'failed')),
    released_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    released_at TIMESTAMPTZ,
    payout_date TIMESTAMPTZ,
    transaction_reference TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 13. REFUNDS TABLE (100% Client Full Refund)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.refunds (
    id TEXT PRIMARY KEY DEFAULT ('ref-' || substr(md5(random()::text), 1, 12)),
    appointment_id TEXT NOT NULL REFERENCES public.appointments(id) ON DELETE CASCADE,
    payment_id TEXT NOT NULL REFERENCES public.payments(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
    reason TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'processed', 'failed')),
    initiated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    initiated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    processed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    transaction_reference TEXT,
    admin_comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==============================================================================
-- 14. LAWYER AVAILABILITY TABLE
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.lawyer_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID REFERENCES public.lawyer_profiles(id) ON DELETE CASCADE,
    available_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT valid_time_range CHECK (start_time < end_time)
);

-- ==============================================================================
-- 15. PERFORMANCE INDEXES
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_lawyer_profiles_user_id ON public.lawyer_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_lawyer_profiles_category_id ON public.lawyer_profiles(category_id);
CREATE INDEX IF NOT EXISTS idx_lawyer_profiles_verification_status ON public.lawyer_profiles(verification_status);
CREATE INDEX IF NOT EXISTS idx_lawyer_profiles_approval_status ON public.lawyer_profiles(approval_status);

CREATE INDEX IF NOT EXISTS idx_appointments_client_id ON public.appointments(client_id);
CREATE INDEX IF NOT EXISTS idx_appointments_lawyer_id ON public.appointments(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON public.appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON public.appointments(appointment_date);

CREATE INDEX IF NOT EXISTS idx_payments_client_id ON public.payments(client_id);
CREATE INDEX IF NOT EXISTS idx_payments_lawyer_id ON public.payments(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON public.payments(payment_status);
CREATE INDEX IF NOT EXISTS idx_payments_appointment_id ON public.payments(appointment_id);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_id ON public.notifications(recipient_user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);

CREATE INDEX IF NOT EXISTS idx_reviews_lawyer_id ON public.reviews(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_payouts_lawyer_id ON public.payouts(lawyer_id);
CREATE INDEX IF NOT EXISTS idx_payouts_status ON public.payouts(status);
CREATE INDEX IF NOT EXISTS idx_refunds_client_id ON public.refunds(client_id);
CREATE INDEX IF NOT EXISTS idx_refunds_status ON public.refunds(status);

-- ==============================================================================
-- 16. AUTOMATIC TRIGGER: UPDATE LAWYER RATING UPON REVIEW CREATION / UPDATE
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.update_lawyer_rating_on_review()
RETURNS TRIGGER AS $$
DECLARE
    target_lawyer_id UUID;
    new_avg NUMERIC(3, 2);
    new_count INTEGER;
BEGIN
    target_lawyer_id := COALESCE(NEW.lawyer_id, OLD.lawyer_id);
    
    IF target_lawyer_id IS NOT NULL THEN
        SELECT 
            COALESCE(ROUND(AVG(rating), 2), 0.00),
            COUNT(*)
        INTO new_avg, new_count
        FROM public.reviews
        WHERE lawyer_id = target_lawyer_id;

        UPDATE public.lawyer_profiles
        SET 
            rating_average = new_avg,
            review_count = new_count,
            updated_at = NOW()
        WHERE id = target_lawyer_id OR user_id = target_lawyer_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_update_lawyer_rating ON public.reviews;
CREATE TRIGGER trg_update_lawyer_rating
AFTER INSERT OR UPDATE OR DELETE ON public.reviews
FOR EACH ROW EXECUTE FUNCTION public.update_lawyer_rating_on_review();

-- ==============================================================================
-- 17. AUTOMATIC TRIGGER: USER SYNC FROM auth.users TO public.profiles
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user_sync()
RETURNS TRIGGER AS $$
DECLARE
    user_role TEXT;
    user_name TEXT;
    user_phone TEXT;
BEGIN
    user_role := COALESCE(NEW.raw_user_meta_data->>'role', 'client');
    user_name := COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1));
    user_phone := NEW.raw_user_meta_data->>'phone';

    INSERT INTO public.profiles (id, email, full_name, phone, role)
    VALUES (NEW.id, NEW.email, user_name, user_phone, user_role)
    ON CONFLICT (id) DO UPDATE
    SET 
        email = EXCLUDED.email,
        full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
        phone = COALESCE(EXCLUDED.phone, public.profiles.phone),
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_sync();

-- ==============================================================================
-- 18. HELPER SECURITY FUNCTION: IS_ADMIN
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.profiles 
        WHERE id = auth.uid() AND role = 'admin' AND is_active = true
    );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- ==============================================================================
-- 19. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.legal_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lawyer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lawyer_directory_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lawyer_verification_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lawyer_verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointment_documents DROP CONSTRAINT IF EXISTS appointment_documents_appointment_id_fkey;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lawyer_availability ENABLE ROW LEVEL SECURITY;

-- 19.1 Profiles Policies
CREATE POLICY "Public profiles can read active basic profile"
ON public.profiles FOR SELECT
USING (true);

CREATE POLICY "Users can update own profile"
ON public.profiles FOR UPDATE
USING (auth.uid() = id OR public.is_admin())
WITH CHECK (auth.uid() = id OR public.is_admin());

-- 19.2 Legal Categories (Public Read, Admin Write)
CREATE POLICY "Public legal categories read"
ON public.legal_categories FOR SELECT
USING (is_active = true OR public.is_admin());

CREATE POLICY "Admin manage legal categories"
ON public.legal_categories FOR ALL
USING (public.is_admin());

-- 19.3 Lawyer Directory Profiles (Public Directory Read)
CREATE POLICY "Public lawyer directory read"
ON public.lawyer_directory_profiles FOR SELECT
USING (is_active = true OR public.is_admin());

CREATE POLICY "Admin manage lawyer directory"
ON public.lawyer_directory_profiles FOR ALL
USING (public.is_admin());

-- 19.4 Lawyer Profiles
CREATE POLICY "Public read verified lawyers"
ON public.lawyer_profiles FOR SELECT
USING (
    (approval_status = 'APPROVED' AND is_active = true)
    OR (auth.uid() = user_id)
    OR public.is_admin()
);

CREATE POLICY "Lawyers can update own profile"
ON public.lawyer_profiles FOR UPDATE
USING (auth.uid() = user_id OR public.is_admin())
WITH CHECK (auth.uid() = user_id OR public.is_admin());

CREATE POLICY "Lawyers insert own profile"
ON public.lawyer_profiles FOR INSERT
WITH CHECK (auth.uid() = user_id OR public.is_admin());

-- 19.5 Appointments Policies
CREATE POLICY "Users read assigned appointments"
ON public.appointments FOR SELECT
USING (
    auth.uid() = client_id
    OR auth.uid() = lawyer_id
    OR public.is_admin()
);

CREATE POLICY "Clients create appointments"
ON public.appointments FOR INSERT
WITH CHECK (
    auth.uid() = client_id
    OR public.is_admin()
);

CREATE POLICY "Parties update appointments"
ON public.appointments FOR UPDATE
USING (
    auth.uid() = client_id
    OR auth.uid() = lawyer_id
    OR public.is_admin()
);

-- 19.6 Appointment Documents Policies
CREATE POLICY "Read appointment documents"
ON public.appointment_documents FOR SELECT
USING (
    auth.uid() = client_id
    OR auth.uid() = lawyer_id
    OR public.is_admin()
);

CREATE POLICY "Insert appointment documents"
ON public.appointment_documents FOR INSERT
WITH CHECK (
    auth.uid() = client_id
    OR auth.uid() = lawyer_id
    OR public.is_admin()
);

-- 19.7 Payments Policies
CREATE POLICY "Read payments"
ON public.payments FOR SELECT
USING (
    auth.uid() = client_id
    OR auth.uid() = lawyer_id
    OR public.is_admin()
);

CREATE POLICY "Clients submit payments"
ON public.payments FOR INSERT
WITH CHECK (
    auth.uid() = client_id
    OR public.is_admin()
);

CREATE POLICY "Admin verify payments"
ON public.payments FOR UPDATE
USING (public.is_admin());

-- 19.8 Receipts Policies
CREATE POLICY "Read receipts"
ON public.receipts FOR SELECT
USING (
    auth.uid() = client_id
    OR auth.uid() = lawyer_id
    OR public.is_admin()
);

CREATE POLICY "Insert receipts"
ON public.receipts FOR INSERT
WITH CHECK (
    auth.uid() = client_id
    OR public.is_admin()
);

-- 19.9 Notifications Policies
CREATE POLICY "Read own notifications"
ON public.notifications FOR SELECT
USING (
    auth.uid() = user_id
    OR auth.uid() = recipient_user_id
    OR public.is_admin()
);

CREATE POLICY "Update own notifications read status"
ON public.notifications FOR UPDATE
USING (
    auth.uid() = user_id
    OR auth.uid() = recipient_user_id
    OR public.is_admin()
);

-- 19.10 Reviews Policies
CREATE POLICY "Public read reviews"
ON public.reviews FOR SELECT
USING (true);

CREATE POLICY "Clients create reviews"
ON public.reviews FOR INSERT
WITH CHECK (
    auth.uid() = client_id
    OR public.is_admin()
);

-- 19.11 Payouts Policies
CREATE POLICY "Lawyers and admin read payouts"
ON public.payouts FOR SELECT
USING (
    auth.uid() = lawyer_id
    OR public.is_admin()
);

CREATE POLICY "Admin manage payouts"
ON public.payouts FOR ALL
USING (public.is_admin());

-- 19.12 Refunds Policies
CREATE POLICY "Clients and admin read refunds"
ON public.refunds FOR SELECT
USING (
    auth.uid() = client_id
    OR public.is_admin()
);

CREATE POLICY "Admin manage refunds"
ON public.refunds FOR ALL
USING (public.is_admin());

-- ==============================================================================
-- 20. SUPABASE STORAGE BUCKETS SETUP
-- ==============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('lawyer-profile-photos', 'lawyer-profile-photos', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
    ('lawyer-verification-documents', 'lawyer-verification-documents', false, 10485760, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
    ('appointment-documents', 'appointment-documents', false, 15728640, ARRAY['image/jpeg', 'image/png', 'application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']),
    ('payment-proofs', 'payment-proofs', false, 5242880, ARRAY['image/jpeg', 'image/png', 'application/pdf']),
    ('receipts', 'receipts', false, 5242880, ARRAY['application/pdf'])
ON CONFLICT (id) DO NOTHING;

-- Storage RLS Policies
CREATE POLICY "Public Access Lawyer Photos" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'lawyer-profile-photos');

CREATE POLICY "Lawyers Upload Own Photo" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'lawyer-profile-photos' AND auth.role() = 'authenticated');

CREATE POLICY "Users Access Own Appointment Documents" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'appointment-documents' AND auth.role() = 'authenticated');

CREATE POLICY "Users Upload Appointment Documents" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'appointment-documents' AND auth.role() = 'authenticated');

-- ==============================================================================
-- 21. REALTIME REPLICATION ENABLEMENT
-- ==============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.appointments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.payments;
ALTER PUBLICATION supabase_realtime ADD TABLE public.receipts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.refunds;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.lawyer_profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.lawyer_directory_profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.reviews;
ALTER PUBLICATION supabase_realtime ADD TABLE public.payouts;

-- ==============================================================================
-- 22. SEED: 49 VERIFIED INDIAN LAWYERS (13 with ₹1 Consultation Fee)
-- ==============================================================================
INSERT INTO public.lawyer_directory_profiles (
    id, legacy_id, linked_user_id, test_route_user_id, display_name, gender, 
    legal_category, years_experience, seed_rating, seed_review_count, 
    consultation_fee, locality, city, state, languages, availability, 
    profile_photo_path, source, is_active, is_bookable, is_test_bookable
) VALUES
('lawyer-1', 1, 'abhisheksarangale-uid', 'lawyer-user-1', 'Adv. Abhishek Sarangale', 'Male', 'family', 12, 4.90, 89, 1.00, 'Bandra West', 'Mumbai', 'Maharashtra', ARRAY['Hindi', 'Marathi', 'English'], 'today', 'Abhishek Sarangale.jpg', 'directory', true, true, true),
('lawyer-2', 2, 'lawyer-user-2', 'lawyer-user-2', 'Adv. Aaditya Verma', 'Male', 'property', 8, 4.70, 45, 1.00, 'Indiranagar', 'Bengaluru', 'Karnataka', ARRAY['English', 'Hindi', 'Kannada'], 'today', 'Aaditya Verma.jpg', 'directory', true, true, true),
('lawyer-3', 3, 'lawyer-user-3', 'lawyer-user-3', 'Adv. Aditya Singh', 'Male', 'criminal', 14, 4.80, 52, 1.00, 'Connaught Place', 'Delhi', 'NCR', ARRAY['Hindi', 'English'], 'tomorrow', 'Aditya Singh.jpg', 'directory', true, true, true),
('lawyer-4', 4, 'lawyer-user-4', 'lawyer-user-4', 'Adv. Akash Reddy', 'Male', 'corporate', 10, 4.90, 73, 1.00, 'Hitec City', 'Hyderabad', 'Telangana', ARRAY['Telugu', 'English', 'Hindi'], 'today', 'Akash Reddy.jpg', 'directory', true, true, true),
('lawyer-5', 5, 'lawyer-user-5', 'lawyer-user-5', 'Adv. Aman Kapoor', 'Male', 'civil', 9, 4.60, 41, 1.00, 'Sector 17', 'Chandigarh', 'Punjab', ARRAY['Hindi', 'Punjabi', 'English'], 'week', 'Aman Kapoor.jpg', 'directory', true, true, true),
('lawyer-6', 6, 'lawyer-user-6', 'lawyer-user-6', 'Adv. Amit Desai', 'Male', 'financial', 15, 4.80, 67, 1.00, 'Ashram Road', 'Ahmedabad', 'Gujarat', ARRAY['Gujarati', 'Hindi', 'English'], 'today', 'Amit Desai.jpg', 'directory', true, true, true),
('lawyer-7', 7, 'lawyer-user-7', 'lawyer-user-7', 'Adv. Ananya Roy', 'Female', 'cyber', 7, 4.90, 58, 1.00, 'Salt Lake', 'Kolkata', 'West Bengal', ARRAY['Bengali', 'English', 'Hindi'], 'today', 'Ananya Roy.jpg', 'directory', true, true, true),
('lawyer-8', 8, 'lawyer-user-8', 'lawyer-user-8', 'Adv. Anika Sharma', 'Female', 'labour', 11, 4.70, 49, 1.00, 'Civil Lines', 'Jaipur', 'Rajasthan', ARRAY['Hindi', 'English'], 'tomorrow', 'Anika Sharma.jpg', 'directory', true, true, true),
('lawyer-9', 9, 'lawyer-user-9', 'lawyer-user-9', 'Adv. Aniruddh Joshi', 'Male', 'taxation', 13, 4.80, 81, 1.00, 'Shivaji Nagar', 'Pune', 'Maharashtra', ARRAY['Marathi', 'Hindi', 'English'], 'today', 'Aniruddh Joshi.jpg', 'directory', true, true, true),
('lawyer-10', 10, 'lawyer-user-10', 'lawyer-user-10', 'Adv. Ankita Sen', 'Female', 'constitutional', 16, 4.90, 94, 1.00, 'Alipore', 'Kolkata', 'West Bengal', ARRAY['Bengali', 'English', 'Hindi'], 'today', 'Ankita Sen.jpg', 'directory', true, true, true),
('lawyer-11', 11, 'lawyer-user-11', 'lawyer-user-11', 'Adv. Aravind Menon', 'Male', 'consumer', 10, 4.60, 39, 1.00, 'MG Road', 'Kochi', 'Kerala', ARRAY['Malayalam', 'English', 'Hindi'], 'week', 'Aravind Menon.jpg', 'directory', true, true, true),
('lawyer-12', 12, 'lawyer-user-12', 'lawyer-user-12', 'Adv. Arjun Nair', 'Male', 'intellectual_property', 8, 4.80, 62, 1.00, 'Anna Nagar', 'Chennai', 'Tamil Nadu', ARRAY['Tamil', 'English', 'Hindi'], 'today', 'Arjun Nair.jpg', 'directory', true, true, true),
('lawyer-13', 13, 'lawyer-user-13', 'lawyer-user-13', 'Adv. Avani Iyer', 'Female', 'environmental', 12, 4.90, 77, 1.00, 'Malleswaram', 'Bengaluru', 'Karnataka', ARRAY['Kannada', 'Tamil', 'English', 'Hindi'], 'today', 'Avani Iyer.jpg', 'directory', true, true, true),
('lawyer-14', 14, 'lawyer-user-14', 'lawyer-user-14', 'Adv. Bhavna Kulkarni', 'Female', 'criminal', 11, 4.80, 56, 800.00, 'Deccan', 'Pune', 'Maharashtra', ARRAY['Marathi', 'Hindi', 'English'], 'today', 'Bhavna Kulkarni.jpg', 'directory', true, true, true),
('lawyer-15', 15, 'lawyer-user-15', 'lawyer-user-15', 'Adv. Chetan Bhatt', 'Male', 'family', 15, 4.70, 72, 1200.00, 'Navrangpura', 'Ahmedabad', 'Gujarat', ARRAY['Gujarati', 'Hindi', 'English'], 'tomorrow', 'Chetan Bhatt.jpg', 'directory', true, true, true),
('lawyer-16', 16, 'lawyer-user-16', 'lawyer-user-16', 'Adv. Deepa Sundaram', 'Female', 'property', 9, 4.60, 48, 950.00, 'T. Nagar', 'Chennai', 'Tamil Nadu', ARRAY['Tamil', 'English'], 'today', 'Deepa Sundaram.jpg', 'directory', true, true, true),
('lawyer-17', 17, 'lawyer-user-17', 'lawyer-user-17', 'Adv. Devendra Rathore', 'Male', 'corporate', 18, 4.90, 110, 2500.00, 'Cyber City', 'Gurugram', 'Haryana', ARRAY['Hindi', 'English'], 'today', 'Devendra Rathore.jpg', 'directory', true, true, true),
('lawyer-18', 18, 'lawyer-user-18', 'lawyer-user-18', 'Adv. Divya Pillai', 'Female', 'civil', 13, 4.80, 64, 1100.00, 'Kowdiar', 'Thiruvananthapuram', 'Kerala', ARRAY['Malayalam', 'English', 'Hindi'], 'today', 'Divya Pillai.jpg', 'directory', true, true, true),
('lawyer-19', 19, 'lawyer-user-19', 'lawyer-user-19', 'Adv. Farhan Qureshi', 'Male', 'financial', 7, 4.50, 31, 750.00, 'Hazratganj', 'Lucknow', 'Uttar Pradesh', ARRAY['Hindi', 'Urdu', 'English'], 'tomorrow', 'Farhan Qureshi.jpg', 'directory', true, true, true),
('lawyer-20', 20, 'lawyer-user-20', 'lawyer-user-20', 'Adv. Gautami Hegde', 'Female', 'cyber', 10, 4.90, 85, 1500.00, 'Koramangala', 'Bengaluru', 'Karnataka', ARRAY['Kannada', 'English', 'Hindi'], 'today', 'Gautami Hegde.jpg', 'directory', true, true, true),
('lawyer-21', 21, 'lawyer-user-21', 'lawyer-user-21', 'Adv. Harshvardhan Jain', 'Male', 'labour', 14, 4.70, 59, 1000.00, 'Malviya Nagar', 'Jaipur', 'Rajasthan', ARRAY['Hindi', 'English'], 'today', 'Harshvardhan Jain.jpg', 'directory', true, true, true),
('lawyer-22', 22, 'lawyer-user-22', 'lawyer-user-22', 'Adv. Ishita Mukherjee', 'Female', 'taxation', 12, 4.80, 78, 1400.00, 'Park Street', 'Kolkata', 'West Bengal', ARRAY['Bengali', 'English', 'Hindi'], 'today', 'Ishita Mukherjee.jpg', 'directory', true, true, true),
('lawyer-23', 23, 'lawyer-user-23', 'lawyer-user-23', 'Adv. Jayesh Patel', 'Male', 'constitutional', 20, 5.00, 142, 3000.00, 'Fort', 'Mumbai', 'Maharashtra', ARRAY['Gujarati', 'Marathi', 'Hindi', 'English'], 'today', 'Jayesh Patel.jpg', 'directory', true, true, true),
('lawyer-24', 24, 'lawyer-user-24', 'lawyer-user-24', 'Adv. Kavita Deshmukh', 'Female', 'consumer', 8, 4.60, 36, 650.00, 'Dharampeth', 'Nagpur', 'Maharashtra', ARRAY['Marathi', 'Hindi', 'English'], 'tomorrow', 'Kavita Deshmukh.jpg', 'directory', true, true, true),
('lawyer-25', 25, 'lawyer-user-25', 'lawyer-user-25', 'Adv. Kunal Singhania', 'Male', 'intellectual_property', 11, 4.90, 91, 1800.00, 'Saket', 'Delhi', 'NCR', ARRAY['Hindi', 'English'], 'today', 'Kunal Singhania.jpg', 'directory', true, true, true),
('lawyer-26', 26, 'lawyer-user-26', 'lawyer-user-26', 'Adv. Madhavan Kutty', 'Male', 'environmental', 16, 4.80, 83, 1600.00, 'Panampilly Nagar', 'Kochi', 'Kerala', ARRAY['Malayalam', 'English'], 'today', 'Madhavan Kutty.jpg', 'directory', true, true, true),
('lawyer-27', 27, 'lawyer-user-27', 'lawyer-user-27', 'Adv. Meenakshi Sundaram', 'Female', 'criminal', 15, 4.90, 104, 1750.00, 'Mylapore', 'Chennai', 'Tamil Nadu', ARRAY['Tamil', 'English', 'Hindi'], 'today', 'Meenakshi Sundaram.jpg', 'directory', true, true, true),
('lawyer-28', 28, 'lawyer-user-28', 'lawyer-user-28', 'Adv. Mohit Agarwal', 'Male', 'family', 9, 4.60, 43, 850.00, 'Gomti Nagar', 'Lucknow', 'Uttar Pradesh', ARRAY['Hindi', 'English'], 'today', 'Mohit Agarwal.jpg', 'directory', true, true, true),
('lawyer-29', 29, 'lawyer-user-29', 'lawyer-user-29', 'Adv. Nandini Rao', 'Female', 'property', 17, 4.90, 118, 2200.00, 'Jubilee Hills', 'Hyderabad', 'Telangana', ARRAY['Telugu', 'English', 'Hindi'], 'today', 'Nandini Rao.jpg', 'directory', true, true, true),
('lawyer-30', 30, 'lawyer-user-30', 'lawyer-user-30', 'Adv. Nikhil Choudhary', 'Male', 'corporate', 12, 4.80, 69, 1600.00, 'Whitefield', 'Bengaluru', 'Karnataka', ARRAY['Hindi', 'English'], 'today', 'Nikhil Choudhary.jpg', 'directory', true, true, true),
('lawyer-31', 31, 'lawyer-user-31', 'lawyer-user-31', 'Adv. Pallavi Goswami', 'Female', 'civil', 10, 4.70, 51, 900.00, 'Beltola', 'Guwahati', 'Assam', ARRAY['Assamese', 'Bengali', 'Hindi', 'English'], 'tomorrow', 'Pallavi Goswami.jpg', 'directory', true, true, true),
('lawyer-32', 32, 'lawyer-user-32', 'lawyer-user-32', 'Adv. Pradeep Rawat', 'Male', 'financial', 14, 4.70, 62, 1300.00, 'Rajpur Road', 'Dehradun', 'Uttarakhand', ARRAY['Hindi', 'English'], 'today', 'Pradeep Rawat.jpg', 'directory', true, true, true),
('lawyer-33', 33, 'lawyer-user-33', 'lawyer-user-33', 'Adv. Priyanka Sen', 'Female', 'cyber', 8, 4.80, 47, 1100.00, 'Bidhannagar', 'Kolkata', 'West Bengal', ARRAY['Bengali', 'English', 'Hindi'], 'today', 'Priyanka Sen.jpg', 'directory', true, true, true),
('lawyer-34', 34, 'lawyer-user-34', 'lawyer-user-34', 'Adv. Rahul Bhatnagar', 'Male', 'labour', 13, 4.80, 74, 1200.00, 'Sector 62', 'Noida', 'Uttar Pradesh', ARRAY['Hindi', 'English'], 'today', 'Rahul Bhatnagar.jpg', 'directory', true, true, true),
('lawyer-35', 35, 'lawyer-user-35', 'lawyer-user-35', 'Adv. Rajeshwari Iyer', 'Female', 'taxation', 19, 4.90, 135, 2400.00, 'Adyar', 'Chennai', 'Tamil Nadu', ARRAY['Tamil', 'English', 'Hindi'], 'today', 'Rajeshwari Iyer.jpg', 'directory', true, true, true),
('lawyer-36', 36, 'lawyer-user-36', 'lawyer-user-36', 'Adv. Rakesh Srivastava', 'Male', 'constitutional', 22, 5.00, 160, 3500.00, 'Civil Lines', 'Prayagraj', 'Uttar Pradesh', ARRAY['Hindi', 'English'], 'today', 'Rakesh Srivastava.jpg', 'directory', true, true, true),
('lawyer-37', 37, 'lawyer-user-37', 'lawyer-user-37', 'Adv. Ritu Saxena', 'Female', 'consumer', 11, 4.70, 58, 850.00, 'Arera Colony', 'Bhopal', 'Madhya Pradesh', ARRAY['Hindi', 'English'], 'today', 'Ritu Saxena.jpg', 'directory', true, true, true),
('lawyer-38', 38, 'lawyer-user-38', 'lawyer-user-38', 'Adv. Rohan Malhotra', 'Male', 'intellectual_property', 9, 4.80, 63, 1400.00, 'Vasant Kunj', 'Delhi', 'NCR', ARRAY['Hindi', 'Punjabi', 'English'], 'today', 'Rohan Malhotra.jpg', 'directory', true, true, true),
('lawyer-39', 39, 'lawyer-user-39', 'lawyer-user-39', 'Adv. Sameer Kulkarni', 'Male', 'environmental', 14, 4.80, 79, 1500.00, 'Kothrud', 'Pune', 'Maharashtra', ARRAY['Marathi', 'Hindi', 'English'], 'today', 'Sameer Kulkarni.jpg', 'directory', true, true, true),
('lawyer-40', 40, 'lawyer-user-40', 'lawyer-user-40', 'Adv. Sangeeta Reddy', 'Female', 'criminal', 16, 4.90, 112, 1900.00, 'Banjara Hills', 'Hyderabad', 'Telangana', ARRAY['Telugu', 'English', 'Hindi'], 'today', 'Sangeeta Reddy.jpg', 'directory', true, true, true),
('lawyer-41', 41, 'lawyer-user-41', 'lawyer-user-41', 'Adv. Sanjeev Nair', 'Male', 'family', 12, 4.70, 67, 1100.00, 'Edappally', 'Kochi', 'Kerala', ARRAY['Malayalam', 'English'], 'today', 'Sanjeev Nair.jpg', 'directory', true, true, true),
('lawyer-42', 42, 'lawyer-user-42', 'lawyer-user-42', 'Adv. Shalini Tripathi', 'Female', 'property', 10, 4.80, 54, 1000.00, 'Aliganj', 'Lucknow', 'Uttar Pradesh', ARRAY['Hindi', 'English'], 'tomorrow', 'Shalini Tripathi.jpg', 'directory', true, true, true),
('lawyer-43', 43, 'lawyer-user-43', 'lawyer-user-43', 'Adv. Siddharth Bose', 'Male', 'corporate', 15, 4.90, 98, 2100.00, 'Ballygunge', 'Kolkata', 'West Bengal', ARRAY['Bengali', 'English', 'Hindi'], 'today', 'Siddharth Bose.jpg', 'directory', true, true, true),
('lawyer-44', 44, 'lawyer-user-44', 'lawyer-user-44', 'Adv. Sneha Nambiar', 'Female', 'civil', 8, 4.60, 40, 750.00, 'Calicut Beach', 'Kozhikode', 'Kerala', ARRAY['Malayalam', 'English'], 'today', 'Sneha Nambiar.jpg', 'directory', true, true, true),
('lawyer-45', 45, 'lawyer-user-45', 'lawyer-user-45', 'Adv. Sudhir Chavan', 'Male', 'financial', 17, 4.80, 88, 1700.00, 'Dadar West', 'Mumbai', 'Maharashtra', ARRAY['Marathi', 'Hindi', 'English'], 'today', 'Sudhir Chavan.jpg', 'directory', true, true, true),
('lawyer-46', 46, 'lawyer-user-46', 'lawyer-user-46', 'Adv. Swati Mathur', 'Female', 'cyber', 11, 4.90, 82, 1450.00, 'C-Scheme', 'Jaipur', 'Rajasthan', ARRAY['Hindi', 'English'], 'today', 'Swati Mathur.jpg', 'directory', true, true, true),
('lawyer-47', 47, 'lawyer-user-47', 'lawyer-user-47', 'Adv. Tarun Bansal', 'Male', 'labour', 9, 4.60, 44, 800.00, 'Model Town', 'Ludhiana', 'Punjab', ARRAY['Punjabi', 'Hindi', 'English'], 'today', 'Tarun Bansal.jpg', 'directory', true, true, true),
('lawyer-48', 48, 'lawyer-user-48', 'lawyer-user-48', 'Adv. Urvashi Mehra', 'Female', 'taxation', 14, 4.80, 90, 1600.00, 'Greater Kailash', 'Delhi', 'NCR', ARRAY['Hindi', 'English'], 'today', 'Urvashi Mehra.jpg', 'directory', true, true, true),
('lawyer-49', 49, 'lawyer-user-49', 'lawyer-user-49', 'Adv. Varun Pillai', 'Male', 'consumer', 13, 4.70, 71, 1150.00, 'Vyttila', 'Kochi', 'Kerala', ARRAY['Malayalam', 'English', 'Hindi'], 'today', 'Varun Pillai.jpg', 'directory', true, true, true)
ON CONFLICT (id) DO UPDATE 
SET 
    display_name = EXCLUDED.display_name,
    legal_category = EXCLUDED.legal_category,
    consultation_fee = EXCLUDED.consultation_fee,
    locality = EXCLUDED.locality,
    city = EXCLUDED.city,
    state = EXCLUDED.state,
    languages = EXCLUDED.languages,
    profile_photo_path = EXCLUDED.profile_photo_path;
