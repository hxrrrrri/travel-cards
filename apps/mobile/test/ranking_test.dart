import 'package:flutter_test/flutter_test.dart';
import 'package:tripgraph/core/utils/ranking.dart';
import 'package:tripgraph/shared/models/place_model.dart';
import 'package:tripgraph/shared/models/travel_category.dart';

void main() {
  group('RankingEngine', () {
    final origin = (lat: 12.3375, lng: 75.8069);

    final places = [
      PlaceModel(
        id: 'p1', name: 'High Rated', categoryId: 'viewpoint',
        lat: origin.lat + 0.01, lng: origin.lng + 0.01,
        rating: 4.8, reviewCount: 3000, address: 'Test',
      ),
      PlaceModel(
        id: 'p2', name: 'Low Rated', categoryId: 'viewpoint',
        lat: origin.lat + 0.01, lng: origin.lng + 0.01,
        rating: 2.0, reviewCount: 10, address: 'Test',
      ),
      PlaceModel(
        id: 'p3', name: 'Far Away', categoryId: 'viewpoint',
        lat: origin.lat + 2.0, lng: origin.lng + 2.0, // outside 50km
        rating: 4.9, reviewCount: 5000, address: 'Test',
      ),
      PlaceModel(
        id: 'p4', name: 'Matching Category', categoryId: 'cafe',
        lat: origin.lat + 0.005, lng: origin.lng + 0.005,
        rating: 4.0, reviewCount: 200, address: 'Test',
      ),
    ];

    test('filters places outside radius', () {
      final engine = RankingEngine(
        originLat: origin.lat,
        originLng: origin.lng,
        radiusMeters: 50000,
        selectedCategories: [TravelCategory.viewpoint],
      );
      final result = engine.rank(places);
      expect(result.any((p) => p.id == 'p3'), isFalse);
    });

    test('ranks high-rated place above low-rated', () {
      final engine = RankingEngine(
        originLat: origin.lat,
        originLng: origin.lng,
        radiusMeters: 50000,
        selectedCategories: [TravelCategory.viewpoint],
      );
      final result = engine.rank(places.where((p) => p.id != 'p3').toList());
      final highIdx = result.indexWhere((p) => p.id == 'p1');
      final lowIdx = result.indexWhere((p) => p.id == 'p2');
      expect(highIdx, lessThan(lowIdx));
    });

    test('all results have distanceMeters set', () {
      final engine = RankingEngine(
        originLat: origin.lat,
        originLng: origin.lng,
        radiusMeters: 50000,
        selectedCategories: [TravelCategory.viewpoint],
      );
      final result = engine.rank(places);
      for (final p in result) {
        expect(p.distanceMeters, isNotNull);
        expect(p.distanceMeters!, greaterThan(0));
      }
    });

    test('score is between 0 and 1', () {
      final engine = RankingEngine(
        originLat: origin.lat,
        originLng: origin.lng,
        radiusMeters: 50000,
        selectedCategories: [TravelCategory.viewpoint],
      );
      final result = engine.rank(places);
      for (final p in result) {
        expect(p.rankScore, greaterThanOrEqualTo(0.0));
        expect(p.rankScore, lessThanOrEqualTo(1.0));
      }
    });
  });
}
