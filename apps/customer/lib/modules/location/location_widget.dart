// lib/modules/widgets.dart
import 'package:flutter/material.dart';

import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/location_services.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// SPLASH COUNTRY SELECTOR
// ============================================================
class SplashCountrySelector extends StatefulWidget {
  final LocationProvider provider;
  final ThemeProvider themeProvider;
  final ValueNotifier<String> selectedLocation;
  final Function(String?) onLocationChanged;
  final VoidCallback? onFilterApplied;

  const SplashCountrySelector({
    super.key,
    required this.provider,
    required this.themeProvider,
    required this.selectedLocation,
    required this.onLocationChanged,
    this.onFilterApplied,
  });

  @override
  State<SplashCountrySelector> createState() => _SplashCountrySelectorState();
}

class _SplashCountrySelectorState extends State<SplashCountrySelector>
    with CountrySelectionMixin {
  bool _isLoading = false;
  bool _isAutoDetecting = false;
  bool _hasAttemptedDetection = false;
  bool _detectionComplete = false;
  String? _detectedCountry;

  @override
  void initState() {
    super.initState();
    widget.provider.addListener(_onProviderChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoDetectCountryFromLocation();
    });
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  // ==================== AUTO DETECTION ====================

  Future<void> _autoDetectCountryFromLocation() async {
    if (_hasAttemptedDetection || _detectionComplete) return;
    _hasAttemptedDetection = true;

    final locationService = getIt<LocationService>();

    try {
      _isAutoDetecting = true;
      if (mounted) setState(() {});

      debugPrint('📍 Starting country auto-detection...');

      final currentCountry = widget.provider.filter.country;
      if (currentCountry != null && currentCountry.isNotEmpty) {
        debugPrint('📍 Provider already has country: $currentCountry');
        _detectedCountry = currentCountry;
        _detectionComplete = true;
        _isAutoDetecting = false;
        if (mounted) setState(() {});
        return;
      }

      final position = await locationService.getCurrentLocation(
        timeout: const Duration(seconds: 15),
      );

      if (position != null && mounted) {
        debugPrint(
          '📍 Got device location: ${position.latitude}, ${position.longitude}',
        );

        final address = await locationService.getAddressFromCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        if (address != null && mounted) {
          debugPrint('📍 Got address: $address');

          String? matchedCountry = _directCountryMatch(address);

          if (matchedCountry == null) {
            final extracted = _extractCountryFromAddress(address);
            if (extracted != null && extracted.isNotEmpty) {
              debugPrint('📍 Extracted country: $extracted');
              matchedCountry = _matchCountryWithList(extracted);
            }
          }

          if (matchedCountry != null) {
            debugPrint('✅ Matched country: $matchedCountry');
            await _applyDetectedCountry(matchedCountry);
            _detectionComplete = true;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📍 Location detected: $matchedCountry'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: Colors.green,
                ),
              );
            }
            return;
          }
        }
      }

      debugPrint('📍 Falling back to cached country...');
      await _tryLastKnownCountry();
    } catch (e) {
      debugPrint('❌ Error auto-detecting country: $e');
      await _tryLastKnownCountry();
    } finally {
      if (mounted) {
        _isAutoDetecting = false;
        setState(() {});
      }
    }
  }

  String? _directCountryMatch(String address) {
    final lowerAddress = address.toLowerCase();

    final trinidadKeywords = ['trinidad', 'tobago', 'tt'];
    for (final keyword in trinidadKeywords) {
      if (lowerAddress.contains(keyword)) {
        debugPrint('🎯 DIRECT MATCH: Found "$keyword" in address');
        final countries = widget.provider.getUniqueCountries();
        for (final country in countries) {
          final lowerCountry = country.toLowerCase();
          if (lowerCountry.contains('trinidad') ||
              lowerCountry.contains('tobago')) {
            debugPrint('✅ Found Trinidad in country list: $country');
            return country;
          }
        }
        return 'Trinidad and Tobago';
      }
    }

    final countryPatterns = {
      'nigeria': 'Nigeria',
      'ghana': 'Ghana',
      'kenya': 'Kenya',
      'south africa': 'South Africa',
      'egypt': 'Egypt',
      'united states': 'United States',
      'usa': 'United States',
      'united kingdom': 'United Kingdom',
      'uk': 'United Kingdom',
      'canada': 'Canada',
      'australia': 'Australia',
    };

    for (final entry in countryPatterns.entries) {
      if (lowerAddress.contains(entry.key)) {
        debugPrint('🎯 DIRECT MATCH: Found "${entry.key}" in address');
        return entry.value;
      }
    }

    return null;
  }

  Future<void> _tryLastKnownCountry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCountry = prefs.getString('last_detected_country');

      if (lastCountry != null && lastCountry.isNotEmpty && mounted) {
        debugPrint('📦 Found cached country: $lastCountry');
        final matched = _matchCountryWithList(lastCountry);
        if (matched != null) {
          await _applyDetectedCountry(matched);
          _detectionComplete = true;
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading last known country: $e');
    }
  }

  String? _matchCountryWithList(String detectedCountry) {
    final countries = widget.provider.getUniqueCountries();

    if (countries.isEmpty) {
      debugPrint('⚠️ No countries available in list');
      return null;
    }

    debugPrint(
      '🔍 Matching "$detectedCountry" against ${countries.length} countries',
    );

    for (final country in countries) {
      if (country.toLowerCase() == detectedCountry.toLowerCase()) {
        debugPrint('✅ Exact match found: $country');
        return country;
      }
    }

    for (final country in countries) {
      final countryLower = country.toLowerCase();
      final detectedLower = detectedCountry.toLowerCase();

      if (countryLower.contains(detectedLower) ||
          detectedLower.contains(countryLower)) {
        debugPrint('✅ Partial match found: $country');
        return country;
      }
    }

    final variations = _getCountryVariations(detectedCountry);
    for (final variation in variations) {
      for (final country in countries) {
        if (country.toLowerCase() == variation.toLowerCase()) {
          debugPrint('✅ Variation match found: $country');
          return country;
        }
      }
    }

    debugPrint('❌ No match found for: $detectedCountry');
    return null;
  }

  List<String> _getCountryVariations(String country) {
    final variations = <String>[];
    final lower = country.toLowerCase();

    final countryMap = {
      'trinidad': ['trinidad and tobago', 'trinidad & tobago', 'tt'],
      'usa': ['united states', 'america', 'us', 'united states of america'],
      'uk': ['united kingdom', 'britain', 'england', 'great britain'],
      'uae': ['united arab emirates'],
      'south korea': ['korea', 'republic of korea'],
      'north korea': ['korea', 'democratic people\'s republic of korea'],
      'nigeria': ['naija'],
      'ghana': ['gold coast'],
    };

    for (final entry in countryMap.entries) {
      if (entry.key == lower || entry.value.contains(lower)) {
        variations.add(entry.key);
        variations.addAll(entry.value);
      }
    }

    if (lower.contains('republic of')) {
      variations.add(lower.replaceAll('republic of', '').trim());
    }
    if (lower.contains('united')) {
      variations.add(lower.replaceAll('united', '').trim());
    }
    if (lower.contains('&')) {
      variations.add(lower.replaceAll('&', 'and').trim());
      variations.add(lower.replaceAll('&', '').trim());
    }

    return variations.toSet().toList();
  }

  String? _extractCountryFromAddress(String address) {
    final parts = address.split(',').map((e) => e.trim()).toList();

    debugPrint('📝 Address parts: $parts');

    if (parts.isEmpty) return null;

    final countryKeywords = [
      'republic',
      'kingdom',
      'united',
      'states',
      'federation',
      'trinidad',
      'tobago',
      'nigeria',
      'ghana',
      'kenya',
      'south africa',
      'egypt',
      'morocco',
      'algeria',
    ];

    for (final part in parts) {
      final lowerPart = part.toLowerCase();

      for (final keyword in countryKeywords) {
        if (lowerPart.contains(keyword)) {
          debugPrint('✅ Found country keyword "$keyword" in: $part');
          return part;
        }
      }

      if (part.length > 2 &&
          !RegExp(r'^[0-9\s\-]+$').hasMatch(part) &&
          !RegExp(r'^[A-Z]{1,3}$').hasMatch(part) &&
          part.length < 50) {
        return part;
      }
    }

    for (int i = parts.length - 1; i >= 0; i--) {
      final part = parts[i];
      if (part.isNotEmpty && part.length > 2 && part.length < 50) {
        return part;
      }
    }

    return null;
  }

  Future<void> _applyDetectedCountry(String country) async {
    if (!mounted) return;

    debugPrint('🌍 Applying detected country: $country');

    final countries = widget.provider.getUniqueCountries();

    String countryToApply = country;
    if (!countries.contains(country)) {
      debugPrint('⚠️ Country not in list: $country');

      for (final c in countries) {
        if (c.toLowerCase().contains('trinidad') ||
            c.toLowerCase().contains('tobago')) {
          countryToApply = c;
          debugPrint('✅ Found similar country: $c');
          break;
        }
      }

      if (!countries.contains(countryToApply) && countries.isNotEmpty) {
        countryToApply = countries.first;
        debugPrint('⚠️ Using first available country: $countryToApply');
      }
    }

    widget.selectedLocation.value = countryToApply;
    widget.provider.setCountry(countryToApply);
    widget.onLocationChanged(countryToApply);
    widget.onFilterApplied?.call();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_detected_country', countryToApply);
      debugPrint('💾 Cached detected country: $countryToApply');
    } catch (e) {
      debugPrint('❌ Error caching country: $e');
    }

    if (mounted) {
      setState(() {
        _detectionComplete = true;
        _detectedCountry = countryToApply;
      });
    }
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeProvider.isDarkMode;
    final colorScheme = widget.themeProvider.colorScheme;
    final countries = widget.provider.getUniqueCountries();

    final uniqueCountries = countries.toSet().toList()..sort();
    final currentCountry = getCurrentCountry(widget.provider);

    debugPrint('📍 Build - Current country: "$currentCountry"');
    debugPrint('📍 Build - Detection complete: $_detectionComplete');
    debugPrint('📍 Build - Unique countries: $uniqueCountries');

    if (_isAutoDetecting) {
      return _buildLoadingState(
        isDark,
        colorScheme,
        message: 'Detecting your country...',
      );
    }

    if (uniqueCountries.isEmpty) {
      return _buildLoadingState(
        isDark,
        colorScheme,
        message: 'Loading countries...',
      );
    }

    final displayValue = currentCountry.isNotEmpty ? currentCountry : null;

    debugPrint('📍 Display value: "$displayValue"');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.4),
        ),
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: displayValue,
          hint: _buildHint(isDark, colorScheme),
          dropdownColor: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          isExpanded: true,
          items: _buildDropdownItems(
            uniqueCountries,
            currentCountry,
            isDark,
            colorScheme,
          ),
          onChanged: _isLoading ? null : _onDropdownChanged,
          selectedItemBuilder: (BuildContext context) {
            return uniqueCountries.map((country) {
              return _buildSelectedItem(country, isDark, colorScheme);
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildHint(bool isDark, ColorScheme colorScheme) {
    if (_detectedCountry != null && !_isAutoDetecting) {
      return Row(
        children: [
          const Icon(Icons.gps_fixed, size: 14, color: Colors.green),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Detected: $_detectedCountry',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      'Select Country',
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: isDark ? colorScheme.onSurface : Colors.white70,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  List<DropdownMenuItem<String>> _buildDropdownItems(
    List<String> countries,
    String currentCountry,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final items = <DropdownMenuItem<String>>[];

    items.add(
      DropdownMenuItem<String>(
        value: 'detect_location',
        child: Row(
          children: [
            const Icon(Icons.gps_fixed, size: 16, color: Colors.green),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                '🔍 Detect my location',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    items.add(
      const DropdownMenuItem<String>(
        value: null,
        enabled: false,
        child: Divider(height: 1),
      ),
    );

    items.addAll(
      countries.map((country) {
        final isSelected = currentCountry == country;
        return DropdownMenuItem<String>(
          value: country,
          child: Row(
            children: [
              Text(getFlag(country), style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  country,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: isDark ? colorScheme.onSurface : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
            ],
          ),
        );
      }).toList(),
    );

    return items;
  }

  Widget _buildSelectedItem(
    String country,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        Text(getFlag(country), style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            country,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: isDark ? colorScheme.onSurface : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right,
          size: 18,
          color: isDark ? colorScheme.onSurface : Colors.white70,
        ),
      ],
    );
  }

  // ============================================================
  // ✅ FIXED: Loading state now shrinks to fit narrow slots
  // ============================================================
  Widget _buildLoadingState(
    bool isDark,
    ColorScheme colorScheme, {
    String message = 'Loading countries...',
  }) {
    return Container(
      // ✅ No fixed padding that forces width
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.4),
        ),
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          // ✅ Flexible + ellipsis so it shrinks instead of overflowing
          Flexible(
            child: Text(
              message,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: isDark ? colorScheme.onSurface : Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EVENTS ====================

  void _onDropdownChanged(String? newValue) {
    if (_isLoading) return;

    if (newValue == 'detect_location') {
      _hasAttemptedDetection = false;
      _detectionComplete = false;
      _autoDetectCountryFromLocation();
    } else if (newValue != null && newValue.isNotEmpty) {
      _handleCountrySelection(newValue);
    }
  }

  void _handleCountrySelection(String country) {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    handleCountrySelection(
      widget.provider,
      country,
      onCountrySelected: () {
        widget.selectedLocation.value = country;
        widget.onLocationChanged(country);
        widget.onFilterApplied?.call();
        _detectionComplete = true;
        _detectedCountry = country;
      },
      onFilterApplied: widget.onFilterApplied,
    );

    setState(() => _isLoading = false);
  }
}

// ============================================================
// COUNTRY FLAG DROPDOWN SELECTOR (AppBar version)
// ============================================================
class CountryFlagDropdownSelector extends StatefulWidget {
  final LocationProvider provider;
  final ThemeProvider themeProvider;
  final VoidCallback? onCountrySelected;
  final VoidCallback? onFilterApplied;

  const CountryFlagDropdownSelector({
    super.key,
    required this.provider,
    required this.themeProvider,
    this.onCountrySelected,
    this.onFilterApplied,
  });

  @override
  State<CountryFlagDropdownSelector> createState() =>
      _CountryFlagDropdownSelectorState();
}

class _CountryFlagDropdownSelectorState
    extends State<CountryFlagDropdownSelector>
    with CountrySelectionMixin {
  late ValueNotifier<String> _selectedCountryNotifier;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCountryNotifier = ValueNotifier(
      getCurrentCountry(widget.provider),
    );
    widget.provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderChanged);
    _selectedCountryNotifier.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) {
      final currentCountry = getCurrentCountry(widget.provider);
      if (_selectedCountryNotifier.value != currentCountry) {
        _selectedCountryNotifier.value = currentCountry;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeProvider.isDarkMode;
    final colorScheme = widget.themeProvider.colorScheme;
    final countries = widget.provider.getUniqueCountries();

    final uniqueCountries = countries.toSet().toList()..sort();

    if (uniqueCountries.isEmpty) {
      return _buildLoadingState(isDark, colorScheme);
    }

    return ValueListenableBuilder<String>(
      valueListenable: _selectedCountryNotifier,
      builder: (context, selectedCountry, _) {
        return PopupMenuButton<String>(
          offset: const Offset(0, 40),
          position: PopupMenuPosition.under,
          padding: EdgeInsets.zero,
          tooltip: 'Change country',
          child: _buildSelectorButton(selectedCountry, isDark, colorScheme),
          onSelected: (String newValue) {
            if (newValue.isNotEmpty && newValue != selectedCountry) {
              _handleCountrySelection(newValue);
            }
          },
          itemBuilder: (BuildContext context) {
            return uniqueCountries.map((String country) {
              return PopupMenuItem<String>(
                value: country,
                key: ValueKey(country),
                child: _buildMenuItem(
                  country,
                  country == selectedCountry,
                  isDark,
                ),
              );
            }).toList();
          },
        );
      },
    );
  }

  // ============================================================
  // ✅ FIXED: ultra-compact loading state for AppBar leading slot
  // ============================================================
  Widget _buildLoadingState(bool isDark, ColorScheme colorScheme) {
    // ✅ Return ONLY a spinner — no text. Fits any narrow slot.
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.4),
        ),
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.15),
      ),
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  // ============================================================
  // ✅ FIXED: selector button now shows flag + chevron only
  // ============================================================
  Widget _buildSelectorButton(
    String currentCountry,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final bool hasCountry = currentCountry.isNotEmpty;

    return Container(
      // ✅ Hard cap width so it never blows out the toolbar
      constraints: const BoxConstraints(
        minWidth: 40,
        maxWidth: 56,
        maxHeight: 40,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.4),
        ),
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasCountry ? getFlag(currentCountry) : '🌍',
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 2),
          // ✅ Chevron tells the user it's tappable
          Icon(
            Icons.arrow_drop_down,
            size: 16,
            color: isDark ? colorScheme.onSurface : Colors.white70,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String country, bool isSelected, bool isDark) {
    return Row(
      children: [
        Text(getFlag(country), style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            country,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        if (isSelected)
          Icon(Icons.check_circle, size: 18, color: Colors.green[600]),
      ],
    );
  }

  void _handleCountrySelection(String country) {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      widget.provider.updateFilter(
        widget.provider.filter.copyWith(
          country: country,
          clearState: true,
          clearCity: true,
        ),
      );

      _selectedCountryNotifier.value = country;

      widget.onCountrySelected?.call();
      widget.onFilterApplied?.call();

      debugPrint(
        '🌍 CountryFlagDropdownSelector filtered by country: $country',
      );
    } catch (e) {
      debugPrint('❌ Error selecting country: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// ============================================================
// COUNTRY SELECTION MIXIN
// ============================================================
mixin CountrySelectionMixin {
  void handleCountrySelection(
    LocationProvider provider,
    String country, {
    VoidCallback? onCountrySelected,
    VoidCallback? onFilterApplied,
  }) {
    if (country.isEmpty) return;

    provider.setCountry(country);

    final existingFilter = provider.presetFilters.firstWhere(
      (filter) =>
          filter.country?.toLowerCase() == country.toLowerCase() &&
          filter.city == null &&
          filter.state == null,
      orElse: () => const LocationFilter(),
    );

    if (existingFilter.id != null) {
      if (provider.activeFilterId != existingFilter.id) {
        provider.applyFilterPreset(existingFilter.id!);
        onFilterApplied?.call();
      }
    } else {
      final filter = LocationFilter(
        id: 'filter_${DateTime.now().millisecondsSinceEpoch}',
        name: '$country Locations',
        country: country,
        isExclusive: false,
      );

      provider.addPresetFilter(filter);
      if (filter.id != null) {
        provider.applyFilterPreset(filter.id!);
        onFilterApplied?.call();
      }
    }

    onCountrySelected?.call();
  }

  bool isCountrySelected(LocationProvider provider, String country) {
    return provider.filter.country?.toLowerCase() == country.toLowerCase();
  }

  String getCurrentCountry(LocationProvider provider) {
    return provider.filter.country ?? '';
  }
}

// ============================================================
// FLAG HELPER (assuming it's referenced from here)
// ============================================================
// If getFlag() is defined elsewhere in this file, leave it. Otherwise:
String getFlag(String country) {
  const flags = {
    'Trinidad and Tobago': '🇹🇹',
    'Nigeria': '🇳🇬',
    'Ghana': '🇬🇭',
    'Kenya': '🇰🇪',
    'South Africa': '🇿🇦',
    'Egypt': '🇪🇬',
    'United States': '🇺🇸',
    'United Kingdom': '🇬🇧',
    'Canada': '🇨🇦',
    'Australia': '🇦🇺',
    'India': '🇮🇳',
    'Jamaica': '🇯🇲',
    'Barbados': '🇧🇧',
    'Guyana': '🇬🇾',
  };
  return flags[country] ?? '🌍';
}
