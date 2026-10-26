import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';

import 'package:lehwipalancecustomerv1/core/models/common_models/contact_info.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/social_links.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';

abstract class UserDTO implements Identifiable, Timestamped {
  @override
  final String id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  final String? fcmToken;
  // Profile
  final String name;
  final String email;
  final String imageUrl;
  final String? bio;
  final String? gender;
  final ContactInfo contactInfo;
  final AddressModel address;
  final String language;
  final String currency;
  final String walletId;
  // Status
  final bool isActive;
  final bool isBanned;
  final String? banReason;
  //

  const UserDTO({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.fcmToken,
    required this.email,
    required this.name,
    required this.imageUrl,
    this.bio,
    this.gender,
    required this.contactInfo,
    required this.address,
    required this.language,
    required this.currency,
    required this.walletId,
    required this.isActive,
    required this.isBanned,
    this.banReason,
  });

  // Add copyWith method
  UserDTO copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    String? name,
    String? email,
    String? imageUrl,
    String? bio,
    String? gender,
    ContactInfo? contactInfo,
    AddressModel? address,
    String? language,
    String? currency,
    String? walletId,
    bool? isActive,
    bool? isBanned,
    String? banReason,
  });
}

class MemberDTO extends UserDTO {
  final String? organisationId;
  final List<String> accessIds;
  final String referralCode;
  final List<String> organiserOfIds;
  final List<String> listingIds;
  final List<String> invitationIds;
  final List<String> teamIds;
  final DateTime joinedAt;
  final DateTime? lastActiveAt;

  MemberDTO({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    super.fcmToken,
    required super.name,
    required super.email,
    required super.imageUrl,
    super.bio,
    super.gender,
    required super.contactInfo,
    required super.address,
    required super.language,
    required super.currency,
    required this.referralCode,
    required super.walletId,
    required super.isActive,
    required super.isBanned,
    super.banReason,
    this.organisationId,
    required this.accessIds,
    required this.organiserOfIds,
    required this.listingIds,
    required this.invitationIds,
    required this.teamIds,
    required this.joinedAt,
    this.lastActiveAt,
  });

  @override
  MemberDTO copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    String? name,
    String? email,
    String? imageUrl,
    String? bio,
    String? gender,
    ContactInfo? contactInfo,
    AddressModel? address,
    String? language,
    String? currency,
    String? walletId,
    bool? isActive,
    bool? isBanned,
    String? banReason,
    String? organisationId,
    List<String>? accessIds,
    String? referralCode,
    List<String>? organiserOfIds,
    List<String>? listingIds,
    List<String>? invitationIds,
    List<String>? teamIds,
    DateTime? joinedAt,
    DateTime? lastActiveAt,
    List<String>? savedMerchantIds,
    List<String>? followingOrganisationsIds,
  }) {
    return MemberDTO(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      name: name ?? this.name,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      contactInfo: contactInfo ?? this.contactInfo,
      address: address ?? this.address,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      walletId: walletId ?? this.walletId,
      isActive: isActive ?? this.isActive,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      organisationId: organisationId ?? this.organisationId,
      accessIds: accessIds ?? this.accessIds,
      referralCode: referralCode ?? this.referralCode,
      organiserOfIds: organiserOfIds ?? this.organiserOfIds,
      listingIds: listingIds ?? this.listingIds,
      invitationIds: invitationIds ?? this.invitationIds,
      teamIds: teamIds ?? this.teamIds,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}

class CustomerDTO extends UserDTO {
  final List<String>
  savedMerchantIds; // List of merchant IDs that the user has saved or favorited
  final List<String> followingOrganisationsIds;
  final List<String> likedMediaIds; // list of reels liked
  final bool notificationsEnabled;
  final String filterPreferencesID;
  final List<String> bookingIds;

  CustomerDTO({
    required super.id,
    required super.createdAt,
    super.updatedAt,
    super.fcmToken,
    required super.name,
    required super.email,
    required super.imageUrl,
    super.bio,
    super.gender,
    required super.contactInfo,
    required super.address,
    required super.language,
    required super.currency,
    required this.notificationsEnabled,
    required this.filterPreferencesID,
    required this.savedMerchantIds,
    required this.followingOrganisationsIds,
    required this.bookingIds,
    required super.walletId,
    required super.isActive,
    required super.isBanned,
    super.banReason,
    required this.likedMediaIds,
  });

  @override
  CustomerDTO copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
    String? name,
    String? email,
    String? imageUrl,
    String? bio,
    String? gender,
    ContactInfo? contactInfo,
    AddressModel? address,
    String? language,
    String? currency,
    String? walletId,
    bool? isActive,
    bool? isBanned,
    String? banReason,

    bool? notificationsEnabled,
    String? filterPreferencesID,
    List<String>? savedMerchantIds,
    List<String>? followingOrganisationsIds,
    List<String>? bookingIds,
  }) {
    return CustomerDTO(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
      name: name ?? this.name,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      contactInfo: contactInfo ?? this.contactInfo,
      address: address ?? this.address,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      walletId: walletId ?? this.walletId,
      isActive: isActive ?? this.isActive,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      filterPreferencesID: filterPreferencesID ?? this.filterPreferencesID,
      savedMerchantIds: savedMerchantIds ?? this.savedMerchantIds,
      followingOrganisationsIds:
          followingOrganisationsIds ?? this.followingOrganisationsIds,
      bookingIds: bookingIds ?? this.bookingIds,
      likedMediaIds: [],
    );
  }
}

final List<UserDTO> mockUsers = [...mockMemberDTOs, ...mockCustomerDTOs];

final List<CustomerDTO> mockCustomerDTOs = [
  CustomerDTO(
    id: 'customer_001',
    createdAt: DateTime(2024, 6, 15),
    updatedAt: DateTime(2025, 5, 20),
    fcmToken: 'fcm_customer_001_abc123',
    name: 'James Wilson',
    email: 'james.wilson@gmail.com',
    imageUrl: 'https://randomuser.me/api/portraits/men/50.jpg',
    bio: 'Love attending music festivals and cultural events',
    gender: 'Male',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        facebook: 'https://facebook.com/jameswilson',
        instagram: 'https://instagram.com/jameswilson',
        whatsapp: '18681234567',
      ),
      email: 'james.wilson@gmail.com',
      phone: '+1-868-123-4567',
    ),
    address: AddressModel(
      street: '45 Maraval Road',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120101',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_customer_001',
    isActive: true,
    isBanned: false,
    banReason: null,
    notificationsEnabled: true,
    filterPreferencesID: 'filter_pref_001',
    savedMerchantIds: [
      // Event listings (matches music festival interest)
      'evt_002', // Trinidad Carnival Kickoff 2025
      'evt_005', // Soca & Steelpan Night
      // Service listing (matches cultural interest)
      'srv_002', // Steelpan Music Lessons
      // Hotel listing (practical for event attendance)
      'htl_001', // Hyatt Regency Trinidad
      // Event listing (matches professional interest)
      'evt_004', // Startup Pitch Competition
    ],
    followingOrganisationsIds: [
      'org_001', // Caribbean Events Pro
      'org_002', // Tobago Events & Hospitality
      'org_003', // Caribbean Hotel Group
    ],
    bookingIds: [
      'RCP001', // Tech Conference Tickets
      'RCP002', // Carnival Kickoff Tickets
      'RCP003', // Hyatt Hotel Booking with Spa
      'RCP004', // Hilton Hotel Booking
    ],
    likedMediaIds: [],
  ),
  CustomerDTO(
    id: 'customer_002',
    createdAt: DateTime(2024, 7, 22),
    updatedAt: DateTime(2025, 5, 18),
    fcmToken: 'fcm_customer_002_def456',
    name: 'Sophia Martinez',
    email: 'sophia.martinez@yahoo.com',
    imageUrl: 'https://randomuser.me/api/portraits/women/51.jpg',
    bio: 'Foodie and art enthusiast',
    gender: 'Female',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/sophiamartinez',
        pinterest: 'https://pinterest.com/sophiamartinez',
      ),
      email: 'sophia.martinez@yahoo.com',
      phone: '+1-868-234-5678',
    ),
    address: AddressModel(
      street: '12 Queen\'s Park West',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120102',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_customer_002',
    isActive: true,
    isBanned: false,
    banReason: null,
    notificationsEnabled: true,
    filterPreferencesID: 'filter_pref_002',
    savedMerchantIds: [
      'htl_001', // Hyatt Regency Trinidad
      'htl_002', // Hilton Trinidad
      'srv_001', // Luxury Spa Package
    ],
    followingOrganisationsIds: ['org_001', 'org_003', 'org_hospitality'],
    bookingIds: [
      'RCP003', // Hyatt Hotel Booking with Spa
      'RCP004', // Hilton Hotel Booking
      'RCP006', // Magdalena Grand Resort
    ],
    likedMediaIds: [],
  ),
  CustomerDTO(
    id: 'customer_003',
    createdAt: DateTime(2024, 8, 5),
    updatedAt: DateTime(2025, 5, 15),
    fcmToken: null,
    name: 'Marcus Thompson',
    email: 'marcus.thompson@hotmail.com',
    imageUrl: 'https://randomuser.me/api/portraits/men/52.jpg',
    bio: 'Sports fan and adventure seeker',
    gender: 'Male',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        twitter: 'https://twitter.com/marcusthompson',
        instagram: 'https://instagram.com/marcusthompson',
      ),
      email: 'marcus.thompson@hotmail.com',
      phone: '+1-868-345-6789',
    ),
    address: AddressModel(
      street: '89 Eastern Main Road',
      city: 'Tunapuna',
      state: 'Tunapuna-Piarco',
      country: 'Trinidad and Tobago',
      postalCode: '350101',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_customer_003',
    isActive: true,
    isBanned: false,
    banReason: null,
    notificationsEnabled: false,
    filterPreferencesID: 'filter_pref_003',
    savedMerchantIds: [
      'htl_003', // Magdalena Grand Beach & Golf Resort
      'htl_005', // Store Bay Beach Resort
      'srv_001', // Luxury Spa Package
    ],
    followingOrganisationsIds: ['org_003', 'org_005', 'org_hospitality'],
    bookingIds: [
      'RCP006', // Magdalena Grand Resort
      'RCP013', // Store Bay Beach Resort
      'RCP015', // Large Group Booking
    ],
    likedMediaIds: [],
  ),
  CustomerDTO(
    id: 'customer_004',
    createdAt: DateTime(2024, 9, 12),
    updatedAt: DateTime(2025, 5, 10),
    fcmToken: 'fcm_customer_004_ghi789',
    name: 'Olivia Charles',
    email: 'olivia.charles@gmail.com',
    imageUrl: 'https://randomuser.me/api/portraits/women/53.jpg',
    bio: 'Music lover and festival goer',
    gender: 'Female',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/oliviacharles',
        tiktok: 'https://tiktok.com/@oliviacharles',
        snapchat: 'https://snapchat.com/add/oliviacharles',
      ),
      email: 'olivia.charles@gmail.com',
      phone: '+1-868-456-7890',
    ),
    address: AddressModel(
      street: '23 Long Circular Road',
      city: 'Maraval',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120103',
    ),
    language: 'en',
    currency: 'USD',
    walletId: 'wallet_customer_004',
    isActive: true,
    isBanned: false,
    banReason: null,
    notificationsEnabled: true,
    filterPreferencesID: 'filter_pref_004',
    savedMerchantIds: [
      'evt_001', // TechConf 2025
      'evt_003', // Caribbean AI Summit
      'srv_003', // Professional Photography Services
    ],
    followingOrganisationsIds: ['org_tech_conf', 'org_services'],
    bookingIds: [
      'RCP001', // Tech Conference Tickets
      'RCP005', // AI Summit Tickets
      'RCP009', // Photography Services
    ],
    likedMediaIds: [],
  ),
  CustomerDTO(
    id: 'customer_005',
    createdAt: DateTime(2024, 10, 18),
    updatedAt: DateTime(2025, 5, 5),
    fcmToken: 'fcm_customer_005_jkl012',
    name: 'Daniel Khan',
    email: 'daniel.khan@outlook.com',
    imageUrl: 'https://randomuser.me/api/portraits/men/54.jpg',
    bio: 'Tech professional who enjoys networking events',
    gender: 'Male',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        linkedin: 'https://linkedin.com/in/danielkhan',
        twitter: 'https://twitter.com/danielkhan',
      ),
      email: 'daniel.khan@outlook.com',
      phone: '+1-868-567-8901',
    ),
    address: AddressModel(
      street: '5 St. Clair Avenue',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120104',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_customer_005',
    isActive: true,
    isBanned: false,
    banReason: null,
    notificationsEnabled: true,
    filterPreferencesID: 'filter_pref_005',
    savedMerchantIds: [
      'evt_003', // Caribbean AI Summit
      'srv_003', // Professional Photography Services
      'htl_004', // Courtyard by Marriott
    ],
    followingOrganisationsIds: [
      'org_tech_conf',
      'org_services',
      'org_hospitality',
    ],
    bookingIds: [
      'RCP005', // AI Summit Tickets
      'RCP009', // Photography Services
      'RCP010', // Full Package - Hotel + Events
    ],
    likedMediaIds: [],
  ),
  CustomerDTO(
    id: 'customer_006',
    createdAt: DateTime(2024, 11, 25),
    updatedAt: DateTime(2025, 5, 1),
    fcmToken: null,
    name: 'Chloe Ramsay',
    email: 'chloe.ramsay@gmail.com',
    imageUrl: 'https://randomuser.me/api/portraits/women/55.jpg',
    bio: 'Art lover and gallery hopper',
    gender: 'Female',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/chloeramsay',
        pinterest: 'https://pinterest.com/chloeramsay',
      ),
      email: 'chloe.ramsay@gmail.com',
      phone: '+1-868-678-9012',
    ),
    address: AddressModel(
      street: '67 Picton Street',
      city: 'San Fernando',
      state: 'San Fernando',
      country: 'Trinidad and Tobago',
      postalCode: '720101',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_customer_006',
    isActive: true,
    isBanned: false,
    banReason: null,
    notificationsEnabled: true,
    filterPreferencesID: 'filter_pref_006',
    savedMerchantIds: [
      'srv_001', // Luxury Spa Package
      'srv_002', // Steelpan Music Lessons
      'htl_001', // Hyatt Regency Trinidad
    ],
    followingOrganisationsIds: ['org_services', 'org_hospitality'],
    bookingIds: [
      'RCP003', // Hyatt Hotel Booking with Spa
      'RCP007', // Steelpan Lessons
      'RCP015', // Large Group Booking
    ],
    likedMediaIds: [],
  ),
  CustomerDTO(
    id: 'customer_007',
    createdAt: DateTime(2024, 12, 3),
    updatedAt: DateTime(2025, 4, 28),
    fcmToken: 'fcm_customer_007_mno345',
    name: 'Ryan Campbell',
    email: 'ryan.campbell@yahoo.com',
    imageUrl: 'https://randomuser.me/api/portraits/men/56.jpg',
    bio: 'Wedding guest enthusiast and social butterfly',
    gender: 'Male',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        facebook: 'https://facebook.com/ryancampbell',
        instagram: 'https://instagram.com/ryancampbell',
        whatsapp: '18687890123',
      ),
      email: 'ryan.campbell@yahoo.com',
      phone: '+1-868-789-0123',
    ),
    address: AddressModel(
      street: '34 Royal Road',
      city: 'St. Augustine',
      state: 'Tunapuna-Piarco',
      country: 'Trinidad and Tobago',
      postalCode: '350102',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_customer_007',
    isActive: true,
    isBanned: false,
    banReason: null,
    notificationsEnabled: false,
    filterPreferencesID: 'filter_pref_007',
    savedMerchantIds: [
      'evt_002', // Trinidad Carnival Kickoff
      'evt_005', // Soca & Steelpan Night
      'srv_002', // Steelpan Music Lessons
    ],
    followingOrganisationsIds: ['org_music_fest', 'org_music', 'org_services'],
    bookingIds: [
      'RCP002', // Carnival Kickoff Tickets
      'RCP007', // Steelpan Lessons
      'RCP014', // Single Ticket Purchase
    ],
    likedMediaIds: [],
  ),
  CustomerDTO(
    id: 'customer_008',
    createdAt: DateTime(2025, 1, 9),
    updatedAt: DateTime(2025, 4, 20),
    fcmToken: 'fcm_customer_008_pqr678',
    name: 'Samantha Hosein',
    email: 'samantha.hosein@gmail.com',
    imageUrl: 'https://randomuser.me/api/portraits/women/57.jpg',
    bio: 'Food festival lover and culinary explorer',
    gender: 'Female',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/samanthahosein',
        tiktok: 'https://tiktok.com/@samanthahosein',
        tripadvisor: 'https://tripadvisor.com/samanthahosein',
      ),
      email: 'samantha.hosein@gmail.com',
      phone: '+1-868-890-1234',
    ),
    address: AddressModel(
      street: '78 O\'Connor Street',
      city: 'Woodbrook',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120105',
    ),
    language: 'en',
    currency: 'USD',
    walletId: 'wallet_customer_008',
    isActive: true,
    isBanned: false,
    banReason: null,
    notificationsEnabled: true,
    filterPreferencesID: 'filter_pref_008',
    savedMerchantIds: [
      'evt_004', // Startup Pitch Competition
      'htl_002', // Hilton Trinidad
      'htl_005', // Store Bay Beach Resort
    ],
    followingOrganisationsIds: ['org_startup', 'org_hospitality'],
    bookingIds: [
      'RCP004', // Hilton Hotel Booking
      'RCP008', // Startup Pitch Competition
      'RCP013', // Store Bay Beach Resort
    ],
    likedMediaIds: [],
  ),
  CustomerDTO(
    id: 'customer_009',
    createdAt: DateTime(2025, 2, 14),
    updatedAt: DateTime(2025, 4, 15),
    fcmToken: null,
    name: 'Brandon Leung',
    email: 'brandon.leung@hotmail.com',
    imageUrl: 'https://randomuser.me/api/portraits/men/58.jpg',
    bio: 'Conference attendee and continuous learner',
    gender: 'Male',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        linkedin: 'https://linkedin.com/in/brandonleung',
        twitter: 'https://twitter.com/brandonleung',
      ),
      email: 'brandon.leung@hotmail.com',
      phone: '+1-868-901-2345',
    ),
    address: AddressModel(
      street: '56 Cipriani Boulevard',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120106',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_customer_009',
    isActive: true,
    isBanned: false,
    banReason: null,
    notificationsEnabled: true,
    filterPreferencesID: 'filter_pref_009',
    savedMerchantIds: [
      'evt_001', // TechConf 2025
      'srv_003', // Professional Photography Services
      'htl_004', // Courtyard by Marriott
    ],
    followingOrganisationsIds: [
      'org_tech_conf',
      'org_services',
      'org_hospitality',
    ],
    bookingIds: [
      'RCP001', // Tech Conference Tickets
      'RCP009', // Photography Services
      'RCP010', // Full Package - Hotel + Events
    ],
    likedMediaIds: [],
  ),
  CustomerDTO(
    id: 'customer_010',
    createdAt: DateTime(2025, 3, 11),
    updatedAt: DateTime(2025, 5, 22),
    fcmToken: 'fcm_customer_010_stu901',
    name: 'Nicole Williams',
    email: 'nicole.williams@gmail.com',
    imageUrl: 'https://randomuser.me/api/portraits/women/59.jpg',
    bio: 'Charity event supporter and community volunteer',
    gender: 'Female',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        facebook: 'https://facebook.com/nicolewilliams',
        instagram: 'https://instagram.com/nicolewilliams',
        linkedin: 'https://linkedin.com/in/nicolewilliams',
      ),
      email: 'nicole.williams@gmail.com',
      phone: '+1-868-012-3456',
    ),
    address: AddressModel(
      street: '123 Tragarete Road',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120107',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_customer_010',
    isActive: true,
    isBanned: false,
    banReason: null,
    notificationsEnabled: true,
    filterPreferencesID: 'filter_pref_010',
    savedMerchantIds: [
      'srv_001', // Luxury Spa Package
      'htl_003', // Magdalena Grand Resort
      'htl_005', // Store Bay Beach Resort
    ],
    followingOrganisationsIds: ['org_services', 'org_hospitality'],
    bookingIds: [
      'RCP006', // Magdalena Grand Resort
      'RCP013', // Store Bay Beach Resort
      'RCP015', // Large Group Booking
    ],
    likedMediaIds: [],
  ),
];

final List<MemberDTO> mockMemberDTOs = [
  MemberDTO(
    id: 'member_001',
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2025, 5, 20),
    fcmToken: 'fcm_token_member_001_xyz789',
    name: 'John Williams',
    email: 'john.williams@eventpro.tt',
    imageUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
    bio: 'Event organizer with 10+ years of experience in Caribbean events',
    gender: 'Male',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        facebook: 'https://facebook.com/johnwilliams',
        instagram: 'https://instagram.com/johnwilliams',
        linkedin: 'https://linkedin.com/in/johnwilliams',
        whatsapp: '18681234567',
      ),
      email: 'john.williams@eventpro.tt',
      phone: '+1-868-123-4567',
      website: 'https://eventpro.tt',
    ),
    address: AddressModel(
      street: '15 Queen\'s Park West',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120101',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_member_001',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_001',
    accessIds: ['access_admin', 'access_event_creator', 'access_venue_manager'],
    referralCode: 'JOHN2024',
    organiserOfIds: ['event_001', 'event_002', 'event_003'],
    listingIds: [
      'evt_002', // From org_002 - Tobago Carnival event
      'htl_001', // From org_003 - Hyatt Hotel
      'srv_001', // From org_003 - Spa Service
    ],
    invitationIds: ['invite_001', 'invite_002'],
    teamIds: ['team_001'],
    joinedAt: DateTime(2024, 1, 15),
    lastActiveAt: DateTime(2025, 5, 20),
  ),
  MemberDTO(
    id: 'member_002',
    createdAt: DateTime(2024, 2, 10),
    updatedAt: DateTime(2025, 5, 18),
    fcmToken: 'fcm_token_member_002_abc456',
    name: 'Sarah Johnson',
    email: 'sarah.johnson@tobagoevents.com',
    imageUrl: 'https://randomuser.me/api/portraits/women/2.jpg',
    bio: 'Passionate about promoting Tobago\'s cultural events and festivals',
    gender: 'Female',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/sarahevents',
        twitter: 'https://twitter.com/sarahevents',
        tripadvisor: 'https://tripadvisor.com/sarahjohnson',
        expedia: 'https://expedia.com/partners/sarahj',
      ),
      email: 'sarah.johnson@tobagoevents.com',
      phone: '+1-868-234-5678',
      website: 'https://tobagoevents.com',
    ),
    address: AddressModel(
      street: '22 Store Bay Local Road',
      city: 'Crown Point',
      state: 'Tobago',
      country: 'Trinidad and Tobago',
      postalCode: '910101',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_member_002',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_002',
    accessIds: ['access_event_creator', 'access_marketing'],
    referralCode: 'TOBAGO2024',
    organiserOfIds: ['event_004', 'event_005'],
    listingIds: [
      'evt_001', // From org_001 - Tech Conference
      'plc_001', // From org_001 - Queen's Park Savannah
      'srv_002', // From org_003 - Steelpan Lessons
    ],
    invitationIds: ['invite_003'],
    teamIds: ['team_002'],
    joinedAt: DateTime(2024, 2, 10),
    lastActiveAt: DateTime(2025, 5, 18),
  ),
  MemberDTO(
    id: 'member_003',
    createdAt: DateTime(2024, 3, 5),
    updatedAt: DateTime(2025, 5, 15),
    fcmToken: 'fcm_token_member_003_def123',
    name: 'Michael Chang',
    email: 'michael.chang@caribbeanhotels.com',
    imageUrl: 'https://randomuser.me/api/portraits/men/3.jpg',
    bio: 'Hotel manager and event coordinator specializing in corporate events',
    gender: 'Male',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        linkedin: 'https://linkedin.com/in/michaelchang',
        bookingDotCom: 'https://booking.com/hotelpartner/mchang',
        airbnb: 'https://airbnb.com/hosts/michaelc',
      ),
      email: 'michael.chang@caribbeanhotels.com',
      phone: '+1-868-345-6789',
      website: 'https://caribbeanhotels.com',
    ),
    address: AddressModel(
      street: '8 Queen\'s Park East',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120102',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_member_003',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_003',
    accessIds: ['access_venue_manager', 'access_hotel_admin'],
    referralCode: 'HOTELPRO',
    organiserOfIds: ['event_006', 'event_007', 'event_008', 'event_009'],
    listingIds: [
      'evt_003', // From org_001 - AI Summit
      'plc_002', // From org_001 - Maracas Beach
      'plc_004', // From org_002 - Pigeon Point (Note: plc_004 is in mockPlaceListingDTOs)
    ],
    invitationIds: [],
    teamIds: ['team_003', 'team_004'],
    joinedAt: DateTime(2024, 3, 5),
    lastActiveAt: DateTime(2025, 5, 15),
  ),
  MemberDTO(
    id: 'member_004',
    createdAt: DateTime(2024, 4, 20),
    updatedAt: DateTime(2025, 5, 10),
    fcmToken: 'fcm_token_member_004_ghi789',
    name: 'Patricia Alleyne',
    email: 'patricia.alleyne@festivalscaribbean.org',
    imageUrl: 'https://randomuser.me/api/portraits/women/4.jpg',
    bio: 'Cultural festival organizer promoting Caribbean heritage worldwide',
    gender: 'Female',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        facebook: 'https://facebook.com/patriciaalleyne',
        instagram: 'https://instagram.com/caribbeanfest',
        youtube: 'https://youtube.com/caribbeanfestivals',
        tiktok: 'https://tiktok.com/@caribfest',
        eventbrite: 'https://eventbrite.com/o/patricia-alleyne',
      ),
      email: 'patricia.alleyne@festivalscaribbean.org',
      phone: '+1-868-456-7890',
      website: 'https://caribbeanfestivals.org',
    ),
    address: AddressModel(
      street: '45 Tragarete Road',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120103',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_member_004',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_004',
    accessIds: ['access_admin', 'access_event_creator', 'access_sponsorship'],
    referralCode: 'FESTCARIB',
    organiserOfIds: [
      'event_010',
      'event_011',
      'event_012',
      'event_013',
      'event_014',
    ],
    listingIds: ['listing_010', 'listing_011', 'listing_012'],
    invitationIds: ['invite_004', 'invite_005', 'invite_006'],
    teamIds: ['team_005', 'team_006'],
    joinedAt: DateTime(2024, 4, 20),
    lastActiveAt: DateTime(2025, 5, 10),
  ),
  MemberDTO(
    id: 'member_005',
    createdAt: DateTime(2024, 5, 12),
    updatedAt: DateTime(2025, 5, 5),
    fcmToken: null,
    name: 'David Thompson',
    email: 'david.thompson@venuefinder.tt',
    imageUrl: 'https://randomuser.me/api/portraits/men/5.jpg',
    bio: 'Venue finder specialist helping people discover perfect event spaces',
    gender: 'Male',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        linkedin: 'https://linkedin.com/in/davidthompson',
        instagram: 'https://instagram.com/venuefinder',
        meetup: 'https://meetup.com/venuefinder',
      ),
      email: 'david.thompson@venuefinder.tt',
      phone: '+1-868-567-8901',
      website: 'https://venuefinder.tt',
    ),
    address: AddressModel(
      street: '112 Eastern Main Road',
      city: 'St. Augustine',
      state: 'Tunapuna-Piarco',
      country: 'Trinidad and Tobago',
      postalCode: '350101',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_member_005',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_005',
    accessIds: ['access_venue_manager', 'access_search'],
    referralCode: 'VENUEFIND',
    organiserOfIds: [],
    listingIds: ['listing_013', 'listing_014', 'listing_015', 'listing_016'],
    invitationIds: ['invite_007'],
    teamIds: ['team_007'],
    joinedAt: DateTime(2024, 5, 12),
    lastActiveAt: DateTime(2025, 5, 5),
  ),
  MemberDTO(
    id: 'member_006',
    createdAt: DateTime(2024, 6, 8),
    updatedAt: DateTime(2025, 5, 1),
    fcmToken: 'fcm_token_member_006_jkl012',
    name: 'Lisa-Marie James',
    email: 'lisamarie.james@weddingplanner.tt',
    imageUrl: 'https://randomuser.me/api/portraits/women/6.jpg',
    bio:
        'Luxury wedding planner specializing in destination weddings in the Caribbean',
    gender: 'Female',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/weddingplanner_lm',
        pinterest: 'https://pinterest.com/weddingplannerlm',
        whatsapp: '18686789012',
        telegram: 'https://t.me/lisamariejames',
      ),
      email: 'lisamarie.james@weddingplanner.tt',
      phone: '+1-868-678-9012',
      website: 'https://weddingplanner.tt',
    ),
    address: AddressModel(
      street: '7 Maraval Road',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120104',
    ),
    language: 'en',
    currency: 'USD',
    walletId: 'wallet_member_006',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_006',
    accessIds: ['access_event_creator', 'access_premium'],
    referralCode: 'WEDDINGPRO',
    organiserOfIds: ['event_015', 'event_016', 'event_017'],
    listingIds: ['listing_017', 'listing_018'],
    invitationIds: ['invite_008', 'invite_009'],
    teamIds: ['team_008'],
    joinedAt: DateTime(2024, 6, 8),
    lastActiveAt: DateTime(2025, 5, 1),
  ),
  MemberDTO(
    id: 'member_007',
    createdAt: DateTime(2024, 7, 3),
    updatedAt: DateTime(2025, 4, 28),
    fcmToken: 'fcm_token_member_007_mno345',
    name: 'Anthony Gomes',
    email: 'anthony.gomes@cateringcaribbean.com',
    imageUrl: 'https://randomuser.me/api/portraits/men/7.jpg',
    bio: 'Professional caterer for large-scale events and festivals',
    gender: 'Male',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        facebook: 'https://facebook.com/cateringcaribbean',
        instagram: 'https://instagram.com/cateringcaribbean',
        tripadvisor: 'https://tripadvisor.com/cateringcaribbean',
      ),
      email: 'anthony.gomes@cateringcaribbean.com',
      phone: '+1-868-789-0123',
      website: 'https://cateringcaribbean.com',
    ),
    address: AddressModel(
      street: '34 Western Main Road',
      city: 'St. James',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120105',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_member_007',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_007',
    accessIds: ['access_event_creator', 'access_catering'],
    referralCode: 'CATERPRO',
    organiserOfIds: ['event_018', 'event_019'],
    listingIds: ['listing_019', 'listing_020'],
    invitationIds: [],
    teamIds: ['team_009'],
    joinedAt: DateTime(2024, 7, 3),
    lastActiveAt: DateTime(2025, 4, 28),
  ),
  MemberDTO(
    id: 'member_008',
    createdAt: DateTime(2024, 8, 15),
    updatedAt: DateTime(2025, 4, 20),
    fcmToken: null,
    name: 'Renuka Maharaj',
    email: 'renuka.maharaj@culturalheritage.tt',
    imageUrl: 'https://randomuser.me/api/portraits/women/8.jpg',
    bio: 'Preserving and promoting Caribbean cultural heritage through events',
    gender: 'Female',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        facebook: 'https://facebook.com/culturalheritagett',
        youtube: 'https://youtube.com/caribbeanheritage',
        linkedin: 'https://linkedin.com/in/renukamaharaj',
      ),
      email: 'renuka.maharaj@culturalheritage.tt',
      phone: '+1-868-890-1234',
      website: 'https://culturalheritage.tt',
    ),
    address: AddressModel(
      street: '56 High Street',
      city: 'San Fernando',
      state: 'San Fernando',
      country: 'Trinidad and Tobago',
      postalCode: '720101',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_member_008',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_008',
    accessIds: ['access_event_creator', 'access_admin'],
    referralCode: 'CULTUREHER',
    organiserOfIds: ['event_020', 'event_021', 'event_022'],
    listingIds: ['listing_021', 'listing_022'],
    invitationIds: ['invite_010'],
    teamIds: ['team_010'],
    joinedAt: DateTime(2024, 8, 15),
    lastActiveAt: DateTime(2025, 4, 20),
  ),
  MemberDTO(
    id: 'member_009',
    createdAt: DateTime(2024, 9, 1),
    updatedAt: DateTime(2025, 4, 15),
    fcmToken: 'fcm_token_member_009_pqr678',
    name: 'Kevin La Ronde',
    email: 'kevin.laronde@musicfest.tt',
    imageUrl: 'https://randomuser.me/api/portraits/men/9.jpg',
    bio:
        'Music festival organizer bringing international artists to the Caribbean',
    gender: 'Male',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/musicfesttt',
        twitter: 'https://twitter.com/musicfesttt',
        eventbrite: 'https://eventbrite.com/o/kevin-laronde',
        tiktok: 'https://tiktok.com/@musicfesttt',
      ),
      email: 'kevin.laronde@musicfest.tt',
      phone: '+1-868-901-2345',
      website: 'https://musicfest.tt',
    ),
    address: AddressModel(
      street: '89 Ariapita Avenue',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120106',
    ),
    language: 'en',
    currency: 'USD',
    walletId: 'wallet_member_009',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_009',
    accessIds: ['access_event_creator', 'access_sponsorship', 'access_premium'],
    referralCode: 'MUSICFEST24',
    organiserOfIds: ['event_023', 'event_024', 'event_025', 'event_026'],
    listingIds: ['listing_023', 'listing_024', 'listing_025'],
    invitationIds: ['invite_011', 'invite_012', 'invite_013'],
    teamIds: ['team_011', 'team_012'],
    joinedAt: DateTime(2024, 9, 1),
    lastActiveAt: DateTime(2025, 4, 15),
  ),
  MemberDTO(
    id: 'member_010',
    createdAt: DateTime(2024, 10, 10),
    updatedAt: DateTime(2025, 4, 10),
    fcmToken: 'fcm_token_member_010_stu901',
    name: 'Maria Rodriguez',
    email: 'maria.rodriguez@eventtech.tt',
    imageUrl: 'https://randomuser.me/api/portraits/women/10.jpg',
    bio: 'Event technology consultant helping organizers go digital',
    gender: 'Female',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        linkedin: 'https://linkedin.com/in/mariarodriguez',
        twitter: 'https://twitter.com/eventtechtt',
        website: 'https://eventtech.tt',
        meetup: 'https://meetup.com/eventtechtt',
      ),
      email: 'maria.rodriguez@eventtech.tt',
      phone: '+1-868-012-3456',
      website: 'https://eventtech.tt',
    ),
    address: AddressModel(
      street: '123 Maraval Road',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120107',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_member_010',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_010',
    accessIds: ['access_admin', 'access_tech_support'],
    referralCode: 'TECHGURU',
    organiserOfIds: ['event_027', 'event_028'],
    listingIds: ['listing_026', 'listing_027'],
    invitationIds: ['invite_014'],
    teamIds: ['team_013'],
    joinedAt: DateTime(2024, 10, 10),
    lastActiveAt: DateTime(2025, 4, 10),
  ),
  MemberDTO(
    id: 'member_011',
    createdAt: DateTime(2024, 11, 5),
    updatedAt: DateTime(2025, 4, 5),
    fcmToken: 'fcm_token_member_011_vwx234',
    name: 'Winston Duke',
    email: 'winston.duke@sportsmanagement.tt',
    imageUrl: 'https://randomuser.me/api/portraits/men/11.jpg',
    bio: 'Sports event manager handling major sporting events in the Caribbean',
    gender: 'Male',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        facebook: 'https://facebook.com/sportsmanagementtt',
        instagram: 'https://instagram.com/sportsmanagement',
        linkedin: 'https://linkedin.com/in/winstonsports',
      ),
      email: 'winston.duke@sportsmanagement.tt',
      phone: '+1-868-123-4567',
      website: 'https://sportsmanagement.tt',
    ),
    address: AddressModel(
      street: '56 Queen\'s Park West',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120108',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_member_011',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_011',
    accessIds: ['access_event_creator', 'access_sports'],
    referralCode: 'SPORTSDIR',
    organiserOfIds: ['event_029', 'event_030', 'event_031'],
    listingIds: ['listing_028', 'listing_029', 'listing_030'],
    invitationIds: ['invite_015', 'invite_016'],
    teamIds: ['team_014'],
    joinedAt: DateTime(2024, 11, 5),
    lastActiveAt: DateTime(2025, 4, 5),
  ),
  MemberDTO(
    id: 'member_012',
    createdAt: DateTime(2024, 12, 1),
    updatedAt: DateTime(2025, 4, 1),
    fcmToken: null,
    name: 'Cheryl Ann Peters',
    email: 'cheryl.peters@artgallery.tt',
    imageUrl: 'https://randomuser.me/api/portraits/women/12.jpg',
    bio:
        'Art curator and exhibition organizer for local and international artists',
    gender: 'Female',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/artgallerytt',
        pinterest: 'https://pinterest.com/artgallerytt',
        website: 'https://artgallery.tt',
        linkedin: 'https://linkedin.com/in/cherylpeters',
      ),
      email: 'cheryl.peters@artgallery.tt',
      phone: '+1-868-234-5678',
      website: 'https://artgallery.tt',
    ),
    address: AddressModel(
      street: '78 Frederick Street',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120109',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_member_012',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_012',
    accessIds: ['access_event_creator', 'access_curator'],
    referralCode: 'ARTCURATOR',
    organiserOfIds: ['event_032', 'event_033'],
    listingIds: ['listing_031', 'listing_032'],
    invitationIds: [],
    teamIds: ['team_015'],
    joinedAt: DateTime(2024, 12, 1),
    lastActiveAt: DateTime(2025, 4, 1),
  ),
  MemberDTO(
    id: 'member_013',
    createdAt: DateTime(2025, 1, 8),
    updatedAt: DateTime(2025, 3, 28),
    fcmToken: 'fcm_token_member_013_yza567',
    name: 'Brian Lara',
    email: 'brian.lara@charityevents.tt',
    imageUrl: 'https://randomuser.me/api/portraits/men/13.jpg',
    bio: 'Charity event organizer raising funds for children\'s education',
    gender: 'Male',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        facebook: 'https://facebook.com/charityevents',
        twitter: 'https://twitter.com/charityevents',
        instagram: 'https://instagram.com/charityevents',
      ),
      email: 'brian.lara@charityevents.tt',
      phone: '+1-868-345-6789',
      website: 'https://charityevents.tt',
    ),
    address: AddressModel(
      street: '9 Abercromby Street',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120110',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_member_013',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_013',
    accessIds: ['access_event_creator', 'access_charity'],
    referralCode: 'CHARITYPRO',
    organiserOfIds: ['event_034', 'event_035', 'event_036'],
    listingIds: ['listing_033', 'listing_034'],
    invitationIds: ['invite_017'],
    teamIds: ['team_016'],
    joinedAt: DateTime(2025, 1, 8),
    lastActiveAt: DateTime(2025, 3, 28),
  ),
  MemberDTO(
    id: 'member_014',
    createdAt: DateTime(2025, 2, 14),
    updatedAt: DateTime(2025, 3, 25),
    fcmToken: 'fcm_token_member_014_bcd890',
    name: 'Nadia Ali',
    email: 'nadia.ali@foodfestival.tt',
    imageUrl: 'https://randomuser.me/api/portraits/women/14.jpg',
    bio: 'Food festival organizer celebrating Caribbean cuisine and culture',
    gender: 'Female',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        instagram: 'https://instagram.com/foodfestivaltt',
        youtube: 'https://youtube.com/caribbeanfood',
        tripadvisor: 'https://tripadvisor.com/foodfestival',
        eventbrite: 'https://eventbrite.com/o/nadia-ali',
      ),
      email: 'nadia.ali@foodfestival.tt',
      phone: '+1-868-456-7890',
      website: 'https://foodfestival.tt',
    ),
    address: AddressModel(
      street: '101 Tragarete Road',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120111',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_member_014',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_014',
    accessIds: ['access_event_creator', 'access_food_industry'],
    referralCode: 'FOODIE24',
    organiserOfIds: ['event_037', 'event_038', 'event_039', 'event_040'],
    listingIds: ['listing_035', 'listing_036', 'listing_037'],
    invitationIds: ['invite_018', 'invite_019'],
    teamIds: ['team_017'],
    joinedAt: DateTime(2025, 2, 14),
    lastActiveAt: DateTime(2025, 3, 25),
  ),
  MemberDTO(
    id: 'member_015',
    createdAt: DateTime(2025, 3, 20),
    updatedAt: DateTime(2025, 5, 22),
    fcmToken: 'fcm_token_member_015_efg123',
    name: 'Peter Smith',
    email: 'peter.smith@conventioncenter.tt',
    imageUrl: 'https://randomuser.me/api/portraits/men/15.jpg',
    bio: 'Convention center manager coordinating large-scale conferences',
    gender: 'Male',
    contactInfo: const ContactInfo(
      socialLinks: SocialLinks(
        linkedin: 'https://linkedin.com/in/petersmith',
        website: 'https://conventioncenter.tt',
        expedia: 'https://expedia.com/partners/conventioncenter',
      ),
      email: 'peter.smith@conventioncenter.tt',
      phone: '+1-868-567-8901',
      website: 'https://conventioncenter.tt',
    ),
    address: AddressModel(
      street: '1 Wrightson Road',
      city: 'Port of Spain',
      state: 'Port of Spain',
      country: 'Trinidad and Tobago',
      postalCode: '120112',
    ),
    language: 'en',
    currency: 'TTD',
    walletId: 'wallet_member_015',
    isActive: true,
    isBanned: false,
    banReason: null,
    organisationId: 'org_015',
    accessIds: ['access_admin', 'access_venue_manager', 'access_premium'],
    referralCode: 'CONVPRO',
    organiserOfIds: ['event_041', 'event_042', 'event_043'],
    listingIds: ['listing_038', 'listing_039'],
    invitationIds: ['invite_020'],
    teamIds: ['team_018', 'team_019'],
    joinedAt: DateTime(2025, 3, 20),
    lastActiveAt: DateTime(2025, 5, 22),
  ),
];
