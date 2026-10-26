// lib/features/listing/widgets/media/listing_map_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_detail_provider.dart';
import 'package:lehwipalancecustomerv1/core/router/route_names.dart';
import 'package:lehwipalancecustomerv1/modules/details/widgets/common/listing_pin_tip_painter.dart';
import 'package:lehwipalancecustomerv1/modules/map/helper/map_constant.dart';

class ListingMapSection extends StatelessWidget {
  final MerchantDetailProvider provider;
  const ListingMapSection({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = provider.cachedLocation;

    if (location == null) return const SizedBox.shrink();

    final hasValidCoords = location.latitude != 0 && location.longitude != 0;
    if (!hasValidCoords) return _buildPlaceholder(context, provider);

    final listingLatLng = LatLng(location.latitude, location.longitude);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: listingLatLng,
                  initialZoom: 15.5,
                  minZoom: 3,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                  onTap: (_, _) => _openFullMap(context, provider),
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
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: listingLatLng,
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: _buildMapPin(context),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                bottom: 12,
                child: GestureDetector(
                  onTap: () => provider.handleDirectionsAction(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Directions',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(
    BuildContext context,
    MerchantDetailProvider provider,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: Stack(
            children: [
              Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 40,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Location unavailable',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: FloatingActionButton.small(
                  onPressed: () => provider.handleDirectionsAction(context),
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.primary,
                  elevation: 2,
                  child: const Icon(Icons.directions),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPin(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.storefront_rounded,
            color: theme.colorScheme.onPrimary,
            size: 18,
          ),
        ),
        Positioned(
          bottom: 0,
          child: CustomPaint(
            size: const Size(10, 8),
            painter: ListingPinTipPainter(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }

  void _openFullMap(BuildContext context, MerchantDetailProvider provider) {
    final location = provider.cachedLocation;
    final listing = provider.listing;
    if (location == null || listing == null) return;
    context.pushNamed(
      RouteNames.map,
      queryParameters: {
        'initialLocationId': location.id,
        'initialListingType': listing.type.name,
        'lat': location.latitude.toString(),
        'lng': location.longitude.toString(),
      },
    );
  }
}
