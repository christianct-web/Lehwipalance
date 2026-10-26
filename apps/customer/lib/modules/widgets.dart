import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';
import 'package:video_player/video_player.dart';

// ==================== GEO POINT CLASS ====================
// Since you're not using Firebase, define your own LatLng class
// Or use LatLng from latlong2 package

// ==================== LOCATION PROVIDER ====================

// ==================== VIDEO PLAYER MANAGER ====================
class VideoPlayerManager {
  static VideoPlayerManager? _instance;
  VideoPlayerController? _currentController;

  factory VideoPlayerManager() {
    return _instance ??= VideoPlayerManager._internal();
  }

  VideoPlayerManager._internal();

  void setCurrentPlaying(VideoPlayerController? controller) {
    _currentController?.pause();
    _currentController = controller;
  }

  void dispose() {
    _currentController?.dispose();
    _currentController = null;
  }
}

// ==================== HEADER OVERLAY ====================
class HeaderOverlay extends StatelessWidget {
  final ValueNotifier<String> selectedLocation;
  final List<String> locations;
  final Function(String?) onLocationChanged;
  final VoidCallback onExplore;
  final LocationProvider? provider;
  final VoidCallback? onFilterTap;
  final ThemeProvider themeProvider;

  const HeaderOverlay({
    super.key,
    required this.selectedLocation,
    required this.locations,
    required this.onLocationChanged,
    required this.themeProvider,
    required this.onExplore,
    this.provider,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WelcomeCard(
          themeProvider: themeProvider,
          selectedLocation: selectedLocation,
          onLocationChanged: onLocationChanged,
          provider: provider,
          onFilterTap: onFilterTap,
        ),
        const SizedBox(height: AppConstants.space6),
        _ExploreButton(
          enabled:
              provider?.filter.country != null &&
              provider!.filter.country!.isNotEmpty,
          onTap: () {
            if (provider?.filter.country == null ||
                provider!.filter.country!.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Please select a country first.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
              return;
            }
            onExplore();
          },
        ),
      ],
    );
  }
}

// ==================== EXPLORE BUTTON ====================
class _ExploreButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool enabled;

  const _ExploreButton({required this.onTap, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusL * 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppDimensions.blurSigma,
              sigmaY: AppDimensions.blurSigma,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppConstants.radiusL * 2),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingL,
                    vertical: AppConstants.paddingS,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusL * 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppConstants.space4),
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: AppConstants.iconS,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== WELCOME CARD ====================
class _WelcomeCard extends StatelessWidget {
  final ThemeProvider themeProvider;
  final ValueNotifier<String> selectedLocation;
  final Function(String?) onLocationChanged;
  final LocationProvider? provider;
  final VoidCallback? onFilterTap;

  const _WelcomeCard({
    required this.themeProvider,
    required this.selectedLocation,
    required this.onLocationChanged,
    this.provider,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = themeProvider.colorScheme;
    final isDark = themeProvider.isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppConstants.paddingL),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: AppDimensions.welcomeCardMaxHeight,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusL * 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppDimensions.blurSigma,
              sigmaY: AppDimensions.blurSigma,
            ),
            child: Container(
              padding: EdgeInsets.all(AppConstants.paddingL),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surface.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppConstants.radiusL * 2),
                border: Border.all(
                  color: isDark
                      ? colorScheme.outline.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: AppConstants.iconXL * 3.33,
                    child: Image.asset('assets/icon.png'),
                  ),
                  Text(
                    'Lehwi Palance',
                    style: textTheme.headlineMedium?.copyWith(
                      color: isDark ? colorScheme.onSurface : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: AppConstants.space3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'in',
                        style: textTheme.headlineSmall?.copyWith(
                          color: isDark ? colorScheme.onSurface : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: AppConstants.space3),
                      if (provider != null)
                        CountryFlagDropdownSelector(
                          provider: provider!,
                          themeProvider: themeProvider,
                        ),
                    ],
                  ),
                  SizedBox(height: AppConstants.space3),
                  Text(
                    provider?.filter.country ?? 'Select a country',
                    style: textTheme.titleMedium?.copyWith(
                      color: isDark ? colorScheme.onSurface : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== SIGN UP / SIGN IN BUTTONS ====================
class SignUpCTA extends StatelessWidget {
  final VoidCallback? onPressed;

  const SignUpCTA({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: onPressed ?? () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        padding: EdgeInsets.symmetric(vertical: AppConstants.paddingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        elevation: AppConstants.elevationS,
      ),
      child: Text(
        'Sign Up',
        style: theme.textTheme.labelLarge?.copyWith(
          fontSize: AppConstants.space6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class SignInCTA extends StatelessWidget {
  final VoidCallback onTap;

  const SignInCTA({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.7)),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: AppConstants.paddingM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
      child: Text(
        "Login",
        style: theme.textTheme.labelLarge?.copyWith(
          fontSize: AppConstants.space6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ==================== COUNTRY FLAG DROPDOWN ====================
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
    extends State<CountryFlagDropdownSelector> {
  late ValueNotifier<String> _selectedCountryNotifier;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCountryNotifier = ValueNotifier(
      widget.provider.filter.country ?? '',
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
      final currentCountry = widget.provider.filter.country ?? '';
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
          offset: const Offset(0, AppConstants.space7),
          position: PopupMenuPosition.under,
          padding: EdgeInsets.zero,
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

  Widget _buildLoadingState(bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingS,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
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
          SizedBox(
            width: AppConstants.iconS,
            height: AppConstants.iconS,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppConstants.space5),
          Text('Loading countries...'),
        ],
      ),
    );
  }

  Widget _buildSelectorButton(
    String currentCountry,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final bool hasCountry = currentCountry.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        minWidth: AppConstants.iconL * 1.43,
        maxWidth: AppConstants.iconL * 5.71,
        maxHeight: AppConstants.iconL * 1.43,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.paddingS,
        vertical: AppConstants.paddingXS,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
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
          Flexible(
            child: Text(
              hasCountry ? getFlag(currentCountry) : '🌍',
              style: TextStyle(fontSize: AppConstants.space7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String country, bool isSelected, bool isDark) {
    return Row(
      children: [
        Text(getFlag(country), style: TextStyle(fontSize: AppConstants.space7)),
        SizedBox(width: AppConstants.paddingS),
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
          Icon(
            Icons.check_circle,
            size: AppConstants.iconS,
            color: Colors.green[600],
          ),
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

// ==================== ABSTRACT CLASSES ====================
abstract class Identifiable {
  String get id;
}

abstract class Timestamped {
  DateTime get createdAt;
  DateTime? get updatedAt;
}

abstract class Publishable {
  PublishStatus get status;
  bool get isActive;
}

enum PublishStatus { draft, unpublished, published, archived, canceled }

// ==================== COUNTRY SELECTION MIXIN ====================
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

// ==================== FLAG HELPER ====================
String getFlag(String country) {
  switch (country.toLowerCase().trim()) {
    case 'antigua and barbuda':
      return '🇦🇬';
    case 'bahamas':
      return '🇧🇸';
    case 'barbados':
      return '🇧🇧';
    case 'cuba':
      return '🇨🇺';
    case 'dominica':
      return '🇩🇲';
    case 'dominican republic':
      return '🇩🇴';
    case 'grenada':
      return '🇬🇩';
    case 'haiti':
      return '🇭🇹';
    case 'jamaica':
      return '🇯🇲';
    case 'saint kitts and nevis':
    case 'st. kitts and nevis':
    case 'st kitts and nevis':
      return '🇰🇳';
    case 'saint lucia':
    case 'st. lucia':
    case 'st lucia':
      return '🇱🇨';
    case 'saint vincent and the grenadines':
    case 'st. vincent and the grenadines':
    case 'st vincent and the grenadines':
      return '🇻🇨';
    case 'trinidad and tobago':
      return '🇹🇹';
    case 'united states':
    case 'usa':
      return '🇺🇸';
    case 'canada':
      return '🇨🇦';
    case 'mexico':
      return '🇲🇽';
    case 'united kingdom':
    case 'uk':
    case 'england':
      return '🇬🇧';
    case 'france':
      return '🇫🇷';
    case 'germany':
      return '🇩🇪';
    case 'italy':
      return '🇮🇹';
    case 'spain':
      return '🇪🇸';
    case 'portugal':
      return '🇵🇹';
    case 'netherlands':
      return '🇳🇱';
    case 'belgium':
      return '🇧🇪';
    case 'switzerland':
      return '🇨🇭';
    case 'india':
      return '🇮🇳';
    case 'nigeria':
      return '🇳🇬';
    case 'ghana':
      return '🇬🇭';
    case 'kenya':
      return '🇰🇪';
    case 'south africa':
      return '🇿🇦';
    case 'egypt':
      return '🇪🇬';
    case 'morocco':
      return '🇲🇦';
    case 'china':
      return '🇨🇳';
    case 'japan':
      return '🇯🇵';
    case 'south korea':
    case 'korea':
      return '🇰🇷';
    case 'australia':
      return '🇦🇺';
    case 'new zealand':
      return '🇳🇿';
    case 'argentina':
      return '🇦🇷';
    case 'brazil':
      return '🇧🇷';
    case 'colombia':
      return '🇨🇴';
    case 'venezuela':
      return '🇻🇪';
    case 'aruba':
      return '🇦🇼';
    case 'curacao':
      return '🇨🇼';
    case 'puerto rico':
      return '🇵🇷';
    case 'sint maarten':
      return '🇸🇽';
    default:
      return '📍';
  }
}
