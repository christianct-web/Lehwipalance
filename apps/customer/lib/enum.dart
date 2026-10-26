import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/modules/widgets.dart';

enum ListingType { event, hotel, place, service, store, vacation }

// lib/features/listing/enums/operating_status.dart
enum OperatingStatus { open, closed, closingSoon }

// Define available categories for each listing type
extension ListingTypeExtension on ListingType {
  ({
    String label,
    String actionText,
    IconData actionIcon,
    IconData icon, // ← NEW: generic type icon
    Color color,
  })
  get meta {
    switch (this) {
      case ListingType.event:
        return (
          label: 'Event',
          actionText: 'Buy Ticket',
          actionIcon: Icons.confirmation_number,
          icon: Icons.event,
          color: Colors.purple,
        );
      case ListingType.hotel:
        return (
          label: 'Hotel',
          actionText: 'Book Now',
          actionIcon: Icons.bed,
          icon: Icons.hotel,
          color: Colors.blue,
        );
      case ListingType.place:
        return (
          label: 'Place',
          actionText: 'Plan Visit',
          actionIcon: Icons.map,
          icon: Icons.place,
          color: Colors.green,
        );
      case ListingType.service:
        return (
          label: 'Service',
          actionText: 'Book Service',
          actionIcon: Icons.build,
          icon: Icons.handyman,
          color: Colors.orange,
        );
      case ListingType.store:
        return (
          label: 'Store',
          actionText: 'Shop Now',
          actionIcon: Icons.shopping_bag,
          icon: Icons.storefront,
          color: Colors.pink,
        );
      case ListingType.vacation:
        return (
          label: 'Vacation',
          actionText: 'Book Getaway',
          actionIcon: Icons.beach_access,
          icon: Icons.beach_access,
          color: Colors.teal,
        );
    }
  }

  String get label => meta.label;
  String get actionButtonText => meta.actionText;
  IconData get actionIcon => meta.actionIcon;
  IconData get icon => meta.icon; // ← NEW
  Color get color => meta.color;

  static const String defaultActionButtonText = 'Book Now';
  static const IconData defaultActionIcon = Icons.book;
  // Static lists of available categories
  static const List<String> eventCategories = [
    'party',
    'hike',
    'tour',
    'concert',
    'festival',
    'workshop',
    'conference',
    'sports',
  ];

  static const List<String> hotelCategories = [
    'hotel',
    'guesthouse',
    'hostel',
    'resort',
    'boutique',
    'apartment',
    'villa',
    'camping',
  ];

  static const List<String> placeCategories = [
    'mall',
    'club',
    'beach',
    'restaurant',
    'cafe',
    'park',
    'museum',
    'attraction',
  ];

  static const List<String> serviceCategories = [
    'entertainer',
    'transport',
    'cleaning',
    'repair',
    'beauty',
    'fitness',
    'tutoring',
    'catering',
  ];

  static const List<String> storeCategories = [
    'clothing',
    'electronics',
    'groceries',
    'pharmacy',
    'books',
    'toys',
    'jewelry',
    'sports',
    'furniture',
    'pet',
  ];

  static const List<String> vacationCategories = [
    'carnival',
    'mountain',
    'city',
    'countryside',
    'island',
    'desert',
    'lake',
    'ski',
    'cruise',
    'adventure',
  ];

  // Get categories based on type
  List<String> get categories {
    switch (this) {
      case ListingType.event:
        return eventCategories;
      case ListingType.hotel:
        return hotelCategories;
      case ListingType.place:
        return placeCategories;
      case ListingType.service:
        return serviceCategories;
      case ListingType.store:
        return storeCategories;
      case ListingType.vacation:
        return vacationCategories;
    }
  }

  // Get category icon/emoji mapping
  Map<String, String> get categoryIcons {
    switch (this) {
      case ListingType.event:
        return {
          'party': '🎉',
          'hike': '🥾',
          'tour': '🏛️',
          'concert': '🎵',
          'festival': '🎪',
          'workshop': '🔧',
          'conference': '💼',
          'sports': '⚽',
        };
      case ListingType.hotel:
        return {
          'hotel': '🏨',
          'guesthouse': '🏠',
          'hostel': '🛏️',
          'resort': '🌴',
          'boutique': '✨',
          'apartment': '🏢',
          'villa': '🏡',
          'camping': '🏕️',
        };
      case ListingType.place:
        return {
          'mall': '🛍️',
          'club': '💃',
          'beach': '🏖️',
          'restaurant': '🍽️',
          'cafe': '☕',
          'park': '🌳',
          'museum': '🏛️',
          'attraction': '🎡',
        };
      case ListingType.service:
        return {
          'entertainer': '🎤',
          'transport': '🚗',
          'cleaning': '🧹',
          'repair': '🔧',
          'beauty': '💄',
          'fitness': '💪',
          'tutoring': '📚',
          'catering': '🍕',
        };
      case ListingType.store:
        return {
          'clothing': '👕',
          'electronics': '📱',
          'groceries': '🛒',
          'pharmacy': '💊',
          'books': '📚',
          'toys': '🧸',
          'jewelry': '💍',
          'sports': '⚽',
          'furniture': '🛋️',
          'pet': '🐾',
        };
      case ListingType.vacation:
        return {
          'beach': '🏖️',
          'mountain': '⛰️',
          'city': '🏙️',
          'countryside': '🌾',
          'island': '🏝️',
          'desert': '🏜️',
          'lake': '🏞️',
          'ski': '⛷️',
          'cruise': '🚢',
          'adventure': '🧗',
        };
    }
  }

  String get collectionName {
    switch (this) {
      case ListingType.event:
        return '🔥 Events';
      case ListingType.hotel:
        return '🏨 Accommodations';
      case ListingType.place:
        return '📍 Places';
      case ListingType.service:
        return '🛠 Services';
      case ListingType.store:
        return '🛍️ Stores';
      case ListingType.vacation:
        return '🌴 Vacations';
    }
  }

  // Validate if a category belongs to this listing type
  bool isValidCategory(String category) {
    return categories.contains(category);
  }

  // Get category display name (capitalized)
  String getCategoryDisplayName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Get category icon
  String getCategoryIcon(String category) {
    return categoryIcons[category] ?? '📌';
  }
}

enum ReceiptStatus {
  purchased,
  pending,
  approved,
  checked,
  checkedIn,
  cancelled,
  refunded,
}

extension ReceiptStatusExtension on ReceiptStatus {
  String get displayName {
    switch (this) {
      case ReceiptStatus.purchased:
        return 'Purchased';
      case ReceiptStatus.pending:
        return 'Pending';
      case ReceiptStatus.approved:
        return 'Approved';
      case ReceiptStatus.checked:
        return 'Checked';
      case ReceiptStatus.checkedIn:
        return 'Checked In';
      case ReceiptStatus.cancelled:
        return 'Cancelled';
      case ReceiptStatus.refunded:
        return 'Refunded';
    }
  }

  Color get color {
    switch (this) {
      case ReceiptStatus.purchased:
        return Colors.green;
      case ReceiptStatus.pending:
        return Colors.orange;
      case ReceiptStatus.approved:
        return Colors.blue;
      case ReceiptStatus.checked:
        return Colors.purple;
      case ReceiptStatus.checkedIn:
        return Colors.teal;
      case ReceiptStatus.cancelled:
        return Colors.red;
      case ReceiptStatus.refunded:
        return Colors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case ReceiptStatus.purchased:
        return Icons.check_circle;
      case ReceiptStatus.pending:
        return Icons.hourglass_empty;
      case ReceiptStatus.approved:
        return Icons.verified;
      case ReceiptStatus.checked:
        return Icons.receipt_long;
      case ReceiptStatus.checkedIn:
        return Icons.verified_user;
      case ReceiptStatus.cancelled:
        return Icons.cancel;
      case ReceiptStatus.refunded:
        return Icons.receipt;
    }
  }
}

enum CartItemType { ticket, room, service }

enum ServiceCategory { entertainer, transport }

enum EventCategory { party, hike, tour }

enum PlaceCategory { mall, club, beach, airport, store, restaurant }

enum AccommodationCategory { hotel, guesthouse, hostel }

//
enum HomeTab {
  forYou,
  events,
  places,
  hotels,
  services,
  stores,
  vacations,
  favorites,
}

enum EventSubTab {
  all('All Events'),
  today('Today'),
  thisWeekend('This Weekend'),
  upcoming('Upcoming'),
  free('Free'),
  paid('Paid');

  final String label;
  const EventSubTab(this.label);
}

enum PlaceSubTab {
  all('All Places'),
  restaurants('Restaurants'),
  cafes('Cafes'),
  nightlife('Nightlife'),
  attractions('Attractions'),
  shopping('Shopping');

  final String label;
  const PlaceSubTab(this.label);
}

enum HotelSubTab {
  all('All Hotels'),
  luxury('Luxury'),
  budget('Budget'),
  boutique('Boutique'),
  resorts('Resorts');

  final String label;
  const HotelSubTab(this.label);
}

enum ServiceSubTab {
  all('All Services'),
  beauty('Beauty & Spa'),
  fitness('Fitness & Health'),
  auto('Auto Services'),
  education('Education'),
  legal('Legal Services'),
  home('Home Services');

  final String label;
  const ServiceSubTab(this.label);
}

enum StoreSubTab {
  all('All Stores'),
  clothing('Clothing'),
  electronics('Electronics'),
  groceries('Groceries'),
  pharmacy('Pharmacy'),
  books('Books'),
  toys('Toys'),
  jewelry('Jewelry'),
  furniture('Furniture');

  final String label;
  const StoreSubTab(this.label);
}

enum VacationSubTab {
  all('All Vacations'),
  beach('Beach'),
  mountain('Mountain'),
  city('City'),
  countryside('Countryside'),
  island('Island'),
  adventure('Adventure'),
  cruise('Cruise');

  final String label;
  const VacationSubTab(this.label);
}

enum BookingType {
  contact, // Show phone/email/booking instructions
  external, // Redirect to external site/app
  instant, // Book instantly in app
  request, // Send booking request for approval
}

enum InvitationStatus {
  none,
  sent,
  accepted,
  rejected,
  cancelled;

  /// Convert to string for Firestore storage (more readable than index)
  String toJson() => name;

  /// Parse from string with fallback
  static InvitationStatus fromJson(String value) {
    return values.firstWhere(
      (e) => e.name == value,
      orElse: () => InvitationStatus.none,
    );
  }
}

//____________//
enum EventSort {
  dateAsc('Date (Oldest first)'),
  dateDesc('Date (Newest first)'),
  priceAsc('Price (Low to high)'),
  priceDesc('Price (high to low)'),
  distanceAsc('Price (High to low)'),
  distance('Near Me'),
  popularity('Most popular');

  final String label;
  const EventSort(this.label);
}

enum BookActionType { contactInfo, hyperlink, payment }

BookActionType bookActionFromString(String value) {
  return BookActionType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => BookActionType.contactInfo,
  );
}

//enum TicketStatus { available, soldOut, comingSoon }

// Helper Extensions
extension PublishStatusExtension on String {
  PublishStatus toPublishStatus() {
    switch (this) {
      case 'published':
        return PublishStatus.published;
      case 'unpublished':
        return PublishStatus.unpublished;
      case 'draft':
        return PublishStatus.draft;
      case 'canceled':
        return PublishStatus.canceled;
      default:
        return PublishStatus.unpublished;
    }
  }
}

// ==================== Parsing ====================
extension EventStatusExtension on PublishStatus {
  String get name => toString().split('.').last;
}

extension TicketStatusExtension on TicketStatus {
  String get name => toString().split('.').last;
}

extension EventPublishStatusParsing on String {
  PublishStatus toEventPublishStatus() => PublishStatus.values.firstWhere(
    (e) => e.name == this,
    orElse: () => PublishStatus.unpublished,
  );
}

extension TicketStatusParsing on String {
  TicketStatus toTicketStatus() => TicketStatus.values.firstWhere(
    (e) => e.name == this,
    orElse: () => TicketStatus.pending,
  );
}

//______________//
enum PaymentMethodType { creditCard, digitalWallet, bankAccount, debitCard }

enum TicketStatus {
  pending,
  checked,
  checkedIn,
  cancelled,
  refunded,
  approved;

  String get displayName {
    switch (this) {
      case TicketStatus.pending:
        return 'Pending';
      case TicketStatus.checked:
        return 'Checked';
      case TicketStatus.checkedIn:
        return 'Checked In';
      case TicketStatus.cancelled:
        return 'Cancelled';
      case TicketStatus.refunded:
        return 'Refunded';
      case TicketStatus.approved:
        return 'Approved';
    }
  }

  Color getColor(BuildContext context) {
    switch (this) {
      case TicketStatus.pending:
        return Colors.orange;
      case TicketStatus.checked:
        return Colors.blue;
      case TicketStatus.checkedIn:
        return Colors.green;
      case TicketStatus.cancelled:
        return Colors.red;
      case TicketStatus.refunded:
        return Colors.purple;
      case TicketStatus.approved:
        return Colors.teal;
    }
  }

  IconData get icon {
    switch (this) {
      case TicketStatus.pending:
        return Icons.pending_outlined;
      case TicketStatus.checked:
        return Icons.verified_outlined;
      case TicketStatus.checkedIn:
        return Icons.check_circle_outline;
      case TicketStatus.cancelled:
        return Icons.cancel_outlined;
      case TicketStatus.refunded:
        return Icons.money_off_outlined;
      case TicketStatus.approved:
        return Icons.check_circle_outline;
    }
  }
}
