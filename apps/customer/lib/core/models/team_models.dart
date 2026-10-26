import 'package:lehwipalancecustomerv1/core/auth/permission_service.dart';
import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';
import 'package:lehwipalancecustomerv1/core/utils/validators.dart';

class TeamDTO implements Identifiable, Timestamped, PermissionHolder {
  @override
  final String id;
  final String name;
  final String? description;
  final String organisationId;
  final String listingId;
  final List<String> memberIds;
  final List<String>
  permissionStrings; // Renamed from 'permissions' to avoid confusion
  final String? roleLabel;
  final bool isActive;
  final DateTime? expiresAt;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  const TeamDTO({
    required this.id,
    required this.name,
    this.description,
    required this.organisationId,
    required this.listingId,
    this.memberIds = const [],
    this.permissionStrings = const [],
    this.roleLabel,
    this.isActive = true,
    this.expiresAt,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isActiveAndValid => isActive && !isExpired;
  // Add role permissions map
  Map<String, List<Permission>> get rolePermissions {
    return {
      'admin': Permission.organiserPermissions,
      'manager': Permission.contentManagerPermissions,
      'lead_guide': Permission.contentManagerPermissions,
      'staff': Permission.supportStaffPermissions,
      'viewer': Permission.viewerPermissions,
    };
  }

  // Convert to list of strings for UI display
  Map<String, List<String>> get rolePermissionStrings {
    return rolePermissions.map(
      (key, value) => MapEntry(key, Permission.toStrings(value)),
    );
  }

  @override
  List<Permission> getPermissions() {
    if (!isActiveAndValid) return [];
    return Permission.fromStrings(permissionStrings);
  }

  @override
  bool hasPermission(Permission permission) {
    return isActiveAndValid && permissionStrings.contains(permission.value);
  }

  @override
  bool hasAllPermissions(List<Permission> required) {
    if (!isActiveAndValid) return false;
    return required.every((p) => permissionStrings.contains(p.value));
  }

  @override
  bool hasAnyPermission(List<Permission> required) {
    if (!isActiveAndValid) return false;
    return required.any((p) => permissionStrings.contains(p.value));
  }

  // Convenience methods
  bool hasMember(String userId) => memberIds.contains(userId);

  int get memberCount => memberIds.length;

  bool get canAddMembers => memberCount < ValidationUtils.maxTeamMembers;

  TeamDTO addMember(String userId) {
    if (memberIds.length >= ValidationUtils.maxTeamMembers) {
      throw ValidationException(
        'Max members (${ValidationUtils.maxTeamMembers}) reached for team $id',
      );
    }
    if (memberIds.contains(userId)) {
      return this; // Already a member
    }
    return copyWith(
      memberIds: [...memberIds, userId],
      updatedAt: DateTime.now(),
    );
  }

  TeamDTO addMembers(List<String> userIds) {
    if (memberIds.length + userIds.length > ValidationUtils.maxTeamMembers) {
      throw ValidationException(
        'Adding ${userIds.length} members would exceed max limit of ${ValidationUtils.maxTeamMembers}',
      );
    }
    final newMembers = [...memberIds];
    for (final userId in userIds) {
      if (!newMembers.contains(userId)) {
        newMembers.add(userId);
      }
    }
    return copyWith(memberIds: newMembers, updatedAt: DateTime.now());
  }

  TeamDTO removeMember(String userId) {
    if (!memberIds.contains(userId)) {
      return this; // Not a member
    }
    return copyWith(
      memberIds: memberIds.where((id) => id != userId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  TeamDTO updatePermissions(List<Permission> newPermissions) {
    return copyWith(
      permissionStrings: Permission.toStrings(newPermissions),
      updatedAt: DateTime.now(),
    );
  }

  TeamDTO updatePermissionStrings(List<String> newPermissionStrings) {
    return copyWith(
      permissionStrings: newPermissionStrings,
      updatedAt: DateTime.now(),
    );
  }

  TeamDTO copyWith({
    String? id,
    String? name,
    String? description,
    String? organisationId,
    String? listingId,
    List<String>? memberIds,
    List<String>? permissionStrings,
    String? roleLabel,
    bool? isActive,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamDTO(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      organisationId: organisationId ?? this.organisationId,
      listingId: listingId ?? this.listingId,
      memberIds: memberIds ?? this.memberIds,
      permissionStrings: permissionStrings ?? this.permissionStrings,
      roleLabel: roleLabel ?? this.roleLabel,
      isActive: isActive ?? this.isActive,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'organisationId': organisationId,
      'listingId': listingId,
      'memberIds': memberIds,
      'permissionStrings': permissionStrings,
      'roleLabel': roleLabel,
      'isActive': isActive,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
    map.removeWhere((key, value) => value == null);
    return map;
  }

  factory TeamDTO.fromJson(Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return null;
    }

    return TeamDTO(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      organisationId: json['organisationId'] ?? '',
      listingId: json['listingId'] ?? '',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      permissionStrings: List<String>.from(
        json['permissionStrings'] ?? json['permissions'] ?? [],
      ), // Backward compatible
      roleLabel: json['roleLabel'],
      isActive: json['isActive'] ?? true,
      expiresAt: parseDateTime(json['expiresAt']),
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  // Factory method for creating a new team
  factory TeamDTO.create({
    required String name,
    required String organisationId,
    required String listingId,
    String? description,
    List<String>? memberIds,
    List<Permission>? permissions,
    String? roleLabel,
    bool isActive = true,
    DateTime? expiresAt,
  }) {
    final now = DateTime.now();
    return TeamDTO(
      id: '', // Will be set by repository
      name: name,
      description: description,
      organisationId: organisationId,
      listingId: listingId,
      memberIds: memberIds ?? [],
      permissionStrings: permissions != null
          ? Permission.toStrings(permissions)
          : [],
      roleLabel: roleLabel,
      isActive: isActive,
      expiresAt: expiresAt,
      createdAt: now,
      updatedAt: now,
    );
  }
}
// =====================================================
// SYNCED TEAM DTO WITH CORRECT PERMISSIONS
// =====================================================

final List<TeamDTO> mockTeams = [
  // ========== ORGANISATION 001 TEAMS (Caribbean Events Pro) ==========
  TeamDTO(
    id: 'team_events',
    name: 'Event Management Team',
    description: 'Core team responsible for planning and executing events',
    organisationId: 'org_001',
    listingId: 'evt_001',
    memberIds: ['member_001', 'member_002'],
    permissionStrings: Permission.toStrings([
      Permission.viewListing,
      Permission.createListing,
      Permission.editListing,
      Permission.publishListing,
      Permission.viewTickets,
      Permission.manageTickets,
      Permission.viewBookings,
      Permission.manageBookings,
      Permission.viewAnalytics,
    ]),
    roleLabel: 'Event Manager',
    isActive: true,
    expiresAt: null,
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 6, 20),
  ),

  TeamDTO(
    id: 'team_marketing',
    name: 'Marketing Team',
    description: 'Responsible for event promotion and social media',
    organisationId: 'org_001',
    listingId: 'evt_001',
    memberIds: ['member_001'],
    permissionStrings: Permission.toStrings([
      Permission.viewListing,
      Permission.editContent,
      Permission.uploadMedia,
      Permission.viewAnalytics,
    ]),
    roleLabel: 'Marketing Lead',
    isActive: true,
    expiresAt: null,
    createdAt: DateTime(2024, 2, 1),
    updatedAt: DateTime(2024, 5, 15),
  ),

  TeamDTO(
    id: 'team_tourism',
    name: 'Tourism Management',
    description: 'Manages tourism-related listings and venues',
    organisationId: 'org_001',
    listingId: 'plc_001',
    memberIds: ['member_001', 'member_004'],
    permissionStrings: Permission.toStrings([
      Permission.viewListing,
      Permission.createListing,
      Permission.editListing,
      Permission.viewBookings,
      Permission.manageBookings,
    ]),
    roleLabel: 'Tourism Coordinator',
    isActive: true,
    expiresAt: null,
    createdAt: DateTime(2024, 3, 10),
    updatedAt: DateTime(2024, 7, 1),
  ),

  TeamDTO(
    id: 'team_ai_summit',
    name: 'AI Summit Team',
    description: 'Specialized team for AI and tech events',
    organisationId: 'org_001',
    listingId: 'evt_003',
    memberIds: ['member_001', 'member_010'],
    permissionStrings: Permission.toStrings([
      Permission.viewListing,
      Permission.createListing,
      Permission.editListing,
      Permission.publishListing,
      Permission.viewTickets,
      Permission.manageTickets,
      Permission.exportData,
    ]),
    roleLabel: 'Tech Event Organizer',
    isActive: true,
    expiresAt: DateTime(2025, 6, 1),
    createdAt: DateTime(2024, 8, 1),
    updatedAt: DateTime(2024, 11, 15),
  ),

  // ========== ORGANISATION 002 TEAMS (Tobago Events & Hospitality) ==========
  TeamDTO(
    id: 'team_production',
    name: 'Event Production Team',
    description: 'Handles event setup, AV, and logistics',
    organisationId: 'org_002',
    listingId: 'evt_002',
    memberIds: ['member_002', 'member_009'],
    permissionStrings: Permission.toStrings([
      Permission.viewListing,
      Permission.editListing,
      Permission.viewTickets,
      Permission.manageTickets,
    ]),
    roleLabel: 'Production Manager',
    isActive: true,
    expiresAt: null,
    createdAt: DateTime(2024, 2, 10),
    updatedAt: DateTime(2024, 8, 15),
  ),

  TeamDTO(
    id: 'team_bookings',
    name: 'Bookings & Reservations',
    description: 'Manages ticket sales and booking systems',
    organisationId: 'org_002',
    listingId: 'evt_002',
    memberIds: ['member_002'],
    permissionStrings: Permission.toStrings([
      Permission.viewBookings,
      Permission.manageBookings,
      Permission.viewTickets,
      Permission.manageTickets,
      Permission.viewAnalytics,
    ]),
    roleLabel: 'Booking Coordinator',
    isActive: true,
    expiresAt: null,
    createdAt: DateTime(2024, 3, 5),
    updatedAt: DateTime(2024, 9, 10),
  ),

  // ========== ORGANISATION 003 TEAMS (Caribbean Hotel Group) ==========
  TeamDTO(
    id: 'team_hotel_ops',
    name: 'Hotel Operations',
    description: 'Manages hotel bookings and guest services',
    organisationId: 'org_003',
    listingId: 'htl_001',
    memberIds: ['member_003', 'member_005'],
    permissionStrings: Permission.toStrings([
      Permission.viewListing,
      Permission.createListing,
      Permission.editListing,
      Permission.viewBookings,
      Permission.manageBookings,
      Permission.manageBilling,
    ]),
    roleLabel: 'Hotel Manager',
    isActive: true,
    expiresAt: null,
    createdAt: DateTime(2024, 3, 5),
    updatedAt: DateTime(2024, 10, 1),
  ),

  TeamDTO(
    id: 'team_spa',
    name: 'Spa & Wellness Services',
    description: 'Manages spa services and wellness programs',
    organisationId: 'org_003',
    listingId: 'srv_001',
    memberIds: ['member_003', 'member_006'],
    permissionStrings: Permission.toStrings([
      Permission.viewListing,
      Permission.editListing,
      Permission.viewBookings,
      Permission.manageBookings,
      Permission.editContent,
      Permission.uploadMedia,
    ]),
    roleLabel: 'Wellness Director',
    isActive: true,
    expiresAt: null,
    createdAt: DateTime(2024, 4, 1),
    updatedAt: DateTime(2024, 11, 5),
  ),

  TeamDTO(
    id: 'team_concierge',
    name: 'Concierge Services',
    description: 'Guest services and experience management',
    organisationId: 'org_003',
    listingId: 'htl_001',
    memberIds: ['member_003', 'member_007'],
    permissionStrings: Permission.toStrings([
      Permission.viewListing,
      Permission.viewBookings,
      Permission.manageBookings,
      Permission.viewTickets,
    ]),
    roleLabel: 'Head Concierge',
    isActive: true,
    expiresAt: null,
    createdAt: DateTime(2024, 5, 10),
    updatedAt: DateTime(2024, 12, 1),
  ),

  // ========== ORGANISATION 004 TEAMS (Caribbean Cultural Festivals) ==========
  TeamDTO(
    id: 'team_cultural',
    name: 'Cultural Events Team',
    description: 'Organizes cultural festivals and heritage events',
    organisationId: 'org_004',
    listingId: 'evt_005', // Soca & Steelpan Night
    memberIds: ['member_004', 'member_001'],
    permissionStrings: Permission.toStrings([
      Permission.viewListing,
      Permission.createListing,
      Permission.editListing,
      Permission.publishListing,
      Permission.viewMembers,
      Permission.inviteMembers,
      Permission.viewAnalytics,
    ]),
    roleLabel: 'Cultural Director',
    isActive: true,
    expiresAt: null,
    createdAt: DateTime(2024, 4, 20),
    updatedAt: DateTime(2024, 8, 15),
  ),

  // ========== ORGANISATION 009 TEAMS (Music Fest Caribbean) ==========
  TeamDTO(
    id: 'team_music',
    name: 'Music Events Team',
    description: 'Organizes music festivals and concerts',
    organisationId: 'org_009',
    listingId: 'evt_002',
    memberIds: ['member_009', 'member_001'],
    permissionStrings: Permission.toStrings([
      Permission.viewListing,
      Permission.createListing,
      Permission.editListing,
      Permission.viewTickets,
      Permission.manageTickets,
      Permission.uploadMedia,
    ]),
    roleLabel: 'Music Event Coordinator',
    isActive: true,
    expiresAt: null,
    createdAt: DateTime(2024, 6, 1),
    updatedAt: DateTime(2024, 12, 10),
  ),

  // ========== ORGANISATION 010 TEAMS (Event Tech Solutions) ==========
  TeamDTO(
    id: 'team_tech',
    name: 'Event Technology',
    description: 'Provides tech solutions for events',
    organisationId: 'org_010',
    listingId: 'evt_001',
    memberIds: ['member_010', 'member_001'],
    permissionStrings: Permission.toStrings([
      Permission.viewListing,
      Permission.viewAnalytics,
      Permission.exportData,
      Permission.viewBookings,
    ]),
    roleLabel: 'Technical Director',
    isActive: true,
    expiresAt: null,
    createdAt: DateTime(2024, 7, 15),
    updatedAt: DateTime(2025, 1, 10),
  ),

  // ========== TEAM WITH EXPIRY DATE (Seasonal Team) ==========
  TeamDTO(
    id: 'team_carnival',
    name: 'Carnival Festival Team',
    description: 'Seasonal team for Carnival events',
    organisationId: 'org_002',
    listingId: 'evt_002',
    memberIds: ['member_002', 'member_009', 'member_004'],
    permissionStrings: Permission.toStrings([
      Permission.viewListing,
      Permission.createListing,
      Permission.editListing,
      Permission.publishListing,
      Permission.viewMembers,
      Permission.inviteMembers,
    ]),
    roleLabel: 'Carnival Coordinator',
    isActive: true,
    expiresAt: DateTime(2025, 3, 15),
    createdAt: DateTime(2024, 10, 1),
    updatedAt: DateTime(2025, 1, 20),
  ),

  // ========== ADMIN TEAM WITH FULL ACCESS ==========
  TeamDTO(
    id: 'team_admin',
    name: 'Organization Administrators',
    description: 'Full system access for organisation owners',
    organisationId: 'org_001',
    listingId: 'evt_001', // Primary listing
    memberIds: ['member_001'],
    permissionStrings: Permission.toStrings(Permission.organiserPermissions),
    roleLabel: 'Organisation Admin',
    isActive: true,
    expiresAt: null,
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 15),
  ),
];
