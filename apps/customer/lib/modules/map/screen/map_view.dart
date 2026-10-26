// merchant_listing_map_view.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';
import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/map/helper/map_constant.dart';
import 'package:lehwipalancecustomerv1/modules/map/widgets/location_details.dart';
import 'package:lehwipalancecustomerv1/modules/map/widgets/location_marker.dart';
import 'package:lehwipalancecustomerv1/modules/map/widgets/location_popup.dart';
import 'package:lehwipalancecustomerv1/modules/map/widgets/map_controls.dart';
import 'package:lehwipalancecustomerv1/modules/map/widgets/merchant_listing_filter_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/utils/logutil.dart';

// ==================== MAIN MAP VIEW ====================

// lib/customer/modules/map/merchant_listing_map_view.dart

// lib/customer/modules/map/merchant_listing_map_view.dart

// ==================== MAIN MAP VIEW ====================

class MerchantListingMapView extends StatefulWidget {
  final String? initialLocationId;
  final ListingType? initialListingType;
  final String? organizationId;
  final Function(LocationModel)? onLocationSelected;
  final bool showSearch;
  final bool showUserLocation;
  final LatLng? initialCenter;
  final double initialZoom;

  const MerchantListingMapView({
    super.key,
    this.initialLocationId,
    this.initialListingType,
    this.organizationId,
    this.onLocationSelected,
    this.showSearch = true,
    this.showUserLocation = true,
    this.initialCenter,
    this.initialZoom = MapConstants.defaultZoom,
  });

  @override
  State<MerchantListingMapView> createState() => _MerchantListingMapViewState();
}

class _MerchantListingMapViewState extends State<MerchantListingMapView>
    with SingleTickerProviderStateMixin {
  // ==================== CONTROLLERS ====================
  final MapController _mapController = MapController();
  final PopupController _popupController = PopupController();
  final TextEditingController _searchController = TextEditingController();
  late MapPopupService _popupService;

  // ==================== PROVIDERS ====================
  late LocationProvider _locationProvider;

  // ==================== ANIMATION ====================
  late AnimationController _animationController;
  late Animation<double> _markerScaleAnimation;

  // ==================== STATE ====================
  LatLng? _currentUserLocation;
  LocationModel? _selectedLocation;
  Marker? _userLocationMarker;
  List<Marker> _markers = [];
  double _zoomLevel = MapConstants.defaultZoom;
  bool _isLoadingLocation = false;

  bool _isUsingDefaultLocation = true;

  Timer? _debounceTimer;
  bool _isInitialized = false;
  bool _isDisposed = false;

  // Location listener
  VoidCallback? _locationListener;

  // Zoom thresholds for hierarchical clustering
  static const double _countryZoomThreshold = 4.0;
  static const double _stateZoomThreshold = 7.0;
  static const double _cityZoomThreshold = 10.0;
  static const double _individualZoomThreshold = 13.0;

  // ==================== LIFECYCLE ====================

  @override
  void initState() {
    super.initState();
    _zoomLevel = widget.initialZoom;
    _setupAnimations();
    _popupService = MapPopupService(popupController: _popupController);

    _locationProvider = getIt<LocationProvider>();

    // Add location listener
    _locationListener = () {
      if (!_isDisposed && mounted) {
        _onLocationChanged();
      }
    };
    _locationProvider.addListener(_locationListener!);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFilters();
      _initializeLocation();
      _selectInitialLocation();
      _isInitialized = true;
      _updateMarkers();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized && !_isDisposed) {
      _updateMarkers();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _mapController.dispose();
    _popupController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    _debounceTimer?.cancel();

    if (_locationListener != null) {
      _locationProvider.removeListener(_locationListener!);
      _locationListener = null;
    }

    super.dispose();
  }

  // ==================== LISTENERS ====================

  void _onLocationChanged() {
    if (_isDisposed || !mounted) return;

    // Update user location marker if available
    if (_locationProvider.hasDeviceLocation) {
      final pos = _locationProvider.devicePosition!;
      _currentUserLocation = LatLng(pos.latitude, pos.longitude);
      _addUserLocationMarker();
      _isUsingDefaultLocation = false;
    }

    _updateMarkers();
  }

  // ==================== INITIALIZATION ====================

  void _initializeFilters() {
    // Apply organization filter if provided
    if (widget.organizationId != null) {
      // If LocationProvider has a way to filter by organization, apply it
      // Otherwise, we can use custom filter
      /*
      _locationProvider.updateFilter(
        _locationProvider.filter.copyWith(
          customFilter: (location) => location.organizationId == widget.organizationId,
        ),
      );
      */
    }

    // Apply listing type filter if provided
    if (widget.initialListingType != null) {
      _locationProvider.updateFilter(
        _locationProvider.filter.copyWith(
          customFilter: (location) =>
              location.listingType == widget.initialListingType,
        ),
      );
    }
  }

  void _initializeLocation() {
    if (widget.showUserLocation && _locationProvider.hasDeviceLocation) {
      final pos = _locationProvider.devicePosition!;
      _currentUserLocation = LatLng(pos.latitude, pos.longitude);
      _isUsingDefaultLocation = false;
      _addUserLocationMarker();
      _centerMapOnUserLocation();
    } else if (widget.initialCenter != null) {
      _mapController.move(widget.initialCenter!, _zoomLevel);
    } else {
      _centerMapOnDefaultLocation();
    }
  }

  Future<void> _selectInitialLocation() async {
    if (widget.initialLocationId == null) return;
    await Future.delayed(const Duration(milliseconds: 800));
    if (widget.initialLocationId != null && mounted && !_isDisposed) {
      final location = _locationProvider.getById(widget.initialLocationId!);
      if (location != null) {
        _selectLocation(location);
      }
    }
  }

  // ==================== ANIMATION SETUP ====================

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _markerScaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );
  }

  // ==================== LOCATION HELPERS ====================

  bool _hasLocation(LocationModel location) {
    return location.latitude != 0 && location.longitude != 0;
  }

  // ==================== HIERARCHICAL CLUSTERING ====================

  Map<String, List<LocationModel>> _groupByCountry(
    List<LocationModel> locations,
  ) {
    final groups = <String, List<LocationModel>>{};
    for (final location in locations) {
      final country = location.address.country;
      if (country.isNotEmpty) {
        groups.putIfAbsent(country, () => []).add(location);
      }
    }
    return groups;
  }

  Map<String, List<LocationModel>> _groupByState(
    List<LocationModel> locations,
  ) {
    final groups = <String, List<LocationModel>>{};
    for (final location in locations) {
      final state = location.address.state;
      final country = location.address.country;
      if (state.isNotEmpty) {
        final key = '$country|$state';
        groups.putIfAbsent(key, () => []).add(location);
      }
    }
    return groups;
  }

  Map<String, List<LocationModel>> _groupByCity(List<LocationModel> locations) {
    final groups = <String, List<LocationModel>>{};
    for (final location in locations) {
      final city = location.address.city;
      final state = location.address.state;
      final country = location.address.country;
      if (city.isNotEmpty) {
        final key = '$country|$state|$city';
        groups.putIfAbsent(key, () => []).add(location);
      }
    }
    return groups;
  }

  LatLng _calculateCenter(List<LocationModel> locations) {
    if (locations.isEmpty) return MapConstants.defaultLocation;

    double lat = 0, lng = 0;
    int count = 0;
    for (final location in locations) {
      lat += location.latitude;
      lng += location.longitude;
      count++;
    }
    if (count == 0) return MapConstants.defaultLocation;
    return LatLng(lat / count, lng / count);
  }

  ListingType? _getPrimaryType(List<LocationModel> locations) {
    final typeCounts = <ListingType, int>{};
    for (final location in locations) {
      final type = location.listingType;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
    }
    if (typeCounts.isEmpty) return null;
    return typeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  LatLng _getCountryCentroid(String country, List<LocationModel> locations) {
    if (MapConstants.countryCentroids.containsKey(country)) {
      return MapConstants.countryCentroids[country]!;
    }
    return _calculateCenter(locations);
  }

  // ==================== BUILD CLUSTER MARKERS ====================

  Widget _buildCountryClusterMarker({
    required String countryName,
    required List<LocationModel> locations,
    required VoidCallback onTap,
  }) {
    final count = locations.length;
    final primaryType = _getPrimaryType(locations);
    final color = primaryType != null
        ? ClusterMarkerBuilder.getTypeColor(primaryType)
        : Colors.blue;

    return ClusterMarkerBuilder.buildCityCluster(
      cityName: countryName,
      count: count,
      color: color,
      onTap: onTap,
    );
  }

  Widget _buildStateClusterMarker({
    required String stateName,
    required List<LocationModel> locations,
    required VoidCallback onTap,
  }) {
    final count = locations.length;
    final primaryType = _getPrimaryType(locations);
    final color = primaryType != null
        ? ClusterMarkerBuilder.getTypeColor(primaryType)
        : Colors.blue;

    return ClusterMarkerBuilder.buildCityCluster(
      cityName: stateName,
      count: count,
      color: color,
      onTap: onTap,
    );
  }

  Widget _buildCityClusterMarker({
    required String cityName,
    required List<LocationModel> locations,
    required VoidCallback onTap,
  }) {
    final count = locations.length;
    final primaryType = _getPrimaryType(locations);
    final color = primaryType != null
        ? ClusterMarkerBuilder.getTypeColor(primaryType)
        : Colors.blue;

    return ClusterMarkerBuilder.buildCityCluster(
      cityName: cityName,
      count: count,
      color: color,
      onTap: onTap,
    );
  }

  // ==================== BUILD HIERARCHICAL MARKERS ====================

  List<Marker> _buildHierarchicalMarkers() {
    final locations = _locationProvider.locations;

    AppLogger.log(
      '[MapView] Building markers for ${locations.length} locations at zoom $_zoomLevel',
    );

    if (locations.isEmpty) return [];

    final List<Marker> markers = [];

    // ===== ZOOM LEVEL 1-4: COUNTRY LEVEL =====
    if (_zoomLevel <= _countryZoomThreshold) {
      AppLogger.log('[MapView] Showing country clusters');
      final countryGroups = _groupByCountry(locations);

      for (final entry in countryGroups.entries) {
        final country = entry.key;
        final countryLocations = entry.value;
        if (countryLocations.isEmpty) continue;

        final center = _getCountryCentroid(country, countryLocations);

        markers.add(
          Marker(
            point: center,
            width: 70,
            height: 80,
            child: _buildCountryClusterMarker(
              countryName: country,
              locations: countryLocations,
              onTap: () {
                final targetZoom = 6.0;
                _zoomLevel = targetZoom;
                _mapController.move(center, targetZoom);
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted && !_isDisposed) _updateMarkers();
                });
              },
            ),
          ),
        );
      }
      AppLogger.log('[MapView] Created ${markers.length} country clusters');
      return markers;
    }

    // ===== ZOOM LEVEL 5-7: STATE/PROVINCE LEVEL =====
    if (_zoomLevel <= _stateZoomThreshold) {
      AppLogger.log('[MapView] Showing state clusters');
      final stateGroups = _groupByState(locations);

      for (final entry in stateGroups.entries) {
        final key = entry.key;
        final stateLocations = entry.value;
        if (stateLocations.isEmpty) continue;

        final parts = key.split('|');
        final stateName = parts.length > 1 ? parts[1] : parts[0];
        final center = _calculateCenter(stateLocations);

        markers.add(
          Marker(
            point: center,
            width: 60,
            height: 70,
            child: _buildStateClusterMarker(
              stateName: stateName,
              locations: stateLocations,
              onTap: () {
                final targetZoom = 10.0;
                _zoomLevel = targetZoom;
                _mapController.move(center, targetZoom);
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted && !_isDisposed) _updateMarkers();
                });
              },
            ),
          ),
        );
      }
      AppLogger.log('[MapView] Created ${markers.length} state clusters');
      return markers;
    }

    // ===== ZOOM LEVEL 8-10: CITY LEVEL =====
    if (_zoomLevel <= _cityZoomThreshold) {
      AppLogger.log('[MapView] Showing city clusters');
      final cityGroups = _groupByCity(locations);

      for (final entry in cityGroups.entries) {
        final key = entry.key;
        final cityLocations = entry.value;
        if (cityLocations.isEmpty) continue;

        final parts = key.split('|');
        final cityName = parts.length > 2 ? parts[2] : parts[0];
        final center = _calculateCenter(cityLocations);

        markers.add(
          Marker(
            point: center,
            width: 55,
            height: 65,
            child: _buildCityClusterMarker(
              cityName: cityName,
              locations: cityLocations,
              onTap: () {
                final targetZoom = 13.0;
                _zoomLevel = targetZoom;
                _mapController.move(center, targetZoom);
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted && !_isDisposed) _updateMarkers();
                });
              },
            ),
          ),
        );
      }
      AppLogger.log('[MapView] Created ${markers.length} city clusters');
      return markers;
    }

    // ===== ZOOM LEVEL 11-12: MIXED CLUSTERING =====
    if (_zoomLevel <= _individualZoomThreshold) {
      AppLogger.log('[MapView] Showing distance-based clusters');
      final distanceClusters = _buildDistanceBasedClusters(locations);
      markers.addAll(distanceClusters);
      AppLogger.log('[MapView] Created ${markers.length} distance clusters');
      return markers;
    }

    // ===== ZOOM LEVEL 13+: INDIVIDUAL MARKERS =====
    AppLogger.log('[MapView] Showing individual markers');
    final individualMarkers = _buildIndividualMarkers(locations);
    markers.addAll(individualMarkers);
    AppLogger.log('[MapView] Created ${markers.length} individual markers');
    return markers;
  }

  // ==================== DISTANCE-BASED CLUSTERING ====================

  List<Marker> _buildDistanceBasedClusters(List<LocationModel> locations) {
    if (locations.isEmpty) return [];

    final clusters = <List<LocationModel>>[];
    final remaining = List<LocationModel>.from(locations);

    while (remaining.isNotEmpty) {
      final location = remaining.removeAt(0);
      final cluster = <LocationModel>[location];

      final toRemove = <LocationModel>[];
      for (final l in remaining) {
        final distance = _calculateDistance(
          location.latitude,
          location.longitude,
          l.latitude,
          l.longitude,
        );
        if (distance <= 1.0) {
          cluster.add(l);
          toRemove.add(l);
        }
      }

      for (final l in toRemove) {
        remaining.remove(l);
      }

      clusters.add(cluster);
    }

    final markers = <Marker>[];
    for (final cluster in clusters) {
      if (cluster.length == 1) {
        final location = cluster.first;
        if (!_hasLocation(location)) continue;
        markers.add(_buildIndividualMarker(location));
      } else {
        final center = _calculateCenter(cluster);
        final count = cluster.length;
        final primaryType = _getPrimaryType(cluster);
        final color = primaryType != null
            ? ClusterMarkerBuilder.getTypeColor(primaryType)
            : Colors.blue;

        markers.add(
          Marker(
            point: center,
            width: 50,
            height: 50,
            child: ClusterMarkerBuilder.buildDistanceCluster(
              count: count,
              color: color,
              onTap: () {
                final targetZoom = (_zoomLevel + 2).clamp(
                  MapConstants.minZoom,
                  MapConstants.maxZoom,
                );
                _zoomLevel = targetZoom;
                _mapController.move(center, targetZoom);
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted && !_isDisposed) _updateMarkers();
                });
              },
            ),
          ),
        );
      }
    }

    return markers;
  }

  // ==================== INDIVIDUAL MARKERS ====================

  List<Marker> _buildIndividualMarkers(List<LocationModel> locations) {
    final markers = <Marker>[];
    for (final location in locations) {
      if (!_hasLocation(location)) continue;
      markers.add(_buildIndividualMarker(location));
    }
    return markers;
  }

  Marker _buildIndividualMarker(LocationModel location) {
    if (!_hasLocation(location)) {
      return Marker(
        point: const LatLng(0, 0),
        width: 0,
        height: 0,
        child: const SizedBox.shrink(),
      );
    }

    final isSelected = _selectedLocation?.id == location.id;
    final latLng = LatLng(location.latitude, location.longitude);

    final distance = _locationProvider.getDistanceToLocation(location);
    final isNearby = distance != null && distance <= 10.0;

    return Marker(
      point: latLng,
      width: 80,
      height: 80,
      child: LocationMarker(
        location: location,
        isSelected: isSelected,
        isNearby: isNearby,
        scale: isSelected ? _markerScaleAnimation.value : 1.0,
        onTap: () => _selectLocation(location),
      ),
    );
  }

  // ==================== UPDATE MARKERS ====================

  void _updateMarkers() {
    if (_isDisposed || !mounted) return;

    final newMarkers = _buildHierarchicalMarkers();

    if (_userLocationMarker != null) {
      newMarkers.add(_userLocationMarker!);
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  // ==================== LOCATION METHODS ====================

  Future<void> _getCurrentLocation() async {
    if (!mounted || _isDisposed) return;

    setState(() => _isLoadingLocation = true);

    try {
      final position = await _locationProvider.getDeviceLocation(
        forceRefresh: true,
      );

      if (position != null) {
        _currentUserLocation = LatLng(position.latitude, position.longitude);

        if (!mounted) return;

        setState(() {
          _isLoadingLocation = false;
          _isUsingDefaultLocation = false;
        });

        _addUserLocationMarker();
        _centerMapOnUserLocation();
      } else {
        setState(() => _isLoadingLocation = false);
        _showSnackBar('Could not get location');
        _centerMapOnDefaultLocation();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
      _showSnackBar('Could not get location');
      _centerMapOnDefaultLocation();
    }
  }

  void _addUserLocationMarker() {
    if (_currentUserLocation == null || _isDisposed) return;

    _userLocationMarker = Marker(
      point: _currentUserLocation!,
      width: 50,
      height: 50,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.blue, width: 3),
        ),
        child: const Icon(
          Icons.person_pin_circle,
          color: Colors.blue,
          size: 30,
        ),
      ),
    );

    _updateMarkers();
  }

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

  void _centerMapOnUserLocation() {
    if (_currentUserLocation != null && mounted && !_isDisposed) {
      _moveMapToLocation(_currentUserLocation!, _zoomLevel);
    }
  }

  void _centerMapOnDefaultLocation() {
    if (mounted && !_isDisposed) {
      _moveMapToLocation(MapConstants.defaultLocation, _zoomLevel);
    }
  }

  void _moveMapToLocation(LatLng location, double zoom) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_isDisposed && mounted) {
        _mapController.move(location, zoom);
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted || _isDisposed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  // ==================== LOCATION SELECTION ====================

  void _selectLocation(LocationModel location) {
    if (_isDisposed) return;

    setState(() => _selectedLocation = location);

    _animationController
      ..reset()
      ..forward();

    final latLng = LatLng(location.latitude, location.longitude);
    final targetZoom = _zoomLevel < 14 ? 14.0 : _zoomLevel;
    _mapController.move(latLng, targetZoom);

    // Find and show popup for the selected marker
    final marker = _markers.firstWhere(
      (m) =>
          m.point.latitude == location.latitude &&
          m.point.longitude == location.longitude,
      orElse: () => _markers.first,
    );
    _popupService.togglePopup(marker);

    widget.onLocationSelected?.call(location);
    _updateMarkers();
  }

  // ==================== UI METHODS ====================

  void _showFilterOptions() {
    if (_isDisposed) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LocationFilterPanel(
        provider: _locationProvider,
        onApply: (filter) {
          _locationProvider.updateFilter(filter);
          _updateMarkers();
        },
        onReset: () {
          _locationProvider.clearActiveFilter();
          _updateMarkers();
        },
      ),
    );
  }

  void _showLocationDetails(LocationModel location) {
    if (!mounted || _isDisposed) return;

    final distance = _locationProvider.getDistanceToLocation(location);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MerchantListingDetailsSheet(
        listingId: location.mainVenueId ?? '',
        distance: distance,
        onGetDirections: () => _openDirections(location),
      ),
    );
  }

  Future<void> _openDirections(LocationModel location) async {
    if (_isDisposed) return;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination='
      '${location.latitude},${location.longitude}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open directions'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleSearch(String query) {
    if (_isDisposed) return;
    _locationProvider.updateFilter(
      _locationProvider.filter.copyWith(search: query.isEmpty ? null : query),
    );
    _updateMarkers();
  }

  void _showNearbyLocations() {
    if (_isDisposed) return;

    if (_currentUserLocation != null) {
      _locationProvider.updateFilter(
        _locationProvider.filter.copyWith(
          center: LatLng(
            _currentUserLocation!.latitude,
            _currentUserLocation!.longitude,
          ),
          radiusKm: MapConstants.defaultRadius,
        ),
      );
      _locationProvider.setCountry(null);
      _centerMapOnUserLocation();
      _updateMarkers();
    } else {
      _getCurrentLocation();
    }
  }

  // ==================== BUILD MAP ====================

  Widget _buildClusteredMap() {
    final locations = _locationProvider.locations;

    final initialCenter =
        widget.initialCenter ??
        (_isUsingDefaultLocation
            ? MapConstants.defaultLocation
            : (_currentUserLocation ??
                  (locations.isNotEmpty
                      ? LatLng(
                          locations.first.latitude,
                          locations.first.longitude,
                        )
                      : MapConstants.defaultLocation)));

    final markers = _buildHierarchicalMarkers();

    final allMarkers = List<Marker>.from(markers);

    if (_userLocationMarker != null) {
      allMarkers.add(_userLocationMarker!);
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: _zoomLevel,
        minZoom: MapConstants.minZoom,
        maxZoom: MapConstants.maxZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onPositionChanged: (MapCamera camera, bool hasGesture) {
          if (hasGesture) {
            setState(() {
              _zoomLevel = camera.zoom;
            });
            _updateMarkers();
          }
        },
        onTap: (_, _) {
          _popupService.hideAllPopups();
          if (mounted) {
            setState(() {
              _selectedLocation = null;
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: MapConstants.tileLayerUrl,
          userAgentPackageName: MapConstants.userAgent,
          tileDimension: 256,
          maxZoom: 19,
          additionalOptions: const {
            'referer': MapConstants.referer,
            'User-Agent': MapConstants.userAgent,
          },
        ),
        MarkerLayer(markers: allMarkers),
        PopupMarkerLayer(
          options: _popupService.buildPopupOptions(
            markers: allMarkers,
            locations: locations,
            onSelectLocation: _selectLocation,
            onOpenDirections: _openDirections,
            onShowDetails: _showLocationDetails,
            context: context,
          ),
        ),
      ],
    );
  }

  // ==================== BUILD UI COMPONENTS ====================

  Widget _buildSearchBar() {
    if (!widget.showSearch) return const SizedBox.shrink();

    return Positioned(
      bottom: 18, //MediaQuery.of(context).padding.top + 80,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.search, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    border: InputBorder.none,

                    hintText:
                        'Search ${_locationProvider.locations.length} locations',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onChanged: _handleSearch,
                ),
              ),
              // if (_locationProvider.activeFilterId != null)
              IconButton(
                icon: Icon(
                  Icons.filter_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: _showFilterOptions,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + (widget.showSearch ? 140 : 100),
      right: 16,
      child: MapControls(
        isUsingDefaultLocation: _isUsingDefaultLocation,
        onZoomIn: () {
          setState(() {
            _zoomLevel = (_zoomLevel + 1).clamp(
              MapConstants.minZoom,
              MapConstants.maxZoom,
            );
          });
          _mapController.move(_mapController.camera.center, _zoomLevel);
          _updateMarkers();
        },
        onZoomOut: () {
          setState(() {
            _zoomLevel = (_zoomLevel - 1).clamp(
              MapConstants.minZoom,
              MapConstants.maxZoom,
            );
          });
          _mapController.move(_mapController.camera.center, _zoomLevel);
          _updateMarkers();
        },
        onCenterLocation: () {
          if (_currentUserLocation != null && !_isUsingDefaultLocation) {
            _centerMapOnUserLocation();
          } else {
            _centerMapOnDefaultLocation();
            setState(() => _isUsingDefaultLocation = true);
          }
        },
        onShowNearbyLocations: _showNearbyLocations,
        hasSelectedLocation: _selectedLocation != null,
      ),
    );
  }

  // ==================== MAIN BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildClusteredMap()),

          _buildMapControls(),
          if (_locationProvider.isLoading || _isLoadingLocation)
            const Positioned.fill(
              child: Center(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Loading locations...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          _buildSearchBar(),
        ],
      ),
    );
  }
}
