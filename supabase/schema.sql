-- ==============================================================================
-- DATABASE SCHEMA: PORTAL & PROFIL PROGRAM KEAHLIAN TKJ SMK BANJARASRI
-- Supabase PostgreSQL + Auth Trigger + Row Level Security (RLS) Policies
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==============================================================================
-- 2. TABLE: PROFILES
-- Menyimpan data profil user yang terhubung langsung dengan auth.users
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'siswa' CHECK (role IN ('admin', 'guru', 'siswa')),
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

-- Indexing untuk query performa tinggi
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- ==============================================================================
-- 3. TABLE: MATERIALS (Materi 4 Bidang Inti Pembelajaran TKJ)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(10) NOT NULL UNIQUE, -- e.g., '01', '02', '03', '04'
    title TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('Pemrograman', 'Sistem Operasi', 'Konektivitas', 'Konfigurasi')),
    description TEXT NOT NULL,
    content TEXT NOT NULL,
    badge TEXT,
    icon TEXT,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_materials_category ON public.materials(category);
CREATE INDEX IF NOT EXISTS idx_materials_code ON public.materials(code);

-- ==============================================================================
-- 4. TABLE: ACTIVITIES (Kegiatan & Pengumuman Praktik Lab TKJ)
-- ==============================================================================
CREATE TABLE IF NOT EXISTS public.activities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    date TEXT NOT NULL,
    category TEXT DEFAULT 'Praktik Lab',
    location TEXT DEFAULT 'Lab Komputer & Jaringan SMK Banjarasri',
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::TEXT, NOW()) NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_activities_date ON public.activities(date);

-- ==============================================================================
-- 5. TRIGGER & FUNCTION: AUTO CREATE PROFILE DARI AUTH.USERS
-- Menggunakan SECURITY DEFINER dan SET search_path = public agar kebal error
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
SECURITY DEFINER 
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    assigned_role TEXT := 'siswa';
    user_name TEXT;
BEGIN
    -- Ambil role dari raw_user_meta_data jika valid
    IF NEW.raw_user_meta_data->>'role' IN ('admin', 'guru', 'siswa') THEN
        assigned_role := NEW.raw_user_meta_data->>'role';
    END IF;

    -- Ambil full_name jika ada, fallback ke username email
    user_name := COALESCE(
        NEW.raw_user_meta_data->>'full_name', 
        split_part(COALESCE(NEW.email, 'siswa'), '@', 1)
    );

    INSERT INTO public.profiles (id, full_name, email, role, created_at, updated_at)
    VALUES (
        NEW.id,
        user_name,
        COALESCE(NEW.email, ''),
        assigned_role,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE
    SET
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        updated_at = NOW();

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- Fallback keamanan agar pendaftaran auth tidak pernah gagal
    RETURN NEW;
END;
$$;

-- Pasang Trigger ke tabel auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION public.get_current_role()
RETURNS TEXT AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

-- Profiles Policies
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can manage all profiles" ON public.profiles;
CREATE POLICY "Admins can manage all profiles"
    ON public.profiles FOR ALL
    USING (public.get_current_role() = 'admin');

-- Materials Policies
DROP POLICY IF EXISTS "Materials are viewable by everyone" ON public.materials;
CREATE POLICY "Materials are viewable by everyone"
    ON public.materials FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Guru and Admin can insert materials" ON public.materials;
CREATE POLICY "Guru and Admin can insert materials"
    ON public.materials FOR INSERT
    WITH CHECK (public.get_current_role() IN ('admin', 'guru'));

DROP POLICY IF EXISTS "Guru and Admin can update materials" ON public.materials;
CREATE POLICY "Guru and Admin can update materials"
    ON public.materials FOR UPDATE
    USING (public.get_current_role() IN ('admin', 'guru'))
    WITH CHECK (public.get_current_role() IN ('admin', 'guru'));

DROP POLICY IF EXISTS "Guru and Admin can delete materials" ON public.materials;
CREATE POLICY "Guru and Admin can delete materials"
    ON public.materials FOR DELETE
    USING (public.get_current_role() IN ('admin', 'guru'));

-- Activities Policies
DROP POLICY IF EXISTS "Activities are viewable by everyone" ON public.activities;
CREATE POLICY "Activities are viewable by everyone"
    ON public.activities FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Admins can manage activities" ON public.activities;
CREATE POLICY "Admins can manage activities"
    ON public.activities FOR ALL
    USING (public.get_current_role() = 'admin');

-- ==============================================================================
-- 7. INITIAL SEED DATA (4 BIDANG UTAMA TKJ SMK BANJARASRI & KEGIATAN PRAKTIK)
-- ==============================================================================

INSERT INTO public.materials (code, title, category, description, content, badge, icon)
VALUES
(
    '01',
    'Pemrograman Website (Backend)',
    'Pemrograman',
    'Mengenal logika server, pengolahan data, dan cara membangun fitur di balik sebuah website.',
    'Siswa belajar dasar-dasar backend modern menggunakan TypeScript/JavaScript dan Node.js. Materi mencakup konsep RESTful API, otentikasi JWT/Session, manipulasi basis data PostgreSQL, serta integrasi endpoint sistem web sekolah.',
    '01 / CODE',
    'Code'
),
(
    '02',
    'Linux Server & Website Frontend',
    'Sistem Operasi',
    'Berkenalan dengan lingkungan Linux, layanan server, dan antarmuka website.',
    'Eksplorasi sistem operasi open-source Ubuntu Server dan Debian. Siswa mengonfigurasi web server Nginx, SSH hardening, DNS Server (BIND9), manajemen package Linux, serta deploying aplikasi frontend responsive.',
    '02 / LINUX',
    'Terminal'
),
(
    '03',
    'Jaringan Dasar',
    'Konektivitas',
    'Memahami perangkat, topologi, alamat IP, dan konsep dasar komunikasi jaringan.',
    'Pengenalan fondasi jaringan komputer: Model OSI 7 Layer & TCP/IP, teknik subnetting IPv4/IPv6, crimping kabel UTP Cat5e/6, analisis paket dengan Wireshark, serta konfigurasi switch manageable dan VLAN.',
    '03 / CONNECT',
    'Network'
),
(
    '04',
    'Konfigurasi Mikrotik',
    'Konfigurasi',
    'Latihan konfigurasi router dan pengelolaan koneksi jaringan secara terarah.',
    'Praktik langsung menggunakan RouterBOARD Mikrotik dan RouterOS: Konfigurasi DHCP Server/Client, Firewall NAT & Filter Rules, Manajemen Bandwidth (Simple Queue & Tree), Hotspot captive portal, serta routing dinamis.',
    '04 / CREATE (MIKROTIK)',
    'Cpu'
)
ON CONFLICT (code) DO UPDATE
SET
    title = EXCLUDED.title,
    category = EXCLUDED.category,
    description = EXCLUDED.description,
    content = EXCLUDED.content,
    badge = EXCLUDED.badge,
    icon = EXCLUDED.icon;

INSERT INTO public.activities (title, description, date, category, location)
VALUES
(
    'Praktikum Topologi Jaringan & Subnetting IPv4',
    'Pengujian konektivitas antarlab dengan pembagian subnet IP statis dan pengujian packet flow.',
    'Senin, 18 November 2026',
    'Praktik Lab',
    'Lab TKJ 1 - SMK Banjarasri'
),
(
    'Workshop Konfigurasi RouterOS Mikrotik MTCNA Prep',
    'Pengenalan fitur routerboard, konfigurasi hotspot login page sekolah, dan manajemen bandwidth limiter.',
    'Rabu, 20 November 2026',
    'Workshop',
    'Lab Jaringan & Server'
),
(
    'Deploy Web Application & Reverse Proxy Nginx di Ubuntu Server',
    'Implementasi full stack application sekolah pada server lokal Linux dengan SSL Let''s Encrypt dan firewall UFW.',
    'Jumat, 22 November 2026',
    'Proyek Siswa',
    'Lab Komputer Utama'
)
ON CONFLICT DO NOTHING;
