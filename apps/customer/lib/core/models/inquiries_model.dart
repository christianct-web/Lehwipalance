// lib/core/models/inquiry_model.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';
import 'package:lehwipalancecustomerv1/core/models/receipt_model.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

// lib/customer/modules/inquiry/inquiry_screen.dart

enum InquiryStatus { pending, responded, resolved, cancelled }

extension InquiryStatusExtension on InquiryStatus {
  String get displayName {
    switch (this) {
      case InquiryStatus.pending:
        return 'Pending';
      case InquiryStatus.responded:
        return 'Responded';
      case InquiryStatus.resolved:
        return 'Resolved';
      case InquiryStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case InquiryStatus.pending:
        return Colors.orange;
      case InquiryStatus.responded:
        return Colors.blue;
      case InquiryStatus.resolved:
        return Colors.green;
      case InquiryStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case InquiryStatus.pending:
        return Icons.hourglass_empty;
      case InquiryStatus.responded:
        return Icons.chat;
      case InquiryStatus.resolved:
        return Icons.check_circle;
      case InquiryStatus.cancelled:
        return Icons.cancel;
    }
  }
}

class Inquiry implements Identifiable, Timestamped {
  @override
  final String id;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;

  final String userId;
  final String? merchantId;
  final String? organisationId;
  final List<InquiryItem> items;
  final String subject;
  final String message;
  final String? response;
  final InquiryStatus status;
  final DateTime? respondedAt;
  final DateTime? resolvedAt;
  final Map<String, dynamic> metadata;

  const Inquiry({
    required this.id,
    required this.userId,
    required this.items,
    required this.subject,
    required this.message,
    this.merchantId,
    this.organisationId,
    this.response,
    this.status = InquiryStatus.pending,
    this.respondedAt,
    this.resolvedAt,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory Inquiry.fromCart({
    required String userId,
    required List<CartItem> cartItems,
    required String subject,
    required String message,
    String? merchantId,
    String? organisationId,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    final items = cartItems.map((item) {
      return InquiryItem(
        id: item.id,
        type: item.type,
        name: item.name,
        quantity: item.quantity,
        price: item.totalPrice,
        selectedDate: item.selectedDate,
        selectedTime: item.selectedTime,
        customizations: item.customizations,
      );
    }).toList();

    return Inquiry(
      id: 'INQ${now.millisecondsSinceEpoch.toString().substring(5)}',
      userId: userId,
      items: items,
      subject: subject,
      message: message,
      merchantId: merchantId,
      organisationId: organisationId,
      metadata: metadata ?? {},
      createdAt: now,
      updatedAt: now,
    );
  }

  Inquiry copyWith({
    String? id,
    String? userId,
    List<InquiryItem>? items,
    String? subject,
    String? message,
    String? response,
    InquiryStatus? status,
    DateTime? respondedAt,
    DateTime? resolvedAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Inquiry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      merchantId: merchantId,
      organisationId: organisationId,
      response: response ?? this.response,
      status: status ?? this.status,
      respondedAt: respondedAt ?? this.respondedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPending => status == InquiryStatus.pending;
  bool get isResponded => status == InquiryStatus.responded;
  bool get isResolved => status == InquiryStatus.resolved;
  bool get isCancelled => status == InquiryStatus.cancelled;
  bool get hasResponse => response != null && response!.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'merchantId': merchantId,
      'organisationId': organisationId,
      'items': items.map((item) => item.toJson()).toList(),
      'subject': subject,
      'message': message,
      'response': response,
      'status': status.name,
      'respondedAt': respondedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      merchantId: json['merchantId'] as String?,
      organisationId: json['organisationId'] as String?,
      items: (json['items'] as List)
          .map((item) => InquiryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subject: json['subject'] as String,
      message: json['message'] as String,
      response: json['response'] as String?,
      status: InquiryStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => InquiryStatus.pending,
      ),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

// lib/core/mock_data/mock_inquiries.dart

final List<Inquiry> mockInquiries = [
  Inquiry(
    id: 'INQ001',
    userId: 'customer_001',
    merchantId: 'org_hospitality',
    organisationId: 'org_hospitality',
    items: [
      InquiryItem(
        id: 'room_001',
        type: CartItemType.room,
        name: 'Deluxe Suite',
        quantity: 1,
        price: 220.0,
        selectedDate: DateTime.now().add(const Duration(days: 10)),
        customizations: {
          'checkOut': DateTime.now().add(const Duration(days: 13)),
          'nights': 3,
        },
      ),
      InquiryItem(
        id: 'spa_massage',
        type: CartItemType.service,
        name: 'Deep Tissue Massage',
        quantity: 2,
        price: 120.0,
        selectedDate: DateTime.now().add(const Duration(days: 11)),
        selectedTime: const TimeOfDay(hour: 14, minute: 0),
      ),
    ],
    subject: 'Room availability and spa packages',
    message:
        'I would like to know if the Deluxe Suite is available for 3 nights starting from next week. Also, are there any spa packages available?',
    status: InquiryStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  Inquiry(
    id: 'INQ002',
    userId: 'customer_002',
    merchantId: 'org_tech_conf',
    organisationId: 'org_tech_conf',
    items: [
      InquiryItem(
        id: 'ticket_001',
        type: CartItemType.ticket,
        name: 'Early Bird',
        quantity: 2,
        price: 99.0,
        selectedDate: DateTime.now().add(const Duration(days: 45)),
      ),
      InquiryItem(
        id: 'ticket_002',
        type: CartItemType.ticket,
        name: 'VIP Pass',
        quantity: 1,
        price: 499.0,
        selectedDate: DateTime.now().add(const Duration(days: 45)),
      ),
    ],
    subject: 'VIP Pass benefits and group discounts',
    message:
        'I am interested in purchasing VIP passes for the TechConf. Could you please provide more details about the benefits? Also, do you offer group discounts for 3+ tickets?',
    response:
        'Thank you for your inquiry. The VIP Pass includes premium seating, access to the after-party, and a meet-and-greet with the keynote speakers. For groups of 3 or more, we offer a 10% discount. Please let me know if you have any other questions.',
    status: InquiryStatus.responded,
    respondedAt: DateTime.now().subtract(const Duration(hours: 1)),
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
  ),
  Inquiry(
    id: 'INQ003',
    userId: 'customer_003',
    merchantId: 'org_services',
    organisationId: 'org_services',
    items: [
      InquiryItem(
        id: 'steelpan',
        type: CartItemType.service,
        name: 'Steelpan Basics',
        quantity: 2,
        price: 45.0,
        selectedDate: DateTime.now().add(const Duration(days: 5)),
        selectedTime: const TimeOfDay(hour: 10, minute: 0),
      ),
    ],
    subject: 'Steelpan lesson availability',
    message:
        'Do you have availability for 2 students in the Steelpan Basics class for next week? We would prefer a morning session if possible.',
    response:
        'Yes, we have availability on Tuesday and Thursday mornings. The 10:00 AM slot is available for both days. Please confirm which day works best for you.',
    status: InquiryStatus.resolved,
    respondedAt: DateTime.now().subtract(const Duration(days: 1)),
    resolvedAt: DateTime.now().subtract(const Duration(days: 1)),
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  Inquiry(
    id: 'INQ004',
    userId: 'customer_004',
    merchantId: 'org_music_fest',
    organisationId: 'org_music_fest',
    items: [
      InquiryItem(
        id: 'ticket_005',
        type: CartItemType.ticket,
        name: 'General Admission',
        quantity: 4,
        price: 49.0,
        selectedDate: DateTime.now().add(const Duration(days: 90)),
      ),
    ],
    subject: 'Carnival Kickoff ticket cancellation policy',
    message:
        'I need to know the cancellation policy for the General Admission tickets. Can I get a refund if I cancel?',
    status: InquiryStatus.cancelled,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
  Inquiry(
    id: 'INQ005',
    userId: 'customer_001',
    merchantId: 'org_hospitality',
    organisationId: 'org_hospitality',
    items: [
      InquiryItem(
        id: 'room_003',
        type: CartItemType.room,
        name: 'Ocean View Suite',
        quantity: 1,
        price: 300.0,
        selectedDate: DateTime.now().add(const Duration(days: 15)),
        customizations: {
          'checkOut': DateTime.now().add(const Duration(days: 18)),
          'nights': 3,
        },
      ),
      InquiryItem(
        id: 'spa_facial',
        type: CartItemType.service,
        name: 'Organic Facial Treatment',
        quantity: 2,
        price: 150.0,
        selectedDate: DateTime.now().add(const Duration(days: 16)),
        selectedTime: const TimeOfDay(hour: 11, minute: 0),
      ),
    ],
    subject: 'Honeymoon package inquiry',
    message:
        'We are planning our honeymoon and would like to know if you have any special packages for newlyweds. We are interested in the Ocean View Suite and some spa treatments.',
    status: InquiryStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
  ),
];

class InquiryItem extends Equatable {
  final String id;
  final CartItemType type;
  final String name;
  final int quantity;
  final double price;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final Map<String, dynamic> customizations;

  const InquiryItem({
    required this.id,
    required this.type,
    required this.name,
    required this.quantity,
    required this.price,
    this.selectedDate,
    this.selectedTime,
    this.customizations = const {},
  });

  String get totalPriceDisplay => '\$${(price * quantity).toStringAsFixed(2)}';
  String get priceDisplay => '\$${price.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'quantity': quantity,
      'price': price,
      'selectedDate': selectedDate?.toIso8601String(),
      'selectedTime': selectedTime != null
          ? '${selectedTime!.hour}:${selectedTime!.minute}'
          : null,
      'customizations': customizations,
    };
  }

  factory InquiryItem.fromJson(Map<String, dynamic> json) {
    return InquiryItem(
      id: json['id'] as String,
      type: CartItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CartItemType.ticket,
      ),
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      selectedDate: json['selectedDate'] != null
          ? DateTime.parse(json['selectedDate'] as String)
          : null,
      selectedTime: json['selectedTime'] != null
          ? TimeOfDay(
              hour: int.parse((json['selectedTime'] as String).split(':')[0]),
              minute: int.parse((json['selectedTime'] as String).split(':')[1]),
            )
          : null,
      customizations: json['customizations'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  List<Object?> get props => [id, type, name, quantity, price];
}

// lib/core/providers/inquiry_provider.dart
