# Migrasi Database SiAbsen

File SQL murni, dijalankan berurutan sesuai nomor prefiks.

| File | Isi |
|------|-----|
| `0001_init.sql` | Skema awal: enum, 15 tabel (PRD §7), constraint, trigger `updated_at`, dan indeks (PRD §7.3). |

## Cara menjalankan

Gunakan koneksi **direct** Neon (bukan pooled) untuk migrasi — lihat `DATABASE_URL_DIRECT` di `.env`.

Dengan `psql`:

```bash
psql "$DATABASE_URL_DIRECT" -f backend/db/migrations/0001_init.sql
```

Atau tempel isi file ke SQL Editor pada dashboard Neon.

## Catatan desain

- **UUID** sebagai primary key (`gen_random_uuid()` dari ekstensi `pgcrypto`).
- Kolom `created_at` / `updated_at` ada di semua tabel; `updated_at` diperbarui
  otomatis lewat trigger `set_updated_at()`.
- **Satu tahun ajaran aktif** ditegakkan oleh partial unique index
  `uniq_tahun_ajaran_aktif`.
- Validasi **Σ bobot komponen = 100%** sengaja TIDAK dibuat sebagai constraint
  database (lintas-baris), melainkan divalidasi di level aplikasi sesuai PRD §4.3 (NIL-1).
- Validasi rentang skor nilai `0..100` dan panjang alasan izin `≤ 500` dibuat
  sebagai CHECK constraint.
