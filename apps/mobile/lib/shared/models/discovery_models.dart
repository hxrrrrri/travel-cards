import 'place_model.dart';
import 'route_info_model.dart';

class DiscoveryRequest {
  final double originLat;
  final double originLng;
  final int radiusMeters;
  final List<String> categories;
  final String travelCardId;

  const DiscoveryRequest({
    required this.originLat,
    required this.originLng,
    required this.radiusMeters,
    required this.categories,
    required this.travelCardId,
  });
}

class DiscoveryResponse {
  final String travelCardId;
  final double originLat;
  final double originLng;
  final List<PlaceModel> places;
  final List<RouteInfoModel> routes;
  final int totalFound;

  const DiscoveryResponse({
    required this.travelCardId,
    required this.originLat,
    required this.originLng,
    required this.places,
    required this.routes,
    required this.totalFound,
  });
}
