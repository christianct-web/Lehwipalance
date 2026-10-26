import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';

import 'customer_routes.dart';
import 'public_routes.dart';
import 'route_guards.dart';
import 'route_paths.dart';

// app_router.dart
abstract final class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: RoutePaths.splash,
      debugLogDiagnostics: true, // Set to false in production
      refreshListenable: authProvider,
      redirect: (context, state) =>
          RouteGuards.redirect(context, state, authProvider),
      errorBuilder: (context, state) {
        return Scaffold(
          body: Center(child: Text('Error: ${state.error.toString()}')),
        );
      },
      routes: [...PublicRoutes.routes, CustomerRoutes.routes],
    );
  }
}
