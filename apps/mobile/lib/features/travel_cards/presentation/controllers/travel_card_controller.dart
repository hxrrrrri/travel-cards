import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/travel_card_model.dart';
import '../../../../shared/models/place_model.dart';
import '../../../../shared/models/route_info_model.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/travel_card_repository_impl.dart';
import '../../domain/travel_card_repository.dart';

class TravelCardState {
  final List<TravelCardModel> cards;
  final bool isLoading;
  final String? error;

  const TravelCardState({
    this.cards = const [],
    this.isLoading = false,
    this.error,
  });

  TravelCardState copyWith({
    List<TravelCardModel>? cards,
    bool? isLoading,
    String? error,
  }) =>
      TravelCardState(
        cards: cards ?? this.cards,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  int get totalDiscovered =>
      cards.fold(0, (sum, c) => sum + c.discoveredCount);
  int get totalVisited =>
      cards.fold(0, (sum, c) => sum + c.visitedCount);
  int get totalPending =>
      cards.fold(0, (sum, c) => sum + c.pendingCount);
}

class TravelCardController extends StateNotifier<TravelCardState> {
  final TravelCardRepository _repo;
  final String _userId;

  TravelCardController(this._repo, this._userId) : super(const TravelCardState()) {
    loadCards();
  }

  Future<void> loadCards() async {
    state = state.copyWith(isLoading: true);
    try {
      final cards = await _repo.getAllCards(_userId);
      state = state.copyWith(cards: cards, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<TravelCardModel?> createCard(String title, String description) async {
    try {
      final card = await _repo.createCard(_userId, title, description);
      await loadCards();
      return card;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<TravelCardModel?> getCard(String id) => _repo.getCard(id);

  Future<void> updateDiscovery(
      String cardId, List<PlaceModel> places, List<RouteInfoModel> routes) async {
    await _repo.updateDiscovery(cardId, places, routes);
    await loadCards();
  }

  Future<void> markVisited(String cardId, String placeId) async {
    await _repo.updatePlaceStatus(cardId, placeId, PlaceVisitStatus.visited);
    await loadCards();
  }

  Future<void> markSkipped(String cardId, String placeId) async {
    await _repo.updatePlaceStatus(cardId, placeId, PlaceVisitStatus.skipped);
    await loadCards();
  }

  Future<void> markPending(String cardId, String placeId) async {
    await _repo.updatePlaceStatus(cardId, placeId, PlaceVisitStatus.pending);
    await loadCards();
  }

  Future<void> updateOrigin(String cardId, double lat, double lng, String name,
      int radius, List<String> cats) async {
    await _repo.updateOrigin(cardId, lat, lng, name, radius, cats);
    await loadCards();
  }

  Future<void> deleteCard(String id) async {
    await _repo.deleteCard(id);
    await loadCards();
  }
}

final _travelCardRepoProvider =
    Provider<TravelCardRepository>((_) => TravelCardRepositoryImpl());

final travelCardControllerProvider =
    StateNotifierProvider<TravelCardController, TravelCardState>((ref) {
  final userId =
      ref.watch(authControllerProvider).userId ?? 'anonymous';
  return TravelCardController(ref.read(_travelCardRepoProvider), userId);
});
