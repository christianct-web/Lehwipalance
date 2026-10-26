// lib/providers/organization_provider.dart
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/base/mock_api_service.dart';
import 'package:lehwipalancecustomerv1/core/models/merchant_listing_model.dart';
import 'package:lehwipalancecustomerv1/core/models/organisation_model.dart';
import 'package:lehwipalancecustomerv1/core/models/user_models.dart';

class OrganizationProvider extends ChangeNotifier {
  final ApiService _apiService;
  List<OrganisationDTO> _allOrganizations = [];
  List<MerchantListingDTO> _listings = [];
  bool _isLoading = false;
  bool _isLoadingListings = false;
  bool _isInitialized = false;
  final Set<String> _followingOrganizations = {};
  String? _listingsError;

  OrganizationProvider({ApiService? apiService})
    : _apiService = apiService ?? MockApiService() {
    _initialize();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingListings => _isLoadingListings;
  bool get isInitialized => _isInitialized;
  List<OrganisationDTO> get allOrganizations => _allOrganizations;
  Set<String> get followingOrganizations => _followingOrganizations;
  List<MerchantListingDTO> get listings => _listings;
  String? get listingsError => _listingsError;

  Future<void> _initialize() async {
    await loadOrganizations();
    _isInitialized = true;
  }

  Future<void> loadOrganizations() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      _allOrganizations = await _apiService.getAllOrganisations();
      debugPrint('Loaded ${_allOrganizations.length} organizations');
    } catch (e) {
      debugPrint('Error loading organizations: $e');
      _allOrganizations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrganisationDTO> createOrganisation(
    OrganisationDTO organisation,
  ) async {
    try {
      final created = await _apiService.createOrganisation(organisation);

      // Add to local list
      _allOrganizations.add(created);

      notifyListeners();
      return created;
    } catch (e) {
      debugPrint('Error creating organization: $e');
      rethrow;
    }
  }

  Future<OrganisationDTO?> getOrganizationForMember(MemberDTO member) async {
    debugPrint('Getting organization for member: ${member.id}');
    debugPrint('Member organisationId: ${member.organisationId}');

    // Ensure organizations are loaded
    if (_allOrganizations.isEmpty) {
      debugPrint('No organizations loaded, loading now...');
      await loadOrganizations();
    }

    // PRIORITY 1: Try to find by organisationId (most reliable)
    if (member.organisationId != null && member.organisationId!.isNotEmpty) {
      try {
        final org = _allOrganizations.firstWhere(
          (org) => org.id == member.organisationId,
        );
        debugPrint(
          'Found organization by organisationId: ${org.name} (${org.id})',
        );
        return org;
      } catch (e) {
        debugPrint(
          'Organization with ID ${member.organisationId} not found: $e',
        );
      }
    }

    // PRIORITY 2: Try to find by userId (member is the owner)
    try {
      final org = _allOrganizations.firstWhere(
        (org) => org.userId == member.id,
      );
      debugPrint('Found organization by userId: ${org.name} (${org.id})');
      return org;
    } catch (e) {
      // Not found by userId
    }

    // PRIORITY 3: Try to find where member is in membersIds
    try {
      final org = _allOrganizations.firstWhere(
        (org) => org.membersIds.contains(member.id),
      );
      debugPrint('Found organization by membersIds: ${org.name} (${org.id})');
      return org;
    } catch (e) {
      // Not found in membersIds
    }

    // PRIORITY 4: Return first organization as fallback
    if (_allOrganizations.isNotEmpty) {
      final fallbackOrg = _allOrganizations.first;
      debugPrint(
        'Using fallback organization: ${fallbackOrg.name} (${fallbackOrg.id})',
      );
      return fallbackOrg;
    }

    debugPrint('No organization found for member');
    return null;
  }

  /// Get organization for the current authenticated user
  Future<OrganisationDTO?> getOrganizationForCurrentUser() async {
    final authProvider = GetIt.I<AuthProvider>();
    final member = authProvider.memberUser;

    if (member == null) {
      debugPrint('No member user found in auth provider');
      return null;
    }

    return getOrganizationForMember(member);
  }

  /// Update an existing organization
  Future<void> updateOrganization(OrganisationDTO updatedOrg) async {
    try {
      // Update via API
      final updated = await _apiService.updateOrganisation(
        updatedOrg.id,
        updatedOrg,
      );

      // Update local list
      final index = _allOrganizations.indexWhere(
        (org) => org.id == updatedOrg.id,
      );
      if (index != -1) {
        _allOrganizations[index] = updated;
      } else {
        _allOrganizations.add(updated);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating organization: $e');
      rethrow;
    }
  }

  /// Get merchant listings for a specific organization
  Future<List<MerchantListingDTO>> getMerchantListingsByOrganization(
    String organizationId,
  ) async {
    try {
      return await _apiService.getMerchantListingsByOrganization(
        organizationId,
      );
    } catch (e) {
      debugPrint('Error getting listings for organization $organizationId: $e');
      return [];
    }
  }

  /// Load merchant listings for a specific organization into the provider state
  Future<void> loadOrganizationListings(String organizationId) async {
    if (_isLoadingListings) return;

    _isLoadingListings = true;
    _listingsError = null;
    notifyListeners();

    try {
      _listings = await _apiService.getMerchantListingsByOrganization(
        organizationId,
      );
      debugPrint(
        'Loaded ${_listings.length} listings for organization $organizationId',
      );
    } catch (e) {
      _listingsError = 'Failed to load listings: $e';
      debugPrint('Error loading listings: $e');
      _listings = [];
    } finally {
      _isLoadingListings = false;
      notifyListeners();
    }
  }

  /// Get merchant listings for multiple organizations
  Future<Map<String, List<MerchantListingDTO>>>
  getMerchantListingsForOrganizations(List<String> organizationIds) async {
    final Map<String, List<MerchantListingDTO>> result = {};

    for (final orgId in organizationIds) {
      try {
        final listings = await _apiService.getMerchantListingsByOrganization(
          orgId,
        );
        result[orgId] = listings;
      } catch (e) {
        debugPrint('Error getting listings for organization $orgId: $e');
        result[orgId] = [];
      }
    }

    return result;
  }

  Future<void> refresh() async {
    await loadOrganizations();
  }

  Future<OrganisationDTO?> getOrganizationById(String id) async {
    try {
      // Try to find in local list first
      final localOrg = _allOrganizations.firstWhere((org) => org.id == id);
      return localOrg;
    } catch (e) {
      // If not found locally, fetch from API
      try {
        return await _apiService.getOrganisationById(id);
      } catch (e) {
        debugPrint('Error fetching organization $id: $e');
        return null;
      }
    }
  }

  bool isFollowing(String organizationId) {
    return _followingOrganizations.contains(organizationId);
  }

  void followOrganization(String organizationId) {
    _followingOrganizations.add(organizationId);
    notifyListeners();
  }

  void unfollowOrganization(String organizationId) {
    _followingOrganizations.remove(organizationId);
    notifyListeners();
  }

  void setFollowingOrganizations(List<String> followingIds) {
    _followingOrganizations.clear();
    _followingOrganizations.addAll(followingIds);
    notifyListeners();
  }

  List<OrganisationDTO> get verifiedOrganizations {
    return _allOrganizations.where((org) => org.isVerified).toList();
  }

  List<OrganisationDTO> get topRatedOrganizations {
    final sorted = List<OrganisationDTO>.from(_allOrganizations)
      ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return sorted.take(5).toList();
  }

  List<OrganisationDTO> searchOrganizations(String query) {
    if (query.isEmpty) return _allOrganizations;
    final lowerQuery = query.toLowerCase();
    return _allOrganizations.where((org) {
      return org.name.toLowerCase().contains(lowerQuery) ||
          (org.description?.toLowerCase().contains(lowerQuery) ?? false) ||
          (org.shortBio?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }
}
