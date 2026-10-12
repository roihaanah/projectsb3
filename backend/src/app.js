import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

import healthRouter from './routes/health.js';

/**
 * Instance Express tanpa app.listen().
 * Dipisah dari index.js agar mudah diuji dan agar nanti dapat
 * diekspor sebagai Vercel Function (sesuai PRD §9.2).
 */
const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

// Semua endpoint API memakai prefix /api (PRD §8)
app.use('/api', healthRouter);

export default app;
