import pkg from 'pg';
import { DATABASE_URL } from './config.js';

const { Pool } = pkg;

export const pool = new Pool({ connectionString: DATABASE_URL });

export async function query(text, params) {
  const res = await pool.query(text, params);
  return res;
}
