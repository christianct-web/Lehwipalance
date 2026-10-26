import 'package:flutter/material.dart';
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

abstract class ApiService
    implements
        UserApiService,
        MemberApiService,
        CustomerApiService,
        InvitationApiService,
        MerchantListingApiService,
        OrganisationApiService,
        LocationApiService,
        TeamApiService,
        RoomApiService,
        TicketApiService,
        ReceiptApiService,
        InquiryApiService,
        ServiceItemApiService,
        MediaFeedApiService,
        WalletApiService,
        PaymentMethodApiService,
        ChatApiService
// Add other specific API service interfaces here
{
  // This interface now composes all specific API services
  // No additional methods needed - it's a marker interface for convenience

  // Optional: Add health check or common methods
  Future<bool> healthCheck();
  Future<void> initialize();
  Future<void> dispose();
}

abstract class UserApiService {
  Future<UserDTO> upsertUser(UserDTO user);
  Future<UserDTO?> getUserById(String userId);
  Future<UserDTO?> getUserByEmail(String email);
  Future<void> deleteUser(String userId);
  Future<List<UserDTO>> getAllUsers();
  Future<PaginatedResult<UserDTO>> getUsersPaginated(int page, int pageSize);
  Future<List<UserDTO>> getActiveUsers();
  Future<List<UserDTO>> getBannedUsers();
  Future<List<UserDTO>> searchUsers(String query);
  Future<UserDTO> updateUserActiveStatus(String userId, bool isActive);
  Future<UserDTO> banUser(String userId, String reason);
  Future<UserDTO> unbanUser(String userId);
  Future<UserDTO> updateUserFcmToken(String userId, String? fcmToken);
}

abstract class TeamApiService {
  Future<TeamDTO> createTeam(TeamDTO team);
  Future<TeamDTO?> getTeamById(String teamId);
  Future<List<TeamDTO>> getTeamsByMemberId(String memberId);
  Future<List<TeamDTO>> getTeamsByOrganisationId(String organisationId);
  Future<List<TeamDTO>> getTeamsByListingId(String listingId);
  Future<TeamDTO> addMemberToTeam(String teamId, String userId);
  Future<TeamDTO> removeMemberFromTeam(String teamId, String userId);
  Future<TeamDTO> updateTeamPermissions(
    String teamId,
    List<String> permissionStrings,
  );
  Future<void> deleteTeam(String teamId);
  Future<PaginatedResult<TeamDTO>> getTeamsPaginated(
    int page,
    int pageSize, {
    String? organisationId,
  });
  Future<List<TeamDTO>> getAllTeams();
  Future<TeamDTO> updateTeam(TeamDTO team);
}

abstract class InvitationApiService {
  Future<InvitationDTO> createInvitation(InvitationDTO invitation);
  Future<InvitationDTO?> getInvitationById(String invitationId);
  Future<InvitationDTO> updateInvitation(InvitationDTO invitation);
  Future<List<InvitationDTO>> getInvitationsByTeamId(String teamId);
  Future<List<InvitationDTO>> getInvitationsSentByUser(String userId);
  Future<void> deleteInvitation(String id);
  Future<PaginatedResult<InvitationDTO>> getInvitationsPaginated(
    int page,
    int pageSize, {
    String? teamId,
    String? userId,
    String? organisationId,
    InvitationStatus? status,
  });
}

// lib/services/api/location_api_service.dart
abstract class LocationApiService {
  Future<LocationModel> upsertLocation(LocationModel location);
  Future<LocationModel?> getLocationById(String locationId);
  Future<void> deleteLocation(String locationId);
  Future<List<LocationModel>> getAllLocations();
  Future<PaginatedResult<LocationModel>> getLocationsPaginated(
    int page,
    int pageSize,
  );

  Future<List<LocationModel>> getLocationsByHost(String hostId);
  Future<List<LocationModel>> getLocationsByMainVenue(String mainVenueId);
  Future<List<LocationModel>> searchLocations(String query);
  Future<List<LocationModel>> getLocationsNearby(
    double latitude,
    double longitude,
    double radiusInKm,
  );
}

// lib/services/api/merchant_listing_api_service.dart
abstract class MerchantListingApiService {
  Future<MerchantListingDTO> upsertMerchantListing(MerchantListingDTO listing);
  Future<MerchantListingDTO?> getMerchantListingById(String listingId);
  Future<List<MerchantListingDTO>> getMerchantListingsByIds(
    List<String> listingIds,
  );

  Future<void> deleteMerchantListing(String listingId);
  Future<List<MerchantListingDTO>> getAllMerchantListings();
  Future<PaginatedResult<MerchantListingDTO>> getMerchantListingsPaginated(
    int page,
    int pageSize,
  );
  Future<PaginatedResult<MerchantListingDTO>>
  getMerchantListingsByTypePaginated(ListingType type, int page, int pageSize);
  Future<List<MerchantListingDTO>> getMerchantListingsByOrganization(
    String organizationId,
  );
  Future<List<MerchantListingDTO>> getMerchantListingsByType(ListingType type);

  Future<PaginatedResult<MerchantListingDTO>>
  getMerchantListingsByOrganizationPaginated(
    String organizationId,
    int page,
    int pageSize,
  );
  Future<List<MerchantListingDTO>> getActiveMerchantListings();
  Future<List<MerchantListingDTO>> getPublishedMerchantListings();
  Future<List<MerchantListingDTO>> searchMerchantListings(String query);
  Future<List<MerchantListingDTO>> getMerchantListingsByBookingType(
    BookingType bookingType,
  );
  Future<List<MerchantListingDTO>> getMerchantListingsByTeamMember(
    String teamId,
  );
  Future<MerchantListingDTO> setMerchantListingActiveStatus(
    String listingId,
    bool isActive,
  );
  Future<MerchantListingDTO> updateMerchantListingStatus(
    String listingId,
    PublishStatus status,
  );
}

// lib/services/api/member_api_service.dart
abstract class MemberApiService {
  Future<MemberDTO> createMember(MemberDTO member);
  Future<MemberDTO?> getMemberByUserId(String userId);

  Future<void> updateMember(MemberDTO updatedMember);
  Future<List<MemberDTO>> getMembersByTeamId(String teamId);
  Future<List<MemberDTO>> getMembersWithMultipleTeams();
  Future<MemberDTO> removeTeamFromMember(String userId, String teamId);
  Future<MemberDTO> addInvitationToMember(String userId, String invitationId);
  Future<MemberDTO> removeInvitationFromMember(
    String userId,
    String invitationId,
  );
  Future<void> deleteMember(String userId);
  Future<PaginatedResult<MemberDTO>> getMembersPaginated(
    int page,
    int pageSize, {
    String? teamId,
  });
  Future<bool> isUserMemberOfTeam(String userId, String teamId);
}

abstract class CustomerApiService {
  Future<CustomerDTO> createCustomer(CustomerDTO customer);
  Future<CustomerDTO?> getCustomerById(String customerId);
  Future<CustomerDTO?> getCustomerByUserId(String userId);
  Future<void> deleteCustomer(String customerId);
  Future<List<CustomerDTO>> getAllCustomers();
  Future<PaginatedResult<CustomerDTO>> getCustomersPaginated(
    int page,
    int pageSize,
  );
  Future<CustomerDTO> updateCustomer(CustomerDTO customer);
  Future<CustomerDTO> addSavedMerchant(String customerId, String merchantId);

  Future<CustomerDTO> removeSavedMerchant(String customerId, String merchantId);
  Future<List<CustomerDTO>> getCustomersBySavedMerchant(String merchantId);
}

// lib/services/api/invitation_api_service.dart

// lib/services/api/organisation_api_service.dart
abstract class OrganisationApiService {
  Future<OrganisationDTO?> getOrganisationById(String oganisationid);
  Future<void> deleteOrganisation(String listingId);
  Future<List<OrganisationDTO>> getAllOrganisations();
  Future<PaginatedResult<OrganisationDTO>> getOrganisationsPaginated(
    int page,
    int pageSize,
  );
  Future<List<OrganisationDTO>> getActiveOrganisations();
  Future<List<OrganisationDTO>> getPublishedOrganisations();
  Future<List<OrganisationDTO>> searchOrganisations(String query);
  Future<OrganisationDTO> setOrganisationActiveStatus(
    String listingId,
    bool isActive,
  );
  Future<OrganisationDTO> updateOrganisationStatus(
    String otganision,
    PublishStatus status,
  );
  Future<OrganisationDTO> updateOrganisation(
    String listingId,
    OrganisationDTO updatedData,
  );
  Future<List<OrganisationDTO>> getOrganisations();
  Future<OrganisationDTO> createOrganisation(OrganisationDTO organisation);
}

// lib/services/api/room_api_service.dart
abstract class RoomApiService {
  Future<RoomDTO> createRoom(RoomDTO room);
  Future<RoomDTO> updateRoom(RoomDTO room);
  Future<RoomDTO?> getRoomById(String roomId);
  Future<void> deleteRoom(String roomId);
  Future<List<RoomDTO>> getRoomsByHotelId(String hotelId);
  Future<PaginatedResult<RoomDTO>> getRoomsPaginated(
    int page,
    int pageSize, {
    String? hotelId,
    bool? onlyAvailable,
  });
  Future<List<RoomDTO>> getAvailableRooms(
    String hotelId,
    DateTimeRange dateRange,
  );
  Future<bool> isRoomAvailable(String roomId, DateTimeRange dateRange);
  Future<RoomDTO> bookRoom(
    String roomId,
    DateTimeRange dateRange,
    String userId,
  );
  Future<RoomDTO> cancelBooking(String roomId, DateTimeRange dateRange);
  Future<RoomDTO> updateRoomStatus(String roomId, PublishStatus status);
  Future<List<RoomDTO>> searchRooms({
    String? hotelId,
    int? minGuests,
    double? minPrice,
    double? maxPrice,
    List<String>? features,
    DateTimeRange? dateRange,
  });
  Future<List<RoomDTO>> getRoomsByIds(List<String> ids);
  Future<List<RoomDTO>> getRoomsByMerchantId(String merchantId);
}

// lib/services/api/ticket_api_service.dart
abstract class TicketApiService {
  Future<TicketDTO> createTicket(TicketDTO ticket);
  Future<TicketDTO> updateTicket(TicketDTO ticket);
  Future<TicketDTO?> getTicketById(String ticketId);
  Future<void> deleteTicket(String ticketId);
  Future<List<TicketDTO>> getTicketsByEventId(String eventId);
  Future<PaginatedResult<TicketDTO>> getTicketsPaginated(
    int page,
    int pageSize, {
    String? eventId,
    bool? onlyAvailable,
  });
  Future<List<TicketDTO>> getAvailableTickets(String eventId);
  Future<TicketDTO> purchaseTicket(
    String ticketId,
    String userId,
    int quantity,
  );
  Future<TicketDTO> refundTicket(String ticketId, String userId, int quantity);
  Future<TicketDTO> updateTicketInventory(String ticketId, int quantitySold);
  Future<TicketDTO> updateTicketSaleStatus(String ticketId, bool isOnSale);
  Future<TicketDTO> updateTicketStatus(String ticketId, PublishStatus status);
  Future<bool> validateTicket(String ticketId, String purchaseId);
  Future<List<TicketDTO>> searchTickets({
    String? eventId,
    String? query,
    double? minPrice,
    double? maxPrice,
    DateTime? salesStartAfter,
    DateTime? salesEndBefore,
  });
  Future<List<TicketDTO>> getTicketsByIds(List<String> ids);
  Future<List<TicketDTO>> getTicketsByEventIds(List<String> eventIds);
  Future<List<TicketDTO>> getTicketsByMerchantId(String merchantId);
}

abstract class ServiceItemApiService {
  Future<ServiceItemDTO> createService(ServiceItemDTO service);
  Future<ServiceItemDTO> updateService(ServiceItemDTO service);
  Future<ServiceItemDTO?> getServiceById(String serviceId);
  Future<void> deleteService(String serviceId);
  Future<List<ServiceItemDTO>> getServicesByHotelId(String hotelId);
  Future<PaginatedResult<ServiceItemDTO>> getServicesPaginated(
    int page,
    int pageSize, {
    String? hotelId,
    bool? onlyAvailable,
  });
  Future<List<ServiceItemDTO>> searchServices({
    String? hotelId,
    String? query,
    double? minPrice,
    double? maxPrice,
    List<String>? features,
  });
  Future<List<ServiceItemDTO>> getServicesByIds(List<String> ids);
  Future<List<ServiceItemDTO>> getServicesByMerchantId(String merchantId);
}

abstract class ReceiptApiService {
  // Create
  Future<Receipt> createReceipt(Receipt receipt);
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
    String merchantId,
    String organisationId,
  });

  // Read - by different IDs
  Future<Receipt?> getReceiptById(String receiptId);
  Future<List<Receipt>> getReceiptsByOrderId(String orderId);
  Future<List<Receipt>> getReceiptsByUserId(String userId);
  Future<List<Receipt>> getReceiptsByMerchantId(String merchantId);
  Future<List<Receipt>> getReceiptsByOrganisationId(String organisationId);

  // Read - by status
  Future<List<Receipt>> getReceiptsByStatus(ReceiptStatus status);
  Future<List<Receipt>> getReceiptsByStatuses(List<ReceiptStatus> statuses);

  // Read - paginated
  Future<PaginatedResult<Receipt>> getReceiptsPaginated({
    required int page,
    required int pageSize,
    String? userId,
    String? merchantId,
    String? organisationId,
    ReceiptStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  });

  // Read - by date range
  Future<List<Receipt>> getReceiptsByDateRange(DateTime start, DateTime end);
  Future<List<Receipt>> getReceiptsByDateRangeForUser(
    String userId,
    DateTime start,
    DateTime end,
  );

  // Update
  Future<Receipt> updateReceipt(Receipt receipt);
  Future<Receipt> updateReceiptStatus(
    String receiptId,
    ReceiptStatus newStatus,
  );
  Future<Receipt> updateReceiptPaymentInfo(
    String receiptId, {
    String? paymentMethod,
    String? transactionId,
    DateTime? paidAt,
  });

  // Delete
  Future<void> deleteReceipt(String receiptId);
  Future<void> deleteReceiptsByUserId(String userId);
  Future<void> deleteReceiptsByOrderId(String orderId);

  // Analytics/Statistics
  Future<double> getTotalRevenue({
    String? userId,
    String? merchantId,
    String? organisationId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Map<ReceiptStatus, int>> getReceiptStatusCounts({
    String? userId,
    String? merchantId,
    String? organisationId,
  });

  Future<double> getAverageOrderValue({
    String? userId,
    String? merchantId,
    String? organisationId,
  });

  // Search
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
  });

  // Batch operations
  Future<void> batchUpdateReceiptStatus(
    List<String> receiptIds,
    ReceiptStatus newStatus,
  );
  Future<void> batchDeleteReceipts(List<String> receiptIds);
}

// lib/services/api/inquiry_api_service.dart

abstract class InquiryApiService {
  // Create
  Future<Inquiry> createInquiry(Inquiry inquiry);

  // Read
  Future<Inquiry?> getInquiryById(String inquiryId);
  Future<List<Inquiry>> getInquiriesByUserId(String userId);
  Future<List<Inquiry>> getInquiriesByMerchantId(String merchantId);
  Future<List<Inquiry>> getInquiriesByOrganisationId(String organisationId);
  Future<List<Inquiry>> getInquiriesByStatus(InquiryStatus status);

  // Update
  Future<Inquiry> updateInquiry(Inquiry inquiry);
  Future<Inquiry> respondToInquiry(String inquiryId, String response);
  Future<Inquiry> updateInquiryStatus(String inquiryId, InquiryStatus status);

  // Delete
  Future<void> deleteInquiry(String inquiryId);

  // Paginated
  Future<PaginatedResult<Inquiry>> getInquiriesPaginated({
    required int page,
    required int pageSize,
    String? userId,
    String? merchantId,
    String? organisationId,
    InquiryStatus? status,
  });
}

abstract class ChatApiService {
  // Chat Group Operations
  Future<ChatGroup> createChatGroup(CreateChatRequest request);
  Future<ChatGroup?> getChatGroupById(String chatGroupId);
  Future<void> deleteChatGroup(String chatGroupId);
  Future<ChatGroup> updateChatGroup(ChatGroup chatGroup);

  // Get chat groups for customer (shows team names only)
  Future<List<ChatGroup>> getChatGroupsForCustomer(String customerId);
  Future<PaginatedResult<ChatGroup>> getChatGroupsForCustomerPaginated(
    String customerId,
    int page,
    int pageSize,
  );

  // Get chat groups for member (shows customer names)
  Future<List<ChatGroup>> getChatGroupsForMember(String memberId);
  Future<PaginatedResult<ChatGroup>> getChatGroupsForMemberPaginated(
    String memberId,
    int page,
    int pageSize,
  );

  // Get chat group by team and customer (for checking if chat exists)
  Future<ChatGroup?> getChatGroupByTeamAndCustomer(
    String teamId,
    String customerId,
  );

  // Message Operations
  Future<ChatMessage> sendMessage({
    required String chatGroupId,
    required String senderId,
    required String senderName,
    required String senderImageUrl,
    required MessageSenderType senderType,
    required String content,
    MessageType messageType = MessageType.text,
    Map<String, dynamic>? metadata,
  });

  Future<List<ChatMessage>> getMessages(
    String chatGroupId, {
    int limit = 50,
    DateTime? before,
  });

  Future<PaginatedResult<ChatMessage>> getMessagesPaginated(
    String chatGroupId,
    int page,
    int pageSize,
  );

  Future<void> markMessagesAsRead(String chatGroupId, String readerId);

  Future<void> deleteMessage(String messageId);

  // Real-time subscriptions
  Stream<ChatMessage> subscribeToMessages(String chatGroupId);
  Stream<ChatGroup> subscribeToChatGroup(String chatGroupId);

  // Analytics
  Future<int> getUnreadCountForCustomer(String customerId);
  Future<int> getUnreadCountForMember(String memberId);
  Future<Map<String, int>> getUnreadCountsByChatGroup(String memberId);
}

abstract class MediaFeedApiService {
  /// Get media feed items with pagination
  Future<PaginatedResult<MediaFeedItem>> getMediaFeed({
    int page = 1,
    int pageSize = 20,
    String? organizationId,
    String? listingId,
    MediaType? mediaType,
    String? searchQuery,
  });

  /// Get media items for a specific listing
  Future<List<MediaFeedItem>> getMediaByListingId(String listingId);

  /// Get media items for a specific organization
  Future<List<MediaFeedItem>> getMediaByOrganizationId(String organizationId);

  /// Get trending media items
  Future<List<MediaFeedItem>> getTrendingMedia({int limit = 10});

  /// Get recommended media items for user
  Future<List<MediaFeedItem>> getRecommendedMedia({int limit = 10});

  /// Like or unlike a media item
  Future<LikeResponse> toggleLike({
    required String mediaId,
    required bool isLiked,
    String? userId,
  });

  /// Get like count for a media item
  Future<int> getLikeCount(String mediaId);

  /// Check if user has liked a media item
  Future<bool> hasUserLikedMedia({
    required String mediaId,
    required String userId,
  });

  /// Follow or unfollow an organization
  Future<FollowResponse> toggleFollow({
    required String organizationId,
    required bool isFollowing,
    String? userId,
  });

  /// Get follow status for an organization
  Future<bool> getFollowStatus({
    required String organizationId,
    required String userId,
  });

  /// Get followers count for an organization
  Future<int> getFollowersCount(String organizationId);

  /// Share media (track shares for analytics)
  Future<void> trackShare({
    required String mediaId,
    required String userId,
    String? platform,
  });

  /// View media (track views for analytics)
  Future<void> trackView({
    required String mediaId,
    required String userId,
    Duration? viewDuration,
  });

  /// Get media statistics
  Future<MediaStats> getMediaStats(String mediaId);

  /// Report inappropriate media
  Future<void> reportMedia({
    required String mediaId,
    required String reason,
    String? description,
  });

  /// Save media to user's collection
  Future<void> saveMedia({
    required String mediaId,
    required String userId,
    String? collectionName,
  });

  /// Remove media from user's collection
  Future<void> unsaveMedia({required String mediaId, required String userId});

  /// Get saved media for user
  Future<List<MediaFeedItem>> getSavedMedia({
    required String userId,
    int limit = 20,
  });

  /// Get comments for a media item
  Future<PaginatedResult<MediaComment>> getComments({
    required String mediaId,
    int page = 1,
    int pageSize = 20,
  });

  /// Add a comment to a media item
  Future<MediaComment> addComment({
    required String mediaId,
    required String userId,
    required String userName,
    required String comment,
    String? userAvatarUrl,
  });

  /// Delete a comment
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  });

  /// Like a comment
  Future<void> likeComment({required String commentId, required String userId});
}

abstract class WalletApiService {
  // Wallet endpoints
  Future<WalletModel> getWalletByUserId(String userId);
  Future<List<TransactionModel>> getRecentTransactions(
    String userId, {
    int limit = 10,
  });
  Future<WalletModel> topUpWallet(
    double amount,
    String paymentMethodId,
    String userId,
  );
  Future<WalletModel> withdrawFromWallet(
    double amount,
    String paymentMethodId,
    String userId,
  );

  // Payment method endpoints
  Future<List<BaseMethod>> getPaymentMethodsByUserId(String userId);

  Future<void> addCreditCard(CreditCardModel card);
  Future<void> addBankAccount(BankAccountModel account);
  Future<void> addStripeAccount(StripeAccountModel account);
  Future<void> addPayPalAccount(PayPalAccountModel account);
  Future<void> setDefaultPaymentMethod(String id);
  Future<void> deletePaymentMethod(String id);
}

// lib/services/api/payment_method_api_service.dart
abstract class PaymentMethodApiService {
  Future<void> addCreditCard(CreditCardModel card);
  Future<void> addBankAccount(BankAccountModel account);
  Future<void> addStripeAccount(StripeAccountModel account);
  Future<void> addPayPalAccount(PayPalAccountModel account);
  Future<void> setDefaultPaymentMethod(String id);
  Future<void> deletePaymentMethod(String id);
}
