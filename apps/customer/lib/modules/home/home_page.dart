// lib/customer/modules/home/home_page.dart
import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/customer_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_listing_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/organisation_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/models/organisation_model.dart';
import 'package:lehwipalancecustomerv1/core/models/user_models.dart';
import 'package:go_router/go_router.dart';

import 'package:lehwipalancecustomerv1/core/router/route_names.dart';
import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/home/category_tab.dart';
import 'package:lehwipalancecustomerv1/modules/home/new_widgets.dart';
import 'package:lehwipalancecustomerv1/modules/home/palance_widget.dart';
import 'package:lehwipalancecustomerv1/modules/home/widgets.dart';
import 'package:lehwipalancecustomerv1/modules/login_and_signup/customer_loginsheet.dart';
import 'package:lehwipalancecustomerv1/modules/map/widgets/merchant_listing_filter_sheet.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

// lib/customer/modules/home/home_page.dart

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  static const List<HomeTab> _homeTabs = [
    HomeTab.forYou,
    HomeTab.events,
    HomeTab.places,
    HomeTab.hotels,
    HomeTab.services,
    HomeTab.stores,
    HomeTab.vacations,
    HomeTab.favorites,
  ];

  @override
  bool get wantKeepAlive => true;

  // Providers
  late LocationProvider _locationProvider;
  late MerchantListingProvider _merchantProvider;
  late OrganizationProvider _organizationProvider;
  late CustomerProvider _customerProvider;
  late AuthProvider _authProvider;

  // Controllers
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // State
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _listenersAttached = false;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _homeTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged); // <-- dynamic hint listener
    _initProviders();

    _safetyTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && !_isInitialized) {
        debugPrint('⚠️ [HomePage] Force-initializing after timeout');
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!getIt.isRegistered<MerchantListingProvider>() ||
          !getIt.isRegistered<CustomerProvider>()) {
        await setupServiceLocator();
        if (!mounted) return;
        _initProviders();
      }
      _attachListeners();
      await _loadData();
    });
  }

  void _initProviders() {
    _locationProvider = getIt<LocationProvider>();
    _merchantProvider = getIt<MerchantListingProvider>();
    _organizationProvider = getIt<OrganizationProvider>();
    _customerProvider = getIt<CustomerProvider>();
    _authProvider = getIt<AuthProvider>();
  }

  void _attachListeners() {
    if (_listenersAttached) return;
    _merchantProvider.addListener(_onDataChanged);
    _organizationProvider.addListener(_onDataChanged);
    _locationProvider.addListener(_onLocationChanged);
    _customerProvider.addListener(_onDataChanged);
    _listenersAttached = true;
  }

  void _detachListeners() {
    if (!_listenersAttached) return;
    if (getIt.isRegistered<MerchantListingProvider>()) {
      _merchantProvider.removeListener(_onDataChanged);
    }
    if (getIt.isRegistered<OrganizationProvider>()) {
      _organizationProvider.removeListener(_onDataChanged);
    }
    if (getIt.isRegistered<LocationProvider>()) {
      _locationProvider.removeListener(_onLocationChanged);
    }
    if (getIt.isRegistered<CustomerProvider>()) {
      _customerProvider.removeListener(_onDataChanged);
    }
    _listenersAttached = false;
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _detachListeners();
    _tabController.removeListener(_onTabChanged); // <-- cleanup
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  void _onLocationChanged() {
    if (_isInitialized && mounted) {
      _merchantProvider.forceSyncWithLocation();
      if (mounted) setState(() {});
    }
  }

  /// Called when the active tab changes (tap or swipe).
  /// Only rebuilds when the index actually changes, not on every animation tick.
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (mounted) setState(() {});
  }

  /// Hint text for the bottom search bar, based on the active tab.
  String get _searchHint {
    final index = _tabController.index;
    final tab = (index >= 0 && index < _homeTabs.length)
        ? _homeTabs[index]
        : HomeTab.forYou;

    switch (tab) {
      case HomeTab.forYou:
        return LanguageConstants.searchListings;
      case HomeTab.events:
        return LanguageConstants.searchEvents;
      case HomeTab.places:
        return LanguageConstants.searchPlaces;
      case HomeTab.hotels:
        return LanguageConstants.searchHotels;
      case HomeTab.services:
        return LanguageConstants.searchServices;
      case HomeTab.stores:
        return LanguageConstants.searchStores;
      case HomeTab.vacations:
        return LanguageConstants.searchVacations;
      case HomeTab.favorites:
        return LanguageConstants.searchFavorites;
    }
  }

  Future<void> _loadData() async {
    if (_isInitialized) return;
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await _locationProvider.initialize();
      if (!_merchantProvider.isInitialized && !_merchantProvider.isLoading) {
        await _merchantProvider.initialize();
      }
      if (!_organizationProvider.isInitialized &&
          !_organizationProvider.isLoading) {
        await _organizationProvider.loadOrganizations();
      }
      if (_authProvider.isCustomer == true) {
        await _customerProvider.loadCustomer();
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
      }
    } catch (e, st) {
      debugPrint('❌ [HomePage] loadData error: $e\n$st');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
        _showErrorSnackBar('Failed to load data: $e');
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    try {
      await _merchantProvider.refresh();
      if (_merchantProvider.allListings.isEmpty) {
        await _merchantProvider.forceReload();
      }
      await _organizationProvider.refresh();
      if (_authProvider.isCustomer == true) {
        await _customerProvider.loadCustomer();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to refresh: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    context.showSnackBar(message, isError: true);
  }

  List<PalanceItem> _getItemsForTab(HomeTab tab) {
    final listings = _merchantProvider.filteredListings;
    switch (tab) {
      case HomeTab.forYou:
        return listings.map(mapToPalanceItem).toList();
      case HomeTab.events:
        return listings
            .where((l) => l.type == ListingType.event)
            .map(mapToPalanceItem)
            .toList();
      case HomeTab.places:
        return listings
            .where((l) => l.type == ListingType.place)
            .map(mapToPalanceItem)
            .toList();
      case HomeTab.hotels:
        return listings
            .where((l) => l.type == ListingType.hotel)
            .map(mapToPalanceItem)
            .toList();
      case HomeTab.services:
        return listings
            .where((l) => l.type == ListingType.service)
            .map(mapToPalanceItem)
            .toList();
      case HomeTab.stores:
        return listings
            .where((l) => l.type == ListingType.store)
            .map(mapToPalanceItem)
            .toList();
      case HomeTab.vacations:
        return listings
            .where((l) => l.type == ListingType.vacation)
            .map(mapToPalanceItem)
            .toList();
      case HomeTab.favorites:
        final favorites = _customerProvider.favoriteItems;
        return listings
            .map(mapToPalanceItem)
            .where((item) => favorites.any((fav) => fav.id == item.id))
            .toList();
    }
  }

  void _applySearchFilter() {
    _merchantProvider.setSearchQuery(
      _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  /// The currently active tab.
  HomeTab get _activeTab {
    final index = _tabController.index;
    if (index < 0 || index >= _homeTabs.length) return HomeTab.forYou;
    return _homeTabs[index];
  }

  /// The listing type the active tab is scoped to. `null` for ForYou / Favorites.
  ListingType? get _activeSearchScope {
    switch (_activeTab) {
      case HomeTab.forYou:
      case HomeTab.favorites:
        return null;
      case HomeTab.events:
        return ListingType.event;
      case HomeTab.places:
        return ListingType.place;
      case HomeTab.hotels:
        return ListingType.hotel;
      case HomeTab.services:
        return ListingType.service;
      case HomeTab.stores:
        return ListingType.store;
      case HomeTab.vacations:
        return ListingType.vacation;
    }
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    _merchantProvider.setSearchQuery(null);
    _searchFocusNode.unfocus();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusXL),
        ),
      ),
      builder: (sheetContext) => MerchantListingFilterSheet(
        provider: _merchantProvider,
        activeScope: _activeSearchScope, // <-- pass the current tab's scope
        onReset: () {
          _merchantProvider.resetFilters();
          _locationProvider.clearCountry();
          if (mounted) setState(() {});
        },
        onApply: (_) {
          if (mounted) setState(() {});
          sheetContext.showSnackBar(LanguageConstants.filtersApplied);
        },
      ),
    );
  }

  void _navigateToDetails(PalanceItem item) {
    context.goNamed(
      RouteNames.listingDetails,
      pathParameters: {'listingId': item.itemID},
    );
  }

  void _navigateToTab(HomeTab tab) {
    final index = _homeTabs.indexOf(tab);
    if (index >= 0 && index < _tabController.length) {
      _tabController.animateTo(index);
    }
  }

  void _navigateToOrganizations() {
    // context.pushNamed(RouteNames.customerOrganizations);
  }

  Future<void> _handleFavoriteToggle(PalanceItem item) async {
    if (!_authProvider.isAuthenticated) {
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => const LoginBottomSheet(),
        );
      }
      return;
    }
    try {
      await _customerProvider.toggleFavorite(item.type, item.id);
      if (mounted) setState(() {});
    } catch (e) {
      _showErrorSnackBar('Failed to update favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Column(
        children: [
          _buildMainTabBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomSearchBar(),
    );
  }

  Widget _buildMainTabBar() {
    final colorScheme = context.colors;
    return Material(
      color: colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingS),
        labelPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
        ),
        tabs: _buildTabs(),
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: context.textStyles.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: context.textStyles.labelLarge,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 3, color: colorScheme.primary),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXS),
          ),
        ),
        dividerColor: colorScheme.outlineVariant,
        splashBorderRadius: BorderRadius.circular(AppConstants.radiusL),
        overlayColor: WidgetStatePropertyAll(
          colorScheme.primary.withValues(alpha: 0.08),
        ),
      ),
    );
  }

  List<Tab> _buildTabs() {
    return _homeTabs
        .map(
          (tab) => Tab(
            icon: Icon(_tabIcon(tab), size: AppConstants.iconM),
            text: _tabTitle(tab),
            height: 60,
          ),
        )
        .toList();
  }

  String _tabTitle(HomeTab tab) {
    switch (tab) {
      case HomeTab.forYou:
        return LanguageConstants.forYou;
      case HomeTab.events:
        return LanguageConstants.eventsTab;
      case HomeTab.places:
        return LanguageConstants.placesTab;
      case HomeTab.hotels:
        return LanguageConstants.hotelsTab;
      case HomeTab.services:
        return LanguageConstants.servicesTab;
      case HomeTab.stores:
        return LanguageConstants.storesTab;
      case HomeTab.vacations:
        return LanguageConstants.vacationsTab;
      case HomeTab.favorites:
        return LanguageConstants.favoritesTab;
    }
  }

  IconData _tabIcon(HomeTab tab) {
    switch (tab) {
      case HomeTab.forYou:
        return Icons.auto_awesome_rounded;
      case HomeTab.events:
        return Icons.event_rounded;
      case HomeTab.places:
        return Icons.location_on_rounded;
      case HomeTab.hotels:
        return Icons.hotel_rounded;
      case HomeTab.services:
        return Icons.handyman_rounded;
      case HomeTab.stores:
        return Icons.storefront_rounded;
      case HomeTab.vacations:
        return Icons.beach_access_rounded;
      case HomeTab.favorites:
        return Icons.favorite_rounded;
    }
  }

  Widget _buildBody() {
    if (_isLoading || !_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_merchantProvider.error != null &&
        _merchantProvider.allListings.isEmpty) {
      return _buildErrorState(
        error: _merchantProvider.error!,
        onRetry: _refreshData,
      );
    }

    final items = _getItemsForTab(HomeTab.forYou);
    if (items.isEmpty && _organizationProvider.allOrganizations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: TabBarView(
        controller: _tabController,
        children: [
          ForYouTab(
            items: _getItemsForTab(HomeTab.forYou),
            organizations: _organizationProvider.allOrganizations,
            onItemTap: _navigateToDetails,
            onFavoriteToggle: _handleFavoriteToggle,
            onViewAllOrganizations: _navigateToOrganizations,
            onNavigateToTab: _navigateToTab,
            customerProvider: _customerProvider,
            authProvider: _authProvider,
          ),
          EventListTab(
            items: _getItemsForTab(HomeTab.events),
            type: ListingType.event,
            onItemTap: _navigateToDetails,
            onFavoriteToggle: _handleFavoriteToggle,
            customerProvider: _customerProvider,
            authProvider: _authProvider,
          ),
          CategoryTab(
            items: _getItemsForTab(HomeTab.places),
            type: ListingType.place,
            onItemTap: _navigateToDetails,
            onFavoriteToggle: _handleFavoriteToggle,
            customerProvider: _customerProvider,
            authProvider: _authProvider,
          ),
          CategoryTab(
            items: _getItemsForTab(HomeTab.hotels),
            type: ListingType.hotel,
            onItemTap: _navigateToDetails,
            onFavoriteToggle: _handleFavoriteToggle,
            customerProvider: _customerProvider,
            authProvider: _authProvider,
          ),
          CategoryTab(
            items: _getItemsForTab(HomeTab.services),
            type: ListingType.service,
            onItemTap: _navigateToDetails,
            onFavoriteToggle: _handleFavoriteToggle,
            customerProvider: _customerProvider,
            authProvider: _authProvider,
          ),
          CategoryTab(
            items: _getItemsForTab(HomeTab.stores),
            type: ListingType.store,
            onItemTap: _navigateToDetails,
            onFavoriteToggle: _handleFavoriteToggle,
            customerProvider: _customerProvider,
            authProvider: _authProvider,
          ),
          CategoryTab(
            items: _getItemsForTab(HomeTab.vacations),
            type: ListingType.vacation,
            onItemTap: _navigateToDetails,
            onFavoriteToggle: _handleFavoriteToggle,
            customerProvider: _customerProvider,
            authProvider: _authProvider,
          ),
          FavoritesTab(
            customerProvider: _customerProvider,
            authProvider: _authProvider,
            merchantProvider: _merchantProvider,
            onItemTap: _navigateToDetails,
            onFavoriteToggle: _handleFavoriteToggle,
            onNavigateToOrganizations: _navigateToOrganizations,
            onNavigateToExplore: () => _navigateToTab(HomeTab.forYou),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({
    required String error,
    required VoidCallback onRetry,
  }) {
    final colorScheme = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: AppConstants.iconXL * 2,
              color: colorScheme.error,
            ),
            const SizedBox(height: AppConstants.space6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: context.textStyles.bodyMedium,
            ),
            const SizedBox(height: AppConstants.space6),
            FilledButton(
              onPressed: onRetry,
              child: const Text(LanguageConstants.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasCountryFilter = _locationProvider.filter.country != null;
    final countryName = _locationProvider.filter.country ?? '';
    final colorScheme = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: AppConstants.iconXL * 2,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppConstants.space6),
            Text(
              hasCountryFilter
                  ? 'No listings found in $countryName'
                  : LanguageConstants.noListingsFound,
              textAlign: TextAlign.center,
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: AppConstants.space6),
            if (hasCountryFilter)
              FilledButton(
                onPressed: () {
                  _locationProvider.clearCountry();
                  _merchantProvider.forceSyncWithLocation();
                  if (mounted) setState(() {});
                },
                child: const Text(LanguageConstants.clearLocationFilter),
              )
            else
              FilledButton(
                onPressed: _refreshData,
                child: const Text(LanguageConstants.refresh),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSearchBar() {
    final colorScheme = context.colors;
    final hasFilters = _listenersAttached && _merchantProvider.hasActiveFilters;

    return Material(
      color: colorScheme.surface,
      elevation: AppConstants.elevationL,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.12),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppConstants.paddingM,
          AppConstants.paddingS,
          AppConstants.paddingM,
          AppConstants.paddingS,
        ),
        child: Row(
          children: [
            Expanded(
              child: SearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: _searchHint, // <-- dynamic hint
                leading: const Icon(Icons.search_rounded),
                trailing: _searchQuery.isNotEmpty
                    ? [
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: LanguageConstants.clear,
                          onPressed: _clearSearch,
                        ),
                      ]
                    : null,
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  colorScheme.surfaceContainerHighest,
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: AppConstants.paddingM),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _applySearchFilter();
                },
                onSubmitted: (_) => _searchFocusNode.unfocus(),
              ),
            ),
            const SizedBox(width: AppConstants.space4),
            Badge(
              isLabelVisible: hasFilters,
              child: IconButton.filledTonal(
                onPressed: _showFilterDialog,
                icon: const Icon(Icons.tune_rounded),
                tooltip: LanguageConstants.filter,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FOR YOU TAB
// ============================================================

class ForYouTab extends StatefulWidget {
  final List<PalanceItem> items;
  final List<OrganisationDTO> organizations;
  final void Function(PalanceItem) onItemTap;
  final Future<void> Function(PalanceItem) onFavoriteToggle;
  final VoidCallback onViewAllOrganizations;
  final void Function(HomeTab) onNavigateToTab;
  final CustomerProvider customerProvider;
  final AuthProvider authProvider;

  const ForYouTab({
    super.key,
    required this.items,
    required this.organizations,
    required this.onItemTap,
    required this.onFavoriteToggle,
    required this.onViewAllOrganizations,
    required this.onNavigateToTab,
    required this.customerProvider,
    required this.authProvider,
  });

  @override
  State<ForYouTab> createState() => _ForYouTabState();
}

class _ForYouTabState extends State<ForYouTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = context.colors;

    if (widget.items.isEmpty && widget.organizations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.explore_off_rounded,
                size: AppConstants.iconXL * 2,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppConstants.space6),
              Text(
                LanguageConstants.nothingToDiscover,
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppConstants.space3),
              Text(
                LanguageConstants.tryAdjustingFilters,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final featured = widget.items.take(6).toList();
    final happeningNearYou = widget.items.skip(6).take(6).toList();
    final popularPlaces = widget.items.skip(12).take(6).toList();
    final recommendedServices = widget.items.skip(18).take(6).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingM,
            AppConstants.paddingM,
            AppConstants.paddingM,
            AppConstants.paddingXXL,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (featured.isNotEmpty) ...[
                _buildSectionHeader(LanguageConstants.featured),
                const SizedBox(height: AppConstants.space5),
                _buildFeaturedCarousel(featured),
                const SizedBox(height: AppConstants.space8),
              ],
              if (happeningNearYou.isNotEmpty) ...[
                _buildSectionHeader(
                  LanguageConstants.happeningNearYou,
                  onViewAll: () => widget.onNavigateToTab(HomeTab.events),
                ),
                const SizedBox(height: AppConstants.space5),
                _buildHorizontalCarousel(happeningNearYou),
                const SizedBox(height: AppConstants.space8),
              ],
              if (popularPlaces.isNotEmpty) ...[
                _buildSectionHeader(
                  LanguageConstants.popularPlaces,
                  onViewAll: () => widget.onNavigateToTab(HomeTab.places),
                ),
                const SizedBox(height: AppConstants.space5),
                _buildHorizontalCarousel(popularPlaces),
                const SizedBox(height: AppConstants.space8),
              ],
              if (recommendedServices.isNotEmpty) ...[
                _buildSectionHeader(
                  LanguageConstants.recommendedServices,
                  onViewAll: () => widget.onNavigateToTab(HomeTab.services),
                ),
                const SizedBox(height: AppConstants.space5),
                _buildHorizontalCarousel(recommendedServices),
                const SizedBox(height: AppConstants.space8),
              ],
              if (widget.organizations.isNotEmpty) ...[
                OrganizationSection(
                  title: LanguageConstants.featuredOrganizations,
                  organizations: widget.organizations,
                  onViewAll: widget.onViewAllOrganizations,
                  maxItems: 3,
                ),
                const SizedBox(height: AppConstants.space8),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: context.textStyles.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text(LanguageConstants.viewAll),
          ),
      ],
    );
  }

  Widget _buildFeaturedCarousel(List<PalanceItem> items) {
    return SizedBox(
      height: 260,
      child: CarouselSlider.builder(
        itemCount: items.length,
        options: CarouselOptions(
          height: 260,
          viewportFraction: 0.9,
          enableInfiniteScroll: items.length > 1,
          autoPlay: items.length > 1,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 700),
          enlargeCenterPage: true,
          enlargeFactor: 0.1,
        ),
        itemBuilder: (context, index, _) {
          final item = items[index];
          final isFavorite = widget.customerProvider.isFavorite(
            item.type,
            item.id,
          );
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.space2,
            ),
            child: PalanceLargeCard(
              item: item,
              onTap: () => widget.onItemTap(item),
              isFavorite: isFavorite,
              onFavoriteToggle: () => widget.onFavoriteToggle(item),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalCarousel(List<PalanceItem> items) {
    return SizedBox(
      height: 220,
      child: CarouselSlider.builder(
        itemCount: items.length,
        options: CarouselOptions(
          height: 220,
          viewportFraction: 0.5,
          enableInfiniteScroll: true,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 3),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
          scrollDirection: Axis.horizontal,
        ),
        itemBuilder: (context, index, _) {
          final item = items[index];
          final isFavorite = widget.customerProvider.isFavorite(
            item.type,
            item.id,
          );
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.space2,
            ),
            child: PalanceGridCard(
              item: item,
              onTap: () => widget.onItemTap(item),
              isFavorite: isFavorite,
              onFavoriteToggle: () => widget.onFavoriteToggle(item),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// FAVORITES TAB
// ============================================================

class FavoritesTab extends StatefulWidget {
  final CustomerProvider customerProvider;
  final AuthProvider authProvider;
  final MerchantListingProvider merchantProvider;
  final void Function(PalanceItem) onItemTap;
  final Future<void> Function(PalanceItem) onFavoriteToggle;
  final VoidCallback onNavigateToOrganizations;
  final VoidCallback onNavigateToExplore;

  const FavoritesTab({
    super.key,
    required this.customerProvider,
    required this.authProvider,
    required this.merchantProvider,
    required this.onItemTap,
    required this.onFavoriteToggle,
    required this.onNavigateToOrganizations,
    required this.onNavigateToExplore,
  });

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<PalanceItem> _favorites = [];

  @override
  void initState() {
    super.initState();
    widget.customerProvider.addListener(_updateFavorites);
    widget.merchantProvider.addListener(_updateFavorites);
    _updateFavorites();
  }

  @override
  void dispose() {
    widget.customerProvider.removeListener(_updateFavorites);
    widget.merchantProvider.removeListener(_updateFavorites);
    super.dispose();
  }

  void _updateFavorites() {
    final favoriteItems = widget.customerProvider.favoriteItems;
    final allItems = widget.merchantProvider.filteredListings
        .map(mapToPalanceItem)
        .toList();
    if (!mounted) return;
    setState(() {
      _favorites = allItems
          .where((item) => favoriteItems.any((fav) => fav.id == item.id))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final isAuthenticated = widget.authProvider.isAuthenticated;
    final customer = widget.authProvider.customerUser;
    final hasFollowing =
        widget.customerProvider.followedOrganizations.isNotEmpty;

    if (!isAuthenticated) return _buildUnauthenticatedState();
    if (_favorites.isEmpty && !hasFollowing) return _buildEmptyState(customer);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (customer != null) ...[
                Text(
                  '${LanguageConstants.welcomeBack}, ${customer.name}!',
                  style: context.textStyles.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.space2),
                Text(
                  LanguageConstants.savedFavoritesSubtitle,
                  style: context.textStyles.bodyLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppConstants.space7),
              ],
              if (_favorites.isNotEmpty) ...[
                _buildSectionHeader(LanguageConstants.yourFavorites),
                const SizedBox(height: AppConstants.space5),
                ..._favorites.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppConstants.space5),
                    child: _buildFavoriteCard(item),
                  ),
                ),
                const SizedBox(height: AppConstants.space7),
              ],
              if (hasFollowing) ...[
                _buildSectionHeader(
                  LanguageConstants.organizationsYouFollow,
                  onViewAll: widget.onNavigateToOrganizations,
                ),
                const SizedBox(height: AppConstants.space5),
                OrganizationSection(
                  title: '',
                  organizations: const [],
                  onViewAll: widget.onNavigateToOrganizations,
                  maxItems: 3,
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: context.textStyles.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: const Text(LanguageConstants.viewAll),
          ),
      ],
    );
  }

  Widget _buildFavoriteCard(PalanceItem item) {
    final isFavorite = widget.customerProvider.isFavorite(item.type, item.id);

    switch (item.type) {
      case ListingType.event:
        return PalanceEventListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
      case ListingType.place:
        return PalancePlaceListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
      case ListingType.hotel:
        return PalanceHotelListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
      case ListingType.service:
      case ListingType.store:
      case ListingType.vacation:
        return PalanceListCard(
          item: item,
          onTap: () => widget.onItemTap(item),
          isFavorite: isFavorite,
          onFavoriteToggle: () => widget.onFavoriteToggle(item),
        );
    }
  }

  Widget _buildUnauthenticatedState() {
    final colorScheme = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppConstants.space8),
            Text(
              LanguageConstants.signInToSeeFavorites,
              style: context.textStyles.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space3),
            Text(
              LanguageConstants.signInToSeeFavoritesDesc,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space8),
            FilledButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const LoginBottomSheet(),
                );
              },
              icon: const Icon(Icons.login_rounded),
              label: const Text(LanguageConstants.signIn),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(CustomerDTO? customer) {
    final colorScheme = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingXXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppConstants.space8),
            Text(
              LanguageConstants.noFavoritesYet,
              style: context.textStyles.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space3),
            Text(
              LanguageConstants.noFavoritesYetDesc,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space8),
            FilledButton.icon(
              onPressed: widget.onNavigateToExplore,
              icon: const Icon(Icons.explore_rounded),
              label: const Text(LanguageConstants.startExploring),
            ),
          ],
        ),
      ),
    );
  }
}
