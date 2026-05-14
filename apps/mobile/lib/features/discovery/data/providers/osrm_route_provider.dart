import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../../../app/env.dart';
import '../../../../../shared/models/place_model.dart';
import '../../../../../shared/models/route_info_model.dart';

const _uuid = Uuid();

/// Fetches real road-following routes via the OSRM routing engine.
/// Public demo server used for development. Self-host for production:
/// https://github.com/Project-OSRM/osrm-backend
class OsrmRouteProvider {
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// Get routes for multiple destinations using OSRM table API first
  /// (single request for all distances), then fetch full geometry for top N.
  Future<List<RouteInfoModel>> getRoutes({
    required String travelCardId,
    required double originLat,
    required double originLng,
    required List<PlaceModel> places,
    int topN = 12,
  }) async {
    if (places.isEmpty) return [];

    try {
      // Step 1: Get distances/durations for all places in one table request
      final enriched = await _tableRequest(originLat, originLng, places);

      // Take top N by distance (already filtered by radius in ranking engine)
      final sorted = enriched.take(topN).toList();

      // Step 2: Fetch full geometry with turn-by-turn for top N
      final routes = <RouteInfoModel>[];
      for (final p in sorted) {
        try {
          final route = await _routeRequest(travelCardId, originLat, originLng, p);
          if (route != null) routes.add(route);
          // Respect demo server — small delay between requests
          await Future.delayed(const Duration(milliseconds: 150));
        } catch (_) {
          // Skip this place if route fetch fails; non-fatal
        }
      }
      return routes;
    } catch (e) {
      throw Exception('OSRM route fetch failed: $e');
    }
  }

  /// OSRM Table API — returns distances + durations in one shot.
  /// Returns places sorted by road distance.
  Future<List<PlaceModel>> _tableRequest(
      double oLat, double oLng, List<PlaceModel> places) async {
    // Build coordinate string: origin first, then all destinations
    final coords = [
      '$oLng,$oLat',
      ...places.map((p) => '${p.lng},${p.lat}'),
    ].join(';');

    final url =
        '${Env.osrmTableUrl}/$coords?sources=0&annotations=distance,duration';

    try {
      final response = await _dio.get(url);
      final distances =
          (response.data['distances'][0] as List<dynamic>).cast<num>();
      final durations =
          (response.data['durations'][0] as List<dynamic>).cast<num>();

      // Index 0 is origin→origin = 0, so destinations start at index 1
      final enriched = <MapEntry<PlaceModel, double>>[];
      for (int i = 0; i < places.length; i++) {
        final roadDist = distances[i + 1].toDouble();
        if (roadDist < 0 || roadDist.isInfinite) continue; // unreachable
        enriched.add(MapEntry(
            places[i].copyWith(distanceMeters: roadDist), roadDist));
      }
      enriched.sort((a, b) => a.value.compareTo(b.value));
      return enriched.map((e) => e.key).toList();
    } catch (_) {
      // Table API failed — return places as-is sorted by straight-line dist
      return places;
    }
  }

  /// OSRM Route API — full geometry + turn-by-turn for one destination.
  Future<RouteInfoModel?> _routeRequest(
      String cardId, double oLat, double oLng, PlaceModel dest) async {
    final url =
        '${Env.osrmBaseUrl}/$oLng,$oLat;${dest.lng},${dest.lat}'
        '?overview=full&geometries=geojson&steps=true&annotations=false';

    final response = await _dio.get(url);

    final code = response.data['code'] as String?;
    if (code != 'Ok') return null;

    final routes = response.data['routes'] as List<dynamic>;
    if (routes.isEmpty) return null;

    final route = routes[0] as Map<String, dynamic>;
    final leg = (route['legs'] as List<dynamic>)[0] as Map<String, dynamic>;

    // Parse polyline from GeoJSON (coordinates are [lng, lat])
    final coords = (route['geometry']['coordinates'] as List<dynamic>)
        .map((c) => LatLng(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ))
        .toList();

    // Parse turn-by-turn steps
    final steps = (leg['steps'] as List<dynamic>)
        .map((s) => RouteStep.fromOsrm(s as Map<String, dynamic>))
        .toList();

    return RouteInfoModel(
      id: _uuid.v4(),
      travelCardId: cardId,
      destinationPlaceId: dest.id,
      distanceMeters: (leg['distance'] as num).round(),
      durationSeconds: (leg['duration'] as num).round(),
      polylinePoints: coords,
      steps: steps,
      provider: 'osrm',
    );
  }
}
