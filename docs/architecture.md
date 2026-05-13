# TripGraph Architecture

## Overview

TripGraph follows Clean Architecture with feature-based folder structure.

```
┌─────────────────────────────────────────┐
│              Presentation               │
│   Screens  ←→  Controllers (Riverpod)  │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│                Domain                   │
│   Repository Interfaces + Use Cases     │
└──────────────────┬──────────────────────┘
                   │
┌──────────────────▼──────────────────────┐
│                  Data                   │
│   Repository Impls + Provider Adapters  │
└──────────────────┬──────────────────────┘
                   │
         ┌─────────▼─────────┐
         │  Hive (local)      │
         │  HTTP API (future) │
         └────────────────────┘
```

## Data Flow: Discovery

```
User taps "Generate Map"
        │
        ▼
DiscoverySetupScreen
  → reads: lat/lng, radius, categories
  → calls: DiscoveryController.discover()
        │
        ▼
DiscoveryRepositoryImpl
  → DemoPlaceProvider.searchNearby()
    returns: List<PlaceModel> (15 seeded places)
  → RankingEngine.rank()
    applies: radius filter + bayesian score + top-K
    returns: List<PlaceModel> (ranked, ≤20)
  → DemoRouteProvider.getRoutes()
    generates: curved polyline per place
    returns: List<RouteInfoModel>
  → returns: DiscoveryResponse
        │
        ▼
TravelCardController.updateDiscovery()
  → persists to Hive via TravelCardRepositoryImpl
        │
        ▼
Router.go('/travel-cards/:id/map')
        │
        ▼
DiscoveryMapScreen
  → flutter_map with CartoDB Dark Matter tiles
  → MarkerLayer: OriginMarker + PlaceNodeMarkers
  → PolylineLayer: dotted routes (cyan/orange)
  → tap marker → PlaceDetailSheet (bottom sheet)
```

## Provider Adapter Pattern

```dart
// Add new provider by implementing this pattern:
class GooglePlaceProvider {
  Future<List<PlaceModel>> searchNearby(DiscoveryRequest req) async {
    // Call Google Places Nearby Search API
    // Normalize to PlaceModel
  }
}

// Switch in DiscoveryRepositoryImpl:
final _placeProvider = Env.placeProvider == 'google'
    ? GooglePlaceProvider()
    : DemoPlaceProvider();
```

## State Management

| Provider | Type | Purpose |
|----------|------|---------|
| `authControllerProvider` | StateNotifierProvider | Auth state + navigation guard |
| `travelCardControllerProvider` | StateNotifierProvider | All card CRUD + status updates |
| `discoveryControllerProvider` | StateNotifierProvider | Discovery request/response lifecycle |
| `routerProvider` | Provider | GoRouter instance with auth redirect |

## Local Storage (Hive)

Two boxes:
- `auth` — userId, email, displayName
- `travel_cards` — JSON-encoded TravelCardModel per key (card.id)

No code generation required. Models use manual toJson/fromJson.

## Map Rendering

`flutter_map` + CartoDB Dark Matter tiles (free, no key).

Custom layers:
- `RouteLayer` → `PolylineLayer` with dotted lines, color by status
- `MarkerLayer` → `PlaceNodeMarker` (circular emoji icons) + `OriginMarker` (pulsing)

## Future: Real Provider Integration

```
PLACE_PROVIDER=google  →  GooglePlaceProvider
ROUTING_PROVIDER=mapbox →  MapboxRouteProvider
MAP_PROVIDER=mapbox    →  MapboxTileLayer
```

Set in `.env` → loaded in `Env.load()` → injected in repository impls.
