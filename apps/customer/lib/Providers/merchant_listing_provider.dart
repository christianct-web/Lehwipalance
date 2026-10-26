// merchant_listing_map_provider.dart
// For Map View - Geospatial queries and location-based filtering

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';

import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';
import 'package:lehwipalancecustomerv1/core/utils/logutil.dart';

import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/map/provider/filter_preference_model.dart';
import 'package:lehwipalancecustomerv1/modules/map/widgets/merchant_listing_filter_sheet.dart';

class MerchantListingProvider extends ChangeNotifier {
  final ApiService _apiService;
  final LocationProvider _locationProvider;

  // ==================== DATA ====================
  List<MerchantListingDTO> _allListings = [];
  List<MerchantListingDTO> _filteredListings = [];
  final Map<String, LocationModel> _locationCache =
      {}; // Cache for location data

  // ==================== FILTER STATE ====================
  MerchantListingFilter _currentFilter = const MerchantListingFilter();
  ListingsFilter _listingsFilter = const ListingsFilter();

  // ==================== STATE ====================
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  bool _isInitialized = false;
  bool _isDisposed = false;
  String? _error;
  DateTime? _lastLoadedAt;
  Timer? _debounceTimer;

  // ==================== PAGINATION ====================
  int _currentPage = 0;
  static const int _pageSize = 50;
  static const Duration _debounceDuration = Duration(milliseconds: 300);
  static const Duration _staleDuration = Duration(minutes: 5);

  // ==================== LISTENERS ====================
  VoidCallback? _locationListener;

  // ==================== CONSTRUCTOR ====================
  MerchantListingProvider({
    ApiService? apiService,
    LocationProvider? locationProvider,
  }) : _apiService = apiService ?? getIt<ApiService>(),
       _locationProvider = locationProvider ?? getIt<LocationProvider>() {
    _setupLocationListener();
    _syncWithLocationProvider();

    // Add self to GetIt if not already registered
    if (!getIt.isRegistered<MerchantListingProvider>()) {
      getIt.registerSingleton<MerchantListingProvider>(this);
    }
  }

  // ==================== GETTERS ====================
  List<MerchantListingDTO> get allListings => _allListings;
  List<MerchantListingDTO> get filteredListings => _filteredListings;
  MerchantListingFilter get currentFilter => _currentFilter;
  ListingsFilter get listingsFilter => _listingsFilter;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isDisposed => _isDisposed;

  LocationProvider get locationProvider => _locationProvider;
  String? get activeCountry => _locationProvider.filter.country;
  bool get hasActiveCountry =>
      activeCountry != null && activeCountry!.isNotEmpty;

  // Combined filter helpers
  bool get hasActiveFilters =>
      _currentFilter.hasFilters || _listingsFilter.hasFilters;
  bool get hasLocationFilters => _currentFilter.hasLocationFilters;
  bool get hasTypeFilters => _currentFilter.hasTypeFilters;
  bool get hasDateFilters =>
      _listingsFilter.startDate != null || _listingsFilter.endDate != null;

  /// Get the filtered listings (for backward compatibility with UI)
  List<MerchantListingDTO> get listings => _filteredListings;

  /// Check if device has location
  bool get hasDeviceLocation => _locationProvider.hasDeviceLocation;

  /// Get device position
  Position? get devicePosition => _locationProvider.devicePosition;

  /// Get location for a listing (async)
  Future<LocationModel?> getLocationForListing(
    MerchantListingDTO listing,
  ) async {
    if (listing.locationid.isEmpty) return null;

    // Check cache first
    if (_locationCache.containsKey(listing.locationid)) {
      return _locationCache[listing.locationid];
    }

    try {
      final location = await _apiService.getLocationById(listing.locationid);
      if (location != null) {
        _locationCache[listing.locationid] = location;
      }
      return location;
    } catch (e) {
      AppLogger.error('Failed to load location ${listing.locationid}: $e');
      return null;
    }
  }

  /// Get location synchronously (if cached)
  LocationModel? getCachedLocation(MerchantListingDTO listing) {
    return _locationCache[listing.locationid];
  }

  // ==================== CATEGORY GETTERS ====================
  List<MerchantListingDTO> get events =>
      _filteredListings.where((e) => e.type == ListingType.event).toList();

  List<MerchantListingDTO> get places =>
      _filteredListings.where((e) => e.type == ListingType.place).toList();

  List<MerchantListingDTO> get hotels =>
      _filteredListings.where((e) => e.type == ListingType.hotel).toList();

  List<MerchantListingDTO> get services =>
      _filteredListings.where((e) => e.type == ListingType.service).toList();

  List<MerchantListingDTO> get listingsByActiveCountry {
    if (!hasActiveCountry) return _filteredListings;
    return _filteredListings.where((listing) {
      final location = _locationCache[listing.locationid];
      if (location == null) return false;
      return location.address.country.toLowerCase() ==
          activeCountry!.toLowerCase();
    }).toList();
  }

  Map<String, int> get categoryCounts => {
    'events': events.length,
    'places': places.length,
    'hotels': hotels.length,
    'services': services.length,
  };

  bool get needsRefresh {
    if (_allListings.isEmpty) return true;
    if (_lastLoadedAt == null) return true;
    return DateTime.now().difference(_lastLoadedAt!) > _staleDuration;
  }

  // ==================== UNIQUE LOCATION HELPERS ====================

  List<String> getUniqueCountries() {
    final countries = <String>{};
    for (final listing in _filteredListings) {
      final location = _locationCache[listing.locationid];
      if (location != null) {
        final country = location.address.country.trim();
        if (country.isNotEmpty) {
          countries.add(country);
        }
      }
    }
    return countries.toList()..sort((a, b) => a.compareTo(b));
  }

  List<String> getUniqueStates({String? country}) {
    final states = <String>{};
    for (final listing in _filteredListings) {
      final location = _locationCache[listing.locationid];
      if (location != null) {
        if (country != null && location.address.country != country) {
          continue;
        }
        final state = location.address.state;
        if (state.isNotEmpty) states.add(state);
      }
    }
    return states.toList()..sort();
  }

  List<String> getUniqueCities({String? country, String? state}) {
    final cities = <String>{};
    for (final listing in _filteredListings) {
      final location = _locationCache[listing.locationid];
      if (location != null) {
        if (country != null && location.address.country != country) {
          continue;
        }
        if (state != null && location.address.state != state) continue;
        final city = location.address.city;
        if (city.isNotEmpty) cities.add(city);
      }
    }
    return cities.toList()..sort();
  }

  /// Get unique countries (uses all listings, not filtered)
  List<String> getUniqueCountriesFromAll() {
    final countries = <String>{};
    for (final listing in _allListings) {
      final location = _locationCache[listing.locationid];
      if (location != null) {
        countries.add(location.address.country);
      }
    }
    return countries.toList()..sort();
  }

  /// Get unique states from all listings (optionally filtered by country)
  List<String> getUniqueStatesFromAll({String? country}) {
    final states = <String>{};
    for (final listing in _allListings) {
      final location = _locationCache[listing.locationid];
      if (location != null) {
        if (country != null && location.address.country != country) {
          continue;
        }
        final state = location.address.state;
        if (state.isNotEmpty) states.add(state);
      }
    }
    return states.toList()..sort();
  }

  /// Get unique cities from all listings (optionally filtered by country/state)
  List<String> getUniqueCitiesFromAll({String? country, String? state}) {
    final cities = <String>{};
    for (final listing in _allListings) {
      final location = _locationCache[listing.locationid];
      if (location != null) {
        if (country != null && location.address.country != country) {
          continue;
        }
        if (state != null && location.address.state != state) continue;
        final city = location.address.city;
        if (city.isNotEmpty) cities.add(city);
      }
    }
    return cities.toList()..sort();
  }

  // ==================== SETUP ====================
  void _setupLocationListener() {
    _locationListener = () {
      if (_isDisposed) return;
      _onLocationChanged();
    };
    _locationProvider.addListener(_locationListener!);
  }

  // ==================== LOAD METHODS ====================

  /// Load locations for a list of listings
  Future<void> _loadLocationsForListings(
    List<MerchantListingDTO> listings,
  ) async {
    final locationIds = listings
        .where((l) => l.locationid.isNotEmpty)
        .map((l) => l.locationid)
        .toSet()
        .toList();

    if (locationIds.isEmpty) return;

    try {
      final locations = await Future.wait(
        locationIds.map((id) => _apiService.getLocationById(id)),
      );

      for (int i = 0; i < locationIds.length; i++) {
        if (locations[i] != null) {
          _locationCache[locationIds[i]] = locations[i]!;
        }
      }
      AppLogger.info('Loaded ${_locationCache.length} locations');
    } catch (e) {
      AppLogger.error('Failed to load locations: $e');
    }
  }

  /// Preload locations for a list of location IDs
  Future<void> preloadLocations(List<String> locationIds) async {
    final idsToLoad = locationIds
        .where((id) => id.isNotEmpty && !_locationCache.containsKey(id))
        .toList();

    if (idsToLoad.isEmpty) return;

    try {
      final locations = await Future.wait(
        idsToLoad.map((id) => _apiService.getLocationById(id)),
      );

      for (int i = 0; i < idsToLoad.length; i++) {
        if (locations[i] != null) {
          _locationCache[idsToLoad[i]] = locations[i]!;
        }
      }
    } catch (e) {
      AppLogger.error('Failed to preload locations: $e');
    }
  }

  Future<void> loadListings({bool refresh = false}) async {
    if (_isDisposed) return;

    // Save current filter state before clearing
    final savedCountry = _currentFilter.country;
    final savedState = _currentFilter.state;
    final savedCity = _currentFilter.city;
    final savedTypes = _currentFilter.listingTypes;
    final savedSearch = _currentFilter.searchQuery;
    final savedUserLocation = _currentFilter.userLocation;
    final savedRadius = _currentFilter.radius;

    if (refresh) {
      _currentPage = 0;
      _allListings.clear();
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.info(
        'Loading merchant listings - Page: $_currentPage, Size: $_pageSize',
      );

      final result = await _apiService.getMerchantListingsPaginated(
        _currentPage,
        _pageSize,
      );

      if (refresh || _currentPage == 0) {
        _allListings = result.items;
      } else {
        _allListings.addAll(result.items);
      }

      // Load locations for the listings
      await _loadLocationsForListings(_allListings);

      _hasMore = result.hasNextPage;
      _currentPage++;
      _lastLoadedAt = DateTime.now();

      // Restore filters after loading
      _currentFilter = _currentFilter.copyWith(
        country: savedCountry,
        state: savedState,
        city: savedCity,
        listingTypes: savedTypes,
        searchQuery: savedSearch,
        userLocation: savedUserLocation,
        radius: savedRadius,
      );

      // Sync with location provider but don't overwrite saved filters
      _syncWithLocationProvider();
      _applyFilters();

      AppLogger.info(
        'Loaded ${_allListings.length} merchant listings, HasMore: $_hasMore',
      );
    } catch (e) {
      _error = 'Failed to load listings: $e';
      AppLogger.error('Error loading merchant listings: $e');

      if (_allListings.isEmpty) {
        await _fallbackLoadAllListings(refresh);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fallbackLoadAllListings(bool refresh) async {
    try {
      AppLogger.info('Attempting fallback: loading all listings');
      final allListings = await _apiService.getAllMerchantListings();

      if (refresh || _currentPage == 0) {
        _allListings = allListings;
      } else {
        _allListings.addAll(allListings);
      }

      // Load locations for the listings
      await _loadLocationsForListings(_allListings);

      _hasMore = false;
      _lastLoadedAt = DateTime.now();
      _syncWithLocationProvider();
      _applyFilters();
      AppLogger.info('Fallback loaded ${_allListings.length} listings');
    } catch (fallbackError) {
      AppLogger.error('Fallback also failed: $fallbackError');
    }
  }

  Future<void> loadMore() async {
    if (_isDisposed) return;
    if (_isLoadingMore || !_hasMore) return;
    if (_allListings.isEmpty) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      AppLogger.info('Loading more listings - Page: $_currentPage');

      final result = await _apiService.getMerchantListingsPaginated(
        _currentPage,
        _pageSize,
      );

      _allListings.addAll(result.items);

      // Load locations for new listings
      await _loadLocationsForListings(result.items);

      _hasMore = result.hasNextPage;
      _currentPage++;
      _lastLoadedAt = DateTime.now();

      _applyFilters();
      AppLogger.info(
        'Loaded more listings: ${_allListings.length} total, HasMore: $_hasMore',
      );
    } catch (e) {
      AppLogger.error('Error loading more listings: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_isDisposed) return;

    // Save current data and filter state
    final savedListings = List<MerchantListingDTO>.from(_allListings);
    final savedFilter = _currentFilter;
    final savedCountry = savedFilter.country;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      AppLogger.info('[MerchantProvider] Refreshing listings...');

      // Load fresh data
      final result = await _apiService.getMerchantListingsPaginated(
        0,
        _pageSize,
      );

      if (result.items.isNotEmpty) {
        // Update with new data
        _allListings = result.items;
        _hasMore = result.hasNextPage;
        _currentPage = 1;
        _lastLoadedAt = DateTime.now();

        // Load locations for the new listings
        await _loadLocationsForListings(_allListings);
      } else {
        // If API returns empty, keep existing data
        AppLogger.log(
          '[MerchantProvider] Refresh returned empty, keeping existing data',
        );
        // Don't clear _allListings
      }

      // Restore filter state
      _currentFilter = savedFilter.copyWith(country: savedCountry);

      // Reapply filters
      _applyFilters();

      AppLogger.info(
        '[MerchantProvider] Refresh completed: ${_allListings.length} listings, Filtered: ${_filteredListings.length}',
      );
    } catch (e) {
      _error = 'Failed to refresh: $e';
      AppLogger.error('[MerchantProvider] Refresh error: $e');

      // Restore saved data on error
      if (savedListings.isNotEmpty) {
        _allListings = savedListings;
        _applyFilters();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add this method to force a complete reload
  Future<void> forceReload() async {
    if (_isDisposed) return;

    final savedCountry = _currentFilter.country;
    final savedState = _currentFilter.state;
    final savedCity = _currentFilter.city;

    // Clear data
    _allListings.clear();
    _filteredListings.clear();
    _locationCache.clear();
    _currentPage = 0;
    _hasMore = true;
    _isInitialized = false;

    notifyListeners();

    // Load fresh data
    await initialize(forceRefresh: true);

    // Restore filters
    if (savedCountry != null) {
      _currentFilter = _currentFilter.copyWith(
        country: savedCountry,
        state: savedState,
        city: savedCity,
      );
      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_isDisposed) return;

    if (_isInitialized && !forceRefresh) {
      if (needsRefresh) {
        await _refreshInBackground();
      }
      return;
    }

    // Prevent multiple simultaneous initializations
    if (_isLoading) {
      debugPrint('[MerchantProvider] Already loading, waiting...');
      await Future.delayed(const Duration(milliseconds: 100));
      if (_isInitialized) return;
    }

    _isLoading = true;
    try {
      await loadListings(refresh: true);
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshInBackground() async {
    if (_isLoading) return;

    try {
      AppLogger.info('Background refresh started');
      final result = await _apiService.getMerchantListingsPaginated(
        0,
        _pageSize,
      );
      _allListings = result.items;
      _hasMore = result.hasNextPage;
      _currentPage = 1;
      _lastLoadedAt = DateTime.now();

      // Load locations for listings
      await _loadLocationsForListings(_allListings);

      _syncWithLocationProvider();
      _applyFilters();
      AppLogger.info(
        'Background refresh completed: ${_allListings.length} listings',
      );
    } catch (e) {
      AppLogger.error('Background refresh failed: $e');
    }
  }

  // ==================== LOCATION SYNC METHODS ====================

  void _syncWithLocationProvider() {
    if (_isDisposed) return;

    final locFilter = _locationProvider.filter;
    final hasCountry =
        locFilter.country != null && locFilter.country!.isNotEmpty;

    // Only update if there's a country or other location filter
    // AND the current filter doesn't already have a value
    if (hasCountry || locFilter.state != null || locFilter.city != null) {
      // Only update if the current filter doesn't have these values set
      // This prevents overwriting user-applied filters
      if (_currentFilter.country == null && hasCountry) {
        _currentFilter = _currentFilter.copyWith(country: locFilter.country);
      }
      if (_currentFilter.state == null && locFilter.state != null) {
        _currentFilter = _currentFilter.copyWith(state: locFilter.state);
      }
      if (_currentFilter.city == null && locFilter.city != null) {
        _currentFilter = _currentFilter.copyWith(city: locFilter.city);
      }
      // Always update user location
      _currentFilter = _currentFilter.copyWith(
        userLocation: locFilter.center,
        radius: locFilter.radiusKm ?? 10.0,
        searchQuery: locFilter.search,
      );

      _applyFilters();
      notifyListeners();
      AppLogger.info('[MerchantProvider] Synced with LocationProvider');
    }
  }

  void _onLocationChanged() {
    if (_isDisposed) return;

    final locFilter = _locationProvider.filter;

    // Always sync location filters from LocationProvider
    _currentFilter = _currentFilter.copyWith(
      country: locFilter.country,
      state: locFilter.state,
      city: locFilter.city,
      userLocation: locFilter.center,
      radius: locFilter.radiusKm ?? 10.0,
      searchQuery: locFilter.search,
    );

    _applyFilters();
    notifyListeners();
    AppLogger.info(
      '[MerchantProvider] Synced from LocationProvider change - Country: ${locFilter.country}',
    );
  }

  /// Sync with LocationProvider - call this when location changes
  void syncWithLocation() {
    if (_isDisposed) return;

    final locFilter = _locationProvider.filter;
    final hasCountry =
        locFilter.country != null && locFilter.country!.isNotEmpty;
    final hasState = locFilter.state != null && locFilter.state!.isNotEmpty;
    final hasCity = locFilter.city != null && locFilter.city!.isNotEmpty;

    // Only update if there are location filters
    if (hasCountry || hasState || hasCity) {
      _currentFilter = _currentFilter.copyWith(
        country: locFilter.country,
        state: locFilter.state,
        city: locFilter.city,
        userLocation: locFilter.center,
        radius: locFilter.radiusKm ?? 10.0,
        searchQuery: locFilter.search,
      );
      _applyFilters();
      notifyListeners();
      AppLogger.info(
        '[MerchantProvider] Synced with LocationProvider - Country: ${locFilter.country}',
      );
    }
  }

  void forceSyncWithLocation() {
    if (_isDisposed) return;

    final locFilter = _locationProvider.filter;

    // Force update all location filters
    _currentFilter = _currentFilter.copyWith(
      country: locFilter.country,
      state: locFilter.state,
      city: locFilter.city,
      userLocation: locFilter.center,
      radius: locFilter.radiusKm ?? 10.0,
      searchQuery: locFilter.search,
    );

    _applyFilters();
    notifyListeners();
    AppLogger.info(
      '[MerchantProvider] Force synced with LocationProvider - Country: ${locFilter.country}',
    );
  }

  /// Check if location has changed since last sync
  bool hasLocationChanged() {
    final locFilter = _locationProvider.filter;
    return _currentFilter.country != locFilter.country ||
        _currentFilter.state != locFilter.state ||
        _currentFilter.city != locFilter.city;
  }

  // ==================== RESET FILTERS ====================

  void resetFilters() {
    if (_isDisposed) return;
    _currentFilter = const MerchantListingFilter();
    _listingsFilter = const ListingsFilter();
    _locationProvider.setCountry(null);
    _debounceTimer?.cancel();

    // Also clear user location filter
    _currentFilter = _currentFilter.copyWith(userLocation: null, radius: null);

    _applyFilters();
    notifyListeners();
    AppLogger.info('All filters reset');
  }

  void setActiveCountry(String? country) {
    if (_isDisposed) return;

    _locationProvider.setCountry(country);
    _currentFilter = _currentFilter.copyWith(
      country: country,
      state: null,
      city: null,
    );

    _applyFilters();
    notifyListeners();
    AppLogger.info('[MerchantProvider] Active country set to: $country');
  }

  /// Clear all filters (convenience method)
  void clearFilters() {
    if (_isDisposed) return;
    resetFilters();
  }

  /// Set the country (alias for setActiveCountry for backward compatibility)
  void setCountry(String? country) {
    setActiveCountry(country);
  }

  // ==================== FILTER METHODS ====================

  void setStateFilter(String? state) {
    if (_isDisposed) return;
    _currentFilter = _currentFilter.copyWith(state: state);
    _applyFilters();
    notifyListeners();
    AppLogger.info('State filter set to: $state');
  }

  void setCityFilter(String? city) {
    if (_isDisposed) return;
    _currentFilter = _currentFilter.copyWith(city: city);
    _applyFilters();
    notifyListeners();
    AppLogger.info('City filter set to: $city');
  }

  void setSearchQuery(String? query) {
    if (_isDisposed) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (!_isDisposed) {
        _currentFilter = _currentFilter.copyWith(searchQuery: query?.trim());
        _applyFilters();
        notifyListeners();
        AppLogger.info('Search query applied: $query');
      }
    });
    // Immediate notify for UI update
    notifyListeners();
  }

  void setListingTypes(List<ListingType>? types) {
    if (_isDisposed) return;
    _currentFilter = _currentFilter.copyWith(listingTypes: types);
    _applyFilters();
    notifyListeners();
    AppLogger.info('Listing types filter set to: $types');
  }

  void toggleListingType(ListingType type) {
    if (_isDisposed) return;

    final currentTypes = _currentFilter.listingTypes ?? [];
    final newTypes = currentTypes.contains(type)
        ? currentTypes.where((t) => t != type).toList()
        : [...currentTypes, type];

    _currentFilter = _currentFilter.copyWith(
      listingTypes: newTypes.isEmpty ? null : newTypes,
    );
    _applyFilters();
    notifyListeners();
    AppLogger.info('Toggled listing type: $type');
  }

  void setOrganizationId(String? organizationId) {
    if (_isDisposed) return;
    _currentFilter = _currentFilter.copyWith(organizationId: organizationId);
    _applyFilters();
    notifyListeners();
    AppLogger.info('Organization filter set to: $organizationId');
  }

  void setUserLocation(LatLng? location, {double? radius}) {
    if (_isDisposed) return;
    _currentFilter = _currentFilter.copyWith(
      userLocation: location,
      radius: radius ?? _currentFilter.radius ?? 10.0,
    );
    _applyFilters();
    notifyListeners();
    AppLogger.info(
      'User location set: ${location?.latitude}, ${location?.longitude}',
    );
  }

  void setRadius(double? radius) {
    if (_isDisposed) return;
    _currentFilter = _currentFilter.copyWith(radius: radius);
    _applyFilters();
    notifyListeners();
  }

  void setSortBy(String? sortBy) {
    if (_isDisposed) return;
    _currentFilter = _currentFilter.copyWith(sortBy: sortBy);
    _applyFilters();
    notifyListeners();
  }

  // ---- ListingsFilter methods ----

  void setListingsFilterType(ListingType? type) {
    if (_isDisposed) return;
    _listingsFilter = _listingsFilter.copyWith(listingType: type);
    _applyFilters();
    notifyListeners();
  }

  void setListingsFilterActiveOnly(bool? activeOnly) {
    if (_isDisposed) return;
    _listingsFilter = _listingsFilter.copyWith(isActiveOnly: activeOnly);
    _applyFilters();
    notifyListeners();
  }

  void setListingsFilterDateRange({DateTime? startDate, DateTime? endDate}) {
    if (_isDisposed) return;
    _listingsFilter = _listingsFilter.copyWith(
      startDate: startDate,
      endDate: endDate,
    );
    _applyFilters();
    notifyListeners();
  }

  void clearListingsFilterDateRange() {
    if (_isDisposed) return;
    _listingsFilter = _listingsFilter.copyWith(startDate: null, endDate: null);
    _applyFilters();
    notifyListeners();
  }

  void setListingsFilterHasLocation(bool? hasLocation) {
    if (_isDisposed) return;
    _listingsFilter = _listingsFilter.copyWith(hasLocation: hasLocation);
    _applyFilters();
    notifyListeners();
  }

  // ---- Combined filter methods ----

  void updateFilter(
    MerchantListingFilter filter, {
    ListingsFilter? listingsFilter,
  }) {
    if (_isDisposed) return;

    _currentFilter = filter;
    if (listingsFilter != null) {
      _listingsFilter = listingsFilter;
    }

    _applyFilters();
    notifyListeners();
  }

  void updateListingsFilter(ListingsFilter filter) {
    if (_isDisposed) return;
    _listingsFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  // ==================== PRIVATE METHODS ====================

  void _applyFilters() {
    if (_isDisposed) return;

    if (_allListings.isEmpty) {
      _filteredListings = [];
      notifyListeners();
      return;
    }

    var filtered = List<MerchantListingDTO>.from(_allListings);

    // ===== Apply Country filter (from LocationProvider via currentFilter) =====
    final country = _currentFilter.country;
    if (country != null && country.isNotEmpty) {
      filtered = filtered.where((listing) {
        final location = _locationCache[listing.locationid];
        if (location == null) return false;
        final listingCountry = location.address.country;
        return listingCountry.toLowerCase() == country.toLowerCase();
      }).toList();
      AppLogger.log(
        '[MerchantProvider] Filtered by country: $country, found ${filtered.length} listings',
      );
    }

    // Search filter
    final searchQuery = _currentFilter.searchQuery;
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((l) {
        final titleMatch = l.title.toLowerCase().contains(query);
        final descMatch = l.description?.toLowerCase().contains(query) ?? false;
        final location = _locationCache[l.locationid];
        final locationMatch =
            location != null &&
            (location.address.city.toLowerCase().contains(query) ||
                location.address.state.toLowerCase().contains(query) ||
                location.address.country.toLowerCase().contains(query));
        return titleMatch || descMatch || locationMatch;
      }).toList();
    }

    // Listing types filter (from merchant filter)
    final types = _currentFilter.listingTypes;
    if (types != null && types.isNotEmpty) {
      filtered = filtered.where((l) => types.contains(l.type)).toList();
    }

    // Organization filter
    final orgId = _currentFilter.organizationId;
    if (orgId != null && orgId.isNotEmpty) {
      filtered = filtered.where((l) => l.organizationId == orgId).toList();
    }

    // State filter
    final state = _currentFilter.state;
    if (state != null && state.isNotEmpty) {
      filtered = filtered.where((l) {
        final location = _locationCache[l.locationid];
        return location?.address.state.toLowerCase() == state.toLowerCase();
      }).toList();
    }

    // City filter
    final city = _currentFilter.city;
    if (city != null && city.isNotEmpty) {
      filtered = filtered.where((l) {
        final location = _locationCache[l.locationid];
        return location?.address.city.toLowerCase() == city.toLowerCase();
      }).toList();
    }

    // User location radius filter
    final userLocation = _currentFilter.userLocation;
    final radius = _currentFilter.radius;
    if (userLocation != null && radius != null && radius > 0) {
      filtered = filtered.where((l) {
        final location = _locationCache[l.locationid];
        if (location == null) return false;
        final distance = _calculateDistance(
          userLocation.latitude,
          userLocation.longitude,
          location.coordinates.latitude,
          location.coordinates.longitude,
        );
        return distance <= radius;
      }).toList();
    }

    // ===== Apply ListingsFilter =====

    // Listing type filter (from listings filter)
    if (_listingsFilter.listingType != null) {
      filtered = filtered
          .where((l) => l.type == _listingsFilter.listingType)
          .toList();
    }

    // Active only filter
    if (_listingsFilter.isActiveOnly == true) {
      filtered = filtered.where((l) => l.isActive).toList();
    }

    // Date range filters
    if (_listingsFilter.startDate != null) {
      filtered = filtered.where((l) {
        if (l.startDate == null) return false;
        return l.startDate!.isAfter(_listingsFilter.startDate!) ||
            l.startDate!.isAtSameMomentAs(_listingsFilter.startDate!);
      }).toList();
    }
    if (_listingsFilter.endDate != null) {
      filtered = filtered.where((l) {
        if (l.endDate == null) return false;
        return l.endDate!.isBefore(_listingsFilter.endDate!) ||
            l.endDate!.isAtSameMomentAs(_listingsFilter.endDate!);
      }).toList();
    }

    // Location filter (from listings filter) - additional location check
    if (_listingsFilter.hasLocation == true) {
      filtered = filtered
          .where((l) => _locationCache.containsKey(l.locationid))
          .toList();
    }

    // Apply sorting
    _applySorting(filtered);

    _filteredListings = filtered;
    AppLogger.log(
      '[MerchantProvider] Applied filters, found ${_filteredListings.length} listings',
    );
  }

  void _applySorting(List<MerchantListingDTO> list) {
    final sortBy = _currentFilter.sortBy;
    if (sortBy == null || sortBy.isEmpty) return;

    switch (sortBy.toLowerCase()) {
      case 'name_asc':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'name_desc':
        list.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'type_asc':
        list.sort((a, b) => a.type.name.compareTo(b.type.name));
        break;
      case 'type_desc':
        list.sort((a, b) => b.type.name.compareTo(a.type.name));
        break;
      case 'status_asc':
        list.sort((a, b) => a.status.name.compareTo(b.status.name));
        break;
      case 'status_desc':
        list.sort((a, b) => b.status.name.compareTo(a.status.name));
        break;
      case 'distance_asc':
      case 'distance':
        final userLocation = _currentFilter.userLocation;
        if (userLocation != null) {
          list.sort((a, b) {
            final locA = _locationCache[a.locationid];
            final locB = _locationCache[b.locationid];
            final distA = locA != null
                ? _calculateDistance(
                    userLocation.latitude,
                    userLocation.longitude,
                    locA.coordinates.latitude,
                    locA.coordinates.longitude,
                  )
                : double.infinity;
            final distB = locB != null
                ? _calculateDistance(
                    userLocation.latitude,
                    userLocation.longitude,
                    locB.coordinates.latitude,
                    locB.coordinates.longitude,
                  )
                : double.infinity;
            return distA.compareTo(distB);
          });
        }
        break;
      case 'distance_desc':
        final userLocation = _currentFilter.userLocation;
        if (userLocation != null) {
          list.sort((a, b) {
            final locA = _locationCache[a.locationid];
            final locB = _locationCache[b.locationid];
            final distA = locA != null
                ? _calculateDistance(
                    userLocation.latitude,
                    userLocation.longitude,
                    locA.coordinates.latitude,
                    locA.coordinates.longitude,
                  )
                : double.infinity;
            final distB = locB != null
                ? _calculateDistance(
                    userLocation.latitude,
                    userLocation.longitude,
                    locB.coordinates.latitude,
                    locB.coordinates.longitude,
                  )
                : double.infinity;
            return distB.compareTo(distA);
          });
        }
        break;
      case 'createdat':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'updatedat':
        list.sort((a, b) {
          final aUpdated = a.updatedAt ?? a.createdAt;
          final bUpdated = b.updatedAt ?? b.createdAt;
          return bUpdated.compareTo(aUpdated);
        });
        break;
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371; // km

    final lat1Rad = lat1 * pi / 180;
    final lon1Rad = lon1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;
    final lon2Rad = lon2 * pi / 180;

    final dLat = lat2Rad - lat1Rad;
    final dLon = lon2Rad - lon1Rad;

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // ==================== DISTANCE METHODS ====================

  /// Get distance from current user location to a listing
  double getDistanceToListing(MerchantListingDTO listing) {
    if (_currentFilter.userLocation == null) return double.infinity;

    final location = _locationCache[listing.locationid];
    if (location == null) return double.infinity;

    return _calculateDistance(
      _currentFilter.userLocation!.latitude,
      _currentFilter.userLocation!.longitude,
      location.coordinates.latitude,
      location.coordinates.longitude,
    );
  }

  /// Check if a listing is nearby based on current user location
  bool isListingNearby(MerchantListingDTO listing) {
    if (_currentFilter.userLocation == null) return false;

    final location = _locationCache[listing.locationid];
    if (location == null) return false;

    final distance = getDistanceToListing(listing);
    final radius = _currentFilter.radius ?? 10.0;
    return distance <= radius;
  }

  /// Calculate distance between two coordinates in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return _calculateDistance(lat1, lon1, lat2, lon2);
  }

  // ==================== UTILITY METHODS ====================

  MerchantListingDTO? getListingById(String id) {
    try {
      return _filteredListings.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  List<MerchantListingDTO> get listingsWithLocation => _filteredListings
      .where((l) => _locationCache.containsKey(l.locationid))
      .toList();

  // ==================== DISPOSAL ====================
  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();

    if (_locationListener != null) {
      _locationProvider.removeListener(_locationListener!);
      _locationListener = null;
    }

    super.dispose();
  }
}
