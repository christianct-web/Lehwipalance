// lib/map/providers/merchant_listing_map_provider.dart
import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:latlong2/latlong.dart';

/// Filter for merchant listings on the map
// lib/core/models/merchant/merchant_listing_filter.dart

/// Complete filter model for merchant listings
class MerchantListingFilter {
  // Location filters (from LocationProvider)
  final String? country;
  final String? state;
  final String? city;
  final LatLng? userLocation;
  final double? radius;

  // Search & Type filters
  final String? searchQuery;
  final List<ListingType>? listingTypes;

  // Additional filters
  final String? organizationId;
  final String? sortBy;
  final bool? isActiveOnly;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minRating;
  final double? minPrice;
  final double? maxPrice;
  final List<String>? tags;

  const MerchantListingFilter({
    this.country,
    this.state,
    this.city,
    this.userLocation,
    this.radius,
    this.searchQuery,
    this.listingTypes,
    this.organizationId,
    this.sortBy,
    this.isActiveOnly,
    this.startDate,
    this.endDate,
    this.minRating,
    this.minPrice,
    this.maxPrice,
    this.tags,
  });

  // Factory methods for common filter combinations
  factory MerchantListingFilter.locationOnly({
    String? country,
    String? state,
    String? city,
    LatLng? userLocation,
    double? radius,
  }) {
    return MerchantListingFilter(
      country: country,
      state: state,
      city: city,
      userLocation: userLocation,
      radius: radius,
    );
  }

  factory MerchantListingFilter.typesOnly(List<ListingType> types) {
    return MerchantListingFilter(listingTypes: types);
  }

  factory MerchantListingFilter.dateRange(DateTime start, DateTime end) {
    return MerchantListingFilter(startDate: start, endDate: end);
  }

  factory MerchantListingFilter.priceRange(double min, double max) {
    return MerchantListingFilter(minPrice: min, maxPrice: max);
  }

  MerchantListingFilter copyWith({
    String? country,
    String? state,
    String? city,
    LatLng? userLocation,
    double? radius,
    String? searchQuery,
    List<ListingType>? listingTypes,
    String? organizationId,
    String? sortBy,
    bool? isActiveOnly,
    DateTime? startDate,
    DateTime? endDate,
    double? minRating,
    double? minPrice,
    double? maxPrice,
    List<String>? tags,
    bool clearCountry = false,
    bool clearState = false,
    bool clearCity = false,
    bool clearLocation = false,
    bool clearRadius = false,
    bool clearSearch = false,
    bool clearTypes = false,
    bool clearOrganization = false,
    bool clearSort = false,
    bool clearDateRange = false,
    bool clearPriceRange = false,
    bool clearTags = false,
  }) {
    return MerchantListingFilter(
      country: clearCountry ? null : country ?? this.country,
      state: clearState ? null : state ?? this.state,
      city: clearCity ? null : city ?? this.city,
      userLocation: clearLocation ? null : userLocation ?? this.userLocation,
      radius: clearRadius ? null : radius ?? this.radius,
      searchQuery: clearSearch ? null : searchQuery ?? this.searchQuery,
      listingTypes: clearTypes ? null : listingTypes ?? this.listingTypes,
      organizationId: clearOrganization
          ? null
          : organizationId ?? this.organizationId,
      sortBy: clearSort ? null : sortBy ?? this.sortBy,
      isActiveOnly: isActiveOnly ?? this.isActiveOnly,
      startDate: clearDateRange ? null : startDate ?? this.startDate,
      endDate: clearDateRange ? null : endDate ?? this.endDate,
      minRating: minRating ?? this.minRating,
      minPrice: clearPriceRange ? null : minPrice ?? this.minPrice,
      maxPrice: clearPriceRange ? null : maxPrice ?? this.maxPrice,
      tags: clearTags ? null : tags ?? this.tags,
    );
  }

  /// Merge with another filter (other takes precedence)
  MerchantListingFilter merge(MerchantListingFilter other) {
    return MerchantListingFilter(
      country: other.country ?? country,
      state: other.state ?? state,
      city: other.city ?? city,
      userLocation: other.userLocation ?? userLocation,
      radius: other.radius ?? radius,
      searchQuery: other.searchQuery ?? searchQuery,
      listingTypes: other.listingTypes ?? listingTypes,
      organizationId: other.organizationId ?? organizationId,
      sortBy: other.sortBy ?? sortBy,
      isActiveOnly: other.isActiveOnly ?? isActiveOnly,
      startDate: other.startDate ?? startDate,
      endDate: other.endDate ?? endDate,
      minRating: other.minRating ?? minRating,
      minPrice: other.minPrice ?? minPrice,
      maxPrice: other.maxPrice ?? maxPrice,
      tags: other.tags ?? tags,
    );
  }

  // Helper getters
  bool get isEmpty =>
      country == null &&
      state == null &&
      city == null &&
      userLocation == null &&
      radius == null &&
      (searchQuery == null || searchQuery!.isEmpty) &&
      (listingTypes == null || listingTypes!.isEmpty) &&
      organizationId == null &&
      sortBy == null &&
      isActiveOnly == null &&
      startDate == null &&
      endDate == null &&
      minRating == null &&
      minPrice == null &&
      maxPrice == null &&
      (tags == null || tags!.isEmpty);

  bool get hasFilters => !isEmpty;
  bool get hasLocationFilters =>
      country != null || state != null || city != null || userLocation != null;
  bool get hasTypeFilters => listingTypes != null && listingTypes!.isNotEmpty;
  bool get hasDateFilters => startDate != null || endDate != null;
  bool get hasPriceFilters => minPrice != null || maxPrice != null;

  @override
  String toString() {
    return 'MerchantListingFilter('
        'country: $country, state: $state, city: $city, '
        'searchQuery: $searchQuery, listingTypes: $listingTypes, '
        'organizationId: $organizationId, sortBy: $sortBy, '
        'isActiveOnly: $isActiveOnly, startDate: $startDate, endDate: $endDate, '
        'minRating: $minRating, minPrice: $minPrice, maxPrice: $maxPrice, tags: $tags)';
  }
}
