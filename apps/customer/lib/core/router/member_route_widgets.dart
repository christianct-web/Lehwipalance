// core/router/navigation_helpers.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lehwipalancecustomerv1/core/router/route_names.dart';

// ================= CUSTOMER NAVIGATION HELPERS =================

class CustomerNavigation {
  static void navigateToHome(BuildContext context) {
    context.goNamed(RouteNames.home);
  }

  static void navigateToMedia(BuildContext context) {
    context.goNamed(RouteNames.media);
  }

  static void navigateToMap(BuildContext context) {
    context.goNamed(RouteNames.map);
  }

  static void navigateToProfile(BuildContext context) {
    context.goNamed(RouteNames.profile);
  }

  static void navigateToFavorites(BuildContext context) {
    context.goNamed(RouteNames.profileFavorites);
  }

  static void navigateToOrders(BuildContext context) {
    context.goNamed(RouteNames.profileOrders);
  }

  static void navigateToWallet(BuildContext context) {
    context.goNamed(RouteNames.wallet);
  }

  static void navigateToListingDetails(
    BuildContext context, {
    required String listingId,
    String? type,
  }) {
    final Map<String, dynamic> queryParams = {};
    if (type != null) {
      queryParams['type'] = type;
    }
    context.pushNamed(
      RouteNames.listingDetails,
      pathParameters: {'listingId': listingId},
    );
  }

  static void navigateToCatalog(
    BuildContext context, {
    required String listingId,
  }) {
    context.pushNamed(
      RouteNames.catalog,
      pathParameters: {'listingId': listingId},
      queryParameters: const {},
    );
  }

  static void navigateToProfileSettings(BuildContext context) {
    context.pushNamed(RouteNames.profileSettings, queryParameters: const {});
  }

  static void navigateToProfileFollowings(BuildContext context) {
    context.pushNamed(RouteNames.profileFollowings, queryParameters: const {});
  }

  static void navigateToProfileFriends(BuildContext context) {
    context.pushNamed(RouteNames.profileFriends, queryParameters: const {});
  }

  static void navigateToPolicies(BuildContext context) {
    context.pushNamed(RouteNames.profilePolicies, queryParameters: const {});
  }

  static void navigateToSupport(BuildContext context) {
    context.pushNamed(RouteNames.profileSupport, queryParameters: const {});
  }

  static void navigateToNotifications(BuildContext context) {
    context.pushNamed(
      RouteNames.profileNotifications,
      queryParameters: const {},
    );
  }

  static void navigateToLocationFilters(BuildContext context) {
    context.pushNamed(
      RouteNames.profileLocationFilters,
      queryParameters: const {},
    );
  }
}

extension NavigationExtension on BuildContext {
  // Customer
  void goToHome() => CustomerNavigation.navigateToHome(this);
  void goToMedia() => CustomerNavigation.navigateToMedia(this);
  void goToMap() => CustomerNavigation.navigateToMap(this);
  void goToProfile() => CustomerNavigation.navigateToProfile(this);
  void goToFavorites() => CustomerNavigation.navigateToFavorites(this);
  void goToOrders() => CustomerNavigation.navigateToOrders(this);
  void goToWallet() => CustomerNavigation.navigateToWallet(this);
  void goToListingDetails({required String listingId, String? type}) =>
      CustomerNavigation.navigateToListingDetails(
        this,
        listingId: listingId,
        type: type,
      );

  void goToCatalog({required String listingId}) =>
      CustomerNavigation.navigateToCatalog(this, listingId: listingId);
  void goToProfileSettings() =>
      CustomerNavigation.navigateToProfileSettings(this);
  void goToProfileFollowings() =>
      CustomerNavigation.navigateToProfileFollowings(this);
  void goToProfileFriends() =>
      CustomerNavigation.navigateToProfileFriends(this);
  void goToPolicies() => CustomerNavigation.navigateToPolicies(this);
  void goToSupport() => CustomerNavigation.navigateToSupport(this);
  void goToNotifications() => CustomerNavigation.navigateToNotifications(this);
  void goToLocationFilters() =>
      CustomerNavigation.navigateToLocationFilters(this);
}
