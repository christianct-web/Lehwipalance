import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // ─────────────────────────────────────────────────────────────
  // App Info
  // ─────────────────────────────────────────────────────────────
  // Navigation & Shell
  static const String home = 'Home';
  static const String media = 'Media';
  static const String orders = 'Orders';
  static const String profile = 'Profile';
  static const String map = 'Map';
  static const String explore = 'Explore';
  static const String welcome = 'Welcome to';

  // Splash / Onboarding
  static const String selectCountryFirst = 'Please select a country first';
  static const String selectACountry = 'Select a country';
  static const String chooseCountry = 'Choose your country';
  static const String brokenImage = 'Image unavailable';

  // Tooltips
  static const String notificationsTooltip = 'Notifications';
  static const String settingsTooltip = 'Settings';
  static const String mapTooltip = 'Map';
  // ─────────────────────────────────────────────────────────────
  // Feature Flags
  // ─────────────────────────────────────────────────────────────
  static const bool enableDarkMode = true;
  static const bool enableMultiLanguage = true;
  static const bool enableOfflineMode = true;

  // ─────────────────────────────────────────────────────────────
  // API
  // ─────────────────────────────────────────────────────────────
  static const String apiBaseUrl = 'https://api.yourdomain.com';
  static const int apiTimeout = 30000;

  // ────────────────────────────────────────────────
  // SPACING SYSTEM
  // ────────────────────────────────────────────────
  static const double space1 = 2.0; // Tiny
  static const double space2 = 4.0; // Extra small
  static const double space3 = 6.0; // Small
  static const double space4 = 8.0; // Medium small
  static const double space5 = 12.0; // Medium
  static const double space6 = 16.0; // Medium large
  static const double space7 = 20.0; // Large
  static const double space8 = 24.0; // Extra large

  // Semantic aliases
  static const double paddingXS = space2; // 4
  static const double paddingS = space4; // 8
  static const double paddingM = space6; // 16
  static const double paddingL = space7; // 20
  static const double paddingXL = space8; // 24
  static const double paddingXXL = 32.0; // Special cases

  static const double marginXS = space2;
  static const double marginS = space4;
  static const double marginM = space6;
  static const double marginL = space7;
  static const double marginXL = space8;
  static const double marginXXL = 32.0;

  static const double itemGap = space3; // 6
  static const double sectionGap = space5; // 12

  // ────────────────────────────────────────────────
  // BORDER RADIUS
  // ────────────────────────────────────────────────
  static const double radiusXS = 4.0;
  static const double radiusS = 6.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusRound = 999;

  // ────────────────────────────────────────────────
  // ICON SIZES
  // ────────────────────────────────────────────────
  static const double iconXS = 14.0;
  static const double iconS = 18.0; // Standard
  static const double iconM = 22.0;
  static const double iconL = 28.0;
  static const double iconXL = 36.0;

  // ────────────────────────────────────────────────
  // BUTTON HEIGHTS
  // ────────────────────────────────────────────────
  static const double buttonHeightXS = 28.0;
  static const double buttonHeightS = 36.0;
  static const double buttonHeightM = 44.0;
  static const double buttonHeightL = 52.0;

  // ────────────────────────────────────────────────
  // ELEVATION
  // ────────────────────────────────────────────────
  static const double elevationS = 1.0;
  static const double elevationM = 2.0;
  static const double elevationL = 3.0;
  static const double elevationXL = 6.0;

  // ────────────────────────────────────────────────
  // ANIMATIONS
  // ────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 100);
  static const Duration animMedium = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 400);

  static const Curve animCurveDefault = Curves.easeInOut;
  static const Curve animCurveElegant = Curves.fastOutSlowIn;
  static const Curve animCurveSnappy = Curves.easeOutBack;

  // ────────────────────────────────────────────────
  // LAYOUT CONSTRAINTS
  // ────────────────────────────────────────────────
  static const double maxContentWidth = 600.0;
  static const double maxDialogWidth = 400.0;
  static const double sidebarWidth = 280.0;
  static const double bottomBarHeight = 56.0;

  // ────────────────────────────────────────────────
  // GRID SYSTEM
  // ────────────────────────────────────────────────
  static const int gridColumnsMobile = 2;
  static const int gridColumnsTablet = 3;
  static const int gridColumnsDesktop = 4;
  static const int productGridColumns = 2;
  static const double productCardAspectRatio = 0.75;

  // ────────────────────────────────────────────────
  // PLACEHOLDERS
  // ────────────────────────────────────────────────
  static const String placeholderImage = 'asset/image/explore_3.jpg';
  static const String placeholderUserImage =
      'https://avatars.githubusercontent.com/u/17293422?v=4';

  // ────────────────────────────────────────────────
  // ANIMATION DURATIONS (Alternative names)
  // ────────────────────────────────────────────────
  static const Duration animationDurationS = Duration(milliseconds: 150);
  static const Duration animationDurationM = Duration(milliseconds: 300);
  static const Duration animationDurationL = Duration(milliseconds: 500);
}

class LanguageConstants {
  LanguageConstants._();

  // ═════════════════════════════════════════════════════════════
  // 1. APP INFO
  // ═════════════════════════════════════════════════════════════
  static const String appName = 'Lehwi Palance';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Event management and booking app';
  static const String appInfo = 'App Information';

  // ═════════════════════════════════════════════════════════════
  // 2. GENERAL ACTIONS (buttons, verbs)
  // ═════════════════════════════════════════════════════════════
  static const String login = 'Login';
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String logout = 'Logout';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String share = 'Share';
  static const String bookmark = 'Bookmark';
  static const String save = 'Save';
  static const String saved = 'Saved';
  static const String follow = 'Follow';
  static const String following = 'Following';
  static const String call = 'Call';
  static const String chat = 'Chat';
  static const String directions = 'Directions';
  static const String website = 'Website';
  static const String bookNow = 'Book Now';
  static const String buyTickets = 'Buy Tickets';
  static const String reserve = 'Reserve';
  static const String confirm = 'Confirm';
  static const String proceed = 'Proceed';
  static const String next = 'Next';
  static const String previous = 'Previous';
  static const String done = 'Done';
  static const String close = 'Close';
  static const String skip = 'Skip';
  static const String finish = 'Finish';
  static const String cancel = 'Cancel';
  static const String clear = 'Clear';
  static const String reset = 'Reset';
  static const String refresh = 'Refresh';
  static const String retry = 'Retry';
  static const String tryAgain = 'Try Again';
  static const String viewAll = 'View All';
  static const String viewDetails = 'View Details';
  static const String editDetails = 'Edit Details';
  static const String search = 'Search';
  static const String max = 'Max';

  // ═════════════════════════════════════════════════════════════
  // 3. NAVIGATION & TABS
  // ═════════════════════════════════════════════════════════════
  static const String home = 'Home';
  static const String explore = 'Explore';
  static const String media = 'Media';
  static const String orders = 'Orders';
  static const String profile = 'Profile';
  static const String map = 'Map';
  static const String calendar = 'Calendar';
  static const String notifications = 'Notifications';
  static const String settings = 'Settings';
  static const String support = 'Support';
  static const String discover = 'Discover';
  static const String welcome = 'Welcome';

  // Tooltips
  static const String mapTooltip = 'Map';
  static const String notificationsTooltip = 'Notifications';
  static const String settingsTooltip = 'Settings';
  static const String closeCalendar = 'Close Calendar';

  // ═════════════════════════════════════════════════════════════
  // 4. HOME TABS & SECTIONS
  // ═════════════════════════════════════════════════════════════
  static const String forYou = 'For You';
  static const String eventsTab = 'Events';
  static const String placesTab = 'Places';
  static const String hotelsTab = 'Hotels';
  static const String servicesTab = 'Services';
  static const String storesTab = 'Stores';
  static const String vacationsTab = 'Vacations';
  static const String favoritesTab = 'Favorites';

  // For You sections
  static const String featured = 'Featured';
  static const String happeningNearYou = 'Happening Near You';
  static const String popularPlaces = 'Popular Places';
  static const String recommendedServices = 'Recommended Services';
  static const String featuredOrganizations = 'Featured Organizations';
  static const String nothingToDiscover = 'Nothing to discover yet';
  static const String recentlyViewed = 'Recently Viewed';
  static const String clearHistory = 'Clear History';

  // Home page labels
  static const String inLocation = 'in';
  static const String events = 'Events';
  static const String accommodations = 'Accommodations';
  static const String places = 'Places';
  static const String organizers = 'Organizers';
  static const String influencers = 'Influencers';

  // ═════════════════════════════════════════════════════════════
  // 5. AUTHENTICATION
  // ═════════════════════════════════════════════════════════════
  // Welcome / Onboarding
  static const String welcomeToPalance = 'Welcome to Palance';
  static const String discoverAmazingExperiences =
      'Discover amazing experiences';
  static const String welcomeBack = 'Welcome back';
  static const String createAccount = 'Create Account';
  static const String signInToContinue = 'Sign in to continue';
  static const String enterCredentials = 'Enter your credentials to continue';
  static const String experience = 'Experience';
  static const String experienceDesc =
      'Discover amazing events and experiences while you sign in to your account.';
  static const String gotIt = 'Got it';

  // Auth form
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String continueAsGuest = 'Continue as Guest';
  static const String orContinueWith = 'Or continue with';
  static const String google = 'Google';
  static const String apple = 'Apple';
  static const String dontHaveAccount = "Don't have an account?";

  // Auth validation
  static const String enterEmail = 'Please enter your email';
  static const String validEmail = 'Please enter a valid email';
  static const String enterPassword = 'Please enter your password';
  static const String passwordLength = 'Password must be at least 6 characters';

  // Login bottom sheet
  static const String loginRequired = 'Login Required';
  static const String loginToContinueTo = 'Login to continue to';
  static const String pleaseLoginToContinue = 'Please login to continue';
  static const String emailOptional = 'Email (optional)';
  static const String passwordOptional = 'Password (optional)';
  static const String leaveBlankAutoLogin = 'Leave blank for auto-login';
  static const String signingIn = 'Signing In...';
  static const String autoLoginAsCustomer = 'Auto Login as Customer';
  static const String loginSuccess = 'Login successful!';
  static const String loginFailed = 'Login failed';
  static const String loginFailedRetry = 'Login failed. Please try again.';
  static const String registrationFailed = 'Registration failed';

  // ═════════════════════════════════════════════════════════════
  // 6. SPLASH / ONBOARDING / LOCATION PICKER
  // ═════════════════════════════════════════════════════════════
  static const String selectCountryFirst = 'Please select a country first';
  static const String selectACountry = 'Select a country';
  static const String chooseCountry = 'Choose your country';
  static const String brokenImage = 'Image unavailable';

  // Location dropdown
  static const String unitedStates = 'United States';
  static const String unitedKingdom = 'United Kingdom';
  static const String canada = 'Canada';
  static const String australia = 'Australia';
  static const String germany = 'Germany';
  static const String france = 'France';
  static const String japan = 'Japan';
  static const String trinidadTobago = 'Trinidad and Tobago';

  // ═════════════════════════════════════════════════════════════
  // 7. FAVORITES
  // ═════════════════════════════════════════════════════════════
  static const String savedFavoritesSubtitle = 'Here are your saved favorites';
  static const String yourFavorites = 'Your Favorites';
  static const String organizationsYouFollow = 'Organizations You Follow';
  static const String signInToSeeFavorites = 'Sign in to see your favorites';
  static const String signInToSeeFavoritesDesc =
      'Save your favorite places, events, hotels, and services.';
  static const String noFavoritesYet = 'No favorites yet';
  static const String noFavoritesYetDesc =
      'Start exploring and save places you love.';
  static const String startExploring = 'Start Exploring';

  // ═════════════════════════════════════════════════════════════
  // 8. LISTINGS (Detail, Info, Media, Reviews)
  // ═════════════════════════════════════════════════════════════
  static const String listingNotFound = 'Listing not found';
  static const String infoTab = 'Info';
  static const String mediaTab = 'Media';
  static const String reviewsTab = 'Reviews';

  // About / description
  static const String about = 'About';
  static const String noDescriptionAvailable = 'No description available.';
  static const String date = 'Date';
  static const String endDate = 'End Date';
  static const String available = 'available';
  static const String from = 'from';
  static const String rooms = 'rooms';
  static const String facilities = 'Facilities';
  static const String entryFee = 'Entry Fee';
  static const String free = 'Free';
  static const String bookingRequired = 'Booking Required';
  static const String yes = 'Yes';
  static const String no = 'No';

  // Media / reviews
  static const String noMediaAvailable = 'No media available';
  static const String reviews = 'reviews';
  static const String noReviewsYet = 'No reviews yet';
  static const String writeReview = 'Write a Review';
  static const String actionTriggered = 'action triggered';

  // Location / website availability
  static const String locationIsUnavailable = 'Location is unavailable.';
  static const String websiteIsUnavailable = 'Website is unavailable.';
  static const String locationNotSpecified = 'Location not specified';

  // ═════════════════════════════════════════════════════════════
  // 9. OPERATING HOURS
  // ═════════════════════════════════════════════════════════════
  static const String operatingHours = 'Operating Hours';
  static const String weeklySchedule = 'Weekly Schedule';
  static const String specialHours = 'Special Hours';
  static const String notSpecified = 'Not specified';
  static const String closed = 'Closed';
  static const String open24Hours = 'Open 24 hours';
  static const String openNow = 'Open Now';
  static const String closedNow = 'Closed Now';
  static const String closes = 'Closes';
  static const String opens = 'Opens';
  static const String closedToday = 'Closed today';
  static const String unknown = 'Unknown';

  // Weekdays
  static const String monday = 'Monday';
  static const String tuesday = 'Tuesday';
  static const String wednesday = 'Wednesday';
  static const String thursday = 'Thursday';
  static const String friday = 'Friday';
  static const String saturday = 'Saturday';
  static const String sunday = 'Sunday';

  // ═════════════════════════════════════════════════════════════
  // 10. SEARCH & FILTERS
  // ═════════════════════════════════════════════════════════════
  static const String filtersTitle = 'Filters';
  static const String filter = 'Filter';
  static const String filtersApplied = 'Filters applied';
  static const String activeFilters = 'Active Filters';
  static const String noActiveFilters = 'No active filters';
  static const String applyFilters = 'Apply Filters';
  static const String resetFilters = 'Reset Filters';
  static const String resetAll = 'Reset All';
  static const String clearAllFilters = 'Clear all filters';
  static const String clearLocationFilter = 'Clear Location Filter';

  // Search placeholders
  static const String searchListings = 'Search listings...';
  static const String searchByNameCityCountry =
      'Search by name, city, or country...';
  static const String searchByTitleDescription =
      'Search by title, description...';
  static const String searchEvents = 'Search events...';
  static const String searchLocation = 'Search Location';
  static const String searchPlaces = 'Search places...';
  static const String searchHotels = 'Search hotels...';
  static const String searchServices = 'Search services...';
  static const String searchStores = 'Search stores...';
  static const String searchVacations = 'Search vacations...';
  static const String searchFavorites = 'Search favorites...';

  // Location filter
  static const String location = 'Location';
  static const String myLocation = 'My Location';
  static const String filterByMyLocation = 'Filter by my location';
  static const String filterByLocation = 'Filter by Location';
  static const String locationNotAvailable = 'Location not available';
  static const String locationError = 'Location error';
  static const String distanceRadius = 'Distance Radius';
  static const String radius = 'Radius';
  static const String distance = 'Distance';

  // Country / state / city
  static const String country = 'Country';
  static const String allCountries = 'All Countries';
  static const String stateProvince = 'State/Province';
  static const String allStates = 'All States';
  static const String city = 'City';
  static const String allCities = 'All Cities';

  // Type / date / status filters
  static const String listingTypes = 'Listing Types';
  static const String listingType = 'Listing Type';
  static const String typeLabel = 'Type';
  static const String allTypes = 'All Types';
  static const String dateRange = 'Date Range';
  static const String selectDateRange = 'Select date range';
  static const String fromLabel = 'From';
  static const String toLabel = 'To';
  static const String activeOnly = 'Active Only';
  static const String activeListingsOnly = 'Active Listings Only';
  static const String listings = 'Listings';
  static const String noListingsFound = 'No listings found';

  // Sort
  static const String sortBy = 'Sort By';
  static const String priceLowToHigh = 'Price: Low to High';
  static const String priceHighToLow = 'Price: High to Low';
  static const String newestFirst = 'Newest First';
  static const String oldestFirst = 'Oldest First';
  static const String rating = 'Rating';
  static const String popularity = 'Popularity';

  // ═════════════════════════════════════════════════════════════
  // 11. EVENT DETAILS
  // ═════════════════════════════════════════════════════════════
  static const String eventDetails = 'Event Details';
  static const String dateAndTime = 'Date & Time';
  static const String organizer = 'Organizer';
  static const String tickets = 'Tickets';
  static const String availableTickets = 'Available Tickets';
  static const String soldOut = 'Sold Out';
  static const String limitedAvailability = 'Limited Availability';
  static const String paid = 'Paid';
  static const String startingFrom = 'Starting from';
  static const String followers = 'Followers';
  static const String findingNearbyEvents = 'Finding events near you...';
  static const String noMoreEvents = 'No more events to load';

  // ═════════════════════════════════════════════════════════════
  // 12. ACCOMMODATION DETAILS
  // ═════════════════════════════════════════════════════════════
  static const String hotelDetails = 'Hotel Details';
  static const String amenities = 'Amenities';
  static const String ratingOutOf5 = 'Rating out of 5';
  static const String perNight = 'per night';
  static const String inclusiveOfTaxes = 'Inclusive of all taxes';

  // ═════════════════════════════════════════════════════════════
  // 13. BOOKING & RESERVATION
  // ═════════════════════════════════════════════════════════════
  static const String bookingDetails = 'Booking Details';
  static const String checkIn = 'Check In';
  static const String checkOut = 'Check Out';
  static const String guests = 'Guests';
  static const String totalPrice = 'Total Price';
  static const String creditCard = 'Credit Card';
  static const String paypal = 'PayPal';
  static const String cash = 'Cash';
  static const String bookingConfirmed = 'Booking Confirmed';
  static const String bookingFailed = 'Booking Failed';
  static const String bookingCancelled = 'Booking cancelled successfully';
  static const String noBookingsYet = 'No bookings yet';

  // ═════════════════════════════════════════════════════════════
  // 14. WALLET & PAYMENT
  // ═════════════════════════════════════════════════════════════
  static const String paymentMethods = 'Payment Methods';
  static const String addPaymentMethod = 'Add Payment Method';
  static const String addNewPaymentMethod = 'Add New Payment Method';
  static const String defaultPaymentMethod = 'Default Payment Method';
  static const String removePaymentMethod = 'Remove Payment Method';
  static const String setAsDefault = 'Set as Default';
  static const String paymentMethodAdded = 'Payment method added successfully';
  static const String failedToLoadPaymentMethods =
      'Failed to load payment methods';
  static const String noPaymentMethods = 'No payment methods';
  static const String expired = 'Expired';
  static const String paymentMethod = 'Payment Method';
  static const String paymentFailed = 'Payment failed';

  // Card details
  static const String cardHolder = 'Card Holder';
  static const String cardNumber = 'Card Number';
  static const String expiryDate = 'Expiry Date';
  static const String cardType = 'Card Type';

  // Bank details
  static const String accountHolder = 'Account Holder';
  static const String accountNumber = 'Account Number';
  static const String routingNumber = 'Routing Number';
  static const String bankName = 'Bank Name';

  // PayPal / Stripe
  static const String paypalEmail = 'PayPal Email';
  static const String paypalPassword = 'PayPal Password';
  static const String connectStripeAccount = 'Connect Stripe Account';
  static const String connectWithStripe = 'Connect with Stripe';
  static const String stripeAccountConnected =
      'Stripe account connected successfully';

  // Balance / transactions
  static const String currentBalance = 'Current Balance';
  static const String availableBalance = 'Available Balance';
  static const String addFunds = 'Add Funds';
  static const String useCredits = 'Use Credits';
  static const String transactionDetails = 'Transaction Details';
  static const String transactionId = 'Transaction ID';
  static const String amount = 'Amount';
  static const String description = 'Description';
  static const String recipient = 'Recipient';
  static const String processing = 'Processing';
  static const String receipt = 'Receipt';

  // ═════════════════════════════════════════════════════════════
  // 15. SETTINGS
  // ═════════════════════════════════════════════════════════════
  static const String editProfile = 'Edit Profile';
  static const String changePassword = 'Change Password';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfService = 'Terms of Service';
  static const String helpCenter = 'Help Center';
  static const String contactUs = 'Contact Us';
  static const String aboutUs = 'About Us';
  static const String deleteAccount = 'Delete Account';

  // Section headers
  static const String appearance = 'Appearance';
  static const String preferences = 'Preferences';
  static const String privacySecurity = 'Privacy & Security';

  // Appearance
  static const String darkMode = 'Dark Mode';
  static const String darkModeDesc = 'Enable dark theme';
  static const String systemTheme = 'Use System Theme';
  static const String systemThemeDesc = 'Follow device theme settings';
  static const String fontFamily = 'Font Family';
  static const String fontFamilyDesc = 'Change app font style';
  static const String language = 'Language';
  static const String theme = 'Theme';

  // Notification settings
  static const String notificationsSettings = 'Notifications';
  static const String pushNotifications = 'Push Notifications';
  static const String pushNotificationsDesc =
      'Receive push notifications on your device';
  static const String eventReminders = 'Event Reminders';
  static const String eventRemindersDesc = 'Get reminded about upcoming events';
  static const String bookingUpdates = 'Booking Updates';
  static const String bookingUpdatesDesc = 'Notifications for booking changes';
  static const String promotionalOffers = 'Promotional Offers';
  static const String promotionalOffersDesc = 'Special deals and discounts';
  static const String emailNotifications = 'Email Notifications';
  static const String emailNotificationsDesc =
      'Receive notifications via email';
  static const String smsNotifications = 'SMS Notifications';
  static const String smsNotificationsDesc = 'Receive notifications via SMS';
  static const String notificationSound = 'Notification Sound';
  static const String notificationSoundDesc = 'Choose notification sound';

  // Preferences
  static const String currency = 'Currency';
  static const String currencyDesc = 'Select your preferred currency';
  static const String region = 'Region';
  static const String regionDesc = 'Set your location for relevant events';
  static const String locationServices = 'Location Services';
  static const String locationServicesDesc =
      'Allow access to your location for nearby events';
  static const String analyticsCrashReports = 'Analytics & Crash Reports';
  static const String analyticsCrashReportsDesc = 'Help us improve the app';
  static const String dataStorage = 'Data & Storage';
  static const String dataStorageDesc = 'Manage cache and storage usage';

  // Privacy & Security
  static const String security = 'Security';
  static const String twoFactorAuthentication = 'Two-Factor Authentication';
  static const String twoFactorAuthenticationDesc =
      'Add an extra layer of security';
  static const String connectedApps = 'Connected Apps';
  static const String connectedAppsDesc = 'Manage third-party app connections';
  static const String privacySettings = 'Privacy Settings';
  static const String privacySettingsDesc = 'Control your privacy preferences';

  // About section
  static const String version = 'Version';
  static const String whatsNew = "What's New";
  static const String whatsNewDesc = 'See latest features and updates';
  static const String rateApp = 'Rate App';
  static const String rateAppDesc = 'Rate our app on the App Store';
  static const String shareApp = 'Share App';
  static const String shareAppDesc = 'Share with friends';
  static const String followUs = 'Follow Us';
  static const String followUsDesc = 'Stay updated on social media';
  static const String openSourceLicenses = 'Open Source Licenses';
  static const String openSourceLicensesDesc = 'View open source licenses';

  // Data / cache
  static const String clearCache = 'Clear Cache';
  static const String clearAll = 'Clear All';
  static const String cacheSize = 'Cache Size';
  static const String imageCache = 'Image Cache';
  static const String documents = 'Documents';

  // ═════════════════════════════════════════════════════════════
  // 16. DIALOGS & MESSAGES
  // ═════════════════════════════════════════════════════════════
  static const String confirmDeletion = 'Confirm Deletion';
  static const String typeToConfirm = 'Please type "DELETE" to confirm:';
  static const String deleteAccountMessage =
      'This will permanently delete your account and all associated data. This action cannot be undone.';
  static const String logoutMessage = 'Are you sure you want to logout?';
  static const String confirmClearHistory = 'Clear History';
  static const String clearHistoryMessage =
      'Are you sure you want to clear your viewing history?';
  static const String historyCleared = 'History cleared';

  // Status messages
  static const String comingSoon = 'Coming Soon!';
  static const String cacheCleared = 'Cache cleared successfully!';
  static const String dataCleared = 'All data cleared successfully!';
  static const String twoFAEnabled = '2FA enabled successfully!';
  static const String twoFADisabled = '2FA disabled!';
  static const String logoutSuccess = 'Logged out successfully!';
  static const String deleteInitiated =
      'Account deletion initiated. Check your email for confirmation.';
  static const String profileUpdated = 'Profile updated successfully';
  static const String passwordChanged = 'Password changed successfully';
  static const String itemAddedToFavorites = 'Added to favorites';
  static const String itemRemovedFromFavorites = 'Removed from favorites';

  // ═════════════════════════════════════════════════════════════
  // 17. FORM LABELS & VALIDATION
  // ═════════════════════════════════════════════════════════════
  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String phoneNumber = 'Phone Number';
  static const String address = 'Address';
  static const String state = 'State';
  static const String zipCode = 'ZIP Code';
  static const String dateOfBirth = 'Date of Birth';
  static const String gender = 'Gender';
  static const String male = 'Male';
  static const String female = 'Female';
  static const String other = 'Other';

  // Validation
  static const String fieldRequired = 'This field is required';
  static const String invalidPhone = 'Please enter a valid phone number';
  static const String invalidZipCode = 'Please enter a valid ZIP code';
  static const String selectDate = 'Please select a date';
  static const String selectOption = 'Please select an option';

  // ═════════════════════════════════════════════════════════════
  // 18. PROFILE / STATISTICS
  // ═════════════════════════════════════════════════════════════
  static const String contact = 'Contact';
  static const String statistics = 'Statistics';
  static const String status = 'Status';
  static const String active = 'Active';
  static const String inactive = 'Inactive';
  static const String views = 'Views';
  static const String likes = 'Likes';
  static const String shares = 'Shares';

  // ═════════════════════════════════════════════════════════════
  // 19. LOADING / ERROR / EMPTY STATES
  // ═════════════════════════════════════════════════════════════
  static const String loadingExperiences = 'Loading amazing experiences...';
  static const String loadingEvents = 'Loading events...';
  static const String somethingWentWrong = 'Something went wrong';
  static const String somethingWentWrongTryAgain =
      'Something went wrong. Please try again.';
  static const String unknownError = 'Unknown error occurred';
  static const String networkConnectionFailed = 'Network connection failed';
  static const String requestTimedOut = 'Request timed out';
  static const String unexpectedError = 'An unexpected error occurred';
  static const String noInternetConnection = 'No internet connection';
  static const String errorLoadingData = 'Error loading data';
  static const String error = 'Error';
  static const String success = 'Success';

  static const String noContentAvailable = 'No content available';
  static const String noContentYet = 'No content available yet';
  static const String noContentAvailableYet = 'No content available yet';
  static const String pullDownRefresh = 'Pull down to refresh';
  static const String noNotifications = 'No notifications';
  static const String noSearchResults = 'No results found';

  // Events empty states
  static const String noEventsAvailable = 'No events available';
  static const String noMatchingEvents = 'No events match your filters';
  static const String tryAdjustingFilters =
      'Try adjusting your search criteria';
  static const String checkBackLater = 'Check back later for new events';

  // ═════════════════════════════════════════════════════════════
  // 20. DROPDOWN OPTIONS (Currency / Language / Font)
  // ═════════════════════════════════════════════════════════════
  // Currency
  static const String usd = 'USD';
  static const String eur = 'EUR';
  static const String gbp = 'GBP';
  static const String jpy = 'JPY';
  static const String cad = 'CAD';
  static const String aud = 'AUD';

  // Language
  static const String english = 'English';
  static const String spanish = 'Spanish';
  static const String french = 'French';
  static const String german = 'German';
  static const String italian = 'Italian';
  static const String japanese = 'Japanese';

  // Font family
  static const String fontMontserrat = 'Montserrat';
  static const String fontRoboto = 'Roboto';
  static const String fontPoppins = 'Poppins';
  static const String fontInter = 'Inter';
  //
  static const String contactInfo = 'Contact Info';
  static const String alwaysOpen = 'Always Open';
  static const String details = 'Details';
  // ═════════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════════
  static String getLocationName(String flag) {
    switch (flag) {
      case '🇺🇸':
        return unitedStates;
      case '🇬🇧':
        return unitedKingdom;
      case '🇨🇦':
        return canada;
      case '🇦🇺':
        return australia;
      case '🇩🇪':
        return germany;
      case '🇫🇷':
        return france;
      case '🇯🇵':
        return japan;
      case '🇹🇹':
        return trinidadTobago;
      default:
        return unitedStates;
    }
  }

  static Map<String, String> get locations => {
    '🇺🇸': unitedStates,
    '🇬🇧': unitedKingdom,
    '🇨🇦': canada,
    '🇦🇺': australia,
    '🇩🇪': germany,
    '🇫🇷': france,
    '🇯🇵': japan,
    '🇹🇹': trinidadTobago,
  };

  static List<String> get locationKeys => locations.keys.toList();
  static List<String> get locationNames => locations.values.toList();
}

class AppDimensions {
  static const double headerOverlayHeight = 400;
  static const double welcomeCardMaxHeight = 200;
  static const double carouselItemHeight = 220;
  static const double carouselViewportFraction = 0.5;
  static const double bottomGradientHeight = 150;
  static const double sideActionsBottom = 200;

  static const EdgeInsets defaultPadding = EdgeInsets.all(16);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(
    horizontal: 16,
  );
  static const EdgeInsets carouselItemPadding = EdgeInsets.symmetric(
    horizontal: 4,
  );
  static const EdgeInsets welcomeCardPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 20,
  );
  static const EdgeInsets locationDropdownPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 4,
  );
  static const EdgeInsets exploreButtonPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );

  static const Duration debounceDuration = Duration(milliseconds: 500);
  static const Duration autoScrollDuration = Duration(seconds: 10);
  static const Duration likeAnimationDuration = Duration(milliseconds: 450);
  static const Duration carouselAutoPlayInterval = Duration(seconds: 3);
  static const Duration carouselAnimationDuration = Duration(milliseconds: 800);

  static const BorderRadius cardBorderRadius = BorderRadius.all(
    Radius.circular(24),
  );
  static const BorderRadius buttonBorderRadius = BorderRadius.all(
    Radius.circular(20),
  );

  static const double iconSizeLarge = 56;
  static const double iconSizeMedium = 24;
  static const double iconSizeError = 64;
  static const double dropdownIconSize = 24;
  static const double flagFontSize = 22;

  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 32;
  static const double spacingExtraLarge = 100;

  static const double blurSigma = 10.0;
  static const double opacityFull = 1.0;
  static const double opacityMedium = 0.7;
  static const double opacityLow = 0.3;
}
