# Portal & Profil Program Keahlian TKJ SMK Banjarasri

Aplikasi web modern, cepat, dan responsif untuk Program Keahlian **Teknik Komputer dan Jaringan (TKJ) SMK Banjarasri**. Terinspirasi dari estetika modern *alfari.my.id* dengan fitur *Floating Island Navbar*, *Bento Grid*, interaksi *Tech Nodes Matrix*, mockup *Terminal Lab*, *Dark/Light Mode Toggle*, serta portal autentikasi multi-peran (*Admin*, *Guru*, *Siswa*) yang terhubung dengan **Supabase Database & Auth**.

---

## 🚀 Tech Stack & Arsitektur

- **Framework:** [Next.js 15](https://nextjs.org/) (App Router) + TypeScript
- **Styling:** [Tailwind CSS](https://tailwindcss.com/)
- **Icons:** [Lucide React](https://lucide.dev/)
- **Animations:** [Framer Motion](https://www.framer.com/motion/)
- **Theming:** [next-themes](https://github.com/pacocoursey/next-themes) (Dark/Light Mode)
- **Backend & Database:** [Supabase](https://supabase.com/) (PostgreSQL, Supabase Auth, Row Level Security)
- **Deployment:** [Vercel](https://vercel.com/)

---

## 📁 Struktur Direktori

```plaintext
tkj-smk-banjarasri/
├── .env.local.example          # Template konfigurasi environment Supabase
├── next.config.mjs             # Konfigurasi Next.js
├── package.json                # Dependencies & scripts
├── postcss.config.mjs          # Konfigurasi PostCSS
├── tailwind.config.ts          # Konfigurasi Tailwind & dark mode
├── tsconfig.json               # Konfigurasi TypeScript
├── supabase/
│   └── schema.sql              # Skema SQL, Trigger Auth, dan RLS Policies
└── src/
    ├── middleware.ts           # Next.js middleware proteksi rute multi-role
    ├── app/
    │   ├── globals.css         # Styling global, glassmorphism, scrollbar
    │   ├── layout.tsx          # Root layout & ThemeProvider
    │   ├── page.tsx            # Landing page (Hero, Tentang, Materi, Kegiatan)
    │   ├── login/
    │   │   └── page.tsx        # Halaman Login split-screen dengan validasi role
    │   ├── register/
    │   │   └── page.tsx        # Halaman Pendaftaran mandiri siswa
    │   └── dashboard/
    │       └── page.tsx        # Dashboard terproteksi role (Admin/Guru/Siswa)
    ├── components/
    │   ├── bento-material-card.tsx # Bento grid 4 bidang materi & modal silabus
    │   ├── hero-nodes.tsx          # Tech node interactive diagram TKJ CONNECTED
    │   ├── navbar.tsx              # Floating Island pill navbar glassmorphism
    │   ├── terminal-mockup.tsx     # Mockup terminal interaktif tkj-lab
    │   ├── theme-provider.tsx      # Provider next-themes
    │   └── theme-toggle.tsx        # Tombol toggle Dark/Light mode
    ├── types/
    │   └── database.ts         # TypeScript schema definitions
    └── utils/
        └── supabase/
            ├── client.ts       # Browser Supabase client
            ├── middleware.ts   # Session handler middleware
            └── server.ts       # Server Supabase client (cookies)
```

---

## 🛠️ Langkah 1: Persiapan Database Supabase

1. Buat proyek baru di [Supabase Dashboard](https://supabase.com/dashboard).
2. Buka menu **SQL Editor** pada project Supabase Anda.
3. Buka file `supabase/schema.sql` pada repositori ini, salin seluruh kodenya, lalu tempelkan ke SQL Editor Supabase dan jalankan (**Run**).
4. Script ini otomatis akan:
   - Membuat enum `user_role` (`admin`, `guru`, `siswa`).
   - Membuat tabel `public.profiles` yang terhubung otomatis ke `auth.users` via trigger.
   - Membuat tabel `public.materials` dengan 4 kompetensi inti TKJ.
   - Membuat tabel `public.activities` untuk agenda praktikum laboratorium.
   - Mengaktifkan kebijakan **Row Level Security (RLS)** ketat untuk semua tabel.
   - Memasukkan *seed data* materi dan agenda lab awal.

---

## 💻 Langkah 2: Setup Lingkungan Lokal

1. Salin template variabel lingkungan:
   ```bash
   cp .env.local.example .env.local
   ```
2. Isi nilai kredensial dari project settings Supabase Anda (**Project Settings** -> **API**):
   ```env
   NEXT_PUBLIC_SUPABASE_URL=https://xxxxxxxxxxxxxxxxxxxx.supabase.co
   NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJh......
   SUPABASE_SERVICE_ROLE_KEY=eyJh......
   ```
3. Install dependencies:
   ```bash
   npm install
   # atau pnpm install / yarn install
   ```
4. Jalankan server lokal:
   ```bash
   npm run dev
   ```
5. Buka [http://localhost:3000](http://localhost:3000) di browser Anda.

---

## 🐙 Langkah 3: Push ke GitHub Repository

1. Inisialisasi Git di folder proyek:
   ```bash
   git init
   git add .
   git commit -m "feat: initial commit portal tkj smk banjarasri"
   ```
2. Buat repositori baru di GitHub (misal: `tkj-smk-banjarasri`).
3. Hubungkan repositori lokal ke GitHub:
   ```bash
   git branch -M main
   git remote add origin https://github.com/USERNAME/tkj-smk-banjarasri.git
   git push -u origin main
   ```

---

## ☁️ Langkah 4: Panduan Deploy ke Vercel

1. Buka [Vercel Dashboard](https://vercel.com/) dan klik **Add New...** -> **Project**.
2. Hubungkan akun GitHub Anda dan pilih repositori `tkj-smk-banjarasri`.
3. Di bagian **Configure Project**:
   - **Framework Preset:** `Next.js`
   - **Root Directory:** `./`
4. Di bagian **Environment Variables**, tambahkan:
   - `NEXT_PUBLIC_SUPABASE_URL` = (URL Supabase Anda)
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` = (Anon Key Supabase Anda)
   - `SUPABASE_SERVICE_ROLE_KEY` = (Service Role Key Supabase Anda)
5. Klik **Deploy**.
6. Vercel akan otomatis melakukan build dan memberikan tautan domain publik HTTPS (misal: `https://tkj-smk-banjarasri.vercel.app`).

---

## 🔒 Konfigurasi Autentikasi Multi-Peran

- **Pendaftaran Siswa Baru:**
  Siswa dapat mendaftar langsung di halaman `/register`. Trigger database otomatis menetapkan peran `siswa`.
- **Membuat Akun Guru / Admin:**
  1. Daftarkan akun baru di halaman `/register`.
  2. Buka Supabase Dashboard -> **Table Editor** -> pilih tabel `profiles`.
  3. Ubah kolom `role` pada baris akun yang diinginkan dari `siswa` menjadi `guru` atau `admin`.
- **Validasi Login:**
  Form login `/login` secara proaktif mencocokkan pilihan dropdown peran dengan data peran di `public.profiles`. Akses ditolak jika peran yang dipilih tidak cocok, mencegah eskalasi hak akses ilegal.

---

## 📄 Lisensi & Hak Cipta

Dibuat untuk Program Keahlian **Teknik Komputer dan Jaringan (TKJ) SMK Banjarasri**.
Hak cipta dilindungi.
