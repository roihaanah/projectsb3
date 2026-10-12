import { Router } from 'express';
import { cekKoneksi } from '../db/index.js';

const router = Router();

/**
 * GET /api/health
 * Mengembalikan status 'OK' bila backend hidup dan koneksi database sehat.
 * Bila database gagal, status 'ERROR' dengan HTTP 503 agar mudah dipantau.
 */
router.get('/health', async (req, res) => {
  let database = 'down';
  try {
    database = (await cekKoneksi()) ? 'up' : 'down';
  } catch {
    database = 'down';
  }

  const sehat = database === 'up';
  res.status(sehat ? 200 : 503).json({
    status: sehat ? 'OK' : 'ERROR',
    service: 'SiAbsen backend',
    database,
    timestamp: new Date().toISOString(),
  });
});

export default router;
