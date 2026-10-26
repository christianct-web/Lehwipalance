import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lehwipalancecustomerv1/core/base/identifiable.dart';

// Missing enum for TicketStatus
enum TicketStatus { pending, checked, checkedIn, cancelled, refunded, approved }

// Missing enum for ServiceStatus
enum ServiceStatus { pending, completed, cancelled, refunded }

class ReceiptApiModel implements Identifiable {
  @override
  final String id;
  final String userId;
  final String? merchantId;
  final PurchaseType type;
  final String title;
  final String description;
  final double amount;
  final String currency;
  final DateTime purchaseDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> ticketIds; // List of associated ticket IDs
  final List<String>? accommodationIds; // List of associated accommodation IDs
  final List<String>? serviceIds; // List of associated event IDs

  ReceiptApiModel({
    required this.id,
    required this.userId,
    this.merchantId,
    required this.type,
    required this.title,
    required this.description,
    required this.amount,
    required this.currency,
    required this.purchaseDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.ticketIds = const [],
    this.accommodationIds = const [],
    this.serviceIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'merchantId': merchantId,
      'type': type.name,
      'title': title,
      'description': description,
      'amount': amount,
      'currency': currency,
      'purchaseDate': purchaseDate.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'ticketIds': ticketIds,
      'accommodationIds': accommodationIds,
      'serviceIds': serviceIds,
    };
  }

  factory ReceiptApiModel.fromJson(Map<String, dynamic> json) {
    return ReceiptApiModel(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      type: PurchaseType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'linx'),
        orElse: () => PurchaseType.linx,
      ),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'USD',
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'])
          : DateTime.now(),
      merchantId: json['merchantId'],
      status: json['status'] ?? 'completed',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      ticketIds: List<String>.from(json['ticketIds'] ?? []),
      accommodationIds: json['accommodationIds'] != null
          ? List<String>.from(json['accommodationIds'])
          : null,
      serviceIds: json['serviceIds'] != null
          ? List<String>.from(json['serviceIds'])
          : null,
    );
  }

  ReceiptApiModel copyWith({
    String? id,
    String? userId,
    PurchaseType? type,
    String? title,
    String? description,
    double? amount,
    String? currency,
    DateTime? purchaseDate,
    String? merchantId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? ticketIds,
    List<String>? accommodationIds,
    List<String>? serviceIds,
  }) {
    return ReceiptApiModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      merchantId: merchantId ?? this.merchantId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ticketIds: ticketIds ?? this.ticketIds,
      accommodationIds: accommodationIds ?? this.accommodationIds,
      serviceIds: serviceIds ?? this.serviceIds,
    );
  }

  String get formattedDate {
    final formatter = DateFormat('MMM dd, yyyy • hh:mm a');
    return formatter.format(purchaseDate);
  }

  String get formattedAmount {
    final formatter = NumberFormat.currency(symbol: '\$');
    return formatter.format(amount);
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      case 'refunded':
        return Icons.refresh;
      default:
        return Icons.receipt;
    }
  }
}

enum PurchaseType { linx, creditCard, paypal }

class IssuedTicket implements Identifiable {
  @override
  final String id;
  final String receiptId; // Link to receipt
  final String ticketNumber;
  final String merchantId;
  final String eventName;
  final String ticketName;
  final DateTime purchaseDate;
  final double price;
  TicketStatus status;
  DateTime? checkInTime;
  DateTime? cancellationTime;
  DateTime? refundTime;
  String? cancellationReason;
  String? scannedBy;
  String qrCodeData; // Unique QR code data for each ticket
  String barcodeNumber; // Human-readable barcode number

  IssuedTicket({
    required this.id,
    required this.ticketNumber,
    required this.receiptId,
    required this.merchantId,
    required this.eventName,
    required this.ticketName,
    required this.purchaseDate,
    required this.price,
    this.status = TicketStatus.pending,
    this.checkInTime,
    this.cancellationTime,
    this.refundTime,
    this.cancellationReason,
    this.scannedBy,
    required this.qrCodeData,
    required this.barcodeNumber,
  });

  IssuedTicket copyWith({
    String? id,
    String? ticketNumber,
    String? receiptId,
    String? merchantId,
    String? eventName,
    String? ticketName,
    DateTime? purchaseDate,
    double? price,
    TicketStatus? status,
    DateTime? checkInTime,
    DateTime? cancellationTime,
    DateTime? refundTime,
    String? cancellationReason,
    String? scannedBy,
    String? qrCodeData,
    String? barcodeNumber,
  }) {
    return IssuedTicket(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      receiptId: receiptId ?? this.receiptId,
      merchantId: merchantId ?? this.merchantId,
      eventName: eventName ?? this.eventName,
      ticketName: ticketName ?? this.ticketName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      price: price ?? this.price,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      cancellationTime: cancellationTime ?? this.cancellationTime,
      refundTime: refundTime ?? this.refundTime,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      scannedBy: scannedBy ?? this.scannedBy,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      barcodeNumber: barcodeNumber ?? this.barcodeNumber,
    );
  }

  // Generate unique QR code data
  static String generateQRCodeData({
    required String ticketId,
    required String merchantId,
    required String ticketNumber,
  }) {
    return 'TICKET:$ticketId:EVENT:$merchantId:NO:$ticketNumber:${DateTime.now().millisecondsSinceEpoch}';
  }

  // Generate human-readable barcode number
  static String generateBarcodeNumber() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomDigits = List.generate(6, (_) => random.nextInt(10)).join();
    return 'T${timestamp.substring(timestamp.length - 8)}$randomDigits';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketNumber': ticketNumber,
      'receiptId': receiptId,
      'merchantId': merchantId,
      'eventName': eventName,
      'ticketName': ticketName,
      'purchaseDate': purchaseDate.toIso8601String(),
      'price': price,
      'status': status.index,
      'checkInTime': checkInTime?.toIso8601String(),
      'cancellationTime': cancellationTime?.toIso8601String(),
      'refundTime': refundTime?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'scannedBy': scannedBy,
      'qrCodeData': qrCodeData,
      'barcodeNumber': barcodeNumber,
    };
  }

  factory IssuedTicket.fromJson(Map<String, dynamic> json) {
    return IssuedTicket(
      id: json['id'] ?? '',
      ticketNumber: json['ticketNumber'] ?? '',
      receiptId: json['receiptId'] ?? '',
      merchantId: json['merchantId'] ?? '',
      eventName: json['eventName'] ?? '',
      ticketName: json['ticketName'] ?? '',
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'])
          : DateTime.now(),
      price: (json['price'] ?? 0.0).toDouble(),
      status: json['status'] != null
          ? TicketStatus.values[json['status']]
          : TicketStatus.pending,
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      cancellationTime: json['cancellationTime'] != null
          ? DateTime.parse(json['cancellationTime'])
          : null,
      refundTime: json['refundTime'] != null
          ? DateTime.parse(json['refundTime'])
          : null,
      cancellationReason: json['cancellationReason'],
      scannedBy: json['scannedBy'],
      qrCodeData: json['qrCodeData'] ?? '',
      barcodeNumber: json['barcodeNumber'] ?? '',
    );
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(purchaseDate);
  }

  String get formattedCheckInTime {
    return checkInTime != null
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(checkInTime!)
        : 'Not checked in';
  }

  String get statusString {
    return status.toString().split('.').last;
  }

  Color get statusColor {
    switch (status) {
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
}

class IssuedRoom implements Identifiable {
  @override
  final String id;
  final String receiptId; // Link to receipt
  final String ticketNumber;
  final String merchantId;
  final String eventName;
  final String ticketName;
  final DateTime purchaseDate;
  final double price;
  TicketStatus status;
  DateTime? checkInTime;
  DateTime? cancellationTime;
  DateTime? refundTime;
  String? cancellationReason;
  String? scannedBy;
  String qrCodeData; // Unique QR code data for each ticket
  String barcodeNumber; // Human-readable barcode number

  IssuedRoom({
    required this.id,
    required this.ticketNumber,
    required this.receiptId,
    required this.merchantId,
    required this.eventName,
    required this.ticketName,
    required this.purchaseDate,
    required this.price,
    this.status = TicketStatus.pending,
    this.checkInTime,
    this.cancellationTime,
    this.refundTime,
    this.cancellationReason,
    this.scannedBy,
    required this.qrCodeData,
    required this.barcodeNumber,
  });

  IssuedRoom copyWith({
    String? id,
    String? ticketNumber,
    String? receiptId,
    String? merchantId,
    String? eventName,
    String? ticketName,
    DateTime? purchaseDate,
    double? price,
    TicketStatus? status,
    DateTime? checkInTime,
    DateTime? cancellationTime,
    DateTime? refundTime,
    String? cancellationReason,
    String? scannedBy,
    String? qrCodeData,
    String? barcodeNumber,
  }) {
    return IssuedRoom(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      receiptId: receiptId ?? this.receiptId,
      merchantId: merchantId ?? this.merchantId,
      eventName: eventName ?? this.eventName,
      ticketName: ticketName ?? this.ticketName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      price: price ?? this.price,
      status: status ?? this.status,
      checkInTime: checkInTime ?? this.checkInTime,
      cancellationTime: cancellationTime ?? this.cancellationTime,
      refundTime: refundTime ?? this.refundTime,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      scannedBy: scannedBy ?? this.scannedBy,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      barcodeNumber: barcodeNumber ?? this.barcodeNumber,
    );
  }

  // Generate unique QR code data
  static String generateQRCodeData({
    required String ticketId,
    required String merchantId,
    required String ticketNumber,
  }) {
    return 'ROOM:$ticketId:PROPERTY:$merchantId:NO:$ticketNumber:${DateTime.now().millisecondsSinceEpoch}';
  }

  // Generate human-readable barcode number
  static String generateBarcodeNumber() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final randomDigits = List.generate(6, (_) => random.nextInt(10)).join();
    return 'R${timestamp.substring(timestamp.length - 8)}$randomDigits';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketNumber': ticketNumber,
      'receiptId': receiptId,
      'merchantId': merchantId,
      'eventName': eventName,
      'ticketName': ticketName,
      'purchaseDate': purchaseDate.toIso8601String(),
      'price': price,
      'status': status.index,
      'checkInTime': checkInTime?.toIso8601String(),
      'cancellationTime': cancellationTime?.toIso8601String(),
      'refundTime': refundTime?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'scannedBy': scannedBy,
      'qrCodeData': qrCodeData,
      'barcodeNumber': barcodeNumber,
    };
  }

  factory IssuedRoom.fromJson(Map<String, dynamic> json) {
    return IssuedRoom(
      id: json['id'] ?? '',
      ticketNumber: json['ticketNumber'] ?? '',
      receiptId: json['receiptId'] ?? '',
      merchantId: json['merchantId'] ?? '',
      eventName: json['eventName'] ?? '',
      ticketName: json['ticketName'] ?? '',
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'])
          : DateTime.now(),
      price: (json['price'] ?? 0.0).toDouble(),
      status: json['status'] != null
          ? TicketStatus.values[json['status']]
          : TicketStatus.pending,
      checkInTime: json['checkInTime'] != null
          ? DateTime.parse(json['checkInTime'])
          : null,
      cancellationTime: json['cancellationTime'] != null
          ? DateTime.parse(json['cancellationTime'])
          : null,
      refundTime: json['refundTime'] != null
          ? DateTime.parse(json['refundTime'])
          : null,
      cancellationReason: json['cancellationReason'],
      scannedBy: json['scannedBy'],
      qrCodeData: json['qrCodeData'] ?? '',
      barcodeNumber: json['barcodeNumber'] ?? '',
    );
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(purchaseDate);
  }

  String get formattedCheckInTime {
    return checkInTime != null
        ? DateFormat('MMM dd, yyyy - hh:mm a').format(checkInTime!)
        : 'Not checked in';
  }

  String get statusString {
    return status.toString().split('.').last;
  }

  Color get statusColor {
    switch (status) {
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
}

class IssuedService implements Identifiable {
  @override
  final String id;
  final String receiptId; // Link to receipt
  final String serviceName;
  final String description;
  final DateTime purchaseDate;
  final double price;
  ServiceStatus status;
  DateTime? completionTime;
  DateTime? cancellationTime;
  DateTime? refundTime;
  String? cancellationReason;
  String? completedBy;

  IssuedService({
    required this.id,
    required this.receiptId,
    required this.serviceName,
    required this.description,
    required this.purchaseDate,
    required this.price,
    this.status = ServiceStatus.pending,
    this.completionTime,
    this.cancellationTime,
    this.refundTime,
    this.cancellationReason,
    this.completedBy,
  });

  IssuedService copyWith({
    String? id,
    String? receiptId,
    String? serviceName,
    String? description,
    DateTime? purchaseDate,
    double? price,
    ServiceStatus? status,
    DateTime? completionTime,
    DateTime? cancellationTime,
    DateTime? refundTime,
    String? cancellationReason,
    String? completedBy,
  }) {
    return IssuedService(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      serviceName: serviceName ?? this.serviceName,
      description: description ?? this.description,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      price: price ?? this.price,
      status: status ?? this.status,
      completionTime: completionTime ?? this.completionTime,
      cancellationTime: cancellationTime ?? this.cancellationTime,
      refundTime: refundTime ?? this.refundTime,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      completedBy: completedBy ?? this.completedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiptId': receiptId,
      'serviceName': serviceName,
      'description': description,
      'purchaseDate': purchaseDate.toIso8601String(),
      'price': price,
      'status': status.index,
      'completionTime': completionTime?.toIso8601String(),
      'cancellationTime': cancellationTime?.toIso8601String(),
      'refundTime': refundTime?.toIso8601String(),
      'cancellationReason': cancellationReason,
      'completedBy': completedBy,
    };
  }

  factory IssuedService.fromJson(Map<String, dynamic> json) {
    return IssuedService(
      id: json['id'] ?? '',
      receiptId: json['receiptId'] ?? '',
      serviceName: json['serviceName'] ?? '',
      description: json['description'] ?? '',
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'])
          : DateTime.now(),
      price: (json['price'] ?? 0.0).toDouble(),
      status: json['status'] != null
          ? ServiceStatus.values[json['status']]
          : ServiceStatus.pending,
      completionTime: json['completionTime'] != null
          ? DateTime.parse(json['completionTime'])
          : null,
      cancellationTime: json['cancellationTime'] != null
          ? DateTime.parse(json['cancellationTime'])
          : null,
      refundTime: json['refundTime'] != null
          ? DateTime.parse(json['refundTime'])
          : null,
      cancellationReason: json['cancellationReason'],
      completedBy: json['completedBy'],
    );
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(purchaseDate);
  }

  String get statusString {
    return status.toString().split('.').last;
  }

  Color get statusColor {
    switch (status) {
      case ServiceStatus.pending:
        return Colors.orange;
      case ServiceStatus.completed:
        return Colors.green;
      case ServiceStatus.cancelled:
        return Colors.red;
      case ServiceStatus.refunded:
        return Colors.blue;
    }
  }
}
