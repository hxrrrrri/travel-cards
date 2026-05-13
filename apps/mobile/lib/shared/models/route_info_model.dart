import 'package:latlong2/latlong.dart';

class RouteInfoModel {
  final String id;
  final String travelCardId;
  final String destinationPlaceId;
  final int distanceMeters;
  final int durationSeconds;
  final List<LatLng> polylinePoints;
  final String routeType; // 'primary' | 'alternative'
  final String provider;

  const RouteInfoModel({
    required this.id,
    required this.travelCardId,
    required this.destinationPlaceId,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polylinePoints,
    this.routeType = 'primary',
    this.provider = 'demo',
  });

  String get distanceText {
    if (distanceMeters < 1000) return '${distanceMeters}m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get durationText {
    final m = durationSeconds ~/ 60;
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? '${h}h ${rem}m' : '${h}h';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'travelCardId': travelCardId,
        'destinationPlaceId': destinationPlaceId,
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'polylinePoints': polylinePoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
        'routeType': routeType,
        'provider': provider,
      };

  factory RouteInfoModel.fromJson(Map<String, dynamic> j) => RouteInfoModel(
        id: j['id'] as String,
        travelCardId: j['travelCardId'] as String,
        destinationPlaceId: j['destinationPlaceId'] as String,
        distanceMeters: j['distanceMeters'] as int,
        durationSeconds: j['durationSeconds'] as int,
        polylinePoints: (j['polylinePoints'] as List<dynamic>)
            .map((p) => LatLng(
                (p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
            .toList(),
        routeType: j['routeType'] as String? ?? 'primary',
        provider: j['provider'] as String? ?? 'demo',
      );
}
