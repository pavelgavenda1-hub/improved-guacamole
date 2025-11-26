import { query } from '../db.js';

export async function getStoneWithLatestLocation(stoneId) {
  const stoneRes = await query(
    `SELECT s.*, u.nickname as creator_nickname
     FROM stones s
     LEFT JOIN users u ON s.creator_user_id = u.id
     WHERE s.id = $1`,
    [stoneId]
  );
  if (stoneRes.rowCount === 0) return null;
  const stone = stoneRes.rows[0];
  const latestLocRes = await query(
    `SELECT sl.*, u.nickname as user_nickname
     FROM stone_locations sl
     LEFT JOIN users u ON sl.user_id = u.id
     WHERE sl.stone_id = $1
     ORDER BY sl.created_at DESC
     LIMIT 1`,
    [stoneId]
  );
  const historyRes = await query(
    `SELECT sl.*, u.nickname as user_nickname
     FROM stone_locations sl
     LEFT JOIN users u ON sl.user_id = u.id
     WHERE sl.stone_id = $1
     ORDER BY sl.created_at DESC
     LIMIT 5`,
    [stoneId]
  );
  return {
    ...stone,
    latest_location: latestLocRes.rows[0] || null,
    recent_locations: historyRes.rows,
  };
}

export async function getActiveStonesWithLatest() {
  const res = await query(
    `SELECT s.*, sl.latitude, sl.longitude, sl.photo_url, sl.created_at AS last_seen_at
     FROM stones s
     LEFT JOIN LATERAL (
       SELECT * FROM stone_locations WHERE stone_id = s.id ORDER BY created_at DESC LIMIT 1
     ) sl ON true
     WHERE s.is_active = true`
  );
  return res.rows;
}
