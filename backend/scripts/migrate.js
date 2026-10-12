import 'dotenv/config';
import { readFileSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { Pool, neonConfig } from '@neondatabase/serverless';
import ws from 'ws';

neonConfig.webSocketConstructor = ws;

const __dirname = dirname(fileURLToPath(import.meta.url));
const migrationsDir = join(__dirname, '..', 'db', 'migrations');

// Gunakan koneksi direct untuk migrasi bila tersedia (PRD §9.4),
// jika tidak, fallback ke DATABASE_URL.
const connectionString =
  process.env.DATABASE_URL_DIRECT || process.env.DATABASE_URL;

if (!connectionString) {
  console.error('DATABASE_URL (atau DATABASE_URL_DIRECT) belum diset.');
  process.exit(1);
}

async function run() {
  const files = readdirSync(migrationsDir)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  if (files.length === 0) {
    console.log('Tidak ada file migrasi .sql ditemukan.');
    return;
  }

  const pool = new Pool({ connectionString });
  const client = await pool.connect();
  try {
    for (const file of files) {
      const sql = readFileSync(join(migrationsDir, file), 'utf8');
      console.log(`Menjalankan migrasi: ${file} ...`);
      await client.query(sql);
      console.log(`  selesai: ${file}`);
    }
    console.log('Semua migrasi berhasil dijalankan.');
  } finally {
    client.release();
    await pool.end();
  }
}

run().catch((err) => {
  console.error('Migrasi gagal:', err.message);
  process.exit(1);
});
