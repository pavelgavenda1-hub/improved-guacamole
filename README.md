# GeoStone MVP

Full-stack MVP for tracking QR-coded stones with Flutter mobile app and Node.js/Express backend.

## Prerequisites
- Node.js 18+
- PostgreSQL 14+
- Flutter SDK (3.16+)

## Backend Setup
1. Copy `.env.example` to `.env` and fill values:
```
DATABASE_URL=postgres://user:pass@localhost:5432/geostone
JWT_SECRET=supersecret
PORT=4000
UPLOAD_DIR=backend/uploads
```
2. Install dependencies:
```
cd backend
npm install
```
3. Apply database schema:
```
psql "$DATABASE_URL" -f migrations/schema.sql
```
4. Seed sample stones:
```
npm run seed
```
5. Start API:
```
npm start
```
Uploads are served from `/uploads` relative to the backend root.

## Flutter App
1. Copy environment example:
```
cd mobile
cp .env.example .env
```
2. Ensure Flutter dependencies are fetched:
```
flutter pub get
```
3. Run the app (Android emulator uses `10.0.2.2` for host):
```
flutter run
```

## API Overview
- `POST /api/auth/register` → `{ jwt }`
- `POST /api/auth/login` → `{ jwt }`
- `GET /api/stones/by-token/:qrToken`
- `POST /api/stones/activate` (auth)
- `POST /api/stones/:stoneId/locations` (auth, multipart)
- `GET /api/stones/:stoneId/locations`
- `GET /api/stones` (optional nearLat, nearLng, radiusKm)
- `GET /api/stones/:stoneId`
- `GET /api/me` (auth)

## Notes
- Images are stored locally in `backend/uploads`.
- The Flutter app includes QR scanning, activation flow, map markers, stone details, and location updates with camera/GPS.
