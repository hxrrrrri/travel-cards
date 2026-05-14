class Env {
  // ─── App mode ────────────────────────────────────────────────────────────
  // true  → use seeded demo data, no API keys required
  // false → use real Overpass (places) + OSRM (routes); optional Supabase
  static bool demoMode = true;

  // ─── Demo anchor (Madikeri, Coorg, India) ────────────────────────────────
  static double demoLat = 12.3375;
  static double demoLng = 75.8069;
  static String demoLocationName = 'Madikeri, Coorg';

  // ─── Free APIs (no key needed — work in non-demo mode) ───────────────────
  // OpenStreetMap Overpass — real place data, zero cost
  static const String overpassUrl = 'https://overpass-api.de/api/interpreter';

  // OSRM public demo — real road routes, zero cost, dev use only
  // Self-host for production: https://github.com/Project-OSRM/osrm-backend
  static const String osrmBaseUrl =
      'http://router.project-osrm.org/route/v1/driving';
  static const String osrmTableUrl =
      'http://router.project-osrm.org/table/v1/driving';

  // ─── Optional paid APIs (activate by setting keys) ───────────────────────
  // OpenRouteService — better routing, 2000 req/day free
  // Get key: https://openrouteservice.org/
  static String orsApiKey = '';
  static const String orsBaseUrl =
      'https://api.openrouteservice.org/v2/directions/driving-car';

  // Google Places API (for rich place data: photos, reviews, ratings)
  // Get key: https://console.cloud.google.com/
  static String googlePlacesKey = '';

  // ─── Supabase (optional cloud backend) ───────────────────────────────────
  // When empty → app uses Hive local storage only
  // Get from: https://supabase.com → Project Settings → API
  static String supabaseUrl = '';
  static String supabaseAnonKey = '';

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get hasOrs => orsApiKey.isNotEmpty;

  static Future<void> load() async {
    // Production: load from flutter_dotenv or similar
    // Example: demoMode = dotenv.env['DEMO_MODE'] == 'false';
    //          supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    //          supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    //          orsApiKey = dotenv.env['ORS_API_KEY'] ?? '';
  }
}
