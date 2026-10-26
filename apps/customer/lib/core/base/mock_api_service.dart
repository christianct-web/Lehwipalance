import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';
import 'package:lehwipalancecustomerv1/core/base/paginated_result.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/media_model.dart';
import 'package:lehwipalancecustomerv1/core/models/inquiries_model.dart';
import 'package:lehwipalancecustomerv1/core/models/media_feed_model.dart';
import 'package:lehwipalancecustomerv1/core/models/messages_model.dart';

import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';
import 'package:lehwipalancecustomerv1/core/models/invitation_model.dart';
import 'package:lehwipalancecustomerv1/core/models/organisation_model.dart';
import 'package:lehwipalancecustomerv1/core/models/receipt_model.dart';
import 'package:lehwipalancecustomerv1/core/models/room_model.dart';
import 'package:lehwipalancecustomerv1/core/models/service_item_model.dart';
import 'package:lehwipalancecustomerv1/core/models/team_models.dart';
import 'package:lehwipalancecustomerv1/core/models/ticket_model.dart';
import 'package:lehwipalancecustomerv1/core/models/user_models.dart';
import 'package:lehwipalancecustomerv1/core/models/waller_model.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

import 'package:uuid/uuid.dart';

// ==================== MOCK DATABASE ====================
// lib/services/api/mock_database.dart (updated)

class MockDatabase {
  static final Map<String, UserDTO> users = {};
  static final Map<String, CustomerDTO> customers = {};
  static final Map<String, MemberDTO> members = {};
  static final Map<String, InvitationDTO> invitations = {};
  static final Map<String, MerchantListingDTO> merchantListings = {};
  static final Map<String, OrganisationDTO> organisations = {};
  static final Map<String, TeamDTO> teams = {};
  static final Map<String, ServiceItemDTO> services = {};
  static final Map<String, RoomDTO> rooms = {};
  static final Map<String, TicketDTO> tickets = {};
  static final Map<String, Receipt> receipts = {};
  static final Map<String, Inquiry> inquiries = {};
  static final Map<String, LocationModel> locations = {};
  static final Map<String, Map<String, dynamic>> bookings = {};
  static final Map<String, Map<String, dynamic>> purchases = {};
  static final Map<String, WalletModel> wallets = {};
  static final Map<String, BaseMethod> paymentMethods = {};
  // Media Feed Data
  static final Map<String, MediaFeedItem> mediaFeedItems = {};
  static final Map<String, List<MediaComment>> mediaComments = {};
  static final Map<String, List<TransactionModel>> transactions = {};
  static void _initializeMockData() {
    // Clear all maps
    users.clear();
    customers.clear();
    members.clear();
    teams.clear();
    organisations.clear();
    merchantListings.clear();
    locations.clear();
    invitations.clear();
    tickets.clear();
    services.clear();
    rooms.clear();
    receipts.clear();
    inquiries.clear();
    mediaFeedItems.clear();
    mediaComments.clear();
    wallets.clear();
    paymentMethods.clear();
    transactions.clear();
    for (final method in mockPaymentMethods) {
      paymentMethods[method.id] = method;
    }

    for (final org in mockOrganisations) {
      organisations[org.id] = org;
    }

    // Add mock merchant listings
    debugPrint(
      'Loading ${mockAllMerchantListingDTOs.length} merchant listings',
    );
    for (final listing in mockAllMerchantListingDTOs) {
      merchantListings[listing.id] = listing;
    }

    // Add mock teams
    for (final team in mockTeams) {
      teams[team.id] = team;
    }

    // Add mock invitations
    for (final invitation in mockInvitations) {
      invitations[invitation.id] = invitation;
    }

    // Add mock locations
    for (final location in mockLocations) {
      locations[location.id] = location;
    }

    // Add mock services
    for (final service in mockServiceItems) {
      services[service.id] = service;
    }

    // Add mock rooms
    for (final room in mockRooms) {
      rooms[room.id] = room;
    }

    // Add mock receipts
    for (final receipt in mockReceipts) {
      receipts[receipt.id] = receipt;
    }

    // Add mock tickets
    for (final ticket in testTickets) {
      tickets[ticket.id] = ticket;
    }

    // Add mock inquiries
    for (final inquiry in mockInquiries) {
      inquiries[inquiry.id] = inquiry;
    }

    // Add mock MemberDTOs
    for (final member in mockMemberDTOs) {
      members[member.id] = member;
      users[member.id] = member;
      users[member.email] = member;
    }

    // Add mock CustomerDTOs
    for (final customer in mockCustomerDTOs) {
      customers[customer.id] = customer;
      users[customer.id] = customer;
      users[customer.email] = customer;
    }
    // Initialize media feed items from mock data
    for (final item in mockMediaFeedItems) {
      mediaFeedItems[item.id] = item;
    }

    // Initialize mock comments for each media item
    for (final item in mediaFeedItems.values) {
      mediaComments[item.id] = List.generate(
        5,
        (index) => MediaComment(
          id: 'comment_${item.id}_$index',
          mediaId: item.id,
          userId: 'user_$index',
          userName: 'User ${index + 1}',
          userAvatarUrl: null,
          comment: 'Great post! ${index + 1}',
          createdAt: DateTime.now().subtract(Duration(minutes: index * 5)),
          likeCount: (index * 3) % 10,
          isLikedByUser: index % 2 == 0,
        ),
      );
    }

    debugPrint('Organisations loaded: ${organisations.length}');
    debugPrint('Merchant listings loaded: ${merchantListings.length}');
    debugPrint('Members loaded: ${members.length}');
    debugPrint('Inquiries loaded: ${inquiries.length}');
    debugPrint('Media feed items loaded: ${mediaFeedItems.length}');
  }

  static void initialize() {
    _initializeMockData();
  }

  static void reset() {
    initialize();
  }
}

// ==================== COMPLETE MOCK API SERVICE ====================
List<LocationModel> getMockLocations() {
  return List.unmodifiable(mockLocations);
}

class MockApiService implements ApiService {
  final bool simulateNetworkDelay;
  final Duration delayDuration;
  bool _isInitialized = false;
  MockApiService({
    this.simulateNetworkDelay = true,
    this.delayDuration = const Duration(milliseconds: 200),
    AuthProvider? authProvider,
  }) {
    // MockDatabase.initialize();
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    debugPrint('[MockApiService] Initializing mock data...');
    await _simulateDelay();
    MockDatabase.initialize();
    _isInitialized = true;
    debugPrint('[MockApiService] Mock data loaded');
  }

  // ==================== CACHE SYSTEM ====================

  /// Cache storage for all data types
  final Map<String, _CacheEntry> _cache = {};

  /// Cache duration configuration
  static const Duration _defaultCacheDuration = Duration(minutes: 5);

  /// Different cache durations for different data types
  static const Map<Type, Duration> _cacheDurations = {
    // User data - short cache (frequently changes)
    UserDTO: Duration(minutes: 1),
    CustomerDTO: Duration(minutes: 1),
    MemberDTO: Duration(minutes: 1),

    // Static data - longer cache
    OrganisationDTO: Duration(minutes: 10),
    MerchantListingDTO: Duration(minutes: 5),
    LocationModel: Duration(minutes: 15),
    TeamDTO: Duration(minutes: 10),

    // Transaction data - very short cache
    TransactionModel: Duration(seconds: 30),
    WalletModel: Duration(seconds: 30),

    // Media data - medium cache
    MediaFeedItem: Duration(minutes: 3),
    MediaComment: Duration(minutes: 3),

    // Default for others
  };

  // ==================== CACHE HELPER METHODS ====================

  /// Get cache duration for a specific type
  Duration _getCacheDuration<T>() {
    return _cacheDurations[T] ?? _defaultCacheDuration;
  }

  /// Generate cache key from method name and parameters
  String _cacheKey(String methodName, [Map<String, dynamic>? params]) {
    if (params == null || params.isEmpty) {
      return methodName;
    }
    final sortedParams = params.keys.toList()..sort();
    final paramString = sortedParams
        .map((key) => '$key=${params[key]}')
        .join('&');
    return '$methodName?$paramString';
  }

  /// Get cached data if valid
  T? _getFromCache<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // Check if cache is still valid
    if (entry.expiry.isAfter(DateTime.now())) {
      return entry.data as T?;
    }

    // Cache expired, remove it
    _cache.remove(key);
    return null;
  }

  /// Store data in cache
  void _setCache<T>(String key, T data, [Duration? customDuration]) {
    final duration = customDuration ?? _getCacheDuration<T>();
    _cache[key] = _CacheEntry(data: data, expiry: DateTime.now().add(duration));
  }

  /// Invalidate specific cache entries
  void _invalidateCache([String? pattern]) {
    if (pattern == null) {
      _cache.clear();
      return;
    }

    _cache.removeWhere((key, _) => key.startsWith(pattern));
  }

  /// Invalidate cache by type
  void invalidateCacheByType<T>() {
    // Since we can't easily filter by type in the cache, we'll clear all
    // and let the next request repopulate
    _cache.clear();
  }

  /// Clear all cache
  void clearAllCache() {
    _cache.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    int validCount = 0;
    int expiredCount = 0;

    for (final entry in _cache.values) {
      if (entry.expiry.isAfter(now)) {
        validCount++;
      } else {
        expiredCount++;
      }
    }

    return {
      'totalEntries': _cache.length,
      'validEntries': validCount,
      'expiredEntries': expiredCount,
      'keys': _cache.keys.toList(),
    };
  }

  // ==================== CONSTRUCTOR ====================

  Future<void> _simulateDelay() async {
    if (simulateNetworkDelay) {
      await Future.delayed(delayDuration);
    }
  }

  // ==================== USER METHODS ====================

  @override
  Future<UserDTO> upsertUser(UserDTO user) async {
    final cacheKey = _cacheKey('upsertUser', {'userId': user.id});
    await _simulateDelay();
    MockDatabase.users[user.id] = user;
    MockDatabase.users[user.email] = user;

    if (user is CustomerDTO) {
      MockDatabase.customers[user.id] = user;
      _invalidateCache('getCustomer');
      _invalidateCache('getAllCustomers');
    } else if (user is MemberDTO) {
      MockDatabase.members[user.id] = user;
      _invalidateCache('getMember');
      _invalidateCache('getAllMembers');
    }

    _invalidateCache('getUser');
    _invalidateCache('getAllUsers');
    _setCache(cacheKey, user, const Duration(seconds: 30));
    return user;
  }

  @override
  Future<UserDTO?> getUserById(String userId) async {
    final key = _cacheKey('getUserById', {'userId': userId});

    // Check cache first
    final cached = _getFromCache<UserDTO?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.users[userId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<UserDTO?> getUserByEmail(String email) async {
    final key = _cacheKey('getUserByEmail', {'email': email});

    final cached = _getFromCache<UserDTO?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.users[email];
    _setCache(key, result);
    return result;
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _simulateDelay();
    final user = MockDatabase.users[userId];
    if (user != null) {
      MockDatabase.users.remove(userId);
      MockDatabase.users.remove(user.email);
      if (user is CustomerDTO) {
        MockDatabase.customers.remove(userId);
        _invalidateCache('getCustomer');
        _invalidateCache('getAllCustomers');
      } else if (user is MemberDTO) {
        MockDatabase.members.remove(userId);
        _invalidateCache('getMember');
        _invalidateCache('getAllMembers');
      }
    }
    _invalidateCache('getUser');
    _invalidateCache('getAllUsers');
  }

  @override
  Future<List<UserDTO>> getAllUsers() async {
    final key = 'getAllUsers';
    final cached = _getFromCache<List<UserDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final users = <String, UserDTO>{};
    for (final entry in MockDatabase.users.entries) {
      if (entry.key.contains('@')) continue;
      users[entry.key] = entry.value;
    }
    final result = users.values.toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<PaginatedResult<UserDTO>> getUsersPaginated(
    int page,
    int pageSize,
  ) async {
    final key = _cacheKey('getUsersPaginated', {
      'page': page,
      'pageSize': pageSize,
    });
    final cached = _getFromCache<PaginatedResult<UserDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final users = await getAllUsers();
    final result = PaginatedResult<UserDTO>.fromList(
      allItems: users,
      page: page,
      pageSize: pageSize,
    );
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<UserDTO>> getActiveUsers() async {
    final key = 'getActiveUsers';
    final cached = _getFromCache<List<UserDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = (await getAllUsers())
        .where((u) => u.isActive && !u.isBanned)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<UserDTO>> getBannedUsers() async {
    final key = 'getBannedUsers';
    final cached = _getFromCache<List<UserDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = (await getAllUsers()).where((u) => u.isBanned).toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<UserDTO>> searchUsers(String query) async {
    final key = _cacheKey('searchUsers', {'query': query});
    final cached = _getFromCache<List<UserDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final lowerQuery = query.toLowerCase();
    final result = (await getAllUsers()).where((u) {
      return u.name.toLowerCase().contains(lowerQuery) ||
          u.email.toLowerCase().contains(lowerQuery);
    }).toList();
    _setCache(key, result, const Duration(minutes: 1));
    return result;
  }

  @override
  Future<UserDTO> updateUserActiveStatus(String userId, bool isActive) async {
    await _simulateDelay();
    final user = MockDatabase.users[userId];
    if (user == null) throw Exception('User not found');

    UserDTO updatedUser;
    if (user is CustomerDTO) {
      updatedUser = user.copyWith(isActive: isActive);
      MockDatabase.customers[userId] = updatedUser as CustomerDTO;
      _invalidateCache('getCustomer');
    } else if (user is MemberDTO) {
      updatedUser = user.copyWith(isActive: isActive);
      MockDatabase.members[userId] = updatedUser as MemberDTO;
      _invalidateCache('getMember');
    } else {
      throw Exception('Unknown user type');
    }

    MockDatabase.users[userId] = updatedUser;
    MockDatabase.users[user.email] = updatedUser;
    _invalidateCache('getUser');
    _invalidateCache('getAllUsers');
    return updatedUser;
  }

  @override
  Future<UserDTO> banUser(String userId, String reason) async {
    await _simulateDelay();
    final user = MockDatabase.users[userId];
    if (user == null) throw Exception('User not found');

    UserDTO updatedUser;
    if (user is CustomerDTO) {
      updatedUser = user.copyWith(isBanned: true, banReason: reason);
      MockDatabase.customers[userId] = updatedUser as CustomerDTO;
      _invalidateCache('getCustomer');
    } else if (user is MemberDTO) {
      updatedUser = user.copyWith(isBanned: true, banReason: reason);
      MockDatabase.members[userId] = updatedUser as MemberDTO;
      _invalidateCache('getMember');
    } else {
      throw Exception('Unknown user type');
    }

    MockDatabase.users[userId] = updatedUser;
    MockDatabase.users[user.email] = updatedUser;
    _invalidateCache('getUser');
    _invalidateCache('getAllUsers');
    return updatedUser;
  }

  @override
  Future<UserDTO> unbanUser(String userId) async {
    await _simulateDelay();
    final user = MockDatabase.users[userId];
    if (user == null) throw Exception('User not found');

    UserDTO updatedUser;
    if (user is CustomerDTO) {
      updatedUser = user.copyWith(isBanned: false, banReason: null);
      MockDatabase.customers[userId] = updatedUser as CustomerDTO;
      _invalidateCache('getCustomer');
    } else if (user is MemberDTO) {
      updatedUser = user.copyWith(isBanned: false, banReason: null);
      MockDatabase.members[userId] = updatedUser as MemberDTO;
      _invalidateCache('getMember');
    } else {
      throw Exception('Unknown user type');
    }

    MockDatabase.users[userId] = updatedUser;
    MockDatabase.users[user.email] = updatedUser;
    _invalidateCache('getUser');
    _invalidateCache('getAllUsers');
    return updatedUser;
  }

  @override
  Future<UserDTO> updateUserFcmToken(String userId, String? fcmToken) async {
    await _simulateDelay();
    final user = MockDatabase.users[userId];
    if (user == null) throw Exception('User not found');
    _invalidateCache('getUser');
    return user;
  }

  // ==================== CUSTOMER METHODS ====================

  @override
  Future<CustomerDTO> createCustomer(CustomerDTO customer) async {
    await _simulateDelay();
    MockDatabase.customers[customer.id] = customer;
    MockDatabase.users[customer.id] = customer;
    MockDatabase.users[customer.email] = customer;
    _invalidateCache('getCustomer');
    _invalidateCache('getAllCustomers');
    _invalidateCache('getAllUsers');
    return customer;
  }

  @override
  Future<CustomerDTO?> getCustomerById(String customerId) async {
    final key = _cacheKey('getCustomerById', {'customerId': customerId});
    final cached = _getFromCache<CustomerDTO?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.customers[customerId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<CustomerDTO> updateCustomer(CustomerDTO customer) async {
    await _simulateDelay();
    MockDatabase.customers[customer.id] = customer;
    MockDatabase.users[customer.id] = customer;
    MockDatabase.users[customer.email] = customer;
    _invalidateCache('getCustomer');
    _invalidateCache('getAllCustomers');
    _invalidateCache('getAllUsers');
    return customer;
  }

  @override
  Future<CustomerDTO> addSavedMerchant(
    String customerId,
    String merchantId,
  ) async {
    await _simulateDelay();
    final customer = MockDatabase.customers[customerId];
    if (customer == null) throw Exception('Customer not found');

    final updatedCustomer = customer.copyWith(
      savedMerchantIds: [...customer.savedMerchantIds, merchantId],
    );
    MockDatabase.customers[customerId] = updatedCustomer;
    MockDatabase.users[customerId] = updatedCustomer;
    MockDatabase.users[customer.email] = updatedCustomer;
    _invalidateCache('getCustomer');
    _invalidateCache('getAllCustomers');
    return updatedCustomer;
  }

  @override
  Future<CustomerDTO> removeSavedMerchant(
    String customerId,
    String merchantId,
  ) async {
    await _simulateDelay();
    final customer = MockDatabase.customers[customerId];
    if (customer == null) throw Exception('Customer not found');

    final updatedCustomer = customer.copyWith(
      savedMerchantIds: customer.savedMerchantIds
          .where((id) => id != merchantId)
          .toList(),
    );
    MockDatabase.customers[customerId] = updatedCustomer;
    MockDatabase.users[customerId] = updatedCustomer;
    MockDatabase.users[customer.email] = updatedCustomer;
    _invalidateCache('getCustomer');
    _invalidateCache('getAllCustomers');
    return updatedCustomer;
  }

  @override
  Future<void> deleteCustomer(String customerId) async {
    await _simulateDelay();
    final customer = MockDatabase.customers[customerId];
    if (customer != null) {
      MockDatabase.customers.remove(customerId);
      MockDatabase.users.remove(customerId);
      MockDatabase.users.remove(customer.email);
      _invalidateCache('getCustomer');
      _invalidateCache('getAllCustomers');
      _invalidateCache('getAllUsers');
    }
  }

  @override
  Future<List<CustomerDTO>> getAllCustomers() async {
    final key = 'getAllCustomers';
    final cached = _getFromCache<List<CustomerDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.customers.values.toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<CustomerDTO?> getCustomerByUserId(String userId) async {
    final key = _cacheKey('getCustomerByUserId', {'userId': userId});
    final cached = _getFromCache<CustomerDTO?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.customers[userId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<CustomerDTO>> getCustomersBySavedMerchant(
    String merchantId,
  ) async {
    final key = _cacheKey('getCustomersBySavedMerchant', {
      'merchantId': merchantId,
    });
    final cached = _getFromCache<List<CustomerDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.customers.values
        .where((customer) => customer.savedMerchantIds.contains(merchantId))
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<PaginatedResult<CustomerDTO>> getCustomersPaginated(
    int page,
    int pageSize,
  ) async {
    final key = _cacheKey('getCustomersPaginated', {
      'page': page,
      'pageSize': pageSize,
    });
    final cached = _getFromCache<PaginatedResult<CustomerDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final customers = await getAllCustomers();
    final result = PaginatedResult<CustomerDTO>.fromList(
      allItems: customers,
      page: page,
      pageSize: pageSize,
    );
    _setCache(key, result);
    return result;
  }

  // ==================== MEMBER METHODS ====================

  @override
  Future<MemberDTO> createMember(MemberDTO member) async {
    await _simulateDelay();
    MockDatabase.members[member.id] = member;
    MockDatabase.users[member.id] = member;
    MockDatabase.users[member.email] = member;
    _invalidateCache('getMember');
    _invalidateCache('getAllMembers');
    _invalidateCache('getAllUsers');
    return member;
  }

  @override
  Future<MemberDTO?> getMemberByUserId(String userId) async {
    final key = _cacheKey('getMemberByUserId', {'userId': userId});
    final cached = _getFromCache<MemberDTO?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.members[userId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<MemberDTO>> getMembersByTeamId(String teamId) async {
    final key = _cacheKey('getMembersByTeamId', {'teamId': teamId});
    final cached = _getFromCache<List<MemberDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final team = MockDatabase.teams[teamId];
    if (team == null) return [];

    final result = team.memberIds
        .map((id) => MockDatabase.members[id])
        .whereType<MemberDTO>()
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<MemberDTO>> getMembersWithMultipleTeams() async {
    final key = 'getMembersWithMultipleTeams';
    final cached = _getFromCache<List<MemberDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.members.values
        .where((member) => member.teamIds.length > 1)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<void> updateMember(MemberDTO updatedMember) {
    return Future.delayed(delayDuration, () {
      MockDatabase.members[updatedMember.id] = updatedMember;
      MockDatabase.users[updatedMember.id] = updatedMember;
      MockDatabase.users[updatedMember.email] = updatedMember;
      _invalidateCache('getMember');
      _invalidateCache('getAllMembers');
    });
  }

  @override
  Future<MemberDTO> removeTeamFromMember(String userId, String teamId) async {
    await _simulateDelay();
    final member = MockDatabase.members[userId];
    if (member == null) throw Exception('Member not found');

    final updatedMember = member.copyWith(
      teamIds: member.teamIds.where((id) => id != teamId).toList(),
    );
    MockDatabase.members[userId] = updatedMember;
    MockDatabase.users[userId] = updatedMember;
    MockDatabase.users[member.email] = updatedMember;
    _invalidateCache('getMember');
    _invalidateCache('getAllMembers');
    return updatedMember;
  }

  @override
  Future<MemberDTO> addInvitationToMember(
    String userId,
    String invitationId,
  ) async {
    await _simulateDelay();
    final member = MockDatabase.members[userId];
    if (member == null) throw Exception('Member not found');

    final updatedMember = member.copyWith(
      invitationIds: [...member.invitationIds, invitationId],
    );
    MockDatabase.members[userId] = updatedMember;
    MockDatabase.users[userId] = updatedMember;
    MockDatabase.users[member.email] = updatedMember;
    _invalidateCache('getMember');
    return updatedMember;
  }

  @override
  Future<MemberDTO> removeInvitationFromMember(
    String userId,
    String invitationId,
  ) async {
    await _simulateDelay();
    final member = MockDatabase.members[userId];
    if (member == null) throw Exception('Member not found');

    final updatedMember = member.copyWith(
      invitationIds: member.invitationIds
          .where((id) => id != invitationId)
          .toList(),
    );
    MockDatabase.members[userId] = updatedMember;
    MockDatabase.users[userId] = updatedMember;
    MockDatabase.users[member.email] = updatedMember;
    _invalidateCache('getMember');
    return updatedMember;
  }

  @override
  Future<void> deleteMember(String userId) async {
    await _simulateDelay();
    final member = MockDatabase.members[userId];
    if (member != null) {
      MockDatabase.members.remove(userId);
      MockDatabase.users.remove(userId);
      MockDatabase.users.remove(member.email);
      _invalidateCache('getMember');
      _invalidateCache('getAllMembers');
      _invalidateCache('getAllUsers');
    }
  }

  @override
  Future<PaginatedResult<MemberDTO>> getMembersPaginated(
    int page,
    int pageSize, {
    String? teamId,
  }) async {
    final key = _cacheKey('getMembersPaginated', {
      'page': page,
      'pageSize': pageSize,
      'teamId': teamId,
    });
    final cached = _getFromCache<PaginatedResult<MemberDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    List<MemberDTO> members;

    if (teamId != null) {
      members = await getMembersByTeamId(teamId);
    } else {
      members = MockDatabase.members.values.toList();
    }

    final result = PaginatedResult<MemberDTO>.fromList(
      allItems: members,
      page: page,
      pageSize: pageSize,
    );
    _setCache(key, result);
    return result;
  }

  @override
  Future<bool> isUserMemberOfTeam(String userId, String teamId) async {
    final key = _cacheKey('isUserMemberOfTeam', {
      'userId': userId,
      'teamId': teamId,
    });
    final cached = _getFromCache<bool>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final member = MockDatabase.members[userId];
    final result = member?.teamIds.contains(teamId) ?? false;
    _setCache(key, result, const Duration(minutes: 1));
    return result;
  }

  // ==================== INVITATION METHODS ====================

  @override
  Future<List<InvitationDTO>> getInvitationsByTeamId(String teamId) async {
    final key = _cacheKey('getInvitationsByTeamId', {'teamId': teamId});
    final cached = _getFromCache<List<InvitationDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.invitations.values
        .where((inv) => inv.teamId == teamId)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<InvitationDTO>> getInvitationsSentByUser(String userId) async {
    final key = _cacheKey('getInvitationsSentByUser', {'userId': userId});
    final cached = _getFromCache<List<InvitationDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.invitations.values
        .where((inv) => inv.invitedBy == userId)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<void> deleteInvitation(String id) async {
    await _simulateDelay();
    MockDatabase.invitations.remove(id);
    _invalidateCache('getInvitations');
  }

  @override
  Future<PaginatedResult<InvitationDTO>> getInvitationsPaginated(
    int page,
    int pageSize, {
    String? teamId,
    String? userId,
    String? organisationId,
    InvitationStatus? status,
  }) async {
    final key = _cacheKey('getInvitationsPaginated', {
      'page': page,
      'pageSize': pageSize,
      'teamId': teamId,
      'userId': userId,
      'organisationId': organisationId,
      'status': status?.toString(),
    });
    final cached = _getFromCache<PaginatedResult<InvitationDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    var invitations = MockDatabase.invitations.values.toList();

    if (teamId != null) {
      invitations = invitations.where((inv) => inv.teamId == teamId).toList();
    }
    if (userId != null) {
      invitations = invitations.where((inv) => inv.userId == userId).toList();
    }
    if (organisationId != null) {
      invitations = invitations
          .where((inv) => inv.organisationId == organisationId)
          .toList();
    }
    if (status != null) {
      invitations = invitations.where((inv) => inv.status == status).toList();
    }

    final result = PaginatedResult<InvitationDTO>.fromList(
      allItems: invitations,
      page: page,
      pageSize: pageSize,
    );
    _setCache(key, result);
    return result;
  }

  // ==================== MERCHANT LISTING METHODS ====================
  @override
  Future<PaginatedResult<MerchantListingDTO>> getMerchantListingsPaginated(
    int page,
    int pageSize,
  ) async {
    // DEBUG: Log the raw values
    debugPrint(
      '🔍 [API] getMerchantListingsPaginated called with page: $page, pageSize: $pageSize',
    );

    // If either is negative, print the stack trace
    if (page < 0 || pageSize < 0) {
      debugPrint('🔴 [API] NEGATIVE VALUE DETECTED!');
      debugPrint(StackTrace.current.toString());
    }
    // VALIDATE INPUTS
    final safePage = page < 0 ? 0 : page;
    final safePageSize = pageSize <= 0 ? 20 : pageSize;

    final key = _cacheKey('getMerchantListingsPaginated', {
      'page': safePage,
      'pageSize': safePageSize,
    });
    final cached = _getFromCache<PaginatedResult<MerchantListingDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final listings = await getAllMerchantListings();
    final result = PaginatedResult<MerchantListingDTO>.fromList(
      allItems: listings,
      page: safePage,
      pageSize: safePageSize,
    );
    _setCache(key, result);
    return result;
  }

  @override
  Future<PaginatedResult<MerchantListingDTO>>
  getMerchantListingsByTypePaginated(
    ListingType type,
    int page,
    int pageSize,
  ) async {
    // VALIDATE INPUTS
    final safePage = page < 0 ? 0 : page;
    final safePageSize = pageSize <= 0 ? 20 : pageSize;

    final key = _cacheKey('getMerchantListingsByTypePaginated', {
      'type': type.toString(),
      'page': safePage,
      'pageSize': safePageSize,
    });
    final cached = _getFromCache<PaginatedResult<MerchantListingDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final listings = await getMerchantListingsByType(type);
    final result = PaginatedResult<MerchantListingDTO>.fromList(
      allItems: listings,
      page: safePage,
      pageSize: safePageSize,
    );
    _setCache(key, result);
    return result;
  }

  @override
  Future<PaginatedResult<MerchantListingDTO>>
  getMerchantListingsByOrganizationPaginated(
    String organizationId,
    int page,
    int pageSize,
  ) async {
    // VALIDATE INPUTS
    final safePage = page < 0 ? 0 : page;
    final safePageSize = pageSize <= 0 ? 20 : pageSize;

    final key = _cacheKey('getMerchantListingsByOrganizationPaginated', {
      'organizationId': organizationId,
      'page': safePage,
      'pageSize': safePageSize,
    });
    final cached = _getFromCache<PaginatedResult<MerchantListingDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final listings = await getMerchantListingsByOrganization(organizationId);
    final result = PaginatedResult<MerchantListingDTO>.fromList(
      allItems: listings,
      page: safePage,
      pageSize: safePageSize,
    );
    _setCache(key, result);
    return result;
  }

  @override
  Future<MerchantListingDTO> upsertMerchantListing(
    MerchantListingDTO listing,
  ) async {
    await _simulateDelay();
    MockDatabase.merchantListings[listing.id] = listing;
    _invalidateCache('getMerchantListing');
    _invalidateCache('getAllMerchantListings');
    _invalidateCache('getMerchantListings');
    return listing;
  }

  @override
  Future<MerchantListingDTO?> getMerchantListingById(String listingId) async {
    final key = _cacheKey('getMerchantListingById', {'listingId': listingId});
    final cached = _getFromCache<MerchantListingDTO?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.merchantListings[listingId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<void> deleteMerchantListing(String listingId) async {
    await _simulateDelay();
    MockDatabase.merchantListings.remove(listingId);
    _invalidateCache('getMerchantListing');
    _invalidateCache('getAllMerchantListings');
    _invalidateCache('getMerchantListings');
  }

  @override
  Future<List<MerchantListingDTO>> getAllMerchantListings() async {
    final key = 'getAllMerchantListings';
    final cached = _getFromCache<List<MerchantListingDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.merchantListings.values.toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<MerchantListingDTO>> getMerchantListingsByIds(
    List<String> listingIds,
  ) {
    return Future.delayed(delayDuration, () {
      final key = _cacheKey('getMerchantListingsByIds', {
        'ids': listingIds.join(','),
      });
      final cached = _getFromCache<List<MerchantListingDTO>>(key);
      if (cached != null) return cached;

      final result = listingIds
          .map((id) => MockDatabase.merchantListings[id])
          .whereType<MerchantListingDTO>()
          .toList();
      _setCache(key, result);
      return result;
    });
  }

  @override
  Future<List<MerchantListingDTO>> getMerchantListingsByType(
    ListingType type,
  ) async {
    final key = _cacheKey('getMerchantListingsByType', {
      'type': type.toString(),
    });
    final cached = _getFromCache<List<MerchantListingDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = (await getAllMerchantListings())
        .where((listing) => listing.type == type)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<MerchantListingDTO>> getMerchantListingsByOrganization(
    String organizationId,
  ) async {
    final key = _cacheKey('getMerchantListingsByOrganization', {
      'organizationId': organizationId,
    });
    final cached = _getFromCache<List<MerchantListingDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = (await getAllMerchantListings())
        .where((listing) => listing.organizationId == organizationId)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<MerchantListingDTO>> getActiveMerchantListings() async {
    final key = 'getActiveMerchantListings';
    final cached = _getFromCache<List<MerchantListingDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = (await getAllMerchantListings())
        .where(
          (listing) =>
              listing.isActive && listing.status == PublishStatus.published,
        )
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<MerchantListingDTO>> getPublishedMerchantListings() async {
    final key = 'getPublishedMerchantListings';
    final cached = _getFromCache<List<MerchantListingDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = (await getAllMerchantListings())
        .where((listing) => listing.status == PublishStatus.published)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<MerchantListingDTO>> searchMerchantListings(String query) async {
    final key = _cacheKey('searchMerchantListings', {'query': query});
    final cached = _getFromCache<List<MerchantListingDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final lowerQuery = query.toLowerCase();
    final result = (await getAllMerchantListings())
        .where((listing) => listing.title.toLowerCase().contains(lowerQuery))
        .toList();
    _setCache(key, result, const Duration(minutes: 1));
    return result;
  }

  @override
  Future<List<MerchantListingDTO>> getMerchantListingsByBookingType(
    BookingType bookingType,
  ) async {
    final key = _cacheKey('getMerchantListingsByBookingType', {
      'bookingType': bookingType.toString(),
    });
    final cached = _getFromCache<List<MerchantListingDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = (await getAllMerchantListings())
        .where((listing) => listing.bookingType == bookingType)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<MerchantListingDTO>> getMerchantListingsByTeamMember(
    String teamId,
  ) async {
    final key = _cacheKey('getMerchantListingsByTeamMember', {
      'teamId': teamId,
    });
    final cached = _getFromCache<List<MerchantListingDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final team = MockDatabase.teams[teamId];
    if (team == null) return [];

    final result = (await getAllMerchantListings())
        .where((listing) => listing.teamIds.contains(teamId))
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<MerchantListingDTO> setMerchantListingActiveStatus(
    String listingId,
    bool isActive,
  ) async {
    await _simulateDelay();
    final listing = MockDatabase.merchantListings[listingId];
    if (listing == null) throw Exception('Listing not found');

    final updatedListing = listing.copyWith(isActive: isActive);
    MockDatabase.merchantListings[listingId] = updatedListing;
    _invalidateCache('getMerchantListing');
    _invalidateCache('getAllMerchantListings');
    _invalidateCache('getMerchantListings');
    return updatedListing;
  }

  @override
  Future<MerchantListingDTO> updateMerchantListingStatus(
    String listingId,
    PublishStatus status,
  ) async {
    await _simulateDelay();
    final listing = MockDatabase.merchantListings[listingId];
    if (listing == null) throw Exception('Listing not found');

    final updatedListing = listing.copyWith(status: status);
    MockDatabase.merchantListings[listingId] = updatedListing;
    _invalidateCache('getMerchantListing');
    _invalidateCache('getAllMerchantListings');
    _invalidateCache('getMerchantListings');
    return updatedListing;
  }

  // ==================== ORGANISATION METHODS ====================
  @override
  Future<List<OrganisationDTO>> getOrganisations() async {
    final key = 'getOrganisations';
    final cached = _getFromCache<List<OrganisationDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.organisations.values.toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<OrganisationDTO?> getOrganisationById(String organisationId) async {
    final key = _cacheKey('getOrganisationById', {
      'organisationId': organisationId,
    });
    final cached = _getFromCache<OrganisationDTO?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.organisations[organisationId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<void> deleteOrganisation(String organisationId) async {
    await _simulateDelay();
    MockDatabase.organisations.remove(organisationId);
    _invalidateCache('getOrganisation');
    _invalidateCache('getOrganisations');
    _invalidateCache('getAllOrganisations');
  }

  @override
  Future<List<OrganisationDTO>> getAllOrganisations() async {
    final key = 'getAllOrganisations';
    final cached = _getFromCache<List<OrganisationDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.organisations.values.toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<PaginatedResult<OrganisationDTO>> getOrganisationsPaginated(
    int page,
    int pageSize,
  ) async {
    final key = _cacheKey('getOrganisationsPaginated', {
      'page': page,
      'pageSize': pageSize,
    });
    final cached = _getFromCache<PaginatedResult<OrganisationDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final organisations = await getAllOrganisations();
    final result = PaginatedResult<OrganisationDTO>.fromList(
      allItems: organisations,
      page: page,
      pageSize: pageSize,
    );
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<OrganisationDTO>> getActiveOrganisations() async {
    final key = 'getActiveOrganisations';
    final cached = _getFromCache<List<OrganisationDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = (await getAllOrganisations())
        .where((org) => org.isActive && org.status == PublishStatus.published)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<OrganisationDTO>> getPublishedOrganisations() async {
    final key = 'getPublishedOrganisations';
    final cached = _getFromCache<List<OrganisationDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = (await getAllOrganisations())
        .where((org) => org.status == PublishStatus.published)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<OrganisationDTO>> searchOrganisations(String query) async {
    final key = _cacheKey('searchOrganisations', {'query': query});
    final cached = _getFromCache<List<OrganisationDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final lowerQuery = query.toLowerCase();
    final result = (await getAllOrganisations())
        .where((org) => org.name.toLowerCase().contains(lowerQuery))
        .toList();
    _setCache(key, result, const Duration(minutes: 1));
    return result;
  }

  @override
  Future<OrganisationDTO> setOrganisationActiveStatus(
    String organisationId,
    bool isActive,
  ) async {
    await _simulateDelay();
    final org = MockDatabase.organisations[organisationId];
    if (org == null) throw Exception('Organisation not found');

    final updatedOrg = org.copyWith(isActive: isActive);
    MockDatabase.organisations[organisationId] = updatedOrg;
    _invalidateCache('getOrganisation');
    _invalidateCache('getOrganisations');
    _invalidateCache('getAllOrganisations');
    return updatedOrg;
  }

  @override
  Future<OrganisationDTO> updateOrganisationStatus(
    String organisationId,
    PublishStatus status,
  ) async {
    await _simulateDelay();
    final org = MockDatabase.organisations[organisationId];
    if (org == null) throw Exception('Organisation not found');

    final updatedOrg = org.copyWith(status: status);
    MockDatabase.organisations[organisationId] = updatedOrg;
    _invalidateCache('getOrganisation');
    _invalidateCache('getOrganisations');
    _invalidateCache('getAllOrganisations');
    return updatedOrg;
  }

  @override
  Future<OrganisationDTO> updateOrganisation(
    String organisationId,
    OrganisationDTO organisation,
  ) async {
    await _simulateDelay();
    final existingOrg = MockDatabase.organisations[organisationId];
    if (existingOrg == null) throw Exception('Organisation not found');

    final updatedOrg = organisation.copyWith(
      id: organisationId,
      updatedAt: DateTime.now(),
    );

    MockDatabase.organisations[organisationId] = updatedOrg;
    _invalidateCache('getOrganisation');
    _invalidateCache('getOrganisations');
    _invalidateCache('getAllOrganisations');
    return updatedOrg;
  }

  @override
  Future<OrganisationDTO> createOrganisation(
    OrganisationDTO organisation,
  ) async {
    await _simulateDelay();
    final newOrg = organisation.copyWith(
      id: Uuid().v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    MockDatabase.organisations[newOrg.id] = newOrg;
    _invalidateCache('getOrganisation');
    _invalidateCache('getOrganisations');
    _invalidateCache('getAllOrganisations');
    return newOrg;
  }

  // ==================== LOCATION METHODS ====================

  @override
  Future<LocationModel> upsertLocation(LocationModel location) async {
    await _simulateDelay();
    MockDatabase.locations[location.id] = location;
    _invalidateCache('getLocation');
    _invalidateCache('getAllLocations');
    _invalidateCache('getLocations');
    return location;
  }

  @override
  Future<LocationModel?> getLocationById(String locationId) async {
    final key = _cacheKey('getLocationById', {'locationId': locationId});
    final cached = _getFromCache<LocationModel?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.locations[locationId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<void> deleteLocation(String locationId) async {
    await _simulateDelay();
    MockDatabase.locations.remove(locationId);
    _invalidateCache('getLocation');
    _invalidateCache('getAllLocations');
    _invalidateCache('getLocations');
  }

  @override
  Future<List<LocationModel>> getAllLocations() async {
    final key = 'getAllLocations';
    final cached = _getFromCache<List<LocationModel>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.locations.values.toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<PaginatedResult<LocationModel>> getLocationsPaginated(
    int page,
    int pageSize,
  ) async {
    final key = _cacheKey('getLocationsPaginated', {
      'page': page,
      'pageSize': pageSize,
    });
    final cached = _getFromCache<PaginatedResult<LocationModel>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final locations = await getAllLocations();
    final result = PaginatedResult<LocationModel>.fromList(
      allItems: locations,
      page: page,
      pageSize: pageSize,
    );
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<LocationModel>> getLocationsByHost(String hostId) async {
    final key = _cacheKey('getLocationsByHost', {'hostId': hostId});
    final cached = _getFromCache<List<LocationModel>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = (await getAllLocations())
        .where((loc) => loc.id == hostId)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<LocationModel>> getLocationsByMainVenue(
    String mainVenueId,
  ) async {
    final key = _cacheKey('getLocationsByMainVenue', {
      'mainVenueId': mainVenueId,
    });
    final cached = _getFromCache<List<LocationModel>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = (await getAllLocations())
        .where((loc) => loc.mainVenueId == mainVenueId)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<LocationModel>> searchLocations(String query) async {
    final key = _cacheKey('searchLocations', {'query': query});
    final cached = _getFromCache<List<LocationModel>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final lowerQuery = query.toLowerCase();
    final result = (await getAllLocations())
        .where((loc) => loc.name.toLowerCase().contains(lowerQuery))
        .toList();
    _setCache(key, result, const Duration(minutes: 1));
    return result;
  }

  @override
  Future<List<LocationModel>> getLocationsNearby(
    double latitude,
    double longitude,
    double radiusInKm,
  ) async {
    final key = _cacheKey('getLocationsNearby', {
      'latitude': latitude,
      'longitude': longitude,
      'radiusInKm': radiusInKm,
    });
    final cached = _getFromCache<List<LocationModel>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = (await getAllLocations()).where((loc) {
      final latDiff = (loc.coordinates.latitude - latitude).abs();
      final lonDiff = (loc.coordinates.longitude - longitude).abs();
      final distanceKm = sqrt(latDiff * latDiff + lonDiff * lonDiff) * 111;
      return distanceKm <= radiusInKm;
    }).toList();
    _setCache(key, result);
    return result;
  }

  // ==================== TEAM METHODS ====================

  @override
  Future<TeamDTO> createTeam(TeamDTO team) async {
    await _simulateDelay();
    MockDatabase.teams[team.id] = team;
    _invalidateCache('getTeam');
    _invalidateCache('getAllTeams');
    _invalidateCache('getTeams');
    return team;
  }

  @override
  Future<TeamDTO?> getTeamById(String teamId) async {
    final key = _cacheKey('getTeamById', {'teamId': teamId});
    final cached = _getFromCache<TeamDTO?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.teams[teamId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<TeamDTO>> getTeamsByMemberId(String memberId) async {
    final key = _cacheKey('getTeamsByMemberId', {'memberId': memberId});
    final cached = _getFromCache<List<TeamDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final member = MockDatabase.members[memberId];
    if (member == null) return [];

    final result = member.teamIds
        .map((id) => MockDatabase.teams[id])
        .whereType<TeamDTO>()
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<TeamDTO>> getTeamsByOrganisationId(String organisationId) async {
    final key = _cacheKey('getTeamsByOrganisationId', {
      'organisationId': organisationId,
    });
    final cached = _getFromCache<List<TeamDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.teams.values
        .where((team) => team.organisationId == organisationId)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<TeamDTO>> getTeamsByListingId(String listingId) async {
    final key = _cacheKey('getTeamsByListingId', {'listingId': listingId});
    final cached = _getFromCache<List<TeamDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.teams.values
        .where((team) => team.listingId == listingId)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<TeamDTO> addMemberToTeam(String teamId, String userId) async {
    await _simulateDelay();
    final team = MockDatabase.teams[teamId];
    if (team == null) throw Exception('Team not found');

    final updatedTeam = team.addMember(userId);
    MockDatabase.teams[teamId] = updatedTeam;

    final member = MockDatabase.members[userId];
    if (member != null && !member.teamIds.contains(teamId)) {
      final updatedMember = member.copyWith(
        teamIds: [...member.teamIds, teamId],
      );
      MockDatabase.members[userId] = updatedMember;
      MockDatabase.users[userId] = updatedMember;
    }

    _invalidateCache('getTeam');
    _invalidateCache('getTeams');
    _invalidateCache('getAllTeams');
    return updatedTeam;
  }

  @override
  Future<TeamDTO> removeMemberFromTeam(String teamId, String userId) async {
    await _simulateDelay();
    final team = MockDatabase.teams[teamId];
    if (team == null) throw Exception('Team not found');

    final updatedTeam = team.removeMember(userId);
    MockDatabase.teams[teamId] = updatedTeam;

    final member = MockDatabase.members[userId];
    if (member != null) {
      final updatedMember = member.copyWith(
        teamIds: member.teamIds.where((id) => id != teamId).toList(),
      );
      MockDatabase.members[userId] = updatedMember;
      MockDatabase.users[userId] = updatedMember;
    }

    _invalidateCache('getTeam');
    _invalidateCache('getTeams');
    _invalidateCache('getAllTeams');
    return updatedTeam;
  }

  @override
  Future<TeamDTO> updateTeamPermissions(
    String teamId,
    List<String> permissionStrings,
  ) async {
    await _simulateDelay();
    final team = MockDatabase.teams[teamId];
    if (team == null) throw Exception('Team not found');

    final updatedTeam = team.copyWith(
      permissionStrings: permissionStrings,
      updatedAt: DateTime.now(),
    );
    MockDatabase.teams[teamId] = updatedTeam;
    _invalidateCache('getTeam');
    return updatedTeam;
  }

  @override
  Future<void> deleteTeam(String teamId) async {
    await _simulateDelay();
    MockDatabase.teams.remove(teamId);
    _invalidateCache('getTeam');
    _invalidateCache('getTeams');
    _invalidateCache('getAllTeams');
  }

  @override
  Future<PaginatedResult<TeamDTO>> getTeamsPaginated(
    int page,
    int pageSize, {
    String? organisationId,
  }) async {
    final key = _cacheKey('getTeamsPaginated', {
      'page': page,
      'pageSize': pageSize,
      'organisationId': organisationId,
    });
    final cached = _getFromCache<PaginatedResult<TeamDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    var teams = MockDatabase.teams.values.toList();

    if (organisationId != null) {
      teams = teams
          .where((team) => team.organisationId == organisationId)
          .toList();
    }

    final result = PaginatedResult<TeamDTO>.fromList(
      allItems: teams,
      page: page,
      pageSize: pageSize,
    );
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<TeamDTO>> getAllTeams() async {
    final key = 'getAllTeams';
    final cached = _getFromCache<List<TeamDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.teams.values.toList();
    _setCache(key, result);
    return result;
  }

  // ==================== ROOM METHODS ====================

  @override
  Future<RoomDTO> createRoom(RoomDTO room) async {
    await _simulateDelay();
    MockDatabase.rooms[room.id] = room;
    _invalidateCache('getRoom');
    _invalidateCache('getAllRooms');
    _invalidateCache('getRooms');
    return room;
  }

  @override
  Future<RoomDTO> updateRoom(RoomDTO room) async {
    await _simulateDelay();
    final existingRoom = MockDatabase.rooms[room.id];
    if (existingRoom == null) throw Exception('Room not found');

    MockDatabase.rooms[room.id] = room;
    _invalidateCache('getRoom');
    _invalidateCache('getRooms');
    return room;
  }

  @override
  Future<RoomDTO?> getRoomById(String roomId) async {
    final key = _cacheKey('getRoomById', {'roomId': roomId});
    final cached = _getFromCache<RoomDTO?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.rooms[roomId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await _simulateDelay();
    MockDatabase.rooms.remove(roomId);
    _invalidateCache('getRoom');
    _invalidateCache('getAllRooms');
    _invalidateCache('getRooms');
  }

  @override
  Future<List<RoomDTO>> getRoomsByHotelId(String hotelId) async {
    final key = _cacheKey('getRoomsByHotelId', {'hotelId': hotelId});
    final cached = _getFromCache<List<RoomDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.rooms.values
        .where((room) => room.hotelId == hotelId)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<PaginatedResult<RoomDTO>> getRoomsPaginated(
    int page,
    int pageSize, {
    String? hotelId,
    bool? onlyAvailable,
  }) async {
    final key = _cacheKey('getRoomsPaginated', {
      'page': page,
      'pageSize': pageSize,
      'hotelId': hotelId,
      'onlyAvailable': onlyAvailable,
    });
    final cached = _getFromCache<PaginatedResult<RoomDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    var rooms = MockDatabase.rooms.values.toList();

    if (hotelId != null) {
      rooms = rooms.where((room) => room.hotelId == hotelId).toList();
    }

    if (onlyAvailable == true) {
      rooms = rooms
          .where((room) => room.status == PublishStatus.published)
          .toList();
    }

    final result = PaginatedResult<RoomDTO>.fromList(
      allItems: rooms,
      page: page,
      pageSize: pageSize,
    );
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<RoomDTO>> getAvailableRooms(
    String hotelId,
    DateTimeRange dateRange,
  ) async {
    final key = _cacheKey('getAvailableRooms', {
      'hotelId': hotelId,
      'start': dateRange.start.toIso8601String(),
      'end': dateRange.end.toIso8601String(),
    });
    final cached = _getFromCache<List<RoomDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final rooms = await getRoomsByHotelId(hotelId);
    final result = rooms
        .where((room) => room.isAvailableFor(dateRange))
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<bool> isRoomAvailable(String roomId, DateTimeRange dateRange) async {
    final key = _cacheKey('isRoomAvailable', {
      'roomId': roomId,
      'start': dateRange.start.toIso8601String(),
      'end': dateRange.end.toIso8601String(),
    });
    final cached = _getFromCache<bool>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final room = await getRoomById(roomId);
    final result = room?.isAvailableFor(dateRange) ?? false;
    _setCache(key, result);
    return result;
  }

  @override
  Future<RoomDTO> bookRoom(
    String roomId,
    DateTimeRange dateRange,
    String userId,
  ) async {
    await _simulateDelay();
    final room = await getRoomById(roomId);
    if (room == null) throw Exception('Room not found');

    if (!room.isAvailableFor(dateRange)) {
      throw Exception('Room is not available for the selected dates');
    }

    final updatedRoom = room.copyWith(
      bookedRanges: [...room.bookedRanges, dateRange],
      updatedAt: DateTime.now(),
    );

    MockDatabase.rooms[roomId] = updatedRoom;

    final bookingId = 'booking_${DateTime.now().millisecondsSinceEpoch}';
    MockDatabase.bookings[bookingId] = {
      'id': bookingId,
      'roomId': roomId,
      'userId': userId,
      'startDate': dateRange.start,
      'endDate': dateRange.end,
      'status': 'confirmed',
      'createdAt': DateTime.now(),
    };

    _invalidateCache('getRoom');
    _invalidateCache('getRooms');
    _invalidateCache('isRoomAvailable');
    return updatedRoom;
  }

  @override
  Future<RoomDTO> cancelBooking(String roomId, DateTimeRange dateRange) async {
    await _simulateDelay();
    final room = await getRoomById(roomId);
    if (room == null) throw Exception('Room not found');

    final updatedBookedRanges = room.bookedRanges
        .where(
          (range) =>
              range.start != dateRange.start || range.end != dateRange.end,
        )
        .toList();

    final updatedRoom = room.copyWith(
      bookedRanges: updatedBookedRanges,
      updatedAt: DateTime.now(),
    );

    MockDatabase.rooms[roomId] = updatedRoom;
    _invalidateCache('getRoom');
    _invalidateCache('getRooms');
    _invalidateCache('isRoomAvailable');
    return updatedRoom;
  }

  @override
  Future<RoomDTO> updateRoomStatus(String roomId, PublishStatus status) async {
    await _simulateDelay();
    final room = await getRoomById(roomId);
    if (room == null) throw Exception('Room not found');

    final updatedRoom = room.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );

    MockDatabase.rooms[roomId] = updatedRoom;
    _invalidateCache('getRoom');
    _invalidateCache('getRooms');
    return updatedRoom;
  }

  @override
  Future<List<RoomDTO>> searchRooms({
    String? hotelId,
    int? minGuests,
    double? minPrice,
    double? maxPrice,
    List<String>? features,
    DateTimeRange? dateRange,
  }) async {
    final key = _cacheKey('searchRooms', {
      'hotelId': hotelId,
      'minGuests': minGuests,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'features': features?.join(','),
      'dateRange': dateRange != null
          ? '${dateRange.start.toIso8601String()}_${dateRange.end.toIso8601String()}'
          : null,
    });
    final cached = _getFromCache<List<RoomDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    var rooms = MockDatabase.rooms.values.toList();

    if (hotelId != null) {
      rooms = rooms.where((room) => room.hotelId == hotelId).toList();
    }

    if (minGuests != null) {
      rooms = rooms.where((room) => room.maxGuests >= minGuests).toList();
    }

    if (minPrice != null) {
      rooms = rooms.where((room) => room.basePrice >= minPrice).toList();
    }

    if (maxPrice != null) {
      rooms = rooms.where((room) => room.basePrice <= maxPrice).toList();
    }

    if (features != null && features.isNotEmpty) {
      rooms = rooms
          .where(
            (room) =>
                features.every((feature) => room.features.contains(feature)),
          )
          .toList();
    }

    if (dateRange != null) {
      rooms = rooms.where((room) => room.isAvailableFor(dateRange)).toList();
    }

    _setCache(key, rooms);
    return rooms;
  }

  @override
  Future<List<RoomDTO>> getRoomsByIds(List<String> ids) async {
    final key = _cacheKey('getRoomsByIds', {'ids': ids.join(',')});
    final cached = _getFromCache<List<RoomDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    final idSet = ids.toSet();
    final result = MockDatabase.rooms.values
        .where((r) => idSet.contains(r.id))
        .toList();

    _setCache(key, result);
    return result;
  }

  @override
  Future<List<RoomDTO>> getRoomsByMerchantId(String merchantId) async {
    final key = _cacheKey('getRoomsByMerchantId', {'merchantId': merchantId});
    final cached = _getFromCache<List<RoomDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    final result = MockDatabase.rooms.values
        .where((r) => r.hotelId == merchantId)
        .toList();

    _setCache(key, result);
    return result;
  }

  // ==================== TICKET METHODS ====================

  @override
  Future<TicketDTO> createTicket(TicketDTO ticket) async {
    await _simulateDelay();
    MockDatabase.tickets[ticket.id] = ticket;
    _invalidateCache('getTicket');
    _invalidateCache('getAllTickets');
    _invalidateCache('getTickets');
    return ticket;
  }

  @override
  Future<TicketDTO> updateTicket(TicketDTO ticket) async {
    await _simulateDelay();
    final existingTicket = MockDatabase.tickets[ticket.id];
    if (existingTicket == null) throw Exception('Ticket not found');

    MockDatabase.tickets[ticket.id] = ticket;
    _invalidateCache('getTicket');
    _invalidateCache('getTickets');
    return ticket;
  }

  @override
  Future<TicketDTO?> getTicketById(String ticketId) async {
    final key = _cacheKey('getTicketById', {'ticketId': ticketId});
    final cached = _getFromCache<TicketDTO?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.tickets[ticketId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<void> deleteTicket(String ticketId) async {
    await _simulateDelay();
    MockDatabase.tickets.remove(ticketId);
    _invalidateCache('getTicket');
    _invalidateCache('getAllTickets');
    _invalidateCache('getTickets');
  }

  @override
  Future<List<TicketDTO>> getTicketsByEventId(String eventId) async {
    final key = _cacheKey('getTicketsByEventId', {'eventId': eventId});
    final cached = _getFromCache<List<TicketDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.tickets.values
        .where((ticket) => ticket.eventId == eventId)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<PaginatedResult<TicketDTO>> getTicketsPaginated(
    int page,
    int pageSize, {
    String? eventId,
    bool? onlyAvailable,
  }) async {
    final key = _cacheKey('getTicketsPaginated', {
      'page': page,
      'pageSize': pageSize,
      'eventId': eventId,
      'onlyAvailable': onlyAvailable,
    });
    final cached = _getFromCache<PaginatedResult<TicketDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    var tickets = MockDatabase.tickets.values.toList();

    if (eventId != null) {
      tickets = tickets.where((ticket) => ticket.eventId == eventId).toList();
    }

    if (onlyAvailable == true) {
      tickets = tickets
          .where((ticket) => ticket.isOnSale && !ticket.isSoldOut)
          .toList();
    }

    final result = PaginatedResult<TicketDTO>.fromList(
      allItems: tickets,
      page: page,
      pageSize: pageSize,
    );
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<TicketDTO>> getAvailableTickets(String eventId) async {
    final key = _cacheKey('getAvailableTickets', {'eventId': eventId});
    final cached = _getFromCache<List<TicketDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final now = DateTime.now();
    final result = MockDatabase.tickets.values
        .where(
          (ticket) =>
              ticket.eventId == eventId &&
              ticket.isOnSale &&
              !ticket.isSoldOut &&
              ticket.salesStartDate.isBefore(now) &&
              ticket.salesEndDate.isAfter(now),
        )
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<TicketDTO> purchaseTicket(
    String ticketId,
    String userId,
    int quantity,
  ) async {
    await _simulateDelay();
    final ticket = await getTicketById(ticketId);
    if (ticket == null) throw Exception('Ticket not found');

    if (!ticket.isOnSale) {
      throw Exception('Ticket is not on sale');
    }

    if (ticket.isSoldOut) {
      throw Exception('Ticket is sold out');
    }

    final remainingQuantity = ticket.remainingQuantity;
    if (remainingQuantity != null && quantity > remainingQuantity) {
      throw Exception('Only $remainingQuantity tickets available');
    }

    final newQuantitySold = ticket.quantitySold + quantity;
    final isNowSoldOut =
        ticket.maxQuantity != null && newQuantitySold >= ticket.maxQuantity!;

    final updatedTicket = ticket.copyWith(
      quantitySold: newQuantitySold,
      isSoldOut: isNowSoldOut,
      updatedAt: DateTime.now(),
    );

    MockDatabase.tickets[ticketId] = updatedTicket;

    final purchaseId = 'purchase_${DateTime.now().millisecondsSinceEpoch}';
    MockDatabase.purchases[purchaseId] = {
      'id': purchaseId,
      'ticketId': ticketId,
      'userId': userId,
      'quantity': quantity,
      'totalPrice': ticket.price * quantity,
      'currency': ticket.currency ?? 'USD',
      'status': 'completed',
      'purchaseDate': DateTime.now(),
    };

    _invalidateCache('getTicket');
    _invalidateCache('getTickets');
    return updatedTicket;
  }

  @override
  Future<TicketDTO> refundTicket(
    String ticketId,
    String userId,
    int quantity,
  ) async {
    await _simulateDelay();
    final ticket = await getTicketById(ticketId);
    if (ticket == null) throw Exception('Ticket not found');

    if (ticket.quantitySold < quantity) {
      throw Exception('Cannot refund more tickets than purchased');
    }

    final newQuantitySold = ticket.quantitySold - quantity;
    final isNowSoldOut =
        ticket.maxQuantity != null && newQuantitySold >= ticket.maxQuantity!;

    final updatedTicket = ticket.copyWith(
      quantitySold: newQuantitySold,
      isSoldOut: isNowSoldOut,
      updatedAt: DateTime.now(),
    );

    MockDatabase.tickets[ticketId] = updatedTicket;
    _invalidateCache('getTicket');
    _invalidateCache('getTickets');
    return updatedTicket;
  }

  @override
  Future<TicketDTO> updateTicketInventory(
    String ticketId,
    int quantitySold,
  ) async {
    await _simulateDelay();
    final ticket = await getTicketById(ticketId);
    if (ticket == null) throw Exception('Ticket not found');

    final updatedTicket = ticket.copyWith(
      quantitySold: quantitySold,
      updatedAt: DateTime.now(),
    );

    MockDatabase.tickets[ticketId] = updatedTicket;
    _invalidateCache('getTicket');
    _invalidateCache('getTickets');
    return updatedTicket;
  }

  @override
  Future<TicketDTO> updateTicketSaleStatus(
    String ticketId,
    bool isOnSale,
  ) async {
    await _simulateDelay();
    final ticket = await getTicketById(ticketId);
    if (ticket == null) throw Exception('Ticket not found');

    final updatedTicket = ticket.copyWith(
      isOnSale: isOnSale,
      updatedAt: DateTime.now(),
    );

    MockDatabase.tickets[ticketId] = updatedTicket;
    _invalidateCache('getTicket');
    _invalidateCache('getTickets');
    return updatedTicket;
  }

  @override
  Future<TicketDTO> updateTicketStatus(
    String ticketId,
    PublishStatus status,
  ) async {
    await _simulateDelay();
    final ticket = await getTicketById(ticketId);
    if (ticket == null) throw Exception('Ticket not found');

    final updatedTicket = ticket.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );

    MockDatabase.tickets[ticketId] = updatedTicket;
    _invalidateCache('getTicket');
    _invalidateCache('getTickets');
    return updatedTicket;
  }

  @override
  Future<bool> validateTicket(String ticketId, String purchaseId) async {
    final key = _cacheKey('validateTicket', {
      'ticketId': ticketId,
      'purchaseId': purchaseId,
    });
    final cached = _getFromCache<bool>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final purchase = MockDatabase.purchases[purchaseId];
    final result =
        purchase != null &&
        purchase['ticketId'] == ticketId &&
        purchase['status'] == 'completed';
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<TicketDTO>> searchTickets({
    String? eventId,
    String? query,
    double? minPrice,
    double? maxPrice,
    DateTime? salesStartAfter,
    DateTime? salesEndBefore,
  }) async {
    final key = _cacheKey('searchTickets', {
      'eventId': eventId,
      'query': query,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'salesStartAfter': salesStartAfter?.toIso8601String(),
      'salesEndBefore': salesEndBefore?.toIso8601String(),
    });
    final cached = _getFromCache<List<TicketDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    var tickets = MockDatabase.tickets.values.toList();

    if (eventId != null) {
      tickets = tickets.where((ticket) => ticket.eventId == eventId).toList();
    }

    if (minPrice != null) {
      tickets = tickets.where((ticket) => ticket.price >= minPrice).toList();
    }

    if (maxPrice != null) {
      tickets = tickets.where((ticket) => ticket.price <= maxPrice).toList();
    }

    if (salesStartAfter != null) {
      tickets = tickets
          .where((ticket) => ticket.salesStartDate.isAfter(salesStartAfter))
          .toList();
    }

    if (salesEndBefore != null) {
      tickets = tickets
          .where((ticket) => ticket.salesEndDate.isBefore(salesEndBefore))
          .toList();
    }

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      tickets = tickets
          .where(
            (ticket) =>
                ticket.name.toLowerCase().contains(lowerQuery) ||
                ticket.description.toLowerCase().contains(lowerQuery),
          )
          .toList();
    }

    _setCache(key, tickets, const Duration(minutes: 1));
    return tickets;
  }

  @override
  Future<List<TicketDTO>> getTicketsByIds(List<String> ids) async {
    final key = _cacheKey('getTicketsByIds', {'ids': ids.join(',')});
    final cached = _getFromCache<List<TicketDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    final idSet = ids.toSet();
    final result = MockDatabase.tickets.values
        .where((t) => idSet.contains(t.id))
        .toList();

    _setCache(key, result);
    return result;
  }

  @override
  Future<List<TicketDTO>> getTicketsByEventIds(List<String> eventIds) async {
    final key = _cacheKey('getTicketsByEventIds', {'ids': eventIds.join(',')});
    final cached = _getFromCache<List<TicketDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    final eventIdSet = eventIds.toSet();
    final result = MockDatabase.tickets.values
        .where((t) => eventIdSet.contains(t.eventId))
        .toList();

    _setCache(key, result);
    return result;
  }

  @override
  Future<List<TicketDTO>> getTicketsByMerchantId(String merchantId) async {
    final key = _cacheKey('getTicketsByMerchantId', {'merchantId': merchantId});
    final cached = _getFromCache<List<TicketDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    final listing = MockDatabase.merchantListings[merchantId];
    final collected = <String, TicketDTO>{}; // de-dupe by id

    // (a) Tickets whose eventId == merchantId
    for (final t in MockDatabase.tickets.values) {
      if (t.eventId == merchantId) collected[t.id] = t;
    }

    // (b) Explicit ticket IDs listed on the merchant
    final directIds = listing?.ticketTypeIds;
    if (directIds != null) {
      for (final tid in directIds) {
        final t = MockDatabase.tickets[tid];
        if (t != null) collected[t.id] = t;
      }
    }

    // (c) Tickets for any events hosted by this merchant
    final hostedEventIds = listing?.accommodationEventIds;
    if (hostedEventIds != null && hostedEventIds.isNotEmpty) {
      final hostedSet = hostedEventIds.toSet();
      for (final t in MockDatabase.tickets.values) {
        if (hostedSet.contains(t.eventId)) collected[t.id] = t;
      }
    }

    final result = collected.values.toList();
    _setCache(key, result);
    return result;
  }
  // ==================== SERVICE ITEM METHODS ====================

  @override
  Future<ServiceItemDTO> createService(ServiceItemDTO service) async {
    await _simulateDelay();
    MockDatabase.services[service.id] = service;
    _invalidateCache('getService');
    _invalidateCache('getAllServices');
    _invalidateCache('getServices');
    return service;
  }

  @override
  Future<ServiceItemDTO> updateService(ServiceItemDTO service) async {
    await _simulateDelay();
    final existingService = MockDatabase.services[service.id];
    if (existingService == null) throw Exception('Service not found');

    MockDatabase.services[service.id] = service;
    _invalidateCache('getService');
    _invalidateCache('getServices');
    return service;
  }

  @override
  Future<ServiceItemDTO?> getServiceById(String serviceId) async {
    final key = _cacheKey('getServiceById', {'serviceId': serviceId});
    final cached = _getFromCache<ServiceItemDTO?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.services[serviceId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<void> deleteService(String serviceId) async {
    await _simulateDelay();
    MockDatabase.services.remove(serviceId);
    _invalidateCache('getService');
    _invalidateCache('getAllServices');
    _invalidateCache('getServices');
  }

  @override
  Future<List<ServiceItemDTO>> getServicesByHotelId(String hotelId) async {
    final key = _cacheKey('getServicesByHotelId', {'hotelId': hotelId});
    final cached = _getFromCache<List<ServiceItemDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.services.values
        .where((service) => service.serviceListingId == hotelId)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<PaginatedResult<ServiceItemDTO>> getServicesPaginated(
    int page,
    int pageSize, {
    String? hotelId,
    bool? onlyAvailable,
  }) async {
    final key = _cacheKey('getServicesPaginated', {
      'page': page,
      'pageSize': pageSize,
      'hotelId': hotelId,
      'onlyAvailable': onlyAvailable,
    });
    final cached = _getFromCache<PaginatedResult<ServiceItemDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    var services = MockDatabase.services.values.toList();

    if (hotelId != null) {
      services = services
          .where((service) => service.serviceListingId == hotelId)
          .toList();
    }

    if (onlyAvailable == true) {
      services = services.where((service) => service.isActive).toList();
    }

    final result = PaginatedResult<ServiceItemDTO>.fromList(
      allItems: services,
      page: page,
      pageSize: pageSize,
    );
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<ServiceItemDTO>> searchServices({
    String? hotelId,
    String? query,
    double? minPrice,
    double? maxPrice,
    List<String>? features,
  }) async {
    final key = _cacheKey('searchServices', {
      'hotelId': hotelId,
      'query': query,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'features': features?.join(','),
    });
    final cached = _getFromCache<List<ServiceItemDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    var services = MockDatabase.services.values.toList();

    if (hotelId != null) {
      services = services
          .where((service) => service.serviceListingId == hotelId)
          .toList();
    }

    if (minPrice != null) {
      services = services
          .where((service) => service.price >= minPrice)
          .toList();
    }

    if (maxPrice != null) {
      services = services
          .where((service) => service.price <= maxPrice)
          .toList();
    }

    if (features != null && features.isNotEmpty) {
      services = services
          .where(
            (service) =>
                features.every((feature) => service.features.contains(feature)),
          )
          .toList();
    }

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      services = services
          .where(
            (service) =>
                service.name.toLowerCase().contains(lowerQuery) ||
                service.description.toLowerCase().contains(lowerQuery),
          )
          .toList();
    }

    _setCache(key, services, const Duration(minutes: 1));
    return services;
  }

  @override
  Future<List<ServiceItemDTO>> getServicesByIds(List<String> ids) async {
    final key = _cacheKey('getServicesByIds', {'ids': ids.join(',')});
    final cached = _getFromCache<List<ServiceItemDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    final idSet = ids.toSet();
    final result = MockDatabase.services.values
        .where((s) => idSet.contains(s.id))
        .toList();

    _setCache(key, result);
    return result;
  }

  @override
  Future<List<ServiceItemDTO>> getServicesByMerchantId(
    String merchantId,
  ) async {
    final key = _cacheKey('getServicesByMerchantId', {
      'merchantId': merchantId,
    });
    final cached = _getFromCache<List<ServiceItemDTO>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    final result = MockDatabase.services.values
        .where((s) => s.serviceListingId == merchantId)
        .toList();

    _setCache(key, result);
    return result;
  }

  @override
  Future<Receipt> createReceipt(Receipt receipt) async {
    await _simulateDelay();
    MockDatabase.receipts[receipt.id] = receipt;
    _invalidateCache('getReceipt');
    _invalidateCache('getAllReceipts');
    return receipt;
  }

  @override
  Future<Receipt> createReceiptFromCart({
    required String orderId,
    required String userId,
    required List<CartItem> cartItems,
    double tax = 0.0,
    double discount = 0.0,
    String? paymentMethod,
    String? transactionId,
    String? notes,
    Map<String, dynamic>? metadata,
    String? merchantId,
    String? organisationId,
  }) async {
    await _simulateDelay();

    final receipt = Receipt.fromCart(
      orderId: orderId,
      userId: userId,
      cartItems: cartItems,
      tax: tax,
      discount: discount,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      notes: notes,
      metadata: metadata,
      merchantId: merchantId,
      organisationId: organisationId,
    );

    MockDatabase.receipts[receipt.id] = receipt;
    _invalidateCache('getReceipt');
    _invalidateCache('getReceipts');
    return receipt;
  }

  @override
  Future<Receipt?> getReceiptById(String receiptId) async {
    final key = _cacheKey('getReceiptById', {'receiptId': receiptId});
    final cached = _getFromCache<Receipt?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.receipts[receiptId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<Receipt>> getReceiptsByOrderId(String orderId) async {
    final key = _cacheKey('getReceiptsByOrderId', {'orderId': orderId});
    final cached = _getFromCache<List<Receipt>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result =
        MockDatabase.receipts.values
            .where((receipt) => receipt.orderId == orderId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<Receipt>> getReceiptsByUserId(String userId) async {
    final key = _cacheKey('getReceiptsByUserId', {'userId': userId});
    final cached = _getFromCache<List<Receipt>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result =
        MockDatabase.receipts.values
            .where((receipt) => receipt.userId == userId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<Receipt>> getReceiptsByMerchantId(String merchantId) async {
    final key = _cacheKey('getReceiptsByMerchantId', {
      'merchantId': merchantId,
    });
    final cached = _getFromCache<List<Receipt>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result =
        MockDatabase.receipts.values
            .where((receipt) => receipt.merchantId == merchantId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<Receipt>> getReceiptsByOrganisationId(
    String organisationId,
  ) async {
    final key = _cacheKey('getReceiptsByOrganisationId', {
      'organisationId': organisationId,
    });
    final cached = _getFromCache<List<Receipt>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result =
        MockDatabase.receipts.values
            .where((receipt) => receipt.organisationId == organisationId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<Receipt>> getReceiptsByStatus(ReceiptStatus status) async {
    final key = _cacheKey('getReceiptsByStatus', {'status': status.toString()});
    final cached = _getFromCache<List<Receipt>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result =
        MockDatabase.receipts.values
            .where((receipt) => receipt.status == status)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<Receipt>> getReceiptsByStatuses(
    List<ReceiptStatus> statuses,
  ) async {
    final key = _cacheKey('getReceiptsByStatuses', {
      'statuses': statuses.map((s) => s.toString()).join(','),
    });
    final cached = _getFromCache<List<Receipt>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result =
        MockDatabase.receipts.values
            .where((receipt) => statuses.contains(receipt.status))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setCache(key, result);
    return result;
  }

  @override
  Future<PaginatedResult<Receipt>> getReceiptsPaginated({
    required int page,
    required int pageSize,
    String? userId,
    String? merchantId,
    String? organisationId,
    ReceiptStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final key = _cacheKey('getReceiptsPaginated', {
      'page': page,
      'pageSize': pageSize,
      'userId': userId,
      'merchantId': merchantId,
      'organisationId': organisationId,
      'status': status?.toString(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    });
    final cached = _getFromCache<PaginatedResult<Receipt>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    var receipts = MockDatabase.receipts.values.toList();

    if (userId != null) {
      receipts = receipts.where((r) => r.userId == userId).toList();
    }
    if (merchantId != null) {
      receipts = receipts.where((r) => r.merchantId == merchantId).toList();
    }
    if (organisationId != null) {
      receipts = receipts
          .where((r) => r.organisationId == organisationId)
          .toList();
    }
    if (status != null) {
      receipts = receipts.where((r) => r.status == status).toList();
    }
    if (startDate != null) {
      receipts = receipts.where((r) => r.createdAt.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      receipts = receipts.where((r) => r.createdAt.isBefore(endDate)).toList();
    }

    receipts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final result = PaginatedResult<Receipt>.fromList(
      allItems: receipts,
      page: page,
      pageSize: pageSize,
    );
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<Receipt>> getReceiptsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final key = _cacheKey('getReceiptsByDateRange', {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    });
    final cached = _getFromCache<List<Receipt>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result =
        MockDatabase.receipts.values
            .where(
              (receipt) =>
                  receipt.createdAt.isAfter(start) &&
                  receipt.createdAt.isBefore(end),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<Receipt>> getReceiptsByDateRangeForUser(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final key = _cacheKey('getReceiptsByDateRangeForUser', {
      'userId': userId,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    });
    final cached = _getFromCache<List<Receipt>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result =
        MockDatabase.receipts.values
            .where(
              (receipt) =>
                  receipt.userId == userId &&
                  receipt.createdAt.isAfter(start) &&
                  receipt.createdAt.isBefore(end),
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setCache(key, result);
    return result;
  }

  @override
  Future<Receipt> updateReceipt(Receipt receipt) async {
    await _simulateDelay();
    final existingReceipt = MockDatabase.receipts[receipt.id];
    if (existingReceipt == null) {
      throw Exception('Receipt not found');
    }

    final updatedReceipt = receipt.copyWith(updatedAt: DateTime.now());

    MockDatabase.receipts[receipt.id] = updatedReceipt;
    _invalidateCache('getReceipt');
    _invalidateCache('getReceipts');
    return updatedReceipt;
  }

  @override
  Future<Receipt> updateReceiptStatus(
    String receiptId,
    ReceiptStatus newStatus,
  ) async {
    await _simulateDelay();
    final receipt = MockDatabase.receipts[receiptId];
    if (receipt == null) {
      throw Exception('Receipt not found');
    }

    final updatedReceipt = receipt.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      paidAt: newStatus == ReceiptStatus.purchased
          ? DateTime.now()
          : receipt.paidAt,
    );

    MockDatabase.receipts[receiptId] = updatedReceipt;
    _invalidateCache('getReceipt');
    _invalidateCache('getReceipts');
    return updatedReceipt;
  }

  @override
  Future<Receipt> updateReceiptPaymentInfo(
    String receiptId, {
    String? paymentMethod,
    String? transactionId,
    DateTime? paidAt,
  }) async {
    await _simulateDelay();
    final receipt = MockDatabase.receipts[receiptId];
    if (receipt == null) {
      throw Exception('Receipt not found');
    }

    final updatedReceipt = receipt.copyWith(
      paymentMethod: paymentMethod ?? receipt.paymentMethod,
      transactionId: transactionId ?? receipt.transactionId,
      paidAt: paidAt ?? receipt.paidAt,
      updatedAt: DateTime.now(),
      status: paidAt != null ? ReceiptStatus.purchased : receipt.status,
    );

    MockDatabase.receipts[receiptId] = updatedReceipt;
    _invalidateCache('getReceipt');
    _invalidateCache('getReceipts');
    return updatedReceipt;
  }

  @override
  Future<void> deleteReceipt(String receiptId) async {
    await _simulateDelay();
    MockDatabase.receipts.remove(receiptId);
    _invalidateCache('getReceipt');
    _invalidateCache('getReceipts');
  }

  @override
  Future<void> deleteReceiptsByUserId(String userId) async {
    await _simulateDelay();
    final receiptsToDelete = MockDatabase.receipts.values
        .where((receipt) => receipt.userId == userId)
        .toList();

    for (final receipt in receiptsToDelete) {
      MockDatabase.receipts.remove(receipt.id);
    }
    _invalidateCache('getReceipt');
    _invalidateCache('getReceipts');
  }

  @override
  Future<void> deleteReceiptsByOrderId(String orderId) async {
    await _simulateDelay();
    final receiptsToDelete = MockDatabase.receipts.values
        .where((receipt) => receipt.orderId == orderId)
        .toList();

    for (final receipt in receiptsToDelete) {
      MockDatabase.receipts.remove(receipt.id);
    }
    _invalidateCache('getReceipt');
    _invalidateCache('getReceipts');
  }

  @override
  Future<double> getTotalRevenue({
    String? userId,
    String? merchantId,
    String? organisationId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final key = _cacheKey('getTotalRevenue', {
      'userId': userId,
      'merchantId': merchantId,
      'organisationId': organisationId,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    });
    final cached = _getFromCache<double>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    var receipts = MockDatabase.receipts.values.toList();

    if (userId != null) {
      receipts = receipts.where((r) => r.userId == userId).toList();
    }
    if (merchantId != null) {
      receipts = receipts.where((r) => r.merchantId == merchantId).toList();
    }
    if (organisationId != null) {
      receipts = receipts
          .where((r) => r.organisationId == organisationId)
          .toList();
    }
    if (startDate != null) {
      receipts = receipts.where((r) => r.createdAt.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      receipts = receipts.where((r) => r.createdAt.isBefore(endDate)).toList();
    }

    receipts = receipts
        .where(
          (r) =>
              r.status == ReceiptStatus.purchased ||
              r.status == ReceiptStatus.checkedIn ||
              r.status == ReceiptStatus.checked ||
              r.status == ReceiptStatus.approved,
        )
        .toList();

    final result = receipts.fold<double>(
      0.0,
      (double sum, receipt) => sum + (receipt.total),
    );
    _setCache(key, result);
    return result;
  }

  @override
  Future<Map<ReceiptStatus, int>> getReceiptStatusCounts({
    String? userId,
    String? merchantId,
    String? organisationId,
  }) async {
    final key = _cacheKey('getReceiptStatusCounts', {
      'userId': userId,
      'merchantId': merchantId,
      'organisationId': organisationId,
    });
    final cached = _getFromCache<Map<ReceiptStatus, int>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    var receipts = MockDatabase.receipts.values.toList();

    if (userId != null) {
      receipts = receipts.where((r) => r.userId == userId).toList();
    }
    if (merchantId != null) {
      receipts = receipts.where((r) => r.merchantId == merchantId).toList();
    }
    if (organisationId != null) {
      receipts = receipts
          .where((r) => r.organisationId == organisationId)
          .toList();
    }

    final counts = <ReceiptStatus, int>{};
    for (final status in ReceiptStatus.values) {
      counts[status] = 0;
    }

    for (final receipt in receipts) {
      counts[receipt.status] = (counts[receipt.status] ?? 0) + 1;
    }

    _setCache(key, counts);
    return counts;
  }

  @override
  Future<double> getAverageOrderValue({
    String? userId,
    String? merchantId,
    String? organisationId,
  }) async {
    final key = _cacheKey('getAverageOrderValue', {
      'userId': userId,
      'merchantId': merchantId,
      'organisationId': organisationId,
    });
    final cached = _getFromCache<double>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    var receipts = MockDatabase.receipts.values.toList();

    if (userId != null) {
      receipts = receipts.where((r) => r.userId == userId).toList();
    }
    if (merchantId != null) {
      receipts = receipts.where((r) => r.merchantId == merchantId).toList();
    }
    if (organisationId != null) {
      receipts = receipts
          .where((r) => r.organisationId == organisationId)
          .toList();
    }

    receipts = receipts
        .where(
          (r) =>
              r.status == ReceiptStatus.purchased ||
              r.status == ReceiptStatus.checkedIn ||
              r.status == ReceiptStatus.checked ||
              r.status == ReceiptStatus.approved,
        )
        .toList();

    if (receipts.isEmpty) return 0.0;

    final total = receipts.fold(0.0, (sum, receipt) => sum + receipt.total);
    final result = total / receipts.length;
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<Receipt>> searchReceipts({
    String? query,
    String? userId,
    String? merchantId,
    String? organisationId,
    ReceiptStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minTotal,
    double? maxTotal,
  }) async {
    final key = _cacheKey('searchReceipts', {
      'query': query,
      'userId': userId,
      'merchantId': merchantId,
      'organisationId': organisationId,
      'status': status?.toString(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'minTotal': minTotal,
      'maxTotal': maxTotal,
    });
    final cached = _getFromCache<List<Receipt>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    var receipts = MockDatabase.receipts.values.toList();

    if (userId != null) {
      receipts = receipts.where((r) => r.userId == userId).toList();
    }
    if (merchantId != null) {
      receipts = receipts.where((r) => r.merchantId == merchantId).toList();
    }
    if (organisationId != null) {
      receipts = receipts
          .where((r) => r.organisationId == organisationId)
          .toList();
    }
    if (status != null) {
      receipts = receipts.where((r) => r.status == status).toList();
    }
    if (startDate != null) {
      receipts = receipts.where((r) => r.createdAt.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      receipts = receipts.where((r) => r.createdAt.isBefore(endDate)).toList();
    }
    if (minTotal != null) {
      receipts = receipts.where((r) => r.total >= minTotal).toList();
    }
    if (maxTotal != null) {
      receipts = receipts.where((r) => r.total <= maxTotal).toList();
    }

    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      receipts = receipts.where((r) {
        return r.orderId.toLowerCase().contains(lowerQuery) ||
            r.id.toLowerCase().contains(lowerQuery) ||
            r.items.any((item) => item.name.toLowerCase().contains(lowerQuery));
      }).toList();
    }

    receipts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    _setCache(key, receipts, const Duration(minutes: 1));
    return receipts;
  }

  @override
  Future<void> batchUpdateReceiptStatus(
    List<String> receiptIds,
    ReceiptStatus newStatus,
  ) async {
    await _simulateDelay();

    for (final receiptId in receiptIds) {
      final receipt = MockDatabase.receipts[receiptId];
      if (receipt != null) {
        final updatedReceipt = receipt.copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
          paidAt: newStatus == ReceiptStatus.purchased
              ? DateTime.now()
              : receipt.paidAt,
        );
        MockDatabase.receipts[receiptId] = updatedReceipt;
      }
    }
    _invalidateCache('getReceipt');
    _invalidateCache('getReceipts');
  }

  @override
  Future<void> batchDeleteReceipts(List<String> receiptIds) async {
    await _simulateDelay();

    for (final receiptId in receiptIds) {
      MockDatabase.receipts.remove(receiptId);
    }
    _invalidateCache('getReceipt');
    _invalidateCache('getReceipts');
  }

  // ==================== INQUIRY METHODS ====================

  @override
  Future<Inquiry> createInquiry(Inquiry inquiry) async {
    await _simulateDelay();
    MockDatabase.inquiries[inquiry.id] = inquiry;
    _invalidateCache('getInquiry');
    _invalidateCache('getInquiries');
    return inquiry;
  }

  @override
  Future<Inquiry?> getInquiryById(String inquiryId) async {
    final key = _cacheKey('getInquiryById', {'inquiryId': inquiryId});
    final cached = _getFromCache<Inquiry?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.inquiries[inquiryId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<Inquiry>> getInquiriesByUserId(String userId) async {
    final key = _cacheKey('getInquiriesByUserId', {'userId': userId});
    final cached = _getFromCache<List<Inquiry>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result =
        MockDatabase.inquiries.values
            .where((inquiry) => inquiry.userId == userId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<Inquiry>> getInquiriesByMerchantId(String merchantId) async {
    final key = _cacheKey('getInquiriesByMerchantId', {
      'merchantId': merchantId,
    });
    final cached = _getFromCache<List<Inquiry>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result =
        MockDatabase.inquiries.values
            .where((inquiry) => inquiry.merchantId == merchantId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<Inquiry>> getInquiriesByOrganisationId(
    String organisationId,
  ) async {
    final key = _cacheKey('getInquiriesByOrganisationId', {
      'organisationId': organisationId,
    });
    final cached = _getFromCache<List<Inquiry>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result =
        MockDatabase.inquiries.values
            .where((inquiry) => inquiry.organisationId == organisationId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setCache(key, result);
    return result;
  }

  @override
  Future<List<Inquiry>> getInquiriesByStatus(InquiryStatus status) async {
    final key = _cacheKey('getInquiriesByStatus', {
      'status': status.toString(),
    });
    final cached = _getFromCache<List<Inquiry>>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result =
        MockDatabase.inquiries.values
            .where((inquiry) => inquiry.status == status)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _setCache(key, result);
    return result;
  }

  @override
  Future<Inquiry> updateInquiry(Inquiry inquiry) async {
    await _simulateDelay();
    final existingInquiry = MockDatabase.inquiries[inquiry.id];
    if (existingInquiry == null) {
      throw Exception('Inquiry not found');
    }

    final updatedInquiry = inquiry.copyWith(updatedAt: DateTime.now());
    MockDatabase.inquiries[inquiry.id] = updatedInquiry;
    _invalidateCache('getInquiry');
    _invalidateCache('getInquiries');
    return updatedInquiry;
  }

  @override
  Future<Inquiry> respondToInquiry(String inquiryId, String response) async {
    await _simulateDelay();
    final inquiry = MockDatabase.inquiries[inquiryId];
    if (inquiry == null) {
      throw Exception('Inquiry not found');
    }

    final updatedInquiry = inquiry.copyWith(
      response: response,
      status: InquiryStatus.responded,
      respondedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    MockDatabase.inquiries[inquiryId] = updatedInquiry;
    _invalidateCache('getInquiry');
    _invalidateCache('getInquiries');
    return updatedInquiry;
  }

  @override
  Future<Inquiry> updateInquiryStatus(
    String inquiryId,
    InquiryStatus status,
  ) async {
    await _simulateDelay();
    final inquiry = MockDatabase.inquiries[inquiryId];
    if (inquiry == null) {
      throw Exception('Inquiry not found');
    }

    final updatedInquiry = inquiry.copyWith(
      status: status,
      resolvedAt: status == InquiryStatus.resolved ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );

    MockDatabase.inquiries[inquiryId] = updatedInquiry;
    _invalidateCache('getInquiry');
    _invalidateCache('getInquiries');
    return updatedInquiry;
  }

  @override
  Future<void> deleteInquiry(String inquiryId) async {
    await _simulateDelay();
    MockDatabase.inquiries.remove(inquiryId);
    _invalidateCache('getInquiry');
    _invalidateCache('getInquiries');
  }

  @override
  Future<PaginatedResult<Inquiry>> getInquiriesPaginated({
    required int page,
    required int pageSize,
    String? userId,
    String? merchantId,
    String? organisationId,
    InquiryStatus? status,
  }) async {
    final key = _cacheKey('getInquiriesPaginated', {
      'page': page,
      'pageSize': pageSize,
      'userId': userId,
      'merchantId': merchantId,
      'organisationId': organisationId,
      'status': status?.toString(),
    });
    final cached = _getFromCache<PaginatedResult<Inquiry>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    var inquiries = MockDatabase.inquiries.values.toList();

    if (userId != null) {
      inquiries = inquiries.where((i) => i.userId == userId).toList();
    }
    if (merchantId != null) {
      inquiries = inquiries.where((i) => i.merchantId == merchantId).toList();
    }
    if (organisationId != null) {
      inquiries = inquiries
          .where((i) => i.organisationId == organisationId)
          .toList();
    }
    if (status != null) {
      inquiries = inquiries.where((i) => i.status == status).toList();
    }

    inquiries.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final result = PaginatedResult<Inquiry>.fromList(
      allItems: inquiries,
      page: page,
      pageSize: pageSize,
    );
    _setCache(key, result);
    return result;
  }

  // ==================== MEDIA METHODS ====================

  @override
  Future<List<MediaFeedItem>> getMediaByListingId(String listingId) async {
    final key = _cacheKey('getMediaByListingId', {'listingId': listingId});
    final cached = _getFromCache<List<MediaFeedItem>>(key);
    if (cached != null) return cached;

    try {
      final result = MockDatabase.mediaFeedItems.values
          .where((item) => item.listingId == listingId)
          .toList();
      _setCache(key, result);
      return result;
    } catch (e) {
      debugPrint('Error fetching media by listing: $e');
      return [];
    }
  }

  @override
  Future<List<MediaFeedItem>> getMediaByOrganizationId(
    String organizationId,
  ) async {
    final key = _cacheKey('getMediaByOrganizationId', {
      'organizationId': organizationId,
    });
    final cached = _getFromCache<List<MediaFeedItem>>(key);
    if (cached != null) return cached;

    try {
      final result = MockDatabase.mediaFeedItems.values
          .where((item) => item.organizationId == organizationId)
          .toList();
      _setCache(key, result);
      return result;
    } catch (e) {
      debugPrint('Error fetching media by organization: $e');
      return [];
    }
  }

  @override
  Future<List<MediaFeedItem>> getTrendingMedia({int limit = 10}) async {
    final key = _cacheKey('getTrendingMedia', {'limit': limit});
    final cached = _getFromCache<List<MediaFeedItem>>(key);
    if (cached != null) return cached;

    try {
      final items = List<MediaFeedItem>.from(
        MockDatabase.mediaFeedItems.values,
      );

      items.sort(
        (a, b) => (b.likeCount + b.commentCount + b.shareCount).compareTo(
          a.likeCount + a.commentCount + a.shareCount,
        ),
      );

      final result = items.take(limit).toList();
      _setCache(key, result);
      return result;
    } catch (e) {
      debugPrint('Error fetching trending media: $e');
      return [];
    }
  }

  @override
  Future<List<MediaFeedItem>> getRecommendedMedia({int limit = 10}) async {
    final key = _cacheKey('getRecommendedMedia', {'limit': limit});
    final cached = _getFromCache<List<MediaFeedItem>>(key);
    if (cached != null) return cached;

    try {
      final items = List<MediaFeedItem>.from(
        MockDatabase.mediaFeedItems.values,
      );

      items.shuffle();
      final result = items.take(limit).toList();
      _setCache(key, result);
      return result;
    } catch (e) {
      debugPrint('Error fetching recommended media: $e');
      return [];
    }
  }

  @override
  Future<LikeResponse> toggleLike({
    required String mediaId,
    required bool isLiked,
    String? userId,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final item = MockDatabase.mediaFeedItems[mediaId];
      if (item != null) {
        final updatedItem = item.copyWith(
          isLikedByUser: isLiked,
          likeCount: isLiked ? item.likeCount + 1 : item.likeCount - 1,
        );
        MockDatabase.mediaFeedItems[mediaId] = updatedItem;
        _invalidateCache('getMedia');
        _invalidateCache('getTrendingMedia');

        return LikeResponse(
          success: true,
          message: isLiked ? 'Liked successfully' : 'Unliked successfully',
          likeCount: updatedItem.likeCount,
        );
      }

      return LikeResponse(
        success: false,
        message: 'Media item not found',
        likeCount: 0,
      );
    } catch (e) {
      debugPrint('Error toggling like: $e');
      return LikeResponse(success: false, message: 'Failed to toggle like: $e');
    }
  }

  @override
  Future<int> getLikeCount(String mediaId) async {
    final key = _cacheKey('getLikeCount', {'mediaId': mediaId});
    final cached = _getFromCache<int>(key);
    if (cached != null) return cached;

    try {
      final item = MockDatabase.mediaFeedItems[mediaId];
      final result = item?.likeCount ?? 0;
      _setCache(key, result);
      return result;
    } catch (e) {
      debugPrint('Error getting like count: $e');
      return 0;
    }
  }

  @override
  Future<bool> hasUserLikedMedia({
    required String mediaId,
    required String userId,
  }) async {
    final key = _cacheKey('hasUserLikedMedia', {
      'mediaId': mediaId,
      'userId': userId,
    });
    final cached = _getFromCache<bool>(key);
    if (cached != null) return cached;

    try {
      final item = MockDatabase.mediaFeedItems[mediaId];
      final result = item?.isLikedByUser ?? false;
      _setCache(key, result);
      return result;
    } catch (e) {
      debugPrint('Error checking like status: $e');
      return false;
    }
  }

  @override
  Future<FollowResponse> toggleFollow({
    required String organizationId,
    required bool isFollowing,
    String? userId,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      final items = MockDatabase.mediaFeedItems.values
          .where((item) => item.organizationId == organizationId)
          .toList();

      for (final item in items) {
        final updatedItem = item.copyWith(isFollowing: isFollowing);
        MockDatabase.mediaFeedItems[item.id] = updatedItem;
      }

      final followersCount =
          items.length + (organizationId.hashCode.abs() % 500) + 10;

      _invalidateCache('getMedia');

      return FollowResponse(
        success: true,
        message: isFollowing
            ? 'Followed successfully'
            : 'Unfollowed successfully',
        followersCount: followersCount,
      );
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      return FollowResponse(
        success: false,
        message: 'Failed to toggle follow: $e',
      );
    }
  }

  @override
  Future<bool> getFollowStatus({
    required String organizationId,
    required String userId,
  }) async {
    final key = _cacheKey('getFollowStatus', {
      'organizationId': organizationId,
      'userId': userId,
    });
    final cached = _getFromCache<bool>(key);
    if (cached != null) return cached;

    try {
      final items = MockDatabase.mediaFeedItems.values
          .where((item) => item.organizationId == organizationId)
          .toList();
      final result = items.any((item) => item.isFollowing);
      _setCache(key, result);
      return result;
    } catch (e) {
      debugPrint('Error getting follow status: $e');
      return false;
    }
  }

  @override
  Future<int> getFollowersCount(String organizationId) async {
    final key = _cacheKey('getFollowersCount', {
      'organizationId': organizationId,
    });
    final cached = _getFromCache<int>(key);
    if (cached != null) return cached;

    try {
      final items = MockDatabase.mediaFeedItems.values
          .where((item) => item.organizationId == organizationId)
          .toList();
      final result = items.length + (organizationId.hashCode.abs() % 500) + 10;
      _setCache(key, result);
      return result;
    } catch (e) {
      debugPrint('Error getting followers count: $e');
      return 0;
    }
  }

  @override
  Future<void> trackShare({
    required String mediaId,
    required String userId,
    String? platform,
  }) async {
    try {
      final item = MockDatabase.mediaFeedItems[mediaId];
      if (item != null) {
        final updatedItem = item.copyWith(shareCount: item.shareCount + 1);
        MockDatabase.mediaFeedItems[mediaId] = updatedItem;
        _invalidateCache('getMedia');
      }
      debugPrint('Track share: $mediaId by $userId on $platform');
    } catch (e) {
      debugPrint('Error tracking share: $e');
    }
  }

  @override
  Future<void> trackView({
    required String mediaId,
    required String userId,
    Duration? viewDuration,
  }) async {
    try {
      final item = MockDatabase.mediaFeedItems[mediaId];
      if (item != null) {
        final updatedItem = item.copyWith(viewCount: item.viewCount + 1);
        MockDatabase.mediaFeedItems[mediaId] = updatedItem;
        _invalidateCache('getMedia');
      }
      debugPrint('Track view: $mediaId by $userId');
    } catch (e) {
      debugPrint('Error tracking view: $e');
    }
  }

  @override
  Future<MediaStats> getMediaStats(String mediaId) async {
    final key = _cacheKey('getMediaStats', {'mediaId': mediaId});
    final cached = _getFromCache<MediaStats>(key);
    if (cached != null) return cached;

    try {
      final item = MockDatabase.mediaFeedItems[mediaId];
      if (item != null) {
        final result = MediaStats(
          views: item.viewCount,
          likes: item.likeCount,
          comments: item.commentCount,
          shares: item.shareCount,
          saves: item.isSavedByUser ? 1 : 0,
          engagementRate:
              (item.likeCount + item.commentCount) /
              (item.viewCount > 0 ? item.viewCount : 1),
        );
        _setCache(key, result);
        return result;
      }
      return const MediaStats();
    } catch (e) {
      debugPrint('Error getting media stats: $e');
      return const MediaStats();
    }
  }

  @override
  Future<void> reportMedia({
    required String mediaId,
    required String reason,
    String? description,
  }) async {
    try {
      MockDatabase.mediaFeedItems.remove(mediaId);
      _invalidateCache('getMedia');
      debugPrint('Report media: $mediaId, reason: $reason');
    } catch (e) {
      debugPrint('Error reporting media: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveMedia({
    required String mediaId,
    required String userId,
    String? collectionName,
  }) async {
    try {
      final item = MockDatabase.mediaFeedItems[mediaId];
      if (item != null) {
        final updatedItem = item.copyWith(isSavedByUser: true);
        MockDatabase.mediaFeedItems[mediaId] = updatedItem;
        _invalidateCache('getMedia');
      }
      debugPrint('Save media: $mediaId by $userId');
    } catch (e) {
      debugPrint('Error saving media: $e');
      rethrow;
    }
  }

  @override
  Future<void> unsaveMedia({
    required String mediaId,
    required String userId,
  }) async {
    try {
      final item = MockDatabase.mediaFeedItems[mediaId];
      if (item != null) {
        final updatedItem = item.copyWith(isSavedByUser: false);
        MockDatabase.mediaFeedItems[mediaId] = updatedItem;
        _invalidateCache('getMedia');
      }
      debugPrint('Unsave media: $mediaId by $userId');
    } catch (e) {
      debugPrint('Error unsaving media: $e');
      rethrow;
    }
  }

  @override
  Future<List<MediaFeedItem>> getSavedMedia({
    required String userId,
    int limit = 20,
  }) async {
    final key = _cacheKey('getSavedMedia', {'userId': userId, 'limit': limit});
    final cached = _getFromCache<List<MediaFeedItem>>(key);
    if (cached != null) return cached;

    try {
      final result = MockDatabase.mediaFeedItems.values
          .where((item) => item.isSavedByUser)
          .take(limit)
          .toList();
      _setCache(key, result);
      return result;
    } catch (e) {
      debugPrint('Error getting saved media: $e');
      return [];
    }
  }

  @override
  Future<PaginatedResult<MediaFeedItem>> getMediaFeed({
    int page = 1,
    int pageSize = 20,
    String? organizationId,
    String? listingId,
    MediaType? mediaType,
    String? searchQuery,
  }) async {
    final key = _cacheKey('getMediaFeed', {
      'page': page,
      'pageSize': pageSize,
      'organizationId': organizationId,
      'listingId': listingId,
      'mediaType': mediaType?.toString(),
      'searchQuery': searchQuery,
    });
    final cached = _getFromCache<PaginatedResult<MediaFeedItem>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    try {
      var items = List<MediaFeedItem>.from(MockDatabase.mediaFeedItems.values);

      if (organizationId != null) {
        items = items
            .where((item) => item.organizationId == organizationId)
            .toList();
      }
      if (listingId != null) {
        items = items.where((item) => item.listingId == listingId).toList();
      }
      if (mediaType != null) {
        items = items.where((item) => item.mediaType == mediaType).toList();
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        items = items.where((item) {
          return item.title?.toLowerCase().contains(query) == true ||
              item.description?.toLowerCase().contains(query) == true ||
              item.organizationName?.toLowerCase().contains(query) == true;
        }).toList();
      }

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final totalCount = items.length;
      final start = (page - 1) * pageSize;
      final end = start + pageSize;
      final hasNextPage = end < totalCount;
      final hasPreviousPage = page > 1;

      final paginatedItems = items.length > start
          ? items.sublist(start, end > items.length ? items.length : end)
          : <MediaFeedItem>[];

      final result = PaginatedResult<MediaFeedItem>(
        items: paginatedItems,
        totalCount: totalCount,
        page: page,
        pageSize: pageSize,
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
      );

      _setCache(key, result);
      return result;
    } catch (e) {
      debugPrint('Error fetching media feed: $e');
      return PaginatedResult<MediaFeedItem>(
        items: [],
        totalCount: 0,
        page: page,
        pageSize: pageSize,
        hasNextPage: false,
        hasPreviousPage: false,
      );
    }
  }

  @override
  Future<PaginatedResult<MediaComment>> getComments({
    required String mediaId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final key = _cacheKey('getComments', {
      'mediaId': mediaId,
      'page': page,
      'pageSize': pageSize,
    });
    final cached = _getFromCache<PaginatedResult<MediaComment>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    try {
      var comments = MockDatabase.mediaComments[mediaId] ?? [];

      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final totalCount = comments.length;
      final start = (page - 1) * pageSize;
      final end = start + pageSize;
      final hasNextPage = end < totalCount;
      final hasPreviousPage = page > 1;

      final paginatedItems = comments.length > start
          ? comments.sublist(
              start,
              end > comments.length ? comments.length : end,
            )
          : <MediaComment>[];

      final result = PaginatedResult<MediaComment>(
        items: paginatedItems,
        totalCount: totalCount,
        page: page,
        pageSize: pageSize,
        hasNextPage: hasNextPage,
        hasPreviousPage: hasPreviousPage,
      );

      _setCache(key, result);
      return result;
    } catch (e) {
      debugPrint('Error getting comments for media $mediaId: $e');
      return PaginatedResult<MediaComment>(
        items: [],
        totalCount: 0,
        page: page,
        pageSize: pageSize,
        hasNextPage: false,
        hasPreviousPage: false,
      );
    }
  }

  @override
  Future<MediaComment> addComment({
    required String mediaId,
    required String userId,
    required String userName,
    required String comment,
    String? userAvatarUrl,
  }) async {
    try {
      final newComment = MediaComment(
        id: 'comment_${DateTime.now().millisecondsSinceEpoch}',
        mediaId: mediaId,
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        comment: comment,
        createdAt: DateTime.now(),
        likeCount: 0,
        isLikedByUser: false,
      );

      if (!MockDatabase.mediaComments.containsKey(mediaId)) {
        MockDatabase.mediaComments[mediaId] = [];
      }
      MockDatabase.mediaComments[mediaId]!.add(newComment);

      final item = MockDatabase.mediaFeedItems[mediaId];
      if (item != null) {
        final updatedItem = item.copyWith(commentCount: item.commentCount + 1);
        MockDatabase.mediaFeedItems[mediaId] = updatedItem;
      }

      _invalidateCache('getComments');
      _invalidateCache('getMedia');
      return newComment;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  }) async {
    try {
      for (final entry in MockDatabase.mediaComments.entries) {
        final comments = entry.value;
        final index = comments.indexWhere((c) => c.id == commentId);
        if (index != -1) {
          final removedComment = comments.removeAt(index);
          final item = MockDatabase.mediaFeedItems[removedComment.mediaId];
          if (item != null) {
            final updatedItem = item.copyWith(
              commentCount: item.commentCount - 1,
            );
            MockDatabase.mediaFeedItems[removedComment.mediaId] = updatedItem;
          }
          break;
        }
      }
      _invalidateCache('getComments');
      _invalidateCache('getMedia');
      debugPrint('Delete comment: $commentId by $userId');
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      rethrow;
    }
  }

  @override
  Future<void> likeComment({
    required String commentId,
    required String userId,
  }) async {
    try {
      for (final entry in MockDatabase.mediaComments.entries) {
        final comments = entry.value;
        final index = comments.indexWhere((c) => c.id == commentId);
        if (index != -1) {
          final comment = comments[index];
          final updatedComment = comment.copyWith(
            likeCount: comment.likeCount + 1,
            isLikedByUser: true,
          );
          comments[index] = updatedComment;
          _invalidateCache('getComments');
          break;
        }
      }
      debugPrint('Like comment: $commentId by $userId');
    } catch (e) {
      debugPrint('Error liking comment: $e');
      rethrow;
    }
  }

  // ==================== WALLET METHODS ====================

  @override
  Future<WalletModel> getWalletByUserId(String userId) async {
    final key = _cacheKey('getWalletByUserId', {'userId': userId});
    final cached = _getFromCache<WalletModel>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    if (MockDatabase.wallets.containsKey(userId)) {
      final result = MockDatabase.wallets[userId]!;
      _setCache(key, result);
      return result;
    }

    final walletId = 'wallet_$userId';
    if (MockDatabase.wallets.containsKey(walletId)) {
      final result = MockDatabase.wallets[walletId]!;
      _setCache(key, result);
      return result;
    }

    final newWallet = WalletModel(
      id: walletId,
      userId: userId,
      balance: 100.0,
      currency: 'TTD',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    MockDatabase.wallets[userId] = newWallet;
    MockDatabase.wallets[walletId] = newWallet;
    _setCache(key, newWallet);
    return newWallet;
  }

  @override
  Future<List<TransactionModel>> getRecentTransactions(
    String userId, {
    int limit = 10,
  }) async {
    final key = _cacheKey('getRecentTransactions', {
      'userId': userId,
      'limit': limit,
    });
    final cached = _getFromCache<List<TransactionModel>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    final userTransactions = MockDatabase.transactions[userId] ?? [];
    userTransactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final result = userTransactions.take(limit).toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<WalletModel> topUpWallet(
    double amount,
    String paymentMethodId,
    String userId,
  ) async {
    await _simulateDelay();

    if (userId.isEmpty) {
      throw Exception('User ID is required');
    }

    WalletModel wallet;
    if (MockDatabase.wallets.containsKey(userId)) {
      wallet = MockDatabase.wallets[userId]!;
    } else {
      wallet = await getWalletByUserId(userId);
    }

    final updatedWallet = wallet.copyWith(
      balance: wallet.balance + amount,
      updatedAt: DateTime.now(),
    );

    MockDatabase.wallets[userId] = updatedWallet;
    MockDatabase.wallets[wallet.id] = updatedWallet;

    final transaction = TransactionModel(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      walletId: wallet.id,
      amount: amount,
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      description: 'Top-up via $paymentMethodId',
      timestamp: DateTime.now(),
      metadata: {
        'paymentMethodId': paymentMethodId,
        'transactionType': 'credit',
        'reference': 'TOPUP_${DateTime.now().millisecondsSinceEpoch}',
        'userId': userId,
      },
    );

    if (!MockDatabase.transactions.containsKey(userId)) {
      MockDatabase.transactions[userId] = [];
    }
    MockDatabase.transactions[userId]!.add(transaction);

    _invalidateCache('getWalletByUserId');
    _invalidateCache('getRecentTransactions');
    return updatedWallet;
  }

  @override
  Future<WalletModel> withdrawFromWallet(
    double amount,
    String paymentMethodId,
    String userId,
  ) async {
    await _simulateDelay();

    if (userId.isEmpty) {
      throw Exception('User ID is required');
    }

    if (!MockDatabase.wallets.containsKey(userId)) {
      throw Exception('Wallet not found for user: $userId');
    }

    final wallet = MockDatabase.wallets[userId]!;

    if (wallet.balance < amount) {
      throw Exception(
        'Insufficient balance. Available: ${wallet.balance}, Requested: $amount',
      );
    }

    final updatedWallet = wallet.copyWith(
      balance: wallet.balance - amount,
      updatedAt: DateTime.now(),
    );

    MockDatabase.wallets[userId] = updatedWallet;
    MockDatabase.wallets[wallet.id] = updatedWallet;

    final transaction = TransactionModel(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      walletId: wallet.id,
      amount: amount,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Withdrawal to $paymentMethodId',
      timestamp: DateTime.now(),
      metadata: {
        'paymentMethodId': paymentMethodId,
        'transactionType': 'debit',
        'reference': 'WITHDRAW_${DateTime.now().millisecondsSinceEpoch}',
        'userId': userId,
      },
    );

    if (!MockDatabase.transactions.containsKey(userId)) {
      MockDatabase.transactions[userId] = [];
    }
    MockDatabase.transactions[userId]!.add(transaction);

    _invalidateCache('getWalletByUserId');
    _invalidateCache('getRecentTransactions');
    return updatedWallet;
  }

  // ==================== PAYMENT METHOD METHODS ====================

  @override
  Future<List<BaseMethod>> getPaymentMethodsByUserId(String userId) async {
    final key = _cacheKey('getPaymentMethodsByUserId', {'userId': userId});
    final cached = _getFromCache<List<BaseMethod>>(key);
    if (cached != null) return cached;

    await _simulateDelay();

    if (userId.isEmpty) {
      return [];
    }

    final result = MockDatabase.paymentMethods.values
        .where((method) => method.userId == userId)
        .toList();
    _setCache(key, result);
    return result;
  }

  @override
  Future<void> addCreditCard(CreditCardModel card) async {
    await _simulateDelay();

    if (card.cardNumber.isEmpty) {
      throw Exception('Card number is required');
    }
    if (card.holderName.isEmpty) {
      throw Exception('Card holder name is required');
    }
    if (card.expiryDate.isBefore(DateTime.now())) {
      throw Exception('Invalid or expired card date');
    }
    if (card.cvv.isEmpty || card.cvv.length < 3) {
      throw Exception('Invalid CVV');
    }

    if (!MockDatabase.wallets.containsKey(card.userId)) {
      throw Exception('User not found: ${card.userId}');
    }

    final maskedCard = CreditCardModel(
      id: card.id,
      userId: card.userId,
      isDefault: card.isDefault,
      isVerified: card.isVerified,
      addedDate: card.addedDate,
      cardNumber:
          '****${card.cardNumber.substring(card.cardNumber.length - 4)}',
      holderName: card.holderName,
      expiryDate: card.expiryDate,
      cvv: '***',
      cardType: card.cardType,
    );

    final userCards = await getPaymentMethodsByUserId(card.userId);
    if (userCards.isEmpty) {
      final defaultCard = maskedCard.copyWithDefault(true);
      MockDatabase.paymentMethods[card.id] = defaultCard;
    } else {
      MockDatabase.paymentMethods[card.id] = maskedCard;
    }
    _invalidateCache('getPaymentMethodsByUserId');
  }

  @override
  Future<void> addBankAccount(BankAccountModel account) async {
    await _simulateDelay();

    if (account.accountNumber.isEmpty) {
      throw Exception('Account number is required');
    }
    if (account.routingNumber.isEmpty) {
      throw Exception('Routing number is required');
    }
    if (account.bankName.isEmpty) {
      throw Exception('Bank name is required');
    }
    if (account.accountHolderName.isEmpty) {
      throw Exception('Account holder name is required');
    }

    if (!MockDatabase.wallets.containsKey(account.userId)) {
      throw Exception('User not found: ${account.userId}');
    }

    final maskedAccount = BankAccountModel(
      id: account.id,
      userId: account.userId,
      isDefault: account.isDefault,
      isVerified: account.isVerified,
      addedDate: account.addedDate,
      accountNumber:
          '****${account.accountNumber.substring(account.accountNumber.length - 4)}',
      routingNumber: account.routingNumber,
      bankName: account.bankName,
      accountType: account.accountType,
      accountHolderName: account.accountHolderName,
      accountHolderType: account.accountHolderType,
    );

    final userAccounts = await getPaymentMethodsByUserId(account.userId);
    if (userAccounts.isEmpty) {
      final defaultAccount = maskedAccount.copyWithDefault(true);
      MockDatabase.paymentMethods[account.id] = defaultAccount;
    } else {
      MockDatabase.paymentMethods[account.id] = maskedAccount;
    }
    _invalidateCache('getPaymentMethodsByUserId');
  }

  @override
  Future<void> addStripeAccount(StripeAccountModel account) async {
    await _simulateDelay();

    if (account.accountId.isEmpty) {
      throw Exception('Stripe account ID is required');
    }
    if (account.email.isEmpty) {
      throw Exception('Email is required');
    }

    if (!MockDatabase.wallets.containsKey(account.userId)) {
      throw Exception('User not found: ${account.userId}');
    }

    final userAccounts = await getPaymentMethodsByUserId(account.userId);
    final stripeAccounts = userAccounts
        .whereType<StripeAccountModel>()
        .toList();

    if (stripeAccounts.isEmpty) {
      final defaultAccount = account.copyWithDefault(true);
      MockDatabase.paymentMethods[account.id] = defaultAccount;
    } else {
      MockDatabase.paymentMethods[account.id] = account;
    }
    _invalidateCache('getPaymentMethodsByUserId');
  }

  @override
  Future<void> addPayPalAccount(PayPalAccountModel account) async {
    await _simulateDelay();

    if (account.email.isEmpty) {
      throw Exception('PayPal email is required');
    }
    if (account.country.isEmpty) {
      throw Exception('Country is required');
    }

    if (!MockDatabase.wallets.containsKey(account.userId)) {
      throw Exception('User not found: ${account.userId}');
    }

    final userAccounts = await getPaymentMethodsByUserId(account.userId);
    final paypalAccounts = userAccounts
        .whereType<PayPalAccountModel>()
        .toList();

    if (paypalAccounts.isEmpty) {
      final defaultAccount = account.copyWithDefault(true);
      MockDatabase.paymentMethods[account.id] = defaultAccount;
    } else {
      MockDatabase.paymentMethods[account.id] = account;
    }
    _invalidateCache('getPaymentMethodsByUserId');
  }

  @override
  Future<void> setDefaultPaymentMethod(String id) async {
    await _simulateDelay();

    final method = MockDatabase.paymentMethods[id];
    if (method == null) {
      throw Exception('Payment method not found: $id');
    }

    final userMethods = await getPaymentMethodsByUserId(method.userId);

    for (final m in userMethods) {
      if (m.id != id) {
        final updated = m.copyWithDefault(false);
        MockDatabase.paymentMethods[m.id] = updated;
      }
    }

    final updatedDefault = method.copyWithDefault(true);
    MockDatabase.paymentMethods[id] = updatedDefault;
    _invalidateCache('getPaymentMethodsByUserId');
  }

  @override
  Future<void> deletePaymentMethod(String id) async {
    await _simulateDelay();

    if (!MockDatabase.paymentMethods.containsKey(id)) {
      throw Exception('Payment method not found: $id');
    }

    final method = MockDatabase.paymentMethods[id]!;

    if (method.isDefault) {
      final userMethods = await getPaymentMethodsByUserId(method.userId);
      final remainingMethods = userMethods.where((m) => m.id != id).toList();

      if (remainingMethods.isNotEmpty) {
        await setDefaultPaymentMethod(remainingMethods.first.id);
      }
    }

    MockDatabase.paymentMethods.remove(id);
    _invalidateCache('getPaymentMethodsByUserId');
  }

  // ==================== HELPER/UTILITY METHODS ====================

  @override
  Future<bool> healthCheck() async {
    await _simulateDelay();
    return true;
  }

  @override
  Future<void> dispose() async {
    await _simulateDelay();
    clearAllCache();
  }

  Future<void> resetDatabase() async {
    await _simulateDelay();
    MockDatabase.reset();
    clearAllCache();
  }

  // ==================== CHAT METHODS (Stubs) ====================

  @override
  Future<ChatGroup> createChatGroup(CreateChatRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteChatGroup(String chatGroupId) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteMessage(String messageId) {
    throw UnimplementedError();
  }

  @override
  Future<ChatGroup?> getChatGroupById(String chatGroupId) {
    throw UnimplementedError();
  }

  @override
  Future<ChatGroup?> getChatGroupByTeamAndCustomer(
    String teamId,
    String customerId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<ChatGroup>> getChatGroupsForCustomer(String customerId) {
    throw UnimplementedError();
  }

  @override
  Future<PaginatedResult<ChatGroup>> getChatGroupsForCustomerPaginated(
    String customerId,
    int page,
    int pageSize,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<ChatGroup>> getChatGroupsForMember(String memberId) {
    throw UnimplementedError();
  }

  @override
  Future<PaginatedResult<ChatGroup>> getChatGroupsForMemberPaginated(
    String memberId,
    int page,
    int pageSize,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<List<ChatMessage>> getMessages(
    String chatGroupId, {
    int limit = 50,
    DateTime? before,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<PaginatedResult<ChatMessage>> getMessagesPaginated(
    String chatGroupId,
    int page,
    int pageSize,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<int> getUnreadCountForCustomer(String customerId) {
    throw UnimplementedError();
  }

  @override
  Future<int> getUnreadCountForMember(String memberId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, int>> getUnreadCountsByChatGroup(String memberId) {
    throw UnimplementedError();
  }

  @override
  Future<void> markMessagesAsRead(String chatGroupId, String readerId) {
    throw UnimplementedError();
  }

  @override
  Future<ChatMessage> sendMessage({
    required String chatGroupId,
    required String senderId,
    required String senderName,
    required String senderImageUrl,
    required MessageSenderType senderType,
    required String content,
    MessageType messageType = MessageType.text,
    Map<String, dynamic>? metadata,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<ChatGroup> subscribeToChatGroup(String chatGroupId) {
    throw UnimplementedError();
  }

  @override
  Stream<ChatMessage> subscribeToMessages(String chatGroupId) {
    throw UnimplementedError();
  }

  @override
  Future<ChatGroup> updateChatGroup(ChatGroup chatGroup) {
    throw UnimplementedError();
  }

  // ==========================================================
  // SUBSCRIPTION API IMPLEMENTATION
  // ==========================================================

  // ==================== INVITATION METHODS (FIXED) ====================

  @override
  Future<InvitationDTO> createInvitation(InvitationDTO invitation) async {
    await _simulateDelay();
    final newInvitation = invitation.copyWith(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    MockDatabase.invitations[newInvitation.id] = newInvitation;
    _invalidateCache('getInvitation');
    _invalidateCache('getInvitations');

    // Also add to member's invitationIds if userId is provided
    if (newInvitation.userId != null) {
      final member = MockDatabase.members[newInvitation.userId];
      if (member != null && !member.invitationIds.contains(newInvitation.id)) {
        final updatedMember = member.copyWith(
          invitationIds: [...member.invitationIds, newInvitation.id],
        );
        MockDatabase.members[member.id] = updatedMember;
        MockDatabase.users[member.id] = updatedMember;
        MockDatabase.users[member.email] = updatedMember;
      }
    }

    debugPrint('[MockApiService] Created invitation: ${newInvitation.id}');
    return newInvitation;
  }

  @override
  Future<InvitationDTO?> getInvitationById(String invitationId) async {
    final key = _cacheKey('getInvitationById', {'invitationId': invitationId});
    final cached = _getFromCache<InvitationDTO?>(key);
    if (cached != null) return cached;

    await _simulateDelay();
    final result = MockDatabase.invitations[invitationId];
    _setCache(key, result);
    return result;
  }

  @override
  Future<InvitationDTO> updateInvitation(InvitationDTO invitation) async {
    await _simulateDelay();
    final existing = MockDatabase.invitations[invitation.id];
    if (existing == null) {
      throw Exception('Invitation not found: ${invitation.id}');
    }

    final updated = invitation.copyWith(updatedAt: DateTime.now());
    MockDatabase.invitations[invitation.id] = updated;

    // Update member's invitation list if status changed to accepted/rejected
    if (updated.userId != null) {
      final member = MockDatabase.members[updated.userId];
      if (member != null) {
        if (updated.status == InvitationStatus.accepted) {
          // Add to team if not already a member
          if (updated.teamId != null &&
              !member.teamIds.contains(updated.teamId)) {
            final team = MockDatabase.teams[updated.teamId];
            if (team != null && !team.memberIds.contains(member.id)) {
              final updatedTeam = team.addMember(member.id);
              MockDatabase.teams[updatedTeam.id] = updatedTeam;
            }
          }
          // Add to organisation if not already
          if (member.organisationId != updated.organisationId) {
            final updatedMember = member.copyWith(
              organisationId: updated.organisationId,
            );
            MockDatabase.members[member.id] = updatedMember;
            MockDatabase.users[member.id] = updatedMember;
            MockDatabase.users[member.email] = updatedMember;
          }
        } else if (updated.status == InvitationStatus.rejected ||
            updated.status == InvitationStatus.cancelled) {
          // Remove from member's invitation list
          final updatedMember = member.copyWith(
            invitationIds: member.invitationIds
                .where((id) => id != updated.id)
                .toList(),
          );
          MockDatabase.members[member.id] = updatedMember;
          MockDatabase.users[member.id] = updatedMember;
          MockDatabase.users[member.email] = updatedMember;
        }
      }
    }

    _invalidateCache('getInvitation');
    _invalidateCache('getInvitations');

    debugPrint(
      '[MockApiService] Updated invitation: ${updated.id} -> ${updated.status}',
    );
    return updated;
  }

  // ==================== TEAM METHODS (FIXED) ====================

  @override
  Future<TeamDTO> updateTeam(TeamDTO team) async {
    await _simulateDelay();
    final existing = MockDatabase.teams[team.id];
    if (existing == null) {
      throw Exception('Team not found: ${team.id}');
    }

    final updated = team.copyWith(updatedAt: DateTime.now());
    MockDatabase.teams[team.id] = updated;

    // Update member's team lists if members changed
    final addedMembers = updated.memberIds
        .where((id) => !existing.memberIds.contains(id))
        .toList();
    final removedMembers = existing.memberIds
        .where((id) => !updated.memberIds.contains(id))
        .toList();

    for (final memberId in addedMembers) {
      final member = MockDatabase.members[memberId];
      if (member != null && !member.teamIds.contains(team.id)) {
        final updatedMember = member.copyWith(
          teamIds: [...member.teamIds, team.id],
        );
        MockDatabase.members[memberId] = updatedMember;
        MockDatabase.users[memberId] = updatedMember;
        MockDatabase.users[member.email] = updatedMember;
      }
    }

    for (final memberId in removedMembers) {
      final member = MockDatabase.members[memberId];
      if (member != null) {
        final updatedMember = member.copyWith(
          teamIds: member.teamIds.where((id) => id != team.id).toList(),
        );
        MockDatabase.members[memberId] = updatedMember;
        MockDatabase.users[memberId] = updatedMember;
        MockDatabase.users[member.email] = updatedMember;
      }
    }

    _invalidateCache('getTeam');
    _invalidateCache('getTeams');
    _invalidateCache('getAllTeams');

    debugPrint('[MockApiService] Updated team: ${updated.id}');
    return updated;
  }

  // ==========================================================
  // OTHER REQUIRED API METHODS (implement stubs)
  // ==========================================================
}

// ==================== CACHE ENTRY CLASS ====================

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});
}
