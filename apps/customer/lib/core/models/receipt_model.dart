import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/core/models/room_model.dart';
import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';
import 'package:lehwipalancecustomerv1/core/models/service_item_model.dart';
import 'package:lehwipalancecustomerv1/core/models/ticket_model.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

class Receipt implements Identifiable, Timestamped {
  @override
  final String id;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  final String orderId; //QR code Data
  final String userId;
  final String? merchantId;
  final String? organisationId;

  // New fields for display names
  final String? merchantName;
  final String? userName;
  final String? organisationName;

  final List<CartItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String currency;
  final String? paymentMethod;
  final String? transactionId;
  final String? notes;
  final Map<String, dynamic> metadata;
  final ReceiptStatus status;

  final DateTime? paidAt;
  final DateTime? fulfilledAt;

  const Receipt({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    this.currency = 'USD',
    this.paymentMethod,
    this.transactionId,
    this.notes,
    this.metadata = const {},
    this.status = ReceiptStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.fulfilledAt,
    this.merchantId,
    this.organisationId,
    this.merchantName,
    this.userName,
    this.organisationName,
  });

  // Factory constructor for creating a receipt from cart
  factory Receipt.fromCart({
    required String orderId,
    required String userId,
    required List<CartItem> cartItems,
    double tax = 0.0,
    double discount = 0.0,
    String? paymentMethod,
    String? transactionId,
    String? notes,
    Map<String, dynamic>? metadata,
    String? merchantId,
    String? organisationId,
    String? merchantName,
    String? userName,
    String? organisationName,
  }) {
    final subtotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    final total = subtotal + tax - discount;

    return Receipt(
      id: 'RCP${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      orderId: orderId,
      userId: userId,
      items: cartItems,
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      paymentMethod: paymentMethod,
      transactionId: transactionId,
      notes: notes,
      metadata: metadata ?? {},
      status: ReceiptStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      merchantId: merchantId,
      organisationId: organisationId,
      merchantName: merchantName,
      userName: userName,
      organisationName: organisationName,
    );
  }

  // Copy with
  Receipt copyWith({
    String? id,
    String? orderId,
    String? userId,
    List<CartItem>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    String? currency,
    String? paymentMethod,
    String? transactionId,
    String? notes,
    Map<String, dynamic>? metadata,
    ReceiptStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? paidAt,
    DateTime? fulfilledAt,
    String? merchantId,
    String? organisationId,
    String? merchantName,
    String? userName,
    String? organisationName,
  }) {
    return Receipt(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paidAt: paidAt ?? this.paidAt,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      merchantId: merchantId ?? this.merchantId,
      organisationId: organisationId ?? this.organisationId,
      merchantName: merchantName ?? this.merchantName,
      userName: userName ?? this.userName,
      organisationName: organisationName ?? this.organisationName,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'merchantId': merchantId,
      'organisationId': organisationId,
      'merchantName': merchantName,
      'userName': userName,
      'organisationName': organisationName,
      'items': items.map((item) => _cartItemtoJson(item)).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'notes': notes,
      'metadata': metadata,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'fulfilledAt': fulfilledAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      userId: json['userId'] as String,
      merchantId: json['merchantId'] as String?,
      organisationId: json['organisationId'] as String?,
      merchantName: json['merchantName'] as String?,
      userName: json['userName'] as String?,
      organisationName: json['organisationName'] as String?,
      items: (json['items'] as List)
          .map((item) => _cartItemfromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      paymentMethod: json['paymentMethod'] as String?,
      transactionId: json['transactionId'] as String?,
      notes: json['notes'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      status: ReceiptStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReceiptStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      fulfilledAt: json['fulfilledAt'] != null
          ? DateTime.parse(json['fulfilledAt'] as String)
          : null,
    );
  }

  // Helper methods
  int get itemCount => items.length;

  String get totalDisplay => '$currency ${total.toStringAsFixed(2)}';

  String get subtotalDisplay => '$currency ${subtotal.toStringAsFixed(2)}';

  String get taxDisplay => '$currency ${tax.toStringAsFixed(2)}';

  String get discountDisplay => '$currency ${discount.toStringAsFixed(2)}';

  // Get display name for merchant (prefer merchantName, fallback to organisationName)
  String get displayMerchantName {
    if (merchantName != null && merchantName!.isNotEmpty) {
      return merchantName!;
    }
    if (organisationName != null && organisationName!.isNotEmpty) {
      return organisationName!;
    }
    return 'Unknown Merchant';
  }

  // Get display name for user
  String get displayUserName {
    return userName ?? 'User';
  }

  bool get isPaid => status == ReceiptStatus.purchased || paidAt != null;

  bool get isCancelled => status == ReceiptStatus.cancelled;

  bool get isRefunded => status == ReceiptStatus.refunded;

  bool get isCompleted => status == ReceiptStatus.checkedIn;

  // Calculate total by type
  double get totalByTickets => items
      .where((item) => item.type == CartItemType.ticket)
      .fold(0.0, (sum, item) => sum + item.totalPrice);

  double get totalByRooms => items
      .where((item) => item.type == CartItemType.room)
      .fold(0.0, (sum, item) => sum + item.totalPrice);

  double get totalByServices => items
      .where((item) => item.type == CartItemType.service)
      .fold(0.0, (sum, item) => sum + item.totalPrice);

  // Private helper for JSON serialization of CartItem
  static Map<String, dynamic> _cartItemtoJson(CartItem item) {
    return {
      'id': item.id,
      'type': item.type.name,
      'quantity': item.quantity,
      'totalPrice': item.totalPrice,
      'name': item.name,
      'priceDisplay': item.priceDisplay,
      'selectedDate': item.selectedDate?.toIso8601String(),
      'selectedTime': item.selectedTime != null
          ? '${item.selectedTime!.hour}:${item.selectedTime!.minute}'
          : null,
      'customizations': item.customizations,
      // For specific item types, store the full item data
      'itemData': _getItemData(item),
    };
  }

  static Map<String, dynamic> _getItemData(CartItem item) {
    switch (item.type) {
      case CartItemType.ticket:
        final ticket = item.item as TicketDTO;
        return {
          'type': 'ticket',
          'id': ticket.id,
          'name': ticket.name,
          'price': ticket.price,
          'description': ticket.description,
          'eventId': ticket.eventId,
        };
      case CartItemType.room:
        final room = item.item as RoomDTO;
        return {
          'type': 'room',
          'id': room.id,
          'name': room.name,
          'basePrice': room.basePrice,
          'description': room.description,
          'hotelId': room.hotelId,
          'bedType': room.bedType,
          'maxGuests': room.maxGuests,
        };
      case CartItemType.service:
        final service = item.item as ServiceItemDTO;
        return {
          'type': 'service',
          'id': service.id,
          'name': service.name,
          'price': service.price,
          'description': service.description,
          'category': service.category.name,
          'duration': service.duration.inMinutes,
        };
    }
  }

  static CartItem _cartItemfromJson(Map<String, dynamic> json) {
    final type = CartItemType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => CartItemType.ticket,
    );

    // Reconstruct the item based on type
    dynamic item;
    final itemData = json['itemData'] as Map<String, dynamic>;

    switch (type) {
      case CartItemType.ticket:
        item = TicketDTO(
          id: itemData['id'],
          eventId: itemData['eventId'],
          name: itemData['name'],
          description: itemData['description'],
          price: (itemData['price'] as num).toDouble(),
          salesStartDate: DateTime.now(),
          salesEndDate: DateTime.now().add(const Duration(days: 30)),
          isOnSale: true,
        );
        break;
      case CartItemType.room:
        item = RoomDTO(
          id: itemData['id'],
          hotelId: itemData['hotelId'],
          name: itemData['name'],
          description: itemData['description'],
          imageUrl: '',
          basePrice: (itemData['basePrice'] as num).toDouble(),
          maxGuests: itemData['maxGuests'] as int? ?? 2,
          size: '',
          bedType: itemData['bedType'] as String? ?? '',
          createdAt: DateTime.now(),
        );
        break;
      case CartItemType.service:
        item = ServiceItemDTO(
          id: itemData['id'],
          serviceListingId: '',
          name: itemData['name'],
          description: itemData['description'],
          price: (itemData['price'] as num).toDouble(),
          category: ServiceItemCategory.values.firstWhere(
            (e) => e.name == itemData['category'],
            orElse: () => ServiceItemCategory.other,
          ),
          duration: Duration(minutes: itemData['duration'] as int? ?? 60),
          createdAt: DateTime.now(),
        );
        break;
    }

    return CartItem(
      id: json['id'],
      type: type,
      item: item,
      quantity: json['quantity'] as int? ?? 1,
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
}

class CartItem extends Equatable {
  final String id;
  final CartItemType type;
  final dynamic item;
  final int quantity;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final Map<String, dynamic> customizations;

  const CartItem({
    required this.id,
    required this.type,
    required this.item,
    this.quantity = 1,
    this.selectedDate,
    this.selectedTime,
    this.customizations = const {},
  });

  double get totalPrice {
    switch (type) {
      case CartItemType.ticket:
        return (item as TicketDTO).price * quantity;
      case CartItemType.room:
        return (item as RoomDTO).basePrice * quantity;
      case CartItemType.service:
        return (item as ServiceItemDTO).price * quantity;
    }
  }

  String get priceDisplay {
    switch (type) {
      case CartItemType.ticket:
        return (item as TicketDTO).priceDisplay;
      case CartItemType.room:
        return '\$${(item as RoomDTO).basePrice.toStringAsFixed(2)}';
      case CartItemType.service:
        return (item as ServiceItemDTO).priceDisplay;
    }
  }

  String get name {
    switch (type) {
      case CartItemType.ticket:
        return (item as TicketDTO).name;
      case CartItemType.room:
        return (item as RoomDTO).name;
      case CartItemType.service:
        return (item as ServiceItemDTO).name;
    }
  }

  String? get imageUrl {
    switch (type) {
      case CartItemType.ticket:
        return (item as TicketDTO).imageUrl;
      case CartItemType.room:
        return (item as RoomDTO).imageUrl;
      case CartItemType.service:
        final service = item as ServiceItemDTO;
        return service.imageUrls.isNotEmpty ? service.imageUrls.first : null;
    }
  }

  CartItem copyWith({
    String? id,
    CartItemType? type,
    dynamic item,
    int? quantity,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    Map<String, dynamic>? customizations,
  }) {
    return CartItem(
      id: id ?? this.id,
      type: type ?? this.type,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      customizations: customizations ?? this.customizations,
    );
  }

  @override
  List<Object?> get props => [id, type, quantity, selectedDate, selectedTime];
}

final List<Receipt> mockReceipts = [
  // RECEIPT 1: Tech Conference Tickets (evt_001) - customer_001
  Receipt(
    id: 'RCP001',
    orderId: 'ORD-TECH-001',
    userId: 'customer_001',
    merchantId: 'org_tech_conf',
    organisationId: 'org_tech_conf',
    merchantName: 'TechConf 2025 - Trinidad',
    userName: 'James Wilson',
    organisationName: 'Tech Conference Organization',
    items: [
      CartItem(
        id: 'ci_ticket_001',
        type: CartItemType.ticket,
        item: testTickets.firstWhere((t) => t.id == 'ticket_001'),
        quantity: 2,
        selectedDate: DateTime.now().add(const Duration(days: 45)),
      ),
      CartItem(
        id: 'ci_ticket_002',
        type: CartItemType.ticket,
        item: testTickets.firstWhere((t) => t.id == 'ticket_002'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 45)),
      ),
    ],
    subtotal: 697.0,
    tax: 69.7,
    discount: 50.0,
    total: 716.7,
    currency: 'USD',
    paymentMethod: 'Credit Card',
    transactionId: 'TXN-2026-001',
    notes: 'Early bird discount applied',
    metadata: {
      'event_id': 'evt_001',
      'event_name': 'TechConf 2025 - Trinidad',
      'booking_reference': 'TC-2025-001',
    },
    status: ReceiptStatus.purchased,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    paidAt: DateTime.now().subtract(const Duration(days: 2)),
    fulfilledAt: DateTime.now().subtract(const Duration(days: 1)),
  ),

  // RECEIPT 2: Carnival Kickoff Tickets (evt_002) - customer_001
  Receipt(
    id: 'RCP002',
    orderId: 'ORD-CARN-001',
    userId: 'customer_001',
    merchantId: 'org_music_fest',
    organisationId: 'org_music_fest',
    merchantName: 'Trinidad Carnival Kickoff 2025',
    userName: 'James Wilson',
    organisationName: 'Music Festival Organization',
    items: [
      CartItem(
        id: 'ci_ticket_005',
        type: CartItemType.ticket,
        item: testTickets.firstWhere((t) => t.id == 'ticket_005'),
        quantity: 3,
        selectedDate: DateTime.now().add(const Duration(days: 90)),
      ),
      CartItem(
        id: 'ci_ticket_006',
        type: CartItemType.ticket,
        item: testTickets.firstWhere((t) => t.id == 'ticket_006'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 90)),
      ),
    ],
    subtotal: 276.0,
    tax: 27.6,
    discount: 0.0,
    total: 303.6,
    currency: 'USD',
    paymentMethod: 'PayPal',
    transactionId: 'TXN-2026-002',
    notes: 'Carnival early bird special',
    metadata: {
      'event_id': 'evt_002',
      'event_name': 'Trinidad Carnival Kickoff 2025',
      'festival_package': 'Premium',
    },
    status: ReceiptStatus.purchased,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    updatedAt: DateTime.now().subtract(const Duration(days: 4)),
    paidAt: DateTime.now().subtract(const Duration(days: 5)),
    fulfilledAt: DateTime.now().subtract(const Duration(days: 4)),
  ),

  // RECEIPT 3: Hotel Booking - Hyatt (htl_001) - customer_001
  Receipt(
    id: 'RCP003',
    orderId: 'ORD-HTL-001',
    userId: 'customer_001',
    merchantId: 'org_hospitality',
    organisationId: 'org_hospitality',
    merchantName: 'Hyatt Regency Trinidad',
    userName: 'James Wilson',
    organisationName: 'Hospitality Organization',
    items: [
      CartItem(
        id: 'ci_room_001',
        type: CartItemType.room,
        item: mockRooms.firstWhere((r) => r.id == 'room_001'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 10)),
        customizations: {
          'check_in': DateTime.now()
              .add(const Duration(days: 10))
              .toIso8601String(),
          'check_out': DateTime.now()
              .add(const Duration(days: 13))
              .toIso8601String(),
          'nights': 3,
          'guests': 2,
          'special_requests': 'Extra pillows, high floor',
        },
      ),
      CartItem(
        id: 'ci_service_massage',
        type: CartItemType.service,
        item: mockServiceItems.firstWhere((s) => s.id == 'spa_massage'),
        quantity: 2,
        selectedDate: DateTime.now().add(const Duration(days: 11)),
        selectedTime: const TimeOfDay(hour: 14, minute: 0),
        customizations: {
          'therapist_preference': 'Any',
          'oil_type': 'Lavender',
          'focus_areas': ['Shoulders', 'Lower Back'],
        },
      ),
    ],
    subtotal: 900.0,
    tax: 90.0,
    discount: 100.0,
    total: 890.0,
    currency: 'USD',
    paymentMethod: 'Credit Card',
    transactionId: 'TXN-2026-003',
    notes: '3-night stay with spa package',
    metadata: {
      'hotel_id': 'htl_001',
      'hotel_name': 'Hyatt Regency Trinidad',
      'booking_type': 'Leisure',
      'room_type': 'Deluxe Suite',
      'nights': 3,
    },
    status: ReceiptStatus.purchased,
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    updatedAt: DateTime.now().subtract(const Duration(days: 6)),
    paidAt: DateTime.now().subtract(const Duration(days: 7)),
    fulfilledAt: DateTime.now().subtract(const Duration(days: 6)),
  ),

  // RECEIPT 4: Hilton Hotel Booking (htl_002) - customer_001
  Receipt(
    id: 'RCP004',
    orderId: 'ORD-HTL-002',
    userId: 'customer_001',
    merchantId: 'org_hospitality',
    organisationId: 'org_hospitality',
    merchantName: 'Hilton Trinidad & Conference Centre',
    userName: 'James Wilson',
    organisationName: 'Hospitality Organization',
    items: [
      CartItem(
        id: 'ci_room_003',
        type: CartItemType.room,
        item: mockRooms.firstWhere((r) => r.id == 'room_003'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 15)),
        customizations: {
          'check_in': DateTime.now()
              .add(const Duration(days: 15))
              .toIso8601String(),
          'check_out': DateTime.now()
              .add(const Duration(days: 17))
              .toIso8601String(),
          'nights': 2,
          'guests': 2,
          'special_requests': 'Ocean view, honeymoon suite',
        },
      ),
    ],
    subtotal: 600.0,
    tax: 60.0,
    discount: 0.0,
    total: 660.0,
    currency: 'USD',
    paymentMethod: 'Debit Card',
    transactionId: 'TXN-2026-004',
    notes: 'Honeymoon package',
    metadata: {
      'hotel_id': 'htl_002',
      'hotel_name': 'Hilton Trinidad',
      'booking_type': 'Honeymoon',
      'room_type': 'Ocean View Suite',
      'nights': 2,
    },
    status: ReceiptStatus.checkedIn,
    createdAt: DateTime.now().subtract(const Duration(days: 14)),
    updatedAt: DateTime.now().subtract(const Duration(days: 13)),
    paidAt: DateTime.now().subtract(const Duration(days: 14)),
    fulfilledAt: DateTime.now().subtract(const Duration(days: 13)),
  ),

  // RECEIPT 5: AI Summit Tickets (evt_003) - customer_004
  Receipt(
    id: 'RCP005',
    orderId: 'ORD-AI-001',
    userId: 'customer_004',
    merchantId: 'org_tech_conf',
    organisationId: 'org_tech_conf',
    merchantName: 'Caribbean AI & Machine Learning Summit',
    userName: 'Olivia Charles',
    organisationName: 'Tech Conference Organization',
    items: [
      CartItem(
        id: 'ci_ticket_008',
        type: CartItemType.ticket,
        item: testTickets.firstWhere((t) => t.id == 'ticket_008'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 120)),
      ),
      CartItem(
        id: 'ci_ticket_010',
        type: CartItemType.ticket,
        item: testTickets.firstWhere((t) => t.id == 'ticket_010'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 120)),
      ),
    ],
    subtotal: 498.0,
    tax: 49.8,
    discount: 50.0,
    total: 497.8,
    currency: 'USD',
    paymentMethod: 'Credit Card',
    transactionId: 'TXN-2026-005',
    notes: 'AI Summit workshop bundle',
    metadata: {
      'event_id': 'evt_003',
      'event_name': 'Caribbean AI & Machine Learning Summit',
      'workshop_selected': 'Deep Learning',
    },
    status: ReceiptStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now(),
    paidAt: null,
    fulfilledAt: null,
  ),

  // RECEIPT 6: Magdalena Grand Resort (htl_003) - customer_010
  Receipt(
    id: 'RCP006',
    orderId: 'ORD-HTL-003',
    userId: 'customer_010',
    merchantId: 'org_hospitality',
    organisationId: 'org_hospitality',
    merchantName: 'Magdalena Grand Beach & Golf Resort',
    userName: 'Nicole Williams',
    organisationName: 'Hospitality Organization',
    items: [
      CartItem(
        id: 'ci_room_005',
        type: CartItemType.room,
        item: mockRooms.firstWhere((r) => r.id == 'room_005'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 20)),
        customizations: {
          'check_in': DateTime.now()
              .add(const Duration(days: 20))
              .toIso8601String(),
          'check_out': DateTime.now()
              .add(const Duration(days: 24))
              .toIso8601String(),
          'nights': 4,
          'guests': 2,
        },
      ),
      CartItem(
        id: 'ci_service_body_wrap',
        type: CartItemType.service,
        item: mockServiceItems.firstWhere((s) => s.id == 'spa_body_wrap'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 21)),
        selectedTime: const TimeOfDay(hour: 15, minute: 0),
      ),
    ],
    subtotal: 900.0,
    tax: 90.0,
    discount: 50.0,
    total: 940.0,
    currency: 'USD',
    paymentMethod: 'Credit Card',
    transactionId: 'TXN-2026-006',
    notes: 'Resort getaway package',
    metadata: {
      'hotel_id': 'htl_003',
      'hotel_name': 'Magdalena Grand Beach & Golf Resort',
      'booking_type': 'Leisure',
      'nights': 4,
    },
    status: ReceiptStatus.purchased,
    createdAt: DateTime.now().subtract(const Duration(days: 10)),
    updatedAt: DateTime.now().subtract(const Duration(days: 8)),
    paidAt: DateTime.now().subtract(const Duration(days: 10)),
    fulfilledAt: DateTime.now().subtract(const Duration(days: 8)),
  ),

  // RECEIPT 7: Steelpan Lessons (srv_002) - customer_006
  Receipt(
    id: 'RCP007',
    orderId: 'ORD-SRV-001',
    userId: 'customer_006',
    merchantId: 'org_services',
    organisationId: 'org_services',
    merchantName: 'Steelpan Music Lessons',
    userName: 'Chloe Ramsay',
    organisationName: 'Services Organization',
    items: [
      CartItem(
        id: 'ci_service_steelpan',
        type: CartItemType.service,
        item: mockServiceItems.firstWhere((s) => s.id == 'steelpan'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 5)),
        selectedTime: const TimeOfDay(hour: 10, minute: 0),
        customizations: {'level': 'Beginner', 'instruments_required': true},
      ),
    ],
    subtotal: 45.0,
    tax: 4.5,
    discount: 0.0,
    total: 49.5,
    currency: 'USD',
    paymentMethod: 'Cash',
    transactionId: 'TXN-2026-007',
    notes: 'Music lessons package',
    metadata: {
      'service_id': 'srv_002',
      'service_name': 'Steelpan Music Lessons',
      'student_level': 'Beginner',
    },
    status: ReceiptStatus.checked,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    paidAt: DateTime.now().subtract(const Duration(days: 3)),
    fulfilledAt: DateTime.now().subtract(const Duration(days: 2)),
  ),

  // RECEIPT 8: Startup Pitch Competition (evt_004) - customer_008
  Receipt(
    id: 'RCP008',
    orderId: 'ORD-STARTUP-001',
    userId: 'customer_008',
    merchantId: 'org_startup',
    organisationId: 'org_startup',
    merchantName: 'Startup Pitch Competition - Caribbean Edition',
    userName: 'Samantha Hosein',
    organisationName: 'Startup Organization',
    items: [
      CartItem(
        id: 'ci_ticket_011',
        type: CartItemType.ticket,
        item: testTickets.firstWhere((t) => t.id == 'ticket_011'),
        quantity: 2,
        selectedDate: DateTime.now().add(const Duration(days: 30)),
      ),
      CartItem(
        id: 'ci_ticket_012',
        type: CartItemType.ticket,
        item: testTickets.firstWhere((t) => t.id == 'ticket_012'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 30)),
      ),
    ],
    subtotal: 50.0,
    tax: 5.0,
    discount: 0.0,
    total: 55.0,
    currency: 'USD',
    paymentMethod: 'Credit Card',
    transactionId: 'TXN-2026-008',
    notes: 'Investor pass with networking',
    metadata: {
      'event_id': 'evt_004',
      'event_name': 'Startup Pitch Competition',
      'investor': true,
    },
    status: ReceiptStatus.purchased,
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
    updatedAt: DateTime.now().subtract(const Duration(days: 11)),
    paidAt: DateTime.now().subtract(const Duration(days: 12)),
    fulfilledAt: DateTime.now().subtract(const Duration(days: 11)),
  ),

  // RECEIPT 9: Photography Services (srv_003) - customer_004
  Receipt(
    id: 'RCP009',
    orderId: 'ORD-PHOTO-001',
    userId: 'customer_004',
    merchantId: 'org_services',
    organisationId: 'org_services',
    merchantName: 'Professional Photography Services',
    userName: 'Olivia Charles',
    organisationName: 'Services Organization',
    items: [
      CartItem(
        id: 'ci_service_photo_event',
        type: CartItemType.service,
        item: mockServiceItems.firstWhere((s) => s.id == 'event'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 25)),
        selectedTime: const TimeOfDay(hour: 9, minute: 0),
        customizations: {
          'event_type': 'Corporate Conference',
          'expected_guests': 150,
          'additional_photographers': 1,
          'delivery_format': 'Digital + USB',
        },
      ),
    ],
    subtotal: 200.0,
    tax: 20.0,
    discount: 0.0,
    total: 220.0,
    currency: 'USD',
    paymentMethod: 'Credit Card',
    transactionId: 'TXN-2026-009',
    notes: 'Event photography for TechConf',
    metadata: {
      'service_id': 'srv_003',
      'service_name': 'Professional Photography Services',
      'coverage_hours': 4,
    },
    status: ReceiptStatus.pending,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    paidAt: null,
    fulfilledAt: null,
  ),

  // RECEIPT 10: Multiple Items - Hotel + Event + Services - customer_005
  Receipt(
    id: 'RCP010',
    orderId: 'ORD-PKG-001',
    userId: 'customer_005',
    merchantId: 'org_hospitality',
    organisationId: 'org_hospitality',
    merchantName: 'Courtyard by Marriott Port of Spain',
    userName: 'Daniel Khan',
    organisationName: 'Hospitality Organization',
    items: [
      CartItem(
        id: 'ci_room_007',
        type: CartItemType.room,
        item: mockRooms.firstWhere((r) => r.id == 'room_007'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 45)),
        customizations: {
          'check_in': DateTime.now()
              .add(const Duration(days: 45))
              .toIso8601String(),
          'check_out': DateTime.now()
              .add(const Duration(days: 48))
              .toIso8601String(),
          'nights': 3,
          'guests': 3,
        },
      ),
      CartItem(
        id: 'ci_ticket_013',
        type: CartItemType.ticket,
        item: testTickets.firstWhere((t) => t.id == 'ticket_013'),
        quantity: 2,
        selectedDate: DateTime.now().add(const Duration(days: 15)),
      ),
    ],
    subtotal: 1100.0,
    tax: 110.0,
    discount: 100.0,
    total: 1110.0,
    currency: 'USD',
    paymentMethod: 'Credit Card',
    transactionId: 'TXN-2026-010',
    notes: 'Complete package - Hotel + Events',
    metadata: {
      'package_type': 'Full Experience',
      'includes': ['Hotel', 'Events'],
      'duration_days': 3,
    },
    status: ReceiptStatus.purchased,
    createdAt: DateTime.now().subtract(const Duration(days: 15)),
    updatedAt: DateTime.now().subtract(const Duration(days: 14)),
    paidAt: DateTime.now().subtract(const Duration(days: 15)),
    fulfilledAt: DateTime.now().subtract(const Duration(days: 14)),
  ),

  // RECEIPT 11: Cancelled Order - customer_001
  Receipt(
    id: 'RCP011',
    orderId: 'ORD-CANCELLED-001',
    userId: 'customer_001',
    merchantId: 'org_hospitality',
    organisationId: 'org_hospitality',
    merchantName: 'Store Bay Beach Resort',
    userName: 'James Wilson',
    organisationName: 'Hospitality Organization',
    items: [
      CartItem(
        id: 'ci_room_009',
        type: CartItemType.room,
        item: mockRooms.firstWhere((r) => r.id == 'room_009'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 60)),
        customizations: {
          'check_in': DateTime.now()
              .add(const Duration(days: 60))
              .toIso8601String(),
          'check_out': DateTime.now()
              .add(const Duration(days: 65))
              .toIso8601String(),
          'nights': 5,
          'guests': 4,
        },
      ),
    ],
    subtotal: 1400.0,
    tax: 140.0,
    discount: 0.0,
    total: 1540.0,
    currency: 'USD',
    paymentMethod: 'Credit Card',
    transactionId: 'TXN-2026-011',
    notes: 'Cancelled - Customer requested refund',
    metadata: {
      'hotel_id': 'htl_005',
      'hotel_name': 'Store Bay Beach Resort',
      'cancellation_reason': 'Travel restrictions',
    },
    status: ReceiptStatus.cancelled,
    createdAt: DateTime.now().subtract(const Duration(days: 20)),
    updatedAt: DateTime.now().subtract(const Duration(days: 18)),
    paidAt: DateTime.now().subtract(const Duration(days: 20)),
    fulfilledAt: null,
  ),

  // RECEIPT 12: Refunded Order - customer_001
  Receipt(
    id: 'RCP012',
    orderId: 'ORD-REFUND-001',
    userId: 'customer_001',
    merchantId: 'org_tech_conf',
    organisationId: 'org_tech_conf',
    merchantName: 'Caribbean AI & Machine Learning Summit',
    userName: 'James Wilson',
    organisationName: 'Tech Conference Organization',
    items: [
      CartItem(
        id: 'ci_ticket_009',
        type: CartItemType.ticket,
        item: testTickets.firstWhere((t) => t.id == 'ticket_009'),
        quantity: 3,
        selectedDate: DateTime.now().add(const Duration(days: 120)),
      ),
    ],
    subtotal: 297.0,
    tax: 29.7,
    discount: 0.0,
    total: 326.7,
    currency: 'USD',
    paymentMethod: 'Credit Card',
    transactionId: 'TXN-2026-012',
    notes: 'Refunded - Duplicate purchase',
    metadata: {
      'event_id': 'evt_003',
      'event_name': 'Caribbean AI Summit',
      'refund_reason': 'Duplicate order',
    },
    status: ReceiptStatus.refunded,
    createdAt: DateTime.now().subtract(const Duration(days: 8)),
    updatedAt: DateTime.now().subtract(const Duration(days: 7)),
    paidAt: DateTime.now().subtract(const Duration(days: 8)),
    fulfilledAt: null,
  ),

  // RECEIPT 13: Store Bay Beach Resort (htl_005) - customer_008
  Receipt(
    id: 'RCP013',
    orderId: 'ORD-HTL-005',
    userId: 'customer_008',
    merchantId: 'org_hospitality',
    organisationId: 'org_hospitality',
    merchantName: 'Store Bay Beach Resort',
    userName: 'Samantha Hosein',
    organisationName: 'Hospitality Organization',
    items: [
      CartItem(
        id: 'ci_room_010',
        type: CartItemType.room,
        item: mockRooms.firstWhere((r) => r.id == 'room_010'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 2)),
        customizations: {
          'check_in': DateTime.now()
              .add(const Duration(days: 2))
              .toIso8601String(),
          'check_out': DateTime.now()
              .add(const Duration(days: 5))
              .toIso8601String(),
          'nights': 3,
          'guests': 6,
          'special_requests': 'Connecting rooms for family',
        },
      ),
    ],
    subtotal: 1050.0,
    tax: 105.0,
    discount: 50.0,
    total: 1105.0,
    currency: 'USD',
    paymentMethod: 'Credit Card',
    transactionId: 'TXN-2026-013',
    notes: 'Family vacation',
    metadata: {
      'hotel_id': 'htl_005',
      'hotel_name': 'Store Bay Beach Resort',
      'booking_type': 'Family',
      'nights': 3,
    },
    status: ReceiptStatus.checked,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now(),
    paidAt: DateTime.now().subtract(const Duration(days: 1)),
    fulfilledAt: DateTime.now(),
  ),

  // RECEIPT 14: Single Ticket Purchase - customer_007
  Receipt(
    id: 'RCP014',
    orderId: 'ORD-SINGLE-001',
    userId: 'customer_007',
    merchantId: 'org_music',
    organisationId: 'org_music',
    merchantName: 'Soca & Steelpan Night',
    userName: 'Ryan Campbell',
    organisationName: 'Music Organization',
    items: [
      CartItem(
        id: 'ci_ticket_single',
        type: CartItemType.ticket,
        item: testTickets.firstWhere((t) => t.id == 'ticket_014'),
        quantity: 1,
        selectedDate: DateTime.now().add(const Duration(days: 15)),
      ),
    ],
    subtotal: 75.0,
    tax: 7.5,
    discount: 0.0,
    total: 82.5,
    currency: 'USD',
    paymentMethod: 'Credit Card',
    transactionId: 'TXN-2026-014',
    notes: 'Single premium seat',
    metadata: {
      'event_id': 'evt_005',
      'event_name': 'Soca & Steelpan Night',
      'seat_number': 'A12',
    },
    status: ReceiptStatus.purchased,
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
    updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    paidAt: DateTime.now().subtract(const Duration(days: 4)),
    fulfilledAt: DateTime.now().subtract(const Duration(days: 3)),
  ),

  // RECEIPT 15: Large Group Booking - customer_006
  Receipt(
    id: 'RCP015',
    orderId: 'ORD-GROUP-001',
    userId: 'customer_006',
    merchantId: 'org_hospitality',
    organisationId: 'org_hospitality',
    merchantName: 'Hyatt Regency Trinidad',
    userName: 'Chloe Ramsay',
    organisationName: 'Hospitality Organization',
    items: [
      CartItem(
        id: 'ci_room_002',
        type: CartItemType.room,
        item: mockRooms.firstWhere((r) => r.id == 'room_002'),
        quantity: 3,
        selectedDate: DateTime.now().add(const Duration(days: 30)),
        customizations: {
          'check_in': DateTime.now()
              .add(const Duration(days: 30))
              .toIso8601String(),
          'check_out': DateTime.now()
              .add(const Duration(days: 33))
              .toIso8601String(),
          'nights': 3,
          'guests': 6,
          'room_numbers': ['101', '102', '103'],
        },
      ),
      CartItem(
        id: 'ci_service_aroma',
        type: CartItemType.service,
        item: mockServiceItems.firstWhere((s) => s.id == 'spa_aroma'),
        quantity: 3,
        selectedDate: DateTime.now().add(const Duration(days: 31)),
        selectedTime: const TimeOfDay(hour: 16, minute: 0),
      ),
    ],
    subtotal: 1350.0,
    tax: 135.0,
    discount: 200.0,
    total: 1285.0,
    currency: 'USD',
    paymentMethod: 'Credit Card',
    transactionId: 'TXN-2026-015',
    notes: 'Corporate group booking - 3 rooms',
    metadata: {
      'hotel_id': 'htl_001',
      'hotel_name': 'Hyatt Regency Trinidad',
      'booking_type': 'Corporate',
      'rooms': 3,
      'guests': 6,
    },
    status: ReceiptStatus.purchased,
    createdAt: DateTime.now().subtract(const Duration(days: 25)),
    updatedAt: DateTime.now().subtract(const Duration(days: 24)),
    paidAt: DateTime.now().subtract(const Duration(days: 25)),
    fulfilledAt: DateTime.now().subtract(const Duration(days: 24)),
  ),
];
