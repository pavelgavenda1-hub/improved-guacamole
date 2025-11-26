import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';

dotenv.config();

const requiredEnv = ['DATABASE_URL', 'JWT_SECRET'];
requiredEnv.forEach((key) => {
  if (!process.env[key]) {
    console.warn(`Warning: Missing env var ${key}`);
  }
});

export const PORT = process.env.PORT || 4000;
export const DATABASE_URL = process.env.DATABASE_URL || 'postgres://localhost:5432/geostone';
export const JWT_SECRET = process.env.JWT_SECRET || 'development-secret';
export const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(process.cwd(), 'backend/uploads');

if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}
