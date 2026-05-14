import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../shared/models/place_model.dart';
import '../../../../shared/models/route_info_model.dart';
import '../../../../shared/models/travel_card_model.dart';
import '../../domain/travel_card_repository.dart';

const _uuid = Uuid();

class SupabaseTravelCardRepository implements TravelCardRepository {
  SupabaseClient get _db => Supabase.instance.client;

  @override
  Future<List<TravelCardModel>> getAllCards(String userId) async {
    final rows = await _db
        .from('travel_cards')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false);

    return rows.map((r) => _fromRow(r)).toList();
  }

  @override
  Future<TravelCardModel?> getCard(String id) async {
    final rows = await _db.from('travel_cards').select().eq('id', id);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  @override
  Future<TravelCardModel> createCard(
      String userId, String title, String description) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await _db.from('travel_cards').insert({
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'status': 'draft',
      'radius_meters': 10000,
      'selected_categories': jsonEncode([]),
      'discovered_places': jsonEncode([]),
      'routes': jsonEncode([]),
      'place_statuses': jsonEncode({}),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    return TravelCardModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> saveCard(TravelCardModel card) async {
    final now = DateTime.now().toUtc();
    await _db.from('travel_cards').upsert({
      'id': card.id,
      'user_id': card.userId,
      'title': card.title,
      'description': card.description,
      'origin_lat': card.originLat,
      'origin_lng': card.originLng,
      'origin_name': card.originName,
      'radius_meters': card.radiusMeters,
      'status': card.status.name,
      'selected_categories': jsonEncode(card.selectedCategories),
      'discovered_places':
          jsonEncode(card.discoveredPlaces.map((p) => p.toJson()).toList()),
      'routes':
          jsonEncode(card.routes.map((r) => r.toJson()).toList()),
      'place_statuses':
          jsonEncode(card.placeStatuses.map((k, v) => MapEntry(k, v.name))),
      'updated_at': now.toIso8601String(),
    });
  }

  @override
  Future<void> deleteCard(String id) async {
    await _db.from('travel_cards').delete().eq('id', id);
  }

  @override
  Future<void> updateDiscovery(
      String cardId, List<PlaceModel> places, List<RouteInfoModel> routes) async {
    final card = await getCard(cardId);
    if (card == null) return;
    final statuses = {
      for (final p in places) p.id: PlaceVisitStatus.pending,
      ...card.placeStatuses,
    };
    await saveCard(card.copyWith(
      discoveredPlaces: places,
      routes: routes,
      placeStatuses: statuses,
      status: TravelCardStatus.active,
    ));
  }

  @override
  Future<void> updatePlaceStatus(
      String cardId, String placeId, PlaceVisitStatus status) async {
    final card = await getCard(cardId);
    if (card == null) return;
    final statuses = Map<String, PlaceVisitStatus>.from(card.placeStatuses);
    statuses[placeId] = status;
    await saveCard(card.copyWith(placeStatuses: statuses));
  }

  @override
  Future<void> updateOrigin(String cardId, double lat, double lng,
      String name, int radius, List<String> cats) async {
    final card = await getCard(cardId);
    if (card == null) return;
    await saveCard(card.copyWith(
      originLat: lat,
      originLng: lng,
      originName: name,
      radiusMeters: radius,
      selectedCategories: cats,
    ));
  }

  // ─── Row parser ─────────────────────────────────────────────────────────────

  TravelCardModel _fromRow(Map<String, dynamic> r) {
    final statusMap =
        (jsonDecode(r['place_statuses'] as String? ?? '{}') as Map)
            .map((k, v) => MapEntry(
                  k as String,
                  PlaceVisitStatus.values.firstWhere(
                      (s) => s.name == v,
                      orElse: () => PlaceVisitStatus.pending),
                ));

    final places = (jsonDecode(r['discovered_places'] as String? ?? '[]')
            as List)
        .map((p) => PlaceModel.fromJson(p as Map<String, dynamic>))
        .toList();

    final routes = (jsonDecode(r['routes'] as String? ?? '[]') as List)
        .map((rt) => RouteInfoModel.fromJson(rt as Map<String, dynamic>))
        .toList();

    return TravelCardModel(
      id: r['id'] as String,
      userId: r['user_id'] as String,
      title: r['title'] as String,
      description: r['description'] as String? ?? '',
      originLat: (r['origin_lat'] as num?)?.toDouble(),
      originLng: (r['origin_lng'] as num?)?.toDouble(),
      originName: r['origin_name'] as String?,
      radiusMeters: r['radius_meters'] as int? ?? 10000,
      selectedCategories:
          (jsonDecode(r['selected_categories'] as String? ?? '[]') as List)
              .cast<String>(),
      status: TravelCardStatus.values.firstWhere(
          (s) => s.name == (r['status'] as String? ?? 'draft'),
          orElse: () => TravelCardStatus.draft),
      discoveredPlaces: places,
      routes: routes,
      placeStatuses: statusMap,
      createdAt: DateTime.parse(r['created_at'] as String),
      updatedAt: DateTime.parse(r['updated_at'] as String),
    );
  }
}
