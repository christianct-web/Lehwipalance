// scaffold_with_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/router/customer_routes.dart';
import 'package:lehwipalancecustomerv1/core/router/route_names.dart';
import 'package:lehwipalancecustomerv1/core/router/route_paths.dart';
import 'package:lehwipalancecustomerv1/modules/login_and_signup/customer_loginsheet.dart';
import 'package:lehwipalancecustomerv1/modules/widgets.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';

// scaffold_with_nav_bar.dart

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  static const int homeIndex = 0;
  static const int mediaIndex = 1;
  static const int mapIndex = 2;
  static const int ordersIndex = 3;
  static const int profileIndex = 4;

  late final AuthProvider authService;
  late final ThemeProvider _themeProvider;
  late final LocationProvider _locationProvider;

  @override
  void initState() {
    super.initState();
    authService = getIt<AuthProvider>();
    _themeProvider = getIt<ThemeProvider>();
    _locationProvider = getIt<LocationProvider>();
    NavigationService().setNavigationShell(widget.navigationShell);
  }

  @override
  void didUpdateWidget(ScaffoldWithNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.navigationShell != oldWidget.navigationShell) {
      NavigationService().setNavigationShell(widget.navigationShell);
    }
  }

  void _goBranch(int index, BuildContext context) {
    final Map<int, String> routeByIndex = {
      homeIndex: RoutePaths.home,
      mediaIndex: RoutePaths.media,
      mapIndex: RoutePaths.map,
      ordersIndex: RoutePaths.profileOrders,
      profileIndex: RoutePaths.profile,
    };
    final selectedRoute = routeByIndex[index];
    if (selectedRoute == null) return;

    final isProtectedRoute =
        index == ordersIndex || index == profileIndex || index == mapIndex;

    if (isProtectedRoute && !authService.isCustomer) {
      final redirectPath = selectedRoute.startsWith('/')
          ? selectedRoute
          : '/$selectedRoute';

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => LoginBottomSheet(redirectPath: redirectPath),
      );
      return;
    }

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _updateCache() {
    _locationProvider.activeFilter;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final isOnMap = currentIndex == mapIndex;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // ✅ Gradient App Bar
      appBar: _GradientAppBar(
        title: isOnMap ? LanguageConstants.map : LanguageConstants.appName,
        leading: CountryFlagDropdownSelector(
          themeProvider: _themeProvider,
          provider: _locationProvider,
          onCountrySelected: () {
            _locationProvider.activeFilter;
            _updateCache();
          },
          onFilterApplied: () {
            _locationProvider.activeFilter;
            _updateCache();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.pushNamed(RouteNames.profileNotifications),
            tooltip: LanguageConstants.notificationsTooltip,
            color: colorScheme.onPrimary,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.pushNamed(RouteNames.profileSettings),
            tooltip: LanguageConstants.settingsTooltip,
            color: colorScheme.onPrimary,
          ),
        ],
      ),
      body: widget.navigationShell,

      // ✅ Custom Gradient Navigation Bar
      bottomNavigationBar: _GradientNavBar(
        selectedIndex: isOnMap ? homeIndex : currentIndex,
        onDestinationSelected: (index) => _goBranch(index, context),
        destinations: const [
          _GradientNavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: LanguageConstants.home,
          ),
          _GradientNavDestination(
            icon: Icons.photo_library_outlined,
            selectedIcon: Icons.photo_library,
            label: LanguageConstants.media,
          ),
          // Empty slot for center FAB
          null,
          _GradientNavDestination(
            icon: Icons.shopping_bag_outlined,
            selectedIcon: Icons.shopping_bag,
            label: LanguageConstants.orders,
          ),
          _GradientNavDestination(
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: LanguageConstants.profile,
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _goBranch(mapIndex, context),
        backgroundColor: isOnMap
            ? colorScheme.secondaryContainer
            : colorScheme.primaryContainer,
        foregroundColor: isOnMap
            ? colorScheme.onSecondaryContainer
            : colorScheme.onPrimaryContainer,
        tooltip: LanguageConstants.mapTooltip,
        child: Icon(isOnMap ? Icons.map : Icons.map_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

// ============================================================================
// GRADIENT APP BAR
// ============================================================================

class _GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  const _GradientAppBar({required this.title, this.leading, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // ✅ Gradient uses the blueTealPurple scheme's primary → secondary
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [cs.primary, cs.secondary],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Row(
            children: [
              if (leading != null)
                SizedBox(width: 56, child: Center(child: leading)),
              Expanded(
                child: Text(
                  title,
                  textAlign: leading == null
                      ? TextAlign.center
                      : TextAlign.start,
                  style: textTheme.titleLarge?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actions != null) ...actions! else const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// GRADIENT NAVIGATION BAR
// ============================================================================

class _GradientNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _GradientNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class _GradientNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<_GradientNavDestination?> destinations;

  const _GradientNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // ✅ Gradient uses secondary → tertiary (blue → purple)
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [cs.secondary, cs.tertiary],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(destinations.length, (i) {
              final dest = destinations[i];
              if (dest == null) {
                // Empty slot for the centered FAB
                return const SizedBox(width: 64);
              }
              return Expanded(
                child: _GradientNavItem(
                  destination: dest,
                  isSelected: i == selectedIndex,
                  onTap: () => onDestinationSelected(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _GradientNavItem extends StatelessWidget {
  final _GradientNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _GradientNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // ✅ Selected state = onPrimary icon + subtle pill; unselected = translucent
    final iconColor = isSelected
        ? cs.onPrimary
        : cs.onPrimary.withValues(alpha: 0.75);
    final labelColor = isSelected
        ? cs.onPrimary
        : cs.onPrimary.withValues(alpha: 0.75);

    return InkWell(
      onTap: onTap,
      splashColor: cs.onPrimary.withValues(alpha: 0.15),
      highlightColor: cs.onPrimary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected indicator pill behind the icon
            AnimatedContainer(
              duration: AppConstants.animMedium,
              curve: AppConstants.animCurveDefault,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.onPrimary.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppConstants.radiusRound),
              ),
              child: Icon(
                isSelected ? destination.selectedIcon : destination.icon,
                size: AppConstants.iconM,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              style: textTheme.labelSmall?.copyWith(
                color: labelColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
