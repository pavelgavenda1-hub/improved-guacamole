import { v4 as uuidv4 } from 'uuid';
import { query, pool } from '../src/db.js';
import '../src/config.js';

async function run() {
  const tokens = ['STONE-ALPHA', 'STONE-BETA', 'STONE-GAMMA'];
  for (const token of tokens) {
    const id = uuidv4();
    await query(
      `INSERT INTO stones (id, qr_token, code, is_active, created_at)
       VALUES ($1, $2, $3, false, NOW())
       ON CONFLICT (qr_token) DO NOTHING`,
      [id, token, token.slice(0, 4)]
    );
  }
  console.log('Seeded stones');
  await pool.end();
}

run().catch((err) => {
  console.error(err);
  pool.end();
});
