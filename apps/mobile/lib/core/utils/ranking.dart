import 'dart:math';
import '../../shared/models/place_model.dart';
import '../../shared/models/travel_category.dart';
import '../constants/app_constants.dart';
import 'haversine.dart';

class RankingEngine {
  final double originLat;
  final double originLng;
  final int radiusMeters;
  final List<TravelCategory> selectedCategories;

  RankingEngine({
    required this.originLat,
    required this.originLng,
    required this.radiusMeters,
    required this.selectedCategories,
  });

  List<PlaceModel> rank(List<PlaceModel> places) {
    final inRadius = _filterByRadius(places);
    final withDistances = inRadius.map((p) {
      final dist = haversineDistance(originLat, originLng, p.lat, p.lng);
      return p.copyWith(distanceMeters: dist);
    }).toList();

    final globalAvgRating = _globalAverage(withDistances);
    final maxReviews = withDistances.isEmpty
        ? 1.0
        : withDistances.map((p) => p.reviewCount).reduce(max).toDouble();

    final scored = withDistances.map((p) {
      final score = _score(p, globalAvgRating, maxReviews);
      return p.copyWith(rankScore: score);
    }).toList();

    scored.sort((a, b) => b.rankScore.compareTo(a.rankScore));
    return _topKPerCategory(scored);
  }

  List<PlaceModel> _filterByRadius(List<PlaceModel> places) => places.where((p) {
        final dist = haversineDistance(originLat, originLng, p.lat, p.lng);
        return dist <= radiusMeters;
      }).toList();

  double _globalAverage(List<PlaceModel> places) {
    if (places.isEmpty) return AppConstants.globalAverageRating;
    return places.map((p) => p.rating).reduce((a, b) => a + b) / places.length;
  }

  double _score(PlaceModel p, double globalAvg, double maxReviews) {
    final v = p.reviewCount.toDouble();
    final m = AppConstants.minReviewThreshold.toDouble();
    final bayesian = (v / (v + m)) * p.rating + (m / (v + m)) * globalAvg;
    final bayesianScore = (bayesian / 5.0).clamp(0.0, 1.0);

    final reviewScore = maxReviews > 0 ? log(1 + v) / log(1 + maxReviews) : 0.0;

    final catIds = selectedCategories.map((c) => c.id).toSet();
    final categoryScore = catIds.contains(p.categoryId) ? 1.0 : 0.3;

    final maxDist = radiusMeters.toDouble();
    final dist = p.distanceMeters ?? maxDist;
    final distanceScore = 1.0 - (dist / maxDist).clamp(0.0, 1.0);

    final openScore = p.isOpenNow ? 1.0 : 0.2;
    final photoScore = p.photos.isNotEmpty ? 1.0 : 0.0;
    final noveltyScore = 0.5;

    return AppConstants.wBayesianRating * bayesianScore +
        AppConstants.wReviewCount * reviewScore +
        AppConstants.wCategoryMatch * categoryScore +
        AppConstants.wDistance * distanceScore +
        AppConstants.wRouteConvenience * distanceScore +
        AppConstants.wOpenNow * openScore +
        AppConstants.wPhoto * photoScore +
        AppConstants.wNovelty * noveltyScore;
  }

  List<PlaceModel> _topKPerCategory(List<PlaceModel> sorted) {
    const kPerCategory = 4;
    final counts = <String, int>{};
    final result = <PlaceModel>[];

    for (final p in sorted) {
      final count = counts[p.categoryId] ?? 0;
      if (count < kPerCategory) {
        result.add(p);
        counts[p.categoryId] = count + 1;
      }
      if (result.length >= AppConstants.maxDisplayedPlaces) break;
    }
    return result;
  }
}
