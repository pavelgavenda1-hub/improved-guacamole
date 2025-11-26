import express from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { query } from '../db.js';
import { JWT_SECRET } from '../config.js';

const router = express.Router();

router.post('/register', async (req, res) => {
  const { email, password, nickname } = req.body;
  if (!email || !password || !nickname) {
    return res.status(400).json({ message: 'Missing fields' });
  }
  const existing = await query('SELECT id FROM users WHERE email=$1', [email]);
  if (existing.rowCount > 0) {
    return res.status(400).json({ message: 'Email already registered' });
  }
  const passwordHash = await bcrypt.hash(password, 10);
  const id = uuidv4();
  await query(
    'INSERT INTO users (id, email, password_hash, nickname, created_at) VALUES ($1, $2, $3, $4, NOW())',
    [id, email, passwordHash, nickname]
  );
  const token = jwt.sign({ userId: id, email }, JWT_SECRET, { expiresIn: '7d' });
  return res.json({ jwt: token });
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ message: 'Missing fields' });
  }
  const userRes = await query('SELECT * FROM users WHERE email=$1', [email]);
  if (userRes.rowCount === 0) {
    return res.status(401).json({ message: 'Invalid credentials' });
  }
  const user = userRes.rows[0];
  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) {
    return res.status(401).json({ message: 'Invalid credentials' });
  }
  const token = jwt.sign({ userId: user.id, email }, JWT_SECRET, { expiresIn: '7d' });
  return res.json({ jwt: token });
});

export default router;
