# SiAbsen — Aplikasi Manajemen Kelas

Project fullstack dengan folder terpisah untuk backend dan frontend.

- `backend/` — Node.js + Express (API, nantinya terhubung ke Neon PostgreSQL)
- `frontend/` — React (Vite)

Status saat ini: **Tahap Fondasi (M0)** — scaffolding + skema database + koneksi Neon + health check.

## Struktur

```
SiAbsen/
├─ backend/
│  ├─ src/
│  │  ├─ app.js            # instance Express (tanpa listen)
│  │  ├─ index.js          # entry point lokal (app.listen)
│  │  ├─ db/index.js       # koneksi Neon (Pool) + helper query
│  │  └─ routes/health.js  # GET /api/health (cek DB)
│  ├─ db/migrations/       # skema SQL murni (0001_init.sql)
│  ├─ scripts/migrate.js   # runner migrasi
│  └─ .env.example
└─ frontend/
   ├─ src/
   │  ├─ App.jsx           # halaman utama penampil status backend
   │  └─ main.jsx
   └─ vite.config.js       # proxy /api -> backend
```

## Menjalankan secara lokal

Butuh dua terminal.

### 1. Backend

```bash
cd backend
npm install

# Salin .env.example ke .env lalu isi DATABASE_URL (Neon pooled)
# Jalankan migrasi skema (sekali saja / saat skema berubah)
npm run migrate

npm run dev
```

Server berjalan di `http://localhost:4000`. Uji endpoint:

```bash
curl http://localhost:4000/api/health
# { "status": "OK", "database": "up", ... }
```

### 2. Frontend

```bash
cd frontend
npm install
npm run dev
```

Buka `http://localhost:5173`. Halaman utama akan memanggil `/api/health`
(di-proxy ke backend) dan menampilkan status **OK**.
