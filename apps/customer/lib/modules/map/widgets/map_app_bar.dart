import 'package:flutter/material.dart';

class MapAppBar extends StatelessWidget {
  final bool isUsingDefaultLocation;
  final int locationCount;
  final String? selectedCountry;
  final VoidCallback onBackPressed;
  final VoidCallback onCountryPressed;
  final VoidCallback onLocationToggle;
  final VoidCallback onQRScan;
  final VoidCallback onListToggle;
  final bool showLocationList;

  const MapAppBar({
    super.key,
    required this.isUsingDefaultLocation,
    required this.locationCount,
    required this.selectedCountry,
    required this.onBackPressed,
    required this.onCountryPressed,
    required this.onLocationToggle,
    required this.onQRScan,
    required this.onListToggle,
    required this.showLocationList,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Back button
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Flexible title section to prevent overflow
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Country/Location info
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isUsingDefaultLocation
                                ? 'Trinidad & Tobago'
                                : selectedCountry ?? 'Nearby Locations',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$locationCount locations',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Country selector button
                    IconButton(
                      icon: const Icon(Icons.expand_more),
                      onPressed: onCountryPressed,
                      iconSize: 20,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location toggle button
                IconButton(
                  icon: Icon(
                    isUsingDefaultLocation ? Icons.near_me : Icons.flag,
                  ),
                  onPressed: onLocationToggle,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  tooltip: isUsingDefaultLocation
                      ? 'Use my location'
                      : 'Default location',
                ),

                const SizedBox(width: 8),

                // QR Scan button
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: onQRScan,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  tooltip: 'Scan QR code',
                ),

                const SizedBox(width: 8),

                // List toggle button
                IconButton(
                  icon: Icon(showLocationList ? Icons.map : Icons.list),
                  onPressed: onListToggle,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  tooltip: showLocationList ? 'Show map' : 'Show list',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
