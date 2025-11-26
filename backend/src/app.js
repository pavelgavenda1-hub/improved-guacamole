import express from 'express';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';
import authRoutes from './routes/auth.js';
import stoneRoutes from './routes/stones.js';
import { PORT, UPLOAD_DIR } from './config.js';
import { authRequired } from './middleware/auth.js';
import { query } from './db.js';

const app = express();
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(UPLOAD_DIR));

app.use('/api/auth', authRoutes);
app.use('/api/stones', stoneRoutes);

app.get('/api/me', authRequired, async (req, res) => {
  const userRes = await query('SELECT id, email, nickname, created_at FROM users WHERE id=$1', [req.user.userId]);
  const user = userRes.rows[0];
  const createdCount = await query('SELECT COUNT(*) FROM stones WHERE creator_user_id=$1', [req.user.userId]);
  const movedCount = await query('SELECT COUNT(DISTINCT stone_id) FROM stone_locations WHERE user_id=$1', [req.user.userId]);
  return res.json({
    ...user,
    stones_created: parseInt(createdCount.rows[0].count, 10),
    stones_moved: parseInt(movedCount.rows[0].count, 10),
  });
});

app.get('/', (req, res) => res.json({ status: 'GeoStone API running' }));

app.listen(PORT, () => {
  console.log(`GeoStone backend listening on port ${PORT}`);
});
