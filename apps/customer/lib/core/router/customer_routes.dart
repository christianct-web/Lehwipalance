import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/core/base/provider_groups.dart';
import 'package:lehwipalancecustomerv1/core/router/public_routes.dart';
import 'package:lehwipalancecustomerv1/core/router/route_names.dart';
import 'package:lehwipalancecustomerv1/core/router/route_paths.dart';
import 'package:lehwipalancecustomerv1/customer_navbar.dart';
import 'package:lehwipalancecustomerv1/enum.dart';
import 'package:lehwipalancecustomerv1/modules/cart/catolog_screen.dart';
import 'package:lehwipalancecustomerv1/modules/cart/event_cart.dart';
import 'package:lehwipalancecustomerv1/modules/details/listing_detail_sheet_screen.dart';
import 'package:lehwipalancecustomerv1/modules/following/following_screen.dart';
import 'package:lehwipalancecustomerv1/modules/home/home_page.dart';
import 'package:lehwipalancecustomerv1/modules/location/suscribed_cities_page.dart';
import 'package:lehwipalancecustomerv1/modules/map/screen/map_screen.dart';
import 'package:lehwipalancecustomerv1/modules/orders/orders_screen.dart';
import 'package:lehwipalancecustomerv1/modules/profile/customer_profile_page.dart';
import 'package:lehwipalancecustomerv1/modules/profile/favorites_page.dart';
import 'package:lehwipalancecustomerv1/modules/reels/media_screen.dart';
import 'package:lehwipalancecustomerv1/modules/settings/friends_screen.dart';
import 'package:lehwipalancecustomerv1/modules/settings/notification_screen.dart';
import 'package:lehwipalancecustomerv1/modules/settings/policies_support/polcies_screen.dart';
import 'package:lehwipalancecustomerv1/modules/settings/policies_support/support_screen.dart';
import 'package:lehwipalancecustomerv1/modules/settings/settings_screen.dart';
import 'package:lehwipalancecustomerv1/modules/wallet/wallet_screen.dart';
//import 'package:lehwipalancecustomerv1/widgets/bottomsheet_widget.dart';

// core/router/customer_routes.dart

// Screens
import 'package:lehwipalancecustomerv1/modules/cart/checkout_screen.dart';
import 'package:lehwipalancecustomerv1/modules/cart/inquiries_page.dart';
import 'package:lehwipalancecustomerv1/modules/orders/receipt_screen.dart';

abstract final class CustomerRoutes {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static StatefulShellRoute routes = StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      return CustomerDashboardProviders(
        child: ScaffoldWithNavBar(navigationShell: navigationShell),
      );
    },
    branches: [
      // ============================================================
      // 0 - HOME BRANCH (Public)
      // ============================================================
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: RoutePaths.home, // '/home'
            name: RouteNames.home,
            builder: (context, state) => const HomePage(),
            routes: [
              // --- Listing details bottom sheet ---
              GoRoute(
                path: RoutePaths.listingDetails,
                name: RouteNames.listingDetails,
                pageBuilder: (context, state) {
                  final listingId = state.pathParameters['listingId'] ?? '';
                  return MaterialPage<void>(
                    child: ListingDetailSheetScreen(
                      listingId: listingId,
                      //  listingType: type,
                      onDismissed: () {
                        if (context.canPop()) context.pop();
                      },
                    ),
                  );
                },
                routes: [
                  // --- Catalog (nested under listing cover) ---
                  GoRoute(
                    path: RoutePaths.catalog, // 'catalog'
                    name: RouteNames.catalog,
                    builder: (context, state) {
                      // Inherits :listingId from parent
                      final listingId = state.pathParameters['listingId'];
                      if (listingId == null) {
                        return const ErrorScreen(
                          message: 'Listing ID not found',
                        );
                      }
                      return CatalogScreen(merchantId: listingId);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ============================================================
      // 1 - MEDIA BRANCH (Public)
      // ============================================================
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: RoutePaths.media, // '/media'
            name: RouteNames.media,
            builder: (context, state) => const MediaFeedScreen(),
          ),
        ],
      ),

      // ============================================================
      // 2 - MAP BRANCH (Protected)
      // ============================================================
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: RoutePaths.map, // '/map'
            name: RouteNames.map,
            builder: (context, state) {
              final qp = state.uri.queryParameters;

              final locationId = qp['initialLocationId'];
              final listingTypeName = qp['initialListingType'];
              final lat = double.tryParse(qp['lat'] ?? '');
              final lng = double.tryParse(qp['lng'] ?? '');

              ListingType? listingType;
              if (listingTypeName != null) {
                listingType = ListingType.values.firstWhere(
                  (t) => t.name == listingTypeName,
                  orElse: () => ListingType.values.first,
                );
              }

              return MerchantMapScreen(
                initialLocationId: locationId,
                initialListingType: listingType,
                initialLat: lat,
                initialLng: lng,
              );
            },
          ),
        ],
      ),
      // ============================================================
      // 3 - CART BRANCH (was Orders — now hosts cart + orders + receipts)
      // ============================================================
      StatefulShellBranch(
        routes: [
          // Cart home
          GoRoute(
            path: RoutePaths.cart, // '/cart'
            name: RouteNames.cart,
            builder: (context, state) => const CartScreen(),
            routes: [
              // Checkout
              GoRoute(
                path: RoutePaths.checkout, // 'checkout'
                name: RouteNames.checkout,
                builder: (context, state) {
                  // Accept userId / merchantId / organisationId via `extra`
                  final extra = state.extra;
                  final Map<String, dynamic> data =
                      extra is Map<String, dynamic> ? extra : const {};
                  return CheckoutScreen(
                    userId: data['userId'] as String? ?? '',
                    merchantId: data['merchantId'] as String?,
                    organisationId: data['organisationId'] as String?,
                  );
                },
              ),

              // Inquiry
              GoRoute(
                path: RoutePaths.inquiry, // 'inquiry'
                name: RouteNames.inquiry,
                builder: (context, state) => const InquiryScreen(),
              ),
            ],
          ),

          // Orders / receipts list (was the top-level of branch 3)
          GoRoute(
            path: RoutePaths.profileOrders, // '/orders'
            name: RouteNames.profileOrders,
            builder: (context, state) => const CustomerOrders(),
            routes: [
              // Receipt detail (or nested receipt screen)
              GoRoute(
                path: RoutePaths.receiptsList, // 'receipts'
                name: RouteNames.receiptsList,
                builder: (context, state) => const CustomerOrders(),
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.receipt,
            name: RouteNames.receipt,
            builder: (context, state) {
              final receiptId = state.pathParameters['receiptId'];
              if (receiptId == null) {
                return const ErrorScreen(message: 'Receipt ID missing');
              }
              return ReceiptScreen(receiptId: receiptId);
            },
          ),
        ],
      ),

      // ============================================================
      // 4 - PROFILE BRANCH (Protected)
      // ============================================================
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: RoutePaths.profile, // '/profile'
            name: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: RoutePaths.profileLocationFilters, // 'location-filters'
                name: RouteNames.profileLocationFilters,
                builder: (context, state) =>
                    const LocationFilterPreferencePage(),
              ),
              GoRoute(
                path: RoutePaths.profileSettings, // 'settings'
                name: RouteNames.profileSettings,
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: RoutePaths.profileFavorites, // 'favorites'
                name: RouteNames.profileFavorites,
                builder: (context, state) => const FavoritesPage(),
              ),
              GoRoute(
                path: RoutePaths.profileFollowings, // 'followings'
                name: RouteNames.profileFollowings,
                builder: (context, state) => const FollowingsScreen(),
              ),
              GoRoute(
                path: RoutePaths.wallet, // 'wallet'
                name: RouteNames.wallet,
                builder: (context, state) => const WalletScreen(),
              ),
              GoRoute(
                path: RoutePaths.profilePolicies, // 'policies'
                name: RouteNames.profilePolicies,
                builder: (context, state) => const PoliciesScreen(),
              ),
              GoRoute(
                path: RoutePaths.profileFriends, // 'friends'
                name: RouteNames.profileFriends,
                builder: (context, state) => const FriendsScreen(),
              ),
              GoRoute(
                path: RoutePaths.profileNotifications, // 'notifications'
                name: RouteNames.profileNotifications,
                builder: (context, state) => const NotificationSettingsScreen(),
              ),
              GoRoute(
                path: RoutePaths.profileSupport, // 'support'
                name: RouteNames.profileSupport,
                builder: (context, state) => const SupportScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ============================================================
// NAVIGATION SERVICE
// ============================================================
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  StatefulNavigationShell? _navigationShell;

  void setNavigationShell(StatefulNavigationShell shell) {
    _navigationShell = shell;
  }

  void switchToTab(int index) {
    if (_navigationShell != null) {
      _navigationShell!.goBranch(
        index,
        initialLocation: _navigationShell!.currentIndex == index,
      );
    }
  }

  // Branch indices (matched to branches above)
  void switchToHomeTab() => switchToTab(0);
  void switchToMediaTab() => switchToTab(1);
  void switchToMapTab() => switchToTab(2);
  void switchToCartTab() => switchToTab(3);
  void switchToOrdersTab() => switchToTab(3); // Same branch as cart
  void switchToProfileTab() => switchToTab(4);

  StatefulNavigationShell? get navigationShell => _navigationShell;
}
