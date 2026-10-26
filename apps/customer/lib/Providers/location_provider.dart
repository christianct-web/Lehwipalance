// ignore_for_file: unused_field

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lehwipalancecustomerv1/Providers/location_services.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/base/mock_api_service.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';
import 'package:latlong2/latlong.dart';

class LocationProvider extends ChangeNotifier {
  final ApiService _apiService;
  final LocationService? _locationService;

  // ==========================================================================
  // STATE
  // ==========================================================================

  final List<LocationModel> _allLocations = [];
  final List<LocationFilter> _presetFilters = [];
  final GeoIndex<LocationModel> _geoIndex = GeoIndex<LocationModel>();

  List<LocationModel> _filteredLocations = [];
  List<String> _allCountries = [];

  Position? _devicePosition;

  // ==========================================================================
  // FLAGS
  // ==========================================================================

  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isCacheLoaded = false;
  final bool _isLoadingCache = false;
  bool _isCacheFullyLoaded = false;
  bool _isLocationLoading = false;
  bool _isListeningToLocation = false;

  // ==========================================================================
  // PROGRESS TRACKING
  // ==========================================================================

  int _cacheLoadProgress = 0;
  final int _totalLocationsInCache = 0;

  // ==========================================================================
  // FILTER STATE
  // ==========================================================================

  LocationFilter _filter = const LocationFilter();
  String? _activeFilterId;

  // ==========================================================================
  // CACHE CONFIGURATION
  // ==========================================================================

  static const Duration _cacheMaxAge = Duration(hours: 24);
  static const int _chunkSize = 100;
  static const int _batchSize = 50;

  // ==========================================================================
  // CONSTRUCTOR
  // ==========================================================================

  LocationProvider({ApiService? apiService, LocationService? locationService})
    : _apiService = apiService ?? getIt<ApiService>(),
      _locationService = locationService ?? LocationService() {
    _allCountries = [];
  }

  // ==========================================================================
  // GETTERS
  // ==========================================================================

  List<LocationModel> get locations => _filteredLocations;
  bool get isLoading => _isLoading;
  bool get isLocationLoading => _isLocationLoading;
  LocationFilter get filter => _filter;
  List<LocationFilter> get presetFilters => List.unmodifiable(_presetFilters);
  String? get activeFilterId => _activeFilterId;
  List<String> get countries => List.unmodifiable(_allCountries);
  Position? get devicePosition => _devicePosition;
  bool get hasDeviceLocation => _devicePosition != null;
  bool get isListeningToLocation => _isListeningToLocation;
  bool get hasCachedData => _allLocations.isNotEmpty;
  bool get isCacheLoading => _isLoadingCache;
  int get cacheLoadProgress => _cacheLoadProgress;
  bool get isCacheFullyLoaded => _isCacheFullyLoaded;

  LocationFilter? get activeFilter {
    if (_activeFilterId == null) return null;
    try {
      return _presetFilters.firstWhere((f) => f.id == _activeFilterId);
    } catch (_) {
      return null;
    }
  }

  String? get selectedCountry => _filter.country;
  bool get hasSelectedCountry =>
      selectedCountry != null && selectedCountry!.isNotEmpty;

  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_isInitialized && !forceRefresh) {
      debugPrint('📍 LocationProvider already initialized');
      return;
    }

    if (_isLoading) {
      debugPrint('📍 LocationProvider already loading, waiting...');
      await Future.delayed(const Duration(milliseconds: 100));
      if (_isInitialized) return;
    }

    debugPrint('🔄 Initializing LocationProvider...');
    _isLoading = true;

    try {
      // Load saved device location from memory
      if (_devicePosition != null) {
        _updateLocationInFilter(_devicePosition!);
      }

      if (_allLocations.isEmpty || forceRefresh) {
        debugPrint('📍 No locations in cache, loading from mock data...');
        await _loadFromMockDatabase();
      }

      if (_locationService != null) {
        await getDeviceLocation();
      }

      await _applyActiveFilter();

      _isInitialized = true;
      _isCacheLoaded = true;

      debugPrint(
        '✅ LocationProvider initialized with ${_allLocations.length} locations',
      );
      debugPrint('🌎 Countries available: ${_allCountries.length}');

      if (_allLocations.isEmpty) {
        debugPrint(
          '⚠️ Still no locations, forcing direct load from mockLocations...',
        );
        await _forceLoadFromMockLocations();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ LocationProvider initialization failed: $e');
      await _forceLoadFromMockLocations();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _forceLoadFromMockLocations() async {
    try {
      debugPrint('🚨 FORCE LOADING locations from mockLocations...');
      final locations = mockLocations;

      if (locations.isNotEmpty) {
        _allLocations.clear();
        _allLocations.addAll(locations);

        for (final location in locations) {
          MockDatabase.locations[location.id] = location;
        }

        await _buildIndexes();

        debugPrint(
          '✅ FORCE LOADED ${locations.length} locations from mockLocations',
        );

        _buildLocationCaches();
        debugPrint('🌎 Countries after force load: ${_allCountries.length}');

        _isCacheFullyLoaded = true;
        _isInitialized = true;
        notifyListeners();
      } else {
        debugPrint('❌ No mockLocations found!');
      }
    } catch (e) {
      debugPrint('❌ Force load failed: $e');
    }
  }

  // ==========================================================================
  // CACHE LOADING WITH PROGRESS
  // ==========================================================================

  // ==========================================================================
  // GEOINDEX CACHING
  // ==========================================================================

  Future<void> _buildIndexes() async {
    _buildLocationCaches();
    await _buildGeoIndex();
    _applyFilters();
  }

  void _buildLocationCaches() {
    _allCountries =
        _allLocations
            .map((location) => location.address.country)
            .where((country) => country.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
  }

  Future<void> _buildGeoIndex({int precision = 5}) async {
    _geoIndex.clear();

    final total = _allLocations.length;
    for (int i = 0; i < total; i += _batchSize) {
      final end = (i + _batchSize < total) ? i + _batchSize : total;

      for (int j = i; j < end; j++) {
        final loc = _allLocations[j];
        _geoIndex.insert(
          loc.latitude,
          loc.longitude,
          loc,
          precision: precision,
        );
      }

      if (i % 100 == 0 && i > 0) {
        await Future.delayed(Duration.zero);
      }
    }

    debugPrint('🗺️ GeoIndex built with $total locations');
  }

  // ==========================================================================
  // CACHE SAVING
  // ==========================================================================

  Future<void> _saveToCache() async {
    // In-memory only - no persistent storage
    debugPrint('💾 Location cache kept in memory');
  }

  // ==========================================================================
  // DATA LOADING
  // ==========================================================================

  Future<void> loadAllLocations({bool forceRefresh = false}) async {
    if (_allLocations.isNotEmpty && !forceRefresh) {
      debugPrint('📦 Using cached locations (${_allLocations.length} items)');
      return;
    }

    if (_isLoading) {
      debugPrint('⏳ Location load already in progress, skipping...');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🔄 Loading all locations...');
      final locations = await _apiService.getAllLocations();

      if (locations.isNotEmpty) {
        _allLocations.clear();
        _allLocations.addAll(locations);
        debugPrint('✅ Loaded ${locations.length} locations from API');
      } else {
        debugPrint(
          '⚠️ API returned 0 locations, loading from mockLocations...',
        );
        await _loadFromMockDatabase();
      }

      await _buildIndexes();
      await _saveToCache();

      debugPrint(
        '✅ Location cache updated with ${_allLocations.length} locations',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to load locations: $e');
      await _loadFromMockDatabase();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromMockDatabase() async {
    try {
      debugPrint('📦 Loading locations from mockLocations...');
      final locations = getMockLocations();

      if (locations.isNotEmpty) {
        _allLocations.clear();
        _allLocations.addAll(locations);
        debugPrint('✅ Loaded ${locations.length} locations from mockLocations');

        for (final location in locations) {
          MockDatabase.locations[location.id] = location;
        }

        await _buildIndexes();
        await _saveToCache();
      } else {
        debugPrint('⚠️ No mockLocations found');
      }
    } catch (e) {
      debugPrint('❌ Failed to load from mockLocations: $e');
    }
  }

  // ==========================================================================
  // DEVICE LOCATION
  // ==========================================================================

  Future<Position?> getDeviceLocation({bool forceRefresh = false}) async {
    if (_locationService == null) {
      debugPrint('⚠️ LocationService not available');
      return null;
    }

    if (_devicePosition != null && !forceRefresh) {
      debugPrint('📍 Using cached device location');
      return _devicePosition;
    }

    try {
      _isLocationLoading = true;
      notifyListeners();

      debugPrint('📍 Fetching device location...');
      final position = await _locationService.getCurrentLocation(
        forceRefresh: forceRefresh,
      );

      if (position != null) {
        _devicePosition = position;
        _updateLocationInFilter(position);
        debugPrint(
          '✅ Device location: ${position.latitude}, ${position.longitude}',
        );
      } else {
        debugPrint('⚠️ Could not get device location');
      }

      notifyListeners();
      return _devicePosition;
    } catch (e) {
      debugPrint('❌ Error getting device location: $e');
      return null;
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  void startListeningToLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int interval = 5,
    double distanceFilter = 10.0,
  }) {
    if (_locationService == null || _isListeningToLocation) return;

    _isListeningToLocation = true;
    _locationService
        .listenToLocationUpdates(
          accuracy: accuracy,
          interval: interval,
          distanceFilter: distanceFilter,
        )
        .listen(_onLocationUpdate)
        .onError((error) {
          debugPrint('❌ Location stream error: $error');
          _isListeningToLocation = false;
        });
  }

  void _onLocationUpdate(Position position) {
    _devicePosition = position;
    _updateLocationInFilter(position);
    notifyListeners();
  }

  void stopListeningToLocation() {
    _locationService?.stopListening();
    _isListeningToLocation = false;
    debugPrint('📍 Stopped listening to location updates');
  }

  // ==========================================================================
  // FILTER MANAGEMENT
  // ==========================================================================

  void _updateLocationInFilter(Position position) {
    final center = LatLng(position.latitude, position.longitude);

    if (_filter.center == null ||
        _calculateDistance(
              _filter.center!.latitude,
              _filter.center!.longitude,
              center.latitude,
              center.longitude,
            ) >
            1.0) {
      _filter = _filter.copyWith(center: center);
      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> _applyActiveFilter() async {
    if (_activeFilterId == null) return;

    final filter = getPresetFilter(_activeFilterId!);
    if (filter != null) {
      _filter = filter;
      _applyFilters();
      notifyListeners();
    } else {
      _activeFilterId = null;
    }
  }

  void _applyFilters() {
    if (_allLocations.isEmpty) {
      _filteredLocations = [];
      return;
    }

    List<LocationModel> result = _allLocations;

    if (_filter.center != null && _filter.radiusKm != null) {
      result = _geoIndex.search(
        _filter.center!.latitude,
        _filter.center!.longitude,
        _filter.radiusKm!,
      );
    }

    if (_filter.search != null && _filter.search!.isNotEmpty) {
      final q = _filter.search!.toLowerCase();
      result = result.where((l) {
        return l.name.toLowerCase().contains(q) ||
            l.address.city.toLowerCase().contains(q) ||
            l.address.country.toLowerCase().contains(q) ||
            l.address.state.toLowerCase().contains(q);
      }).toList();
    }

    if (_filter.state != null && _filter.state!.isNotEmpty) {
      result = result
          .where(
            (l) =>
                l.address.state.toLowerCase() == _filter.state!.toLowerCase(),
          )
          .toList();
    }

    if (_filter.country != null && _filter.country!.isNotEmpty) {
      result = result
          .where(
            (l) =>
                l.address.country.toLowerCase() ==
                _filter.country!.toLowerCase(),
          )
          .toList();
    }

    if (_filter.city != null && _filter.city!.isNotEmpty) {
      result = result
          .where(
            (l) => l.address.city.toLowerCase() == _filter.city!.toLowerCase(),
          )
          .toList();
    }

    if (_filter.customFilter != null) {
      result = result.where(_filter.customFilter!).toList();
    }

    _filteredLocations = result;
  }

  // ==========================================================================
  // PUBLIC FILTER METHODS
  // ==========================================================================

  void setCountry(String? country) {
    if (_filter.country != country) {
      _filter = _filter.copyWith(country: country);
      _applyFilters();
      notifyListeners();
      debugPrint('[LocationProvider] Country set to: $country');
    }
  }

  void clearCountry() {
    if (_filter.country != null) {
      _filter = _filter.copyWith(clearCountry: true);
      _applyFilters();
      notifyListeners();
      debugPrint('[LocationProvider] Country cleared');
    }
  }

  void updateFilter(LocationFilter filter) {
    _filter = filter;
    final matchingPreset = _presetFilters.firstWhere(
      (f) => f.id == filter.id,
      orElse: () => const LocationFilter(),
    );
    if (matchingPreset.id != null) {
      _activeFilterId = matchingPreset.id;
    } else {
      _activeFilterId = null;
    }
    _applyFilters();
    notifyListeners();
  }

  void setActivePresetExclusive(String id) {
    for (int i = 0; i < _presetFilters.length; i++) {
      _presetFilters[i] = _presetFilters[i].copyWith(
        isExclusive: _presetFilters[i].id == id,
      );
    }

    _activeFilterId = id;
    applyFilterPreset(id);
    notifyListeners();
  }

  void addPresetFilter(LocationFilter filter) {
    if (filter.id == null || filter.id!.isEmpty) {
      debugPrint('⚠️ Cannot add filter with null or empty ID');
      return;
    }

    final existsById = _presetFilters.any((f) => f.id == filter.id);
    if (existsById) {
      debugPrint('⚠️ Filter with ID ${filter.id} already exists');
      return;
    }

    if (filter.name != null && filter.name!.isNotEmpty) {
      final existsByName = _presetFilters.any(
        (f) => f.name?.toLowerCase() == filter.name!.toLowerCase(),
      );
      if (existsByName) {
        debugPrint('⚠️ Filter with name "${filter.name}" already exists');
        return;
      }
    }

    _presetFilters.add(filter);
    notifyListeners();
    debugPrint('✅ Filter added: ${filter.name} (${filter.id})');
  }

  bool removePresetFilter(String id) {
    if (id.isEmpty) return false;

    final initialLength = _presetFilters.length;
    _presetFilters.removeWhere((f) => f.id == id);
    final removed = _presetFilters.length < initialLength;
    if (removed) {
      if (_activeFilterId == id) {
        _activeFilterId = null;
      }
      notifyListeners();
      debugPrint('🗑️ Filter removed: $id');
    }
    return removed;
  }

  bool applyFilterPreset(String id) {
    if (id.isEmpty) return false;

    try {
      final filter = _presetFilters.firstWhere((f) => f.id == id);
      _activeFilterId = id;
      _filter = filter;
      _applyFilters();
      notifyListeners();
      debugPrint('✅ Active filter set to: ${filter.name} ($id)');
      return true;
    } catch (e) {
      debugPrint('❌ Error applying filter preset: $e');
      return false;
    }
  }

  void clearActiveFilter() {
    _activeFilterId = null;
    _filter = const LocationFilter();
    _applyFilters();
    notifyListeners();
    debugPrint('🧹 Active filter cleared');
  }

  LocationFilter? getPresetFilter(String id) {
    if (id.isEmpty) return null;
    try {
      return _presetFilters.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  LocationFilter? createCountryFilter(
    String country, {
    bool isExclusive = false,
  }) {
    if (country.isEmpty) {
      debugPrint('⚠️ Cannot create filter with empty country');
      return null;
    }

    final existing = _presetFilters.firstWhere(
      (f) =>
          f.country?.toLowerCase() == country.toLowerCase() &&
          f.city == null &&
          f.state == null,
      orElse: () => const LocationFilter(),
    );

    if (existing.id != null) {
      debugPrint('⚠️ Filter for $country already exists');
      return existing;
    }

    final filter = LocationFilter(
      id: 'filter_${DateTime.now().millisecondsSinceEpoch}',
      name: '$country Locations',
      country: country,
      isExclusive: isExclusive,
    );

    addPresetFilter(filter);
    return filter;
  }

  bool updatePresetFilter(LocationFilter filter) {
    if (filter.id == null || filter.id!.isEmpty) {
      debugPrint('⚠️ Cannot update filter with null or empty ID');
      return false;
    }

    if (filter.name != null && filter.name!.isNotEmpty) {
      final existsByName = _presetFilters.any(
        (f) =>
            f.id != filter.id &&
            f.name?.toLowerCase() == filter.name!.toLowerCase(),
      );

      if (existsByName) {
        debugPrint(
          '⚠️ Another filter with name "${filter.name}" already exists',
        );
        return false;
      }
    }

    final index = _presetFilters.indexWhere((f) => f.id == filter.id);
    if (index != -1) {
      _presetFilters[index] = filter;
      if (_activeFilterId == filter.id) {
        applyFilterPreset(filter.id!);
      }
      notifyListeners();
      debugPrint('✏️ Filter updated: ${filter.name} (${filter.id})');
      return true;
    }

    debugPrint('⚠️ Filter with ID ${filter.id} not found');
    return false;
  }

  // ==========================================================================
  // LOCATION-BASED FEATURES
  // ==========================================================================

  List<LocationModel> getNearbyLocations({double radiusKm = 10}) {
    if (_devicePosition == null) return [];
    return _geoIndex.search(
      _devicePosition!.latitude,
      _devicePosition!.longitude,
      radiusKm,
    );
  }

  double? getDistanceToLocation(LocationModel location) {
    if (_devicePosition == null) return null;
    return _calculateDistance(
      _devicePosition!.latitude,
      _devicePosition!.longitude,
      location.latitude,
      location.longitude,
    );
  }

  List<LocationModel> getLocationsSortedByDistance() {
    if (_devicePosition == null) return _filteredLocations;

    final list = List<LocationModel>.from(_filteredLocations);
    list.sort((a, b) {
      final distA = getDistanceToLocation(a) ?? double.infinity;
      final distB = getDistanceToLocation(b) ?? double.infinity;
      return distA.compareTo(distB);
    });
    return list;
  }

  Future<LocationFilter?> suggestFilterFromLocation() async {
    if (_devicePosition == null || _locationService == null) return null;

    try {
      final address = await _locationService.getAddressFromCoordinates(
        latitude: _devicePosition!.latitude,
        longitude: _devicePosition!.longitude,
      );

      if (address == null) return null;

      final city = _extractCityFromAddress(address);
      if (city != null) {
        final existingFilter = _presetFilters.firstWhere(
          (f) => f.city == city,
          orElse: () => const LocationFilter(),
        );

        if (existingFilter.id != null) {
          return existingFilter;
        }

        final newFilter = LocationFilter(
          id: 'filter_${DateTime.now().millisecondsSinceEpoch}',
          name: '📍 Near $city',
          city: city,
          center: LatLng(_devicePosition!.latitude, _devicePosition!.longitude),
          radiusKm: 10.0,
          isExclusive: false,
        );

        return newFilter;
      }
    } catch (e) {
      debugPrint('❌ Error suggesting filter: $e');
    }

    return null;
  }

  String? _extractCityFromAddress(String address) {
    final parts = address.split(',');
    if (parts.length >= 2) {
      return parts[1].trim();
    }
    return parts.first.trim();
  }

  Future<void> suggestActiveCityFromGPS({
    required double userLat,
    required double userLng,
    required BuildContext context,
  }) async {
    if (_presetFilters.isEmpty) return;

    LocationFilter? closest;
    double? closestDistance;

    for (final filter in _presetFilters) {
      if (filter.city == null || filter.center == null) continue;

      final d = _calculateDistance(
        userLat,
        userLng,
        filter.center!.latitude,
        filter.center!.longitude,
      );

      if (closestDistance == null || d < closestDistance) {
        closestDistance = d;
        closest = filter;
      }
    }

    if (closest == null || closestDistance == null) return;
    if (closestDistance > 25) return;
    if (closest.id == _activeFilterId) return;

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Switch to ${closest.city}? You're near it (${closestDistance.toStringAsFixed(1)} km)",
        ),
        action: SnackBarAction(
          label: "Switch",
          onPressed: () {
            applyFilterPreset(closest!.id!);
          },
        ),
      ),
    );
  }

  // ==========================================================================
  // UNIQUE VALUES FROM LOCATIONS
  // ==========================================================================

  List<String> getUniqueCountries() {
    return List.unmodifiable(_allCountries);
  }

  List<String> getUniqueStates({String? country}) {
    final states = <String>{};
    for (final location in _allLocations) {
      if (country != null && location.address.country != country) continue;
      final state = location.address.state;
      if (state.isNotEmpty) states.add(state);
    }
    return states.toList()..sort();
  }

  List<String> getUniqueCities({String? country, String? state}) {
    final cities = <String>{};
    for (final location in _allLocations) {
      if (country != null && location.address.country != country) continue;
      if (state != null && location.address.state != state) continue;
      final city = location.address.city;
      if (city.isNotEmpty) cities.add(city);
    }
    return cities.toList()..sort();
  }

  List<String> getAllCityNames() {
    final cities = <String>{};
    for (final location in _allLocations) {
      if (location.address.city.isNotEmpty) {
        cities.add(location.address.city);
      }
    }
    return cities.toList()..sort();
  }

  List<LocationModel> getLocationsByCountry(String country) {
    return _allLocations
        .where((l) => l.address.country.toLowerCase() == country.toLowerCase())
        .toList();
  }

  List<LocationModel> getLocationsByState(String state) {
    return _allLocations
        .where((l) => l.address.state.toLowerCase() == state.toLowerCase())
        .toList();
  }

  List<LocationModel> getLocationsByCity(String city) {
    return _allLocations
        .where((l) => l.address.city.toLowerCase() == city.toLowerCase())
        .toList();
  }

  void updateLocations(List<LocationModel> locations) {
    _allLocations
      ..clear()
      ..addAll(locations);
    _buildLocationCaches();
    _buildGeoIndex();
    _applyFilters();
    notifyListeners();
    debugPrint('[LocationProvider] Updated with ${locations.length} locations');
  }

  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  LocationModel? getById(String id) {
    try {
      return _allLocations.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  List<LocationModel> getNearby({
    required LatLng center,
    required double radiusKm,
  }) {
    return _geoIndex.search(center.latitude, center.longitude, radiusKm);
  }

  Map<String, dynamic> getFilterSummary() {
    return {
      'hasActiveFilter': _activeFilterId != null,
      'activeFilterName': getActiveFilterName(),
      'filterCount': _presetFilters.length,
      'exclusiveCount': _presetFilters.where((f) => f.isExclusive).length,
      'currentCountry': _filter.country,
      'currentState': _filter.state,
      'currentCity': _filter.city,
      'hasLocation': hasDeviceLocation,
      'resultCount': _filteredLocations.length,
    };
  }

  String getActiveFilterName({String defaultName = 'All Locations'}) {
    if (_activeFilterId == null) return defaultName;
    final filter = getPresetFilter(_activeFilterId!);
    return filter?.name ?? defaultName;
  }

  int getActiveFilterCount() {
    return _presetFilters.where((f) => f.isExclusive).length;
  }

  bool isFilterNameUnique(String name, {String? excludeId}) {
    if (name.isEmpty) return false;
    return !_presetFilters.any(
      (f) => f.id != excludeId && f.name?.toLowerCase() == name.toLowerCase(),
    );
  }

  bool hasFilter(String id) {
    if (id.isEmpty) return false;
    return _presetFilters.any((f) => f.id == id);
  }

  LocationFilter? getFilterByName(String name) {
    if (name.isEmpty) return null;
    try {
      return _presetFilters.firstWhere(
        (f) => f.name?.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  List<String> getFilterNames() {
    return _presetFilters.map((f) => f.name ?? 'Unnamed').toList();
  }

  // ==========================================================================
  // CLEAR / DISPOSE
  // ==========================================================================

  void clearAllData() {
    _allLocations.clear();
    _allCountries.clear();
    _filteredLocations.clear();
    _presetFilters.clear();
    _activeFilterId = null;
    _filter = const LocationFilter();
    _devicePosition = null;
    _isInitialized = false;
    _isCacheLoaded = false;
    _isCacheFullyLoaded = false;
    _cacheLoadProgress = 0;
    _geoIndex.clear();

    debugPrint('🗑️ Location data cleared');
    notifyListeners();
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    stopListeningToLocation();
    _isInitialized = false;
    super.dispose();
  }
}
