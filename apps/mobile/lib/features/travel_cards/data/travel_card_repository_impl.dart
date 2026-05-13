import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/place_model.dart';
import '../../../shared/models/route_info_model.dart';
import '../../../shared/models/travel_card_model.dart';
import '../domain/travel_card_repository.dart';

class TravelCardRepositoryImpl implements TravelCardRepository {
  static const _uuid = Uuid();

  Box<dynamic> get _box => Hive.box(AppConstants.hiveBoxTravelCards);

  @override
  Future<List<TravelCardModel>> getAllCards(String userId) async {
    final cards = <TravelCardModel>[];
    for (final key in _box.keys) {
      final raw = _box.get(key) as String?;
      if (raw == null) continue;
      try {
        final card = TravelCardModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (card.userId == userId) cards.add(card);
      } catch (_) {}
    }
    cards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return cards;
  }

  @override
  Future<TravelCardModel?> getCard(String id) async {
    final raw = _box.get(id) as String?;
    if (raw == null) return null;
    return TravelCardModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<TravelCardModel> createCard(
      String userId, String title, String description) async {
    final now = DateTime.now();
    final card = TravelCardModel(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      description: description,
      createdAt: now,
      updatedAt: now,
    );
    await _box.put(card.id, jsonEncode(card.toJson()));
    return card;
  }

  @override
  Future<void> saveCard(TravelCardModel card) async {
    await _box.put(card.id, jsonEncode(card.toJson()));
  }

  @override
  Future<void> deleteCard(String id) async {
    await _box.delete(id);
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
  Future<void> updateOrigin(String cardId, double lat, double lng, String name,
      int radius, List<String> cats) async {
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
}
