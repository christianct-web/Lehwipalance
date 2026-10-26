// lib/map/widgets/merchant_listing_filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_listing_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';

import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';

import 'dart:async';

import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/map/provider/filter_preference_model.dart';

// lib/customer/modules/map/widgets/merchant_listing_filter_sheet.dart
// lib/map/widgets/merchant_listing_filter_sheet.dart

import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

// lib/map/widgets/merchant_listing_filter_sheet.dart

// lib/customer/modules/map/widgets/merchant_listing_filter_sheet.dart
// lib/map/widgets/merchant_listing_filter_sheet.dart

enum _FilterTab { location, listings }

class MerchantListingFilterSheet extends StatefulWidget {
  final MerchantListingProvider provider;
  final VoidCallback onReset;
  final ValueChanged<MerchantListingFilter> onApply;

  /// The active HomeTab's listing type scope, if any.
  /// When non-null, only chips matching this scope are enabled and the
  /// scope is carried into the applied [MerchantListingFilter.searchScope].
  final ListingType? activeScope;

  const MerchantListingFilterSheet({
    super.key,
    required this.provider,
    required this.onReset,
    required this.onApply,
    this.activeScope,
  });

  @override
  State<MerchantListingFilterSheet> createState() =>
      _MerchantListingFilterSheetState();
}

class _MerchantListingFilterSheetState extends State<MerchantListingFilterSheet>
    with SingleTickerProviderStateMixin {
  late MerchantListingFilter _filter;
  late final TextEditingController _searchController;

  _FilterTab _currentTab = _FilterTab.location;
  bool _isSidePanelOpen = true;

  // Location filter state
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  double _radius = 10.0;
  bool _filterByUserLocation = false;
  List<String> _states = [];
  List<String> _cities = [];

  // Listing types filter state
  List<ListingType> _selectedTypes = [];

  // Listings filter state
  ListingsFilter _listingsFilter = const ListingsFilter();

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Cache for all countries
  List<String> _allCountries = [];

  @override
  void initState() {
    super.initState();
    _filter = widget.provider.currentFilter;
    _searchController = TextEditingController(text: _filter.searchQuery ?? '');

    _selectedCountry = _filter.country;
    _selectedState = _filter.state;
    _selectedCity = _filter.city;
    _radius = _filter.radius ?? 10.0;

    // Seed the chip list from the current filter, but if a tab scope is
    // active, force the selection to that scope only. This prevents the
    // sheet from opening with contradictory chips pre-selected.
    if (widget.activeScope != null) {
      _selectedTypes = [widget.activeScope!];
    } else {
      _selectedTypes = List<ListingType>.from(_filter.listingTypes ?? const []);
    }

    _filterByUserLocation =
        _filter.userLocation != null && widget.provider.hasDeviceLocation;

    _listingsFilter = widget.provider.listingsFilter;

    _loadAllCountries();
    _updateStates();
    _updateCities();

    _animationController = AnimationController(
      duration: AppConstants.animMedium,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: AppConstants.animCurveDefault,
    );
    _animationController.forward();
  }

  void _loadAllCountries() {
    final allListings = widget.provider.allListings;
    final countries = <String>{};
    for (final listing in allListings) {
      final location = widget.provider.getCachedLocation(listing);
      if (location != null) {
        final country = location.address.country;
        if (country.isNotEmpty) countries.add(country);
      }
    }
    _allCountries = countries.toList()..sort();
  }

  void _updateStates() {
    final allListings = widget.provider.allListings;
    final states = <String>{};
    for (final listing in allListings) {
      final location = widget.provider.getCachedLocation(listing);
      if (location != null) {
        if (_selectedCountry != null &&
            location.address.country != _selectedCountry) {
          continue;
        }
        final state = location.address.state;
        if (state.isNotEmpty) states.add(state);
      }
    }
    _states = states.toList()..sort();
  }

  void _updateCities() {
    final allListings = widget.provider.allListings;
    final cities = <String>{};
    for (final listing in allListings) {
      final location = widget.provider.getCachedLocation(listing);
      if (location != null) {
        if (_selectedCountry != null &&
            location.address.country != _selectedCountry) {
          continue;
        }
        if (_selectedState != null &&
            location.address.state != _selectedState) {
          continue;
        }
        final city = location.address.city;
        if (city.isNotEmpty) cities.add(city);
      }
    }
    _cities = cities.toList()..sort();
  }

  /// Computes the effective listing types to apply.
  ///
  /// - If a tab scope is active, the scope wins (only that one type).
  /// - Otherwise, use the user's chip selection (or null if empty).
  List<ListingType>? _effectiveListingTypes() {
    if (widget.activeScope != null) {
      return <ListingType>[widget.activeScope!];
    }
    if (_selectedTypes.isEmpty) return null;
    return List<ListingType>.from(_selectedTypes);
  }

  void _applyFilters() {
    final merchantFilter = MerchantListingFilter(
      searchQuery: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      country: _selectedCountry,
      state: _selectedState,
      city: _selectedCity,
      userLocation: _filterByUserLocation && widget.provider.hasDeviceLocation
          ? LatLng(
              widget.provider.devicePosition!.latitude,
              widget.provider.devicePosition!.longitude,
            )
          : null,
      radius: _radius,
      listingTypes: _effectiveListingTypes(),
    );

    widget.provider.updateFilter(
      merchantFilter,
      listingsFilter: _listingsFilter,
    );
    widget.onApply(merchantFilter);

    if (_selectedCountry != null && _selectedCountry!.isNotEmpty) {
      widget.provider.setActiveCountry(_selectedCountry);
    } else {
      widget.provider.setActiveCountry(null);
    }

    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _filterByUserLocation = false;
      _radius = 10.0;
      _selectedCountry = null;
      _selectedState = null;
      _selectedCity = null;
      // Keep the scope if one is active, otherwise clear chips entirely.
      _selectedTypes = widget.activeScope != null ? [widget.activeScope!] : [];
      _searchController.clear();
      _listingsFilter = const ListingsFilter();
      _updateStates();
      _updateCities();
    });
    widget.provider.resetFilters();
    widget.onReset();
    Navigator.pop(context);
  }

  void _toggleListingType(ListingType type) {
    // Safety: if a scope is active, only that type is selectable.
    if (widget.activeScope != null && widget.activeScope != type) return;

    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXL),
          ),
        ),
        child: Row(
          children: [
            // Side Panel - hidden on small screens
            if (MediaQuery.of(context).size.width > 600)
              AnimatedContainer(
                duration: AppConstants.animMedium,
                width: _isSidePanelOpen ? 240 : 0,
                color: colorScheme.surfaceContainerLow,
                child: _isSidePanelOpen ? _buildSidePanel(colorScheme) : null,
              ),
            // Main content
            Expanded(
              child: Column(
                children: [
                  _buildHeader(colorScheme),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingM),
                      child: Column(
                        children: [
                          _buildTabSelector(colorScheme),
                          const SizedBox(height: AppConstants.space5),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const BouncingScrollPhysics(),
                              child: _currentTab == _FilterTab.location
                                  ? _buildLocationTab()
                                  : _buildListingsTab(),
                            ),
                          ),
                          const SizedBox(height: AppConstants.space5),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB SELECTOR ====================

  Widget _buildTabSelector(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
      ),
      child: Row(
        children: [
          _buildTabButton(
            icon: Icons.location_on_outlined,
            label: LanguageConstants.location,
            tab: _FilterTab.location,
            colorScheme: colorScheme,
          ),
          _buildTabButton(
            icon: Icons.filter_list_outlined,
            label: LanguageConstants.listings,
            tab: _FilterTab.listings,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required _FilterTab tab,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _currentTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentTab = tab),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppConstants.space5),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppConstants.iconS,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppConstants.space3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SIDE PANEL ====================

  Widget _buildSidePanel(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppConstants.paddingM,
        horizontal: AppConstants.paddingS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingS,
              vertical: AppConstants.paddingS,
            ),
            child: Text(
              LanguageConstants.filtersTitle,
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(),
          _buildSidePanelItem(
            icon: Icons.location_on_outlined,
            label: LanguageConstants.location,
            tab: _FilterTab.location,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: AppConstants.space1),
          _buildSidePanelItem(
            icon: Icons.filter_list_outlined,
            label: LanguageConstants.listings,
            tab: _FilterTab.listings,
            colorScheme: colorScheme,
          ),
          const Spacer(),
          _buildFilterSummary(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSidePanelItem({
    required IconData icon,
    required String label,
    required _FilterTab tab,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _currentTab == tab;
    return InkWell(
      onTap: () => setState(() => _currentTab = tab),
      borderRadius: BorderRadius.circular(AppConstants.radiusM),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingS,
          vertical: AppConstants.paddingM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.secondaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: AppConstants.iconM,
              color: isSelected
                  ? colorScheme.onSecondaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppConstants.paddingS),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSummary(ColorScheme colorScheme) {
    final filters = <String>[];
    if (_selectedCountry != null) filters.add('🌍 ${_selectedCountry!}');
    if (_selectedState != null) filters.add('🏛️ ${_selectedState!}');
    if (_selectedCity != null) filters.add('🏙️ ${_selectedCity!}');

    // Show scope as the effective type filter (overrides chip selection).
    final effectiveTypes = _effectiveListingTypes();
    if (effectiveTypes != null && effectiveTypes.isNotEmpty) {
      filters.add('📋 ${effectiveTypes.map((t) => t.name).join(', ')}');
    }

    if (_filterByUserLocation) {
      filters.add('📍 ${LanguageConstants.myLocation}');
    }
    if (_listingsFilter.listingType != null) {
      filters.add(
        '${LanguageConstants.typeLabel}: ${_listingsFilter.listingType!.name}',
      );
    }
    if (_listingsFilter.isActiveOnly == true) {
      filters.add('✅ ${LanguageConstants.activeOnly}');
    }
    if (_listingsFilter.startDate != null) {
      filters.add(
        '📅 ${LanguageConstants.fromLabel}: ${_formatDate(_listingsFilter.startDate!)}',
      );
    }
    if (_listingsFilter.endDate != null) {
      filters.add(
        '📅 ${LanguageConstants.toLabel}: ${_formatDate(_listingsFilter.endDate!)}',
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LanguageConstants.activeFilters,
            style: context.textStyles.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.space1),
          if (filters.isEmpty)
            Text(
              LanguageConstants.noActiveFilters,
              style: context.textStyles.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...filters.map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Text(
                  f,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== HEADER ====================

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingS,
        vertical: AppConstants.paddingS,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width > 600)
            IconButton(
              icon: Icon(_isSidePanelOpen ? Icons.menu_open : Icons.menu),
              onPressed: () =>
                  setState(() => _isSidePanelOpen = !_isSidePanelOpen),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          if (MediaQuery.of(context).size.width > 600)
            const SizedBox(width: AppConstants.paddingS),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    size: AppConstants.iconS,
                  ),
                  hintText: LanguageConstants.searchListings,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingS,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radiusM),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingS),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ==================== TABS ====================

  Widget _buildLocationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocationByUserRadius(),
        const SizedBox(height: AppConstants.paddingM),
        _buildCountryDropdown(),
        const SizedBox(height: AppConstants.paddingM),
        _buildStateDropdown(),
        const SizedBox(height: AppConstants.paddingM),
        _buildCityDropdown(),
        const SizedBox(height: AppConstants.paddingM),
        if (!_filterByUserLocation) _buildRadiusSlider(),
        const SizedBox(height: AppConstants.paddingM),
        _buildListingTypes(),
        const SizedBox(height: AppConstants.paddingS),
      ],
    );
  }

  Widget _buildListingsTab() {
    return ListingsFilterPanel(
      initialFilter: _listingsFilter,
      onFilterChanged: (filter) => setState(() => _listingsFilter = filter),
      onReset: () => setState(() => _listingsFilter = const ListingsFilter()),
    );
  }

  // ==================== LOCATION WIDGETS ====================

  Widget _buildLocationByUserRadius() {
    final colorScheme = context.colors;
    final hasLocation = widget.provider.hasDeviceLocation;
    final position = widget.provider.devicePosition;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: hasLocation
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: hasLocation
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(
                value: _filterByUserLocation,
                onChanged: hasLocation
                    ? (value) => setState(() {
                        _filterByUserLocation = value;
                        if (value) _radius = _filter.radius ?? 10.0;
                      })
                    : null,
              ),
              const SizedBox(width: AppConstants.paddingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageConstants.filterByMyLocation,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: hasLocation
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasLocation && position != null)
                      Text(
                        '📍 ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (!hasLocation)
                      Text(
                        LanguageConstants.locationNotAvailable,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_filterByUserLocation && hasLocation) ...[
            const SizedBox(height: AppConstants.paddingM),
            _buildRadiusSlider(),
          ],
        ],
      ),
    );
  }

  Widget _buildCountryDropdown() {
    final colorScheme = context.colors;
    if (_allCountries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LanguageConstants.country,
          style: context.textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCountry,
              isExpanded: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingM,
                  vertical: AppConstants.paddingS,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(LanguageConstants.allCountries),
                ),
                ..._allCountries.map(
                  (country) => DropdownMenuItem(
                    value: country,
                    child: Row(
                      children: [
                        Text(getFlag(country)),
                        const SizedBox(width: AppConstants.paddingS),
                        Expanded(
                          child: Text(
                            country,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() {
                _selectedCountry = value;
                _selectedState = null;
                _selectedCity = null;
                _updateStates();
                _updateCities();
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown() {
    final colorScheme = context.colors;
    if (_selectedCountry == null || _states.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LanguageConstants.stateProvince,
          style: context.textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedState,
              isExpanded: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingM,
                  vertical: AppConstants.paddingS,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(LanguageConstants.allStates),
                ),
                ..._states.map(
                  (e) => DropdownMenuItem(value: e, child: Text(e)),
                ),
              ],
              onChanged: (value) => setState(() {
                _selectedState = value;
                _selectedCity = null;
                _updateCities();
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    final colorScheme = context.colors;
    if (_selectedState == null || _cities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LanguageConstants.city,
          style: context.textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              isExpanded: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingM,
                  vertical: AppConstants.paddingS,
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(LanguageConstants.allCities),
                ),
                ..._cities.map(
                  (e) => DropdownMenuItem(value: e, child: Text(e)),
                ),
              ],
              onChanged: (value) => setState(() {
                _selectedCity = value;
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRadiusSlider() {
    final colorScheme = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LanguageConstants.radius,
              style: context.textStyles.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_radius.round()} km',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _radius,
          min: 1,
          max: 100,
          divisions: 99,
          label: '${_radius.round()} km',
          onChanged: (value) => setState(() => _radius = value),
        ),
      ],
    );
  }

  // ==================== LISTING TYPES ====================

  Widget _buildListingTypes() {
    final colorScheme = context.colors;
    final scope = widget.activeScope;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              LanguageConstants.listingTypes,
              style: context.textStyles.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (scope != null) ...[
              const SizedBox(width: AppConstants.paddingS),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppConstants.radiusS),
                ),
                child: Text(
                  scope.name,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppConstants.paddingS),
        if (scope != null) ...[
          Text(
            'Scoped to the active tab — other types are unavailable.',
            style: context.textStyles.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
        ],
        Wrap(
          spacing: AppConstants.paddingS,
          runSpacing: AppConstants.paddingS,
          children: ListingType.values.map((type) {
            final isSelected = _selectedTypes.contains(type);
            final isOutOfScope = scope != null && scope != type;
            final isDisabled = isOutOfScope;

            return FilterChip(
              label: Text(type.name),
              selected: isSelected,
              onSelected: isDisabled ? null : (_) => _toggleListingType(type),
              avatar: isSelected ? const Icon(Icons.check, size: 16) : null,
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.primary,
              labelStyle: isOutOfScope
                  ? TextStyle(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    )
                  : null,
              side: isOutOfScope
                  ? BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    )
                  : null,
              disabledColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==================== ACTION BUTTONS ====================

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _resetFilters,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            child: const Text(LanguageConstants.resetAll),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: _applyFilters,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            child: const Text(LanguageConstants.applyFilters),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ==================== LOCATION FILTER PANEL ====================

enum FilterPanel { location, listingTypes }

class LocationFilterPanel extends StatefulWidget {
  final LocationProvider provider;
  final VoidCallback onReset;
  final ValueChanged<LocationFilter> onApply;

  const LocationFilterPanel({
    super.key,
    required this.provider,
    required this.onReset,
    required this.onApply,
  });

  @override
  State<LocationFilterPanel> createState() => _LocationFilterPanelState();
}

class _LocationFilterPanelState extends State<LocationFilterPanel> {
  late LocationFilter _filter;
  late final TextEditingController _searchController;
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;
  double _radius = 10.0;
  bool _filterByUserLocation = false;
  List<String> _states = [];
  List<String> _cities = [];

  @override
  void initState() {
    super.initState();
    _filter = widget.provider.filter.copyWith();
    _searchController = TextEditingController(text: _filter.search ?? '');
    _selectedCountry = widget.provider.filter.country;
    _selectedState = widget.provider.filter.state;
    _selectedCity = widget.provider.filter.city;
    _radius = _filter.radiusKm ?? 10.0;
    _filterByUserLocation =
        _filter.center != null &&
        widget.provider.hasDeviceLocation &&
        _isSameLocation(_filter.center!, widget.provider.devicePosition!);
    _updateStates();
    _updateCities();
  }

  bool _isSameLocation(LatLng point1, Position point2) {
    const double threshold = 0.001;
    return (point1.latitude - point2.latitude).abs() < threshold &&
        (point1.longitude - point2.longitude).abs() < threshold;
  }

  void _updateStates() {
    _states = widget.provider.getUniqueStates(country: _selectedCountry);
  }

  void _updateCities() {
    _cities = widget.provider.getUniqueCities(
      country: _selectedCountry,
      state: _selectedState,
    );
  }

  void _onCountryChanged(String? value) {
    setState(() {
      _selectedCountry = value;
      _selectedState = null;
      _selectedCity = null;
      _states = [];
      _cities = [];
      _updateStates();
      _updateCities();
    });
  }

  void _onStateChanged(String? value) {
    setState(() {
      _selectedState = value;
      _selectedCity = null;
      _cities = [];
      _updateCities();
    });
  }

  void _onCityChanged(String? value) {
    setState(() => _selectedCity = value);
  }

  void _applyFilters() {
    final search = _searchController.text.trim();
    LocationFilter filter;

    if (_filterByUserLocation && widget.provider.hasDeviceLocation) {
      final position = widget.provider.devicePosition!;
      filter = widget.provider.filter.copyWith(
        search: search.isEmpty ? null : search,
        country: _selectedCountry,
        state: _selectedState,
        city: _selectedCity,
        center: LatLng(position.latitude, position.longitude),
        radiusKm: _radius,
      );
    } else {
      filter = widget.provider.filter.copyWith(
        search: search.isEmpty ? null : search,
        country: _selectedCountry,
        state: _selectedState,
        city: _selectedCity,
        radiusKm: _radius,
        clearCenter: true,
      );
    }

    widget.provider.updateFilter(filter);
    widget.onApply(filter);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _filterByUserLocation = false;
      _selectedCountry = null;
      _selectedState = null;
      _selectedCity = null;
      _states = [];
      _cities = [];
      _radius = 10;
      _searchController.clear();
    });
    widget.provider.updateFilter(const LocationFilter());
    widget.onReset();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countries = widget.provider.getUniqueCountries();
    final colorScheme = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(colorScheme),
        const SizedBox(height: AppConstants.paddingM),
        _buildLocationByUserRadius(),
        const SizedBox(height: AppConstants.paddingM),
        _buildCountryDropdown(countries, colorScheme),
        const SizedBox(height: AppConstants.paddingM),
        _buildStateDropdown(colorScheme),
        const SizedBox(height: AppConstants.paddingM),
        _buildCityDropdown(colorScheme),
        const SizedBox(height: AppConstants.paddingM),
        if (!_filterByUserLocation) _buildRadiusSlider(colorScheme),
        const SizedBox(height: AppConstants.paddingXL),
        _buildActionButtons(colorScheme),
      ],
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LanguageConstants.searchLocation,
          style: context.textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: LanguageConstants.searchByNameCityCountry,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingM,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryDropdown(
    List<String> countries,
    ColorScheme colorScheme,
  ) {
    final uniqueCountries = countries.toSet().toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LanguageConstants.country,
          style: context.textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        DropdownButtonFormField<String>(
          initialValue: _selectedCountry,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingM,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(LanguageConstants.allCountries),
            ),
            ...uniqueCountries.map(
              (country) => DropdownMenuItem<String>(
                value: country,
                child: Row(
                  children: [
                    Text(getFlag(country)),
                    const SizedBox(width: AppConstants.paddingS),
                    Expanded(
                      child: Text(country, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: _filterByUserLocation ? null : _onCountryChanged,
          selectedItemBuilder: (context) {
            return [
              DropdownMenuItem<String>(
                value: null,
                child: Text(LanguageConstants.allCountries),
              ),
              ...uniqueCountries.map(
                (country) => DropdownMenuItem<String>(
                  value: country,
                  child: Row(
                    children: [
                      Text(getFlag(country)),
                      const SizedBox(width: AppConstants.paddingS),
                      Expanded(
                        child: Text(country, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  Widget _buildStateDropdown(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LanguageConstants.stateProvince,
          style: context.textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        DropdownButtonFormField<String>(
          initialValue: _selectedState,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingM,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(LanguageConstants.allStates),
            ),
            ..._states.map(
              (e) => DropdownMenuItem<String>(value: e, child: Text(e)),
            ),
          ],
          onChanged: _filterByUserLocation || _selectedCountry == null
              ? null
              : _onStateChanged,
        ),
      ],
    );
  }

  Widget _buildCityDropdown(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LanguageConstants.city,
          style: context.textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        DropdownButtonFormField<String>(
          initialValue: _selectedCity,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingM,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(LanguageConstants.allCities),
            ),
            ..._cities.map(
              (e) => DropdownMenuItem<String>(value: e, child: Text(e)),
            ),
          ],
          onChanged: _filterByUserLocation || _selectedState == null
              ? null
              : _onCityChanged,
        ),
      ],
    );
  }

  Widget _buildRadiusSlider(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LanguageConstants.distanceRadius,
              style: context.textStyles.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${_radius.round()} km',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.space2),
        Slider(
          value: _radius,
          min: 1,
          max: 100,
          divisions: 99,
          label: '${_radius.round()} km',
          onChanged: (value) => setState(() => _radius = value),
        ),
      ],
    );
  }

  Widget _buildLocationByUserRadius() {
    final colorScheme = context.colors;
    final hasLocation = widget.provider.hasDeviceLocation;
    final position = widget.provider.devicePosition;

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: hasLocation
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: hasLocation
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(
                value: _filterByUserLocation,
                onChanged: hasLocation
                    ? (value) {
                        setState(() {
                          _filterByUserLocation = value;
                          if (value) {
                            _radius = _filter.radiusKm ?? 10.0;
                          } else {
                            _radius = 10.0;
                          }
                        });
                      }
                    : null,
              ),
              const SizedBox(width: AppConstants.paddingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LanguageConstants.filterByMyLocation,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: hasLocation
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (hasLocation && position != null)
                      Text(
                        '📍 ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (!hasLocation)
                      Text(
                        LanguageConstants.locationNotAvailable,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_filterByUserLocation && hasLocation) ...[
            const SizedBox(height: AppConstants.paddingM),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LanguageConstants.radius,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${_radius.round()} km',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _radius,
                  min: 5,
                  max: 200,
                  divisions: 39,
                  label: '${_radius.round()} km',
                  onChanged: (value) => setState(() => _radius = value),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _resetFilters,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            child: const Text(LanguageConstants.resetAll),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: _applyFilters,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            child: const Text(LanguageConstants.applyFilters),
          ),
        ),
      ],
    );
  }
}

// ==================== LISTINGS FILTER PANEL ====================

class ListingsFilterPanel extends StatefulWidget {
  final ListingsFilter initialFilter;
  final ValueChanged<ListingsFilter>? onFilterChanged;
  final VoidCallback? onReset;

  const ListingsFilterPanel({
    super.key,
    required this.initialFilter,
    this.onFilterChanged,
    this.onReset,
  });

  @override
  State<ListingsFilterPanel> createState() => _ListingsFilterPanelState();
}

class _ListingsFilterPanelState extends State<ListingsFilterPanel> {
  late ListingsFilter _filter;
  late TextEditingController _searchController;

  ListingType? _selectedType;
  DateTimeRange? _dateRange;
  bool _isActiveOnly = true;
  bool _hasLocation = false;
  double _radius = 10.0;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _searchController = TextEditingController(text: _filter.searchQuery ?? '');

    _selectedType = _filter.listingType;
    _isActiveOnly = _filter.isActiveOnly ?? true;
    _hasLocation = _filter.hasLocation ?? false;
    _radius = _filter.radius ?? 10.0;
    _startDate = _filter.startDate;
    _endDate = _filter.endDate;

    if (_startDate != null && _endDate != null) {
      _dateRange = DateTimeRange(start: _startDate!, end: _endDate!);
    }
  }

  void _notifyFilterChanged() {
    final filter = ListingsFilter(
      searchQuery: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      listingType: _selectedType,
      startDate: _startDate,
      endDate: _endDate,
      isActiveOnly: _isActiveOnly,
      hasLocation: _hasLocation,
      radius: _radius,
    );
    widget.onFilterChanged?.call(filter);
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = null;
      _startDate = null;
      _endDate = null;
      _dateRange = null;
      _isActiveOnly = true;
      _hasLocation = false;
      _radius = 10.0;
    });
    widget.onReset?.call();
    _notifyFilterChanged();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _notifyFilterChanged();
    }
  }

  void _clearDateRange() {
    setState(() {
      _dateRange = null;
      _startDate = null;
      _endDate = null;
    });
    _notifyFilterChanged();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(colorScheme),
        const SizedBox(height: AppConstants.paddingM),
        _buildListingTypeDropdown(colorScheme),
        const SizedBox(height: AppConstants.paddingM),
        _buildDateRangePicker(colorScheme),
        const SizedBox(height: AppConstants.paddingM),
        _buildActiveOnlyToggle(colorScheme),
        const SizedBox(height: AppConstants.paddingM),
        _buildLocationFilter(colorScheme),
        const SizedBox(height: AppConstants.paddingXL),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LanguageConstants.searchListings,
          style: context.textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        TextField(
          controller: _searchController,
          onChanged: (_) => _notifyFilterChanged(),
          decoration: InputDecoration(
            hintText: LanguageConstants.searchByTitleDescription,
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingM,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListingTypeDropdown(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LanguageConstants.listingType,
          style: context.textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.paddingS),
        DropdownButtonFormField<ListingType?>(
          initialValue: _selectedType,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingM,
              vertical: AppConstants.paddingM,
            ),
          ),
          items: [
            DropdownMenuItem<ListingType?>(
              value: null,
              child: Text(LanguageConstants.allTypes),
            ),
            ...ListingType.values.map(
              (type) => DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      type.icon,
                      size: AppConstants.iconS,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppConstants.paddingS),
                    Text(type.label),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() => _selectedType = value);
            _notifyFilterChanged();
          },
        ),
      ],
    );
  }

  Widget _buildDateRangePicker(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LanguageConstants.dateRange,
              style: context.textStyles.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_dateRange != null)
              TextButton(
                onPressed: _clearDateRange,
                child: const Text(LanguageConstants.clear),
              ),
          ],
        ),
        const SizedBox(height: AppConstants.paddingS),
        InkWell(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(AppConstants.radiusM),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: colorScheme.primary,
                  size: AppConstants.iconS,
                ),
                const SizedBox(width: AppConstants.paddingM),
                Expanded(
                  child: Text(
                    _dateRange != null
                        ? '${_formatDate(_dateRange!.start)} - ${_formatDate(_dateRange!.end)}'
                        : LanguageConstants.selectDateRange,
                    style: TextStyle(
                      color: _dateRange != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveOnlyToggle(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          LanguageConstants.activeListingsOnly,
          style: context.textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Switch(
          value: _isActiveOnly,
          onChanged: (value) {
            setState(() => _isActiveOnly = value);
            _notifyFilterChanged();
          },
        ),
      ],
    );
  }

  Widget _buildLocationFilter(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: _hasLocation
            ? colorScheme.primaryContainer.withValues(alpha: 0.4)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: _hasLocation
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                LanguageConstants.filterByLocation,
                style: context.textStyles.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Switch(
                value: _hasLocation,
                onChanged: (value) {
                  setState(() => _hasLocation = value);
                  _notifyFilterChanged();
                },
              ),
            ],
          ),
          if (_hasLocation) ...[
            const SizedBox(height: AppConstants.paddingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  LanguageConstants.radius,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${_radius.round()} km',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _radius,
              min: 1,
              max: 100,
              divisions: 99,
              label: '${_radius.round()} km',
              onChanged: (value) {
                setState(() => _radius = value);
                _notifyFilterChanged();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _resetFilters,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            child: const Text(LanguageConstants.resetFilters),
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: () => _notifyFilterChanged(),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.paddingM,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusM),
              ),
            ),
            child: const Text(LanguageConstants.applyFilters),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ==================== LISTINGS FILTER MODEL ====================

class ListingsFilter {
  final String? searchQuery;
  final ListingType? listingType;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isActiveOnly;
  final bool? hasLocation;
  final double? radius;

  const ListingsFilter({
    this.searchQuery,
    this.listingType,
    this.startDate,
    this.endDate,
    this.isActiveOnly,
    this.hasLocation,
    this.radius,
  });

  bool get hasFilters =>
      searchQuery != null ||
      listingType != null ||
      startDate != null ||
      endDate != null ||
      isActiveOnly != null ||
      hasLocation != null ||
      radius != null;

  ListingsFilter copyWith({
    String? searchQuery,
    ListingType? listingType,
    PublishStatus? status,
    BookingType? bookingType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActiveOnly,
    bool? hasLocation,
    double? radius,
  }) {
    return ListingsFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      listingType: listingType ?? this.listingType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActiveOnly: isActiveOnly ?? this.isActiveOnly,
      hasLocation: hasLocation ?? this.hasLocation,
      radius: radius ?? this.radius,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (searchQuery != null) 'searchQuery': searchQuery,
      if (listingType != null) 'listingType': listingType!.name,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (isActiveOnly != null) 'isActiveOnly': isActiveOnly,
      if (hasLocation != null) 'hasLocation': hasLocation,
      if (radius != null) 'radius': radius,
    };
  }

  factory ListingsFilter.fromJson(Map<String, dynamic> json) {
    return ListingsFilter(
      searchQuery: json['searchQuery'] as String?,
      listingType: json['listingType'] != null
          ? ListingType.values.firstWhere(
              (e) => e.name == json['listingType'],
              orElse: () => ListingType.place,
            )
          : null,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActiveOnly: json['isActiveOnly'] as bool?,
      hasLocation: json['hasLocation'] as bool?,
      radius: json['radius'] as double?,
    );
  }
}
