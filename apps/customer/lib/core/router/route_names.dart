// core/router/route_names.dart

abstract class RouteNames {
  // ================= SHARED =================
  static const splash = 'splash';
  static const filterSplash = 'filter-splash';
  static const loginSheet = 'customer-login';
  static const signup = 'customer-signup';

  // ================= CUSTOMER =================
  static const home = 'customer_home';
  static const viewAll = 'customer_view_all';
  static const listingDetails = 'customer_listing_details';
  static const catalog = 'customer_catalog';
  static const wallet = 'customer_wallet';
  static const media = 'customer_media';
  static const map = 'customer_map';

  // ================= CART & CHECKOUT =================
  static const cart = 'customer_cart';
  static const checkout = 'customer_checkout';
  static const inquiry = 'customer_inquiry';
  static const receipt = 'customer_receipt';
  static const receiptsList = 'customer_receipts_list';

  // ================= CUSTOMER PROFILE =================
  static const profile = 'customer_profile';
  static const profileSettings = 'customer_profile_settings';
  static const profileOrders = 'customer_profile_orders';
  static const profileFavorites = 'customer_profile_favorites';
  static const profileFollowings = 'customer_profile_followings';
  static const profilePolicies = 'customer_profile_policies';
  static const profileFriends = 'customer_profile_friends';
  static const profileNotifications = 'customer_profile_notifications';
  static const profileSupport = 'customer_profile_support';
  static const profileLocationFilters = 'profile_location_filters';

  static const chat = 'customer_chat';

  static const writeReview = 'customer_write_review';
}
