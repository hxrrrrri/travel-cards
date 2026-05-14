import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// ─── Turn-by-turn step ────────────────────────────────────────────────────────

class RouteStep {
  final String instruction;
  final double distanceMeters;
  final double durationSeconds;
  final LatLng location; // Maneuver point
  final String maneuverType; // depart | turn | new name | continue | fork | arrive
  final String? modifier; // left | right | straight | slight left | slight right | sharp left | sharp right | uturn
  final String? streetName;

  const RouteStep({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.location,
    required this.maneuverType,
    this.modifier,
    this.streetName,
  });

  IconData get icon {
    if (maneuverType == 'arrive') return Icons.location_on;
    if (maneuverType == 'depart') return Icons.navigation;
    if (modifier == null) return Icons.straight;
    if (modifier!.contains('sharp left') || modifier! == 'uturn')
      return Icons.u_turn_left;
    if (modifier!.contains('sharp right')) return Icons.u_turn_right;
    if (modifier!.contains('left')) return Icons.turn_left;
    if (modifier!.contains('right')) return Icons.turn_right;
    return Icons.straight;
  }

  String get distanceText {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  Map<String, dynamic> toJson() => {
        'instruction': instruction,
        'distanceMeters': distanceMeters,
        'durationSeconds': durationSeconds,
        'location': {'lat': location.latitude, 'lng': location.longitude},
        'maneuverType': maneuverType,
        'modifier': modifier,
        'streetName': streetName,
      };

  factory RouteStep.fromJson(Map<String, dynamic> j) => RouteStep(
        instruction: j['instruction'] as String,
        distanceMeters: (j['distanceMeters'] as num).toDouble(),
        durationSeconds: (j['durationSeconds'] as num).toDouble(),
        location: LatLng(
          (j['location']['lat'] as num).toDouble(),
          (j['location']['lng'] as num).toDouble(),
        ),
        maneuverType: j['maneuverType'] as String,
        modifier: j['modifier'] as String?,
        streetName: j['streetName'] as String?,
      );

  // Build human-readable instruction from OSRM raw step
  static RouteStep fromOsrm(Map<String, dynamic> step) {
    final maneuver = step['maneuver'] as Map<String, dynamic>;
    final type = maneuver['type'] as String? ?? 'continue';
    final mod = maneuver['modifier'] as String?;
    final name = (step['name'] as String?) ?? '';
    final dist = (step['distance'] as num?)?.toDouble() ?? 0;
    final dur = (step['duration'] as num?)?.toDouble() ?? 0;
    final loc = maneuver['location'] as List<dynamic>;

    final instruction = _buildInstruction(type, mod, name);

    return RouteStep(
      instruction: instruction,
      distanceMeters: dist,
      durationSeconds: dur,
      location: LatLng(
        (loc[1] as num).toDouble(),
        (loc[0] as num).toDouble(),
      ),
      maneuverType: type,
      modifier: mod,
      streetName: name.isEmpty ? null : name,
    );
  }

  static String _buildInstruction(String type, String? mod, String name) {
    final on = name.isNotEmpty ? ' on $name' : '';
    switch (type) {
      case 'depart':
        return 'Head ${_modText(mod)}$on';
      case 'arrive':
        return 'Arrive at your destination';
      case 'turn':
        return 'Turn ${_modText(mod)}$on';
      case 'continue':
        return 'Continue$on';
      case 'new name':
        return 'Continue$on';
      case 'merge':
        return 'Merge ${_modText(mod)}$on';
      case 'fork':
        return 'Keep ${_modText(mod)}$on';
      case 'end of road':
        return 'At end of road, turn ${_modText(mod)}$on';
      case 'roundabout':
      case 'rotary':
        return 'Enter roundabout$on';
      default:
        return 'Continue$on';
    }
  }

  static String _modText(String? mod) {
    if (mod == null) return 'straight';
    return switch (mod) {
      'left' => 'left',
      'right' => 'right',
      'straight' => 'straight',
      'slight left' => 'slight left',
      'slight right' => 'slight right',
      'sharp left' => 'sharp left',
      'sharp right' => 'sharp right',
      'uturn' => 'and make a U-turn',
      _ => mod,
    };
  }
}

// ─── Route model ─────────────────────────────────────────────────────────────

class RouteInfoModel {
  final String id;
  final String travelCardId;
  final String destinationPlaceId;
  final int distanceMeters;
  final int durationSeconds;
  final List<LatLng> polylinePoints;
  final List<RouteStep> steps;
  final String routeType; // 'primary' | 'alternative'
  final String provider;

  const RouteInfoModel({
    required this.id,
    required this.travelCardId,
    required this.destinationPlaceId,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polylinePoints,
    this.steps = const [],
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
        'steps': steps.map((s) => s.toJson()).toList(),
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
        steps: (j['steps'] as List<dynamic>?)
                ?.map((s) => RouteStep.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        routeType: j['routeType'] as String? ?? 'primary',
        provider: j['provider'] as String? ?? 'demo',
      );
}
