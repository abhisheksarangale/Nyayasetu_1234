-- ==============================================================================
-- 1. Disable RLS on the appointment_documents database table
-- ==============================================================================
ALTER TABLE public.appointment_documents DISABLE ROW LEVEL SECURITY;

-- ==============================================================================
-- 2. Drop restrictive foreign key constraints on the documents table
-- ==============================================================================
ALTER TABLE public.appointment_documents 
  DROP CONSTRAINT IF EXISTS appointment_documents_appointment_id_fkey;
