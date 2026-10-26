// ignore_for_file: unused_field

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';

import 'package:lehwipalancecustomerv1/core/models/common_models/media_model.dart';
import 'package:lehwipalancecustomerv1/core/router/route_names.dart';
import 'package:lehwipalancecustomerv1/core/router/route_paths.dart';

import 'package:lehwipalancecustomerv1/modules/widgets.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';
import 'package:video_player/video_player.dart';

// ==================== SPLASH FILTER WIDGET ====================

class SplashFilter extends StatefulWidget {
  final List<MediaModel> mediaItems;
  final bool isActive;
  final LocationProvider provider;
  final Duration autoPlayInterval;
  final ValueNotifier<String> selectedLocation;
  final Function(String?) onLocationChanged;
  final VoidCallback onExploreTap;
  final VoidCallback onSignUpTap;
  final VoidCallback onSignInTap;

  const SplashFilter({
    super.key,
    required this.mediaItems,
    required this.isActive,
    required this.provider,
    required this.selectedLocation,
    required this.onLocationChanged,
    required this.onExploreTap,
    required this.onSignUpTap,
    required this.onSignInTap,
    this.autoPlayInterval = const Duration(seconds: 5),
  });

  @override
  State<SplashFilter> createState() => _SplashFilterState();
}

class _SplashFilterState extends State<SplashFilter>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late ThemeProvider _themeProvider;

  List<VideoPlayerController?> _videoControllers = [];
  List<bool> _isVideoInitialized = [];
  int _currentIndex = 0;

  List<String> _states = [];
  late List<String> _allMediaUrls;

  @override
  void initState() {
    super.initState();
    // ✅ FIX: Use GetIt singleton
    _themeProvider = getIt<ThemeProvider>();
    _pageController = PageController();

    _allMediaUrls = [];
    for (final media in widget.mediaItems) {
      _allMediaUrls.addAll(media.imageUrls);
      if (media.videoUrls != null) {
        _allMediaUrls.addAll(media.videoUrls!);
      }
    }

    _animationController =
        AnimationController(vsync: this, duration: widget.autoPlayInterval)
          ..addListener(() {
            if (_animationController.isCompleted) {
              _nextMedia();
              _animationController.reset();
              if (widget.isActive && _allMediaUrls.length > 1) {
                _animationController.forward();
              }
            }
          });

    _initializeAllMedia();
    _loadInitialFilter();

    if (widget.isActive && _allMediaUrls.length > 1) {
      _animationController.forward();
    }
  }

  void _initializeAllMedia() async {
    _videoControllers = List.generate(_allMediaUrls.length, (_) => null);
    _isVideoInitialized = List.generate(_allMediaUrls.length, (_) => false);

    for (int i = 0; i < _allMediaUrls.length; i++) {
      final url = _allMediaUrls[i];
      if (_isVideoUrl(url)) {
        try {
          final controller = VideoPlayerController.networkUrl(Uri.parse(url));
          await controller.initialize();
          _videoControllers[i] = controller;
          _isVideoInitialized[i] = true;

          if (widget.isActive && i == _currentIndex) {
            controller.play();
            controller.setLooping(true);
            VideoPlayerManager().setCurrentPlaying(controller);
          }
        } catch (e) {
          debugPrint('Failed to initialize video at index $i: $e');
          _videoControllers[i] = null;
          _isVideoInitialized[i] = false;
        }
      }
    }
    if (mounted) setState(() {});
  }

  void _disposeAllVideos() {
    for (final controller in _videoControllers) {
      controller?.dispose();
    }
    _videoControllers.clear();
    _isVideoInitialized.clear();
  }

  void _reinitializeMedia() {
    _disposeAllVideos();
    _initializeAllMedia();
  }

  @override
  void didUpdateWidget(SplashFilter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.mediaItems != widget.mediaItems) {
      _allMediaUrls = [];
      for (final media in widget.mediaItems) {
        _allMediaUrls.addAll(media.imageUrls);
        if (media.videoUrls != null) {
          _allMediaUrls.addAll(media.videoUrls!);
        }
      }
      _reinitializeMedia();
    }

    if (widget.isActive && !oldWidget.isActive) {
      if (_allMediaUrls.length > 1) _animationController.forward();
      if (_currentIndex < _videoControllers.length &&
          _videoControllers[_currentIndex] != null &&
          _isVideoInitialized[_currentIndex] &&
          !_videoControllers[_currentIndex]!.value.isPlaying) {
        _videoControllers[_currentIndex]?.play();
      }
    } else if (!widget.isActive && oldWidget.isActive) {
      _animationController.stop();
      if (_currentIndex < _videoControllers.length &&
          _videoControllers[_currentIndex] != null &&
          _isVideoInitialized[_currentIndex] &&
          _videoControllers[_currentIndex]!.value.isPlaying) {
        _videoControllers[_currentIndex]?.pause();
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _disposeAllVideos();
    super.dispose();
  }

  void _loadInitialFilter() {
    final filter = widget.provider.filter;
    _states = widget.provider.getUniqueStates(country: filter.country);
  }

  bool _isVideoUrl(String url) {
    for (final media in widget.mediaItems) {
      if (media.videoUrls != null && media.videoUrls!.contains(url)) {
        return true;
      }
    }
    const videoExtensions = ['.mp4', '.mov', '.avi', '.wmv', '.flv', '.webm'];
    return videoExtensions.any((ext) => url.toLowerCase().endsWith(ext));
  }

  void _nextMedia() {
    if (_currentIndex < _allMediaUrls.length - 1) {
      _goToPage(_currentIndex + 1);
    } else {
      _goToPage(0);
    }
  }

  void _goToPage(int index) {
    if (_videoControllers[_currentIndex] != null &&
        _isVideoInitialized[_currentIndex]) {
      _videoControllers[_currentIndex]?.pause();
    }

    if (!mounted) return;
    setState(() => _currentIndex = index);

    // The PageView may not be attached yet (e.g. before first layout or
    // while the slide list is empty); animating then throws "No element".
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: AppConstants.animSlow,
      curve: AppConstants.animCurveDefault,
    );

    if (_videoControllers[index] != null && _isVideoInitialized[index]) {
      _videoControllers[index]?.play();
      VideoPlayerManager().setCurrentPlaying(_videoControllers[index]);
    }
  }

  void _showFilterSheet() {
    _animationController.stop();
    if (_videoControllers[_currentIndex] != null &&
        _isVideoInitialized[_currentIndex] &&
        _videoControllers[_currentIndex]!.value.isPlaying) {
      _videoControllers[_currentIndex]?.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_allMediaUrls.isEmpty) {
      return ColoredBox(color: colorScheme.surface);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('cover_image1.jpg', fit: BoxFit.cover),
        // ✅ Material 3: Theme-aware scrim gradient
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                colorScheme.scrim.withValues(alpha: 0.85),
              ],
            ),
          ),
        ),
        _buildContentOverlay(),
      ],
    );
  }

  Widget _buildContentOverlay() {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(height: AppConstants.space3),
          HeaderOverlay(
            selectedLocation: widget.selectedLocation,
            locations: widget.provider.getUniqueCountries(),
            onLocationChanged: widget.onLocationChanged,
            themeProvider: _themeProvider,
            onExplore: widget.onExploreTap,
            provider: widget.provider,
            onFilterTap: _showFilterSheet,
          ),
          _buildAuthButtons(),
        ],
      ),
    );
  }

  Widget _buildAuthButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingM,
        vertical: AppConstants.paddingL,
      ),
      child: Row(
        children: [
          Expanded(child: SignUpCTA(onPressed: widget.onSignUpTap)),
          const SizedBox(width: AppConstants.space5),
          Expanded(child: SignInCTA(onTap: widget.onSignInTap)),
        ],
      ),
    );
  }
}
// ==================== SPLASH FILTER SCREEN ====================

// ==================== SPLASH FILTER SCREEN ====================

class SplashFilterScreen extends StatefulWidget {
  const SplashFilterScreen({super.key});

  @override
  State<SplashFilterScreen> createState() => _SplashFilterScreenState();
}

class _SplashFilterScreenState extends State<SplashFilterScreen> {
  late final LocationProvider _locationProvider;
  final bool _isActive = true;
  final ValueNotifier<String> _selectedLocation = ValueNotifier('Nigeria');
  bool _isLoading = true;

  final List<MediaModel> _mediaItems = const [
    MediaModel(
      mainImageUrl:
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
      imageUrls: [
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
        'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800',
      ],
    ),
    MediaModel(
      mainImageUrl:
          'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800',
      imageUrls: [
        'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800',
        'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800',
      ],
      videoUrls: [
        'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
      ],
    ),
    MediaModel(
      mainImageUrl:
          'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800',
      imageUrls: [
        'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=800',
        'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _locationProvider = getIt<LocationProvider>();
    _initializeAndSync();
  }

  Future<void> signUp() async {
    await context.push(RoutePaths.signup);
    if (!mounted) return;
    if (getIt<AuthProvider>().isAuthenticated) {
      context.go(RoutePaths.home);
    }
  }

  Future<void> _initializeAndSync() async {
    await _locationProvider.initialize();
    if (mounted) {
      setState(() {
        _isLoading = false;
        final country = _locationProvider.filter.country;
        if (country != null && country.isNotEmpty) {
          _selectedLocation.value = country;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : SplashFilter(
              mediaItems: _mediaItems,
              isActive: _isActive,
              provider: _locationProvider,
              selectedLocation: _selectedLocation,
              onLocationChanged: (value) {
                if (value != null) {
                  _selectedLocation.value = value;
                  _locationProvider.setCountry(value);
                }
              },
              onExploreTap: () {
                if (_locationProvider.filter.country == null ||
                    _locationProvider.filter.country!.isEmpty) {
                  context.showSnackBar(
                    LanguageConstants.selectCountryFirst,
                    isError: true,
                  );
                  return;
                }
                context.go(RoutePaths.home);
              },
              onSignUpTap: signUp,
              onSignInTap: () => context.pushNamed(RouteNames.loginSheet),
              autoPlayInterval: const Duration(seconds: 4),
            ),
    );
  }
}

// ==================== SPLASH FILTER WIDGET ====================

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
  final ThemeProvider themeProvider;
  final VoidCallback onExplore;
  final LocationProvider? provider;
  final VoidCallback? onFilterTap;

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
    final hasCountry = provider?.filter.country?.isNotEmpty ?? false;

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
          enabled: hasCountry,
          onTap: () {
            if (!hasCountry) {
              context.showSnackBar(
                LanguageConstants.selectCountryFirst,
                isError: true,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppDimensions.blurSigma,
              sigmaY: AppDimensions.blurSigma,
            ),
            child: Material(
              color: colorScheme.surface.withValues(alpha: 0.25),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                splashColor: colorScheme.primary.withValues(alpha: 0.2),
                highlightColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingXL,
                    vertical: AppConstants.paddingM,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LanguageConstants.explore,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppConstants.space4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: colorScheme.onSurface,
                        size: AppConstants.iconM,
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

    final surfaceColor = isDark
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.4)
        : colorScheme.surface.withValues(alpha: 0.25);
    final borderColor = isDark
        ? colorScheme.outlineVariant.withValues(alpha: 0.3)
        : colorScheme.outline.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingXL),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppDimensions.blurSigma,
            sigmaY: AppDimensions.blurSigma,
          ),
          child: Container(
            // ✅ No ConstrainedBox; card sizes to content
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingL,
              vertical: AppConstants.paddingM,
            ),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Icon scales but capped
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 72),
                  child: Image.asset(
                    'icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.event_available_rounded,
                      size: 56,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.space3),
                Text(
                  LanguageConstants.appName,
                  style: textTheme.titleLarge?.copyWith(
                    // ✅ titleLarge (22) instead of headlineMedium (28)
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppConstants.space2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LanguageConstants.inLocation,
                      style: textTheme.titleSmall?.copyWith(
                        // ✅ titleSmall (14) instead of headlineSmall (24)
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppConstants.space2),
                    if (provider != null)
                      Flexible(
                        child: CountryFlagDropdownSelector(
                          provider: provider!,
                          themeProvider: themeProvider,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppConstants.space2),
                Text(
                  provider?.filter.country ?? LanguageConstants.selectACountry,
                  style: textTheme.bodyMedium?.copyWith(
                    // ✅ bodyMedium (14) instead of titleMedium (16)
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ==================== HEADER OVERLAY ====================

// ==================== SIGN UP / SIGN IN BUTTONS ====================
// ==================== SIGN UP / SIGN IN BUTTONS ====================

class SignUpCTA extends StatelessWidget {
  final VoidCallback? onPressed;

  const SignUpCTA({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed ?? () {},
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(AppConstants.buttonHeightL),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
      ),
      child: const Text(LanguageConstants.signUp),
    );
  }
}

class SignInCTA extends StatelessWidget {
  final VoidCallback onTap;

  const SignInCTA({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppConstants.buttonHeightL),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
      ),
      child: const Text(LanguageConstants.login),
    );
  }
}
