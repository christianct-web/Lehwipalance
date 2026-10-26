import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_listing_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/organisation_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/base/mock_api_service.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/contact_info.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/social_links.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';

import 'package:lehwipalancecustomerv1/core/utils/logutil.dart';
import 'package:lehwipalancecustomerv1/core/models/user_models.dart';
import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/home/palance_widget.dart';
import 'package:lehwipalancecustomerv1/modules/login_and_signup/customer_loginsheet.dart';

// lib/core/providers/customer_provider.dart

class CustomerProvider extends ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider _authProvider;
  final OrganizationProvider _organizationProvider;
  final MerchantListingProvider _listingProvider;

  CustomerDTO? _customer;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _error;
  // Track favorites by category
  Map<String, Set<String>> _favorites = {
    'event': <String>{},
    'place': <String>{},
    'hotel': <String>{},
    'service': <String>{},
  };

  CustomerProvider({
    required AuthProvider authProvider,
    required MerchantListingProvider listingProvider,
    required OrganizationProvider organizationProvider,
    ApiService? apiService,
  }) : _authProvider = authProvider,
       _listingProvider = listingProvider,
       _organizationProvider = organizationProvider,
       _apiService = apiService ?? MockApiService() {
    // Listen to auth changes
    _authProvider.addListener(_onAuthChanged);
    _listingProvider.addListener(_onListingsChanged);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    _listingProvider.removeListener(_onListingsChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!_authProvider.isAuthenticated) {
      // Reset state when logged out
      reset();
    } else if (!_isInitialized) {
      // Load customer when authenticated but not initialized
      loadCustomer();
    }
  }

  Future<void> loadCustomerData() async {
    if (_isInitialized && _customer != null) return;
    await loadCustomer(force: true);
  }

  void _onListingsChanged() {
    // Refresh favorites when listings change
    if (_isInitialized && _customer != null) {
      _reorganizeFavoritesByType();
    }
  }

  CustomerDTO? get customer => _customer;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _authProvider.isAuthenticated;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  // Track followed organizations
  Set<String> get followedOrganizations =>
      Set.from(_customer?.followingOrganisationsIds ?? []);

  // ================= INIT =================

  // Sign up as Customer
  Future<bool> signUp({
    required String name,
    required String email,

    required String password,
    String? website,
    String? imageUrl,
    String? bio,
    String? gender,
    String? phone,
    String? street,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? language = 'en',
    String? currency = 'USD',
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Check if user already exists
      final existingUser = await _apiService.getUserByEmail(email);
      if (existingUser != null) {
        _setError('User with this email already exists');
        return false;
      }

      final userId = _generateUserId();
      final now = DateTime.now();

      // Create Customer
      final newUser = CustomerDTO(
        id: userId,
        createdAt: now,
        updatedAt: now,
        fcmToken: null,
        name: name,
        email: email,
        imageUrl: imageUrl ?? '',
        bio: bio,
        gender: gender,
        contactInfo: ContactInfo(
          socialLinks: const SocialLinks(),
          email: email,
          phone: phone,
          website: website ?? '',
          qrCodeUrl: null,
        ),
        address: AddressModel(
          street: street ?? '',
          city: city ?? '',
          state: state ?? '',
          country: country ?? '',
          postalCode: postalCode ?? '',
          title: 'Home',
          isDefault: true,
        ),
        language: language ?? 'en',
        currency: currency ?? 'USD',
        walletId: ' ',
        isActive: true,
        isBanned: false,
        banReason: null,
        notificationsEnabled: true,
        filterPreferencesID: 'filter_$userId',
        savedMerchantIds: [],
        followingOrganisationsIds: [],
        bookingIds: [],
        likedMediaIds: [],
      );

      final createdUser = await _apiService.upsertUser(newUser);
      _customer = createdUser as CustomerDTO;

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCustomer({bool force = false}) async {
    // Prevent concurrent loads
    if (_isLoading || _isInitializing) return;

    // Skip if already initialized and not forced
    if (_isInitialized && !force) return;

    _isLoading = true;
    _isInitializing = true;
    notifyListeners();

    try {
      final user = _authProvider.state.user;
      if (user == null || user is! CustomerDTO) {
        _customer = null;
        _favorites = {
          'event': <String>{},
          'place': <String>{},
          'hotel': <String>{},
          'service': <String>{},
        };
        _isInitialized = true;
        return;
      }

      _customer = await _apiService.getCustomerById(user.id);

      if (_customer != null) {
        // Initialize favorites from savedMerchantIds
        await _reorganizeFavoritesByType();

        // Update organization provider with followed organizations
        _organizationProvider.setFollowingOrganizations(
          _customer!.followingOrganisationsIds,
        );
      }

      _isInitialized = true;
    } catch (e) {
      AppLogger.error('Error loading customer: $e');
      _customer = null;
      _isInitialized = true;
    } finally {
      _isLoading = false;
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _reorganizeFavoritesByType() async {
    if (_customer == null) return;

    final _ = _listingProvider.allListings;
    final tempFavorites = {
      'event': <String>{},
      'place': <String>{},
      'hotel': <String>{},
      'service': <String>{},
    };

    // Only process listing IDs that exist in the listings provider
    for (final savedId in _customer!.savedMerchantIds) {
      // Skip member IDs and organization IDs
      if (savedId.startsWith('member_') || savedId.startsWith('org_')) {
        continue;
      }

      try {
        // final listing = allListings.firstWhere((l) => l.id == savedId);
        // final category = _getCategoryFromListing(listing);
        // tempFavorites[category]?.add(savedId);
      } catch (e) {
        // Listing not found - skip it silently (could be deleted)
        // Don't log to avoid spam
      }
    }

    _favorites = tempFavorites;
  }

  // ==================== FAVORITE ITEMS GETTER ====================

  List<PalanceItem> get favoriteItems {
    final allListings = _listingProvider.allListings;
    final ids = _favorites.values.expand((e) => e).toSet();

    if (ids.isEmpty) return [];

    final provider = getIt<MerchantListingProvider>();

    return allListings
        .where((listing) => ids.contains(listing.id))
        .map((listing) => mapToPalanceItem(listing, provider))
        .toList();
  }

  Future<List<PalanceItem>> get favoriteItemsAsync async {
    final allListings = _listingProvider.allListings;
    final ids = _favorites.values.expand((e) => e).toSet();

    if (ids.isEmpty) return [];

    final provider = getIt<MerchantListingProvider>();
    final favoriteListings = allListings
        .where((listing) => ids.contains(listing.id))
        .toList();

    // Convert to PalanceItems asynchronously (loads locations if needed)
    final items = <PalanceItem>[];
    for (final listing in favoriteListings) {
      final item = await mapToPalanceItemAsync(listing, provider);
      items.add(item);
    }
    return items;
  }

  Future<List<PalanceItem>> get favoriteItemsWithPreload async {
    final allListings = _listingProvider.allListings;
    final ids = _favorites.values.expand((e) => e).toSet();

    if (ids.isEmpty) return [];

    final provider = getIt<MerchantListingProvider>();
    final favoriteListings = allListings
        .where((listing) => ids.contains(listing.id))
        .toList();

    // Preload all locations first
    final locationIds = favoriteListings
        .where((l) => l.locationid.isNotEmpty)
        .map((l) => l.locationid)
        .toSet()
        .toList();

    if (locationIds.isNotEmpty) {
      await provider.preloadLocations(locationIds);
    }

    // Now convert synchronously since locations are cached
    return favoriteListings
        .map((listing) => mapToPalanceItem(listing, provider))
        .toList();
  }

  // ==================== FAVORITES BY TYPE ====================

  List<PalanceItem> getFavoriteItemsByType(ListingType type) {
    final allListings = _listingProvider.allListings;
    final typeName = type.name;
    final ids = _favorites[typeName] ?? {};

    if (ids.isEmpty) return [];

    final provider = getIt<MerchantListingProvider>();

    return allListings
        .where((listing) => ids.contains(listing.id))
        .map((listing) => mapToPalanceItem(listing, provider))
        .toList();
  }

  Future<List<PalanceItem>> getFavoriteItemsByTypeAsync(
    ListingType type,
  ) async {
    final allListings = _listingProvider.allListings;
    final typeName = type.name;
    final ids = _favorites[typeName] ?? {};

    if (ids.isEmpty) return [];

    final provider = getIt<MerchantListingProvider>();
    final favoriteListings = allListings
        .where((listing) => ids.contains(listing.id))
        .toList();

    // Preload locations
    final locationIds = favoriteListings
        .where((l) => l.locationid.isNotEmpty)
        .map((l) => l.locationid)
        .toSet()
        .toList();

    if (locationIds.isNotEmpty) {
      await provider.preloadLocations(locationIds);
    }

    return favoriteListings
        .map((listing) => mapToPalanceItem(listing, provider))
        .toList();
  }

  // ==================== FAVORITE OPERATIONS ====================

  bool isFollowingOrganization(String organizationId) {
    return _customer?.followingOrganisationsIds.contains(organizationId) ??
        false;
  }

  bool isFavorite(ListingType category, String id) {
    return _favorites[category.name]?.contains(id) ?? false;
  }

  Future<bool> requireAuth(BuildContext context, {String? redirectPath}) async {
    if (isAuthenticated) return true;
    //TODO checkif to use go router or showModalBottomSheet
    if (context.mounted) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => LoginBottomSheet(redirectPath: redirectPath),
      );
    }
    return false;
  }

  Future<bool> toggleFollowOrganization(String organizationId) async {
    if (_customer == null) return false;

    final wasFollowing = _customer!.followingOrganisationsIds.contains(
      organizationId,
    );
    final newFollowingIds = List<String>.from(
      _customer!.followingOrganisationsIds,
    );

    if (wasFollowing) {
      newFollowingIds.remove(organizationId);
    } else {
      newFollowingIds.add(organizationId);
    }

    // Save old state for rollback
    final oldCustomer = _customer;
    final oldOrgProviderState = _organizationProvider.followingOrganizations
        .toSet();

    // Optimistic update
    _customer = _customer!.copyWith(followingOrganisationsIds: newFollowingIds);
    _organizationProvider.setFollowingOrganizations(newFollowingIds);
    notifyListeners();

    try {
      await _apiService.updateCustomer(_customer!);
      return true;
    } catch (e) {
      // Rollback on error
      _customer = oldCustomer;
      _organizationProvider.setFollowingOrganizations(
        oldOrgProviderState.toList(),
      );
      notifyListeners();
      AppLogger.error('Error toggling follow: $e');
      return false;
    }
  }

  Future<bool> toggleFavorite(ListingType category, String itemId) async {
    if (_customer == null) return false;

    // Make sure the favorites set exists for this category
    if (!_favorites.containsKey(category.name)) {
      _favorites[category.name] = <String>{};
    }

    final favoritesSet = _favorites[category.name]!;
    final isFavorite = favoritesSet.contains(itemId);

    // Create new list for savedMerchantIds
    final newSavedIds = List<String>.from(_customer!.savedMerchantIds);

    if (isFavorite) {
      // Remove from favorites
      favoritesSet.remove(itemId);
      newSavedIds.remove(itemId);
    } else {
      // Add to favorites
      favoritesSet.add(itemId);
      if (!newSavedIds.contains(itemId)) {
        newSavedIds.add(itemId);
      }
    }

    // Save old state for rollback
    final oldFavorites = Map<String, Set<String>>.from(
      _favorites.map((key, value) => MapEntry(key, Set.from(value))),
    );
    final oldCustomer = _customer;

    // Optimistic update
    _favorites[category.name] = favoritesSet;
    _customer = _customer!.copyWith(savedMerchantIds: newSavedIds);
    notifyListeners();

    try {
      await _apiService.updateCustomer(_customer!);
      return true;
    } catch (e) {
      // Rollback on error
      _favorites = oldFavorites;
      _customer = oldCustomer;
      notifyListeners();
      AppLogger.error('Error toggling favorite: $e');
      return false;
    }
  }

  Future<bool> addFavorite(ListingType category, String itemId) async {
    if (_customer == null) return false;

    if (isFavorite(category, itemId)) {
      return true; // Already favorite
    }

    return toggleFavorite(category, itemId);
  }

  Future<bool> removeFavorite(ListingType category, String itemId) async {
    if (_customer == null) return false;

    if (!isFavorite(category, itemId)) {
      return true; // Not a favorite
    }

    return toggleFavorite(category, itemId);
  }

  Future<void> clearFavorites() async {
    if (_customer == null) return;

    // Clear all favorites
    _favorites.updateAll((key, _) => <String>{});
    _customer = _customer!.copyWith(savedMerchantIds: []);

    try {
      await _apiService.updateCustomer(_customer!);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error clearing favorites: $e');
      // Reload to restore state
      await loadCustomer(force: true);
    }
  }

  Future<void> removeFavoriteById(String itemId) async {
    if (_customer == null) return;

    // Find which category contains this item
    String? category;
    for (final entry in _favorites.entries) {
      if (entry.value.contains(itemId)) {
        category = entry.key;
        break;
      }
    }

    if (category != null) {
      await removeFavorite(
        ListingType.values.firstWhere((e) => e.name == category),
        itemId,
      );
    }
  }

  void refreshFavorites() {
    if (_customer != null && !_isLoading) {
      // Only reorganize if we're initialized and not loading
      _reorganizeFavoritesByType().then((_) {
        if (!_isLoading) {
          notifyListeners();
        }
      });
    }
  }

  int getFavoriteCount(ListingType type) {
    return _favorites[type.name]?.length ?? 0;
  }

  // Get total favorite count
  int get totalFavoriteCount {
    return _favorites.values.fold(0, (sum, set) => sum + set.length);
  }

  // Reset the provider (useful for logout)
  void reset() {
    _customer = null;
    _isInitialized = false;
    _isLoading = false;
    _favorites = {
      'event': <String>{},
      'place': <String>{},
      'hotel': <String>{},
      'service': <String>{},
    };
    notifyListeners();
  }

  // Helper methods
  String _generateUserId() {
    return 'cust_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
