import 'package:lehwipalancecustomerv1/core/auth/permission_service.dart';
import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/contact_info.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/media_model.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/social_links.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';

// lib/core/models/organisation_model.dart

class OrganisationDTO
    implements Identifiable, Timestamped, Publishable, PermissionHolder {
  @override
  final String id;
  final String userId;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final bool isActive;
  @override
  final PublishStatus status;

  final String name;
  final String? description;
  final String? shortBio;
  final String? businessRegistrationNumber;
  final BusinessRegistration? businessRegistration;
  final String? legalName;

  final ContactInfo contactInfo;
  final AddressModel? address;
  final MediaModel media;

  final double averageRating;
  final int totalReviews;
  final List<String> followerIds;

  final bool isVerified;
  final DateTime? verifiedAt;

  final List<String> merchantListingIds;
  final List<String> favMerchantIds;
  final List<String> merchantInvitationIds;
  final List<String> membersIds;

  /// ✅ NEW: IDs of organizations this org collaborates with
  final List<String> collaboratorIds;

  /// ✅ NEW: IDs of organizations that collaborate with this org
  final List<String> collaboratingWithIds;

  /// ✅ NEW: Type/category of organization (for collaborators display)
  final OrganisationType? organisationType;

  final String? walletId;
  final List<String> mediaFeedIds;
  final List<String> accessIds;
  final List<String> teamIds;

  final Map<String, dynamic>? attributes;
  final String permissionString;

  const OrganisationDTO({
    required this.id,
    required this.userId,
    required this.name,
    this.legalName,
    this.description,
    this.shortBio,
    required this.contactInfo,
    this.address,
    required this.media,
    required this.businessRegistration,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.isVerified = false,
    this.isActive = true,
    this.status = PublishStatus.draft,
    this.verifiedAt,
    this.businessRegistrationNumber,
    required this.createdAt,
    this.updatedAt,
    this.followerIds = const [],
    this.teamIds = const [],
    this.merchantListingIds = const [],
    this.favMerchantIds = const [],
    this.merchantInvitationIds = const [],
    this.membersIds = const [],
    this.collaboratorIds = const [],
    this.collaboratingWithIds = const [],
    this.organisationType,
    this.accessIds = const [],
    this.attributes,
    this.permissionString = 'manageAll',
    this.walletId,
    this.mediaFeedIds = const [],
  });

  // Convenience getters
  String? get email => contactInfo.email;
  String? get phone => contactInfo.phone;
  String? get website => contactInfo.website;
  String? get qrCodeUrl => contactInfo.qrCodeUrl;
  int get followerCount => followerIds.length;
  String? get fullAddress => address?.fullAddress;
  int get mediaFeedCount => mediaFeedIds.length;

  /// Total collaborators (both directions)
  int get totalCollaboratorCount =>
      collaboratorIds.length + collaboratingWithIds.length;

  /// Check if this org collaborates with another
  bool collaboratesWith(String otherOrgId) {
    return collaboratorIds.contains(otherOrgId) ||
        collaboratingWithIds.contains(otherOrgId);
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'userId': userId,
      'name': name,
      'legalName': legalName,
      'description': description,
      'shortBio': shortBio,
      'contactInfo': {
        'email': contactInfo.email,
        'phone': contactInfo.phone,
        'website': contactInfo.website,
        'qrCodeUrl': contactInfo.qrCodeUrl,
        'socialLinks': contactInfo.socialLinks.toJson(),
      },
      'address': address?.toJson(),
      'media': media.toJson(),
      'businessRegistration': businessRegistration?.toJson(),
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'followerCount': followerCount,
      'isVerified': isVerified,
      'isActive': isActive,
      'status': status.name,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'businessRegistrationNumber': businessRegistrationNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'followerIds': followerIds,
      'teamIds': teamIds,
      'merchantListingIds': merchantListingIds,
      'favMerchantIds': favMerchantIds,
      'merchantInvitationIds': merchantInvitationIds,
      'membersIds': membersIds,
      'collaboratorIds': collaboratorIds,
      'collaboratingWithIds': collaboratingWithIds,
      'organisationType': organisationType?.name,
      'accessIds': accessIds,
      'attributes': attributes,
      'walletId': walletId,
      'mediaFeedIds': mediaFeedIds,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }

  factory OrganisationDTO.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value is String) return DateTime.parse(value);
      if (value is DateTime) return value;
      return null;
    }

    AddressModel? address;
    if (json['address'] != null) {
      address = AddressModel.fromJson(
        Map<String, dynamic>.from(json['address']),
      );
    }

    ContactInfo contactInfo;
    if (json['contactInfo'] != null) {
      final contactData = Map<String, dynamic>.from(json['contactInfo']);
      contactInfo = ContactInfo(
        email: contactData['email'] ?? '',
        phone: contactData['phone'],
        website: contactData['website'],
        qrCodeUrl: contactData['qrCodeUrl'] ?? '',
        socialLinks: contactData['socialLinks'] != null
            ? SocialLinks.fromJson(
                Map<String, dynamic>.from(contactData['socialLinks']),
              )
            : const SocialLinks(),
      );
    } else {
      contactInfo = ContactInfo(
        email: json['email'] ?? '',
        phone: json['phone'],
        website: json['website'],
        qrCodeUrl: '',
        socialLinks: json['socialLinks'] != null
            ? SocialLinks.fromJson(
                Map<String, dynamic>.from(json['socialLinks']),
              )
            : const SocialLinks(),
      );
    }

    return OrganisationDTO(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      legalName: json['legalName'],
      description: json['description'],
      shortBio: json['shortBio'],
      contactInfo: contactInfo,
      address: address,
      media: json['media'] ?? MediaModel.fromJson(json['media'] ?? {}),
      businessRegistration: json['businessRegistration'] != null
          ? BusinessRegistration.fromJson(
              Map<String, dynamic>.from(json['businessRegistration']),
            )
          : null,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      status: PublishStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PublishStatus.draft,
      ),
      verifiedAt: parseDateTime(json['verifiedAt']),
      businessRegistrationNumber: json['businessRegistrationNumber'],
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt']),
      followerIds: List<String>.from(json['followerIds'] ?? []),
      teamIds: List<String>.from(json['teamIds'] ?? []),
      merchantListingIds: List<String>.from(json['merchantListingIds'] ?? []),
      favMerchantIds: List<String>.from(json['favMerchantIds'] ?? []),
      merchantInvitationIds: List<String>.from(
        json['merchantInvitationIds'] ?? [],
      ),
      membersIds: List<String>.from(json['membersIds'] ?? []),
      collaboratorIds: List<String>.from(json['collaboratorIds'] ?? []),
      collaboratingWithIds: List<String>.from(
        json['collaboratingWithIds'] ?? [],
      ),
      organisationType: json['organisationType'] != null
          ? OrganisationType.values.firstWhere(
              (e) => e.name == json['organisationType'],
              orElse: () => OrganisationType.other,
            )
          : null,
      accessIds: List<String>.from(json['accessIds'] ?? []),
      attributes: json['attributes'] as Map<String, dynamic>?,
      walletId: json['walletId'] as String?,
      mediaFeedIds: List<String>.from(json['mediaFeedIds'] ?? []),
    );
  }

  OrganisationDTO copyWith({
    String? id,
    String? userId,
    String? name,
    String? legalName,
    String? description,
    String? shortBio,
    ContactInfo? contactInfo,
    AddressModel? address,
    MediaModel? media,
    BusinessRegistration? businessRegistration,
    double? averageRating,
    int? totalReviews,
    bool? isVerified,
    bool? isActive,
    PublishStatus? status,
    DateTime? verifiedAt,
    String? businessRegistrationNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? followerIds,
    List<String>? teamIds,
    List<String>? merchantListingIds,
    List<String>? favMerchantIds,
    List<String>? merchantInvitationIds,
    List<String>? membersIds,
    List<String>? collaboratorIds,
    List<String>? collaboratingWithIds,
    OrganisationType? organisationType,
    List<String>? accessIds,
    Map<String, dynamic>? attributes,
    String? walletId,
    List<String>? mediaFeedIds,
  }) {
    return OrganisationDTO(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      legalName: legalName ?? this.legalName,
      description: description ?? this.description,
      shortBio: shortBio ?? this.shortBio,
      contactInfo: contactInfo ?? this.contactInfo,
      address: address ?? this.address,
      media: media ?? this.media,
      businessRegistration: businessRegistration ?? this.businessRegistration,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      businessRegistrationNumber:
          businessRegistrationNumber ?? this.businessRegistrationNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      followerIds: followerIds ?? this.followerIds,
      teamIds: teamIds ?? this.teamIds,
      merchantListingIds: merchantListingIds ?? this.merchantListingIds,
      favMerchantIds: favMerchantIds ?? this.favMerchantIds,
      merchantInvitationIds:
          merchantInvitationIds ?? this.merchantInvitationIds,
      membersIds: membersIds ?? this.membersIds,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      collaboratingWithIds: collaboratingWithIds ?? this.collaboratingWithIds,
      organisationType: organisationType ?? this.organisationType,
      accessIds: accessIds ?? this.accessIds,
      attributes: attributes ?? this.attributes,
      walletId: walletId ?? this.walletId,
      mediaFeedIds: mediaFeedIds ?? this.mediaFeedIds,
    );
  }

  @override
  List<Permission> getPermissions() =>
      isActive ? Permission.values.toList() : [];

  @override
  bool hasPermission(Permission permission) => isActive;
  @override
  bool hasAllPermissions(List<Permission> permissions) => isActive;
  @override
  bool hasAnyPermission(List<Permission> permissions) => isActive;
}

/// ✅ NEW: Organization type for collaborators display
enum OrganisationType {
  venue,
  promoter,
  artist,
  dj,
  band,
  vendor,
  sponsor,
  media,
  security,
  catering,
  decorator,
  photographer,
  videographer,
  soundEngineer,
  lightingTechnician,
  other;

  String get displayName {
    switch (this) {
      case OrganisationType.venue:
        return 'Venue';
      case OrganisationType.promoter:
        return 'Promoter';
      case OrganisationType.artist:
        return 'Artist';
      case OrganisationType.dj:
        return 'DJ';
      case OrganisationType.band:
        return 'Band';
      case OrganisationType.vendor:
        return 'Vendor';
      case OrganisationType.sponsor:
        return 'Sponsor';
      case OrganisationType.media:
        return 'Media';
      case OrganisationType.security:
        return 'Security';
      case OrganisationType.catering:
        return 'Catering';
      case OrganisationType.decorator:
        return 'Decorator';
      case OrganisationType.photographer:
        return 'Photographer';
      case OrganisationType.videographer:
        return 'Videographer';
      case OrganisationType.soundEngineer:
        return 'Sound Engineer';
      case OrganisationType.lightingTechnician:
        return 'Lighting Technician';
      case OrganisationType.other:
        return 'Other';
    }
  }
}

/// Business registration information
class BusinessRegistration {
  final String registrationNumber;
  final String? legalName;
  final DateTime? registeredAt;
  final String? taxId;
  final double? taxPercentage;
  final BusinessType? businessType;
  final String? countryOfRegistration;
  final String? vatNumber;

  const BusinessRegistration({
    required this.registrationNumber,
    this.legalName,
    this.registeredAt,
    this.taxId,
    this.taxPercentage,
    this.businessType,
    this.countryOfRegistration,
    this.vatNumber,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'registrationNumber': registrationNumber,
      'legalName': legalName,
      'registeredAt': registeredAt?.toIso8601String(),
      'taxId': taxId,
      'taxPercentage': taxPercentage,
      'businessType': businessType?.name,
      'countryOfRegistration': countryOfRegistration,
      'vatNumber': vatNumber,
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }

  factory BusinessRegistration.fromJson(Map<String, dynamic>? data) {
    if (data == null) {
      return const BusinessRegistration(registrationNumber: '');
    }

    DateTime? parseDateTime(dynamic value) {
      if (value is String) return DateTime.parse(value);
      if (value is DateTime) return value;
      return null;
    }

    return BusinessRegistration(
      registrationNumber: data['registrationNumber'] ?? '',
      legalName: data['legalName'] ?? data['registeredName'],
      registeredAt: parseDateTime(
        data['registeredAt'] ?? data['registrationDate'],
      ),
      taxId: data['taxId'],
      taxPercentage: (data['taxPercentage'] as num?)?.toDouble(),
      businessType: data['businessType'] != null
          ? BusinessType.values.firstWhere(
              (e) => e.name == data['businessType'],
              orElse: () => BusinessType.soleProprietorship,
            )
          : null,
      countryOfRegistration: data['countryOfRegistration'],
      vatNumber: data['vatNumber'],
    );
  }

  bool get isValid =>
      registrationNumber.isNotEmpty && registrationNumber != 'PENDING-2024';

  BusinessRegistration copyWith({
    String? registrationNumber,
    String? legalName,
    DateTime? registeredAt,
    String? taxId,
    double? taxPercentage,
    BusinessType? businessType,
    String? countryOfRegistration,
    String? vatNumber,
  }) {
    return BusinessRegistration(
      registrationNumber: registrationNumber ?? this.registrationNumber,
      legalName: legalName ?? this.legalName,
      registeredAt: registeredAt ?? this.registeredAt,
      taxId: taxId ?? this.taxId,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      businessType: businessType ?? this.businessType,
      countryOfRegistration:
          countryOfRegistration ?? this.countryOfRegistration,
      vatNumber: vatNumber ?? this.vatNumber,
    );
  }

  @override
  String toString() {
    return 'BusinessRegistration(registrationNumber: $registrationNumber, legalName: $legalName, '
        'registeredAt: $registeredAt, businessType: $businessType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessRegistration &&
        other.registrationNumber == registrationNumber &&
        other.legalName == legalName &&
        other.registeredAt == registeredAt &&
        other.taxId == taxId &&
        other.taxPercentage == taxPercentage &&
        other.businessType == businessType &&
        other.countryOfRegistration == countryOfRegistration &&
        other.vatNumber == vatNumber;
  }

  @override
  int get hashCode {
    return Object.hash(
      registrationNumber,
      legalName,
      registeredAt,
      taxId,
      taxPercentage,
      businessType,
      countryOfRegistration,
      vatNumber,
    );
  }
}

enum BusinessType {
  soleProprietorship,
  partnership,
  llc,
  corporation,
  nonProfit,
  cooperative,
  other;

  String get displayName {
    switch (this) {
      case BusinessType.soleProprietorship:
        return 'Sole Proprietorship';
      case BusinessType.partnership:
        return 'Partnership';
      case BusinessType.llc:
        return 'Limited Liability Company (LLC)';
      case BusinessType.corporation:
        return 'Corporation';
      case BusinessType.nonProfit:
        return 'Non-Profit Organization';
      case BusinessType.cooperative:
        return 'Cooperative';
      case BusinessType.other:
        return 'Other';
    }
  }
}

// Mock data remains the same but with DateTime parsing fixes
final DateTime now = DateTime.now();
final DateTime lastWeek = now.subtract(const Duration(days: 7));
final DateTime lastMonth = now.subtract(const Duration(days: 30));
final DateTime twoMonthsAgo = now.subtract(const Duration(days: 60));

// Organization name validation
class OrganisationDTOName {
  final String value;

  static const int minLength = 2;
  static const int maxLength = 100;

  OrganisationDTOName(this.value) {
    if (value.length < minLength || value.length > maxLength) {
      throw ArgumentError(
        'Organization name must be between $minLength and $maxLength characters',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganisationDTOName &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class OrganisationDTODescription {
  final String? value;
  static const int maxLength = 5000;

  OrganisationDTODescription(this.value) {
    if (value != null && value!.length > maxLength) {
      throw ArgumentError('Description cannot exceed $maxLength characters');
    }
  }
}

class ShortBio {
  final String? value;
  static const int maxLength = 500;

  ShortBio(this.value) {
    if (value != null && value!.length > maxLength) {
      throw ArgumentError('Short bio cannot exceed $maxLength characters');
    }
  }
}

class TaxInfo {
  final String? taxId;
  final double? percentage;

  const TaxInfo({this.taxId, this.percentage});

  bool get hasTaxInfo => taxId != null || percentage != null;
}

class OrganisationMetrics {
  final double averageRating;
  final int totalReviews;
  final int followerCount;
  final int totalListings;

  const OrganisationMetrics({
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.followerCount = 0,
    this.totalListings = 0,
  });
}

class VerificationStatus {
  final bool isVerified;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  const VerificationStatus({
    this.isVerified = false,
    this.verifiedAt,
    this.verifiedBy,
  });

  VerificationStatus verify(String by) {
    return VerificationStatus(
      isVerified: true,
      verifiedAt: DateTime.now(),
      verifiedBy: by,
    );
  }
}

// First, define all valid IDs
const Map<String, String> organizationNameToId = {
  'Caribbean Events Pro': 'org_001',
  'Tobago Events & Hospitality': 'org_002',
  'Caribbean Hotel Group': 'org_003',
  'Caribbean Cultural Festivals': 'org_004',
  'Venue Finder TT': 'org_005',
  'Luxury Weddings Caribbean': 'org_006',
  'Caribbean Catering Services': 'org_007',
  'Cultural Heritage TT': 'org_008',
  'Music Fest Caribbean': 'org_009',
  'Event Tech Solutions': 'org_010',
  'Sports Management TT': 'org_011',
  'Art Gallery TT': 'org_012',
  'Charity Events Caribbean': 'org_013',
  'Caribbean Food Festival': 'org_014',
  'Convention Center TT': 'org_015',
};

// =====================================================
// FIXED MERCHANT LISTING DTOS WITH CORRECT IDs
// =====================================================

// =====================================================
// FIXED ORGANISATION DTO WITH CORRECT LISTING IDS
// =====================================================

///
///
///

final List<OrganisationDTO> mockOrganisations = [
  OrganisationDTO(
    id: 'org_001',
    userId: 'member_001',
    name: 'Caribbean Events Pro',
    legalName: 'Caribbean Events Professional Ltd',
    description:
        'Premier event management company specializing in Caribbean festivals and corporate events',
    shortBio: 'Your go-to event organizers in Trinidad & Tobago',
    contactInfo: const ContactInfo(
      email: 'info@caribbeaneventspro.com',
      phone: '+1-868-123-4567',
      website: 'https://caribbeaneventspro.com',
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/caribbeaneventspro',
      ),
    ),
    address: AddressModel(
      street: '15 Queen\'s Park West',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120101',
    ),
    media: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/200?random=org1',
    ),
    businessRegistration: BusinessRegistration(
      registrationNumber: 'BRN-2024-001',
      registeredAt: DateTime(2024, 1, 15),
    ),
    averageRating: 4.8,
    totalReviews: 156,
    isVerified: true,
    verifiedAt: DateTime(2024, 2, 1),
    businessRegistrationNumber: 'BRN-2024-001',
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 6, 20),
    merchantListingIds: ['evt_001', 'evt_003', 'plc_001', 'plc_002'],
    teamIds: ['team_events', 'team_marketing', 'team_tourism'],
    membersIds: ['member_001', 'member_002'],
    accessIds: ['access_admin', 'access_event_creator'],
    // ✅ NEW FIELDS
    walletId: 'wallet_org_001',
    mediaFeedIds: [
      'feed_001',
      'feed_003',
      'feed_005',
      'feed_006',
      'feed_008',
      'feed_010',
      'feed_011',
      'feed_013',
    ],
  ),
  OrganisationDTO(
    id: 'org_002',
    userId: 'member_002',
    name: 'Tobago Events & Hospitality',
    legalName: 'Tobago Events & Hospitality Ltd',
    description: 'Full-service event and hospitality management in Tobago',
    contactInfo: const ContactInfo(
      email: 'info@tobagoevents.com',
      phone: '+1-868-234-5678',
      website: 'https://tobagoevents.com',
      socialLinks: SocialLinks(instagram: 'https://instagram.com/tobagoevents'),
    ),
    address: AddressModel(
      street: '22 Store Bay Local Road',
      city: 'Crown Point',
      state: 'Tobago',
      country: 'Trinidad and Tobago',
      postalCode: '910101',
    ),
    media: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/200?random=org2',
    ),
    businessRegistration: BusinessRegistration(
      registrationNumber: 'BRN-2024-002',
      registeredAt: DateTime(2024, 2, 10),
    ),
    averageRating: 4.6,
    totalReviews: 89,
    isVerified: true,
    createdAt: DateTime(2024, 2, 10),
    merchantListingIds: ['evt_002'], // Fixed: using actual listing ID
    teamIds: ['team_production', 'team_bookings'],
    membersIds: ['member_002'],
  ),
  OrganisationDTO(
    id: 'org_003',
    userId: 'member_003',
    name: 'Caribbean Hotel Group',
    legalName: 'Caribbean Hotel Management Group Inc',
    description:
        'Managing premium hotels and accommodations across the Caribbean',
    contactInfo: const ContactInfo(
      email: 'info@caribbeanhotels.com',
      phone: '+1-868-345-6789',
      website: 'https://caribbeanhotels.com',
      socialLinks: SocialLinks(
        linkedin: 'https://linkedin.com/company/caribbeanhotels',
      ),
    ),
    address: AddressModel(
      street: '8 Queen\'s Park East',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120102',
    ),
    media: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/200?random=org3',
    ),
    businessRegistration: BusinessRegistration(
      registrationNumber: 'BRN-2024-003',
      registeredAt: DateTime(2024, 3, 5),
    ),
    averageRating: 4.3,
    totalReviews: 234,
    isVerified: true,
    createdAt: DateTime(2024, 3, 5),
    merchantListingIds: [
      'htl_001',
      'srv_001',
    ], // Fixed: using actual listing IDs
    teamIds: ['team_hotel_ops', 'team_spa'],
    membersIds: ['member_003'],
  ),
  OrganisationDTO(
    id: 'org_004',
    userId: 'member_004',
    name: 'Music Fest Caribbean',
    legalName: 'Music Fest Caribbean Ltd',
    description: 'Organizing the best music festivals across the Caribbean',
    contactInfo: const ContactInfo(
      email: 'info@musicfestcaribbean.com',
      phone: '+1-868-456-7890',
      website: 'https://musicfestcaribbean.com',
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/musicfestcaribbean',
      ),
    ),
    address: AddressModel(
      street: '45 Music Avenue',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120103',
    ),
    media: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/200?random=org4',
    ),
    businessRegistration: BusinessRegistration(
      registrationNumber: 'BRN-2024-004',
      registeredAt: DateTime(2024, 4, 1),
    ),
    averageRating: 4.7,
    totalReviews: 89,
    isVerified: true,
    createdAt: DateTime(2024, 4, 1),
    merchantListingIds: ['evt_002', 'evt_005'],
    teamIds: ['team_music', 'team_production'],
    membersIds: ['member_004'],
  ),
  OrganisationDTO(
    id: 'org_005',
    userId: 'member_005',
    name: 'Trinidad Hospitality Group',
    legalName: 'Trinidad Hospitality Group Ltd',
    description: 'Luxury hotel management and hospitality services',
    contactInfo: const ContactInfo(
      email: 'info@trinidadhospitality.com',
      phone: '+1-868-567-8901',
      website: 'https://trinidadhospitality.com',
      socialLinks: SocialLinks(
        linkedin: 'https://linkedin.com/company/trinidadhospitality',
      ),
    ),
    address: AddressModel(
      street: '12 Hotel Row',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120104',
    ),
    media: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/200?random=org5',
    ),
    businessRegistration: BusinessRegistration(
      registrationNumber: 'BRN-2024-005',
      registeredAt: DateTime(2024, 5, 1),
    ),
    averageRating: 4.5,
    totalReviews: 156,
    isVerified: true,
    createdAt: DateTime(2024, 5, 1),
    merchantListingIds: ['htl_004', 'htl_005'],
    teamIds: ['team_hotel'],
    membersIds: ['member_005'],
  ),
  OrganisationDTO(
    id: 'org_006',
    userId: 'member_006',
    name: 'Tobago Resort Management',
    legalName: 'Tobago Resort Management Ltd',
    description: 'Managing resorts and beachfront properties in Tobago',
    contactInfo: const ContactInfo(
      email: 'info@tobagoresorts.com',
      phone: '+1-868-678-9012',
      website: 'https://tobagoresorts.com',
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/tobagoresorts',
      ),
    ),
    address: AddressModel(
      street: '8 Store Bay Road',
      city: 'Crown Point',
      state: 'Tobago',
      country: 'Trinidad and Tobago',
      postalCode: '910102',
    ),
    media: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/200?random=org6',
    ),
    businessRegistration: BusinessRegistration(
      registrationNumber: 'BRN-2024-006',
      registeredAt: DateTime(2024, 6, 1),
    ),
    averageRating: 4.4,
    totalReviews: 78,
    isVerified: true,
    createdAt: DateTime(2024, 6, 1),
    merchantListingIds: ['htl_003', 'plc_004'],
    teamIds: ['team_resort'],
    membersIds: ['member_006'],
  ),
  OrganisationDTO(
    id: 'org_007',
    userId: 'member_007',
    name: 'Caribbean Entertainment Group',
    legalName: 'Caribbean Entertainment Group Ltd',
    description: 'Premier entertainment and events company in the Caribbean',
    contactInfo: const ContactInfo(
      email: 'info@caribbeanentertainment.com',
      phone: '+1-868-789-0123',
      website: 'https://caribbeanentertainment.com',
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/caribbeanentertainment',
        twitter: 'https://twitter.com/caribbeanent',
      ),
    ),
    address: AddressModel(
      street: '33 Entertainment Drive',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120105',
    ),
    media: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/200?random=org7',
    ),
    businessRegistration: BusinessRegistration(
      registrationNumber: 'BRN-2024-007',
      registeredAt: DateTime(2024, 7, 1),
    ),
    averageRating: 4.9,
    totalReviews: 234,
    isVerified: true,
    createdAt: DateTime(2024, 7, 1),
    merchantListingIds: ['evt_002', 'evt_005', 'srv_002'],
    teamIds: ['team_production', 'team_bookings'],
    membersIds: ['member_007'],
  ),
  OrganisationDTO(
    id: 'org_008',
    userId: 'member_008',
    name: 'Trinidad Tourism Authority',
    legalName: 'Trinidad Tourism Authority',
    description: 'Promoting tourism and cultural events in Trinidad',
    contactInfo: const ContactInfo(
      email: 'info@trinidadtourism.com',
      phone: '+1-868-890-1234',
      website: 'https://trinidadtourism.com',
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/trinidadtourism',
        twitter: 'https://twitter.com/trinidadtourism',
      ),
    ),
    address: AddressModel(
      street: '2 Tourism Boulevard',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120106',
    ),
    media: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/200?random=org8',
    ),
    businessRegistration: BusinessRegistration(
      registrationNumber: 'BRN-2024-008',
      registeredAt: DateTime(2024, 8, 1),
    ),
    averageRating: 4.2,
    totalReviews: 345,
    isVerified: true,
    createdAt: DateTime(2024, 8, 1),
    merchantListingIds: ['plc_001', 'plc_002', 'plc_003', 'plc_005', 'plc_006'],
    teamIds: ['team_tourism'],
    membersIds: ['member_008'],
  ),
  OrganisationDTO(
    id: 'org_009',
    userId: 'member_009',
    name: 'Caribbean Wedding Planners',
    legalName: 'Caribbean Wedding Planners Ltd',
    description: 'Specializing in destination weddings and events',
    contactInfo: const ContactInfo(
      email: 'info@caribbeanweddings.com',
      phone: '+1-868-901-2345',
      website: 'https://caribbeanweddings.com',
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/caribbeanweddings',
        pinterest: 'https://pinterest.com/caribbeanweddings',
      ),
    ),
    address: AddressModel(
      street: '44 Wedding Lane',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120107',
    ),
    media: MediaModel(
      mainImageUrl: 'https://picsum.photos/400/200?random=org9',
    ),
    businessRegistration: BusinessRegistration(
      registrationNumber: 'BRN-2024-009',
      registeredAt: DateTime(2024, 9, 1),
    ),
    averageRating: 4.6,
    totalReviews: 123,
    isVerified: true,
    createdAt: DateTime(2024, 9, 1),
    merchantListingIds: ['srv_003', 'evt_004'],
    teamIds: ['team_events'],
    membersIds: ['member_009'],
  ),
];
