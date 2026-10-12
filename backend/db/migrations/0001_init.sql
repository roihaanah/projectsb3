-- =====================================================================
-- SiAbsen — Migrasi awal skema database (PostgreSQL / Neon)
-- Mengacu pada PRD §7 (Model Data)
--
-- Konvensi:
--   * Primary key UUID (gen_random_uuid)
--   * created_at / updated_at pada semua tabel
--   * enum Postgres untuk nilai tetap
--   * updated_at diperbarui otomatis via trigger
-- =====================================================================

-- Ekstensi untuk gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------
-- Trigger helper: set updated_at = now() setiap UPDATE
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- ENUM TYPES
-- ---------------------------------------------------------------------
CREATE TYPE user_role        AS ENUM ('guru', 'siswa');
CREATE TYPE semester_jenis   AS ENUM ('ganjil', 'genap');
CREATE TYPE absensi_status   AS ENUM ('hadir', 'izin_sakit', 'terlambat', 'dispensasi', 'alpha');
CREATE TYPE absensi_sumber   AS ENUM ('manual', 'izin_disetujui');
CREATE TYPE izin_jenis       AS ENUM ('izin', 'sakit');
CREATE TYPE izin_status      AS ENUM ('menunggu', 'disetujui', 'ditolak', 'dibatalkan');

-- =====================================================================
-- 1. users  (guru & siswa; username siswa = NIS)
-- =====================================================================
CREATE TABLE users (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username             TEXT NOT NULL UNIQUE,
  password_hash        TEXT NOT NULL,
  role                 user_role NOT NULL,
  nama_lengkap         TEXT NOT NULL,
  must_change_password BOOLEAN NOT NULL DEFAULT false,
  is_active            BOOLEAN NOT NULL DEFAULT true,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 2. tahun_ajaran  (hanya satu yang boleh aktif)
-- =====================================================================
CREATE TABLE tahun_ajaran (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama            TEXT NOT NULL,
  semester        semester_jenis NOT NULL,
  tanggal_mulai   DATE NOT NULL,
  tanggal_selesai DATE NOT NULL,
  is_aktif        BOOLEAN NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_tahun_ajaran_tanggal CHECK (tanggal_selesai >= tanggal_mulai)
);
-- Partial unique index: maksimal satu baris is_aktif = true
CREATE UNIQUE INDEX uniq_tahun_ajaran_aktif
  ON tahun_ajaran (is_aktif) WHERE is_aktif = true;
CREATE TRIGGER trg_tahun_ajaran_updated_at
  BEFORE UPDATE ON tahun_ajaran FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 3. kelas  (terikat tahun ajaran)
-- =====================================================================
CREATE TABLE kelas (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tahun_ajaran_id UUID NOT NULL REFERENCES tahun_ajaran(id) ON DELETE RESTRICT,
  nama            TEXT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uniq_kelas_tahun_nama UNIQUE (tahun_ajaran_id, nama)
);
CREATE TRIGGER trg_kelas_updated_at
  BEFORE UPDATE ON kelas FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 4. mapel  (mata pelajaran)
-- =====================================================================
CREATE TABLE mapel (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nama       TEXT NOT NULL,
  kode       TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_mapel_updated_at
  BEFORE UPDATE ON mapel FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 5. kelas_mapel  (penugasan mapel ke kelas)
-- =====================================================================
CREATE TABLE kelas_mapel (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kelas_id   UUID NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
  mapel_id   UUID NOT NULL REFERENCES mapel(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uniq_kelas_mapel UNIQUE (kelas_id, mapel_id)
);
CREATE TRIGGER trg_kelas_mapel_updated_at
  BEFORE UPDATE ON kelas_mapel FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 6. siswa_kelas  (satu kelas per siswa per tahun ajaran)
-- =====================================================================
CREATE TABLE siswa_kelas (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  siswa_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kelas_id   UUID NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uniq_siswa_kelas UNIQUE (siswa_id, kelas_id)
);
CREATE TRIGGER trg_siswa_kelas_updated_at
  BEFORE UPDATE ON siswa_kelas FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 7. komponen_nilai  (Σ bobot per kelas_mapel = 100, divalidasi di aplikasi)
-- =====================================================================
CREATE TABLE komponen_nilai (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kelas_mapel_id UUID NOT NULL REFERENCES kelas_mapel(id) ON DELETE CASCADE,
  nama          TEXT NOT NULL,
  bobot         NUMERIC(5,2) NOT NULL,
  urutan        INTEGER NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_komponen_bobot CHECK (bobot >= 0 AND bobot <= 100)
);
CREATE TRIGGER trg_komponen_nilai_updated_at
  BEFORE UPDATE ON komponen_nilai FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 8. penilaian  (satu komponen punya banyak penilaian)
-- =====================================================================
CREATE TABLE penilaian (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  komponen_id UUID NOT NULL REFERENCES komponen_nilai(id) ON DELETE CASCADE,
  judul       TEXT NOT NULL,
  tanggal     DATE NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_penilaian_updated_at
  BEFORE UPDATE ON penilaian FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 9. nilai  (skor per siswa per penilaian; nullable = belum dinilai)
-- =====================================================================
CREATE TABLE nilai (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  penilaian_id UUID NOT NULL REFERENCES penilaian(id) ON DELETE CASCADE,
  siswa_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  skor         NUMERIC(5,2),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uniq_nilai_penilaian_siswa UNIQUE (penilaian_id, siswa_id),
  CONSTRAINT chk_nilai_skor CHECK (skor IS NULL OR (skor >= 0 AND skor <= 100))
);
CREATE TRIGGER trg_nilai_updated_at
  BEFORE UPDATE ON nilai FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 10. sesi_pertemuan  (unik per kelas_mapel + tanggal + pertemuan_ke)
-- =====================================================================
CREATE TABLE sesi_pertemuan (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kelas_mapel_id UUID NOT NULL REFERENCES kelas_mapel(id) ON DELETE CASCADE,
  tanggal        DATE NOT NULL,
  pertemuan_ke   INTEGER NOT NULL,
  topik          TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uniq_sesi_kelasmapel_tgl_pertemuan UNIQUE (kelas_mapel_id, tanggal, pertemuan_ke)
);
CREATE TRIGGER trg_sesi_pertemuan_updated_at
  BEFORE UPDATE ON sesi_pertemuan FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 11. absensi  (unik per sesi + siswa)
-- =====================================================================
CREATE TABLE absensi (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sesi_id    UUID NOT NULL REFERENCES sesi_pertemuan(id) ON DELETE CASCADE,
  siswa_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status     absensi_status NOT NULL DEFAULT 'hadir',
  catatan    TEXT,
  sumber     absensi_sumber NOT NULL DEFAULT 'manual',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uniq_absensi_sesi_siswa UNIQUE (sesi_id, siswa_id)
);
CREATE TRIGGER trg_absensi_updated_at
  BEFORE UPDATE ON absensi FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 12. pengajuan_izin
-- =====================================================================
CREATE TABLE pengajuan_izin (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  siswa_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  jenis           izin_jenis NOT NULL,
  tanggal_mulai   DATE NOT NULL,
  tanggal_selesai DATE NOT NULL,
  alasan          TEXT NOT NULL,
  status          izin_status NOT NULL DEFAULT 'menunggu',
  catatan_guru    TEXT,
  diputuskan_oleh UUID REFERENCES users(id) ON DELETE SET NULL,
  diputuskan_pada TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT chk_izin_tanggal CHECK (tanggal_selesai >= tanggal_mulai),
  CONSTRAINT chk_izin_alasan_panjang CHECK (char_length(alasan) <= 500)
);
CREATE TRIGGER trg_pengajuan_izin_updated_at
  BEFORE UPDATE ON pengajuan_izin FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 13. pengaturan_risiko  (satu baris)
-- =====================================================================
CREATE TABLE pengaturan_risiko (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  min_kehadiran_persen NUMERIC(5,2) NOT NULL DEFAULT 80,
  maks_alpha           INTEGER NOT NULL DEFAULT 3,
  tren_turun_n         INTEGER NOT NULL DEFAULT 3,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_pengaturan_risiko_updated_at
  BEFORE UPDATE ON pengaturan_risiko FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 14. ai_analisis  (riwayat analisis per kelas / kelas_mapel)
-- =====================================================================
CREATE TABLE ai_analisis (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kelas_id       UUID NOT NULL REFERENCES kelas(id) ON DELETE CASCADE,
  kelas_mapel_id UUID REFERENCES kelas_mapel(id) ON DELETE SET NULL,
  dibuat_oleh    UUID REFERENCES users(id) ON DELETE SET NULL,
  model_id       TEXT,
  status         TEXT,
  ringkasan_kelas TEXT,
  hasil_guru     JSONB,
  metrik         JSONB,
  token_input    INTEGER,
  token_output   INTEGER,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_ai_analisis_updated_at
  BEFORE UPDATE ON ai_analisis FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- 15. ai_insight_siswa  (dibaca siswa pemilik)
-- =====================================================================
CREATE TABLE ai_insight_siswa (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  analisis_id    UUID NOT NULL REFERENCES ai_analisis(id) ON DELETE CASCADE,
  siswa_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pesan          TEXT,
  area_perhatian JSONB,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_ai_insight_siswa_updated_at
  BEFORE UPDATE ON ai_insight_siswa FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =====================================================================
-- INDEKS yang disarankan (PRD §7.3)
-- =====================================================================
CREATE INDEX idx_absensi_siswa_sesi        ON absensi (siswa_id, sesi_id);
CREATE INDEX idx_sesi_kelasmapel_tanggal   ON sesi_pertemuan (kelas_mapel_id, tanggal);
CREATE INDEX idx_nilai_siswa               ON nilai (siswa_id);
CREATE INDEX idx_pengajuan_status_created  ON pengajuan_izin (status, created_at);
CREATE INDEX idx_ai_insight_siswa_created  ON ai_insight_siswa (siswa_id, created_at DESC);
