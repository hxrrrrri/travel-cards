import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../../../app/theme.dart';
import '../../../../shared/models/route_info_model.dart';
import '../../../../shared/models/travel_card_model.dart';

class RouteLayer extends StatelessWidget {
  final List<RouteInfoModel> routes;
  final String? selectedPlaceId;
  final Map<String, PlaceVisitStatus> placeStatuses;

  const RouteLayer({
    super.key,
    required this.routes,
    this.selectedPlaceId,
    required this.placeStatuses,
  });

  @override
  Widget build(BuildContext context) {
    final polylines = routes.map((r) {
      final isSelected = r.destinationPlaceId == selectedPlaceId;
      final status =
          placeStatuses[r.destinationPlaceId] ?? PlaceVisitStatus.pending;
      final color = _routeColor(isSelected, status);
      final width = isSelected ? 4.0 : 2.5;
      final opacity = isSelected ? 1.0 : 0.5;

      return Polyline(
        points: r.polylinePoints,
        strokeWidth: width,
        color: color.withOpacity(opacity),
        isDotted: true,
      );
    }).toList();

    return PolylineLayer(polylines: polylines);
  }

  Color _routeColor(bool selected, PlaceVisitStatus status) {
    if (selected) return AppTheme.accentOrange;
    return switch (status) {
      PlaceVisitStatus.visited => AppTheme.success,
      PlaceVisitStatus.skipped => AppTheme.routeInactive,
      PlaceVisitStatus.pending => AppTheme.primaryCyan,
    };
  }
}
