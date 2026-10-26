import 'package:flutter/material.dart';

class MapControls extends StatelessWidget {
  final bool isUsingDefaultLocation;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onCenterLocation;

  final VoidCallback onShowNearbyLocations;
  final bool hasSelectedLocation;

  const MapControls({
    super.key,
    required this.isUsingDefaultLocation,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onCenterLocation,
    required this.onShowNearbyLocations,
    required this.hasSelectedLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          onPressed: onZoomIn,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          heroTag: 'zoom_in',
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          onPressed: onZoomOut,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          heroTag: 'zoom_out',
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          onPressed: onCenterLocation,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          heroTag: 'center_location',
          child: Icon(isUsingDefaultLocation ? Icons.flag : Icons.location_on),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          onPressed: onShowNearbyLocations,
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          heroTag: 'nearby',
          child: const Icon(Icons.near_me),
        ),
      ],
    );
  }
}
