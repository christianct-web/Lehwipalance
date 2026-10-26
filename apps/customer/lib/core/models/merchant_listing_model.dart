// ignore_for_file: avoid_types_as_parameter_names, unused_local_variable

import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';

import 'package:lehwipalancecustomerv1/core/models/common_models/contact_info.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/listing_stats.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/media_model.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/opening_hour_model.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/policies_model.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/social_links.dart';
import 'package:lehwipalancecustomerv1/core/models/organisation_model.dart';
//import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

/// =====================================================
/// MERGED MERCHANT LISTING DTO
/// =====================================================
// lib/core/models/merchant_listing_model.dart

/// =====================================================
/// FACILITY / AMENITY MODEL
/// =====================================================

class ListingFacility {
  final String id;
  final String label;
  final IconData? icon;
  final String? iconName;
  final FacilityCategory category;
  final bool isHighlighted;

  const ListingFacility({
    required this.id,
    required this.label,
    this.icon,
    this.iconName,
    this.category = FacilityCategory.general,
    this.isHighlighted = false,
  });

  factory ListingFacility.fromJson(Map<String, dynamic> map) {
    return ListingFacility(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      iconName: map['iconName'],
      category: FacilityCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => FacilityCategory.general,
      ),
      isHighlighted: map['isHighlighted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'iconName': iconName,
    'category': category.name,
    'isHighlighted': isHighlighted,
  };
}

enum FacilityCategory {
  general,
  dining,
  parking,
  accessibility,
  entertainment,
  wellness,
  business,
  outdoor,
  safety,
  payment,
}

/// =====================================================
/// PROHIBITED ITEM MODEL
/// =====================================================

class ProhibitedItem {
  final String id;
  final String label;
  final IconData? icon;
  final String? iconName;
  final String? description;
  final ProhibitedSeverity severity;

  const ProhibitedItem({
    required this.id,
    required this.label,
    this.icon,
    this.iconName,
    this.description,
    this.severity = ProhibitedSeverity.standard,
  });

  factory ProhibitedItem.fromJson(Map<String, dynamic> map) {
    return ProhibitedItem(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      iconName: map['iconName'],
      description: map['description'],
      severity: ProhibitedSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => ProhibitedSeverity.standard,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'iconName': iconName,
    'description': description,
    'severity': severity.name,
  };
}

enum ProhibitedSeverity { low, standard, strict, zeroTolerance }

/// =====================================================
/// COLLABORATOR MODEL (embedded, denormalized for display)
/// =====================================================

class ListingCollaborator {
  final String organisationId;
  final String name;
  final String? imageUrl;
  final String role;
  final OrganisationType? type;
  final bool isVerified;
  final int displayOrder;

  const ListingCollaborator({
    required this.organisationId,
    required this.name,
    this.imageUrl,
    required this.role,
    this.type,
    this.isVerified = false,
    this.displayOrder = 0,
  });

  factory ListingCollaborator.fromJson(Map<String, dynamic> map) {
    return ListingCollaborator(
      organisationId: map['organisationId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      role: map['role'] ?? '',
      type: map['type'] != null
          ? OrganisationType.values.firstWhere(
              (e) => e.name == map['type'],
              orElse: () => OrganisationType.other,
            )
          : null,
      isVerified: map['isVerified'] ?? false,
      displayOrder: map['displayOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'organisationId': organisationId,
    'name': name,
    'imageUrl': imageUrl,
    'role': role,
    'type': type?.name,
    'isVerified': isVerified,
    'displayOrder': displayOrder,
  };

  /// Create from an OrganisationDTO
  factory ListingCollaborator.fromOrganisation(
    OrganisationDTO org, {
    required String role,
    int displayOrder = 0,
  }) {
    return ListingCollaborator(
      organisationId: org.id,
      name: org.name,
      imageUrl: org.media.mainImageUrl,
      role: role,
      type: org.organisationType,
      isVerified: org.isVerified,
      displayOrder: displayOrder,
    );
  }
}

// =====================================================
// UPDATED MERCHANT LISTING DTO
// =====================================================

// lib/core/models/merchant_listing_model.dart

class MerchantListingDTO implements Identifiable, Timestamped, Publishable {
  // =============================================
  // BASE FIELDS
  // =============================================
  @override
  final String id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final bool isActive;
  @override
  final PublishStatus status;

  final String title;
  final String? description;
  final ListingType type;
  final ContactInfo? contactInfo;
  final MediaModel mediaUrls;
  final ListingStats stats;
  final OperationalHoursDTO? operationalHours;
  final DateTime? startDate;
  final DateTime? endDate;
  final BookingType bookingType;
  final String organizationId;
  final String locationid;
  final String? walletId;
  final List<String> teamIds;
  final List<String> mediaFeedIds;

  // =============================================
  // SUBSCRIPTION FIELDS
  // =============================================
  final String? subscriptionId;
  final int? subscriptionTier;
  final DateTime? subscriptionExpiryDate;
  final bool? hasActiveSubscription;

  // =============================================
  // EVENT FIELDS
  // =============================================
  final Map<String, EventCategory>? eventCategories;
  final List<String>? ticketTypeIds;
  final List<String>? speakerIds;
  final EventPolicies? eventPolicies;
  final TicketSummary? ticketSummary;
  final bool? requiresApproval;

  // =============================================
  // PLACE FIELDS
  // =============================================
  final Map<String, PlaceCategory>? placeCategories;
  final double? entryFee;
  final bool? requiresBooking;
  final PlacePolicies? placePolicies;
  final List<String>? placeServiceIds;
  final List<String>? placeEventIds;
  final List<String>? placeIds;
  final List<String>? accommodationIds;

  // =============================================
  // SERVICE FIELDS
  // =============================================
  final Map<String, ServiceCategory>? serviceCategories;
  final List<String>? serviceTypeIds;
  final ServicePolicies? servicePolicies;

  // =============================================
  // ACCOMMODATION FIELDS
  // =============================================
  final Map<String, AccommodationCategory>? accommodationCategories;
  final List<String>? roomIds;
  final List<String>? accommodationServiceIds;
  final List<String>? accommodationEventIds;
  final List<String>? amenities;
  final TimeOfDay? checkInTime;
  final TimeOfDay? checkOutTime;
  final RoomSummary? roomSummary;
  final int? starRating;
  final double? averageRating;
  final int? totalReviews;

  // =============================================
  // SHARED DATA FIELDS (raw strings — no UI types)
  // =============================================

  /// Facility labels, e.g. ['Pool', 'WiFi', 'Parking']
  final List<String> facilities;

  /// Prohibited item labels, e.g. ['Alcohol', 'No Photos']
  final List<String> prohibitedItems;

  /// IDs of organizations collaborating on this listing
  final List<String> collaboratorIds;

  const MerchantListingDTO({
    // Base required
    required this.id,
    required this.organizationId,
    required this.title,
    required this.type,
    required this.locationid,
    required this.createdAt,
    required this.mediaUrls,
    required this.stats,

    // Base optional
    this.description,
    this.contactInfo,
    this.operationalHours,
    this.startDate,
    this.endDate,
    this.bookingType = BookingType.contact,
    this.isActive = true,
    this.status = PublishStatus.draft,
    this.teamIds = const [],
    this.updatedAt,
    this.mediaFeedIds = const [],
    this.walletId,

    // Subscription
    this.subscriptionId,
    this.subscriptionTier,
    this.subscriptionExpiryDate,
    this.hasActiveSubscription = false,

    // Event
    this.eventCategories,
    this.ticketTypeIds,
    this.speakerIds,
    this.eventPolicies,
    this.ticketSummary,
    this.requiresApproval,

    // Place
    this.placeCategories,
    this.entryFee,
    this.requiresBooking,
    this.placePolicies,
    this.placeServiceIds,
    this.placeEventIds,
    this.placeIds,
    this.accommodationIds,

    // Service
    this.serviceCategories,
    this.serviceTypeIds,
    this.servicePolicies,

    // Accommodation
    this.accommodationCategories,
    this.roomIds,
    this.accommodationServiceIds,
    this.accommodationEventIds,
    this.amenities,
    this.checkInTime,
    this.checkOutTime,
    this.roomSummary,
    this.starRating,
    this.averageRating,
    this.totalReviews,

    // Shared data
    this.facilities = const [],
    this.prohibitedItems = const [],
    this.collaboratorIds = const [],
  });

  // =============================================
  // CONVENIENCE GETTERS
  // =============================================

  bool get isEvent => type == ListingType.event;
  bool get isPlace => type == ListingType.place;
  bool get isAccommodation => type == ListingType.hotel;
  bool get isService => type == ListingType.service;

  int get totalMediaFeeds => mediaFeedIds.length;

  bool get hasFacilities => facilities.isNotEmpty;
  bool get hasProhibitedItems => prohibitedItems.isNotEmpty;
  bool get hasCollaborators => collaboratorIds.isNotEmpty;

  // =============================================
  // FROM JSON
  // =============================================

  factory MerchantListingDTO.fromJson(Map<String, dynamic> map, String id) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return null;
    }

    TimeOfDay? parseTimeOfDay(String? timeString) {
      if (timeString == null) return null;
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return MerchantListingDTO(
      id: id,
      organizationId: map['organizationId'] ?? '',
      title: map['title'] ?? '',
      type: ListingType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => throw Exception('Unknown listing type for $id'),
      ),
      description: map['description'],
      locationid: map['locationid'] ?? '',
      createdAt: parseDateTime(map['createdAt']) ?? DateTime.now(),
      mediaUrls: MediaModel.fromJson(map['mediaUrls'] ?? map),
      stats: ListingStats.fromJson(map['stats'] ?? {}),
      contactInfo: map['contactInfo'] != null
          ? ContactInfo.fromJson(map['contactInfo'])
          : null,
      operationalHours: map['operationalHours'] != null
          ? OperationalHoursDTO.fromJson(map['operationalHours'])
          : null,
      startDate: parseDateTime(map['startDate']),
      endDate: parseDateTime(map['endDate']),
      isActive: map['isActive'] ?? true,
      status: PublishStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PublishStatus.draft,
      ),
      teamIds: List<String>.from(map['teamIds'] ?? []),
      updatedAt: parseDateTime(map['updatedAt']),
      mediaFeedIds: List<String>.from(map['mediaFeedIds'] ?? []),
      walletId: map['walletId'] as String?,
      bookingType: BookingType.values.firstWhere(
        (e) => e.name == map['bookingType'],
        orElse: () => BookingType.contact,
      ),

      // Subscription
      subscriptionId: map['subscriptionId'] as String?,
      subscriptionTier: map['subscriptionTier'] as int?,
      subscriptionExpiryDate: parseDateTime(map['subscriptionExpiryDate']),
      hasActiveSubscription: map['hasActiveSubscription'] ?? false,

      // Event
      eventCategories: (map['eventCategories'] ?? {})
          .map<String, EventCategory>(
            (k, v) => MapEntry(
              k,
              EventCategory.values.firstWhere(
                (e) => e.name == v,
                orElse: () => EventCategory.values.first,
              ),
            ),
          ),
      ticketTypeIds: List<String>.from(map['ticketTypeIds'] ?? []),
      speakerIds: List<String>.from(map['speakerIds'] ?? []),
      eventPolicies: map['eventPolicies'] != null
          ? EventPolicies.fromMap(map['eventPolicies'])
          : null,
      ticketSummary: map['ticketSummary'] != null
          ? TicketSummary.fromJson(map['ticketSummary'])
          : null,
      requiresApproval: map['requiresApproval'] ?? false,

      // Place
      placeCategories: (map['placeCategories'] ?? {})
          .map<String, PlaceCategory>(
            (k, v) => MapEntry(
              k,
              PlaceCategory.values.firstWhere(
                (e) => e.name == v,
                orElse: () => PlaceCategory.values.first,
              ),
            ),
          ),
      entryFee: (map['entryFee'] as num?)?.toDouble(),
      requiresBooking: map['requiresBooking'],
      placePolicies: map['placePolicies'] != null
          ? PlacePolicies.fromMap(map['placePolicies'])
          : null,
      placeServiceIds: List<String>.from(map['placeServiceIds'] ?? []),
      placeEventIds: List<String>.from(map['placeEventIds'] ?? []),
      placeIds: List<String>.from(map['placeIds'] ?? []),
      accommodationIds: List<String>.from(map['accommodationIds'] ?? []),

      // Service
      serviceCategories: (map['serviceCategories'] ?? {})
          .map<String, ServiceCategory>(
            (k, v) => MapEntry(
              k,
              ServiceCategory.values.firstWhere(
                (e) => e.name == v,
                orElse: () => ServiceCategory.values.first,
              ),
            ),
          ),
      serviceTypeIds: List<String>.from(map['serviceTypeIds'] ?? []),
      servicePolicies: map['servicePolicies'] != null
          ? ServicePolicies.fromMap(map['servicePolicies'])
          : null,

      // Accommodation
      accommodationCategories: (map['accommodationCategories'] ?? {})
          .map<String, AccommodationCategory>(
            (k, v) => MapEntry(
              k,
              AccommodationCategory.values.firstWhere(
                (e) => e.name == v,
                orElse: () => AccommodationCategory.values.first,
              ),
            ),
          ),
      roomIds: List<String>.from(map['roomIds'] ?? []),
      accommodationServiceIds: List<String>.from(
        map['accommodationServiceIds'] ?? [],
      ),
      accommodationEventIds: List<String>.from(
        map['accommodationEventIds'] ?? [],
      ),
      amenities: map['amenities'] != null
          ? List<String>.from(map['amenities'])
          : null,
      checkInTime: parseTimeOfDay(map['checkInTime'] as String?),
      checkOutTime: parseTimeOfDay(map['checkOutTime'] as String?),
      roomSummary: map['roomSummary'] != null
          ? RoomSummary.fromJson(map['roomSummary'])
          : null,
      starRating: map['starRating'] as int?,
      averageRating: (map['averageRating'] as num?)?.toDouble(),
      totalReviews: map['totalReviews'] as int?,

      // Shared data
      facilities: List<String>.from(map['facilities'] ?? []),
      prohibitedItems: List<String>.from(map['prohibitedItems'] ?? []),
      collaboratorIds: List<String>.from(map['collaboratorIds'] ?? []),
    );
  }

  // =============================================
  // TO JSON
  // =============================================

  Map<String, dynamic> toJson() {
    String? timeOfDayToString(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    final map = <String, dynamic>{
      'id': id,
      'organizationId': organizationId,
      'title': title,
      'description': description,
      'type': type.name,
      'locationid': locationid,
      'createdAt': createdAt.toIso8601String(),
      'mediaUrls': mediaUrls.toJson(),
      'stats': stats.toJson(),
      'isActive': isActive,
      'status': status.name,
      'teamIds': teamIds,
      'mediaFeedIds': mediaFeedIds,
      'walletId': walletId,
      'bookingType': bookingType.name,

      'subscriptionId': subscriptionId,
      'subscriptionTier': subscriptionTier,
      'subscriptionExpiryDate': subscriptionExpiryDate?.toIso8601String(),
      'hasActiveSubscription': hasActiveSubscription ?? false,

      'eventCategories': eventCategories?.map((k, v) => MapEntry(k, v.name)),
      'ticketTypeIds': ticketTypeIds,
      'speakerIds': speakerIds,
      'eventPolicies': eventPolicies?.toMap(),
      'ticketSummary': ticketSummary?.toJson(),
      'requiresApproval': requiresApproval,

      'placeCategories': placeCategories?.map((k, v) => MapEntry(k, v.name)),
      'entryFee': entryFee,
      'requiresBooking': requiresBooking,
      'placePolicies': placePolicies?.toMap(),
      'placeServiceIds': placeServiceIds,
      'placeEventIds': placeEventIds,
      'placeIds': placeIds,
      'accommodationIds': accommodationIds,

      'serviceCategories': serviceCategories?.map(
        (k, v) => MapEntry(k, v.name),
      ),
      'serviceTypeIds': serviceTypeIds,
      'servicePolicies': servicePolicies?.toMap(),

      'accommodationCategories': accommodationCategories?.map(
        (k, v) => MapEntry(k, v.name),
      ),
      'roomIds': roomIds,
      'accommodationServiceIds': accommodationServiceIds,
      'accommodationEventIds': accommodationEventIds,
      'amenities': amenities,
      'checkInTime': timeOfDayToString(checkInTime),
      'checkOutTime': timeOfDayToString(checkOutTime),
      'roomSummary': roomSummary?.toJson(),
      'starRating': starRating,
      'averageRating': averageRating,
      'totalReviews': totalReviews,

      // Shared data
      'facilities': facilities,
      'prohibitedItems': prohibitedItems,
      'collaboratorIds': collaboratorIds,
    };

    if (contactInfo != null) map['contactInfo'] = contactInfo!.toJson();
    if (operationalHours != null) {
      map['operationalHours'] = operationalHours!.toJson();
    }
    if (startDate != null) {
      map['startDate'] = startDate!.toIso8601String();
    }
    if (endDate != null) {
      map['endDate'] = endDate!.toIso8601String();
    }
    if (updatedAt != null) {
      map['updatedAt'] = updatedAt!.toIso8601String();
    }

    map.removeWhere((key, value) => value == null);
    return map;
  }

  // =============================================
  // COPY WITH
  // =============================================

  MerchantListingDTO copyWith({
    String? id,
    String? organizationId,
    String? title,
    String? description,
    ListingType? type,
    String? locationid,
    DateTime? createdAt,
    DateTime? updatedAt,
    MediaModel? mediaUrls,
    ListingStats? stats,
    ContactInfo? contactInfo,
    OperationalHoursDTO? operationalHours,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    PublishStatus? status,
    List<String>? teamIds,
    List<String>? mediaFeedIds,
    String? walletId,
    BookingType? bookingType,
    String? subscriptionId,
    int? subscriptionTier,
    DateTime? subscriptionExpiryDate,
    bool? hasActiveSubscription,
    Map<String, EventCategory>? eventCategories,
    List<String>? ticketTypeIds,
    List<String>? speakerIds,
    EventPolicies? eventPolicies,
    TicketSummary? ticketSummary,
    bool? requiresApproval,
    Map<String, PlaceCategory>? placeCategories,
    double? entryFee,
    bool? requiresBooking,
    PlacePolicies? placePolicies,
    List<String>? placeServiceIds,
    List<String>? placeEventIds,
    List<String>? placeIds,
    List<String>? accommodationIds,
    Map<String, ServiceCategory>? serviceCategories,
    List<String>? serviceTypeIds,
    ServicePolicies? servicePolicies,
    Map<String, AccommodationCategory>? accommodationCategories,
    List<String>? roomIds,
    List<String>? accommodationServiceIds,
    List<String>? accommodationEventIds,
    List<String>? amenities,
    TimeOfDay? checkInTime,
    TimeOfDay? checkOutTime,
    RoomSummary? roomSummary,
    int? starRating,
    double? averageRating,
    int? totalReviews,

    // Shared data
    List<String>? facilities,
    List<String>? prohibitedItems,
    List<String>? collaboratorIds,
  }) {
    return MerchantListingDTO(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      locationid: locationid ?? this.locationid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      stats: stats ?? this.stats,
      contactInfo: contactInfo ?? this.contactInfo,
      operationalHours: operationalHours ?? this.operationalHours,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      teamIds: teamIds ?? this.teamIds,
      mediaFeedIds: mediaFeedIds ?? this.mediaFeedIds,
      walletId: walletId ?? this.walletId,
      bookingType: bookingType ?? this.bookingType,

      subscriptionId: subscriptionId ?? this.subscriptionId,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiryDate:
          subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      hasActiveSubscription:
          hasActiveSubscription ?? this.hasActiveSubscription,

      eventCategories: eventCategories ?? this.eventCategories,
      ticketTypeIds: ticketTypeIds ?? this.ticketTypeIds,
      speakerIds: speakerIds ?? this.speakerIds,
      eventPolicies: eventPolicies ?? this.eventPolicies,
      ticketSummary: ticketSummary ?? this.ticketSummary,
      requiresApproval: requiresApproval ?? this.requiresApproval,

      placeCategories: placeCategories ?? this.placeCategories,
      entryFee: entryFee ?? this.entryFee,
      requiresBooking: requiresBooking ?? this.requiresBooking,
      placePolicies: placePolicies ?? this.placePolicies,
      placeServiceIds: placeServiceIds ?? this.placeServiceIds,
      placeEventIds: placeEventIds ?? this.placeEventIds,
      placeIds: placeIds ?? this.placeIds,
      accommodationIds: accommodationIds ?? this.accommodationIds,

      serviceCategories: serviceCategories ?? this.serviceCategories,
      serviceTypeIds: serviceTypeIds ?? this.serviceTypeIds,
      servicePolicies: servicePolicies ?? this.servicePolicies,

      accommodationCategories:
          accommodationCategories ?? this.accommodationCategories,
      roomIds: roomIds ?? this.roomIds,
      accommodationServiceIds:
          accommodationServiceIds ?? this.accommodationServiceIds,
      accommodationEventIds:
          accommodationEventIds ?? this.accommodationEventIds,
      amenities: amenities ?? this.amenities,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      roomSummary: roomSummary ?? this.roomSummary,
      starRating: starRating ?? this.starRating,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,

      // Shared data
      facilities: facilities ?? this.facilities,
      prohibitedItems: prohibitedItems ?? this.prohibitedItems,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
    );
  }
}
// =============================================
// SUPPORTING CLASSES
// =============================================

class TicketSummary {
  final int totalTickets;
  final int availableTickets;
  final double minPrice;
  final double maxPrice;
  final List<String> ticketTypes;

  TicketSummary({
    required this.totalTickets,
    required this.availableTickets,
    required this.minPrice,
    required this.maxPrice,
    required this.ticketTypes,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalTickets': totalTickets,
      'availableTickets': availableTickets,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'ticketTypes': ticketTypes,
    };
  }

  factory TicketSummary.fromJson(Map<String, dynamic> data) {
    return TicketSummary(
      totalTickets: data['totalTickets'] as int,
      availableTickets: data['availableTickets'] as int,
      minPrice: (data['minPrice'] as num).toDouble(),
      maxPrice: (data['maxPrice'] as num).toDouble(),
      ticketTypes: List<String>.from(data['ticketTypes'] ?? []),
    );
  }

  bool get hasAvailableTickets => availableTickets > 0;
  double get availabilityPercentage =>
      totalTickets == 0 ? 0.0 : (availableTickets / totalTickets) * 100;

  String get availabilityStatus {
    if (availableTickets <= 0) return 'Sold out';
    if (availabilityPercentage < 25) return 'Limited';
    if (availabilityPercentage < 50) return 'Moderate';
    return 'Good';
  }
}

class RoomSummary {
  final int totalRooms;
  final double minPrice;
  final double maxPrice;
  final List<String> roomTypes;

  RoomSummary({
    required this.totalRooms,
    required this.minPrice,
    required this.maxPrice,
    required this.roomTypes,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalRooms': totalRooms,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'roomTypes': roomTypes,
    };
  }

  factory RoomSummary.fromJson(Map<String, dynamic> map) {
    return RoomSummary(
      totalRooms: (map['totalRooms'] as num).toInt(),
      minPrice: (map['minPrice'] as num).toDouble(),
      maxPrice: (map['maxPrice'] as num).toDouble(),
      roomTypes: List<String>.from(map['roomTypes'] ?? []),
    );
  }
}

// =============================================
// MOCK DATA (Converted to use single DTO)
// =============================================

final List<MerchantListingDTO> mockAllMerchantListingDTOs = [
  ...mockEventListings,
  ...mockPlaceListing,
  ...mockAccommodationListingDTOs,
  ...mockServiceListings,
];

final List<MerchantListingDTO> mockAccommodationListingDTOs = [
  MerchantListingDTO(
    id: 'htl_001',
    type: ListingType.hotel,
    organizationId: 'org_hospitality',
    title: 'Hyatt Regency Trinidad - Luxury Stay',
    description:
        '5-star luxury hotel in downtown Port of Spain with stunning waterfront views, world-class amenities, and exceptional service.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=201',
      imageUrls: [
        'https://picsum.photos/400/300?random=202',
        'https://picsum.photos/400/300?random=203',
        'https://picsum.photos/400/300?random=204',
      ],
      videoUrls: ['https://example.com/hotel-tour.mp4'],
    ),
    stats: const ListingStats(
      totalSales: 1250,
      availableItems: 50,
      confirmed: 1100,
      checkIns: 45230,
      saves: 5678,
      revenue: 875000,
    ),
    accommodationCategories: {'luxury': AccommodationCategory.hotel},
    locationid: 'loc11',
    createdAt: DateTime(2024, 9, 1),
    updatedAt: DateTime(2024, 11, 15),
    operationalHours: create24HourOperationalHours(),
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_hotel_ops'],
    roomIds: ['room_001', 'room_002'],
    serviceTypeIds: ['spa_massage', 'spa_facial', 'spa_body_wrap', 'spa_aroma'],
    placeEventIds: ['evt_001'],
    facilities: ['Pool', 'Fitness Center', 'Spa', 'Restaurant', 'Bar'],
    amenities: ['WiFi', 'Parking', 'Room Service', 'Air Conditioning'],
    starRating: 4,
    // Subscription info
    subscriptionId: 'sub_003',
    subscriptionTier: 3, // Booster = Tier 3
    subscriptionExpiryDate: DateTime(2025, 11, 1),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    id: 'htl_002',
    type: ListingType.hotel,
    organizationId: 'org_hospitality',
    title: 'Hilton Trinidad & Conference Centre',
    description:
        'Iconic hotel with panoramic city views, modern amenities, and easy access to attractions.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=205',
      imageUrls: [
        'https://picsum.photos/400/300?random=206',
        'https://picsum.photos/400/300?random=207',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 890,
      availableItems: 30,
      confirmed: 760,
      checkIns: 32150,
      saves: 4321,
      revenue: 654000,
    ),
    accommodationCategories: {'business': AccommodationCategory.hotel},
    locationid: 'loc15',
    createdAt: DateTime(2024, 8, 15),
    updatedAt: DateTime(2024, 11, 20),
    operationalHours: create24HourOperationalHours(),
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_hotel_ops'],
    roomIds: ['room_003', 'room_004'],
    serviceTypeIds: ['spa_massage', 'spa_facial'],
    facilities: ['Conference Center', 'Pool', 'Fitness Center'],
    amenities: ['WiFi', 'Parking', 'Room Service'],
    starRating: 4,
    // Subscription info
    subscriptionId: 'sub_003',
    subscriptionTier: 3,
    subscriptionExpiryDate: DateTime(2025, 11, 1),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    id: 'htl_003',
    type: ListingType.hotel,
    organizationId: 'org_hospitality',
    title: 'Magdalena Grand Beach & Golf Resort',
    description:
        'Luxury beachfront resort with golf course, spa, and stunning ocean views.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=208',
      imageUrls: [
        'https://picsum.photos/400/300?random=209',
        'https://picsum.photos/400/300?random=210',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 560,
      availableItems: 15,
      confirmed: 490,
      checkIns: 18760,
      saves: 2345,
      revenue: 432000,
    ),
    accommodationCategories: {'resort': AccommodationCategory.hotel},
    locationid: 'loc16',
    createdAt: DateTime(2024, 7, 1),
    updatedAt: DateTime(2024, 10, 5),
    operationalHours: create24HourOperationalHours(),
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_hotel'],
    roomIds: ['room_005', 'room_006'],
    serviceTypeIds: ['spa_body_wrap', 'spa_aroma'],
    facilities: ['Golf Course', 'Pool', 'Spa', 'Private Beach'],
    amenities: ['WiFi', 'Parking', 'Room Service', 'Bar'],
    starRating: 4,
    // Subscription info
    subscriptionId: 'sub_003',
    subscriptionTier: 3,
    subscriptionExpiryDate: DateTime(2025, 11, 1),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    id: 'htl_004',
    type: ListingType.hotel,
    organizationId: 'org_hospitality',
    title: 'Courtyard by Marriott Port of Spain',
    description:
        'Modern hotel near the waterfront, perfect for business travelers.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=211',
      imageUrls: [
        'https://picsum.photos/400/300?random=212',
        'https://picsum.photos/400/300?random=213',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 2340,
      availableItems: 85,
      confirmed: 1980,
      checkIns: 28900,
      saves: 3120,
      revenue: 468000,
    ),
    accommodationCategories: {'business': AccommodationCategory.hotel},
    locationid: 'loc14',
    createdAt: DateTime(2024, 5, 20),
    updatedAt: DateTime(2024, 9, 12),
    operationalHours: create24HourOperationalHours(),
    isActive: true,
    status: PublishStatus.published,
    teamIds: [],
    roomIds: ['room_007', 'room_008'],
    facilities: ['Business Center', 'Pool', 'Fitness Center'],
    amenities: ['WiFi', 'Parking', 'Breakfast'],
    starRating: 4,
    // Subscription info
    subscriptionId: 'sub_003',
    subscriptionTier: 3,
    subscriptionExpiryDate: DateTime(2025, 11, 1),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    id: 'htl_005',
    type: ListingType.hotel,
    organizationId: 'org_hospitality',
    title: 'Store Bay Beach Resort',
    description:
        'Beachfront resort near the airport with easy access to Store Bay.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=214',
      imageUrls: [
        'https://picsum.photos/400/300?random=215',
        'https://picsum.photos/400/300?random=216',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 430,
      availableItems: 12,
      confirmed: 380,
      checkIns: 15420,
      saves: 1876,
      revenue: 325000,
    ),
    accommodationCategories: {'beachfront': AccommodationCategory.hotel},
    locationid: 'loc17',
    createdAt: DateTime(2024, 6, 10),
    updatedAt: DateTime(2024, 8, 25),
    operationalHours: create24HourOperationalHours(),
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_hotel'],
    roomIds: ['room_009', 'room_010'],
    serviceTypeIds: ['spa_massage'],
    facilities: ['Beachfront', 'Pool', 'Restaurant'],
    amenities: ['WiFi', 'Parking', 'Airport Shuttle'],
    starRating: 4,
    // Subscription info
    subscriptionId: 'sub_003',
    subscriptionTier: 3,
    subscriptionExpiryDate: DateTime(2025, 11, 1),
    hasActiveSubscription: true,
  ),
];
final List<MerchantListingDTO> mockServiceListings = [
  MerchantListingDTO(
    id: 'srv_001',
    type: ListingType.service,
    organizationId: 'org_services',
    title: 'Luxury Spa Package at Hyatt',
    description:
        'Relax and rejuvenate with our premium spa services including massage, facial, and sauna.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=401',
      imageUrls: [
        'https://picsum.photos/400/300?random=402',
        'https://picsum.photos/400/300?random=403',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 450,
      availableItems: 25,
      confirmed: 380,
      checkIns: 12340,
      saves: 1654,
      revenue: 134550,
    ),
    serviceCategories: {'wellness': ServiceCategory.entertainer},
    serviceTypeIds: ['spa_massage', 'spa_facial', 'spa_body_wrap', 'spa_aroma'],
    locationid: 'loc11',
    createdAt: DateTime(2024, 8, 1),
    updatedAt: DateTime(2024, 11, 10),
    operationalHours: createStandardOperationalHours(
      openTime: '09:00',
      closeTime: '21:00',
    ),
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_spa'],
    servicePolicies: ServicePolicies(
      cancellationPolicy: 'strict',
      additionalPolicies: {'requires_appointment': true},
    ),
    // Subscription info
    subscriptionId: 'sub_005',
    subscriptionTier: 2, // Regular = Tier 2
    subscriptionExpiryDate: DateTime(2025, 10, 15),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    id: 'srv_002',
    type: ListingType.service,
    organizationId: 'org_services',
    title: 'Steelpan Music Lessons',
    description:
        'Learn to play the steelpan, Trinidad\'s national instrument, with professional musicians.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=404',
      imageUrls: [
        'https://picsum.photos/400/300?random=405',
        'https://picsum.photos/400/300?random=406',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 230,
      availableItems: 15,
      confirmed: 180,
      checkIns: 8760,
      saves: 987,
      revenue: 34500,
    ),
    serviceCategories: {'music': ServiceCategory.entertainer},
    serviceTypeIds: ['steelpan', 'soca', 'calypso', 'ensemble'],
    locationid: 'loc12',
    createdAt: DateTime(2024, 7, 15),
    updatedAt: DateTime(2024, 10, 20),
    operationalHours: createStandardOperationalHours(
      openTime: '10:00',
      closeTime: '20:00',
      closedDays: [Weekday.sunday],
    ),
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_music'],
    // Subscription info
    subscriptionId: 'sub_005',
    subscriptionTier: 2,
    subscriptionExpiryDate: DateTime(2025, 10, 15),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    id: 'srv_003',
    type: ListingType.service,
    organizationId: 'org_services',
    title: 'Professional Photography Services',
    description:
        'Professional photography for events, portraits, and commercial work in Trinidad.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=407',
      imageUrls: [
        'https://picsum.photos/400/300?random=408',
        'https://picsum.photos/400/300?random=409',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 120,
      availableItems: 20,
      confirmed: 95,
      checkIns: 6540,
      saves: 765,
      revenue: 36000,
    ),
    serviceCategories: {'photography': ServiceCategory.entertainer},
    serviceTypeIds: ['event', 'portrait', 'commercial', 'product'],
    locationid: 'loc20',
    createdAt: DateTime(2024, 5, 10),
    updatedAt: DateTime(2024, 9, 15),
    isActive: true,
    status: PublishStatus.published,
    teamIds: [],
    // Subscription info
    subscriptionId: 'sub_005',
    subscriptionTier: 2,
    subscriptionExpiryDate: DateTime(2025, 10, 15),
    hasActiveSubscription: true,
  ),
];
final List<MerchantListingDTO> mockPlaceListing = [
  ...mockAirportListings,
  MerchantListingDTO(
    id: 'plc_001',
    type: ListingType.place,
    organizationId: 'org_tourism',
    title: "Queen's Park Savannah Experience",
    description:
        'Explore the largest open space in Port of Spain, surrounded by historic buildings and vibrant culture.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=301',
      imageUrls: [
        'https://picsum.photos/400/300?random=302',
        'https://picsum.photos/400/300?random=303',
        'https://picsum.photos/400/300?random=304',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 3450,
      availableItems: 500,
      confirmed: 2800,
      checkIns: 56780,
      saves: 12345,
      revenue: 172500,
    ),
    placeCategories: {'park': PlaceCategory.mall},
    locationid: 'loc1',
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 11, 1),
    operationalHours: create24HourOperationalHours(),
    entryFee: 0.0,
    requiresBooking: false,
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_tourism'],
    // Subscription info
    subscriptionId: 'sub_004',
    subscriptionTier: 1, // Basic = Tier 1
    subscriptionExpiryDate: DateTime(2025, 8, 1),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    id: 'plc_002',
    type: ListingType.place,
    organizationId: 'org_tourism',
    title: 'Maracas Beach Day Trip',
    description:
        'Experience Trinidad\'s most famous beach, famous for bake and shark, with golden sands and excellent waves.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=305',
      imageUrls: [
        'https://picsum.photos/400/300?random=306',
        'https://picsum.photos/400/300?random=307',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 5670,
      availableItems: 800,
      confirmed: 4900,
      checkIns: 67890,
      saves: 8765,
      revenue: 283500,
    ),
    placeCategories: {'beach': PlaceCategory.beach},
    locationid: 'loc2',
    createdAt: DateTime(2024, 2, 10),
    updatedAt: DateTime(2024, 10, 15),
    operationalHours: create24HourOperationalHours(),
    entryFee: 0.0,
    requiresBooking: false,
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_tourism'],
    // Subscription info
    subscriptionId: 'sub_004',
    subscriptionTier: 1,
    subscriptionExpiryDate: DateTime(2025, 8, 1),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    id: 'plc_003',
    type: ListingType.place,
    organizationId: 'org_tourism',
    title: 'Pitch Lake Tour',
    description:
        'Visit the largest natural asphalt lake in the world, a geological wonder.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=308',
      imageUrls: [
        'https://picsum.photos/400/300?random=309',
        'https://picsum.photos/400/300?random=310',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 2340,
      availableItems: 400,
      confirmed: 2100,
      checkIns: 34560,
      saves: 4567,
      revenue: 70200,
    ),
    placeCategories: {'natural_wonder': PlaceCategory.beach},
    locationid: 'loc5',
    createdAt: DateTime(2024, 3, 5),
    updatedAt: DateTime(2024, 9, 20),
    operationalHours: createStandardOperationalHours(
      openTime: '08:00',
      closeTime: '18:00',
    ),
    entryFee: 10.0,
    requiresBooking: true,
    isActive: true,
    status: PublishStatus.published,
    teamIds: [],
    placePolicies: PlacePolicies(
      cancellationPolicy: 'strict',
      additionalPolicies: {'age_restriction': 'All ages welcome'},
    ),
    // Subscription info
    subscriptionId: 'sub_004',
    subscriptionTier: 1,
    subscriptionExpiryDate: DateTime(2025, 8, 1),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    id: 'plc_004',
    type: ListingType.place,
    organizationId: 'org_tourism',
    title: 'Pigeon Point Heritage Park',
    description:
        'Iconic Tobago beach with the famous jetty, perfect for swimming and relaxation.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=311',
      imageUrls: [
        'https://picsum.photos/400/300?random=312',
        'https://picsum.photos/400/300?random=313',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 1890,
      availableItems: 250,
      confirmed: 1650,
      checkIns: 28900,
      saves: 3456,
      revenue: 94500,
    ),
    placeCategories: {'beach': PlaceCategory.beach},
    locationid: 'loc3',
    createdAt: DateTime(2024, 4, 12),
    updatedAt: DateTime(2024, 8, 30),
    operationalHours: createStandardOperationalHours(
      openTime: '09:00',
      closeTime: '18:00',
    ),
    entryFee: 15.0,
    requiresBooking: false,
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_tourism'],
    // Subscription info
    subscriptionId: 'sub_004',
    subscriptionTier: 1,
    subscriptionExpiryDate: DateTime(2025, 8, 1),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    type: ListingType.place,
    id: 'plc_005',
    organizationId: 'org_tourism',
    title: 'Caroni Bird Sanctuary Tour',
    description:
        'Experience the nesting grounds of the Scarlet Ibis, Trinidad\'s national bird.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=314',
      imageUrls: [
        'https://picsum.photos/400/300?random=315',
        'https://picsum.photos/400/300?random=316',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 1230,
      availableItems: 180,
      confirmed: 980,
      checkIns: 23450,
      saves: 2345,
      revenue: 61500,
    ),
    placeCategories: {'wildlife': PlaceCategory.beach},
    locationid: 'loc8',
    createdAt: DateTime(2024, 5, 8),
    updatedAt: DateTime(2024, 7, 15),
    operationalHours: createStandardOperationalHours(
      openTime: '06:00',
      closeTime: '18:00',
    ),
    entryFee: 30.0,
    requiresBooking: true,
    isActive: true,
    status: PublishStatus.published,
    teamIds: [],
    placePolicies: PlacePolicies(
      cancellationPolicy: 'moderate',
      additionalPolicies: {
        'guided_tours_required': true,
        'maximum_group_size': 15,
      },
    ),
    // Subscription info
    subscriptionId: 'sub_004',
    subscriptionTier: 1,
    subscriptionExpiryDate: DateTime(2025, 8, 1),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    type: ListingType.place,
    id: 'plc_006',
    organizationId: 'org_tourism',
    title: 'Argyle Waterfall Adventure',
    description:
        'Tobago\'s highest waterfall, a stunning three-tiered cascade in the rainforest.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=317',
      imageUrls: [
        'https://picsum.photos/400/300?random=318',
        'https://picsum.photos/400/300?random=319',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 8900,
      availableItems: 1000,
      confirmed: 7600,
      checkIns: 78900,
      saves: 9876,
      revenue: 178000,
    ),
    placeCategories: {'waterfall': PlaceCategory.beach},
    locationid: 'loc9',
    createdAt: DateTime(2024, 6, 20),
    updatedAt: DateTime(2024, 9, 5),
    operationalHours: createStandardOperationalHours(
      openTime: '08:00',
      closeTime: '16:00',
    ),
    entryFee: 10.0,
    requiresBooking: false,
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_tourism'],
    // Subscription info
    subscriptionId: 'sub_004',
    subscriptionTier: 1,
    subscriptionExpiryDate: DateTime(2025, 8, 1),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    type: ListingType.place,
    id: 'plc_007',
    organizationId: 'org_tourism',
    title: 'Fort King George Historical Site',
    description:
        'Historic fort overlooking Scarborough with museums and panoramic views.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=320',
      imageUrls: [
        'https://picsum.photos/400/300?random=321',
        'https://picsum.photos/400/300?random=322',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 4500,
      availableItems: 600,
      confirmed: 3800,
      checkIns: 34500,
      saves: 4321,
      revenue: 90000,
    ),
    placeCategories: {'historical': PlaceCategory.mall},
    locationid: 'loc6',
    createdAt: DateTime(2024, 3, 15),
    updatedAt: DateTime(2024, 8, 10),
    operationalHours: createStandardOperationalHours(
      openTime: '09:00',
      closeTime: '17:00',
    ),
    entryFee: 5.0,
    requiresBooking: false,
    isActive: true,
    status: PublishStatus.published,
    teamIds: [],
    placePolicies: PlacePolicies(
      cancellationPolicy: 'flexible',
      additionalPolicies: {'museum_entry_included': true},
    ),
    // Subscription info
    subscriptionId: 'sub_004',
    subscriptionTier: 1,
    subscriptionExpiryDate: DateTime(2025, 8, 1),
    hasActiveSubscription: true,
  ),
];
final List<MerchantListingDTO> mockAirportListings = [
  // The main airport listing
  MerchantListingDTO(
    id: 'antigua_airport',
    type: ListingType.place,
    organizationId: 'org_airports',
    title: 'V.C. Bird International Airport',
    description:
        'Main international airport serving Antigua and Barbuda with modern facilities.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=2001',
      imageUrls: [
        'https://picsum.photos/400/300?random=2002',
        'https://picsum.photos/400/300?random=2003',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 12000,
      availableItems: 800,
      confirmed: 9500,
      checkIns: 200000,
      saves: 12000,
      revenue: 400000,
    ),
    placeCategories: {'airport': PlaceCategory.airport},
    locationid: 'antigua_vc_bird', // Same location ID as the airport
    createdAt: DateTime(2024, 1, 15),

    operationalHours: create24HourOperationalHours(),
    entryFee: 0.0,
    requiresBooking: false,
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_airports'],
  ),

  // Store 1 - Duty Free Shop
  MerchantListingDTO(
    id: 'store_001',
    type: ListingType.place,
    organizationId: 'org_airports',
    title: 'Antigua Duty Free - Airport Store',
    description:
        'Shop luxury goods, perfumes, and electronics at duty-free prices.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=2004',
      imageUrls: [
        'https://picsum.photos/400/300?random=2005',
        'https://picsum.photos/400/300?random=2006',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 5000,
      availableItems: 300,
      confirmed: 4000,
      checkIns: 50000,
      saves: 3000,
      revenue: 200000,
    ),
    placeCategories: {'shop': PlaceCategory.store},
    locationid: 'antigua_vc_bird', // Same location ID as the airport
    createdAt: DateTime(2024, 2, 10),

    operationalHours: createStandardOperationalHours(
      openTime: '06:00',
      closeTime: '22:00',
    ),
    entryFee: 0.0,
    requiresBooking: false,
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_airports'],
  ),

  // Store 2 - Airport Restaurant
  MerchantListingDTO(
    type: ListingType.place,
    id: 'store_002',
    organizationId: 'org_airports',
    title: 'Sky Lounge Restaurant & Bar',
    description:
        'Enjoy local and international cuisine with a view of the runway.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=2007',
      imageUrls: [
        'https://picsum.photos/400/300?random=2008',
        'https://picsum.photos/400/300?random=2009',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 3500,
      availableItems: 200,
      confirmed: 2800,
      checkIns: 45000,
      saves: 2000,
      revenue: 150000,
    ),
    placeCategories: {'restaurant': PlaceCategory.restaurant},
    locationid: 'antigua_vc_bird', // Same location ID as the airport
    createdAt: DateTime(2024, 3, 5),

    operationalHours: createStandardOperationalHours(
      openTime: '05:00',
      closeTime: '23:00',
    ),
    entryFee: 0.0,
    requiresBooking: true,
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_airports'],
    placePolicies: PlacePolicies(
      cancellationPolicy: 'moderate',
      additionalPolicies: {'reservations_recommended': true},
    ),
  ),

  MerchantListingDTO(
    id: 'store_003',
    type: ListingType.service,
    organizationId: 'org_airports',
    title: 'Antigua Car Rentals - Airport Desk',
    description:
        'Rent a car for your stay in Antigua. Pick up at the airport arrivals hall.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=2010',
      imageUrls: [
        'https://picsum.photos/400/300?random=2011',
        'https://picsum.photos/400/300?random=2012',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 2000,
      availableItems: 150,
      confirmed: 1600,
      checkIns: 30000,
      saves: 1500,
      revenue: 250000,
    ),
    placeCategories: {'car_rental': PlaceCategory.club},
    locationid: 'antigua_vc_bird', // Same location ID as the airport
    createdAt: DateTime(2024, 4, 1),

    operationalHours: createStandardOperationalHours(
      openTime: '06:00',
      closeTime: '22:00',
    ),
    entryFee: 0.0,
    requiresBooking: true,
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_airports'],
    placePolicies: PlacePolicies(
      cancellationPolicy: 'strict',
      additionalPolicies: {'driver_license_required': true, 'minimum_age': 21},
    ),
  ),
];
final List<MerchantListingDTO> mockEventListings = [
  MerchantListingDTO(
    id: 'evt_001',
    type: ListingType.event,
    organizationId: 'org_tech_conf',
    title: 'TechConf 2025 - Trinidad',
    description:
        'The biggest tech conference of the year featuring keynotes from industry leaders, hands-on workshops, and networking opportunities.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=101',
      imageUrls: [
        'https://picsum.photos/400/300?random=102',
        'https://picsum.photos/400/300?random=103',
        'https://picsum.photos/400/300?random=104',
      ],
      videoUrls: ['https://example.com/video1.mp4'],
    ),
    stats: const ListingStats(
      totalSales: 1250,
      availableItems: 250,
      confirmed: 850,
      checkIns: 15420,
      saves: 2341,
      revenue: 375000,
    ),
    eventCategories: {'technology': EventCategory.party},
    locationid: 'loc13',
    createdAt: DateTime(2024, 11, 1),
    updatedAt: DateTime(2024, 12, 1),
    startDate: DateTime.now().add(const Duration(days: 45)),
    endDate: DateTime.now().add(const Duration(days: 47)),
    contactInfo: ContactInfo(
      socialLinks: SocialLinks(
        twitter: 'https://twitter.com/techconf',
        instagram: 'https://instagram.com/techconf',
      ),
      email: 'info@techconf.com',
      phone: '+18681234567',
      website: 'https://techconf.tt',
    ),
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_events', 'team_marketing'],
    ticketTypeIds: ['ticket_001', 'ticket_002', 'ticket_003', 'ticket_004'],
    speakerIds: ['speaker_001', 'speaker_002', 'speaker_003', 'speaker_004'],
    eventPolicies: EventPolicies(
      cancellationPolicy: 'Full refund up to 7 days before event',
      additionalPolicies: {'recording_available': true},
    ),
    // Subscription info
    subscriptionId: 'sub_001',
    subscriptionTier: 3, // Booster = Tier 3
    subscriptionExpiryDate: DateTime(2025, 12, 1),
    hasActiveSubscription: true,
    mediaFeedIds: ['feed_001', 'feed_005'],
    walletId: 'wallet_evt_001',
  ),
  MerchantListingDTO(
    id: 'evt_002',
    type: ListingType.event,
    organizationId: 'org_music_fest',
    title: 'Trinidad Carnival Kickoff 2025',
    description:
        'Three days of incredible music featuring top soca artists from around the Caribbean.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=105',
      imageUrls: [
        'https://picsum.photos/400/300?random=106',
        'https://picsum.photos/400/300?random=107',
        'https://picsum.photos/400/300?random=108',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 3450,
      availableItems: 1550,
      confirmed: 2800,
      checkIns: 45230,
      saves: 6789,
      revenue: 892500,
    ),
    eventCategories: {'music': EventCategory.party},
    locationid: 'loc1',
    createdAt: DateTime(2024, 10, 15),
    updatedAt: DateTime(2024, 12, 5),
    startDate: DateTime.now().add(const Duration(days: 90)),
    endDate: DateTime.now().add(const Duration(days: 92)),
    contactInfo: ContactInfo(
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/carnivalkickoff',
      ),
      email: 'info@carnivalkickoff.com',
      phone: '+18687654321',
    ),
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_production', 'team_bookings'],
    ticketTypeIds: ['ticket_005', 'ticket_006', 'ticket_007'],
    // Subscription info
    subscriptionId: 'sub_002',
    subscriptionTier: 2, // Regular = Tier 2
    subscriptionExpiryDate: DateTime(2025, 7, 15),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    id: 'evt_003',
    type: ListingType.event,
    organizationId: 'org_tech_conf',
    title: 'Caribbean AI & Machine Learning Summit',
    description:
        'Deep dive into the latest advancements in AI, ML, and data science with hands-on workshops.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=109',
      imageUrls: [
        'https://picsum.photos/400/300?random=110',
        'https://picsum.photos/400/300?random=111',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 890,
      availableItems: 110,
      confirmed: 720,
      checkIns: 18340,
      saves: 2156,
      revenue: 267000,
    ),
    eventCategories: {'artificial_intelligence': EventCategory.party},
    locationid: 'loc11',
    createdAt: DateTime(2024, 11, 20),
    updatedAt: DateTime(2024, 12, 3),
    startDate: DateTime.now().add(const Duration(days: 120)),
    endDate: DateTime.now().add(const Duration(days: 122)),
    contactInfo: ContactInfo(
      socialLinks: SocialLinks(),
      email: 'info@caribbeanai.com',
      phone: '+18689876543',
      website: 'https://caribbeanai.com',
    ),
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_events'],
    ticketTypeIds: ['ticket_008', 'ticket_009', 'ticket_010'],
    speakerIds: ['speaker_005', 'speaker_006', 'speaker_007', 'speaker_008'],
    eventPolicies: EventPolicies(
      cancellationPolicy: 'No refunds for virtual tickets',
      additionalPolicies: {'virtual_attendance': true},
    ),
    // Subscription info (same as org_tech_conf - already active)
    subscriptionId: 'sub_001',
    subscriptionTier: 3,
    subscriptionExpiryDate: DateTime(2025, 12, 1),
    hasActiveSubscription: true,
  ),
  MerchantListingDTO(
    id: 'evt_004',
    type: ListingType.event,
    organizationId: 'org_startup',
    title: 'Startup Pitch Competition - Caribbean Edition',
    description:
        'Watch the most promising Caribbean startups compete for funding and exposure.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=112',
      imageUrls: [
        'https://picsum.photos/400/300?random=113',
        'https://picsum.photos/400/300?random=114',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 450,
      availableItems: 50,
      confirmed: 400,
      checkIns: 12340,
      saves: 1345,
      revenue: 22500,
    ),
    eventCategories: {'startup': EventCategory.party},
    locationid: 'loc20',
    createdAt: DateTime(2024, 12, 1),
    updatedAt: DateTime(2024, 12, 10),
    startDate: DateTime.now().add(const Duration(days: 30)),
    endDate: DateTime.now().add(const Duration(days: 30)),
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_events'],
    ticketTypeIds: ['ticket_011', 'ticket_012'],
    speakerIds: ['speaker_009', 'speaker_010', 'speaker_011'],
    // Subscription info - EXPIRED
    subscriptionId: 'sub_006',
    subscriptionTier: 1,
    subscriptionExpiryDate: DateTime(2024, 12, 1),
    hasActiveSubscription: false,
  ),
  MerchantListingDTO(
    id: 'evt_005',
    type: ListingType.event,
    organizationId: 'org_music',
    title: 'Soca & Steelpan Night',
    description:
        'An energetic evening of soca music and steelpan performances featuring local artists.',
    mediaUrls: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/300?random=115',
      imageUrls: [
        'https://picsum.photos/400/300?random=116',
        'https://picsum.photos/400/300?random=117',
      ],
      videoUrls: [],
    ),
    stats: const ListingStats(
      totalSales: 320,
      availableItems: 80,
      confirmed: 290,
      checkIns: 8920,
      saves: 876,
      revenue: 48000,
    ),
    eventCategories: {'soca': EventCategory.party},
    locationid: 'loc12',
    createdAt: DateTime(2024, 12, 5),
    updatedAt: DateTime(2024, 12, 8),
    startDate: DateTime.now().add(const Duration(days: 15)),
    endDate: DateTime.now().add(const Duration(days: 15)),
    isActive: true,
    status: PublishStatus.published,
    teamIds: ['team_production'],
    ticketTypeIds: ['ticket_013', 'ticket_014'],
    // Subscription info - CANCELLED
    subscriptionId: 'sub_007',
    subscriptionTier: 2,
    subscriptionExpiryDate: DateTime(2025, 8, 1),
    hasActiveSubscription: false,
  ),
];
