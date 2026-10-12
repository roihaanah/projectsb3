import { Pool, neonConfig } from '@neondatabase/serverless';
import ws from 'ws';

// Di lingkungan Node (bukan edge), driver butuh implementasi WebSocket
// untuk mode Pool. Di Vercel Edge / browser hal ini tidak diperlukan.
neonConfig.webSocketConstructor = ws;

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL belum diset. Salin backend/.env.example ke .env dan isi.');
}

/**
 * Pool koneksi Neon (pooled connection string disarankan untuk serverless,
 * PRD §9.4). Dipakai bersama transaksi pada tahap berikutnya.
 */
export const pool = new Pool({ connectionString: process.env.DATABASE_URL });

/**
 * Helper query berparameter (anti SQL injection, PRD §9.6).
 * @param {string} text
 * @param {unknown[]} [params]
 */
export function query(text, params) {
  return pool.query(text, params);
}

/** Cek koneksi database; mengembalikan true bila SELECT 1 berhasil. */
export async function cekKoneksi() {
  const res = await pool.query('SELECT 1 AS ok');
  return res.rows[0]?.ok === 1;
}
