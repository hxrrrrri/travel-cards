import '../../../app/env.dart';
import '../../../core/utils/ranking.dart';
import '../../../shared/models/discovery_models.dart';
import '../../../shared/models/travel_category.dart';
import '../domain/discovery_repository.dart';
import 'providers/demo_place_provider.dart';
import 'providers/demo_route_provider.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final _placeProvider = DemoPlaceProvider();
  final _routeProvider = DemoRouteProvider();

  @override
  Future<DiscoveryResponse> discover(DiscoveryRequest req) async {
    final rawPlaces = await _placeProvider.searchNearby(req);

    final engine = RankingEngine(
      originLat: req.originLat,
      originLng: req.originLng,
      radiusMeters: req.radiusMeters,
      selectedCategories: req.categories
          .map((id) => TravelCategory.fromId(id))
          .toList(),
    );

    final ranked = engine.rank(rawPlaces);

    final routes = await _routeProvider.getRoutes(
      travelCardId: req.travelCardId,
      originLat: req.originLat,
      originLng: req.originLng,
      places: ranked,
    );

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
