import '../../../shared/models/travel_card_model.dart';
import '../../../shared/models/place_model.dart';
import '../../../shared/models/route_info_model.dart';

abstract class TravelCardRepository {
  Future<List<TravelCardModel>> getAllCards(String userId);
  Future<TravelCardModel?> getCard(String id);
  Future<TravelCardModel> createCard(String userId, String title, String description);
  Future<void> saveCard(TravelCardModel card);
  Future<void> deleteCard(String id);
  Future<void> updateDiscovery(
      String cardId, List<PlaceModel> places, List<RouteInfoModel> routes);
  Future<void> updatePlaceStatus(
      String cardId, String placeId, PlaceVisitStatus status);
  Future<void> updateOrigin(
      String cardId, double lat, double lng, String name, int radius, List<String> cats);
}
