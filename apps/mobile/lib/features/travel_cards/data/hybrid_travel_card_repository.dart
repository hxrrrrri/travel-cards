import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../app/env.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/place_model.dart';
import '../../../shared/models/route_info_model.dart';
import '../../../shared/models/travel_card_model.dart';
import '../domain/travel_card_repository.dart';

const _uuid = Uuid();

/// Tries Supabase first, falls back to Hive. Works with HybridAuthRepository.
class HybridTravelCardRepository implements TravelCardRepository {
  Box<dynamic> get _hiveBox => Hive.box(AppConstants.hiveBoxTravelCards);
  SupabaseClient? get _supabaseClient =>
      Env.hasSupabase ? Supabase.instance.client : null;

  @override
  Future<List<TravelCardModel>> getAllCards(String userId) async {
    // Try Supabase first
    if (_supabaseClient != null && _supabaseClient!.auth.currentUser != null) {
      try {
        final rows = await _supabaseClient!
            .from('travel_cards')
            .select()
            .eq('user_id', userId)
            .order('updated_at', ascending: false);
        return rows.map((r) => _fromSupabaseRow(r)).toList();
      } catch (_) {
        // Fall through to Hive
      }
    }

    // Fallback: Hive
    final cards = <TravelCardModel>[];
    for (final key in _hiveBox.keys) {
      final raw = _hiveBox.get(key) as String?;
      if (raw == null) continue;
      try {
        final card =
            TravelCardModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (card.userId == userId) cards.add(card);
      } catch (_) {}
    }
    cards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return cards;
  }

  @override
  Future<TravelCardModel?> getCard(String id) async {
    // Try Supabase first
    if (_supabaseClient != null && _supabaseClient!.auth.currentUser != null) {
      try {
        final rows = await _supabaseClient!
            .from('travel_cards')
            .select()
            .eq('id', id);
        if (rows.isNotEmpty) return _fromSupabaseRow(rows.first);
      } catch (_) {
        // Fall through to Hive
      }
    }

    // Fallback: Hive
    final raw = _hiveBox.get(id) as String?;
    if (raw == null) return null;
    return TravelCardModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<TravelCardModel> createCard(
      String userId, String title, String description) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    final card = TravelCardModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
    );

    // Try Supabase first
    if (_supabaseClient != null && _supabaseClient!.auth.currentUser != null) {
      try {
        await _supabaseClient!.from('travel_cards').insert({
          'id': id,
          'user_id': userId,
          'title': title,
          'description': description,
          'status': 'draft',
          'radius_meters': 10000,
          'selected_categories': [],
          'discovered_places': [],
          'routes': [],
          'place_statuses': {},
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        });
        return card;
      } catch (_) {
        // Fall through to Hive
      }
    }

    // Fallback: Hive
    await _hiveBox.put(id, jsonEncode(card.toJson()));
    return card;
  }

  @override
  Future<void> saveCard(TravelCardModel card) async {
    // Try Supabase first
    if (_supabaseClient != null && _supabaseClient!.auth.currentUser != null) {
      try {
        final now = DateTime.now().toUtc();
        await _supabaseClient!.from('travel_cards').upsert({
          'id': card.id,
          'user_id': card.userId,
          'title': card.title,
          'description': card.description,
          'origin_lat': card.originLat,
          'origin_lng': card.originLng,
          'origin_name': card.originName,
          'radius_meters': card.radiusMeters,
          'status': card.status.name,
          'selected_categories': card.selectedCategories,
          'discovered_places':
              card.discoveredPlaces.map((p) => p.toJson()).toList(),
          'routes': card.routes.map((r) => r.toJson()).toList(),
          'place_statuses':
              card.placeStatuses.map((k, v) => MapEntry(k, v.name)),
          'updated_at': now.toIso8601String(),
        });
        return;
      } catch (_) {
        // Fall through to Hive
      }
    }

    // Fallback: Hive
    await _hiveBox.put(card.id, jsonEncode(card.toJson()));
  }

  @override
  Future<void> deleteCard(String id) async {
    // Try Supabase first
    if (_supabaseClient != null && _supabaseClient!.auth.currentUser != null) {
      try {
        await _supabaseClient!.from('travel_cards').delete().eq('id', id);
        return;
      } catch (_) {
        // Fall through to Hive
      }
    }

    // Fallback: Hive
    await _hiveBox.delete(id);
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
    final updated = card.copyWith(
      discoveredPlaces: places,
      routes: routes,
      placeStatuses: statuses,
      status: TravelCardStatus.active,
      updatedAt: DateTime.now(),
    );
    await saveCard(updated);
  }

  @override
  Future<void> updatePlaceStatus(
      String cardId, String placeId, PlaceVisitStatus status) async {
    final card = await getCard(cardId);
    if (card == null) return;
    final statuses = Map<String, PlaceVisitStatus>.from(card.placeStatuses);
    statuses[placeId] = status;
    await saveCard(card.copyWith(placeStatuses: statuses, updatedAt: DateTime.now()));
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
      updatedAt: DateTime.now(),
    ));
  }

  // ─── Supabase row parser ─────────────────────────────────────────────────────

  TravelCardModel _fromSupabaseRow(Map<String, dynamic> r) {
    List _parseList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value;
      if (value is String) return jsonDecode(value) as List;
      return [];
    }

    Map _parseMap(dynamic value) {
      if (value == null) return {};
      if (value is Map) return value;
      if (value is String) return jsonDecode(value) as Map;
      return {};
    }

    final statusMap = _parseMap(r['place_statuses']).map((k, v) => MapEntry(
          k as String,
          PlaceVisitStatus.values.firstWhere(
              (s) => s.name == v,
              orElse: () => PlaceVisitStatus.pending),
        ));

    final places = _parseList(r['discovered_places'])
        .map((p) => PlaceModel.fromJson(p as Map<String, dynamic>))
        .toList();

    final routes = _parseList(r['routes'])
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
      selectedCategories: _parseList(r['selected_categories']).cast<String>(),
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
