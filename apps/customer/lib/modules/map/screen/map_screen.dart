import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/map/screen/map_view.dart';
import 'package:provider/provider.dart';

class MerchantMapScreen extends StatelessWidget {
  final String? initialLocationId;
  final ListingType? initialListingType;
  final double? initialLat;
  final double? initialLng;

  const MerchantMapScreen({
    super.key,
    this.initialLocationId,
    this.initialListingType,
    this.initialLat,
    this.initialLng,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LocationProvider(),
      child: MerchantListingMapView(
        initialZoom: 12,
        showSearch: true,
        showUserLocation: true,
        initialLocationId: initialLocationId,
        initialListingType: initialListingType,
        initialCenter: (initialLat != null && initialLng != null)
            ? LatLng(initialLat!, initialLng!)
            : null,
      ),
    );
  }
}
