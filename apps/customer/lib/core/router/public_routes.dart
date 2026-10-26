import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/customer_splash_filter.dart';
import 'package:lehwipalancecustomerv1/modules/login_and_signup/customer_loginsheet.dart';
import 'package:lehwipalancecustomerv1/modules/login_and_signup/signup_sheet.dart';
import 'package:lehwipalancecustomerv1/widgets/bottomsheet_widget.dart';

import 'route_names.dart';
import 'route_paths.dart';

abstract final class PublicRoutes {
  static List<RouteBase> routes = [
    GoRoute(
      path: '/filtersplash',
      name: '/filtersplash',
      pageBuilder: (context, state) =>
          const MaterialPage(child: SplashFilterScreen()),
    ),

    GoRoute(
      path: RoutePaths.loginSheet,
      name: RouteNames.loginSheet,
      pageBuilder: (context, state) {
        final redirectPath = state.uri.queryParameters['redirect'];
        return BottomSheetPage(
          key: state.pageKey, // 👈 add this
          child: LoginBottomSheet(redirectPath: redirectPath),
        );
      },
    ),
    // CustomerSignupScreen
    GoRoute(
      path: RoutePaths.signup,
      name: RouteNames.signup,
      pageBuilder: (context, state) =>
          MaterialPage(child: CustomerSignupScreen()),
    ),
  ];
}

class ErrorScreen extends StatelessWidget {
  final String message;

  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
