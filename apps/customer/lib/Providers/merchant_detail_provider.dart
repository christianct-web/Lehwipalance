import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:lehwipalancecustomerv1/Providers/customer_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_listing_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/organisation_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/media_model.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';
import 'package:lehwipalancecustomerv1/core/models/organisation_model.dart';
import 'package:lehwipalancecustomerv1/core/models/room_model.dart';
import 'package:lehwipalancecustomerv1/core/models/service_item_model.dart';
import 'package:lehwipalancecustomerv1/core/models/ticket_model.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';
import 'package:lehwipalancecustomerv1/core/router/route_names.dart';
import 'package:lehwipalancecustomerv1/core/utils/logutil.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

// ============================================================
// STATE ENUMS
// ============================================================
// merchant_detail_provider.dart

import 'package:lehwipalancecustomerv1/modules/details/detail_sheet_widgets.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Load states for the detail sheet
enum DetailLoadState { idle, loading, loaded, error }

/// Available tabs in the detail sheet
enum ListingDetailTab { info, media, reviews }

class MerchantDetailProvider extends ChangeNotifier {
  // ==================== DEPENDENCIES ====================

  final ApiService _apiService;
  final AuthProvider _authProvider;
  final CustomerProvider _customerProvider;
  final LocationProvider _locationProvider;
  final OrganizationProvider _organizationProvider;
  final MerchantListingProvider _merchantProvider;
  final InteractionService _interactionService;

  // ==================== STATE ====================

  DetailLoadState _loadState = DetailLoadState.idle;
  MerchantListingDTO? _listing;
  OrganisationDTO? _organization;
  LocationModel? _cachedLocation;
  String? _error;

  // Type-specific data
  List<TicketDTO> _tickets = [];
  List<RoomDTO> _rooms = [];
  List<ServiceItemDTO> _services = [];

  // UI state
  ListingDetailTab _selectedTab = ListingDetailTab.info;
  bool _isBookmarked = false;
  bool _isFollowing = false;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isDisposed = false;

  // Media state
  List<MediaItem> _mediaItems = [];
  int _currentMediaIndex = 0;
  bool _isVideoPlaying = true;
  bool _showVideoControls = true;

  // ==================== CONSTRUCTOR ====================

  MerchantDetailProvider({
    ApiService? apiService,
    AuthProvider? authProvider,
    CustomerProvider? customerProvider,
    LocationProvider? locationProvider,
    OrganizationProvider? organizationProvider,
    MerchantListingProvider? merchantProvider,
    InteractionService? interactionService,
  }) : _apiService = apiService ?? getIt<ApiService>(),
       _authProvider = authProvider ?? getIt<AuthProvider>(),
       _customerProvider = customerProvider ?? getIt<CustomerProvider>(),
       _locationProvider = locationProvider ?? getIt<LocationProvider>(),
       _organizationProvider =
           organizationProvider ?? getIt<OrganizationProvider>(),
       _merchantProvider = merchantProvider ?? getIt<MerchantListingProvider>(),
       _interactionService = interactionService ?? getIt<InteractionService>() {
    _setupListeners();
  }

  // ==================== LISTENERS ====================

  VoidCallback? _customerListener;

  void _setupListeners() {
    _customerListener = () {
      if (_isDisposed || _listing == null) return;
      _syncBookmarkState();
      _syncFollowState();
      _syncLikeState();
    };
    _customerProvider.addListener(_customerListener!);
  }

  void _syncBookmarkState() {
    final listing = _listing;
    if (listing == null) return;

    final newState = _customerProvider.isFavorite(listing.type, listing.id);
    if (_isBookmarked != newState) {
      _isBookmarked = newState;
      _safeNotifyListeners();
    }
  }

  void _syncFollowState() {
    final org = _organization;
    if (org == null) return;

    final newState = _customerProvider.isFollowingOrganization(org.id);
    if (_isFollowing != newState) {
      _isFollowing = newState;
      _safeNotifyListeners();
    }
  }

  void _syncLikeState() {
    final listing = _listing;
    final userId = _customerProvider.customer?.id;
    if (listing == null || userId == null) return;

    final newState = _interactionService.isLiked(listing.id, userId);
    if (_isLiked != newState) {
      _isLiked = newState;
      _safeNotifyListeners();
    }
  }

  // ==================== GETTERS ====================

  // Load state
  DetailLoadState get loadState => _loadState;
  bool get isLoading => _loadState == DetailLoadState.loading;
  bool get isLoaded => _loadState == DetailLoadState.loaded;
  bool get hasError => _loadState == DetailLoadState.error;
  String? get error => _error;

  // Data
  MerchantListingDTO? get listing => _listing;
  OrganisationDTO? get organization => _organization;
  LocationModel? get cachedLocation => _cachedLocation;
  List<TicketDTO> get tickets => List.unmodifiable(_tickets);
  List<RoomDTO> get rooms => List.unmodifiable(_rooms);
  List<ServiceItemDTO> get services => List.unmodifiable(_services);

  // UI State
  ListingDetailTab get selectedTab => _selectedTab;
  bool get isBookmarked => _isBookmarked;
  bool get isFollowing => _isFollowing;
  bool get isLiked => _isLiked;
  int get likeCount => _likeCount;

  // Media state
  List<MediaItem> get mediaItems => List.unmodifiable(_mediaItems);
  int get currentMediaIndex => _currentMediaIndex;
  bool get isVideoPlaying => _isVideoPlaying;
  bool get showVideoControls => _showVideoControls;
  bool get hasMedia => _mediaItems.isNotEmpty;
  int get mediaCount => _mediaItems.length;

  MediaItem? get currentMedia =>
      _mediaItems.isNotEmpty && _currentMediaIndex < _mediaItems.length
      ? _mediaItems[_currentMediaIndex]
      : null;

  bool get isCurrentMediaVideo => currentMedia?.type == MediaType.video;

  // Computed
  double? get averageRating => _listing?.averageRating;
  int? get totalReviews => _listing?.totalReviews;
  bool get hasOrganization => _organization != null;
  bool get hasLocation => _cachedLocation != null;
  bool get canPerformActions => _authProvider.isAuthenticated;

  // Action button helpers
  String get actionButtonText =>
      _listing?.type.actionButtonText ??
      ListingTypeExtension.defaultActionButtonText;

  IconData get actionIcon =>
      _listing?.type.actionIcon ?? ListingTypeExtension.defaultActionIcon;

  // ==================== PUBLIC METHODS ====================

  /// Loads a listing by ID with organization and type-specific data.
  Future<void> loadListing(String listingId) async {
    if (_isDisposed) return;
    if (listingId.isEmpty) {
      _setError('Invalid listing ID');
      return;
    }

    _setLoading();
    _resetData();

    try {
      // Try provider cache first, then API
      MerchantListingDTO? listing = _merchantProvider.getListingById(listingId);
      listing ??= await _apiService.getMerchantListingById(listingId);

      if (listing == null) {
        _setError('Listing not found');
        return;
      }

      if (_isDisposed) return;

      _listing = listing;
      _likeCount = listing.stats.saves;
      _buildMediaItems(listing);
      _syncBookmarkState();
      _loadCachedLocation(listing);
      _syncFollowState();
      _syncLikeState();

      // Load organization and type-specific data in parallel
      await Future.wait([
        _loadOrganization(listing.organizationId),
        _loadTypeSpecificData(listing),
      ]);

      if (_isDisposed) return;

      _loadState = DetailLoadState.loaded;
      _safeNotifyListeners();

      AppLogger.info('[MerchantDetailProvider] Loaded: ${listing.title}');
    } catch (e) {
      AppLogger.error('[MerchantDetailProvider] Failed to load: $e');
      _setError('Failed to load listing: ${e.toString()}');
    }
  }

  /// Refreshes the currently loaded listing.
  Future<void> refresh() async {
    final id = _listing?.id;
    if (id == null) return;
    await loadListing(id);
  }

  /// Sets the selected tab.
  void setSelectedTab(ListingDetailTab tab) {
    if (_isDisposed || _selectedTab == tab) return;
    _selectedTab = tab;
    _safeNotifyListeners();
  }

  /// Sets the current media index.
  void setCurrentMediaIndex(int index) {
    if (_isDisposed || index == _currentMediaIndex) return;
    if (index < 0 || index >= _mediaItems.length) return;

    _currentMediaIndex = index;
    _isVideoPlaying = true;
    _showVideoControls = true;
    _safeNotifyListeners();
  }

  /// Toggles video playback state.
  void toggleVideoPlayback() {
    if (_isDisposed) return;
    _isVideoPlaying = !_isVideoPlaying;
    _safeNotifyListeners();
  }

  /// Toggles video controls visibility.
  void toggleVideoControls() {
    if (_isDisposed) return;
    _showVideoControls = !_showVideoControls;
    _safeNotifyListeners();
  }

  /// Toggles the bookmark state for the current listing.
  Future<void> toggleBookmark() async {
    if (_isDisposed) return;

    final listing = _listing;
    if (listing == null) return;

    if (!_authProvider.isAuthenticated) {
      AppLogger.info('[MerchantDetailProvider] Bookmark requires auth');
      return;
    }

    // Optimistic update
    final previousState = _isBookmarked;
    _isBookmarked = !_isBookmarked;
    _safeNotifyListeners();

    try {
      await _customerProvider.toggleFavorite(listing.type, listing.id);
    } catch (e) {
      _isBookmarked = previousState;
      _safeNotifyListeners();
      AppLogger.error('[MerchantDetailProvider] Bookmark failed: $e');
    }
  }

  /// Toggles the like state for the current listing.
  Future<void> toggleLike() async {
    if (_isDisposed) return;

    final listing = _listing;
    if (listing == null) return;

    if (!_authProvider.isAuthenticated) {
      AppLogger.info('[MerchantDetailProvider] Like requires auth');
      return;
    }

    final userId = _customerProvider.customer?.id;
    if (userId == null) return;

    // Optimistic update
    final previousState = _isLiked;
    final previousCount = _likeCount;

    _isLiked = !_isLiked;
    _likeCount += _isLiked ? 1 : -1;
    _safeNotifyListeners();

    try {
      _interactionService.toggleLike(listing.id, userId, (delta) {
        _likeCount += delta;
        _safeNotifyListeners();
      });
    } catch (e) {
      _isLiked = previousState;
      _likeCount = previousCount;
      _safeNotifyListeners();
      AppLogger.error('[MerchantDetailProvider] Like failed: $e');
    }
  }

  /// Toggles the follow state for the current organization.
  Future<void> toggleFollow() async {
    if (_isDisposed) return;

    final org = _organization;
    if (org == null) return;

    if (!_authProvider.isAuthenticated) {
      AppLogger.info('[MerchantDetailProvider] Follow requires auth');
      return;
    }

    // Optimistic update
    final previousState = _isFollowing;
    _isFollowing = !_isFollowing;
    _safeNotifyListeners();

    try {
      final success = await _customerProvider.toggleFollowOrganization(org.id);
      if (!success) {
        _isFollowing = previousState;
        _safeNotifyListeners();
      }
    } catch (e) {
      _isFollowing = previousState;
      _safeNotifyListeners();
      AppLogger.error('[MerchantDetailProvider] Follow failed: $e');
    }
  }

  /// Handles the primary action button (booking, etc.)
  Future<void> handlePrimaryAction(BuildContext context) async {
    final listing = _listing;
    if (listing == null) return;

    AppLogger.info('[MerchantDetailProvider] Primary action: ${listing.title}');

    // Navigate based on listing type
    context.pushNamed(
      RouteNames.catalog,
      pathParameters: {'listingId': listing.id},
    );
  }

  /// Handles the directions action.
  Future<void> handleDirectionsAction(BuildContext context) async {
    final location = _cachedLocation;
    if (location == null) return;

    final lat = location.latitude;
    final lng = location.longitude;

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  /// Handles the write review action.
  Future<void> handleWriteReview(BuildContext context) async {
    final listing = _listing;
    if (listing == null) return;

    if (!_authProvider.isAuthenticated) {
      AppLogger.info('[MerchantDetailProvider] Review requires auth');
      return;
    }

    AppLogger.info('[MerchantDetailProvider] Write review: ${listing.title}');
  }

  /// Shares the listing.
  Future<void> shareListing(BuildContext context) async {
    final listing = _listing;
    if (listing == null) return;

    final orgName = _organization?.name ?? '';

    await SharePlus.instance.share(
      ShareParams(
        text:
            'Check out ${listing.title} on Lehwi Palance!\n'
            '📍 $orgName\n'
            '🔗 https://lehwi-palance.app/listing/${listing.id}',
        subject: listing.title,
      ),
    );
  }

  /// Makes a phone call.
  Future<void> makePhoneCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  /// Sends an email.
  Future<void> sendEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  /// Opens a website.
  Future<void> openWebsite(String website) async {
    final url = Uri.parse(
      website.startsWith('http') ? website : 'https://$website',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // ==================== PRIVATE METHODS ====================

  void _buildMediaItems(MerchantListingDTO listing) {
    _mediaItems = [];

    // Add video URLs first
    final videoUrls = listing.mediaUrls.videoUrls;
    if (videoUrls != null) {
      for (final url in videoUrls) {
        if (url.trim().isEmpty) continue;
        _mediaItems.add(
          MediaItem(
            url: url,
            type: MediaType.video,
            title: listing.title,
            listingId: listing.id,
          ),
        );
      }
    }

    // Add image URLs
    for (final url in listing.mediaUrls.imageUrls) {
      if (url.trim().isEmpty) continue;
      _mediaItems.add(
        MediaItem(
          url: url,
          type: MediaType.image,
          title: listing.title,
          listingId: listing.id,
        ),
      );
    }

    // Add main image if not already present
    final mainImage = listing.mediaUrls.mainImageUrl;
    if (mainImage.isNotEmpty &&
        !_mediaItems.any((item) => item.url == mainImage)) {
      _mediaItems.add(
        MediaItem(
          url: mainImage,
          type: MediaType.image,
          title: listing.title,
          listingId: listing.id,
        ),
      );
    }
  }

  void _setLoading() {
    _loadState = DetailLoadState.loading;
    _error = null;
    _safeNotifyListeners();
  }

  void _setError(String message) {
    _loadState = DetailLoadState.error;
    _error = message;
    _safeNotifyListeners();
  }

  void _resetData() {
    _listing = null;
    _organization = null;
    _cachedLocation = null;
    _tickets = [];
    _rooms = [];
    _services = [];
    _mediaItems = [];
    _currentMediaIndex = 0;
    _isBookmarked = false;
    _isFollowing = false;
    _isLiked = false;
    _likeCount = 0;
    _error = null;
  }

  void _loadCachedLocation(MerchantListingDTO listing) {
    _cachedLocation = _merchantProvider.getCachedLocation(listing);
    _cachedLocation ??= _locationProvider.getById(listing.locationid);
  }

  Future<void> _loadOrganization(String organizationId) async {
    if (organizationId.isEmpty) return;

    try {
      _organization = await _organizationProvider.getOrganizationById(
        organizationId,
      );
      _organization ??= await _apiService.getOrganisationById(organizationId);

      if (_organization != null) {
        _syncFollowState();
      }
    } catch (e) {
      AppLogger.error('[MerchantDetailProvider] Org load failed: $e');
    }
  }

  Future<void> _loadTypeSpecificData(MerchantListingDTO listing) async {
    if (_isDisposed) return;

    try {
      if (listing.isEvent) {
        await _loadEventData(listing);
      } else if (listing.isAccommodation) {
        await _loadAccommodationData(listing);
      } else if (listing.isPlace) {
        await _loadPlaceData(listing);
      } else if (listing.isService) {
        await _loadServiceData(listing);
      }
    } catch (e) {
      AppLogger.error('[MerchantDetailProvider] Type data failed: $e');
    }
  }

  Future<void> _loadEventData(MerchantListingDTO listing) async {
    if (listing.ticketTypeIds?.isNotEmpty == true) {
      _tickets = await _apiService.getTicketsByIds(listing.ticketTypeIds!);
    } else {
      _tickets = await _apiService.getTicketsByEventId(listing.id);
    }
  }

  Future<void> _loadAccommodationData(MerchantListingDTO listing) async {
    final futures = <Future>[];

    if (listing.roomIds?.isNotEmpty == true) {
      futures.add(
        _apiService.getRoomsByIds(listing.roomIds!).then((rooms) {
          _rooms = rooms;
        }),
      );
    }

    if (listing.accommodationServiceIds?.isNotEmpty == true) {
      futures.add(
        _apiService.getServicesByIds(listing.accommodationServiceIds!).then((
          services,
        ) {
          _services = services;
        }),
      );
    }

    await Future.wait(futures);
  }

  Future<void> _loadPlaceData(MerchantListingDTO listing) async {
    if (listing.placeServiceIds?.isNotEmpty == true) {
      _services = await _apiService.getServicesByIds(listing.placeServiceIds!);
    }
  }

  Future<void> _loadServiceData(MerchantListingDTO listing) async {
    if (listing.serviceTypeIds?.isNotEmpty == true) {
      _services = await _apiService.getServicesByIds(listing.serviceTypeIds!);
    }
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  // ==================== DISPOSAL ====================

  @override
  void dispose() {
    _isDisposed = true;

    if (_customerListener != null) {
      _customerProvider.removeListener(_customerListener!);
      _customerListener = null;
    }

    super.dispose();
  }
}

/// Represents the loading state of the detail provider.

// ============================================================
// MEDIA ITEM MODEL
// ============================================================

// ============================================================
// MERCHANT DETAIL PROVIDER
// ============================================================
