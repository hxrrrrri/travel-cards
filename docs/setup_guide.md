# TripGraph — Full Setup Guide

## Quick start (demo mode — zero API keys)

```bash
cd apps/mobile
flutter pub get
flutter run
```

Tap **Try Demo Mode**. Works offline with seeded Coorg data.

---

## Enable real places + routes (free, no signup)

Set in `lib/app/env.dart`:

```dart
static bool demoMode = false;
```

This activates:
- **Overpass API** — real OSM places, completely free
- **OSRM public server** — real road-following routes, free for dev

No API keys needed. Expect 2–4 seconds for discovery (network requests).

---

## Supabase — cloud auth + sync (optional)

### 1. Create project

Sign up at [supabase.com](https://supabase.com), create a project.

### 2. Run schema

In your Supabase project → SQL Editor → paste contents of `docs/supabase_schema.sql` → Run.

### 3. Get credentials

Project Settings → API:
- **Project URL** → copy
- **anon public** key → copy

### 4. Set in env

```dart
// lib/app/env.dart
static String supabaseUrl = 'https://xxxxxxxxxxxx.supabase.co';
static String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

When set, the app:
- Uses Supabase Auth for login/signup
- Syncs travel cards to PostgreSQL
- Falls back to Hive if Supabase unavailable

---

## OpenRouteService — better routing (optional)

Free tier: 2000 requests/day, more accurate than OSRM public server.

### 1. Get key

Sign up at [openrouteservice.org](https://openrouteservice.org) → Dashboard → Tokens.

### 2. Set in env

```dart
static String orsApiKey = 'your_ors_key_here';
```

The app auto-switches to ORS when the key is present.

---

## Google Places API — rich place data (optional)

Adds: real ratings, photo URLs, opening hours, reviews.

### 1. Get key

[console.cloud.google.com](https://console.cloud.google.com) → Enable Places API → Create credentials.

### 2. Set in env

```dart
static String googlePlacesKey = 'AIza...';
```

### 3. Enable in discovery

In `lib/features/discovery/data/discovery_repository_impl.dart`:

```dart
// Replace OverpassPlaceProvider() with GooglePlaceProvider()
```

---

## Production OSRM (self-hosted)

For production, replace the public OSRM demo server with your own:

```bash
# Docker quick-start (example for India region)
wget https://download.geofabrik.de/asia/india-latest.osm.pbf
docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend \
  osrm-extract -p /opt/car.lua /data/india-latest.osm.pbf
docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend \
  osrm-partition /data/india-latest.osrm
docker run -t -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend \
  osrm-customize /data/india-latest.osrm
docker run -d -p 5000:5000 -v "${PWD}:/data" ghcr.io/project-osrm/osrm-backend \
  osrm-routed --algorithm mld /data/india-latest.osrm
```

Then update `env.dart`:

```dart
static const String osrmBaseUrl = 'http://your-server:5000/route/v1/driving';
static const String osrmTableUrl = 'http://your-server:5000/table/v1/driving';
```

---

## Feature matrix

| Feature | Demo | Real (free) | With API key |
|---------|------|-------------|--------------|
| Place data | Seeded (15 places) | OSM Overpass (unlimited) | Google Places (rich data) |
| Routes | Simulated curves | OSRM real roads + turns | ORS (more accurate) |
| Turn-by-turn | — | ✓ (OSRM steps) | ✓ |
| Auth | Local Hive | Local Hive | Supabase Auth |
| Sync | Local only | Local only | Supabase cloud |
| Offline | ✓ | Cached | Cached |

---

## Build for Android

```bash
cd apps/mobile
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```
