import 'dart:math';

double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
  return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double deg) => deg * pi / 180;

String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()}m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}

String formatDuration(int seconds) {
  final mins = seconds ~/ 60;
  if (mins < 60) return '$mins min';
  final h = mins ~/ 60;
  final m = mins % 60;
  return m > 0 ? '${h}h ${m}m' : '${h}h';
}
