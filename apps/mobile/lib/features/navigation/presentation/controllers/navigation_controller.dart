import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../shared/models/place_model.dart';
import '../../../../shared/models/route_info_model.dart';
import '../../../../shared/models/travel_card_model.dart';
import '../../../travel_cards/presentation/controllers/travel_card_controller.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class NavigationState {
  final PlaceModel destination;
  final RouteInfoModel route;
  final LatLng? currentPosition;
  final double? currentHeading;       // degrees
  final int currentStepIndex;
  final double distanceToNextStep;    // meters
  final double totalRemainingDistance;// meters
  final int estimatedTimeSecs;
  final bool isArrived;
  final bool isOffRoute;
  final List<LatLng> remainingPolyline;
  final List<LatLng> completedPolyline;
  final bool isLoading;
  final String? error;

  const NavigationState({
    required this.destination,
    required this.route,
    this.currentPosition,
    this.currentHeading,
    this.currentStepIndex = 0,
    this.distanceToNextStep = 0,
    this.totalRemainingDistance = 0,
    this.estimatedTimeSecs = 0,
    this.isArrived = false,
    this.isOffRoute = false,
    this.remainingPolyline = const [],
    this.completedPolyline = const [],
    this.isLoading = true,
    this.error,
  });

  NavigationState copyWith({
    LatLng? currentPosition,
    double? currentHeading,
    int? currentStepIndex,
    double? distanceToNextStep,
    double? totalRemainingDistance,
    int? estimatedTimeSecs,
    bool? isArrived,
    bool? isOffRoute,
    List<LatLng>? remainingPolyline,
    List<LatLng>? completedPolyline,
    bool? isLoading,
    String? error,
  }) =>
      NavigationState(
        destination: destination,
        route: route,
        currentPosition: currentPosition ?? this.currentPosition,
        currentHeading: currentHeading ?? this.currentHeading,
        currentStepIndex: currentStepIndex ?? this.currentStepIndex,
        distanceToNextStep: distanceToNextStep ?? this.distanceToNextStep,
        totalRemainingDistance:
            totalRemainingDistance ?? this.totalRemainingDistance,
        estimatedTimeSecs: estimatedTimeSecs ?? this.estimatedTimeSecs,
        isArrived: isArrived ?? this.isArrived,
        isOffRoute: isOffRoute ?? this.isOffRoute,
        remainingPolyline: remainingPolyline ?? this.remainingPolyline,
        completedPolyline: completedPolyline ?? this.completedPolyline,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  RouteStep? get currentStep =>
      route.steps.isNotEmpty && currentStepIndex < route.steps.length
          ? route.steps[currentStepIndex]
          : null;

  RouteStep? get nextStep =>
      route.steps.isNotEmpty && currentStepIndex + 1 < route.steps.length
          ? route.steps[currentStepIndex + 1]
          : null;

  String get etaText {
    final m = estimatedTimeSecs ~/ 60;
    if (m < 60) return '$m min';
    final h = m ~/ 60;
    final rem = m % 60;
    return rem > 0 ? '${h}h ${rem}m' : '${h}h';
  }

  String get distanceText {
    if (totalRemainingDistance < 1000) {
      return '${totalRemainingDistance.round()} m';
    }
    return '${(totalRemainingDistance / 1000).toStringAsFixed(1)} km';
  }
}

// ─── Controller ───────────────────────────────────────────────────────────────

class NavigationController extends StateNotifier<NavigationState> {
  StreamSubscription<Position>? _posSub;
  static const _arrivalThresholdM = 25.0;
  static const _stepAdvanceThresholdM = 30.0;
  static const _offRouteThresholdM = 80.0;

  NavigationController(PlaceModel dest, RouteInfoModel route)
      : super(NavigationState(
          destination: dest,
          route: route,
          remainingPolyline: route.polylinePoints,
          totalRemainingDistance: route.distanceMeters.toDouble(),
          estimatedTimeSecs: route.durationSeconds,
          isLoading: true,
        ));

  Future<void> start() async {
    // Request permission if needed
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      state = state.copyWith(
          isLoading: false, error: 'Location permission denied');
      return;
    }

    // Get initial position immediately
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.navigation),
      );
      _processPosition(pos);
    } catch (_) {}

    // Stream updates
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.navigation,
        distanceFilter: 5, // update every 5 meters moved
      ),
    ).listen(_processPosition);

    state = state.copyWith(isLoading: false);
  }

  void _processPosition(Position pos) {
    if (!mounted) return;
    final current = LatLng(pos.latitude, pos.longitude);
    final polyline = state.route.polylinePoints;

    // ── Check arrival at destination ────────────────────────────────────────
    final dest = polyline.last;
    final distToDest = _haversine(current, dest);
    if (distToDest < _arrivalThresholdM) {
      state = state.copyWith(
        currentPosition: current,
        isArrived: true,
        remainingPolyline: [current, dest],
        totalRemainingDistance: distToDest,
        estimatedTimeSecs: 0,
      );
      stop();
      return;
    }

    // ── Find closest point on polyline ──────────────────────────────────────
    final (closestIdx, perpPoint) = _closestPointOnPolyline(current, polyline);

    // ── Off-route check ─────────────────────────────────────────────────────
    final distToRoute = _haversine(current, perpPoint);
    final isOffRoute = distToRoute > _offRouteThresholdM;

    // ── Advance step if needed ──────────────────────────────────────────────
    int stepIdx = state.currentStepIndex;
    final steps = state.route.steps;

    if (steps.isNotEmpty) {
      // Check if we've passed the current step's maneuver point
      while (stepIdx < steps.length - 1) {
        final nextStepDist = _haversine(current, steps[stepIdx + 1].location);
        if (nextStepDist < _stepAdvanceThresholdM) {
          stepIdx++;
        } else {
          break;
        }
      }
    }

    // ── Split polyline into completed + remaining ────────────────────────────
    final completed = [...polyline.sublist(0, closestIdx), perpPoint];
    final remaining = [perpPoint, ...polyline.sublist(closestIdx)];

    // ── Recalculate remaining distance ──────────────────────────────────────
    final remainingDist = _polylineLength(remaining);

    // ── Estimate time (assume 30 km/h average) ──────────────────────────────
    const speedMs = 30 / 3.6;
    final etaSecs = (remainingDist / speedMs).round();

    // ── Distance to next step maneuver ──────────────────────────────────────
    double distToNextStep = 0;
    if (steps.isNotEmpty && stepIdx < steps.length) {
      distToNextStep = _haversine(current, steps[stepIdx].location);
    }

    state = state.copyWith(
      currentPosition: current,
      currentHeading: pos.heading,
      currentStepIndex: stepIdx,
      distanceToNextStep: distToNextStep,
      totalRemainingDistance: remainingDist,
      estimatedTimeSecs: etaSecs,
      isOffRoute: isOffRoute,
      remainingPolyline: remaining,
      completedPolyline: completed,
    );
  }

  void stop() {
    _posSub?.cancel();
    _posSub = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  // ── Geometry helpers ────────────────────────────────────────────────────────

  static double _haversine(LatLng a, LatLng b) {
    const r = 6371000.0;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLon = (b.longitude - a.longitude) * pi / 180;
    final sinA = sin(dLat / 2);
    final sinB = sin(dLon / 2);
    final h = sinA * sinA +
        cos(a.latitude * pi / 180) *
            cos(b.latitude * pi / 180) *
            sinB * sinB;
    return r * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  static double _polylineLength(List<LatLng> pts) {
    double total = 0;
    for (int i = 1; i < pts.length; i++) {
      total += _haversine(pts[i - 1], pts[i]);
    }
    return total;
  }

  /// Returns index of the segment start and the projected point
  static (int, LatLng) _closestPointOnPolyline(
      LatLng p, List<LatLng> polyline) {
    if (polyline.length == 1) return (0, polyline[0]);

    int bestIdx = 0;
    LatLng bestPoint = polyline[0];
    double bestDist = double.infinity;

    for (int i = 0; i < polyline.length - 1; i++) {
      final proj =
          _projectPointOnSegment(p, polyline[i], polyline[i + 1]);
      final d = _haversine(p, proj);
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
        bestPoint = proj;
      }
    }
    return (bestIdx, bestPoint);
  }

  static LatLng _projectPointOnSegment(LatLng p, LatLng a, LatLng b) {
    final ax = a.longitude, ay = a.latitude;
    final bx = b.longitude, by = b.latitude;
    final px = p.longitude, py = p.latitude;

    final dx = bx - ax, dy = by - ay;
    if (dx == 0 && dy == 0) return a;

    final t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
    final tClamped = t.clamp(0.0, 1.0);

    return LatLng(ay + tClamped * dy, ax + tClamped * dx);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final navigationControllerProvider = StateNotifierProvider.family<
    NavigationController, NavigationState, (PlaceModel, RouteInfoModel)>(
  (ref, args) => NavigationController(args.$1, args.$2),
);
