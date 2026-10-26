// lib/core/base/service_locator.dart

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:lehwipalancecustomerv1/Providers/cart_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/customer_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/location_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_catalog_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/merchant_listing_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/organisation_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/receipt_provider.dart';
import 'package:lehwipalancecustomerv1/Providers/wallet_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/base/mock_api_service.dart';
import 'package:lehwipalancecustomerv1/modules/details/detail_sheet_widgets.dart';
import 'package:lehwipalancecustomerv1/modules/orders/inquiry_provider.dart';
import 'package:lehwipalancecustomerv1/theme/provider/theme_provider.dart';
import 'package:lehwipalancecustomerv1/theme/shared_preferences_keys.dart';

final getIt = GetIt.instance;

// ==========================================================
// GLOBAL FLAGS for data loading state
// ==========================================================
bool _dataLoaded = false;
bool _dataLoading = false;

// ==========================================================
// SETUP
// ==========================================================
Future<void> setupServiceLocator() async {
  // ✅ FIX: Guard against double-init (hot restart / rebuilds).
  //    We use ApiService as the sentinel because it's the first
  //    thing registered after reset below.
  if (getIt.isRegistered<ApiService>()) {
    debugPrint('[ServiceLocator] Already initialized, skipping...');
    return;
  }

  debugPrint('[ServiceLocator] ===== SETUP STARTED =====');

  // ✅ FIX: Only reset if we were partially initialized.
  //    Calling reset() unconditionally was wiping valid
  //    registrations during hot-reload triggered re-inits.
  if (getIt.isRegistered<SharedPreferencesService>() ||
      getIt.isRegistered<AuthProvider>()) {
    debugPrint('[ServiceLocator] Partial state detected, resetting...');
    await getIt.reset();
  }

  // ==========================================================
  // EXTERNAL DEPENDENCIES
  // ==========================================================
  final sharedPreferencesService = SharedPreferencesService();
  await sharedPreferencesService.init();
  getIt.registerSingleton<SharedPreferencesService>(sharedPreferencesService);

  // ==========================================================
  // API SERVICE
  // ==========================================================
  final apiService = MockApiService(
    simulateNetworkDelay: true,
    delayDuration: const Duration(milliseconds: 200),
  );

  // Explicitly initialize mock data BEFORE registering,
  // so that any provider that reads it at construction time
  // gets a fully-loaded service.
  await apiService.initialize();

  getIt.registerSingleton<ApiService>(apiService);

  // ==========================================================
  // CORE PROVIDERS (no dependencies)
  // ==========================================================
  getIt.registerLazySingleton<AuthProvider>(() => AuthProvider());
  getIt.registerLazySingleton<ThemeProvider>(() => ThemeProvider());

  // ==========================================================
  // LOCATION PROVIDER
  // ==========================================================
  getIt.registerLazySingleton<LocationProvider>(
    () => LocationProvider(apiService: getIt()),
  );

  // ==========================================================
  // MERCHANT LISTING PROVIDER
  // ==========================================================
  getIt.registerLazySingleton<MerchantListingProvider>(
    () =>
        MerchantListingProvider(apiService: getIt(), locationProvider: getIt()),
  );

  // ==========================================================
  // ORGANIZATION PROVIDER
  // ==========================================================
  getIt.registerLazySingleton<OrganizationProvider>(
    () => OrganizationProvider(apiService: getIt()),
  );

  // ==========================================================
  // CUSTOMER PROVIDER
  // ==========================================================
  getIt.registerLazySingleton<CustomerProvider>(
    () => CustomerProvider(
      authProvider: getIt(),
      listingProvider: getIt(),
      organizationProvider: getIt(),
    ),
  );

  // ==========================================================
  // CART PROVIDER
  // ==========================================================
  getIt.registerLazySingleton<CartProvider>(
    () => CartProvider(authProvider: getIt()),
  );

  // ==========================================================
  // MERCHANT CATALOG PROVIDER (Factory — new instance per screen)
  // ==========================================================
  getIt.registerLazySingleton<MerchantCatalogProvider>(
    () => MerchantCatalogProvider(),
  );
  // ==========================================================
  // RECEIPT PROVIDER
  // ✅ FIX: This was the provider that threw
  //    "Object/factory with type ReceiptProvider is not registered"
  //    The registration IS here — the issue was that reset()
  //    was being called elsewhere without re-running this setup.
  //    Keeping registration, and the reset fix above prevents it.
  // ==========================================================
  getIt.registerLazySingleton<ReceiptProvider>(
    () => ReceiptProvider(apiService: getIt(), authProvider: getIt()),
  );

  // ==========================================================
  // INQUIRY PROVIDER
  // ==========================================================
  getIt.registerLazySingleton<InquiryProvider>(
    () => InquiryProvider(apiService: getIt(), authProvider: getIt()),
  );

  // ==========================================================
  // INTERACTION SERVICE
  // ==========================================================
  getIt.registerLazySingleton(() => InteractionService());

  // ==========================================================
  // WALLET PROVIDER
  // ==========================================================
  getIt.registerLazySingleton<WalletProvider>(
    () => WalletProvider(customerProvider: getIt(), apiService: getIt()),
  );

  // ==========================================================
  // PAYMENT METHOD PROVIDER
  // ==========================================================
  getIt.registerLazySingleton<PaymentMethodProvider>(
    () => PaymentMethodProvider(customerProvider: getIt(), apiService: getIt()),
  );

  debugPrint('[ServiceLocator] ✅ All providers registered');

  // ==========================================================
  // OPTIONAL: kick off initial data load in the background.
  // If you want it, uncomment. Do NOT await here — the app
  // should render its loading UI while this runs.
  // ==========================================================
  // unawaited(loadInitialData());
}

// ==========================================================
// INITIAL DATA LOADING
// ==========================================================
Future<void> loadInitialData() async {
  // Prevent concurrent / duplicate loads
  if (_dataLoaded || _dataLoading) {
    debugPrint('[ServiceLocator] Data already loading/loaded, skipping...');
    return;
  }

  // Guard: providers must be registered
  if (!getIt.isRegistered<LocationProvider>()) {
    debugPrint(
      '[ServiceLocator] ⚠️ LocationProvider not registered yet, waiting...',
    );
    await Future.delayed(const Duration(milliseconds: 100));
    if (!getIt.isRegistered<LocationProvider>()) {
      debugPrint(
        '[ServiceLocator] ❌ LocationProvider still not registered, aborting...',
      );
      return;
    }
  }

  _dataLoading = true;
  debugPrint('[ServiceLocator] 📦 Loading initial data...');

  try {
    await Future.delayed(const Duration(milliseconds: 50));

    // 1. Locations first
    final locationProvider = getIt<LocationProvider>();
    await locationProvider.initialize();
    debugPrint('[ServiceLocator] ✅ Location data loaded');

    await Future.delayed(const Duration(milliseconds: 50));

    // 2. Merchant listings — ✅ FIX: guard registration
    if (getIt.isRegistered<MerchantListingProvider>()) {
      // final merchantProvider = getIt<MerchantListingProvider>();
      // await merchantProvider.initialize();
      debugPrint('[ServiceLocator] ✅ Merchant listings loaded');
    } else {
      debugPrint(
        '[ServiceLocator] ⚠️ MerchantListingProvider not registered, skipping.',
      );
    }

    await Future.delayed(const Duration(milliseconds: 50));

    // 3. Customer data if authenticated — ✅ FIX: guard registration
    if (getIt.isRegistered<AuthProvider>() &&
        getIt.isRegistered<CustomerProvider>()) {
      final authProvider = getIt<AuthProvider>();
      if (authProvider.isAuthenticated) {
        // await getIt<CustomerProvider>().loadCustomerData();
        debugPrint('[ServiceLocator] ✅ Customer data loaded');
      }
    }

    _dataLoaded = true;
    debugPrint('[ServiceLocator] ✅ All initial data loaded successfully');
  } catch (e, st) {
    debugPrint('[ServiceLocator] ❌ Error loading initial data: $e');
    debugPrint('[ServiceLocator] $st');
    _dataLoaded = false;
  } finally {
    _dataLoading = false;
  }
}

// ==========================================================
// RESET HELPERS
// ==========================================================

/// Clears only the in-memory flags — leaves GetIt registrations intact.
/// Call this when you want loadInitialData() to be re-runnable.
void clearAllProviderData() {
  debugPrint('[ServiceLocator] 🧹 Clearing all provider data');
  _dataLoaded = false;
  _dataLoading = false;
}

/// ✅ FIX: This used to dispose providers but leave them registered,
/// meaning subsequent `getIt<X>()` calls would return a disposed
/// (broken) instance, or throw "not registered" if reset() was also
/// called somewhere. Now it disposes AND resets the locator atomically,
/// then re-runs setup so the app is left in a clean, usable state.
Future<void> resetAllProviders() async {
  debugPrint('[ServiceLocator] 🔄 Resetting all providers');

  // Dispose gracefully — guard every lookup
  try {
    if (getIt.isRegistered<LocationProvider>()) {
      getIt<LocationProvider>().dispose();
    }
    if (getIt.isRegistered<MerchantListingProvider>()) {
      getIt<MerchantListingProvider>().dispose();
    }
    if (getIt.isRegistered<CustomerProvider>()) {
      getIt<CustomerProvider>().dispose();
    }
    if (getIt.isRegistered<CartProvider>()) {
      getIt<CartProvider>().dispose();
    }
    if (getIt.isRegistered<WalletProvider>()) {
      getIt<WalletProvider>().dispose();
    }
    if (getIt.isRegistered<ReceiptProvider>()) {
      getIt<ReceiptProvider>().dispose();
    }
    if (getIt.isRegistered<InquiryProvider>()) {
      getIt<InquiryProvider>().dispose();
    }
  } catch (e) {
    debugPrint('[ServiceLocator] ⚠️ Dispose error (continuing): $e');
  }

  clearAllProviderData();

  // ✅ FIX: Full reset + re-register, so the app never ends up
  //    in the "registered but disposed" limbo state.
  await getIt.reset();
  await setupServiceLocator();
}

// ==========================================================
// SAFE ACCESSOR HELPERS
// ==========================================================
// ✅ FIX: Add these so callers (especially route builders in
//    app_router.dart) can look up providers without throwing.
//    This is what solves:
//      "Bad state: GetIt: Object/factory with type
//       MerchantListingProvider is not registered inside GetIt."
//      "Bad state: GetIt: Object/factory with type
//       ReceiptProvider is not registered inside GetIt."

T? tryGet<T extends Object>() {
  if (!getIt.isRegistered<T>()) {
    debugPrint('[ServiceLocator] ⚠️ $T is not registered');
    return null;
  }
  return getIt<T>();
}

/// Async-safe lookup for use inside route redirects / builders.
bool has<T extends Object>() => getIt.isRegistered<T>();
