import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../../shared/models/place_model.dart';
import '../../../../shared/models/route_info_model.dart';

const _uuid = Uuid();
final _rng = Random(42);

class DemoRouteProvider {
  Future<List<RouteInfoModel>> getRoutes({
    required String travelCardId,
    required double originLat,
    required double originLng,
    required List<PlaceModel> places,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return places.map((p) => _buildRoute(travelCardId, originLat, originLng, p)).toList();
  }

  RouteInfoModel _buildRoute(
      String cardId, double oLat, double oLng, PlaceModel dest) {
    final points = _generateCurvedPath(oLat, oLng, dest.lat, dest.lng);
    final distM = _pathLength(points);
    final speedMs = 30.0 / 3.6; // 30 km/h average
    return RouteInfoModel(
      id: _uuid.v4(),
      travelCardId: cardId,
      destinationPlaceId: dest.id,
      distanceMeters: distM.round(),
      durationSeconds: (distM / speedMs).round(),
      polylinePoints: points,
    );
  }

  List<LatLng> _generateCurvedPath(
      double lat1, double lng1, double lat2, double lng2) {
    final points = <LatLng>[LatLng(lat1, lng1)];
    const steps = 8;
    for (int i = 1; i < steps; i++) {
      final t = i / steps;
      final midLat = lat1 + (lat2 - lat1) * t;
      final midLng = lng1 + (lng2 - lng1) * t;
      // Add slight perpendicular jitter to simulate road curves
      final jitter = (_rng.nextDouble() - 0.5) * 0.004;
      final perpLat = midLat + jitter * (lng2 - lng1);
      final perpLng = midLng - jitter * (lat2 - lat1);
      points.add(LatLng(perpLat, perpLng));
    }
    points.add(LatLng(lat2, lng2));
    return points;
  }

  double _pathLength(List<LatLng> pts) {
    double total = 0;
    for (int i = 1; i < pts.length; i++) {
      total += _haversine(pts[i - 1].latitude, pts[i - 1].longitude,
          pts[i].latitude, pts[i].longitude);
    }
    return total;
  }

  double _haversine(double la1, double lo1, double la2, double lo2) {
    const r = 6371000.0;
    final dLat = (la2 - la1) * pi / 180;
    final dLon = (lo2 - lo1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(la1 * pi / 180) * cos(la2 * pi / 180) *
            sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
