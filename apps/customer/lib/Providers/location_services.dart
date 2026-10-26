import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehwipalancecustomerv1/api_keys.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';
import 'package:lehwipalancecustomerv1/core/utils/logutil.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

// lib/core/providers/location_provider.dart
class LocationService {
  static const double _defaultLatitude = 40.7128;
  static const double _defaultLongitude = -74.0060;
  static const double _defaultAccuracy = 10.0;

  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;

  Position? get currentPosition => _currentPosition;
  bool get hasLocation => _currentPosition != null;
  bool get isListening => _positionSubscription != null;

  // ==========================================================================
  // PERMISSION METHODS
  // ==========================================================================

  Future<PermissionStatus> requestPermissions() async {
    final status = await Permission.location.request();
    debugPrint('📍 Location permission: $status');
    return status;
  }

  Future<bool> checkPermissions() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  Future<bool> checkServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // ==========================================================================
  // GET CURRENT LOCATION
  // ==========================================================================

  Future<Position?> getCurrentLocation({
    bool forceRefresh = false,
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      if (!forceRefresh && _currentPosition != null) {
        debugPrint('📍 Using cached location');
        return _currentPosition;
      }

      final hasPermission = await checkPermissions();

      if (!hasPermission) {
        final permission = await requestPermissions();
        if (!permission.isGranted) {
          debugPrint('❌ Location permission denied');
          return null;
        }
      }

      final enabled = await checkServiceEnabled();

      if (!enabled) {
        debugPrint('❌ Location services disabled');
        return await _getLastKnownPosition();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _currentPosition = position;
      debugPrint(
        '📍 Current Position: ${position.latitude}, ${position.longitude}',
      );

      return position;
    } on TimeoutException {
      debugPrint('⚠️ Location request timed out');
      return await _getLastKnownPosition();
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      return await _getLastKnownPosition();
    }
  }

  Future<Position?> _getLastKnownPosition() async {
    try {
      final position = await Geolocator.getLastKnownPosition();

      if (position != null) {
        _currentPosition = position;
        debugPrint(
          '📦 Last known location: ${position.latitude}, ${position.longitude}',
        );
      } else {
        debugPrint('⚠️ No last known position available');
      }

      return position;
    } catch (e) {
      debugPrint('❌ Last location error: $e');
      return null;
    }
  }

  // ==========================================================================
  // LOCATION STREAM
  // ==========================================================================

  Stream<Position> listenToLocationUpdates({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int interval = 5,
    double distanceFilter = 10,
  }) {
    final settings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter.round(),
      timeLimit: Duration(seconds: interval),
    );

    return Geolocator.getPositionStream(locationSettings: settings).map((
      position,
    ) {
      _currentPosition = position;
      return position;
    });
  }

  void stopListening() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    debugPrint('📍 Location listener stopped');
  }

  // ==========================================================================
  // GEOCODING METHODS - FIXED
  // ==========================================================================

  Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Create an instance of Geocoding
      final geocoding = Geocoding();
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        debugPrint('⚠️ No placemarks found for coordinates');
        return null;
      }

      final place = placemarks.first;

      final parts =
          [
                place.name,
                place.street,
                place.locality,
                place.administrativeArea,
                place.country,
              ]
              .where((e) => e != null && e.toString().trim().isNotEmpty)
              .cast<String>();

      final address = parts.join(', ');
      debugPrint('📍 Reverse geocoded address: $address');
      return address;
    } catch (e) {
      debugPrint('❌ Reverse geocode error: $e');
      return null;
    }
  } // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  Position getDefaultLocation() {
    return Position(
      latitude: _defaultLatitude,
      longitude: _defaultLongitude,
      timestamp: DateTime.now(),
      accuracy: _defaultAccuracy,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  // ==========================================================================
  // DISPOSAL
  // ==========================================================================

  void dispose() {
    stopListening();
    _currentPosition = null;
    debugPrint('📍 LocationService disposed');
  }
}

// ============================================================================
// GEO INDEX CLASS
// ============================================================================

class GeoIndex<T> {
  final Map<String, List<T>> _buckets = {};

  Map<String, List<T>> get buckets => _buckets;

  int get totalEntries =>
      _buckets.values.fold(0, (int count, List<T> list) => count + list.length);

  void insert(double lat, double lng, T item, {int precision = 5}) {
    final key = GeoEngine.encode(lat, lng, precision: precision);
    _buckets.putIfAbsent(key, () => []).add(item);
  }

  List<T> search(double lat, double lng, double radiusKm, {int precision = 5}) {
    final center = GeoEngine.encode(lat, lng, precision: precision);
    final neighbors = GeoEngine.expandNeighbors(center);

    final results = <T>[];
    for (final key in neighbors) {
      final bucket = _buckets[key];
      if (bucket != null) results.addAll(bucket);
    }
    return results;
  }

  void clear() => _buckets.clear();
}

// ============================================================================
// GEO ENGINE
// ============================================================================

class GeoEngine {
  static String encode(double lat, double lng, {int precision = 5}) {
    bool isEven = true;
    int bit = 0;
    int ch = 0;

    double latMin = -90, latMax = 90;
    double lngMin = -180, lngMax = 180;

    final buffer = StringBuffer();

    while (buffer.length < precision) {
      if (isEven) {
        final mid = (lngMin + lngMax) / 2;
        if (lng >= mid) {
          ch |= (1 << (4 - bit));
          lngMin = mid;
        } else {
          lngMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (lat >= mid) {
          ch |= (1 << (4 - bit));
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      isEven = !isEven;

      if (bit < 4) {
        bit++;
      } else {
        buffer.write(ApiKeys.base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return buffer.toString();
  }

  static List<String> expandNeighbors(String hash) {
    if (hash.isEmpty) return [hash];

    final neighbors = <String>{hash};

    final last = hash.substring(hash.length - 1);
    final index = ApiKeys.base32.indexOf(last);
    if (index == -1) return neighbors.toList();

    for (int d = -1; d <= 1; d++) {
      final i = index + d;
      if (i >= 0 && i < ApiKeys.base32.length) {
        neighbors.add(hash.substring(0, hash.length - 1) + ApiKeys.base32[i]);
      }
    }

    return neighbors.toList();
  }
}

// ============================================================================
// EXTENSIONS
// ============================================================================

// ================= EXTENSIONS =================

extension StringExtensions on String {
  bool equalsIgnoreCase(String other) {
    return toLowerCase() == other.toLowerCase();
  }
}

// ================= LOCATION SERVICE =================

class GeocodingService {
  static const Map<String, String> _headers = {
    'User-Agent': 'LehwiPalanceApp/1.0',
  };

  Future<LatLng?> geocodeAddress(AddressModel address) async {
    try {
      final query = _buildQuery(address);
      final uri = Uri.parse('$ApiKeys.baseUrl?$query&format=json&limit=1');

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final result = data[0];
          return LatLng(
            double.parse(result['lat']),
            double.parse(result['lon']),
          );
        }
      }
      return null;
    } catch (e) {
      AppLogger.info('Geocoding error: $e');
      return null;
    }
  }

  String _buildQuery(AddressModel address) {
    final parts = <String>[];
    parts.add(address.street);
    parts.add(address.city);
    parts.add(address.state);
    parts.add(address.country);

    return 'q=${Uri.encodeComponent(parts.join(', '))}';
  }

  Future<AddressModel?> reverseGeocode(LatLng location) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'lat=${location.latitude}&lon=${location.longitude}&format=json',
      );

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];

        return AddressModel(
          country: address['country'] ?? '',
          city: address['city'] ?? address['town'] ?? address['village'] ?? '',
          state: address['state'] ?? address['region'] ?? '',
          street: '',
          postalCode: address['postcode'],
        );
      }
      return null;
    } catch (e) {
      AppLogger.info('Reverse geocoding error: $e');
      return null;
    }
  }
}

// ================= GEO ENGINE (Consolidated) =================

class GeoHashUtils {
  static String encode(double lat, double lon, {int precision = 5}) {
    bool isEven = true;
    int bit = 0;
    int ch = 0;

    double latMin = -90, latMax = 90;
    double lonMin = -180, lonMax = 180;

    final geohash = StringBuffer();

    while (geohash.length < precision) {
      if (isEven) {
        final mid = (lonMin + lonMax) / 2;
        if (lon >= mid) {
          ch |= (1 << (4 - bit));
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (lat >= mid) {
          ch |= (1 << (4 - bit));
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      isEven = !isEven;

      if (bit < 4) {
        bit++;
      } else {
        geohash.write(ApiKeys.base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return geohash.toString();
  }

  static List<String> neighbors(String hash) {
    final neighbors = <String>{hash};

    if (hash.isEmpty) return neighbors.toList();

    final lastChar = hash.substring(hash.length - 1);

    final index = ApiKeys.base32.indexOf(lastChar);
    if (index == -1) return neighbors.toList();

    for (int i = -1; i <= 1; i++) {
      final newIndex = index + i;
      if (newIndex >= 0 && newIndex < ApiKeys.base32.length) {
        neighbors.add(
          hash.substring(0, hash.length - 1) + ApiKeys.base32[newIndex],
        );
      }
    }

    return neighbors.toList();
  }
}
// ============================================================================
// STATIC FUNCTIONS FOR ISOLATES
// ============================================================================

// ============================================================================
// LOCATION PROVIDER - Main Class
// ============================================================================
