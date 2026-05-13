class AppConstants {
  static const String appName = 'TripGraph';
  static const String hiveBoxTravelCards = 'travel_cards';
  static const String hiveBoxAuth = 'auth';

  // Demo map tiles (CartoDB Dark Matter — free, no API key)
  static const String darkMapTileUrl =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const List<String> mapSubdomains = ['a', 'b', 'c', 'd'];
  static const String mapAttribution =
      '© OpenStreetMap contributors © CARTO';

  // Discovery defaults
  static const int defaultRadiusMeters = 10000;
  static const int minRadiusMeters = 1000;
  static const int maxRadiusMeters = 50000;
  static const int maxDisplayedPlaces = 20;

  // Ranking weights
  static const double wBayesianRating = 0.30;
  static const double wReviewCount = 0.20;
  static const double wCategoryMatch = 0.15;
  static const double wDistance = 0.10;
  static const double wRouteConvenience = 0.10;
  static const double wOpenNow = 0.05;
  static const double wPhoto = 0.05;
  static const double wNovelty = 0.05;

  static const int minReviewThreshold = 50;
  static const double globalAverageRating = 4.0;

  // Route corridor radius for "places along route"
  static const double routeCorridorMeters = 400.0;

  // External navigation deep links
  static String googleMapsDirectionsUrl(double lat, double lng, String name) =>
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$name&travelmode=driving';

  static String appleMapsUrl(double lat, double lng) =>
      'maps://?daddr=$lat,$lng';
}
