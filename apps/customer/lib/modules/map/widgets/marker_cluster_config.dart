// lib/customer/modules/map/services/marker_cluster_config.dart
/*
import 'package:flutter/material.dart';
// lib/customer/modules/map/services/marker_cluster_service.dart

// lib/customer/modules/map/services/marker_cluster_service.dart

 
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehwipalancecustomerv1/core/constants/enums/enums.dart';
import 'package:lehwipalancecustomerv1/customer/modules/map/screen/map_view.dart';
import 'package:lehwipalancecustomerv1/customer/modules/map/widgets/location_marker.dart';
 

class MarkerClusterConfig {
  final double maxClusterRadius;
  final Size clusterSize;
  final EdgeInsets fitPadding;
  final Duration debounceDuration;
  final bool enableSpiderfy;
  final int minZoomForIndividualMarkers;

  const MarkerClusterConfig({
    this.maxClusterRadius = 80,
    this.clusterSize = const Size(50, 50),
    this.fitPadding = const EdgeInsets.all(80),
    this.debounceDuration = const Duration(milliseconds: 100),
    this.enableSpiderfy = true,
    this.minZoomForIndividualMarkers = 15,
  });

  /// Get cluster radius based on zoom level
  double getClusterRadius(double zoom) {
    if (zoom <= 6) return 120;
    if (zoom <= 10) return 90;
    if (zoom <= 13) return 60;
    return 40;
  }

  /// Check if we should show individual markers
  bool shouldShowIndividualMarkers(double zoom) {
    return zoom >= minZoomForIndividualMarkers;
  }

  factory MarkerClusterConfig.defaultConfig() => const MarkerClusterConfig();
}
/// Service for efficient marker clustering using pixel-based algorithms
class MarkerClusterService {
  final MarkerClusterConfig config;
  
  // Cache for performance
  double? _lastZoom;
  LatLngBounds? _lastBounds;
  List<Marker>? _cachedMarkers;
  MapController? _mapController;
  
  MarkerClusterService({MarkerClusterConfig? config})
      : config = config ?? MarkerClusterConfig.defaultConfig();

  /// Build clustered markers with caching
  List<Marker> buildClusters({
    required List<Marker> markers,
    required MapController controller,
    required double zoom,
    LatLngBounds? visibleBounds,
  }) {
    // Update controller reference
    _mapController = controller;

    // Check cache
    if (_shouldUseCache(zoom, visibleBounds)) {
      return _cachedMarkers!;
    }

    // If no markers or high zoom, return individual markers
    if (markers.isEmpty) {
      _updateCache(zoom, visibleBounds, markers);
      return markers;
    }

    if (config.shouldShowIndividualMarkers(zoom)) {
      _updateCache(zoom, visibleBounds, markers);
      return markers;
    }

    // Build clusters
    final clusteredMarkers = _buildClustersInternal(markers, zoom);
    _updateCache(zoom, visibleBounds, clusteredMarkers);
    return clusteredMarkers;
  }

  /// Internal clustering algorithm
  List<Marker> _buildClustersInternal(List<Marker> markers, double zoom) {
    if (markers.isEmpty) return markers;

    final radius = config.getClusterRadius(zoom);
    final clusters = <List<Marker>>[];
    final visited = <Marker>{};

    // Pre-calculate offsets for all markers to avoid repeated calculations
    final markerOffsets = <Marker, Offset>{};
    for (final marker in markers) {
      markerOffsets[marker] = _latLngToOffset(marker.point);
    }

    for (final marker in markers) {
      if (visited.contains(marker)) continue;

      final cluster = <Marker>[marker];
      visited.add(marker);

      final p1 = markerOffsets[marker]!;

      for (final other in markers) {
        if (visited.contains(other)) continue;

        final p2 = markerOffsets[other]!;
        final distance = (p1 - p2).distance;

        if (distance < radius) {
          cluster.add(other);
          visited.add(other);
        }
      }

      clusters.add(cluster);
    }

    // Build cluster markers
    return clusters.map((cluster) => _createClusterMarker(cluster)).toList();
  }

  /// Convert LatLng to screen offset
  Offset _latLngToOffset(LatLng point) {
    if (_mapController == null) {
      // Fallback using a simple projection if controller is not available
      return Offset(point.longitude * 100, point.latitude * 100);
    }
    
    final projected = _mapController!.camera.project(point);
    return Offset(projected.x.toDouble(), projected.y.toDouble());
  }

  /// Create a cluster marker
  Marker _createClusterMarker(List<Marker> cluster) {
    if (cluster.length == 1) {
      return cluster.first;
    }

    // Calculate center
    final center = LatLng(
      cluster.map((e) => e.point.latitude).reduce((a, b) => a + b) /
          cluster.length,
      cluster.map((e) => e.point.longitude).reduce((a, b) => a + b) /
          cluster.length,
    );

    // Get cluster color based on types
    final color = _getClusterColor(cluster);
    final count = cluster.length;

    return Marker(
      point: center,
      width: config.clusterSize.width,
      height: config.clusterSize.height,
      child: ClusterMarkerWidget(
        count: count,
        point: center,
        color: color,
        onTap: () => _zoomToCluster(cluster),
        markers: config.enableSpiderfy ? cluster : null,
      ),
    );
  }

  /// Zoom to cluster bounds
  void _zoomToCluster(List<Marker> cluster) {
    if (_mapController == null) return;

    final bounds = LatLngBounds.fromPoints(
      cluster.map((e) => e.point).toList(),
    );

    _mapController!.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: config.fitPadding,
      ),
    );
  }

  /// Get cluster color based on marker types
  Color _getClusterColor(List<Marker> cluster) {
    if (cluster.isEmpty) return Colors.blue;

    // Try to get color from first marker
    try {
      final firstMarker = cluster.first.child;
      if (firstMarker is MerchantListingMarker) {
        return _getTypeColor(firstMarker.listing.type);
      }
      if (firstMarker is ClusterMarkerWidget) {
        return firstMarker.color ?? Colors.blue;
      }
    } catch (_) {}

    // Fallback based on count
    final count = cluster.length;
    if (count < 5) return Colors.blue;
    if (count < 10) return Colors.green;
    if (count < 20) return Colors.orange;
    if (count < 50) return Colors.purple;
    return Colors.red;
  }

  Color _getTypeColor(ListingType type) {
    switch (type) {
      case ListingType.event:
        return Colors.purple;
      case ListingType.place:
        return Colors.green;
      case ListingType.hotel:
        return Colors.blue;
      case ListingType.service:
        return Colors.orange;
    }
  }

  /// Cache management
  bool _shouldUseCache(double zoom, LatLngBounds? bounds) {
    if (_cachedMarkers == null) return false;
    if (_lastZoom == null || _lastBounds == null) return false;
    
    // Check if zoom changed significantly
    if ((_lastZoom! - zoom).abs() > 0.5) return false;
    
    // Check if bounds changed
    if (bounds != null && _lastBounds != null) {
      // Calculate area using LatLngBounds directly
      final currentArea = _calculateArea(bounds);
      final lastArea = _calculateArea(_lastBounds!);
      
      // If area changed more than 20%, rebuild
      if (lastArea > 0 && currentArea / lastArea > 1.2) {
        return false;
      }
      if (lastArea > 0 && lastArea / currentArea > 1.2) {
        return false;
      }
    }
    
    return true;
  }

  void _updateCache(double zoom, LatLngBounds? bounds, List<Marker> markers) {
    _lastZoom = zoom;
    _lastBounds = bounds;
    _cachedMarkers = markers;
  }

  double _calculateArea(LatLngBounds bounds) {
    final width = bounds.east - bounds.west;
    final height = bounds.north - bounds.south;
    return width * height;
  }

  /// Clear cache when needed
  void clearCache() {
    _lastZoom = null;
    _lastBounds = null;
    _cachedMarkers = null;
  }

  /// Dispose service
  void dispose() {
    clearCache();
    _mapController = null;
  }
}
 */
