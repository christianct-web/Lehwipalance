import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';

import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';
//import 'package:lehwipalancecustomerv1/customer/modules/map/helper/location_icons.dart';

// lib/map/services/marker_clustering_service.dart
import 'dart:math';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

// popup_service.dart

import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/map/helper/map_constant.dart';

/// Service class for building cluster markers
class ClusterMarkerBuilder {
  static const Map<ListingType, Color> typeColors = {
    ListingType.event: Color(0xFF9C27B0),
    ListingType.place: Color(0xFF4CAF50),
    ListingType.hotel: Color(0xFF2196F3),
    ListingType.service: Color(0xFFFF9800),
  };

  /// Build a city cluster marker
  static Widget buildCityCluster({
    required String cityName,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    double size = 48;
    if (count > 30) {
      size = 55;
    } else if (count > 15)
      // ignore: curly_braces_in_flow_control_structures
      size = 50;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(width: size, child: Image.asset('icon.png')),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    fontSize: count > 99 ? 8 : 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  cityName.length > 8
                      ? '${cityName.substring(0, 8)}...'
                      : cityName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a distance-based cluster marker
  static Widget buildDistanceCluster({
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    double size = 45;
    if (count > 20) {
      size = 52;
    } else if (count > 10)
      size = 48;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(width: 30, child: Image.asset('icon.png')),
            //   const Icon(Icons.location_on, color: Colors.white, size: 16),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    fontSize: count > 99 ? 8 : 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get color for a listing type
  static Color getTypeColor(ListingType type) {
    return typeColors[type] ?? Colors.blue;
  }

  /// Get primary type from a list of listings
  static ListingType? getPrimaryType(List<MerchantListingDTO> listings) {
    final typeCounts = <ListingType, int>{};
    for (final listing in listings) {
      typeCounts[listing.type] = (typeCounts[listing.type] ?? 0) + 1;
    }
    if (typeCounts.isEmpty) return null;
    return typeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// ✅ FIXED: Calculate center point using location cache
  static LatLng calculateCenterWithLocations(
    List<MerchantListingDTO> listings,
    LocationModel? Function(MerchantListingDTO listing) getLocationForListing,
  ) {
    double lat = 0, lng = 0;
    int count = 0;
    for (final listing in listings) {
      final location = getLocationForListing(listing);
      if (location != null) {
        lat += location.coordinates.latitude;
        lng += location.coordinates.longitude;
        count++;
      }
    }
    if (count == 0) return MapConstants.defaultLocation;
    return LatLng(lat / count, lng / count);
  }
}

/// Service class for managing map popups
class MerchantListingMarker extends StatelessWidget {
  final MerchantListingDTO listing;
  final bool isSelected;
  final bool isNearby;
  final double scale;
  final VoidCallback onTap;

  const MerchantListingMarker({
    super.key,
    required this.listing,
    this.isSelected = false,
    this.isNearby = false,
    this.scale = 1.0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: scale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: listing.type.color.withValues(alpha: 0.2),
                  boxShadow: [
                    BoxShadow(
                      color: listing.type.color.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            if (isNearby)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
              ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? listing.type.color : Colors.white,
                border: Border.all(
                  color: isSelected ? Colors.white : listing.type.color,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                listing.type.icon,
                color: isSelected ? Colors.white : listing.type.color,
                size: 20,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: listing.isActive ? Colors.green : Colors.red,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
///
class ClusterMarker extends StatelessWidget {
  final int count;
  final LatLng point;
  final VoidCallback onTap;
  final Color? color;
  final String? clusterType;

  const ClusterMarker({
    super.key,
    required this.count,
    required this.point,
    required this.onTap,
    this.color,
    this.clusterType,
  });

  @override
  Widget build(BuildContext context) {
    final clusterColor = color ?? _getClusterColor(count);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: clusterType != null ? 60 : 50,
        height: clusterType != null ? 60 : 50,
        decoration: BoxDecoration(
          color: clusterColor.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: clusterType == 'country' ? Colors.amber : Colors.white,
            width: clusterType == 'country' ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(width: 20, child: Image.asset('icon.png')),
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: clusterColor, width: 1.5),
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    fontSize: count > 99 ? 8 : 10,
                    fontWeight: FontWeight.bold,
                    color: clusterColor,
                  ),
                ),
              ),
            ),
            if (clusterType != null && clusterType == 'country')
              Positioned(
                bottom: -20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getClusterLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getClusterLabel() {
    return 'Country';
  }

  Color _getClusterColor(int count) {
    if (count < 5) return Colors.blue;
    if (count < 10) return Colors.green;
    if (count < 20) return Colors.orange;
    if (count < 50) return Colors.purple;
    return Colors.red;
  }
}

class MarkerClusteringService {
  static const double _clusterRadius = 0.05;

  static List<Marker> clusterMarkers({
    required List<Marker> markers,
    required double zoom,
    required LatLng bounds,
    required int maxMarkersPerCluster,
  }) {
    if (zoom >= 15) {
      return markers;
    }

    final clusters = _performClustering(markers, zoom);
    return _buildClusterMarkers(clusters);
  }

  static List<List<Marker>> _performClustering(
    List<Marker> markers,
    double zoom,
  ) {
    final radius = _clusterRadius * (15 / max(zoom, 1));

    final List<List<Marker>> clusters = [];
    final List<Marker> remaining = List.from(markers);

    while (remaining.isNotEmpty) {
      final marker = remaining.removeAt(0);
      final cluster = [marker];

      final toRemove = <Marker>[];
      for (final m in remaining) {
        final distance = _haversineDistance(
          marker.point.latitude,
          marker.point.longitude,
          m.point.latitude,
          m.point.longitude,
        );

        if (distance <= radius) {
          cluster.add(m);
          toRemove.add(m);
        }
      }

      for (final m in toRemove) {
        remaining.remove(m);
      }

      clusters.add(cluster);
    }

    return clusters;
  }

  static List<Marker> _buildClusterMarkers(List<List<Marker>> clusters) {
    return clusters.map((cluster) {
      if (cluster.length == 1) {
        return cluster.first;
      }

      double lat = 0, lng = 0;
      for (final marker in cluster) {
        lat += marker.point.latitude;
        lng += marker.point.longitude;
      }
      lat /= cluster.length;
      lng /= cluster.length;

      final center = LatLng(lat, lng);

      return Marker(
        point: center,
        width: 60,
        height: 60,
        child: ClusterMarker(
          count: cluster.length,
          point: center,
          onTap: () {},
        ),
      );
    }).toList();
  }

  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371;

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
}

class LocationMarker extends StatelessWidget {
  final LocationModel location;
  final bool isSelected;
  final bool isNearby;
  final double scale;
  final VoidCallback onTap;

  const LocationMarker({
    super.key,
    required this.location,
    required this.isSelected,
    required this.isNearby,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Transform.scale(
        scale: scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(
                  color: isNearby
                      ? Colors.green
                      : (isSelected ? Colors.blue : Colors.transparent),
                  width: 3,
                ),
              ),
              child: SizedBox(width: 30, child: Image.asset('icon.png')),
              //   Icon(
              //    LocationIcons.getLocationIcon(location),
              //    color: Colors.blue,
              //    size: 24,
              //  ),
            ),
            if (!isSelected) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isNearby ? Colors.green.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                  border: isNearby
                      ? Border.all(color: Colors.green, width: 1)
                      : null,
                ),
                child: Text(
                  location.name.split(' ').first,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isNearby ? Colors.green : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
