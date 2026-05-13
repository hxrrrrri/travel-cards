# TripGraph

**Travel Discovery Graph App** — Discover and navigate the best nearby places within a radius, ranked by rating, reviews, and route convenience. Built with Flutter.

![Dark map UI with route nodes and cyan polylines](docs/screenshots/placeholder.png)

---

## What It Does

TripGraph converts your current location + a travel radius + selected categories into a clean map of ranked places with real route polylines. Create trip cards, explore, mark places visited, and track your progress.

**Core flow:**
1. Sign in (or tap Demo Mode — no API key needed)
2. Create a trip card (e.g. "Coorg Weekend")
3. Select radius (1–50 km) and place categories
4. App discovers + ranks nearby places and draws routes
5. Tap any node → view details, navigate, mark visited
6. Dashboard tracks all trips + stats

---

## Quick Start

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | ≥ 3.19 |
| Dart | ≥ 3.3 |
| Android Studio / Xcode | Latest |

### 1. Clone and setup

```bash
git clone <repo-url>
cd travel-cards/apps/mobile
```

### 2. Create the Flutter shell (first time only)

```bash
# From apps/mobile directory
flutter create . --project-name tripgraph --org com.tripgraph
# Say 'y' to overwrite conflicts — our source files take precedence
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run in demo mode (no API keys needed)

```bash
flutter run
```

Tap **"Try Demo Mode"** on the auth screen. The app uses seeded places around Coorg, Karnataka, India with simulated routes.

---

## Project Structure

```
travel-cards/
├── apps/
│   └── mobile/                 # Flutter application
│       ├── lib/
│       │   ├── app/            # Router, theme, env config
│       │   ├── core/           # Constants, utils, shared widgets
│       │   ├── shared/models/  # Domain models (Place, TravelCard, Route…)
│       │   └── features/
│       │       ├── auth/       # Login / demo auth
│       │       ├── dashboard/  # Home screen + stats
│       │       ├── travel_cards/  # CRUD + progress tracking
│       │       ├── discovery/  # Radius + category setup + ranking
│       │       └── map/        # flutter_map + node markers + route lines
│       └── test/
│           └── ranking_test.dart
├── docs/
│   └── architecture.md
├── .env.example
└── README.md
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter 3.x |
| State Management | Riverpod 2.x |
| Navigation | GoRouter |
| Maps | flutter_map + OpenStreetMap (free, no key) |
| Location | Geolocator |
| Local Storage | Hive |
| Navigation Launch | url_launcher → Google Maps deep link |

---

## Demo Mode

Demo mode requires **zero API keys**. When enabled:

- Uses a fixed location (Madikeri, Coorg, India)
- Loads 15 seeded places across all categories
- Generates curved polyline routes to each place
- All features work: visit tracking, progress, navigation launch

Switch to real providers by setting API keys in `.env` (see `.env.example`).

---

## Map Tiles

Uses [CartoDB Dark Matter](https://carto.com/basemaps/) tiles — completely free, no key required, matches the dark premium UI aesthetic.

---

## Real API Integration

Set in `lib/app/env.dart` or via environment variables:

```dart
Env.demoMode = false;
Env.googleMapsKey = 'YOUR_KEY';
Env.mapboxToken = 'YOUR_TOKEN';
```

Provider adapters are in `features/discovery/data/providers/`. To add a real provider, implement the `DemoPlaceProvider` interface pattern and switch in `discovery_repository_impl.dart`.

---

## Running Tests

```bash
cd apps/mobile
flutter test
```

Tests cover:
- Bayesian ranking scores
- Radius filtering (places outside radius excluded)
- Score normalization (0–1 range)

---

## Building

### Android APK

```bash
cd apps/mobile
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### iOS (requires macOS + Xcode)

```bash
flutter build ios --release
```

---

## Ranking Algorithm

Places are scored using a weighted formula:

```
score =
  0.30 × bayesian_rating      (Bayesian smoothed rating)
  0.20 × review_count_score   (log-normalized)
  0.15 × category_match_score (selected categories = 1.0, others = 0.3)
  0.10 × distance_score       (closer = higher)
  0.10 × route_convenience    (same as distance in v1)
  0.05 × open_now_score
  0.05 × photo_score
  0.05 × novelty_score
```

Top-4 results per category are kept, then globally sorted, limited to 20 total.

---

## Architecture

```
Presentation  →  Controllers (Riverpod StateNotifier)
                     ↓
Domain        →  Repository interfaces + Use cases
                     ↓
Data          →  Implementations (Demo / Real providers)
                     ↓
Storage       →  Hive (local) / API (remote, future)
```

See [docs/architecture.md](docs/architecture.md) for full design.

---

## Roadmap (V2+)

- [ ] Real Google Places / Mapbox Search integration
- [ ] Real road-following routes (Google Routes API / OSRM)
- [ ] AI trip planner ("best half-day route")
- [ ] Offline map support
- [ ] Social trip sharing
- [ ] Budget-aware planning
- [ ] Web dashboard
- [ ] Self-hosted routing (Valhalla / OSRM)

---

## License

MIT
