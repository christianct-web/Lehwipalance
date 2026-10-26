import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

class Ticket implements Identifiable, Timestamped {
  // Core identifiers
  @override
  final String id;
  // Metadata
  @override
  final DateTime createdAt;
  @override
  DateTime? updatedAt;

  final String ticketNumber;
  final String qrCode;

  final String eventId;
  final String eventName;
  final String ticketTypeId;
  final String ticketTypeName;
  // final Media media;
  final String? ticketTypeImageUrl;
  final String description;
  final bool requiresApproval; //

  // Attendee info
  final String attendeeName;
  final String attendeeEmail;
  final String? attendeePhone;

  // Purchase details
  final DateTime purchaseDate;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final double taxAmount;
  final double total;
  final double creditsUsed;
  final String? transactionId;
  final PaymentMethodType paymentMethod;

  // Status tracking
  TicketStatus status;
  DateTime? checkInTime;
  DateTime? cancellationTime;
  DateTime? refundTime;
  DateTime? approvalTime;
  String? cancellationReason;
  String? checkInBy;
  String? approvedBy;

  Ticket({
    required this.id,
    required this.ticketNumber,
    required this.qrCode,
    required this.eventId,
    required this.eventName,
    required this.ticketTypeId,
    required this.ticketTypeName,
    this.ticketTypeImageUrl,
    required this.description,
    required this.requiresApproval,
    required this.attendeeName,
    required this.attendeeEmail,
    this.attendeePhone,
    required this.purchaseDate,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    required this.creditsUsed,
    this.transactionId,
    required this.paymentMethod,
    this.status = TicketStatus.pending,
    this.checkInTime,
    this.cancellationTime,
    this.refundTime,
    this.approvalTime,
    this.cancellationReason,
    this.checkInBy,
    this.approvedBy,
    required this.createdAt,
    this.updatedAt,
  });

  // Factory constructor for creating from mock data
  factory Ticket.mock({
    String? id,
    String? ticketNumber,
    String? eventId,
    String? eventName,
    String? ticketTypeId,
    String? ticketTypeName,
    String? attendeeName,
    String? attendeeEmail,
    double? price,
    TicketStatus? status,
    DateTime? purchaseDate,
    bool? requiresApproval,
  }) {
    final now = DateTime.now();
    return Ticket(
      id: id ?? 'ticket_${now.millisecondsSinceEpoch}',
      ticketNumber:
          ticketNumber ?? 'TKT${now.millisecond.toString().padLeft(6, '0')}',
      qrCode: 'QR$ticketNumber',
      eventId: eventId ?? 'event_1',
      eventName: eventName ?? 'Sample Event',
      ticketTypeId: ticketTypeId ?? 'type_1',
      ticketTypeName: ticketTypeName ?? 'General Admission',
      ticketTypeImageUrl: null,
      description: 'Access to all sessions',
      requiresApproval: requiresApproval ?? false,
      attendeeName: attendeeName ?? 'John Doe',
      attendeeEmail: attendeeEmail ?? 'john@example.com',
      attendeePhone: '+1234567890',
      purchaseDate: purchaseDate ?? now.subtract(const Duration(days: 1)),
      quantity: 1,
      unitPrice: price ?? 49.99,
      subtotal: price ?? 49.99,
      taxAmount: (price ?? 49.99) * 0.1,
      total: (price ?? 49.99) * 1.1,
      creditsUsed: 0,
      transactionId: 'txn_${now.millisecondsSinceEpoch}',
      paymentMethod: PaymentMethodType.creditCard,
      status: status ?? TicketStatus.pending,
      createdAt: now,
    );
  }

  // Create from purchase data and ticket type
  factory Ticket.fromPurchase({
    required Map<String, dynamic> purchaseData,
    required TicketDTO ticketType,
    required String eventName,
  }) {
    final now = DateTime.now();
    return Ticket(
      id: purchaseData['id'] ?? now.millisecondsSinceEpoch.toString(),
      ticketNumber: purchaseData['ticketNumber'] ?? 'TKT${now.millisecond}',
      qrCode: purchaseData['barcodeData'] ?? 'QR${now.millisecondsSinceEpoch}',
      eventId: purchaseData['eventId'],
      eventName: eventName,
      ticketTypeId: ticketType.id,
      ticketTypeName: ticketType.name,
      ticketTypeImageUrl: ticketType.imageUrl,
      description: ticketType.description,
      requiresApproval: ticketType.requiresApproval,
      attendeeName: purchaseData['attendeeName'] ?? 'Unknown',
      attendeeEmail: purchaseData['attendeeEmail'] ?? 'unknown@email.com',
      attendeePhone: purchaseData['attendeePhone'],
      purchaseDate: DateTime.parse(
        purchaseData['purchaseDate'] ?? now.toIso8601String(),
      ),
      quantity: purchaseData['quantity'] ?? 1,
      unitPrice: ticketType.price,
      subtotal:
          (purchaseData['subtotal'] as num?)?.toDouble() ?? ticketType.price,
      taxAmount: (purchaseData['taxAmount'] as num?)?.toDouble() ?? 0,
      total: (purchaseData['total'] as num?)?.toDouble() ?? ticketType.price,
      creditsUsed: (purchaseData['creditsUsed'] as num?)?.toDouble() ?? 0,
      transactionId: purchaseData['transactionId'],
      paymentMethod: PaymentMethodType.values.firstWhere(
        (e) => e.name == (purchaseData['paymentMethod'] ?? 'creditCard'),
        orElse: () => PaymentMethodType.creditCard,
      ),
      status: TicketStatus.values[purchaseData['status'] ?? 0],
      checkInTime: purchaseData['checkInTime'] != null
          ? DateTime.parse(purchaseData['checkInTime'])
          : null,
      cancellationTime: purchaseData['cancellationTime'] != null
          ? DateTime.parse(purchaseData['cancellationTime'])
          : null,
      refundTime: purchaseData['refundTime'] != null
          ? DateTime.parse(purchaseData['refundTime'])
          : null,
      approvalTime: purchaseData['approvalTime'] != null
          ? DateTime.parse(purchaseData['approvalTime'])
          : null,
      cancellationReason: purchaseData['cancellationReason'],
      checkInBy: purchaseData['checkInBy'],
      approvedBy: purchaseData['approvedBy'],
      createdAt: DateTime.parse(
        purchaseData['createdAt'] ?? now.toIso8601String(),
      ),
      updatedAt: purchaseData['updatedAt'] != null
          ? DateTime.parse(purchaseData['updatedAt'])
          : null,
    );
  }

  // Computed properties
  String get formattedDate =>
      DateFormat('MMM dd, yyyy - hh:mm a').format(purchaseDate);

  String get formattedCheckInTime => checkInTime != null
      ? DateFormat('MMM dd, yyyy - hh:mm a').format(checkInTime!)
      : 'Not checked in';

  bool get isActive =>
      status == TicketStatus.pending || status == TicketStatus.approved;
  bool get canCheckIn =>
      status == TicketStatus.pending || status == TicketStatus.approved;
  bool get canCancel =>
      status != TicketStatus.cancelled && status != TicketStatus.refunded;
  bool get canRefund =>
      status == TicketStatus.checkedIn || status == TicketStatus.checked;

  double get taxPercentage => subtotal > 0 ? (taxAmount / subtotal) * 100 : 0;

  String get priceDisplay {
    return '\$${unitPrice.toStringAsFixed(2)}';
  }

  String get totalDisplay {
    return '\$${total.toStringAsFixed(2)}';
  }

  Color Function(BuildContext context) get statusColor => status.getColor;
  IconData get statusIcon => status.icon;

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketNumber': ticketNumber,
      'qrCode': qrCode,
      'eventId': eventId,
      'eventName': eventName,
      'ticketTypeId': ticketTypeId,
      'ticketTypeName': ticketTypeName,
      'ticketTypeImageUrl': ticketTypeImageUrl,
      'description': description,
      'requiresApproval': requiresApproval,
      'attendeeName': attendeeName,
      'attendeeEmail': attendeeEmail,
      'attendeePhone': attendeePhone,
      'purchaseDate': purchaseDate.toIso8601String(),
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'total': total,
      'creditsUsed': creditsUsed,
      'transactionId': transactionId,
      'paymentMethod': paymentMethod.name,
      'status': status.index,
      'checkInTime': checkInTime?.toIso8601String(),
      'cancellationTime': cancellationTime?.toIso8601String(),
      'refundTime': refundTime?.toIso8601String(),
      'approvalTime': approvalTime?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'checkInBy': checkInBy,
      'approvedBy': approvedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'],
      ticketNumber: json['ticketNumber'],
      qrCode: json['qrCode'],
      eventId: json['eventId'],
      eventName: json['eventName'],
      ticketTypeId: json['ticketTypeId'],
      ticketTypeName: json['ticketTypeName'],
      ticketTypeImageUrl: json['ticketTypeImageUrl'],
      description: json['description'],
      requiresApproval: json['requiresApproval'] ?? false,
      attendeeName: json['attendeeName'],
      attendeeEmail: json['attendeeEmail'],
      attendeePhone: json['attendeePhone'],
      purchaseDate: DateTime.parse(json['purchaseDate']),
      quantity: json['quantity'],
      unitPrice: json['unitPrice'].toDouble(),
      subtotal: json['subtotal'].toDouble(),
      taxAmount: json['taxAmount'].toDouble(),
      total: json['total'].toDouble(),
      creditsUsed: json['creditsUsed'].toDouble(),
      transactionId: json['transactionId'],
      paymentMethod: PaymentMethodType.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethodType.creditCard,
      ),
      status: TicketStatus.values[json['status']],
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      cancellationTime: json['cancellationTime'] != null
          ? DateTime.parse(json['cancellationTime'])
          : null,
      refundTime: json['refundTime'] != null
          ? DateTime.parse(json['refundTime'])
          : null,
      approvalTime: json['approvalTime'] != null
          ? DateTime.parse(json['approvalTime'])
          : null,
      cancellationReason: json['cancellationReason'],
      checkInBy: json['checkInBy'],
      approvedBy: json['approvedBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Ticket copyWith({
    String? id,
    String? ticketNumber,
    String? qrCode,
    String? eventId,
    String? eventName,
    String? ticketTypeId,
    String? ticketTypeName,
    String? ticketTypeImageUrl,
    String? description,
    bool? requiresApproval,
    String? attendeeName,
    String? attendeeEmail,
    String? attendeePhone,
    DateTime? purchaseDate,
    int? quantity,
    double? unitPrice,
    double? subtotal,
    double? taxAmount,
    double? total,
    double? creditsUsed,
    String? transactionId,
    PaymentMethodType? paymentMethod,
    TicketStatus? status,
    DateTime? checkInTime,
    DateTime? cancellationTime,
    DateTime? refundTime,
    DateTime? approvalTime,
    String? cancellationReason,
    String? checkInBy,
    String? approvedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      qrCode: qrCode ?? this.qrCode,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      ticketTypeId: ticketTypeId ?? this.ticketTypeId,
      ticketTypeName: ticketTypeName ?? this.ticketTypeName,
      ticketTypeImageUrl: ticketTypeImageUrl ?? this.ticketTypeImageUrl,
      description: description ?? this.description,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      attendeeName: attendeeName ?? this.attendeeName,
      attendeeEmail: attendeeEmail ?? this.attendeeEmail,
      attendeePhone: attendeePhone ?? this.attendeePhone,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      creditsUsed: creditsUsed ?? this.creditsUsed,
      transactionId: transactionId ?? this.transactionId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      cancellationTime: cancellationTime ?? this.cancellationTime,
      refundTime: refundTime ?? this.refundTime,
      approvalTime: approvalTime ?? this.approvalTime,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      checkInBy: checkInBy ?? this.checkInBy,
      approvedBy: approvedBy ?? this.approvedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

// Helper classes

// -------------------------------
// Domain Value Object
// -------------------------------

class TicketConfirmModel implements Identifiable {
  @override
  final String id;
  final String eventId;
  final String ticketId;
  final String userId;
  final String confirmedByUserId;
  final int quantity;
  bool isConfirmed;

  TicketConfirmModel({
    required this.id,
    required this.eventId,
    required this.ticketId,
    required this.quantity,
    required this.userId,
    required this.confirmedByUserId,
    this.isConfirmed = false,
  });

  TicketConfirmModel copyWith({
    String? id,
    String? eventId,
    String? ticketId,
    int? quantity,
    String? userId,
    String? confirmedByUserId,
    bool? isConfirmed,
  }) {
    return TicketConfirmModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      ticketId: ticketId ?? this.ticketId,
      quantity: quantity ?? this.quantity,
      userId: userId ?? this.userId,
      confirmedByUserId: confirmedByUserId ?? this.confirmedByUserId,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}

final mocktickets = [
  // Pending tickets
  Ticket.mock(
    id: '1',
    ticketNumber: 'TKT001',
    attendeeName: 'John Smith',
    attendeeEmail: 'john.smith@email.com',
    eventName: 'Tech Conference 2024',
    ticketTypeName: 'General Admission',
    ticketTypeId: 'type_1',
    price: 49.99,
    status: TicketStatus.pending,
    purchaseDate: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Ticket.mock(
    id: '2',
    ticketNumber: 'TKT002',
    attendeeName: 'Sarah Johnson',
    attendeeEmail: 'sarah.j@email.com',
    eventName: 'Tech Conference 2024',
    ticketTypeName: 'VIP Pass',
    ticketTypeId: 'type_2',
    price: 199.99,
    status: TicketStatus.pending,
    purchaseDate: DateTime.now().subtract(const Duration(days: 1)),
    requiresApproval: true,
  ),

  // Checked tickets
  Ticket.mock(
    id: '3',
    ticketNumber: 'TKT003',
    attendeeName: 'Mike Wilson',
    attendeeEmail: 'mike.w@email.com',
    eventName: 'Music Festival',
    ticketTypeName: 'General Admission',
    ticketTypeId: 'type_1',
    price: 79.99,
    status: TicketStatus.checked,
    purchaseDate: DateTime.now().subtract(const Duration(days: 5)),
  )..checkInTime = DateTime.now().subtract(const Duration(hours: 2)),

  // Checked in tickets
  Ticket.mock(
    id: '4',
    ticketNumber: 'TKT004',
    attendeeName: 'Emily Brown',
    attendeeEmail: 'emily.b@email.com',
    eventName: 'Music Festival',
    ticketTypeName: 'VIP Pass',
    ticketTypeId: 'type_2',
    price: 199.99,
    status: TicketStatus.checkedIn,
    purchaseDate: DateTime.now().subtract(const Duration(days: 3)),
  )..checkInTime = DateTime.now().subtract(const Duration(hours: 1)),

  // Approved tickets
  Ticket.mock(
    id: '5',
    ticketNumber: 'TKT005',
    attendeeName: 'David Lee',
    attendeeEmail: 'david.lee@email.com',
    eventName: 'Workshop Series',
    ticketTypeName: 'Early Bird',
    ticketTypeId: 'type_3',
    price: 39.99,
    status: TicketStatus.approved,
    purchaseDate: DateTime.now().subtract(const Duration(days: 7)),
  )..approvalTime = DateTime.now().subtract(const Duration(days: 1)),

  // Cancelled tickets
  Ticket.mock(
      id: '6',
      ticketNumber: 'TKT006',
      attendeeName: 'Lisa Anderson',
      attendeeEmail: 'lisa.a@email.com',
      eventName: 'Workshop Series',
      ticketTypeName: 'Student',
      ticketTypeId: 'type_4',
      price: 29.99,
      status: TicketStatus.cancelled,
      purchaseDate: DateTime.now().subtract(const Duration(days: 4)),
      requiresApproval: true,
    )
    ..cancellationTime = DateTime.now().subtract(const Duration(days: 1))
    ..cancellationReason = 'Personal reasons',

  // Refunded tickets
  Ticket.mock(
      id: '7',
      ticketNumber: 'TKT007',
      attendeeName: 'Robert Taylor',
      attendeeEmail: 'robert.t@email.com',
      eventName: 'Premium Workshop',
      ticketTypeName: 'Premium Package',
      ticketTypeId: 'type_5',
      price: 299.99,
      status: TicketStatus.refunded,
      purchaseDate: DateTime.now().subtract(const Duration(days: 10)),
    )
    ..refundTime = DateTime.now().subtract(const Duration(days: 2))
    ..cancellationReason = 'Duplicate purchase',

  // More pending tickets
  Ticket.mock(
    id: '8',
    ticketNumber: 'TKT008',
    attendeeName: 'Amanda White',
    attendeeEmail: 'amanda.w@email.com',
    eventName: 'Tech Conference 2024',
    ticketTypeName: 'General Admission',
    ticketTypeId: 'type_1',
    price: 49.99,
    status: TicketStatus.pending,
  ),
  Ticket.mock(
    id: '9',
    ticketNumber: 'TKT009',
    attendeeName: 'James Martin',
    attendeeEmail: 'james.m@email.com',
    eventName: 'Music Festival',
    ticketTypeName: 'General Admission',
    ticketTypeId: 'type_1',
    price: 79.99,
    status: TicketStatus.pending,
  ),
  Ticket.mock(
    id: '10',
    ticketNumber: 'TKT010',
    attendeeName: 'Patricia Garcia',
    attendeeEmail: 'patricia.g@email.com',
    eventName: 'Workshop Series',
    ticketTypeName: 'Student',
    ticketTypeId: 'type_4',
    price: 29.99,
    status: TicketStatus.approved,
    requiresApproval: true,
  )..approvalTime = DateTime.now().subtract(const Duration(hours: 5)),
];

// customer ticket model
class TicketDTO implements Identifiable, Timestamped, Publishable {
  @override
  final String id;
  @override
  bool isActive;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  PublishStatus status;

  final String eventId;
  final String name;
  final String? imageUrl;
  final String description;
  final double price;
  final String? currency;
  // Inventory & sales tracking
  final int quantitySold;
  final int? maxQuantity;
  final DateTime salesStartDate;
  final DateTime salesEndDate;
  final bool requiresApproval;
  final bool isOnSale;
  final Duration? purchaseWindow;

  final bool isSoldOut;

  TicketDTO({
    required this.id,
    required this.eventId,
    required this.name,
    this.imageUrl,
    required this.description,
    required this.price,
    this.quantitySold = 0,
    this.maxQuantity,
    required this.salesStartDate,
    required this.salesEndDate,
    this.isOnSale = false,
    this.isSoldOut = false,
    this.requiresApproval = false,
    this.currency,
    this.purchaseWindow,
    // Interface fields
    this.isActive = false,
    this.status = PublishStatus.unpublished,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Derived getters
  bool get isAvailable => isOnSale && !isSoldOut;
  bool get isUpcoming => salesStartDate.isAfter(DateTime.now());
  bool get isExpired => salesEndDate.isBefore(DateTime.now());

  /// Auto-calculated from [maxQuantity] and [quantitySold]
  int? get remainingQuantity =>
      maxQuantity != null ? maxQuantity! - quantitySold : null;

  /// Format price with currency
  String get priceDisplay {
    if (currency != null) {
      return '$currency ${price.toStringAsFixed(2)}';
    }
    return '\$${price.toStringAsFixed(2)}';
  }

  /// Get availability status
  String get availabilityStatus {
    if (isSoldOut) return 'Sold Out';
    if (!isOnSale) return 'Not On Sale';
    if (isExpired) return 'Sales Ended';
    if (isUpcoming) {
      return 'Sales Start ${DateFormat('MMM d').format(salesStartDate)}';
    }
    return 'Available';
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'eventId': eventId,
      'name': name,
      'description': description,
      'price': price,
      'quantitySold': quantitySold,
      'maxQuantity': maxQuantity,
      'salesStartDate': salesStartDate.toIso8601String(),
      'salesEndDate': salesEndDate.toIso8601String(),
      'isOnSale': isOnSale,
      'isSoldOut': isSoldOut,
      'requiresApproval': requiresApproval,
      'currency': currency,
      'purchaseWindow': purchaseWindow?.inMinutes,
      'isActive': isActive,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };

    if (imageUrl != null) map['imageUrl'] = imageUrl;
    if (updatedAt != null) map['updatedAt'] = updatedAt!.toIso8601String();

    return map;
  }

  // Create from JSON
  factory TicketDTO.fromJson(Map<String, dynamic> data) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      return null;
    }

    return TicketDTO(
      id: data['id'] as String,
      eventId: data['eventId'] as String,
      name: data['name'] as String,
      imageUrl: data['imageUrl'] as String?,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      quantitySold: data['quantitySold'] as int? ?? 0,
      maxQuantity: data['maxQuantity'] as int?,
      salesStartDate: parseDateTime(data['salesStartDate']) ?? DateTime.now(),
      salesEndDate: parseDateTime(data['salesEndDate']) ?? DateTime.now(),
      isOnSale: data['isOnSale'] as bool? ?? false,
      isSoldOut: data['isSoldOut'] as bool? ?? false,
      requiresApproval: data['requiresApproval'] as bool? ?? false,
      currency: data['currency'] as String?,
      purchaseWindow: data['purchaseWindow'] != null
          ? Duration(minutes: data['purchaseWindow'] as int)
          : null,
      isActive: data['isActive'] as bool? ?? false,
      status: PublishStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PublishStatus.unpublished,
      ),
      createdAt: parseDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  // Update with partial data
  Map<String, dynamic> toUpdateMap({
    String? name,
    String? description,
    double? price,
    int? quantitySold,
    int? maxQuantity,
    bool? isOnSale,
    bool? isSoldOut,
    bool? requiresApproval,
    String? currency,
    Duration? purchaseWindow,
    bool? isActive,
    PublishStatus? status,
  }) {
    final updateMap = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (name != null) updateMap['name'] = name;
    if (description != null) updateMap['description'] = description;
    if (price != null) updateMap['price'] = price;
    if (quantitySold != null) updateMap['quantitySold'] = quantitySold;
    if (maxQuantity != null) updateMap['maxQuantity'] = maxQuantity;
    if (isOnSale != null) updateMap['isOnSale'] = isOnSale;
    if (isSoldOut != null) updateMap['isSoldOut'] = isSoldOut;
    if (requiresApproval != null) {
      updateMap['requiresApproval'] = requiresApproval;
    }
    if (currency != null) updateMap['currency'] = currency;
    if (purchaseWindow != null) {
      updateMap['purchaseWindow'] = purchaseWindow.inMinutes;
    }
    if (isActive != null) updateMap['isActive'] = isActive;
    if (status != null) updateMap['status'] = status.name;

    return updateMap;
  }

  TicketDTO copyWith({
    String? id,
    String? eventId,
    String? name,
    String? description,
    double? price,
    int? quantitySold,
    int? maxQuantity,
    DateTime? salesStartDate,
    DateTime? salesEndDate,
    bool? isOnSale,
    bool? isSoldOut,
    bool? requiresApproval,
    String? currency,
    Duration? purchaseWindow,
    String? imageUrl,
    bool? isActive,
    PublishStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TicketDTO(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      quantitySold: quantitySold ?? this.quantitySold,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      salesStartDate: salesStartDate ?? this.salesStartDate,
      salesEndDate: salesEndDate ?? this.salesEndDate,
      isOnSale: isOnSale ?? this.isOnSale,
      isSoldOut: isSoldOut ?? this.isSoldOut,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      currency: currency ?? this.currency,
      purchaseWindow: purchaseWindow ?? this.purchaseWindow,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventId': eventId,
      'name': name,
      'description': description,
      'price': price,
      'quantitySold': quantitySold,
      'maxQuantity': maxQuantity,
      'salesStartDate': salesStartDate.toIso8601String(),
      'salesEndDate': salesEndDate.toIso8601String(),
      'isOnSale': isOnSale,
      'isSoldOut': isSoldOut,
      'requiresApproval': requiresApproval,
      'currency': currency,
      'purchaseWindow': purchaseWindow?.inMinutes,
      'isActive': isActive,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'imageUrl': imageUrl,
    };
  }

  factory TicketDTO.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      if (date is DateTime) return date;
      return DateTime.parse(date as String);
    }

    return TicketDTO(
      id: map['id'] as String,
      eventId: map['eventId'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      price: (map['price'] as num).toDouble(),
      quantitySold: map['quantitySold'] as int? ?? 0,
      maxQuantity: map['maxQuantity'] as int?,
      salesStartDate: parseDate(map['salesStartDate']),
      salesEndDate: parseDate(map['salesEndDate']),
      isOnSale: map['isOnSale'] as bool? ?? false,
      isSoldOut: map['isSoldOut'] as bool? ?? false,
      requiresApproval: map['requiresApproval'] as bool? ?? false,
      currency: map['currency'] as String?,
      purchaseWindow: map['purchaseWindow'] != null
          ? Duration(minutes: map['purchaseWindow'] as int)
          : null,
      imageUrl: map['imageUrl'] as String?,
      isActive: map['isActive'] as bool? ?? false,
      status: PublishStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'unpublished'),
        orElse: () => PublishStatus.unpublished,
      ),
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? parseDate(map['updatedAt']) : null,
    );
  }
}

// Updated testTickets with IDs that match EventListingDTO ticketTypeIds
final List<TicketDTO> testTickets = [
  TicketDTO(
    id: 'ticket_001', // Matches evt_001 ticketTypeIds[0]
    eventId: 'evt_001',
    name: 'Early Bird',
    description: 'Access to all conference sessions',
    price: 99.0,
    maxQuantity: 200,
    quantitySold: 180,
    salesStartDate: DateTime.now().subtract(const Duration(days: 30)),
    salesEndDate: DateTime.now().add(const Duration(days: 9)),
    isOnSale: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 35)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TicketDTO(
    id: 'ticket_002', // Matches evt_001 ticketTypeIds[1]
    eventId: 'evt_001',
    name: 'VIP Pass',
    description: 'Includes premium seating and after-party',
    price: 499.0,
    maxQuantity: 50,
    quantitySold: 45,
    salesStartDate: DateTime.now().subtract(const Duration(days: 30)),
    salesEndDate: DateTime.now().add(const Duration(days: 9)),
    isOnSale: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 35)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TicketDTO(
    id: 'ticket_003', // Matches evt_001 ticketTypeIds[2]
    eventId: 'evt_001',
    name: 'Student Discount',
    description: 'Student rate with valid ID',
    price: 49.0,
    maxQuantity: 100,
    quantitySold: 85,
    salesStartDate: DateTime.now().subtract(const Duration(days: 30)),
    salesEndDate: DateTime.now().add(const Duration(days: 9)),
    isOnSale: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 35)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TicketDTO(
    id: 'ticket_004', // Matches evt_001 ticketTypeIds[3]
    eventId: 'evt_001',
    name: 'Workshop Only',
    description: 'Access to workshops only',
    price: 149.0,
    maxQuantity: 150,
    quantitySold: 120,
    salesStartDate: DateTime.now().subtract(const Duration(days: 30)),
    salesEndDate: DateTime.now().add(const Duration(days: 9)),
    isOnSale: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 35)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  // Carnival Kickoff tickets (evt_002)
  TicketDTO(
    id: 'ticket_005', // Matches evt_002 ticketTypeIds[0]
    eventId: 'evt_002',
    name: 'General Admission',
    description: 'Access to all music stages',
    price: 49.0,
    maxQuantity: 2000,
    quantitySold: 1250,
    salesStartDate: DateTime.now().subtract(const Duration(days: 60)),
    salesEndDate: DateTime.now().add(const Duration(days: 29)),
    isOnSale: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 65)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TicketDTO(
    id: 'ticket_006', // Matches evt_002 ticketTypeIds[1]
    eventId: 'evt_002',
    name: 'VIP Pass',
    description: 'Front row access + after-party',
    price: 129.0,
    maxQuantity: 2000,
    quantitySold: 1750,
    salesStartDate: DateTime.now().subtract(const Duration(days: 60)),
    salesEndDate: DateTime.now().add(const Duration(days: 29)),
    isOnSale: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 65)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TicketDTO(
    id: 'ticket_007', // Matches evt_002 ticketTypeIds[2]
    eventId: 'evt_002',
    name: 'All-Access Pass',
    description: 'Includes backstage access',
    price: 199.0,
    maxQuantity: 1000,
    quantitySold: 950,
    salesStartDate: DateTime.now().subtract(const Duration(days: 60)),
    salesEndDate: DateTime.now().add(const Duration(days: 29)),
    isOnSale: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 65)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  // Caribbean AI Summit tickets (evt_003)
  TicketDTO(
    id: 'ticket_008', // Matches evt_003 ticketTypeIds[0]
    eventId: 'evt_003',
    name: 'Standard Pass',
    description: 'Access to all sessions',
    price: 199.0,
    maxQuantity: 300,
    quantitySold: 250,
    salesStartDate: DateTime.now().subtract(const Duration(days: 45)),
    salesEndDate: DateTime.now().add(const Duration(days: 90)),
    isOnSale: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 50)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TicketDTO(
    id: 'ticket_009', // Matches evt_003 ticketTypeIds[1]
    eventId: 'evt_003',
    name: 'Student Pass',
    description: 'Student discount with valid ID',
    price: 99.0,
    maxQuantity: 100,
    quantitySold: 95,
    salesStartDate: DateTime.now().subtract(const Duration(days: 45)),
    salesEndDate: DateTime.now().add(const Duration(days: 90)),
    isOnSale: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 50)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TicketDTO(
    id: 'ticket_010', // Matches evt_003 ticketTypeIds[2]
    eventId: 'evt_003',
    name: 'Workshop Pass',
    description: 'Hands-on workshop access',
    price: 299.0,
    maxQuantity: 50,
    quantitySold: 48,
    salesStartDate: DateTime.now().subtract(const Duration(days: 45)),
    salesEndDate: DateTime.now().add(const Duration(days: 90)),
    isOnSale: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 50)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  // Startup Pitch Competition tickets (evt_004)
  TicketDTO(
    id: 'ticket_011', // Matches evt_004 ticketTypeIds[0]
    eventId: 'evt_004',
    name: 'General Admission',
    description: 'Observer pass',
    price: 0.0,
    maxQuantity: 200,
    quantitySold: 120,
    salesStartDate: DateTime.now().subtract(const Duration(days: 30)),
    salesEndDate: DateTime.now().add(const Duration(days: 19)),
    isOnSale: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 35)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TicketDTO(
    id: 'ticket_012', // Matches evt_004 ticketTypeIds[1]
    eventId: 'evt_004',
    name: 'Investor Pass',
    description: 'Includes networking reception',
    price: 50.0,
    maxQuantity: 100,
    quantitySold: 85,
    salesStartDate: DateTime.now().subtract(const Duration(days: 30)),
    salesEndDate: DateTime.now().add(const Duration(days: 19)),
    isOnSale: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 35)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  // Soca & Steelpan Night tickets (evt_005)
  TicketDTO(
    id: 'ticket_013', // Matches evt_005 ticketTypeIds[0]
    eventId: 'evt_005',
    name: 'General Admission',
    description: 'Standard seating',
    price: 25.0,
    maxQuantity: 150,
    quantitySold: 150,
    salesStartDate: DateTime.now().subtract(const Duration(days: 30)),
    salesEndDate: DateTime.now().add(const Duration(days: 14)),
    isOnSale: true,
    isSoldOut: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 35)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TicketDTO(
    id: 'ticket_014', // Matches evt_005 ticketTypeIds[1]
    eventId: 'evt_005',
    name: 'Premium Seating',
    description: 'Front row with table service',
    price: 75.0,
    maxQuantity: 50,
    quantitySold: 45,
    salesStartDate: DateTime.now().subtract(const Duration(days: 30)),
    salesEndDate: DateTime.now().add(const Duration(days: 14)),
    isOnSale: true,
    currency: 'USD',
    isActive: true,
    status: PublishStatus.published,
    createdAt: DateTime.now().subtract(const Duration(days: 35)),
    updatedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];
