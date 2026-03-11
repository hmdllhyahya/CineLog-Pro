# AUDIT PROMPT — CineLog Pro
> Paste prompt ini ke Claude baru. Claude Desktop dengan MCP Filesystem aktif sangat direkomendasikan.

---

## Konteks Proyek

Kamu adalah senior software auditor. Kamu diminta melakukan **audit menyeluruh** terhadap proyek **CineLog Pro** — sebuah web app pencatat & review film berbasis HTML/CSS/JS statis dengan Supabase sebagai backend target.

Lokasi proyek di filesystem:
```
/home/yahyahmdllh/Projects/CineLog-Pro/
```

Struktur proyek saat ini:
```
CineLog-Pro/
├── .env.example
├── .github/
│   └── workflows/
│       ├── auto-release.yml
│       └── deploy-pages.yml
├── .nojekyll
├── AUDIT.md              ← audit lama, gunakan sebagai referensi tapi jangan percaya 100%
├── SUPABASE_SETUP.md
├── assets/
│   └── js/
│       ├── config.js
│       └── supabase-bootstrap.js
├── index.html            ← file utama, SANGAT besar
├── supabase/
│   └── schema.sql
```

---

## Yang Sudah Diketahui (dari audit sebelumnya)

1. App adalah **single-page static app** — semua HTML/CSS/JS ada di `index.html`
2. Supabase **belum terintegrasi** ke logic app — `config.js` kosong, `supabase-bootstrap.js` ada tapi belum dipakai di fitur apapun
3. Data masih **hardcoded/mock** di JS
4. State user pakai **localStorage** saja
5. Schema SQL sudah ada (`schema.sql`) tapi belum diapply
6. CI/CD sudah ada (GitHub Pages + auto-release) tapi **tidak ada quality gate**

---

## Tugas Audit Kamu

Baca semua file di proyek ini menggunakan filesystem tool. Lakukan audit menyeluruh dan laporkan:

### 1. BUGS & ERRORS
- JavaScript errors (syntax, runtime, logic)
- HTML errors (invalid markup, broken references)
- CSS issues (broken styles, conflicts)
- Broken links atau resource references
- Console errors yang bisa diprediksi

### 2. SECURITY ISSUES
- Exposed credentials atau API keys
- Missing input validation/sanitization
- XSS vulnerabilities di HTML rendering
- Supabase RLS gaps di schema.sql
- Anything that should NOT be committed

### 3. ARSITEKTUR & CODE QUALITY
- Anti-patterns
- Dead code / unused code
- Duplikasi logic
- Monolith issues (semua di 1 file)
- Inconsistency naming/convention

### 4. FITUR YANG BELUM SELESAI / MISSING
- Fitur yang ada UI-nya tapi belum ada logic-nya
- Fitur yang ada logic-nya tapi belum ada UI-nya
- Fitur yang setengah jalan
- Gap antara schema SQL dan implementasi front-end

### 5. SUPABASE INTEGRATION GAPS
- Tabel yang ada di schema tapi belum dipakai di front-end
- Auth flow yang belum diimplementasi
- RLS policies yang incomplete atau salah
- Query yang missing atau salah

### 6. CI/CD & DEPLOYMENT
- Workflow issues di `.github/workflows/`
- Missing environment variables
- Deploy pipeline yang bisa fail
- Missing validation sebelum deploy

### 7. REKOMENDASI PRIORITAS
Setelah audit, buat daftar prioritas perbaikan:
- 🔴 CRITICAL (harus fix sekarang)
- 🟡 IMPORTANT (fix sebelum launch)
- 🟢 NICE TO HAVE (bisa nanti)

---

## Format Output

Buat laporan dalam format Markdown yang terstruktur. Untuk setiap temuan, sertakan:
- **Lokasi** (file + baris kalau bisa)
- **Masalah** (apa yang salah)
- **Dampak** (apa konsekuensinya)
- **Saran fix** (gimana cara benarnya)

Simpan hasil audit ke file baru:
```
/home/yahyahmdllh/Projects/CineLog-Pro/AUDIT_FULL.md
```

---

## Catatan Penting
- Baca `index.html` dengan teliti — ini file terbesar dan paling krusial
- Bandingkan schema SQL dengan implementasi front-end
- Perhatikan `supabase-bootstrap.js` — cek apakah sudah dipanggil dengan benar di `index.html`
- Jangan percaya `AUDIT.md` yang lama 100% — verifikasi sendiri kondisi terkini
- Fokus pada **kondisi nyata saat ini**, bukan yang seharusnya ada
