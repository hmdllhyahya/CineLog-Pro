# CineLog Pro Audit (Linux handover)

## Ringkasan kondisi saat ini
- Repo saat ini masih berupa **single-page static app**: hanya `index.html` + workflow deployment/release.
- Belum ditemukan integrasi backend/database (Supabase), auth, atau API layer.
- Data aplikasi (film, review, list, profile) masih hardcoded di front-end dan state user masih disimpan lokal (`localStorage`).

## Temuan utama (yang masih kurang)

### 1) Integrasi Supabase belum ada
**Status:** Belum dikerjakan di repo ini.

Indikator:
- Tidak ada file konfigurasi env seperti `.env.example`.
- Tidak ada referensi `supabase` di source.
- Tidak ada struktur project backend/schema/migration.

**Dampak:**
- Belum ada persistence multi-device / multi-user.
- Semua data sosial (review/feed/likes/comments) belum real-time dan belum tersimpan server-side.

### 2) Arsitektur app masih monolitik 1 file
**Status:** Semua HTML/CSS/JS menyatu di `index.html`.

**Dampak:**
- Sulit scaling fitur (auth, CRUD, feed real-time, moderation).
- Sulit testing dan maintainability.

### 3) Data masih mock/hardcoded
**Status:** Dataset film/review/list ada langsung di JS.

**Dampak:**
- Tidak bisa dikelola dari dashboard/admin.
- Tidak sinkron antar user/device.

### 4) State user lokal saja
**Status:** Onboarding/profile pakai `localStorage`.

**Dampak:**
- Data hilang saat clear browser.
- Tidak ada session/login.

### 5) CI/CD sudah ada, tapi quality gate belum ada
**Status:** Workflow Pages + auto-release sudah ada.

**Gap:**
- Belum ada lint/test pipeline.
- Belum ada workflow validasi HTML/JS sederhana sebelum deploy.

## Rekomendasi lanjutan (prioritas)

### Prioritas 1 — Pondasi Supabase
1. Tambah `supabaseClient` + env (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
2. Definisikan schema awal:
   - `profiles`
   - `movies`
   - `logs`
   - `reviews`
   - `lists`
   - `list_items`
   - `follows`
   - `likes`
   - `comments`
3. Aktifkan RLS policy per tabel (minimal owner-only untuk write).
4. Migrasi data hardcoded ke seed SQL.

### Prioritas 2 — Refactor front-end
1. Pecah `index.html` menjadi:
   - `index.html`
   - `assets/css/*.css`
   - `assets/js/app.js`
   - `assets/js/data|api|ui/*.js`
2. Pisah layer:
   - data access (Supabase queries)
   - state/store
   - rendering/view

### Prioritas 3 — Auth & session
1. Supabase Auth (email magic link atau OAuth Google).
2. Mapping user -> profile.
3. Protect write action (log/review/comment/list/like).

### Prioritas 4 — Quality & deployment hardening
1. Tambah CI check:
   - syntax check JS
   - basic HTML validation
   - smoke test headless
2. Pisahkan workflow deploy pages dari release dengan status checks.

## Definition of Done tahap “Supabase MVP”
- User login/logout.
- User bisa log film + review tersimpan di DB.
- Profile & diary baca dari DB, bukan hardcoded/localStorage.
- Community feed ambil dari tabel reviews/logs.
- Lists CRUD tersimpan server-side.
- RLS aktif dan lolos uji akses dasar.

## Catatan migrasi dari Codex Desktop ke Linux
- Secara repo, jejak integrasi Supabase belum ada. Jadi besar kemungkinan progress sebelumnya belum tersimpan/ter-commit ke branch ini.
- Aman untuk lanjut dari branch saat ini dengan milestone bertahap (MVP dulu), tanpa menunggu environment desktop lama.
