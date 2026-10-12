# PRD — Aplikasi Manajemen Kelas

| | |
|---|---|
| **Versi** | 1.0 (Draft siap dikembangkan) |
| **Tanggal** | 9 Oktober 2026 |
| **Pemilik produk** | Guru (pengguna utama) |
| **Status** | Disetujui untuk fase pengembangan V1 |

---

## 1. Ringkasan Produk

Aplikasi web untuk **satu guru** yang mengajar **banyak kelas dan mata pelajaran**. Aplikasi membantu guru mengelola **nilai** dan **absensi** siswa, melihat **dashboard laporan per kelas**, dan memanfaatkan **AI (AWS Bedrock)** untuk insight otomatis serta deteksi siswa berisiko. Siswa dapat melihat nilai, absensi, dan insight untuk dirinya sendiri, serta mengajukan izin/sakit yang harus disetujui guru.

### 1.1 Tujuan
1. Menggantikan pencatatan nilai dan absensi manual (buku/spreadsheet) dengan satu sistem terpusat.
2. Memberi guru gambaran cepat kondisi kehadiran dan performa tiap kelas.
3. Membantu guru mengidentifikasi siswa yang membutuhkan perhatian lebih awal.
4. Memberi siswa transparansi atas nilai dan kehadirannya.

### 1.2 Metrik Keberhasilan
| Metrik | Target |
|---|---|
| Waktu input absensi satu sesi (±35 siswa) | ≤ 1 menit |
| Waktu muat dashboard guru | ≤ 2 detik (p95) |
| Siswa berisiko teridentifikasi sebelum UTS/UAS | Guru dapat menjalankan analisis kapan saja dalam ≤ 3 klik |
| Pengajuan izin/sakit terproses | Guru dapat menyetujui/menolak langsung dari dashboard |

### 1.3 Di Luar Cakupan (V1)
Lampiran surat izin/sakit, login Google, analisis AI terjadwal otomatis, ekspor PDF, chatbot tanya-jawab, komentar rapor otomatis, banyak guru, multi-sekolah, KKM/predikat nilai, notifikasi email/WhatsApp.

---

## 2. Pengguna & Hak Akses

### 2.1 Role
| Role | Deskripsi | Jumlah |
|---|---|---|
| **Guru** | Administrator tunggal sistem. Mengelola semua data. | 1 akun (dibuat lewat seed script) |
| **Siswa** | Pengguna read-mostly dengan akses terbatas ke data miliknya. | Banyak (impor CSV / manual) |

### 2.2 Matriks Permission
| Kemampuan | Guru | Siswa |
|---|:---:|:---:|
| Login (NIS/username + password) | ✅ | ✅ |
| Ganti password sendiri | ✅ | ✅ |
| Reset password siswa | ✅ | — |
| CRUD tahun ajaran, kelas, mapel, penugasan mapel | ✅ | — |
| CRUD siswa & impor CSV | ✅ | — |
| Atur komponen nilai & bobot | ✅ | — |
| CRUD penilaian & input nilai | ✅ | — |
| Buat sesi & input absensi | ✅ | — |
| Setujui/tolak pengajuan izin/sakit | ✅ | — |
| Lihat dashboard kelas | ✅ | — |
| Jalankan analisis AI | ✅ | — |
| Ekspor Excel | ✅ | — |
| Atur ambang risiko | ✅ | — |
| Lihat nilai | Semua siswa | **Hanya miliknya** |
| Lihat riwayat absensi | Semua siswa | **Hanya miliknya** |
| Ajukan / batalkan pengajuan izin-sakit (status menunggu) | — | ✅ |
| Lihat insight AI | Semua | **Hanya untuk dirinya** |

> **Aturan keamanan inti:** pembatasan data siswa ditegakkan di **level query backend** (`WHERE siswa_id = <user.id>`), bukan hanya disembunyikan di UI.

---

## 3. Alur Pengguna (User Flow)

### 3.1 Setup Awal (Guru)
1. Login → buat **Tahun Ajaran/Semester** aktif.
2. Buat **Kelas** dan **Mata Pelajaran**, lalu hubungkan mapel ke kelas (`kelas_mapel`).
3. Tambah siswa: **impor CSV** atau **input manual**, lalu tetapkan kelasnya.
4. Unduh daftar kredensial awal (username + password sementara) untuk dibagikan ke siswa.
5. Atur **komponen nilai & bobot** per mapel per kelas (total = 100%).

### 3.2 Input Absensi (Guru)
1. Pilih kelas + mapel → **Buat Sesi** (tanggal, pertemuan ke-, topik opsional).
2. Daftar siswa muncul dengan status default **Hadir**; siswa dengan izin/sakit yang sudah disetujui pada tanggal itu otomatis berstatus **Izin/Sakit**.
3. Guru mengubah status yang berbeda (Terlambat, Dispensasi, Alpha, dst.) → **Simpan**.

### 3.3 Input Nilai (Guru)
1. Pilih kelas + mapel → pilih komponen (Tugas/UH/UTS/UAS) → **Tambah Penilaian** (judul, tanggal).
2. Isi skor per siswa dalam tabel (mendukung tempel dari spreadsheet) → Simpan.
3. Nilai akhir per siswa dihitung otomatis dan tampil di tabel rekap.

### 3.4 Pengajuan Izin/Sakit
1. **Siswa** membuka menu Izin/Sakit → isi jenis (Izin/Sakit), tanggal mulai–selesai, alasan teks → kirim (status *Menunggu*).
2. **Guru** melihat antrean di dashboard → **Setujui** atau **Tolak** (catatan opsional).
3. Jika **disetujui**: absensi siswa pada semua sesi dalam rentang tanggal tersebut menjadi **Izin/Sakit** (sumber: `izin_disetujui`); sesi yang dibuat kemudian pada rentang itu juga default Izin/Sakit.
4. Siswa melihat status keputusan di halamannya.

### 3.5 Analisis AI (Guru)
1. Di dashboard, pilih kelas (opsional: mapel) → klik **Analisis**.
2. Backend menghitung metrik & menandai siswa berisiko, lalu meminta Bedrock menyusun narasi.
3. Hasil tampil di dashboard (ringkasan kelas + daftar siswa berisiko + alasan + saran tindak lanjut) dan insight pribadi muncul di halaman masing-masing siswa.

### 3.6 Siswa Melihat Data
Login → halaman beranda: nilai per mapel (komponen + nilai akhir), riwayat absensi (filter mapel/bulan), status pengajuan, dan insight AI terbaru.

---

## 4. Kebutuhan Fungsional

> Prioritas: **P0** = wajib V1, **P1** = penting, bisa menyusul bila waktu terbatas.

### 4.1 Autentikasi & Akun
| ID | Kebutuhan | Prioritas |
|---|---|:---:|
| AUTH-1 | Login dengan username (NIS untuk siswa) + password. | P0 |
| AUTH-2 | Password di-hash (bcrypt/argon2); sesi via JWT di cookie `httpOnly`, `Secure`, `SameSite=Lax`. | P0 |
| AUTH-3 | Siswa wajib ganti password pada login pertama (`must_change_password`). | P0 |
| AUTH-4 | Guru dapat mereset password siswa (password sementara baru ditampilkan sekali). | P0 |
| AUTH-5 | Rate limiting pada endpoint login (mis. 5 percobaan/menit/IP+username). | P0 |
| AUTH-6 | Middleware otorisasi berbasis role pada seluruh endpoint. | P0 |
| AUTH-7 | Akun guru dibuat via seed script (tanpa halaman registrasi publik). | P0 |

### 4.2 Master Data
| ID | Kebutuhan | Prioritas |
|---|---|:---:|
| MD-1 | CRUD Tahun Ajaran/Semester; hanya satu yang berstatus aktif. | P0 |
| MD-2 | CRUD Kelas (terikat tahun ajaran). | P0 |
| MD-3 | CRUD Mata Pelajaran. | P0 |
| MD-4 | Penugasan mapel ke kelas (`kelas_mapel`). | P0 |
| MD-5 | CRUD Siswa (NIS unik, nama lengkap, kelas). Hapus siswa = **nonaktifkan** (soft delete) agar riwayat tetap utuh. | P0 |
| MD-6 | **Impor CSV** siswa: kolom `nis`, `nama_lengkap`, `kelas`. Validasi per baris, tampilkan laporan baris berhasil/gagal (NIS duplikat, kelas tidak ditemukan, kolom kosong). Password sementara dibuat otomatis. | P0 |
| MD-7 | Unduh template CSV dan unduh daftar kredensial awal hasil impor. | P0 |
| MD-8 | Pindah kelas siswa. | P1 |

### 4.3 Penilaian
| ID | Kebutuhan | Prioritas |
|---|---|:---:|
| NIL-1 | Guru mengatur komponen nilai per `kelas_mapel` (default: Tugas, UH, UTS, UAS) beserta bobot. **Total bobot harus 100%**, jika tidak simpan ditolak. | P0 |
| NIL-2 | Satu komponen dapat memiliki banyak penilaian (mis. Tugas 1, Tugas 2). | P0 |
| NIL-3 | Input skor skala 0–100 (validasi rentang); sel kosong = belum dinilai. | P0 |
| NIL-4 | Perhitungan otomatis (lihat §5.1). | P0 |
| NIL-5 | Tabel rekap per kelas+mapel: baris siswa, kolom komponen + nilai akhir. | P0 |
| NIL-6 | Edit & hapus penilaian (hapus meminta konfirmasi). | P0 |
| NIL-7 | Tempel (paste) skor dari spreadsheet ke tabel input. | P1 |

### 4.4 Absensi
| ID | Kebutuhan | Prioritas |
|---|---|:---:|
| ABS-1 | Status yang didukung: **Hadir, Izin/Sakit, Terlambat, Dispensasi, Alpha**. | P0 |
| ABS-2 | Absensi dicatat **per sesi/pertemuan per mata pelajaran**. Kombinasi (`kelas_mapel`, tanggal, pertemuan_ke) unik. | P0 |
| ABS-3 | Default status Hadir; tombol "Semua Hadir" dan ubah per siswa dengan cepat (satu klik/ketuk). | P0 |
| ABS-4 | Auto-isi Izin/Sakit dari pengajuan yang disetujui (lihat §3.4). | P0 |
| ABS-5 | Catatan opsional per siswa per sesi. | P1 |
| ABS-6 | Edit absensi sesi yang sudah tersimpan. | P0 |
| ABS-7 | Rekap kehadiran per siswa dan per kelas, dengan filter periode (lihat §5.2). | P0 |

### 4.5 Pengajuan Izin/Sakit
| ID | Kebutuhan | Prioritas |
|---|---|:---:|
| IZN-1 | Siswa membuat pengajuan: jenis (Izin/Sakit), tanggal mulai–selesai, alasan (teks, maks. 500 karakter). **Tanpa lampiran.** | P0 |
| IZN-2 | Status: `menunggu`, `disetujui`, `ditolak`, `dibatalkan`. | P0 |
| IZN-3 | Siswa dapat membatalkan pengajuan selama masih `menunggu`. Setelah diputuskan, tidak dapat diubah. | P0 |
| IZN-4 | Guru menyetujui/menolak (catatan opsional) dari dashboard atau halaman khusus. | P0 |
| IZN-5 | Persetujuan memicu pembaruan absensi otomatis dalam satu transaksi database. | P0 |
| IZN-6 | Rentang tanggal tidak boleh mundur lebih dari 14 hari dan maksimal 14 hari panjangnya. | P1 |

### 4.6 Dashboard Guru
| ID | Kebutuhan | Prioritas |
|---|---|:---:|
| DSH-1 | Filter global: tahun ajaran (default aktif), kelas, mapel (opsional), periode (mingguan/bulanan). | P0 |
| DSH-2 | **Kartu KPI:** persentase kehadiran kelas, jumlah siswa berisiko, jumlah pengajuan menunggu, jumlah Alpha periode ini. | P0 |
| DSH-3 | **Grafik tren kehadiran** per periode (line chart) dan **komposisi status absensi** (stacked bar per kelas atau per periode). | P0 |
| DSH-4 | **Tabel siswa berisiko:** nama, kehadiran %, jumlah Alpha, tren nilai, alasan dari AI. Dapat diklik ke detail siswa. | P0 |
| DSH-5 | **Panel ringkasan AI** (narasi kelas) + tombol **Analisis** + waktu analisis terakhir. | P0 |
| DSH-6 | **Antrean izin/sakit menunggu:** tombol Setujui/Tolak langsung di dashboard. | P0 |
| DSH-7 | Perbandingan antar kelas (kehadiran dan rata-rata nilai akhir). | P1 |

> Distribusi nilai/rata-rata nilai **tidak** menjadi widget wajib dashboard V1; rekap nilai tersedia di halaman Penilaian.

### 4.7 Halaman Siswa
| ID | Kebutuhan | Prioritas |
|---|---|:---:|
| SIS-1 | Daftar mapel dengan nilai per komponen dan nilai akhir. | P0 |
| SIS-2 | Riwayat absensi (tanggal, mapel, status) + ringkasan persentase kehadiran. | P0 |
| SIS-3 | Form dan riwayat pengajuan izin/sakit beserta statusnya. | P0 |
| SIS-4 | Kartu insight AI pribadi (pesan suportif + area perhatian). | P0 |

### 4.8 Ekspor
| ID | Kebutuhan | Prioritas |
|---|---|:---:|
| EXP-1 | Ekspor **Excel (.xlsx)** nilai per kelas+mapel (komponen + nilai akhir). | P0 |
| EXP-2 | Ekspor **Excel (.xlsx)** absensi per kelas+mapel pada rentang tanggal (matriks siswa × sesi + rekap persentase). | P0 |

### 4.9 Pengaturan
| ID | Kebutuhan | Prioritas |
|---|---|:---:|
| SET-1 | Guru mengubah ambang risiko (lihat §5.3). | P0 |

---

## 5. Aturan Bisnis

### 5.1 Perhitungan Nilai
- Skala nilai: **0–100**.
- **Nilai komponen** = rata-rata skor semua penilaian dalam komponen tersebut (penilaian yang belum diisi untuk siswa itu diabaikan).
- **Nilai akhir** = Σ (nilai komponen × bobot) ÷ 100.
- Jika ada komponen yang belum memiliki nilai sama sekali, nilai akhir dihitung dari **bobot komponen yang sudah terisi** (dinormalisasi) dan diberi label **"Sementara"**.
- Pembulatan: 2 desimal di penyimpanan/perhitungan, tampil 1–2 desimal.

### 5.2 Perhitungan Kehadiran
- Persentase kehadiran = (**Hadir + Terlambat + Dispensasi**) ÷ total sesi × 100.
- **Izin/Sakit** dan **Alpha** tidak dihitung sebagai hadir.
- *Asumsi:* Terlambat dan Dispensasi dianggap hadir. Definisi ini disimpan sebagai konstanta terpusat sehingga mudah diubah.

### 5.3 Aturan Siswa Berisiko (deterministik, dihitung backend)
Siswa ditandai berisiko bila **salah satu** terpenuhi (ambang default dapat diubah guru):

| Aturan | Default |
|---|---|
| Persentase kehadiran di bawah ambang | **< 80%** |
| Jumlah Alpha mencapai ambang | **≥ 3** |
| Nilai turun berturut-turut pada N penilaian terakhir (dalam satu mapel) | **N = 3** |

### 5.4 Absensi & Izin
- Siswa hanya dapat diabsen pada kelas tempat ia terdaftar.
- Absensi dari persetujuan izin ditandai `sumber = izin_disetujui`; guru tetap boleh menimpanya secara manual (sumber berubah menjadi `manual`).
- Pengajuan yang ditolak/dibatalkan tidak mengubah absensi.

---

## 6. Desain Fitur AI (AWS Bedrock)

### 6.1 Prinsip
**Hibrida:** perhitungan metrik dan penandaan risiko dilakukan **backend secara deterministik**. Bedrock hanya bertugas **menyusun narasi** (ringkasan dan rekomendasi) dari data agregat. Hasilnya akurat, murah, dan mudah diaudit.

### 6.2 Alur
1. Guru klik **Analisis** (scope: kelas, atau kelas + mapel).
2. Backend mengumpulkan metrik per siswa: persentase kehadiran, hitungan per status, tren skor, nilai akhir.
3. Backend menerapkan aturan §5.3 untuk menentukan siswa berisiko.
4. **Anonimisasi:** nama dan NIS diganti ID sementara (`S01`, `S02`, …); pemetaan disimpan hanya di memori backend selama request.
5. Backend memanggil Bedrock (Converse API) dengan prompt + data agregat, meminta **output JSON** terstruktur.
6. Backend memvalidasi JSON (skema), memetakan ID kembali ke siswa, lalu menyimpan ke `ai_analisis` dan `ai_insight_siswa`.
7. Frontend menampilkan hasil. Bila gagal, tampil pesan error dan **metrik deterministik tetap ditampilkan**.

### 6.3 Data yang Dikirim ke Model
- **Dikirim:** ID anonim, angka agregat (persen kehadiran, jumlah per status, deret skor penilaian, nilai akhir), nama mapel, periode.
- **Tidak dikirim:** nama siswa, NIS, username, teks alasan izin/sakit, data guru.

### 6.4 Format Output yang Diminta (kontrak JSON)
```json
{
  "ringkasan_kelas": "string, 2–4 kalimat",
  "siswa": [
    {
      "id": "S01",
      "berisiko": true,
      "alasan": "string singkat, berbasis angka yang diberikan",
      "saran_guru": "string, tindak lanjut konkret",
      "pesan_siswa": "string, nada suportif, tanpa label negatif",
      "area_perhatian": ["kehadiran", "nilai"]
    }
  ]
}
```

### 6.5 Panduan Prompt
- Bahasa Indonesia; nada profesional untuk guru, **suportif dan memotivasi** untuk siswa.
- Model **dilarang** mengarang angka; hanya boleh merujuk data yang diberikan.
- `pesan_siswa` tidak boleh memuat label seperti "berisiko", membandingkan dengan siswa lain, atau membahas kondisi pribadi/kesehatan.
- Output **hanya JSON** (tanpa teks tambahan).

### 6.6 Kontrol & Batasan
| Aspek | Ketentuan |
|---|---|
| Model | Ditentukan lewat env `BEDROCK_MODEL_ID` (tidak di-hardcode). Akses model harus diaktifkan di konsol AWS Bedrock. |
| Region | Env `AWS_REGION`, pilih region yang mendukung model terpilih. |
| Biaya | Set `maxTokens`; batasi analisis per kelas (mis. maks. 60 siswa/panggilan, lebih dari itu dipecah bertahap). |
| Cache | Hasil terakhir disimpan; dashboard menampilkan hasil tersimpan tanpa memanggil ulang. |
| Throttle | Cooldown beberapa detik per kelas untuk mencegah klik berulang. |
| Timeout | Endpoint analisis diatur `maxDuration` yang cukup di Vercel (lihat §9). |
| Visibilitas | Siswa hanya melihat `pesan_siswa` dan `area_perhatian` miliknya; tidak melihat flag "berisiko" atau saran guru. |
| IAM | Kredensial khusus dengan izin minimal `bedrock:InvokeModel` (dan `InvokeModelWithResponseStream` bila streaming dipakai). |

---

## 7. Model Data (PostgreSQL di Neon)

Gunakan UUID sebagai primary key, `created_at`/`updated_at` pada semua tabel, dan enum Postgres untuk nilai tetap.

### 7.1 Diagram Relasi (ringkas)
```
users ──< siswa_kelas >── kelas >── tahun_ajaran
                           │
                           └──< kelas_mapel >── mapel
                                   │
              ┌────────────────────┼────────────────────┐
        komponen_nilai       sesi_pertemuan         ai_analisis
              │                    │                    │
          penilaian             absensi >── users   ai_insight_siswa
              │
            nilai >── users

users ──< pengajuan_izin        pengaturan_risiko (1 baris)
```

### 7.2 Tabel
| Tabel | Kolom Utama | Catatan |
|---|---|---|
| `users` | id, username (unik), password_hash, role (`guru`/`siswa`), nama_lengkap, must_change_password, is_active | Username siswa = NIS |
| `tahun_ajaran` | id, nama, semester (`ganjil`/`genap`), tanggal_mulai, tanggal_selesai, is_aktif | Satu aktif (partial unique index) |
| `kelas` | id, tahun_ajaran_id, nama | Unik (tahun_ajaran_id, nama) |
| `mapel` | id, nama, kode | |
| `kelas_mapel` | id, kelas_id, mapel_id | Unik (kelas_id, mapel_id) |
| `siswa_kelas` | id, siswa_id, kelas_id | Unik (siswa_id, kelas_id); satu kelas per tahun ajaran |
| `komponen_nilai` | id, kelas_mapel_id, nama, bobot (numeric), urutan | Σ bobot per kelas_mapel = 100 (divalidasi di aplikasi) |
| `penilaian` | id, komponen_id, judul, tanggal | |
| `nilai` | id, penilaian_id, siswa_id, skor (numeric(5,2), nullable) | Unik (penilaian_id, siswa_id); CHECK 0–100 |
| `sesi_pertemuan` | id, kelas_mapel_id, tanggal, pertemuan_ke, topik | Unik (kelas_mapel_id, tanggal, pertemuan_ke) |
| `absensi` | id, sesi_id, siswa_id, status (`hadir`/`izin_sakit`/`terlambat`/`dispensasi`/`alpha`), catatan, sumber (`manual`/`izin_disetujui`) | Unik (sesi_id, siswa_id) |
| `pengajuan_izin` | id, siswa_id, jenis (`izin`/`sakit`), tanggal_mulai, tanggal_selesai, alasan, status, catatan_guru, diputuskan_oleh, diputuskan_pada | CHECK tanggal_selesai ≥ tanggal_mulai |
| `pengaturan_risiko` | id, min_kehadiran_persen (80), maks_alpha (3), tren_turun_n (3) | Satu baris |
| `ai_analisis` | id, kelas_id, kelas_mapel_id (nullable), dibuat_oleh, model_id, status, ringkasan_kelas, hasil_guru (jsonb), metrik (jsonb), token_input, token_output, created_at | Riwayat analisis |
| `ai_insight_siswa` | id, analisis_id, siswa_id, pesan, area_perhatian (jsonb) | Dibaca siswa pemilik |

### 7.3 Indeks yang Disarankan
`absensi(siswa_id, sesi_id)`, `sesi_pertemuan(kelas_mapel_id, tanggal)`, `nilai(siswa_id)`, `pengajuan_izin(status, created_at)`, `ai_insight_siswa(siswa_id, created_at DESC)`.

---

## 8. Rancangan API (REST, prefix `/api`)

| Area | Endpoint | Akses |
|---|---|---|
| Auth | `POST /auth/login`, `POST /auth/logout`, `GET /auth/me`, `POST /auth/change-password` | Publik / Login |
| Master | CRUD `/tahun-ajaran`, `/kelas`, `/mapel`, `/kelas/:id/mapel` | Guru |
| Siswa | `GET/POST/PATCH/DELETE /siswa`, `POST /siswa/import` (multipart CSV), `GET /siswa/import/template`, `POST /siswa/:id/reset-password` | Guru |
| Nilai | `GET/PUT /kelas-mapel/:id/komponen`, CRUD `/penilaian`, `PUT /penilaian/:id/nilai` (bulk), `GET /kelas-mapel/:id/rekap-nilai` | Guru |
| Nilai (siswa) | `GET /me/nilai` | Siswa |
| Absensi | `POST /sesi`, `GET /sesi/:id`, `PUT /sesi/:id/absensi` (bulk), `GET /kelas-mapel/:id/rekap-absensi` | Guru |
| Absensi (siswa) | `GET /me/absensi` | Siswa |
| Izin | `POST /izin`, `GET /me/izin`, `PATCH /izin/:id/batal` | Siswa |
| Izin (guru) | `GET /izin?status=menunggu`, `PATCH /izin/:id/setujui`, `PATCH /izin/:id/tolak` | Guru |
| Dashboard | `GET /dashboard/ringkasan`, `GET /dashboard/tren-kehadiran`, `GET /dashboard/komposisi-absensi`, `GET /dashboard/siswa-berisiko` | Guru |
| AI | `POST /ai/analisis` (kelas_id, kelas_mapel_id?), `GET /ai/analisis/terbaru?kelas_id=` | Guru |
| AI (siswa) | `GET /me/insight` | Siswa |
| Ekspor | `GET /ekspor/nilai.xlsx?kelas_mapel_id=`, `GET /ekspor/absensi.xlsx?kelas_mapel_id=&dari=&sampai=` | Guru |
| Pengaturan | `GET/PUT /pengaturan/risiko` | Guru |

**Konvensi:** validasi input dengan Zod; format error seragam `{ error: { code, message, details? } }`; paginasi `?page=&limit=` pada daftar panjang; semua endpoint `/me/*` selalu memakai ID dari sesi, bukan dari parameter.

---

## 9. Arsitektur & Kebutuhan Teknis

### 9.1 Stack
| Lapisan | Teknologi |
|---|---|
| Frontend | React (Vite), React Router, TanStack Query, Recharts, Tailwind CSS (disarankan) |
| Backend | Node.js + Express, Zod, bcrypt/argon2, jsonwebtoken, helmet, express-rate-limit, ExcelJS, multer + csv-parse |
| Database | **PostgreSQL di Neon** (koneksi *pooled*, SSL wajib) |
| ORM/Migrasi | Drizzle ORM + drizzle-kit (disarankan; Prisma juga memungkinkan) |
| AI | AWS Bedrock via `@aws-sdk/client-bedrock-runtime` (Converse API) |
| Deploy | Vercel (frontend statis + Express sebagai Vercel Function) |

### 9.2 Struktur Repositori (monorepo)
```
/
├─ client/               # React (Vite)
├─ server/
│  ├─ src/
│  │  ├─ app.js          # instance Express (tanpa listen)
│  │  ├─ routes/ controllers/ services/ middleware/ db/ validators/
│  │  └─ services/ai/    # bedrock client, prompt, anonymizer, risk rules
│  └─ scripts/seed-guru.js
├─ api/index.js          # entry Vercel Function: export app dari server
├─ drizzle/              # migrasi SQL
├─ vercel.json
└─ .env.example
```

### 9.3 Deployment di Vercel
- Frontend dibangun sebagai situs statis; request `/api/*` di-*rewrite* ke Function Express (`api/index.js`). Dengan satu domain, cookie sesi bersifat *same-origin* sehingga tidak perlu CORS.
- Express **tidak** memanggil `app.listen()` di produksi; Vercel menangani request lewat export handler.
- **Batas waktu Function:** analisis AI dapat memakan beberapa detik. Atur `maxDuration` pada route analisis. Perhatikan limit durasi sesuai paket Vercel (paket Hobby lebih pendek dibanding Pro); jaga prompt tetap ringkas dan batasi jumlah siswa per panggilan.
- Environment variable dikelola di dashboard Vercel (terpisah untuk Preview dan Production).

### 9.4 Database di Neon
- Gunakan *connection string* **pooled** (host `-pooler`) untuk Function serverless; gunakan koneksi *direct* untuk menjalankan migrasi.
- Pakai driver yang cocok serverless (`@neondatabase/serverless`, atau `pg` dengan pool kecil dan reuse koneksi).
- Manfaatkan **Neon branching** untuk lingkungan development/preview agar data produksi aman.
- Operasi multi-tabel (persetujuan izin → update absensi, impor CSV, simpan hasil analisis) dibungkus **transaksi**.
- Aktifkan backup/point-in-time restore sesuai paket Neon.

### 9.5 Environment Variables
```
DATABASE_URL=                # Neon pooled
DATABASE_URL_DIRECT=         # Neon direct (migrasi)
JWT_SECRET=
JWT_EXPIRES_IN=7d
AWS_REGION=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
BEDROCK_MODEL_ID=
AI_MAX_STUDENTS_PER_CALL=60
GURU_SEED_USERNAME=
GURU_SEED_PASSWORD=
NODE_ENV=production
```

### 9.6 Kebutuhan Non-Fungsional
| Kategori | Kebutuhan |
|---|---|
| Performa | Dashboard ≤ 2 dtk (p95) untuk ±10 kelas × 40 siswa; gunakan query agregasi SQL dan indeks. |
| Keamanan | HTTPS, cookie `httpOnly`/`Secure`, helmet, rate limiting, validasi input, query berparameter (anti SQL injection), pembatasan akses siswa di level query, rahasia hanya di env. |
| Privasi | Data pribadi siswa tidak dikirim ke AI (§6.3); hanya guru dan siswa pemilik yang dapat melihat data. |
| Responsif | Tampilan nyaman di ponsel (siswa dan guru input absensi dari HP) dan desktop. |
| Aksesibilitas | Kontras warna memadai, navigasi keyboard pada tabel input, label form yang jelas. |
| Bahasa | Antarmuka seluruhnya Bahasa Indonesia; format tanggal `dd/mm/yyyy`; zona waktu **Asia/Jakarta**. |
| Keandalan | Error AI tidak boleh merusak dashboard; metrik deterministik selalu tersedia. |
| Observabilitas | Log terstruktur (Vercel logs), pencatatan token Bedrock per analisis untuk pemantauan biaya. |
| Pemeliharaan | Migrasi terversi, `.env.example`, README setup, seed script. |

---

## 10. Rancangan Antarmuka (Halaman)

**Guru:** Login · Dashboard · Kelas & Mapel · Siswa (daftar, impor CSV, detail) · Penilaian (komponen & bobot, input nilai, rekap) · Absensi (daftar sesi, input sesi, rekap) · Izin/Sakit (antrean + riwayat) · Analisis AI (riwayat) · Pengaturan (ambang risiko, ganti password).

**Siswa:** Login · Ganti password pertama kali · Beranda (nilai, kehadiran, insight AI) · Absensi · Izin/Sakit · Profil/ganti password.

**Prinsip UX:** input absensi dioptimalkan untuk kecepatan (default Hadir, ketuk untuk ganti status, simpan massal); tabel nilai mendukung navigasi keyboard dan tempel dari spreadsheet; konfirmasi untuk aksi destruktif.

---

## 11. Rencana Pengembangan

| Fase | Cakupan | Hasil |
|---|---|---|
| **M0 — Fondasi** | Repo monorepo, setup Vercel + Neon, skema & migrasi, seed guru, auth + guard role | Login berfungsi di Preview |
| **M1 — Master data** | Tahun ajaran, kelas, mapel, siswa (manual + CSV), reset password | Data awal dapat disiapkan |
| **M2 — Absensi** | Sesi, input absensi, rekap | Absensi harian berjalan |
| **M3 — Penilaian** | Komponen & bobot, penilaian, input nilai, rekap, nilai akhir | Nilai berjalan |
| **M4 — Izin/Sakit** | Pengajuan siswa, antrean guru, auto-update absensi | Alur izin lengkap |
| **M5 — Dashboard & halaman siswa** | KPI, grafik, siswa berisiko (aturan deterministik), halaman siswa | Pelaporan berjalan |
| **M6 — AI** | Integrasi Bedrock, anonimisasi, prompt, penyimpanan hasil, tampilan guru & siswa | Insight AI aktif |
| **M7 — Ekspor & finalisasi** | Ekspor Excel, uji keamanan/otorisasi, perapihan UX, dokumentasi, rilis produksi | V1 rilis |

---

## 12. Strategi Pengujian
- **Unit test:** perhitungan nilai akhir (termasuk kasus komponen kosong), persentase kehadiran, aturan risiko, validasi bobot = 100%, parser CSV.
- **Integrasi/API test:** otorisasi tiap endpoint per role; **siswa tidak bisa membaca data siswa lain** (uji eksplisit dengan ID milik orang lain); transaksi persetujuan izin.
- **Uji AI:** respons Bedrock di-*mock*; uji validasi skema JSON, penanganan JSON rusak/timeout, dan pemastian tidak ada nama/NIS pada payload.
- **UAT:** guru mencoba alur lengkap dengan data satu kelas nyata sebelum rilis.

---

## 13. Kriteria Penerimaan Utama
1. Guru dapat mengimpor CSV berisi ≥ 40 siswa dan menerima laporan baris gagal yang jelas.
2. Guru dapat menyimpan absensi satu sesi dengan kelima status; data tampil benar di rekap dan dashboard.
3. Bobot komponen yang tidak berjumlah 100% **tidak dapat disimpan**; nilai akhir cocok dengan perhitungan manual contoh uji.
4. Pengajuan izin/sakit yang disetujui mengubah absensi sesi dalam rentang tanggal menjadi Izin/Sakit; yang ditolak tidak mengubah apa pun.
5. Siswa A **tidak dapat** mengakses nilai, absensi, pengajuan, maupun insight siswa B melalui UI maupun API langsung.
6. Klik **Analisis** menghasilkan ringkasan kelas dan daftar siswa berisiko; payload ke Bedrock tidak memuat nama/NIS/alasan izin.
7. Bila Bedrock gagal, dashboard tetap menampilkan metrik dan daftar siswa berisiko deterministik beserta pesan error yang jelas.
8. Ekspor Excel nilai dan absensi dapat dibuka dan isinya sesuai tampilan aplikasi.

---

## 14. Risiko & Mitigasi
| Risiko | Dampak | Mitigasi |
|---|---|---|
| Timeout Function Vercel saat analisis AI | Analisis gagal | Atur `maxDuration`, prompt ringkas, batasi siswa per panggilan, pecah bertahap |
| Cold start + koneksi database serverless | Respons lambat | Pooled connection Neon, reuse koneksi, query agregasi efisien |
| Halusinasi/kesalahan narasi AI | Informasi menyesatkan | Metrik dihitung backend, model hanya menarasikan, validasi skema, label "dihasilkan AI" |
| Kebocoran data siswa ke pihak ketiga | Isu privasi | Anonimisasi, tanpa teks bebas, IAM minimal |
| Akses data antar siswa (IDOR) | Pelanggaran privasi | ID dari sesi, uji otorisasi otomatis |
| Biaya Bedrock membengkak | Biaya tak terduga | On-demand saja, cooldown, `maxTokens`, cache hasil, catat token |
| Salah impor CSV | Data siswa kacau | Validasi per baris, pratinjau sebelum commit, laporan galat |

---

## 15. Asumsi & Pertanyaan Terbuka

**Asumsi yang dipakai (dapat direvisi):**
1. Terlambat dan Dispensasi dihitung sebagai hadir pada persentase kehadiran (§5.2).
2. Nilai akhir "Sementara" dinormalisasi dari komponen yang sudah terisi (§5.1).
3. Ambang risiko default 80% / 3 Alpha / tren turun 3 penilaian (§5.3).
4. Satu siswa terdaftar pada satu kelas per tahun ajaran.
5. Insight AI siswa langsung terlihat setelah analisis dijalankan guru.

**Pertanyaan terbuka untuk fase desain:**
1. Apakah guru perlu meninjau/mempublikasikan insight AI sebelum siswa dapat melihatnya?
2. Apakah perlu riwayat perubahan (audit log) untuk edit nilai/absensi?
3. Apakah data tahun ajaran lama perlu diarsipkan/dikunci saat semester berganti?
4. Model Bedrock dan region spesifik yang akan dipakai (menyesuaikan ketersediaan akun AWS dan anggaran).

---

*Akhir dokumen PRD v1.0*
