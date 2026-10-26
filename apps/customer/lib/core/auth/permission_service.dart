import 'package:lehwipalancecustomerv1/core/utils/validators.dart';

abstract class PermissionHolder {
  List<Permission> getPermissions();

  bool hasPermission(Permission permission) {
    return getPermissions().contains(permission);
  }

  bool hasAllPermissions(List<Permission> permissions) {
    return permissions.every((p) => getPermissions().contains(p));
  }

  bool hasAnyPermission(List<Permission> permissions) {
    return permissions.any((p) => getPermissions().contains(p));
  }
}

enum Permission {
  viewListing('view_listing', 'Can view listing details'),
  createListing('create_listing', 'Can create new listings'),
  editListing('edit_listing', 'Can edit listing details'),
  deleteListing('delete_listing', 'Can delete listings'),
  publishListing('publish_listing', 'Can publish/unpublish listings'),
  viewMembers('view_members', 'Can view members'),
  inviteMembers('invite_members', 'Can invite new members'),
  removeMembers('remove_members', 'Can remove members'),
  manageRoles('manage_roles', 'Can manage member roles'),
  editOrganisation('edit_organisation', 'Can edit organisation details'),
  deleteOrganisation('delete_organisation', 'Can delete organisation'),
  manageBilling('manage_billing', 'Can manage billing'),
  viewAnalytics('view_analytics', 'Can view analytics'),
  viewBookings('view_bookings', 'Can view bookings'),
  manageBookings('manage_bookings', 'Can manage bookings'),
  viewTickets('view_tickets', 'Can view tickets'),
  manageTickets('manage_tickets', 'Can manage tickets'),
  editContent('edit_content', 'Can edit content'),
  deleteContent('delete_content', 'Can delete content'),
  uploadMedia('upload_media', 'Can upload media'),
  exportData('export_data', 'Can export data'),
  transferOwnership('transfer_ownership', 'Can transfer ownership'),
  delegateAccess('delegate_access', 'Can delegate access'),
  manageAll('manage_all', 'Full system access - Organiser only');

  final String value;
  final String description;

  const Permission(this.value, this.description);

  static Permission fromString(String value) {
    return values.firstWhere(
      (p) => p.value == value,
      orElse: () => throw ValidationException('Invalid permission: $value'),
    );
  }

  static List<Permission> fromStrings(List<String> values) {
    return values.map((v) => fromString(v)).toList();
  }

  static List<String> toStrings(List<Permission> permissions) {
    return permissions.map((p) => p.value).toList();
  }

  static List<Permission> get organiserPermissions => values.toList();
  static List<Permission> get contentManagerPermissions => [
    viewListing,
    createListing,
    editListing,
    publishListing,
    viewBookings,
    manageBookings,
    viewTickets,
    manageTickets,
    editContent,
    uploadMedia,
    viewAnalytics,
  ];
  static List<Permission> get supportStaffPermissions => [
    viewListing,
    viewMembers,
    viewBookings,
    viewTickets,
    manageBookings,
    manageTickets,
  ];
  static List<Permission> get viewerPermissions => [
    viewListing,
    viewBookings,
    viewTickets,
  ];
}

class PermissionCache {
  final Duration ttl;
  final Map<String, _CacheEntry<bool>> _cache = {};

  PermissionCache({this.ttl = const Duration(minutes: 5)});

  Future<bool> check(
    String userId,
    String contextId,
    Permission permission,
    Future<bool> Function() checker,
  ) async {
    final key = '${userId}_${contextId}_${permission.value}';
    if (_cache.containsKey(key) && !_cache[key]!.isExpired) {
      return _cache[key]!.value;
    }
    final result = await checker();
    _cache[key] = _CacheEntry(result, DateTime.now().add(ttl));
    return result;
  }

  void invalidateForUser(String userId) =>
      _cache.removeWhere((k, _) => k.startsWith('${userId}_'));
  void clearAll() => _cache.clear();
}

class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;
  _CacheEntry(this.value, this.expiresAt);
  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
