import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/provider_groups.dart';
import 'package:lehwipalancecustomerv1/core/router/app_router.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/model/themes.dart'; // AppTheme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // STEP 1: Initialize everything FIRST
  try {
    // Setup service locator (this will initialize mock data)
    await setupServiceLocator();

    // Get providers from service locator
    final authProvider = getIt<AuthProvider>();
    final themeProvider = getIt<ThemeProvider>();

    // Create router
    final router = AppRouter.createRouter(authProvider);

    // STEP 2: Run the app with all dependencies
    runApp(
      MyApp(
        authProvider: authProvider,
        themeProvider: themeProvider,
        router: router,
      ),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
    // Show error screen if initialization fails
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                Text('Error loading app: $e'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== MAIN APP ====================

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;
  final GoRouter router;

  const MyApp({
    super.key,
    required this.authProvider,
    required this.themeProvider,
    required this.router,
  });

  @override
  Widget build(BuildContext context) {
    return CoreProviders(
      child: ListenableBuilder(
        // ✅ Use ListenableBuilder — ThemeProvider IS a ChangeNotifier,
        //    so Consumer<ThemeProvider> only works if you registered it
        //    as a Provider too. ListenableBuilder works regardless.
        listenable: themeProvider,
        builder: (context, _) {
          return MaterialApp.router(
            title: LanguageConstants.appName,
            debugShowCheckedModeBanner: false,

            // ✅ Use the theme from ThemeProvider — this pulls from
            //    AppTheme.lightTheme(fontFamily) → ColorSchemes.getLightScheme
            //    → ColorSchemeType.blueTealPurple
            theme: AppTheme.lightTheme(themeProvider.fontFamilyType),
            darkTheme: AppTheme.darkTheme(themeProvider.fontFamilyType),

            themeMode: themeProvider.themeMode,
            routerConfig: router,

            // Optional: locale support
            locale: themeProvider.locale,
            supportedLocales: const [
              Locale('en', 'US'),
              Locale('es', 'ES'),
              Locale('fr', 'FR'),
            ],
          );
        },
      ),
    );
  }
}
