import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../../app/env.dart';
import '../../../../../shared/models/discovery_models.dart';
import '../../../../../shared/models/place_model.dart';

const _uuid = Uuid();

// Maps TripGraph category IDs → Overpass tag filters
const _tagMap = {
  'cafe': [
    ['amenity', 'cafe'],
    ['amenity', 'coffee_shop'],
  ],
  'restaurant': [
    ['amenity', 'restaurant'],
    ['amenity', 'fast_food'],
    ['amenity', 'food_court'],
  ],
  'viewpoint': [
    ['tourism', 'viewpoint'],
    ['natural', 'peak'],
  ],
  'tourist_attraction': [
    ['tourism', 'attraction'],
    ['tourism', 'artwork'],
    ['historic', 'monument'],
  ],
  'park': [
    ['leisure', 'park'],
    ['leisure', 'garden'],
    ['landuse', 'recreation_ground'],
  ],
  'bio_park': [
    ['tourism', 'zoo'],
    ['tourism', 'aquarium'],
    ['leisure', 'nature_reserve'],
  ],
  'museum': [
    ['tourism', 'museum'],
    ['tourism', 'gallery'],
  ],
  'hotel': [
    ['tourism', 'hotel'],
    ['tourism', 'resort'],
    ['tourism', 'guest_house'],
    ['tourism', 'hostel'],
  ],
  'fuel_station': [
    ['amenity', 'fuel'],
  ],
  'shopping': [
    ['shop', 'mall'],
    ['shop', 'supermarket'],
    ['shop', 'department_store'],
    ['shop', 'marketplace'],
  ],
  'temple': [
    ['amenity', 'place_of_worship'],
    ['historic', 'temple'],
  ],
  'beach': [
    ['natural', 'beach'],
  ],
  'waterfall': [
    ['waterway', 'waterfall'],
    ['natural', 'waterfall'],
  ],
};

class OverpassPlaceProvider {
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  Future<List<PlaceModel>> searchNearby(DiscoveryRequest req) async {
    final tags = _buildTagFilters(req.categories);
    if (tags.isEmpty) return [];

    final query = _buildQuery(tags, req.originLat, req.originLng, req.radiusMeters);

    try {
      final response = await _dio.post(
        Env.overpassUrl,
        data: query,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          headers: {'Accept': 'application/json'},
        ),
      );

      final elements = (response.data['elements'] as List<dynamic>?) ?? [];
      return elements
          .where((e) => _hasName(e))
          .map((e) => _parseElement(e, req))
          .toList();
    } on DioException catch (e) {
      throw Exception('Overpass API error: ${e.message}');
    }
  }

  List<List<String>> _buildTagFilters(List<String> categories) {
    final result = <List<String>>[];
    for (final cat in categories) {
      result.addAll(_tagMap[cat] ?? []);
    }
    return result;
  }

  String _buildQuery(
      List<List<String>> tags, double lat, double lng, int radius) {
    // Convert radius (meters) to degrees (~111km per degree)
    final radiusDeg = radius / 111000;
    final south = lat - radiusDeg;
    final west = lng - radiusDeg;
    final north = lat + radiusDeg;
    final east = lng + radiusDeg;

    // Use bbox filter (more reliable than around)
    final bbox = '$south,$west,$north,$east';

    final queries = <String>[];
    for (final tag in tags.take(3)) {
      queries.add('node["${tag[0]}"="${tag[1]}"](bbox:$bbox);');
      queries.add('way["${tag[0]}"="${tag[1]}"](bbox:$bbox);');
    }

    return '[out:json][timeout:60];(${queries.join('')});out center tags;';
  }

  bool _hasName(dynamic e) =>
      (e['tags'] as Map<String, dynamic>?)?.containsKey('name') == true &&
      ((e['tags']['name'] as String?)?.isNotEmpty == true);

  PlaceModel _parseElement(dynamic e, DiscoveryRequest req) {
    final tags = Map<String, String>.from(e['tags'] as Map);
    final isWay = e['type'] == 'way';

    final lat = isWay
        ? (e['center']['lat'] as num).toDouble()
        : (e['lat'] as num).toDouble();
    final lng = isWay
        ? (e['center']['lon'] as num).toDouble()
        : (e['lon'] as num).toDouble();

    // Detect category from tags
    final categoryId = _detectCategory(tags, req.categories);

    // Build address
    final address = _buildAddress(tags, lat, lng);

    // Check open now via opening_hours (basic check)
    final isOpen = _checkOpenNow(tags);

    // OSM doesn't provide star ratings; use vote count heuristic
    final votes = int.tryParse(tags['vote:count'] ?? '') ?? 0;

    return PlaceModel(
      id: '${e['type']}-${e['id']}',
      name: tags['name'] ?? 'Unknown',
      categoryId: categoryId,
      lat: lat,
      lng: lng,
      rating: 4.0, // OSM has no star rating; real ratings require Google/Yelp
      reviewCount: votes > 0 ? votes : _syntheticReviewCount(tags),
      address: address,
      isOpenNow: isOpen,
      provider: 'overpass',
      providerId: '${e['type']}-${e['id']}',
      reviews: [],
    );
  }

  String _detectCategory(Map<String, String> tags, List<String> preferred) {
    for (final cat in preferred) {
      final filters = _tagMap[cat] ?? [];
      for (final filter in filters) {
        if (tags[filter[0]] == filter[1]) return cat;
      }
    }
    // Fallback: guess from any known tag
    if (tags.containsKey('amenity')) {
      final amenity = tags['amenity']!;
      if (amenity == 'cafe' || amenity == 'coffee_shop') return 'cafe';
      if (amenity == 'restaurant' || amenity == 'fast_food') return 'restaurant';
      if (amenity == 'fuel') return 'fuel_station';
      if (amenity == 'place_of_worship') return 'temple';
    }
    if (tags.containsKey('tourism')) {
      final tourism = tags['tourism']!;
      if (tourism == 'viewpoint') return 'viewpoint';
      if (tourism == 'museum' || tourism == 'gallery') return 'museum';
      if (tourism == 'hotel' || tourism == 'guest_house') return 'hotel';
      if (tourism == 'zoo') return 'bio_park';
    }
    if (tags['natural'] == 'beach') return 'beach';
    if (tags['waterway'] == 'waterfall' || tags['natural'] == 'waterfall') {
      return 'waterfall';
    }
    if (tags.containsKey('leisure')) return 'park';
    return 'tourist_attraction';
  }

  String _buildAddress(Map<String, String> tags, double lat, double lng) {
    final parts = <String>[];
    if (tags['addr:housenumber'] != null) {
      parts.add(tags['addr:housenumber']!);
    }
    if (tags['addr:street'] != null) parts.add(tags['addr:street']!);
    if (tags['addr:city'] != null) parts.add(tags['addr:city']!);
    if (tags['addr:state'] != null) parts.add(tags['addr:state']!);
    if (parts.isNotEmpty) return parts.join(', ');
    // Fallback to village/suburb
    if (tags['is_in'] != null) return tags['is_in']!;
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  bool _checkOpenNow(Map<String, String> tags) {
    final oh = tags['opening_hours'];
    if (oh == null) return true; // Assume open if not specified
    if (oh.toLowerCase() == '24/7') return true;
    // Simplified: just return true for now; full parsing is complex
    return true;
  }

  // Synthetic review count based on how much OSM data is filled in
  int _syntheticReviewCount(Map<String, String> tags) {
    int score = 50;
    if (tags.containsKey('website')) score += 80;
    if (tags.containsKey('phone')) score += 40;
    if (tags.containsKey('opening_hours')) score += 60;
    if (tags.containsKey('cuisine')) score += 30;
    if (tags.containsKey('description')) score += 40;
    return score;
  }
}
