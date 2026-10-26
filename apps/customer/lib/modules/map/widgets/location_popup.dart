import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';

// lib/customer/modules/map/widgets/location_popup.dart

import 'package:lehwipalancecustomerv1/enum.dart';

// ==================== MAP POPUP SERVICE ====================

class MapPopupService {
  final PopupController popupController;

  MapPopupService({required this.popupController});

  /// Build popup layer options
  PopupMarkerLayerOptions buildPopupOptions({
    required List<Marker> markers,
    required List<LocationModel> locations,
    required Function(LocationModel) onSelectLocation,
    required Function(LocationModel) onOpenDirections,
    required Function(LocationModel) onShowDetails,
    required BuildContext context,
  }) {
    return PopupMarkerLayerOptions(
      popupController: popupController,
      markers: markers,
      popupDisplayOptions: PopupDisplayOptions(
        builder: (context, marker) {
          final matchingLocation = _findMatchingLocation(marker, locations);
          final provider = GetIt.I.get<LocationProvider>();
          final distance = provider.getDistanceToLocation(matchingLocation);

          return LocationPopupCard(
            location: matchingLocation,
            distance: distance?.isFinite == true ? distance : null,
            onSelect: () => onSelectLocation(matchingLocation),
            onDirections: () => onOpenDirections(matchingLocation),
            onDetails: () {
              popupController.hideAllPopups();
              onShowDetails(matchingLocation);
            },
            childCount: getChildLocationCount(matchingLocation),
            onChildList: () {
              // Get child locations from the provider
              // final childLocations = provider.getChildLocations(matchingLocation.id);
              /*
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LocationListSheet(
                    childLocations: childLocations,
                    isLoadingMore: provider.isLoading,
                    hasMore: false,
                    onLoadMore: () => provider.loadAllLocations(),
                  ),
                ),
              );
              */
            },
          );
        },
      ),
    );
  }

  LocationModel _findMatchingLocation(
    Marker marker,
    List<LocationModel> locations,
  ) {
    // Try to find by exact coordinates
    for (final location in locations) {
      if (location.latitude == marker.point.latitude &&
          location.longitude == marker.point.longitude) {
        return location;
      }
    }
    // Fallback to first location
    return locations.first;
  }

  /// Toggle popup for a specific marker
  void togglePopup(Marker marker) {
    popupController.togglePopup(marker);
  }

  /// Hide all popups
  void hideAllPopups() {
    popupController.hideAllPopups();
  }

  int getChildLocationCount(LocationModel location) {
    // If LocationModel has child locations, return count
    // Otherwise return 0
    return location.childListings?.length ?? 0;
  }
}

// ==================== LOCATION POPUP CARD ====================

class LocationPopupCard extends StatelessWidget {
  final LocationModel location;
  final double? distance;
  final VoidCallback onSelect;
  final VoidCallback onDirections;
  final VoidCallback onDetails;
  final VoidCallback? onChildList;
  final int? childCount;

  const LocationPopupCard({
    super.key,
    required this.location,
    this.distance,
    required this.onSelect,
    required this.onDirections,
    required this.onDetails,
    this.onChildList,
    this.childCount,
  });
  String _getTypeLabel() => location.listingType.label;
  Color _getTypeColor() => location.listingType.color;

  String _getFullAddress() {
    final parts = <String>[];
    if (location.address.street.isNotEmpty) {
      parts.add(location.address.street);
    }
    if (location.address.city.isNotEmpty) {
      parts.add(location.address.city);
    }
    if (location.address.state.isNotEmpty) {
      parts.add(location.address.state);
    }
    if (location.address.country.isNotEmpty) {
      parts.add(location.address.country);
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Location not specified';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== IMAGE ====================
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: location.imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.image_not_supported,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ==================== TITLE + TYPE BADGE ====================
            Row(
              children: [
                Expanded(
                  child: Text(
                    location.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _getTypeColor()),
                  ),
                  child: Text(
                    _getTypeLabel(),
                    style: TextStyle(
                      fontSize: 10,
                      color: _getTypeColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ==================== ADDRESS ====================
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getFullAddress(),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ==================== ACTIONS ====================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Distance
                if (distance != null && distance!.isFinite)
                  Row(
                    children: [
                      Icon(
                        Icons.directions_walk,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${distance!.toStringAsFixed(1)} km',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                // Action Buttons
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.directions, size: 18),
                      onPressed: onDirections,
                      color: Colors.blue,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 18),
                      onPressed: onDetails,
                      color: Colors.blue,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    if (childCount != null && onChildList != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.list, size: 18),
                        onPressed: onChildList,
                        color: Colors.blue,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),

            // ==================== STATUS ====================
            Row(
              children: [
                SizedBox(width: 6, height: 6),
                const SizedBox(width: 4),
                if (childCount != null && childCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$childCount Listings',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
