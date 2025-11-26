import express from 'express';
import multer from 'multer';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { authRequired } from '../middleware/auth.js';
import { query } from '../db.js';
import { UPLOAD_DIR } from '../config.js';
import { getActiveStonesWithLatest, getStoneWithLatestLocation } from '../utils/stoneQueries.js';

const router = express.Router();

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, UPLOAD_DIR),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${uuidv4()}${ext}`);
  },
});

const upload = multer({ storage });

router.get('/by-token/:qrToken', async (req, res) => {
  const { qrToken } = req.params;
  const stoneRes = await query('SELECT * FROM stones WHERE qr_token=$1', [qrToken]);
  if (stoneRes.rowCount === 0) {
    return res.status(404).json({ message: 'Not found' });
  }
  const stone = stoneRes.rows[0];
  if (!stone.is_active) {
    return res.json({ is_active: false });
  }
  const detailed = await getStoneWithLatestLocation(stone.id);
  return res.json(detailed);
});

router.post('/activate', authRequired, async (req, res) => {
  const { qrToken, name, description } = req.body;
  if (!qrToken || !name || !description) {
    return res.status(400).json({ message: 'Missing fields' });
  }
  const stoneRes = await query('SELECT * FROM stones WHERE qr_token=$1', [qrToken]);
  if (stoneRes.rowCount === 0) {
    return res.status(404).json({ message: 'Stone not found' });
  }
  const stone = stoneRes.rows[0];
  if (stone.is_active) {
    return res.status(400).json({ message: 'Stone already active' });
  }
  await query(
    'UPDATE stones SET name=$1, description=$2, creator_user_id=$3, is_active=true WHERE id=$4',
    [name, description, req.user.userId, stone.id]
  );
  const updated = await getStoneWithLatestLocation(stone.id);
  return res.json(updated);
});

router.post('/:stoneId/locations', authRequired, upload.single('photo'), async (req, res) => {
  const { stoneId } = req.params;
  const { latitude, longitude, note } = req.body;
  if (!latitude || !longitude) {
    return res.status(400).json({ message: 'Missing coordinates' });
  }
  const photoUrl = req.file ? `/uploads/${req.file.filename}` : null;
  const id = uuidv4();
  const insertRes = await query(
    `INSERT INTO stone_locations (id, stone_id, user_id, latitude, longitude, note, photo_url, created_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, NOW()) RETURNING *`,
    [id, stoneId, req.user.userId, latitude, longitude, note || null, photoUrl]
  );
  return res.json(insertRes.rows[0]);
});

router.get('/:stoneId/locations', async (req, res) => {
  const { stoneId } = req.params;
  const locations = await query(
    `SELECT sl.*, u.nickname as user_nickname
     FROM stone_locations sl
     LEFT JOIN users u ON sl.user_id = u.id
     WHERE stone_id = $1
     ORDER BY created_at DESC`,
    [stoneId]
  );
  return res.json(locations.rows);
});

router.get('/', async (req, res) => {
  const { nearLat, nearLng, radiusKm } = req.query;
  const stones = await getActiveStonesWithLatest();
  if (nearLat && nearLng && radiusKm) {
    const lat = parseFloat(nearLat);
    const lng = parseFloat(nearLng);
    const radius = parseFloat(radiusKm);
    const filtered = stones.filter((s) => {
      if (!s.latitude || !s.longitude) return false;
      const R = 6371;
      const dLat = ((s.latitude - lat) * Math.PI) / 180;
      const dLng = ((s.longitude - lng) * Math.PI) / 180;
      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos((lat * Math.PI) / 180) *
          Math.cos((s.latitude * Math.PI) / 180) *
          Math.sin(dLng / 2) * Math.sin(dLng / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      const dist = R * c;
      return dist <= radius;
    });
    return res.json(filtered);
  }
  return res.json(stones);
});

router.get('/:stoneId', async (req, res) => {
  const detailed = await getStoneWithLatestLocation(req.params.stoneId);
  if (!detailed) return res.status(404).json({ message: 'Not found' });
  return res.json(detailed);
});

export default router;
