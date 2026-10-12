import 'dotenv/config';
import app from './app.js';

const PORT = process.env.PORT || 4000;

app.listen(PORT, () => {
  console.log(`SiAbsen backend berjalan di http://localhost:${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
});
