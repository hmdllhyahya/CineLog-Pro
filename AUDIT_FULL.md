# 🎬 AUDIT_FULL.md — CineLog Pro
**Auditor:** Senior Software Auditor (Claude)
**Tanggal:** 2026-03-11
**Scope:** Audit menyeluruh seluruh codebase — bugs, security, arsitektur, fitur, Supabase, CI/CD
**File yang diaudit:** index.html (261KB, 3178 baris), assets/js/config.js, assets/js/supabase-bootstrap.js, supabase/schema.sql, .github/workflows/*.yml, .env.example

---

## RINGKASAN EKSEKUTIF

CineLog Pro adalah SPA (Single Page Application) statis yang sudah berkembang jauh melampaui kondisi yang digambarkan di AUDIT.md lama. App ini sekarang punya **dua layer JS yang hidup berdampingan** di dalam satu file `index.html` — satu layer lama (baris 789–1260) dan satu layer baru yang lebih canggih (baris 2199–3178). Kondisi ini menghasilkan **duplikasi masif** semua function, dua set CSS, dua HTML DOM yang berbeda naming convention, dan konflik runtime yang tidak terdeteksi.

Temuan terbesar: **TMDB API key hardcoded di source code**, **SUPABASE_URL/KEY dikonsumsi tanpa didefinisikan** (akan crash), dan **schema SQL tidak sesuai sama sekali dengan tabel yang dipakai app** (app pakai `cl_*` tables, schema mendefinisikan `public.*` tables).

---

## 1. BUGS & ERRORS

### 🔴 BUG-01: `SUPABASE_URL` dan `SUPABASE_ANON_KEY` tidak terdefinisi saat dipanggil

**Lokasi:** `index.html` baris 2780
```js
CLOUD.client = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {...});
```
**Masalah:** `SUPABASE_URL` dan `SUPABASE_ANON_KEY` dipanggil sebagai variabel global, tapi tidak pernah didefinisikan di `index.html`. `config.js` hanya meng-assign ke `window.CINELOG_CONFIG.SUPABASE_URL`, bukan ke variabel global `SUPABASE_URL`. Ini akan throw `ReferenceError: SUPABASE_URL is not defined` setiap kali `initCloudSession()` dipanggil — bahkan ketika config diisi sekalipun.

**Dampak:** `CLOUD.enabled` selalu `false`. Seluruh cloud sync mati total walau Supabase sudah dikonfigurasi.

**Fix:**
```js
// Di initCloudSession(), ganti:
CLOUD.client = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {...});
// Dengan:
const cfg = window.CINELOG_CONFIG || {};
const url = cfg.SUPABASE_URL || '';
const key = cfg.SUPABASE_ANON_KEY || '';
if (!url || !key) { CLOUD.lastError = 'Config not set'; return false; }
CLOUD.client = supabase.createClient(url, key, {...});
```

---

### 🔴 BUG-02: Duplikasi Masif — Dua Versi Seluruh Codebase di Satu File

**Lokasi:** `index.html` baris 789–1260 (versi lama) vs baris 2199–3178 (versi baru)

**Masalah:** Hampir semua function didefinisikan dua kali:
- `resizeCanvas` → baris 789 & 2199
- `makeBlobs` → baris 790 & 2200
- `bindCursor` → baris 835 & 2246
- `toggleFab` → baris 857 & 2265
- `goBack` → baris 876 & 2282
- `toggleMute/togglePlay` → baris 909-919 & 2308-2320
- `populateMovie` → baris 997 & 2399
- `navigate` → baris 1032 & 2438
- `buildFilmLog` → baris 1080 & 2481
- `runAI` → baris 1130 & 2530
- `analyzeStyle` → baris 1141 & 2562
- `saveProfile` → baris 1157 & 2593
- `postComment` → baris 1119 & 2519

JavaScript menggunakan deklarasi terakhir. Ini berarti versi lama (baris 789–1260) **tidak pernah dijalankan** — tapi mereka masih ada di file, membebani parse time browser sebesar ~40KB.

CSS juga didefinisikan dua kali — ada block `<style>` pertama di `<head>` (baris 12–283) dan block CSS kedua di sekitar baris 1280–1370 dengan naming berbeda (`.btnp`, `.btng`, `.btna` vs `.btn-p`, `.btn-g`, `.btn-a`).

**Dampak:** File 261KB ketika seharusnya ~160KB. Parse overhead besar. Confusing bagi developer selanjutnya. Bugs di satu versi tidak diperbaiki di versi lain.

**Fix:** Hapus seluruh blok baris 789–1260 dan semua CSS dari blok `<style>` pertama yang sudah tidak digunakan oleh HTML kedua.

---

### 🔴 BUG-03: Log Modal — `saveLog()` Tidak Terpanggil (Save Button Salah)

**Lokasi:** `index.html` baris ~596 (versi HTML lama)
```html
<button class="btn btn-p" onclick="closeM('log-modal')">Save to Diary</button>
```

**Masalah:** Save button di HTML versi lama memanggil `closeM()` langsung, bukan `saveLog()`. Fungsi `ensureEnhancements()` mencoba mempatch ini dengan `querySelector('.btn.btnp')`, tapi button di HTML lama pakai class `btn-p` (dengan dash), bukan `btnp` (tanpa dash). Query selector `.btn.btnp` tidak akan pernah match.

HTML versi baru (baris ~2020) sudah benar menggunakan `btnp`, tapi bergantung pada DOM mana yang aktif di runtime menjadi tidak jelas.

**Dampak:** User menekan "Save to Diary" → dialog tertutup tanpa menyimpan data. Log hilang diam-diam.

**Fix:** Pastikan satu versi DOM aktif. Ganti onclick langsung ke `saveLog()` di button tersebut.

---

### 🔴 BUG-04: ID Duplikat di HTML — Dua Versi DOM

**Lokasi:** Baris ~350–650 (versi HTML lama) vs baris ~1730–2060 (versi HTML baru)

Terdapat dua set elemen HTML dengan ID berbeda untuk objek yang sama:

| Konsep | Versi Lama | Versi Baru |
|---|---|---|
| Profile name | `id="prof-name"` | `id="profname"` |
| Profile meta/bio | `id="prof-bio"` | `id="profmeta"` |
| Hero title | `id="h-title"` | `id="htitle"` |
| Hero desc | `id="h-desc"` | `id="hdesc"` |
| Fab dropdown | `id="fab-dd"` | `id="fabdd"` |
| Comment input | `id="comment-input"` | `id="cmtinp"` |
| Comment list | `id="comments-list"` | `id="cmtlist"` |
| Film log grid | `id="log-grid"` | `id="lgrid"` |
| Onboarding body | `id="ob-body"` | `id="obbody"` |
| Onboarding next | `id="ob-next"` | `id="obnext"` |
| Like button | `id="like-btn"` | `id="likebtn"` |

JS versi baru memanggil `getElementById('profname')`, `getElementById('htitle')`, dll. Ketika DOM versi lama aktif, semua panggilan ini return `null` → silent errors sepanjang runtime.

**Dampak:** Profil tidak terupdate, hero tidak terupdate, onboarding tidak berfungsi, semua UI update gagal silently.

---

### 🟡 BUG-05: `getElementById('ai-disclaimer')` Mencari ID yang Tidak Ada di HTML

**Lokasi:** `index.html` — `showAID()` function
```js
const e = document.getElementById('ai-disclaimer');
```
**Masalah:** ID `ai-disclaimer` tidak ada di HTML manapun. `ensureEnhancements()` mencoba membuatnya secara dinamis, tapi `getElementById('aibtn')` di dalam `ensureEnhancements()` juga bisa null jika versi DOM lama aktif.

**Dampak:** Pesan disclaimer AI tidak pernah muncul ke user meski AI gagal load.

---

### 🟡 BUG-06: `getElementById('logdate')`, `getElementById('logreview')` Tidak Ada di HTML

**Lokasi:** `saveLog()` function
```js
date: (document.getElementById('logdate') || {}).value || __today(),
review: ((document.getElementById('logreview') || {}).value || '').trim(),
```
**Masalah:** IDs `logdate` dan `logreview` tidak ada di HTML — mereka di-inject oleh `ensureEnhancements()`. Jika `ensureEnhancements()` gagal (karena `getElementById('log-modal')` null), `saveLog()` akan selalu save date hari ini dan review kosong.

**Dampak:** Review hilang, tanggal salah.

---

### 🟡 BUG-07: `switchVideo()` Dipanggil via String Template di `onclick` — Injection Risk & Fragility

**Lokasi:** `index.html` baris 990 & 2392
```js
tabsEl.innerHTML = m.videos.map((v, i) =>
  `<button onclick="switchVideo(MOVIES.find(x=>x.id==='${m.id}'),${i})">${v.label}</button>`
).join('');
```
**Masalah:** `m.id` di-inject langsung ke string onclick attribute. Jika `m.id` mengandung single quote atau backtick, ini bisa break JS. Juga, `v.label` tidak di-escape sebelum dimasukkan ke innerHTML.

---

### 🟡 BUG-08: `animBG()` dan Canvas `requestAnimationFrame` Loop Tidak Pernah Dibersihkan

**Lokasi:** Canvas background loop (dua versi)

Tidak ada mechanism untuk cancel `requestAnimationFrame` loop. Ketika user navigate antar view, loop terus berjalan. Jika ada error di `drawBG()`, loop crash diam-diam dan background mati tanpa pesan.

---

### 🟢 BUG-09: `edit-bio` ID — `.textContent` pada Input Element

**Lokasi:** JS baris ~1161 vs HTML baris ~604
```js
document.getElementById('edit-bio').textContent = b; // seharusnya .value
```
HTML punya `id="edit-bio"` di `<input>`, tapi JS menggunakan `.textContent` (seharusnya `.value` untuk input). Versi baru menggunakan `id="editbio"` dengan `.value` — konsisten. Tapi versi lama tetap ada.

---

## 2. SECURITY ISSUES

### 🔴 SEC-01: TMDB API Key Hardcoded di Source Code

**Lokasi:** `index.html` baris 2058
```js
const TMDB = '849b72ab31fb69f120ef8c5df5c5f7d0';
```

**Masalah:** API key TMDB di-commit langsung ke source code. File ini dideploy ke GitHub Pages (public), sehingga key ini sepenuhnya exposed ke publik. Siapapun bisa menggunakan key ini untuk request ke TMDB API atas nama project ini.

**Dampak:** Potensi rate limit abuse, account suspension dari TMDB, billing jika key digunakan untuk scraping massal.

**Fix:**
1. Revoke key lama di dashboard TMDB **sekarang**
2. Gunakan backend proxy (misalnya Supabase Edge Function) yang menyimpan key di environment variable server
3. Minimal: pindahkan ke `config.js` dan pastikan tidak pernah di-commit dengan value real

---

### 🔴 SEC-02: XSS Vulnerability — Data Eksternal Dirender Tanpa Escaping

**Lokasi:** Banyak lokasi, contoh utama:

**a) Quote data dari MOVIES (bisa dimanipulasi jika dari Supabase nanti):**
```js
// baris 1009
document.getElementById('md-quotes').innerHTML = m.quotes.map(q =>
  `<div class="qb"><p>"${q.t}"</p><cite>— ${q.a}${q.r ? ', ' + q.r : ''}</cite></div>`
).join('');
```
`q.t`, `q.a`, `q.r` tidak di-escape sebelum dimasukkan ke innerHTML.

**b) Komentar user dirender langsung:**
```js
// baris 1113
cl.innerHTML = r.comments.map(c =>
  `<div>...<p>${c.t}</p></div>`
).join('');
```
`c.t` (teks komentar) tidak di-escape. User bisa injeksi `<script>alert(1)</script>` sebagai komentar.

**c) Poster URL dari log user:**
```js
// baris 1087
d.innerHTML = `<div style="background-image:url('${m.poster}')">...`;
```
`m.poster` tidak di-escape. URL dengan `')` bisa break out dari CSS context.

**d) Versi baru punya `__safe()` function** (baris 2682) tapi tidak konsisten dipakai — banyak template literal masih tidak menggunakannya.

**Dampak:** Stored XSS jika data user tersimpan di Supabase dan dirender ke user lain. Cookie/localStorage theft, session hijacking.

**Fix:** Wajibkan `__safe()` di semua innerHTML interpolation. Lebih baik: gunakan `textContent` dan `createElement` untuk setiap data user-controlled.

---

### 🔴 SEC-03: Schema SQL Tidak Sesuai — App Pakai Tabel Berbeda

**Lokasi:** `supabase/schema.sql` vs `index.html` (CLOUD layer)

Schema mendefinisikan tabel: `profiles`, `movies`, `logs`, `reviews`, `lists`, `list_items`, `follows`, `review_likes`, `review_comments`

Tapi app mengakses tabel: `cl_profiles`, `cl_logs`, `cl_lists`, `cl_friends`, `cl_reviews`, `cl_watchlist`, `cl_user_directory`

**Ini adalah mismatch total.** Schema yang ada tidak bisa digunakan oleh app. Jika schema diapply ke Supabase, `initCloudSession()` akan selalu fail di probe check:
```js
const probe = await CLOUD.client.from('cl_profiles').select('user_id').limit(1);
if (probe.error) { CLOUD.lastError = 'Table cl_profiles not ready'; return false; }
```

**Dampak:** Supabase tidak akan pernah berfungsi meski sudah dikonfigurasi dan schema diapply.

---

### 🟡 SEC-04: Anonymous Sign-in Tanpa Consent User

**Lokasi:** `index.html` baris 2783–2788
```js
if (!session) {
  const sign = await CLOUD.client.auth.signInAnonymously();
  ...
}
```
**Masalah:** App langsung sign-in anonymous tanpa consent user. User tidak tahu bahwa data mereka dikirim ke Supabase. Tidak ada login/logout UI, tidak ada account linking, tidak ada cara bagi user untuk claim anonymous session mereka ke permanent account.

**Dampak:** GDPR/privacy concern. Data hilang jika browser di-clear. Tidak ada cara recover data.

---

### 🟡 SEC-05: RLS Policy di Schema Tidak Melindungi Tabel `movies`

**Lokasi:** `supabase/schema.sql`

Tabel `movies` tidak di-enable RLS-nya dan tidak ada write policy. Siapapun dengan anon key bisa insert/update/delete movie records.

**Fix:**
```sql
alter table public.movies enable row level security;
create policy "movies are publicly readable" on public.movies for select using (true);
-- Hanya service_role yang bisa write
```

---

### 🟡 SEC-06: `cl_user_directory` Rentan Terhadap User Enumeration

**Lokasi:** `index.html` baris 2993
```js
const dataQ = await CLOUD.client.from('cl_user_directory')
  .select('user_id, username, public_id, display_name, avatar_url, status_text')
  .or(`username.ilike.%${q}%,public_id.ilike.%${q}%,display_name.ilike.%${q}%`)
  .limit(8);
```
**Masalah:** Query menggunakan `ilike` dengan wildcard penuh `%query%`. User bisa enumerate semua user dengan query satu karakter. Tidak ada rate limiting atau minimum query length enforced di database level.

---

### 🟢 SEC-07: `config.js` Bisa Tidak Sengaja Di-commit dengan Kredensial Real

**Lokasi:** `assets/js/config.js`

File ini di-commit dengan placeholder kosong — pattern yang benar. Tapi tidak ada `.gitignore` entry untuk mencegah developer mengisi dan commit file ini dengan real credentials.

**Fix:** Tambahkan `assets/js/config.js` ke `.gitignore`. Buat `assets/js/config.example.js` sebagai template.

---

## 3. ARSITEKTUR & CODE QUALITY

### 🔴 ARC-01: Monolith Ekstrim — 261KB, 3178 Baris, Satu File

Seluruh app (HTML, CSS, JS data, JS logic, modal, views) ada di satu file. Ini batas ekstrim dari maintainability:

- **Parse time:** Browser harus parse ~261KB JS+HTML sebelum app bisa interaktif
- **Collaboration:** Tidak mungkin dua developer bekerja paralel tanpa merge conflict
- **Testing:** Tidak ada satu function pun yang bisa di-unit test secara isolated
- **Debugging:** Stack trace tidak bermakna karena semua ada di "line X of index.html"

---

### 🔴 ARC-02: Dua Versi Code Paralel — "Ghost Code" Layer

Seperti dijelaskan di BUG-02: ada dua layer JS lengkap. Layer lama (baris 789–1260) adalah "ghost" — tidak pernah dieksekusi karena didefinisikan ulang oleh layer baru, tapi tetap di-parse browser. Ini ~40KB dead code murni.

---

### 🔴 ARC-03: `ensureEnhancements()` — Anti-Pattern "Patch After Render"

**Lokasi:** `index.html` baris ~2901

`ensureEnhancements()` adalah fungsi yang mencoba mempatch HTML yang sudah dirender — menambahkan ID ke elemen, mengubah onclick handler, inject elemen baru. Ini adalah symptom dari dua layer code yang hidup berdampingan. Setiap bug di HTML lama harus di-fix via JavaScript di layer baru, bukan di HTML langsung.

**Masalah spesifik:**
- `querySelector('.btn.btnp')` mencari class `btnp` tapi button di HTML lama punya class `btn-p` → query tidak pernah match
- Semua patch bergantung pada DOM structure yang bisa berubah kapan saja

---

### 🟡 ARC-04: Global State Tanpa Management Pattern

Semua state app adalah global variables di window scope:
```js
let curMovie, curReview, ytPlayer, sndPlayer, isMuted, isPlaying,
    sndMuted, sndPlaying, ffIdx, ffTimer, fabOpen, logRating, liked,
    navStack, curVidIdx, obStep, userLogs, userLists, userFriends,
    userReviews, userWatchlist, logSelectedMovie, logSort, trendingCache,
    cloudSaveTimer, connectResults, sndPreview, sndIsPlaying, analyzing...
```

Tidak ada encapsulation. Setiap fungsi bisa mutasi state manapun kapan saja. Race condition sangat mungkin terjadi di async functions.

---

### 🟡 ARC-05: Data Layer Tercampur dengan Render Layer

Function seperti `renderCommunity()` sekaligus fetch data (dari `userReviews`), transform data, dan update DOM. Tidak ada separation of concern. Perubahan ke data model memerlukan edit di banyak tempat sekaligus.

---

### 🟡 ARC-06: Duplikasi CSS — Dua Naming Convention

CSS di `<head>` menggunakan BEM-like: `.btn-p`, `.btn-g`, `.btn-a`, `.log-grid`, `.lg-item`, `.lg-poster`

CSS di blok kedua (sekitar baris 1280) menggunakan abbreviated: `.btnp`, `.btng`, `.btna`, `.lgrd`, `.lgi`, `.lgp`

Dua set class dengan styling serupa tapi berbeda. HTML baru menggunakan abbreviated class. HTML lama menggunakan BEM-like. Hasilnya adalah unstyled elements jika salah satu DOM aktif dengan CSS yang salah.

---

### 🟢 ARC-07: Magic Strings untuk View Navigation

```js
navigate('movie&id=dark-knight')
navigate('lists-detail&id=masterpieces')
```
View IDs dan param keys adalah magic strings yang tersebar di seluruh codebase. Typo di mana saja mengakibatkan white screen tanpa error message.

---

### 🟢 ARC-08: `MOVIES` Array Dimutasi Runtime

```js
// ensureMovie():
MOVIES.push(m); // menambah ke global const array!
```
Array `MOVIES` yang seharusnya static data katalog dimutasi setiap kali user log film baru. Ini bisa menyebabkan collision antara film hardcoded dan film dari log user jika ID-nya sama.

---

## 4. FITUR YANG BELUM SELESAI / MISSING

### 🔴 FEAT-01: "Save to Diary" Tidak Benar-Benar Menyimpan (Versi Lama)

Seperti di BUG-03: Log modal button versi lama hanya `closeM()`. User yang berinteraksi dengan versi lama tidak bisa log film sama sekali.

---

### 🔴 FEAT-02: Edit Favorites Tidak Punya Logic

**Lokasi:** `edit-fav-modal` + tombol "Save Favorites"
```html
<button onclick="closeM('edit-fav-modal')">Save Favorites</button>
```
Modal edit favorites menampilkan hardcoded movie posters. Tidak ada fungsi untuk memilih film lain, tidak ada state management untuk "selected favorites", save button hanya menutup modal. Data favorites tidak pernah tersimpan.

---

### 🔴 FEAT-03: "Add Films to List" Tidak Berfungsi

**Lokasi:** List detail view
```html
<button onclick="openM('new-list-modal')">Add Films</button>
```
Tombol "Add Films" di list detail membuka modal **Create New List** — bukan modal untuk menambah film ke list yang sudah ada. Tidak ada UI untuk mencari dan menambah film ke list existing.

---

### 🔴 FEAT-04: Delete List Tidak Berfungsi

**Lokasi:** Edit list modal
```html
<button style="color:#ef4444"><i class="ph-bold ph-trash"></i></button>
```
Tombol delete tidak punya `onclick` handler. List tidak bisa dihapus dari UI.

---

### 🟡 FEAT-05: Like/Unlike Hanya di Memory, Tidak Persist

**Lokasi:** `toggleLike()` function
```js
function toggleLike() {
  liked = !liked;
  document.getElementById('like-btn').classList.toggle('liked', liked);
  ...
}
```
Like count hanya ada di memori session. Refresh = reset. Tidak ada penyimpanan ke localStorage maupun Supabase.

---

### 🟡 FEAT-06: Komentar Tidak Persist

`postComment()` hanya mengappend elemen ke DOM. Tidak ada penyimpanan. Refresh = hilang.

---

### 🟡 FEAT-07: Watchlist Feature Setengah Jalan

Tombol Watchlist ada di movie detail (`id="watchlist-btn"`). `toggleWatchlist()` dan `syncWatchlistButton()` ada di code. Data disimpan ke `userWatchlist` di localStorage. Tapi:
- Tidak ada view khusus watchlist yang bisa diakses dari nav
- Section watchlist di profile di-inject oleh `ensureEnhancements()` secara dinamis
- `renderWatchlistSection()` mencari `id="watchlist-grid"` yang mungkin tidak ada tergantung DOM mana yang aktif

---

### 🟡 FEAT-08: Onboarding Data Tidak Sepenuhnya Di-Sync ke Profile

`obData` diisi selama onboarding, tapi `finishOnboarding()` hanya menyimpan ke localStorage. Jika user refresh setelah onboarding, beberapa field tidak terbaca kembali dengan benar karena ID mismatch antara dua versi DOM.

---

### 🟢 FEAT-09: Star Rating Bisa Disimpan sebagai 0 Tanpa Warning

Di `saveLog()`:
```js
rating: Number(logRating || 0)
```
Jika user tidak menekan bintang (`logRating` masih 0), log disimpan dengan rating 0 tanpa peringatan apapun ke user.

---

### 🟢 FEAT-10: "Connect Plus" / Friend Search Hanya Mock

Fungsi `searchConnectPlus()` mencari ke `cl_user_directory` via Supabase (yang tidak berfungsi karena tabel mismatch), lalu fallback ke `CONNECT_POOL` yang adalah array hardcoded user palsu. User yang ditambahkan sebagai "friend" hanya ada di localStorage lokal — tidak ada mutual follow mechanism.

---

## 5. SUPABASE INTEGRATION GAPS

### 🔴 SUP-01: Schema SQL vs App Layer — Mismatch Total

| Tabel di schema.sql | Tabel yang diakses app |
|---|---|
| `public.profiles` | `cl_profiles` |
| `public.logs` | `cl_logs` |
| `public.reviews` | `cl_reviews` |
| `public.lists` | `cl_lists` |
| `public.list_items` | *(tidak dipakai)* |
| `public.follows` | *(tidak dipakai — diganti `cl_friends`)* |
| `public.review_likes` | *(tidak dipakai)* |
| `public.review_comments` | *(tidak dipakai)* |
| *(tidak ada)* | `cl_watchlist` |
| *(tidak ada)* | `cl_user_directory` |
| `public.movies` | *(tidak dipakai — movies masih hardcoded)* |

**Schema SQL tidak bisa diapply dan langsung dipakai oleh app.** Dibutuhkan schema baru yang mendefinisikan tabel `cl_*`, atau app harus direfactor untuk menggunakan tabel dari schema yang ada.

---

### 🔴 SUP-02: `supabase-bootstrap.js` Tidak Terintegrasi dengan CLOUD Layer

`supabase-bootstrap.js` menginisialisasi `window.supabaseClient` dan `window.supabaseReady`.

`initCloudSession()` di `index.html` **tidak menggunakan** `window.supabaseClient` — ia membuat client baru sendiri via `supabase.createClient()`.

Hasilnya: dua Supabase client bisa aktif bersamaan (satu dari bootstrap, satu dari CLOUD), dengan session berbeda, potensi conflict auth.

---

### 🔴 SUP-03: Anonymous Auth — Data Tidak Bisa di-Claim

App menggunakan anonymous sign-in. Tidak ada:
- Flow upgrade ke email/OAuth account
- UI login/logout
- Cara bagi user untuk recover data jika browser di-clear

---

### 🟡 SUP-04: `cloudPushState()` Pakai Delete+Insert — Tidak Atomic

```js
await CLOUD.client.from('cl_logs').delete().eq('user_id', uid);
// Jika insert gagal di sini, semua data log hilang permanen
if (userLogs.length) {
  await CLOUD.client.from('cl_logs').insert(userLogs.map(...));
}
```
Delete semua log dulu, baru insert ulang. Jika insert gagal di tengah jalan, data hilang. Tidak ada transaction/rollback mechanism.

---

### 🟡 SUP-05: Data Payload Disimpan Sebagai JSON Blob

```js
await CLOUD.client.from('cl_logs').insert(
  userLogs.map(l => ({ user_id: uid, log_id: l.id, payload: l }))
);
```
Seluruh object log disimpan sebagai satu kolom `payload` (JSONB). Ini membuat query/filter/sort di database level tidak mungkin. Untuk menampilkan "film apa yang paling sering ditonton bulan ini", harus pull semua data dulu baru filter di client.

---

### 🟡 SUP-06: RLS di Schema Tidak Mencakup `movies` Table

Seperti di SEC-05. `public.movies` tidak punya RLS enabled, sehingga siapapun dengan anon key bisa write.

---

### 🟢 SUP-07: Trigger `handle_new_user` Akan Crash pada Anonymous User

```sql
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, display_name)
  values (new.id, split_part(new.email, '@', 1), split_part(new.email, '@', 1))
```
Untuk anonymous auth, `new.email` adalah `NULL`. `split_part(NULL, '@', 1)` return `NULL` di PostgreSQL. Jika ada constraint `UNIQUE` atau `NOT NULL` pada username, trigger akan fail dan user creation bisa rollback.

**Fix:**
```sql
values (new.id,
  coalesce(split_part(new.email, '@', 1), 'user_' || substring(new.id::text, 1, 8)),
  coalesce(split_part(new.email, '@', 1), 'Anonymous User'))
```

---

## 6. CI/CD & DEPLOYMENT

### 🔴 CI-01: Deploy ke GitHub Pages Tanpa Quality Gate

**Lokasi:** `.github/workflows/deploy-pages.yml`

Workflow langsung deploy setelah checkout, tanpa:
- Lint HTML/CSS/JS
- Validasi bahwa file tidak mengandung hardcoded credentials
- Smoke test sederhana
- Check bahwa `TMDB` API key tidak ada di source

**Dampak:** Setiap push ke `main` langsung live, termasuk commit yang break app atau expose credentials baru.

---

### 🟡 CI-02: `auto-release.yml` Berjalan Bersamaan dengan Deploy

Kedua workflow trigger pada `push` ke `main`. Tidak ada dependency — release dibuat bersamaan dengan deploy, bukan setelah deploy berhasil. Jika deploy gagal, release tetap dibuat.

**Fix:** Tambahkan `needs` dependency di auto-release:
```yaml
jobs:
  release:
    needs: deploy
```

---

### 🟡 CI-03: Tidak Ada Validasi Environment Variables Sebelum Deploy

`config.js` di-commit kosong. Tidak ada workflow step yang memverifikasi bahwa Supabase URL/key sudah dikonfigurasi (via GitHub Secrets) sebelum deploy. App akan deploy dengan config kosong dan berjalan dalam "local-only mode" secara diam-diam tanpa warning ke user.

---

### 🟡 CI-04: `auto-release.yml` Membuat Release dari Setiap Push — Noise

Setiap push ke `main` menghasilkan GitHub Release baru dengan nama seperti `Auto Release 2026.03.11-143022 (abc1234)`. Ini akan menghasilkan ratusan release dalam seminggu, membuat release history tidak bermakna.

**Fix:** Gunakan tag-based release (`on: push: tags: ['v*']`) atau manual dispatch only.

---

### 🟢 CI-05: Tidak Ada `.gitignore` yang Tepat

Tidak ada `.gitignore` yang mencegah commit:
- File environment yang berisi credentials
- OS files (`.DS_Store`, `Thumbs.db`)
- Editor files (`.vscode/`, `.idea/`)

---

## 7. REKOMENDASI PRIORITAS

### 🔴 CRITICAL — Harus fix sekarang (sebelum commit berikutnya)

| ID | Masalah | Aksi Konkret |
|---|---|---|
| SEC-01 | TMDB API Key exposed di GitHub | 1. Revoke key lama di TMDB dashboard. 2. Jangan commit key baru ke source |
| BUG-01 | `SUPABASE_URL` tidak terdefinisi → ReferenceError | Ganti referensi ke `window.CINELOG_CONFIG.SUPABASE_URL` |
| SUP-01 | Schema SQL ≠ tabel yang dipakai app | Buat `supabase/cl_schema.sql` untuk tabel `cl_*` ATAU refactor app |
| BUG-02 | Dua versi code paralel — 40KB ghost code | Hapus layer lama (JS baris 789–1260, CSS blok pertama) |
| BUG-03 | Log modal Save button tidak trigger `saveLog()` | Fix onclick di kedua versi button |
| BUG-04 | Dual DOM dengan ID berbeda — semua UI update null | Unify ke satu HTML DOM |

### 🟡 IMPORTANT — Fix sebelum launch / beta

| ID | Masalah | Aksi Konkret |
|---|---|---|
| SEC-02 | XSS via innerHTML tanpa escaping | Audit semua innerHTML, wajibkan `__safe()` |
| SEC-04 | Anonymous auth tanpa consent user | Tambahkan auth UI minimal atau notice |
| SUP-02 | Dua Supabase client aktif bersamaan | Gunakan `window.supabaseClient` dari bootstrap |
| SUP-04 | Delete+Insert tidak atomic | Ganti ke upsert pattern |
| FEAT-02 | Edit Favorites tidak fungsional | Implementasi UI + logic |
| FEAT-03 | "Add Films" buka modal salah | Buat modal dedicated untuk add film ke list |
| FEAT-04 | Delete list tidak ada onclick | Tambahkan handler + konfirmasi |
| CI-01 | Deploy tanpa quality gate | Tambahkan step lint + secret scan di workflow |
| SUP-07 | Trigger crash pada anonymous user | Fix `handle_new_user` untuk handle NULL email |

### 🟢 NICE TO HAVE — Bisa dikerjakan nanti

| ID | Masalah | Aksi Konkret |
|---|---|---|
| ARC-01 | Monolith 261KB | Pecah ke modul JS terpisah |
| ARC-04 | Global state tanpa management | Implementasi simple state store |
| ARC-06 | Dual CSS naming convention | Unify ke satu convention |
| FEAT-05 | Like tidak persist | Simpan ke localStorage minimal |
| FEAT-06 | Komentar tidak persist | Simpan ke `userReviews` di state |
| FEAT-09 | Log dengan rating 0 tanpa warning | Tambahkan validasi sebelum save |
| CI-04 | Release spam setiap push | Ganti ke tag-based release |
| BUG-08 | Animation loop tanpa cleanup | Tambahkan `cancelAnimationFrame` |
| SEC-07 | `config.js` bisa di-commit dengan nilai real | Tambahkan ke `.gitignore` |
| SEC-05 | RLS `movies` table tidak aktif | Enable RLS, tambahkan policies |

---

## CATATAN PENTING UNTUK DEVELOPER SELANJUTNYA

1. **Jangan percaya AUDIT.md lama** — kondisi proyek sudah jauh lebih maju. Supabase sudah ada integrasi (walau broken), bukan "belum ada sama sekali". Ada CLOUD layer, anonymous auth, data sync, friend system, dan lebih.

2. **Ada dua HTML di dalam satu file** — ini bukan dua page, ini dua versi HTML yang hidup berdampingan akibat iterasi incremental. Versi baru ada di baris ~1730–2060, versi lama di baris ~350–650. Browser render keduanya, JS hanya mengupdate elemen yang punya ID dari versi baru.

3. **Priority pertama: hapus ghost code.** Sebelum menambah fitur baru, hapus semua kode duplikat. File harus turun dari 261KB ke ~160KB dulu agar bisa di-maintain.

4. **Schema SQL perlu ditulis ulang** sesuai tabel `cl_*` yang dipakai app, atau app perlu direfactor ke pakai schema yang ada. Keduanya valid, tapi harus dipilih satu dan konsisten.

5. **TMDB key harus direvoke segera** — sudah masuk ke Git history dan deployed di GitHub Pages. Key lama sudah compromised.

6. **`supabase-bootstrap.js` dan `initCloudSession()`** adalah dua sistem paralel yang tidak saling berkomunikasi. Salah satunya harus dihapus — rekomendasi: pakai bootstrap, hapus CLOUD.client initialization di index.html.

---

*Audit ini dihasilkan dari pembacaan langsung semua file proyek pada 2026-03-11. Setiap temuan diverifikasi dari source code nyata, bukan dari asumsi atau dokumentasi lama. Verifikasi ulang temuan ini setelah setiap refactor besar.*
