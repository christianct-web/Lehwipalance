// core/router/route_paths.dart

abstract class RoutePaths {
  // ================= SHARED PATHS =================
  static const splash = '/filtersplash';
  static const loginSheet = '/customer_login';
  static const signup = '/customer-signup';

  // ================= CUSTOMER PATHS =================
  static const home = '/home';
  static const viewAll = 'view-all/:categoryType';
  static const listingDetails = 'listing-details/:listingId';
  static const catalog = 'catalog';
  static const media = '/media';
  static const map = '/map';

  // ================= CART & CHECKOUT PATHS =================
  static const cart = '/cart';
  static const checkout = 'checkout';
  static const inquiry = 'inquiry';
  static const receipt = 'receipt/:receiptId';
  static const receiptsList = 'receipts';

  // ================= CUSTOMER PROFILE NESTED PATHS =================
  static const profile = '/profile';
  static const profileSettings = 'settings';
  static const profileOrders = '/orders';
  static const profileFavorites = 'favorites';
  static const profileFollowings = 'followings';
  static const profilePolicies = 'policies';
  static const profileFriends = 'friends';
  static const profileNotifications = 'notifications';
  static const profileSupport = 'support';
  static const profileLocationFilters = 'location-filters';
  static const wallet = 'wallet';
}
