import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehwipalancecustomerv1/api_keys.dart';

import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';

import 'package:url_launcher/url_launcher.dart';

// Remove the unused import
// import 'package:lehwipalancecustomerv1/core/utils/formatters.dart';

import 'dart:math';

class LocationMapSection extends StatefulWidget {
  final LocationModel location;
  final bool interactive;
  final double height;
  final bool showDirectionsButton;
  final VoidCallback? onTap;

  const LocationMapSection({
    super.key,
    required this.location,
    this.interactive = false,
    this.height = 200,
    this.showDirectionsButton = true,
    this.onTap,
  });

  @override
  State<LocationMapSection> createState() => _LocationMapSectionState();
}

class _LocationMapSectionState extends State<LocationMapSection> {
  final MapController _mapController = MapController();
  double _zoomLevel = 15;

  @override
  void initState() {
    super.initState();
    _zoomLevel = MapUtil.defaultZoom + 3;
  }

  Widget _buildInteractiveMap() {
    final location = widget.location;
    final center = LatLng(
      location.coordinates.latitude,
      location.coordinates.longitude,
    );

    return MapUtil.buildMap(
      controller: _mapController,
      center: center,
      zoom: _zoomLevel,
      onTap: widget.onTap,
      markers: [
        MapUtil.createMarker(
          point: center,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: widget.onTap,
            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: Stack(
          children: [
            _buildInteractiveMap(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.15),
                  ],
                ),
              ),
            ),
            if (!widget.interactive && widget.onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDirections() async {
    final lat = widget.location.coordinates.latitude;
    final lng = widget.location.coordinates.longitude;
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open directions'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildMapPreview(),
          if (widget.showDirectionsButton) ...[
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _openDirections,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions, size: 18, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      'Get directions',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: Colors.blue.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.location.name.isNotEmpty)
                  Text(
                    widget.location.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                Text(
                  widget.location.fullAddress,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                if (widget.location.additionalInfo != null &&
                    widget.location.additionalInfo!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      widget.location.additionalInfo!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

// Static version without interactivity
class StaticLocationMapSection extends StatelessWidget {
  final LocationModel location;
  final double height;
  final VoidCallback? onTap;

  const StaticLocationMapSection({
    super.key,
    required this.location,
    this.height = 200,
    this.onTap,
  });

  Future<void> _openDirections() async {
    final lat = location.coordinates.latitude;
    final lng = location.coordinates.longitude;
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(
      location.coordinates.latitude,
      location.coordinates.longitude,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: height,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 14,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: _openDirections,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions, size: 18, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    'Get directions',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  location.fullAddress,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                if (location.additionalInfo != null &&
                    location.additionalInfo!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      location.additionalInfo!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapUtil {
  // Constants with meaningful names

  static const String _userAgent = 'lehwipalancecustomerv1';
  static const double defaultZoom = 12.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 19.0;
  static const LatLng defaultLocation = LatLng(6.9271, 79.8612); // Sri Lanka

  // Calculate distance between two points (Haversine formula)
  static double calculateDistance(
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

  static Widget buildMap({
    required MapController controller,
    required List<Marker> markers,
    required LatLng center,
    required double zoom,
    VoidCallback? onTap,
    ValueChanged<MapCamera>? onPositionChanged,
    List<Widget>? children,
  }) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: minZoom,
        maxZoom: maxZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
        onPositionChanged: (camera, hasGesture) {
          onPositionChanged?.call(camera);
        },
        onTap: (tapPosition, point) {
          onTap?.call();
        },
      ),
      children: [
        TileLayer(
          urlTemplate: ApiKeys.tileUrl,
          userAgentPackageName: _userAgent,
          tileDimension: 256,
          maxZoom: 19,
        ),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
        ...?children,
      ],
    );
  }

  // Create a basic marker
  static Marker createMarker({
    required LatLng point,
    required Widget child,
    double width = 50,
    double height = 50,
    Alignment alignment = Alignment.center,
  }) {
    return Marker(
      point: point,
      width: width,
      height: height,
      alignment: alignment,
      child: child,
    );
  }

  // Get a color based on listing type
  static Color getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'event':
        return Colors.purple;
      case 'place':
        return Colors.green;
      case 'hotel':
        return Colors.blue;
      case 'service':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Get an icon based on listing type
  static IconData getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'event':
        return Icons.event;
      case 'place':
        return Icons.place;
      case 'hotel':
        return Icons.hotel;
      case 'service':
        return Icons.build;
      default:
        return Icons.location_on;
    }
  }

  // Format distance for display
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }
}

// Extension for easier distance calculation
extension LatLngExtension on LatLng {
  double distanceTo(LatLng other) {
    return MapUtil.calculateDistance(
      latitude,
      longitude,
      other.latitude,
      other.longitude,
    );
  }
}
