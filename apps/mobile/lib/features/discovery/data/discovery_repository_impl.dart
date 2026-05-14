import '../../../app/env.dart';
import '../../../core/utils/ranking.dart';
import '../../../shared/models/discovery_models.dart';
import '../../../shared/models/place_model.dart';
import '../../../shared/models/route_info_model.dart';
import '../../../shared/models/travel_category.dart';
import '../domain/discovery_repository.dart';
import 'providers/demo_place_provider.dart';
import 'providers/demo_route_provider.dart';
import 'providers/osrm_route_provider.dart';
import 'providers/overpass_place_provider.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final _demoPlaces = DemoPlaceProvider();
  final _demoRoutes = DemoRouteProvider();
  final _realPlaces = OverpassPlaceProvider();
  final _realRoutes = OsrmRouteProvider();

  @override
  Future<DiscoveryResponse> discover(DiscoveryRequest req) async {
    // 1. Fetch places ─────────────────────────────────────────────────────────
    List<PlaceModel> rawPlaces;
    if (Env.demoMode) {
      rawPlaces = await _demoPlaces.searchNearby(req);
    } else {
      try {
        rawPlaces = await _realPlaces.searchNearby(req);
      } catch (e) {
        // Overpass failed, fall back to demo data
        rawPlaces = await _demoPlaces.searchNearby(req);
      }
    }

    // 2. Rank + filter ────────────────────────────────────────────────────────
    final engine = RankingEngine(
      originLat: req.originLat,
      originLng: req.originLng,
      radiusMeters: req.radiusMeters,
      selectedCategories:
          req.categories.map((id) => TravelCategory.fromId(id)).toList(),
    );
    final ranked = engine.rank(rawPlaces);

    // 3. Fetch real routes ────────────────────────────────────────────────────
    List<RouteInfoModel> routes;
    if (Env.demoMode) {
      routes = await _demoRoutes.getRoutes(
        travelCardId: req.travelCardId,
        originLat: req.originLat,
        originLng: req.originLng,
        places: ranked,
      );
    } else {
      try {
        routes = await _realRoutes.getRoutes(
          travelCardId: req.travelCardId,
          originLat: req.originLat,
          originLng: req.originLng,
          places: ranked,
          topN: 12,
        );
      } catch (e) {
        // OSRM failed, use demo routes
        routes = await _demoRoutes.getRoutes(
          travelCardId: req.travelCardId,
          originLat: req.originLat,
          originLng: req.originLng,
          places: ranked,
        );
      }
    }

    return DiscoveryResponse(
      travelCardId: req.travelCardId,
      originLat: req.originLat,
      originLng: req.originLng,
      places: ranked,
      routes: routes,
      totalFound: rawPlaces.length,
    );
  }
}
