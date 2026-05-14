# TripGraph Supabase End-to-End Test Guide

## Current Status
✅ Supabase connection verified
✅ Travel cards table exists
✅ Schema ready
✅ Real data mode enabled (Overpass + OSRM)

## Test Flow

### 1. Launch App
```powershell
cd c:\project_github\travel-cards\apps\mobile
puro flutter clean
puro flutter run
```
Choose device (Windows / Android / iOS)

### 2. Auth Test (Supabase)

**Signup:**
- Tap "Don't have an account? Sign Up"
- Email: `test@tripgraph.app`
- Password: `TestPass123!`
- Name: `Test User`
- Tap "Create Account"
- ✓ Should redirect to Dashboard
- ✓ Supabase will create auth.users entry
- ✓ HybridAuthRepository syncs to Hive

**Login (if logout):**
- Email: `test@tripgraph.app`
- Password: `TestPass123!`
- ✓ Should authenticate against Supabase
- ✓ Fallback to Hive if Supabase fails

**Demo Login (fallback test):**
- Tap "Try Demo Mode"
- ✓ Uses demo@tripgraph.app / TripGraphDemo2024!
- ✓ Falls back to Hive if Supabase unavailable

### 3. Travel Card CRUD (Supabase)

**Create Card:**
- Dashboard → "+ Create Trip Card"
- Title: "Coorg Weekend"
- Description: "Exploring the Western Ghats"
- Tap "Create Trip Card"
- ✓ Card should appear in Dashboard list
- ✓ Data stored in Supabase travel_cards table
- ✓ user_id matches authenticated user
- ✓ Falls back to Hive if Supabase insert fails

**View Cards:**
- Dashboard shows all user's travel cards
- ✓ Data fetched from Supabase
- ✓ Sorted by updated_at descending
- RLS policy: only see own cards

**Update Card (Discovery):**
- Tap card → "Setup"
- Set origin: Madikeri, Coorg (12.3375, 75.8069)
- Set radius: 15km
- Select categories: Restaurants, Hotels, Attractions
- Tap "Find Places"
- ✓ Discovers places from Overpass API (real OSM data)
- ✓ Fetches routes from OSRM (real roads + turn-by-turn)
- ✓ Stores discovered_places, routes in Supabase as jsonb arrays
- ✓ Updates status to 'active'

**Mark Place Visited:**
- Map screen → tap place → "Mark Visited"
- ✓ Updates place_statuses in Supabase
- ✓ Status badge changes to ✓
- ✓ Falls back to Hive if Supabase update fails

**Delete Card:**
- Long press card → delete
- ✓ Removes from Supabase
- ✓ Removes from Hive fallback

### 4. Discovery (Real Data)

**Overpass API:**
- When discovering places, API queries: https://overpass-api.de/api/interpreter
- Categories: restaurants, hotels, attractions, museums, parks, cafes, etc.
- Free, no API key needed
- Returns real OSM data with tags, ratings, reviews
- ✓ Look for actual places in map view

**OSRM Routing:**
- When calculating routes, API calls: http://router.project-osrm.org/route/v1/driving
- Two-stage: Table API (all distances) → Route API (full geometry + steps)
- Returns: actual road distance, duration, polyline, turn-by-turn steps
- ✓ Routes follow actual roads (not straight lines)
- ✓ Turn-by-turn instructions with maneuver types

### 5. Live Navigation (GPS)

**Start Navigation:**
- Map screen → tap place → "Start Navigation"
- Navigates to `/navigate/:cardId/:placeId`
- ✓ Shows real-time position (requires device/emulator GPS)
- ✓ Displays turn-by-turn instructions
- ✓ Polyline shows completed (faded) + remaining (bright) route
- ✓ ETA calculated from remaining distance
- ✓ Off-route warning at 80m deviation
- ✓ Arrival detected at 25m

**Step Advancement:**
- As you move along the route, current step advances at 30m threshold
- Next step preview updates in real-time
- ✓ Distance to next step shown

### 6. Data Validation

**Supabase Tables:**
```sql
-- Check travel_cards table
SELECT id, user_id, title, status, discovered_places, routes, place_statuses, created_at 
FROM travel_cards 
WHERE user_id = '<authenticated-user-id>'
ORDER BY created_at DESC;
```

**Expected Structure:**
- `id`: UUID
- `user_id`: UUID (matches auth.users.id)
- `title`: text
- `description`: text
- `status`: 'draft' | 'active' | 'completed'
- `selected_categories`: jsonb array (["restaurant", "hotel", ...])
- `discovered_places`: jsonb array (PlaceModel.toJson() objects)
- `routes`: jsonb array (RouteInfoModel.toJson() objects)
- `place_statuses`: jsonb object ({placeId: "visited" | "skipped" | "pending"})
- `created_at`: timestamptz
- `updated_at`: timestamptz (auto-updated)

### 7. Fallback Testing

**Simulate Supabase Failure:**
- Comment out Supabase credentials in env.dart:
  ```dart
  static String supabaseUrl = ''; // Supabase disabled
  static String supabaseAnonKey = '';
  ```
- App should:
  - ✓ Fall back to HiveAuthRepository
  - ✓ Create/read cards from Hive
  - ✓ Still discover with Overpass + route with OSRM
  - ✓ All auth/card operations work without Supabase

**Re-enable Supabase:**
- Restore credentials in env.dart
- App should:
  - ✓ Authenticate against Supabase
  - ✓ Store cards in Supabase
  - ✓ Sync Hive as backup

## Success Criteria

✅ Auth (signup/login/logout) works with Supabase
✅ Travel cards CRUD works with Supabase
✅ Place discovery works with Overpass (real data)
✅ Route calculation works with OSRM (real roads + turn-by-turn)
✅ Live navigation works with GPS
✅ All data persists in Supabase
✅ Fallback to Hive if Supabase unavailable
✅ RLS policies enforce user isolation
✅ No 403 Forbidden errors
✅ No null reference exceptions

## Troubleshooting

**"403 Forbidden" on travel_cards:**
- Check: RLS policy `auth.uid() = user_id`
- Check: User is authenticated (not 'anonymous')
- Check: user_id in JWT matches row.user_id

**"UndefinedColumn" error:**
- Run Supabase schema: `docs/supabase_schema.sql` in SQL Editor
- Verify table structure matches

**Cards not syncing:**
- Check: Env.hasSupabase is true
- Check: Credentials are valid
- Check: Network request succeeds (test with curl above)
- Check: Hive fallback is working (cards still appear locally)

**Routes not showing turns:**
- Check: OSRM returned steps (demo server often has limits)
- Check: Route JSON includes steps array
- Check: RouteStep.fromOsrm() parsed correctly

**GPS not working:**
- Emulator: Set mock location in Android Studio emulator
- Device: Grant location permission
- Check: NavigationController.start() called
- Check: LocationSettings.accuracy = LocationAccuracy.navigation

## API Endpoints Summary

| Service | Endpoint | Key | Status |
|---------|----------|-----|--------|
| Supabase Auth | `https://byvwkpppvgrkydsopend.supabase.co/auth/v1` | anon key | ✓ Working |
| Supabase DB | `https://byvwkpppvgrkydsopend.supabase.co/rest/v1` | anon key | ✓ Working |
| Overpass | `https://overpass-api.de/api/interpreter` | none | ✓ Free |
| OSRM | `http://router.project-osrm.org/route/v1` | none | ✓ Free |
| OpenRouteService | `https://api.openrouteservice.org/v2` | optional | — Not configured |
| Google Places | `https://maps.googleapis.com/maps/api/place` | optional | — Not configured |
