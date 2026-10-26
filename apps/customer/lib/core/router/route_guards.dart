// route_guards.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_state.dart';
import 'route_paths.dart';

abstract final class RouteGuards {
  // ================= PUBLIC ROUTES =================
  static final Set<String> publicRoutes = {
    RoutePaths.splash,
    RoutePaths.home,
    RoutePaths.viewAll,
    RoutePaths.media,
    RoutePaths.loginSheet,
    RoutePaths.signup,
  };

  // ================= CUSTOMER PROTECTED ROUTES =================
  static final Set<String> customerProtectedRoutes = {
    RoutePaths.profile,
    RoutePaths.profileSettings,
    RoutePaths.profileOrders,
    RoutePaths.profileFollowings,
    RoutePaths.wallet,
    RoutePaths.profilePolicies,
    RoutePaths.profileFriends,
    RoutePaths.profileNotifications,
    RoutePaths.profileSupport,
    RoutePaths.map,
    RoutePaths.profileFavorites,
    RoutePaths.profileLocationFilters,
  };

  // ================= CACHING =================
  static final Map<String, String?> _redirectCache = {};
  static const int _maxCacheSize = 100;
  static String? _lastLocation;
  static int _redirectCount = 0;
  static const int _maxRedirects = 3;
  static DateTime? _lastRedirectTime;

  // ================= MAIN REDIRECT LOGIC =================

  static String? redirect(
    BuildContext context,
    GoRouterState state,
    AuthProvider authProvider,
  ) {
    final String location = state.matchedLocation;
    final String fullPath = state.uri.path;

    if (kDebugMode) {
      debugPrint('[RouteGuards] 📍 Checking route: $location');
      debugPrint('[RouteGuards] 📍 Full path: $fullPath');
    }

    // ================= ENHANCED LOOP DETECTION =================
    final now = DateTime.now();

    // Reset counter if more than 1 second has passed
    if (_lastRedirectTime == null ||
        now.difference(_lastRedirectTime!) > const Duration(seconds: 1)) {
      _redirectCount = 0;
      _lastRedirectTime = now;
    }

    // Check if we're in a redirect loop
    if (_lastLocation == location) {
      _redirectCount++;

      if (_redirectCount >= _maxRedirects) {
        if (kDebugMode) {
          debugPrint('[RouteGuards] ⚠️ Redirect loop detected for: $location');
          debugPrint('[RouteGuards] ⚠️ Breaking loop - returning null');
        }
        _redirectCount = 0;
        _lastLocation = null;
        _lastRedirectTime = null;
        return null;
      }

      if (kDebugMode) {
        debugPrint(
          '[RouteGuards] ⏳ Same location encountered: $location (count: $_redirectCount)',
        );
      }
    } else {
      _redirectCount = 1;
    }

    _lastLocation = location;

    // ================= AUTH LOADING =================
    final authState = authProvider.state;
    if (authState is AuthLoading || authState is AuthInitial) {
      if (kDebugMode) {
        debugPrint('[RouteGuards] ⏳ Auth loading - allowing navigation');
      }
      return null;
    }

    // ================= CHECK CACHE =================
    final String? cachedResult = _getCachedRedirect(location);
    if (cachedResult != null) {
      return cachedResult;
    }

    // ================= PERFORM REDIRECT CHECK =================
    final bool isAuthenticated = authProvider.isAuthenticated;
    final bool isCustomer = authProvider.isCustomer;
    final bool isMember = authProvider.isMember;

    if (kDebugMode) {
      debugPrint('[RouteGuards] ===== REDIRECT CHECK =====');
      debugPrint('[RouteGuards] Location: $location');
      debugPrint('[RouteGuards] Authenticated: $isAuthenticated');
      debugPrint('[RouteGuards] Is Customer: $isCustomer');
    }

    String? redirectTarget;

    // Check if it's a public route
    if (publicRoutes.contains(location)) {
      redirectTarget = _handlePublicRoute(
        location,
        isAuthenticated,
        isCustomer,
      );
    }
    // Check if it's a protected route (explicitly defined)
    else if (customerProtectedRoutes.contains(location)) {
      redirectTarget = _handleProtectedRoute(
        location,
        isAuthenticated,
        isCustomer,
        isMember,
      );
    }

    // ================= PREVENT REDIRECT TO SAME LOCATION =================
    if (redirectTarget == location) {
      if (kDebugMode) {
        debugPrint(
          '[RouteGuards] ⚠️ Redirect target same as location - returning null',
        );
      }
      _redirectCount = 0;
      _lastLocation = null;
      return null;
    }

    // ================= SPECIAL CASE: SPLASH SCREEN =================
    // If we're on the splash screen and not authenticated, don't redirect
    if (location == RoutePaths.splash && !isAuthenticated) {
      if (kDebugMode) {
        debugPrint('[RouteGuards] 🌐 On splash screen - allowing navigation');
      }
      return null;
    }

    // ================= CACHE RESULT =================
    if (redirectTarget != null && redirectTarget != location) {
      _cacheRedirect(location, redirectTarget);
    }

    return redirectTarget;
  }

  // ================= ROUTE HANDLERS =================
  // route_guards.dart - Update the _handleProtectedRoute method

  static String? _handleProtectedRoute(
    String location,
    bool isAuthenticated,
    bool isCustomer,
    bool isMember,
  ) {
    // ================= NOT AUTHENTICATED =================
    if (!isAuthenticated) {
      if (kDebugMode) {
        debugPrint('[RouteGuards] 🔒 Protected route - checking login type');
      }

      // Check if it's a customer route
      if (customerProtectedRoutes.contains(location)) {
        return RoutePaths.home;
      }

      // Fallback
      return RoutePaths.home;
    }

    // ================= AUTHENTICATED - CHECK ACCESS =================

    // Customer trying to access customer route
    if (customerProtectedRoutes.contains(location) && isCustomer) {
      if (kDebugMode) {
        debugPrint('[RouteGuards] ✅ Customer access granted to customer route');
      }
      return null;
    }
    return null;

    // ================= UNAUTHORIZED ACCESS =================
  }

  static String? _handlePublicRoute(
    String location,
    bool isAuthenticated,
    bool isCustomer,
  ) {
    // Skip splash if already authenticated
    if (location == RoutePaths.splash && isAuthenticated) {
      return RoutePaths.home; // 👈 add this
    }

    // Don't redirect from splash screen when not authenticated
    if (location == RoutePaths.splash) {
      return null;
    }

    // Redirect authenticated users away from login/signup
    if (isAuthenticated) {
      // Customer login sheet
      if (location == RoutePaths.loginSheet) {
        if (isCustomer) {
          if (kDebugMode) {
            debugPrint(
              '[RouteGuards] 👤 Customer on login sheet - redirecting to home',
            );
          }
          return RoutePaths.home;
        }
      }

      // Customer signup
      if (location == RoutePaths.signup) {
        if (isCustomer) {
          return RoutePaths.home;
        }
      }
    }

    return null;
  }

  // ================= CACHE MANAGEMENT =================

  static String? _getCachedRedirect(String location) {
    if (_redirectCache.containsKey(location)) {
      final result = _redirectCache[location];
      if (kDebugMode) {
        debugPrint('[RouteGuards] 📦 Cache hit for: $location -> $result');
      }
      return result;
    }
    return null;
  }

  static void _cacheRedirect(String location, String? target) {
    if (target == null || target == location) {
      _redirectCache.remove(location);
      return;
    }

    if (_redirectCache.length >= _maxCacheSize) {
      final firstKey = _redirectCache.keys.first;
      _redirectCache.remove(firstKey);
    }
    _redirectCache[location] = target;
  }

  static void clearCache() {
    _redirectCache.clear();
    _lastLocation = null;
    _redirectCount = 0;
    _lastRedirectTime = null;
    if (kDebugMode) {
      debugPrint('[RouteGuards] 🗑️ Cache cleared');
    }
  }

  // ================= ROUTE CHECK METHODS =================

  static bool isPublicRoute(String location) {
    return publicRoutes.contains(location);
  }

  static bool isProtectedRoute(String location) {
    return customerProtectedRoutes.contains(location);
  }

  static bool isCustomerRoute(String location) {
    return customerProtectedRoutes.contains(location);
  }
}
