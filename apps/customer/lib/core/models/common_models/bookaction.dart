import 'package:equatable/equatable.dart';

import 'package:lehwipalancecustomerv1/core/models/common_models/contact_info.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

/// Defines how users can book/interact with a listing
class BookingMode extends Equatable {
  final BookingType type;

  /// External link (used when type == hyperlink)
  final String? url;

  /// Contact-based booking (used when type == contactInfo)
  /// ContactInfo
  final ContactInfo? contactInfo;
  final String?
  instructions; //e.g. our booking hours are 9am-5pm, please call during those times,our ticket outllets are located at...

  /// Internal booking metadata (used when type == internalBooking)
  final String? listingId; // optional: connect to event/place/service
  final double? price;
  final String currency;
  final bool requiresDeposit;
  final bool?
  requiresApproval; // new field to indicate if approval is needed for booking
  final String? buttonText;

  const BookingMode({
    required this.type,
    this.url,
    this.contactInfo,
    this.instructions,
    this.listingId,
    this.price,
    this.currency = 'USD',
    this.requiresDeposit = false,
    this.requiresApproval =
        false, // default to false for backward compatibility
    this.buttonText,
  });

  @override
  List<Object?> get props => [
    type,
    url,
    contactInfo,
    instructions,
    listingId,
    price,
    currency,
    requiresDeposit,
    buttonText,
  ];

  // -------------------------------
  // 🔹 Serialization
  // -------------------------------

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'url': url,
      'contactInfo': contactInfo,
      'instructions': instructions,
      'listingId': listingId,
      'price': price,
      'currency': currency,
      'requiresDeposit': requiresDeposit,
      'buttonText': buttonText,
    };
  }

  factory BookingMode.fromMap(Map<String, dynamic> map) {
    return BookingMode(
      type: BookingType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => BookingType.contact,
      ),
      url: map['url'],
      contactInfo: map['contactInfo'],
      instructions: map['instructions'],
      listingId: map['listingId'],
      price: (map['price'] as num?)?.toDouble(),
      currency: map['currency'] ?? 'USD',
      requiresDeposit: map['requiresDeposit'] ?? false,
      buttonText: map['buttonText'],
    );
  }

  // -------------------------------
  // 🔹 UI Helpers
  // -------------------------------

  String get displayText {
    if (buttonText != null && buttonText!.isNotEmpty) {
      return buttonText!;
    }

    switch (type) {
      case BookingType.contact:
        return 'Contact to Book';
      case BookingType.external:
        return 'Book on Website';
      case BookingType.instant:
        return 'Book Now';
      case BookingType.request:
        return 'Reserve';
    }
  }

  bool get isInternal => type == BookingType.instant;
  bool get isExternal => type == BookingType.external;
  bool get isContact => type == BookingType.contact;
  bool get isRequest => type == BookingType.request;
}
