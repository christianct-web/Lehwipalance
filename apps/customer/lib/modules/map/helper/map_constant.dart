import 'package:latlong2/latlong.dart';

class MapConstants {
  static const double defaultZoom = 13.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;
  static const LatLng defaultLocation = LatLng(10.654, -61.478);
  static const String defaultCountry = 'Trinidad and Tobago';
  static const String defaultCountryDisplay = 'Trinidad & Tobago';
  static const double defaultRadius = 50.0;
  static const double locationListDefaultHeight = 300;
  static const Duration markerAnimationDuration = Duration(milliseconds: 500);

  // Tile caching
  static const String mapCacheDirectory = 'mapTiles';
  static const int maxTileCacheAge = 30; // days

  // Clustering
  static const int clusterThreshold = 50;
  static const double clusterMaxRadius = 45.0;

  // Caching
  static const Duration geocodingCacheDuration = Duration(days: 7);

  // UI constants
  static const double locationListMinHeight = 0.15;
  static const double locationListMaxHeight = 0.7;

  // ==================== TILE LAYER CONFIGURATION ====================
  // Option 1: OpenStreetMap (may have rate limiting)
  static const String tileLayerUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Option 2: Use a faster CDN with better rate limits
  static const String tileLayerUrlCdn =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Option 3: Stadia Maps (requires API key but more reliable)
  // static const String tileLayerUrlStadia =
  //     'https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}{r}.png';

  // Option 4: CartoDB (light and fast)
  // static const String tileLayerUrlCarto =
  //     'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

  static const String userAgent = 'LehwiPalanceApp/1.0';
  static const String referer = 'https://lehwi-palance.com';

  // ==================== COUNTRY CENTROIDS ====================
  static const Map<String, LatLng> countryCentroids = {
    // United States
    'United States': LatLng(39.8283, -98.5795),
    // Caribbean / CARICOM Members
    'Antigua and Barbuda': LatLng(17.0608, -61.7964),
    'Bahamas': LatLng(25.0343, -77.3963),
    'Barbados': LatLng(13.1939, -59.5432),
    'Belize': LatLng(17.1899, -88.4976),
    'Dominica': LatLng(15.4150, -61.3710),
    'Grenada': LatLng(12.1165, -61.6790),
    'Guyana': LatLng(4.8604, -58.9302),
    'Haiti': LatLng(18.9712, -72.2852),
    'Jamaica': LatLng(18.1096, -77.2975),
    'Montserrat': LatLng(16.7425, -62.1874),
    'Saint Kitts and Nevis': LatLng(17.3578, -62.7830),
    'Saint Lucia': LatLng(13.9094, -60.9789),
    'Saint Vincent and the Grenadines': LatLng(12.9843, -61.2872),
    'Suriname': LatLng(3.9193, -56.0278),
    'Trinidad and Tobago': LatLng(10.6549, -61.5019),
    // Other Key Caribbean Territories
    'Cuba': LatLng(21.5218, -77.7812),
    'Dominican Republic': LatLng(18.7357, -70.1627),
    'Puerto Rico': LatLng(18.2208, -66.5901),
    // Central America
    'Guatemala': LatLng(15.7835, -90.2308),
    'Honduras': LatLng(15.2000, -86.2419),
    'El Salvador': LatLng(13.7942, -88.8965),
    'Nicaragua': LatLng(12.8654, -85.2072),
    'Costa Rica': LatLng(9.7489, -83.7534),
    'Panama': LatLng(8.5380, -80.7821),
  };
}
