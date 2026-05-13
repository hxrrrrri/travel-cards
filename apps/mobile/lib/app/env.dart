class Env {
  static bool demoMode = true;
  static String placeProvider = 'demo';
  static String routingProvider = 'demo';
  static String mapboxToken = '';
  static String googleMapsKey = '';

  // Demo anchor — Madikeri, Coorg, Karnataka, India
  static double demoLat = 12.3375;
  static double demoLng = 75.8069;
  static String demoLocationName = 'Madikeri, Coorg';

  static Future<void> load() async {
    // In production: load from a .env file via flutter_dotenv
    // For now defaults apply — set DEMO_MODE=false to use real APIs
  }
}
