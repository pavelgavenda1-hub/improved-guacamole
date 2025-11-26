CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  nickname TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stones (
  id UUID PRIMARY KEY,
  qr_token TEXT UNIQUE NOT NULL,
  code TEXT,
  name TEXT,
  description TEXT,
  creator_user_id UUID REFERENCES users(id),
  is_active BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stone_locations (
  id UUID PRIMARY KEY,
  stone_id UUID REFERENCES stones(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  latitude FLOAT NOT NULL,
  longitude FLOAT NOT NULL,
  note TEXT,
  photo_url TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
