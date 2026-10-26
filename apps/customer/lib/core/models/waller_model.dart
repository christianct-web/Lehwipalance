// lib/features/wallet/models/wallet_models.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum TransactionType { credit, debit, pending, refund }

enum TransactionStatus { pending, completed, failed, cancelled }

enum WalletMenuAction { transactions, help, security }

enum MethodType { creditCard, debitCard, bankAccount, stripe, paypal }

abstract class BaseMethod extends Equatable {
  final String id;
  final String userId;
  final MethodType type;
  final bool isDefault;
  final bool isVerified;
  final DateTime addedDate;

  const BaseMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.isDefault,
    required this.isVerified,
    required this.addedDate,
  });

  String get displayName;
  String get maskedDetails;
  IconData get icon;

  factory BaseMethod.fromJson(Map<String, dynamic> json) {
    final type = MethodType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => MethodType.creditCard,
    );

    switch (type) {
      case MethodType.creditCard:
      case MethodType.debitCard:
        return CreditCardModel.fromJson(json);
      case MethodType.bankAccount:
        return BankAccountModel.fromJson(json);
      case MethodType.stripe:
        return StripeAccountModel.fromJson(json);
      case MethodType.paypal:
        return PayPalAccountModel.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();

  BaseMethod copyWith({
    String? id,
    String? userId,
    bool? isDefault,
    bool? isVerified,
    DateTime? addedDate,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        isDefault,
        isVerified,
        addedDate,
      ];
}

// ==================== CREDIT CARD ====================

class CreditCardModel extends BaseMethod {
  final String cardNumber;
  final String holderName;
  final DateTime expiryDate;
  final String cvv;
  final CardType cardType;

  const CreditCardModel({
    required super.id,
    required super.userId,
    required super.isDefault,
    required super.isVerified,
    required super.addedDate,
    required this.cardNumber,
    required this.holderName,
    required this.expiryDate,
    required this.cvv,
    required this.cardType,
  }) : super(type: MethodType.creditCard);

  factory CreditCardModel.fromJson(Map<String, dynamic> json) {
    return CreditCardModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      isDefault: json['isDefault'] as bool,
      isVerified: json['isVerified'] as bool,
      addedDate: DateTime.parse(json['addedDate'] as String),
      cardNumber: json['cardNumber'] as String,
      holderName: json['holderName'] as String,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      cvv: json['cvv'] as String,
      cardType: CardType.values.firstWhere(
        (e) => e.name == json['cardType'],
        orElse: () => CardType.visa,
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'isDefault': isDefault,
      'isVerified': isVerified,
      'addedDate': addedDate.toIso8601String(),
      'cardNumber': cardNumber,
      'holderName': holderName,
      'expiryDate': expiryDate.toIso8601String(),
      'cvv': cvv,
      'cardType': cardType.name,
    };
  }

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  @override
  String get displayName =>
      '${cardType.name.toUpperCase()} •••• ${cardNumber.substring(cardNumber.length - 4)}';

  @override
  String get maskedDetails =>
      'Expires ${expiryDate.month}/${expiryDate.year % 100}';

  @override
  IconData get icon => Icons.credit_card;

  @override
  List<Object?> get props => [
        ...super.props,
        cardNumber,
        holderName,
        expiryDate,
        cvv,
        cardType,
      ];

  @override
  CreditCardModel copyWith({
    String? id,
    String? userId,
    bool? isDefault,
    bool? isVerified,
    DateTime? addedDate,
    String? cardNumber,
    String? holderName,
    DateTime? expiryDate,
    String? cvv,
    CardType? cardType,
  }) {
    return CreditCardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
      isVerified: isVerified ?? this.isVerified,
      addedDate: addedDate ?? this.addedDate,
      cardNumber: cardNumber ?? this.cardNumber,
      holderName: holderName ?? this.holderName,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      cardType: cardType ?? this.cardType,
    );
  }
}

// ==================== BANK ACCOUNT ====================

class BankAccountModel extends BaseMethod {
  final String accountNumber;
  final String routingNumber;
  final String bankName;
  final AccountType accountType;
  final String accountHolderName;
  final String accountHolderType;

  const BankAccountModel({
    required super.id,
    required super.userId,
    required super.isDefault,
    required super.isVerified,
    required super.addedDate,
    required this.accountNumber,
    required this.routingNumber,
    required this.bankName,
    required this.accountType,
    required this.accountHolderName,
    required this.accountHolderType,
  }) : super(type: MethodType.bankAccount);

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      isDefault: json['isDefault'] as bool,
      isVerified: json['isVerified'] as bool,
      addedDate: DateTime.parse(json['addedDate'] as String),
      accountNumber: json['accountNumber'] as String,
      routingNumber: json['routingNumber'] as String,
      bankName: json['bankName'] as String,
      accountType: AccountType.values.firstWhere(
        (e) => e.name == json['accountType'],
        orElse: () => AccountType.checking,
      ),
      accountHolderName: json['accountHolderName'] as String,
      accountHolderType: json['accountHolderType'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'isDefault': isDefault,
      'isVerified': isVerified,
      'addedDate': addedDate.toIso8601String(),
      'accountNumber': accountNumber,
      'routingNumber': routingNumber,
      'bankName': bankName,
      'accountType': accountType.name,
      'accountHolderName': accountHolderName,
      'accountHolderType': accountHolderType,
    };
  }

  @override
  String get displayName =>
      '$bankName •••• ${accountNumber.substring(accountNumber.length - 4)}';

  @override
  String get maskedDetails =>
      '${accountType.name.toUpperCase()} - $accountHolderName';

  @override
  IconData get icon => Icons.account_balance;

  @override
  List<Object?> get props => [
        ...super.props,
        accountNumber,
        routingNumber,
        bankName,
        accountType,
        accountHolderName,
        accountHolderType,
      ];

  @override
  BankAccountModel copyWith({
    String? id,
    String? userId,
    bool? isDefault,
    bool? isVerified,
    DateTime? addedDate,
    String? accountNumber,
    String? routingNumber,
    String? bankName,
    AccountType? accountType,
    String? accountHolderName,
    String? accountHolderType,
  }) {
    return BankAccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
      isVerified: isVerified ?? this.isVerified,
      addedDate: addedDate ?? this.addedDate,
      accountNumber: accountNumber ?? this.accountNumber,
      routingNumber: routingNumber ?? this.routingNumber,
      bankName: bankName ?? this.bankName,
      accountType: accountType ?? this.accountType,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountHolderType: accountHolderType ?? this.accountHolderType,
    );
  }
}

// ==================== STRIPE ACCOUNT ====================

class StripeAccountModel extends BaseMethod {
  final String accountId;
  final String email;
  final String country;
  final StripeBusinessType businessType;
  final String? firstName;
  final String? lastName;
  final bool payoutsEnabled;
  final DateTime? verifiedDate;

  const StripeAccountModel({
    required super.id,
    required super.userId,
    required super.isDefault,
    required super.isVerified,
    required super.addedDate,
    required this.accountId,
    required this.email,
    required this.country,
    required this.businessType,
    this.firstName,
    this.lastName,
    required this.payoutsEnabled,
    this.verifiedDate,
  }) : super(type: MethodType.stripe);

  factory StripeAccountModel.fromJson(Map<String, dynamic> json) {
    return StripeAccountModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      isDefault: json['isDefault'] as bool,
      isVerified: json['isVerified'] as bool,
      addedDate: DateTime.parse(json['addedDate'] as String),
      accountId: json['accountId'] as String,
      email: json['email'] as String,
      country: json['country'] as String,
      businessType: StripeBusinessType.values.firstWhere(
        (e) => e.name == json['businessType'],
        orElse: () => StripeBusinessType.individual,
      ),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      payoutsEnabled: json['payoutsEnabled'] as bool,
      verifiedDate: json['verifiedDate'] != null
          ? DateTime.parse(json['verifiedDate'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'isDefault': isDefault,
      'isVerified': isVerified,
      'addedDate': addedDate.toIso8601String(),
      'accountId': accountId,
      'email': email,
      'country': country,
      'businessType': businessType.name,
      'firstName': firstName,
      'lastName': lastName,
      'payoutsEnabled': payoutsEnabled,
      'verifiedDate': verifiedDate?.toIso8601String(),
    };
  }

  @override
  String get displayName => 'Stripe • $email';

  @override
  String get maskedDetails => 'Account: $accountId';

  @override
  IconData get icon => Icons.account_balance_wallet;

  @override
  List<Object?> get props => [
        ...super.props,
        accountId,
        email,
        country,
        businessType,
        firstName,
        lastName,
        payoutsEnabled,
        verifiedDate,
      ];

  @override
  StripeAccountModel copyWith({
    String? id,
    String? userId,
    bool? isDefault,
    bool? isVerified,
    DateTime? addedDate,
    String? accountId,
    String? email,
    String? country,
    StripeBusinessType? businessType,
    String? firstName,
    String? lastName,
    bool? payoutsEnabled,
    DateTime? verifiedDate,
  }) {
    return StripeAccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
      isVerified: isVerified ?? this.isVerified,
      addedDate: addedDate ?? this.addedDate,
      accountId: accountId ?? this.accountId,
      email: email ?? this.email,
      country: country ?? this.country,
      businessType: businessType ?? this.businessType,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      payoutsEnabled: payoutsEnabled ?? this.payoutsEnabled,
      verifiedDate: verifiedDate ?? this.verifiedDate,
    );
  }
}

// ==================== PAYPAL ACCOUNT ====================

class PayPalAccountModel extends BaseMethod {
  final String email;
  final String country;
  final String? firstName;
  final String? lastName;
  final bool payoutsEnabled;
  final DateTime? verifiedDate;

  const PayPalAccountModel({
    required super.id,
    required super.userId,
    required super.isDefault,
    required super.isVerified,
    required super.addedDate,
    required this.email,
    required this.country,
    this.firstName,
    this.lastName,
    required this.payoutsEnabled,
    this.verifiedDate,
  }) : super(type: MethodType.paypal);

  factory PayPalAccountModel.fromJson(Map<String, dynamic> json) {
    return PayPalAccountModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      isDefault: json['isDefault'] as bool,
      isVerified: json['isVerified'] as bool,
      addedDate: DateTime.parse(json['addedDate'] as String),
      email: json['email'] as String,
      country: json['country'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      payoutsEnabled: json['payoutsEnabled'] as bool,
      verifiedDate: json['verifiedDate'] != null
          ? DateTime.parse(json['verifiedDate'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'isDefault': isDefault,
      'isVerified': isVerified,
      'addedDate': addedDate.toIso8601String(),
      'email': email,
      'country': country,
      'firstName': firstName,
      'lastName': lastName,
      'payoutsEnabled': payoutsEnabled,
      'verifiedDate': verifiedDate?.toIso8601String(),
    };
  }

  @override
  String get displayName => 'PayPal • $email';

  @override
  String get maskedDetails => 'Account: $email';

  @override
  IconData get icon => Icons.payment;

  @override
  List<Object?> get props => [
        ...super.props,
        email,
        country,
        firstName,
        lastName,
        payoutsEnabled,
        verifiedDate,
      ];

  @override
  PayPalAccountModel copyWith({
    String? id,
    String? userId,
    bool? isDefault,
    bool? isVerified,
    DateTime? addedDate,
    String? email,
    String? country,
    String? firstName,
    String? lastName,
    bool? payoutsEnabled,
    DateTime? verifiedDate,
  }) {
    return PayPalAccountModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      isDefault: isDefault ?? this.isDefault,
      isVerified: isVerified ?? this.isVerified,
      addedDate: addedDate ?? this.addedDate,
      email: email ?? this.email,
      country: country ?? this.country,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      payoutsEnabled: payoutsEnabled ?? this.payoutsEnabled,
      verifiedDate: verifiedDate ?? this.verifiedDate,
    );
  }
}

class WalletModel extends Equatable {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TransactionModel> transactions;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.transactions = const [],
  });

  WalletModel copyWith({
    String? id,
    String? userId,
    double? balance,
    String? currency,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TransactionModel>? transactions,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      transactions: transactions ?? this.transactions,
    );
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      transactions: (json['transactions'] as List?)
              ?.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'balance': balance,
      'currency': currency,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'transactions': transactions.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        balance,
        currency,
        isActive,
        createdAt,
        updatedAt,
        transactions,
      ];
}

class TransactionModel extends Equatable {
  final String id;
  final String walletId;
  final double amount;
  final TransactionType type;
  final TransactionStatus status;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const TransactionModel({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.type,
    required this.status,
    required this.description,
    required this.timestamp,
    this.metadata = const {},
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      walletId: json['walletId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.pending,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      description: json['description'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletId': walletId,
      'amount': amount,
      'type': type.name,
      'status': status.name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  @override
  List<Object?> get props => [
        id,
        walletId,
        amount,
        type,
        status,
        description,
        timestamp,
        metadata,
      ];
}

enum CardType { visa, mastercard, amex, discover }

enum AccountType { checking, savings }

enum StripeBusinessType { individual, company, nonprofit }

enum PaymentMethodAction { setDefault, delete }

final List<WalletModel> mockWalletModel = [];

extension BaseMethodCopyWith on BaseMethod {
  BaseMethod copyWithDefault(bool isDefault) {
    if (this is CreditCardModel) {
      return (this as CreditCardModel).copyWith(isDefault: isDefault);
    } else if (this is BankAccountModel) {
      return (this as BankAccountModel).copyWith(isDefault: isDefault);
    } else if (this is StripeAccountModel) {
      return (this as StripeAccountModel).copyWith(isDefault: isDefault);
    } else if (this is PayPalAccountModel) {
      return (this as PayPalAccountModel).copyWith(isDefault: isDefault);
    }
    return this;
  }
}

// lib/features/wallet/constants/wallet_constants.dart
class WalletConstants {
  static const double minTopUpAmount = 1.0;
  static const double maxTopUpAmount = 10000.0;
  static const double processingFeePercent = 0.029;
  static const int maxRecentTransactions = 5;

  static const List<double> quickTopUpAmounts = [
    10.0,
    25.0,
    50.0,
    100.0,
    250.0,
    500.0,
  ];
  static const Duration refreshInterval = Duration(minutes: 5);
}

extension TransactionExtension on TransactionModel {
  bool get isCredit => type == TransactionType.credit;
  bool get isDebit => type == TransactionType.debit;
  bool get isPending => status == TransactionStatus.pending;
  bool get isCompleted => status == TransactionStatus.completed;
  bool get isFailed => status == TransactionStatus.failed;

  String get formattedAmount {
    final sign = isCredit ? '+' : '-';
    return '$sign\$${amount.toStringAsFixed(2)}';
  }

  Color get statusColor {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
    }
  }
}
// In wallet_models.dart - Add these sync versions

extension MethodExtension on BaseMethod {
  bool get isExpired =>
      this is CreditCardModel && (this as CreditCardModel).isExpired;
}

// ============================================================
// MOCK WALLET DATA FOR 3 CUSTOMERS
// ============================================================

// CUSTOMER 1: JAMES WILSON (Music & Festival Enthusiast)
final walletcustomer_001 = WalletModel(
  id: 'wallet_customer_001',
  userId: 'customer_001',
  balance: 1250.75,
  currency: 'TTD',
  isActive: true,
  createdAt: DateTime(2024, 6, 15, 10, 30, 0),
  updatedAt: DateTime(2026, 7, 8, 14, 22, 0),
  transactions: [
    TransactionModel(
      id: 'txn_001_001',
      walletId: 'wallet_customer_001',
      amount: 250.00,
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      description: 'Refund for cancelled booking - Trinidad Carnival Kickoff',
      timestamp: DateTime(2026, 7, 8, 10, 15, 0),
      metadata: const {
        'bookingId': 'RCP002',
        'refundReason': 'Event cancelled by organizer',
        'processedBy': 'system',
      },
    ),
    TransactionModel(
      id: 'txn_001_002',
      walletId: 'wallet_customer_001',
      amount: 75.50,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Payment for Steelpan Music Lessons - Session 1',
      timestamp: DateTime(2026, 7, 6, 16, 30, 0),
      metadata: const {
        'serviceId': 'srv_002',
        'bookingId': 'RCP010',
        'paymentMethod': 'creditCard',
        'cardLast4': '4582',
      },
    ),
    TransactionModel(
      id: 'txn_001_003',
      walletId: 'wallet_customer_001',
      amount: 450.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Hotel booking - Hyatt Regency Trinidad (2 nights)',
      timestamp: DateTime(2026, 7, 5, 09, 45, 0),
      metadata: const {
        'serviceId': 'htl_001',
        'bookingId': 'RCP015',
        'paymentMethod': 'creditCard',
        'cardLast4': '4582',
        'nights': 2,
        'roomType': 'Deluxe Ocean View',
      },
    ),
    TransactionModel(
      id: 'txn_001_004',
      walletId: 'wallet_customer_001',
      amount: 150.00,
      type: TransactionType.credit,
      status: TransactionStatus.pending,
      description: 'Referral bonus - Sophia Martinez joined',
      timestamp: DateTime(2026, 7, 3, 08, 20, 0),
      metadata: const {
        'referredUserId': 'customer_002',
        'referralProgram': 'Summer 2026',
        'bonusType': 'New User Referral',
      },
    ),
    TransactionModel(
      id: 'txn_001_005',
      walletId: 'wallet_customer_001',
      amount: 120.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Startup Pitch Competition - Early Bird Ticket',
      timestamp: DateTime(2026, 7, 1, 14, 00, 0),
      metadata: const {
        'eventId': 'evt_004',
        'ticketId': 'tkt_004_001',
        'paymentMethod': 'paypal',
        'tier': 'Early Bird',
      },
    ),
    TransactionModel(
      id: 'txn_001_006',
      walletId: 'wallet_customer_001',
      amount: 35.00,
      type: TransactionType.debit,
      status: TransactionStatus.failed,
      description: 'Soca & Steelpan Night - VIP Upgrade',
      timestamp: DateTime(2026, 6, 30, 19, 30, 0),
      metadata: const {
        'eventId': 'evt_005',
        'errorCode': 'PAYMENT_DECLINED',
        'errorMessage': 'Insufficient funds',
        'retryCount': 0,
      },
    ),
    TransactionModel(
      id: 'txn_001_007',
      walletId: 'wallet_customer_001',
      amount: 100.00,
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      description: 'Deposit - Added funds to wallet',
      timestamp: DateTime(2026, 6, 28, 11, 00, 0),
      metadata: const {
        'paymentMethod': 'bankAccount',
        'accountLast4': '7890',
        'referenceId': 'DEP_20260628_001',
      },
    ),
    TransactionModel(
      id: 'txn_001_008',
      walletId: 'wallet_customer_001',
      amount: 85.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Trinidad Carnival Kickoff - General Admission',
      timestamp: DateTime(2026, 6, 25, 20, 15, 0),
      metadata: const {
        'eventId': 'evt_002',
        'ticketId': 'tkt_002_001',
        'paymentMethod': 'creditCard',
        'cardLast4': '4582',
        'tier': 'General Admission',
      },
    ),
    TransactionModel(
      id: 'txn_001_009',
      walletId: 'wallet_customer_001',
      amount: 200.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Caribbean Music Festival - Weekend Pass',
      timestamp: DateTime(2026, 6, 20, 12, 00, 0),
      metadata: const {
        'eventId': 'evt_001',
        'ticketId': 'tkt_001_001',
        'paymentMethod': 'creditCard',
        'cardLast4': '4582',
        'tier': 'Weekend Pass',
      },
    ),
    TransactionModel(
      id: 'txn_001_010',
      walletId: 'wallet_customer_001',
      amount: 15.00,
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      description: 'Cashback reward - Music Festival purchase',
      timestamp: DateTime(2026, 6, 18, 15, 30, 0),
      metadata: const {
        'promotionCode': 'MUSIC10',
        'purchaseId': 'purchase_001',
        'cashbackPercentage': 7.5,
      },
    ),
    TransactionModel(
      id: 'txn_001_011',
      walletId: 'wallet_customer_001',
      amount: 60.00,
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      description: 'Refund - Startup Pitch Competition (cancelled)',
      timestamp: DateTime(2026, 6, 15, 09, 00, 0),
      metadata: const {
        'bookingId': 'RCP005',
        'refundReason': 'User cancellation',
        'processedBy': 'system',
      },
    ),
    TransactionModel(
      id: 'txn_001_012',
      walletId: 'wallet_customer_001',
      amount: 300.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Annual Premium Membership - Caribbean Events Pro',
      timestamp: DateTime(2026, 6, 10, 10, 30, 0),
      metadata: const {
        'membershipType': 'Premium',
        'organisationId': 'org_001',
        'billingCycle': 'Annual',
        'nextBillingDate': '2027-06-10',
      },
    ),
    TransactionModel(
      id: 'txn_001_013',
      walletId: 'wallet_customer_001',
      amount: 40.00,
      type: TransactionType.debit,
      status: TransactionStatus.pending,
      description: 'Processing fee - Ticket transfer',
      timestamp: DateTime(2026, 6, 8, 16, 45, 0),
      metadata: const {
        'feeType': 'Transfer Fee',
        'ticketId': 'tkt_002_001',
        'transferredTo': 'customer_004',
        'status': 'Awaiting Confirmation',
      },
    ),
    TransactionModel(
      id: 'txn_001_014',
      walletId: 'wallet_customer_001',
      amount: 500.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Caribbean Music Festival - VIP Experience',
      timestamp: DateTime(2026, 6, 5, 14, 20, 0),
      metadata: const {
        'eventId': 'evt_001',
        'ticketId': 'tkt_001_002',
        'paymentMethod': 'creditCard',
        'cardLast4': '4582',
        'tier': 'VIP Experience',
        'includes': ['Backstage Access', 'Meet & Greet', 'VIP Lounge'],
      },
    ),
    TransactionModel(
      id: 'txn_001_015',
      walletId: 'wallet_customer_001',
      amount: 25.00,
      type: TransactionType.debit,
      status: TransactionStatus.failed,
      description: 'Donation - Cultural Preservation Fund',
      timestamp: DateTime(2026, 6, 1, 18, 00, 0),
      metadata: const {
        'charityId': 'charity_001',
        'errorCode': 'PAYMENT_METHOD_EXPIRED',
        'errorMessage': 'Card has expired',
        'retryCount': 1,
      },
    ),
  ],
);

// CUSTOMER 2: SOPHIA MARTINEZ (Foodie & Art Enthusiast)
final walletcustomer_002 = WalletModel(
  id: 'wallet_customer_002',
  userId: 'customer_002',
  balance: 3450.50,
  currency: 'TTD',
  isActive: true,
  createdAt: DateTime(2024, 7, 22, 09, 15, 0),
  updatedAt: DateTime(2026, 7, 7, 16, 45, 0),
  transactions: [
    TransactionModel(
      id: 'txn_002_001',
      walletId: 'wallet_customer_002',
      amount: 320.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Food & Wine Festival - VIP Tasting Pass',
      timestamp: DateTime(2026, 7, 7, 14, 30, 0),
      metadata: const {
        'eventId': 'evt_006',
        'ticketId': 'tkt_006_001',
        'paymentMethod': 'creditCard',
        'cardLast4': '1122',
        'tier': 'VIP Tasting',
      },
    ),
    TransactionModel(
      id: 'txn_002_002',
      walletId: 'wallet_customer_002',
      amount: 180.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Art Gallery Exhibition - Private Viewing',
      timestamp: DateTime(2026, 7, 5, 19, 00, 0),
      metadata: const {
        'serviceId': 'srv_005',
        'bookingId': 'RCP020',
        'paymentMethod': 'creditCard',
        'cardLast4': '1122',
        'gallery': 'National Museum',
      },
    ),
    TransactionModel(
      id: 'txn_002_003',
      walletId: 'wallet_customer_002',
      amount: 500.00,
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      description: 'Refund - Art Workshop Cancellation',
      timestamp: DateTime(2026, 7, 3, 10, 00, 0),
      metadata: const {
        'bookingId': 'RCP025',
        'refundReason': 'Workshop cancelled due to low enrollment',
        'processedBy': 'system',
      },
    ),
    TransactionModel(
      id: 'txn_002_004',
      walletId: 'wallet_customer_002',
      amount: 65.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Cooking Class - Caribbean Cuisine',
      timestamp: DateTime(2026, 7, 1, 17, 30, 0),
      metadata: const {
        'serviceId': 'srv_008',
        'bookingId': 'RCP030',
        'paymentMethod': 'creditCard',
        'cardLast4': '1122',
        'class': 'Caribbean Spices',
      },
    ),
    TransactionModel(
      id: 'txn_002_005',
      walletId: 'wallet_customer_002',
      amount: 75.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Pottery Workshop - Weekend Session',
      timestamp: DateTime(2026, 6, 28, 14, 00, 0),
      metadata: const {
        'serviceId': 'srv_006',
        'bookingId': 'RCP032',
        'paymentMethod': 'creditCard',
        'cardLast4': '1122',
      },
    ),
    TransactionModel(
      id: 'txn_002_006',
      walletId: 'wallet_customer_002',
      amount: 200.00,
      type: TransactionType.credit,
      status: TransactionStatus.pending,
      description: 'Referral bonus - Marcus Thompson joined',
      timestamp: DateTime(2026, 6, 25, 08, 00, 0),
      metadata: const {
        'referredUserId': 'customer_003',
        'referralProgram': 'Summer 2026',
        'bonusType': 'New User Referral',
      },
    ),
    TransactionModel(
      id: 'txn_002_007',
      walletId: 'wallet_customer_002',
      amount: 45.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Wine Tasting Event - Entry Ticket',
      timestamp: DateTime(2026, 6, 22, 18, 30, 0),
      metadata: const {
        'eventId': 'evt_007',
        'ticketId': 'tkt_007_001',
        'paymentMethod': 'creditCard',
        'cardLast4': '1122',
        'tier': 'Standard',
      },
    ),
    TransactionModel(
      id: 'txn_002_008',
      walletId: 'wallet_customer_002',
      amount: 1500.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Art Auction - Limited Edition Painting',
      timestamp: DateTime(2026, 6, 20, 20, 00, 0),
      metadata: const {
        'purchaseType': 'Art Auction',
        'itemId': 'art_001',
        'artist': 'Local Caribbean Artist',
        'paymentMethod': 'creditCard',
        'cardLast4': '1122',
      },
    ),
    TransactionModel(
      id: 'txn_002_009',
      walletId: 'wallet_customer_002',
      amount: 250.00,
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      description: 'Deposit - Added funds to wallet',
      timestamp: DateTime(2026, 6, 18, 12, 30, 0),
      metadata: const {
        'paymentMethod': 'bankAccount',
        'accountLast4': '3456',
        'referenceId': 'DEP_20260618_002',
      },
    ),
    TransactionModel(
      id: 'txn_002_010',
      walletId: 'wallet_customer_002',
      amount: 120.00,
      type: TransactionType.debit,
      status: TransactionStatus.failed,
      description: 'Photography Workshop - Advanced Course',
      timestamp: DateTime(2026, 6, 15, 09, 00, 0),
      metadata: const {
        'serviceId': 'srv_009',
        'errorCode': 'INSUFFICIENT_FUNDS',
        'errorMessage': 'Balance too low',
        'retryCount': 2,
      },
    ),
    TransactionModel(
      id: 'txn_002_011',
      walletId: 'wallet_customer_002',
      amount: 350.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Tobago Beach Resort - Weekend Getaway',
      timestamp: DateTime(2026, 6, 12, 11, 00, 0),
      metadata: const {
        'serviceId': 'htl_002',
        'bookingId': 'RCP035',
        'paymentMethod': 'creditCard',
        'cardLast4': '1122',
        'nights': 3,
      },
    ),
    TransactionModel(
      id: 'txn_002_012',
      walletId: 'wallet_customer_002',
      amount: 30.00,
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      description: 'Cashback reward - Food Festival purchase',
      timestamp: DateTime(2026, 6, 8, 15, 30, 0),
      metadata: const {
        'promotionCode': 'FOODIE5',
        'purchaseId': 'purchase_005',
        'cashbackPercentage': 5.0,
      },
    ),
    TransactionModel(
      id: 'txn_002_013',
      walletId: 'wallet_customer_002',
      amount: 400.00,
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      description: 'Refund - Art Exhibition Cancellation',
      timestamp: DateTime(2026, 6, 5, 14, 00, 0),
      metadata: const {
        'bookingId': 'RCP040',
        'refundReason': 'Exhibition postponed',
        'processedBy': 'system',
      },
    ),
    TransactionModel(
      id: 'txn_002_014',
      walletId: 'wallet_customer_002',
      amount: 95.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Caribbean Chef Dinner - 5-Course Meal',
      timestamp: DateTime(2026, 6, 1, 19, 30, 0),
      metadata: const {
        'eventId': 'evt_008',
        'ticketId': 'tkt_008_001',
        'paymentMethod': 'creditCard',
        'cardLast4': '1122',
      },
    ),
  ],
);

// CUSTOMER 3: MARCUS THOMPSON (Sports & Adventure Seeker)
final walletcustomer_003 = WalletModel(
  id: 'wallet_customer_003',
  userId: 'customer_003',
  balance: 675.25,
  currency: 'TTD',
  isActive: true,
  createdAt: DateTime(2024, 8, 5, 13, 45, 0),
  updatedAt: DateTime(2026, 7, 6, 20, 15, 0),
  transactions: [
    TransactionModel(
      id: 'txn_003_001',
      walletId: 'wallet_customer_003',
      amount: 280.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Football Tournament - Season Pass',
      timestamp: DateTime(2026, 7, 6, 18, 00, 0),
      metadata: const {
        'eventId': 'evt_010',
        'ticketId': 'tkt_010_001',
        'paymentMethod': 'creditCard',
        'cardLast4': '7890',
        'tier': 'Season Pass',
        'includes': ['All matches', 'VIP access'],
      },
    ),
    TransactionModel(
      id: 'txn_003_002',
      walletId: 'wallet_customer_003',
      amount: 150.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Caribbean Adventure Park - Day Pass',
      timestamp: DateTime(2026, 7, 4, 10, 30, 0),
      metadata: const {
        'serviceId': 'srv_015',
        'bookingId': 'RCP045',
        'paymentMethod': 'creditCard',
        'cardLast4': '7890',
        'package': 'Adventure Plus',
      },
    ),
    TransactionModel(
      id: 'txn_003_003',
      walletId: 'wallet_customer_003',
      amount: 200.00,
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      description: 'Deposit - Added funds to wallet',
      timestamp: DateTime(2026, 7, 2, 09, 00, 0),
      metadata: const {
        'paymentMethod': 'bankAccount',
        'accountLast4': '9012',
        'referenceId': 'DEP_20260702_003',
      },
    ),
    TransactionModel(
      id: 'txn_003_004',
      walletId: 'wallet_customer_003',
      amount: 75.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Cricket Match - Premium Seating',
      timestamp: DateTime(2026, 6, 29, 16, 00, 0),
      metadata: const {
        'eventId': 'evt_011',
        'ticketId': 'tkt_011_001',
        'paymentMethod': 'creditCard',
        'cardLast4': '7890',
        'tier': 'Premium',
      },
    ),
    TransactionModel(
      id: 'txn_003_005',
      walletId: 'wallet_customer_003',
      amount: 50.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Yoga Retreat - Morning Session',
      timestamp: DateTime(2026, 6, 27, 07, 30, 0),
      metadata: const {
        'serviceId': 'srv_016',
        'bookingId': 'RCP048',
        'paymentMethod': 'creditCard',
        'cardLast4': '7890',
      },
    ),
    TransactionModel(
      id: 'txn_003_006',
      walletId: 'wallet_customer_003',
      amount: 320.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Cycling Tour - Tobago Island Tour',
      timestamp: DateTime(2026, 6, 24, 08, 00, 0),
      metadata: const {
        'serviceId': 'srv_017',
        'bookingId': 'RCP050',
        'paymentMethod': 'creditCard',
        'cardLast4': '7890',
        'distance': '35 km',
        'guide': 'Island Adventures Ltd',
      },
    ),
    TransactionModel(
      id: 'txn_003_007',
      walletId: 'wallet_customer_003',
      amount: 180.00,
      type: TransactionType.credit,
      status: TransactionStatus.pending,
      description: 'Refund - Football Tournament (weather cancellation)',
      timestamp: DateTime(2026, 6, 22, 12, 00, 0),
      metadata: const {
        'bookingId': 'RCP055',
        'refundReason': 'Weather cancellation',
        'processedBy': 'system',
        'status': 'Processing',
      },
    ),
    TransactionModel(
      id: 'txn_003_008',
      walletId: 'wallet_customer_003',
      amount: 60.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Marathon Registration - 10K Run',
      timestamp: DateTime(2026, 6, 20, 06, 00, 0),
      metadata: const {
        'eventId': 'evt_012',
        'ticketId': 'tkt_012_001',
        'paymentMethod': 'creditCard',
        'cardLast4': '7890',
        'distance': '10K',
      },
    ),
    TransactionModel(
      id: 'txn_003_009',
      walletId: 'wallet_customer_003',
      amount: 25.00,
      type: TransactionType.debit,
      status: TransactionStatus.failed,
      description: 'Gym Day Pass - Fitness Center',
      timestamp: DateTime(2026, 6, 18, 17, 00, 0),
      metadata: const {
        'serviceId': 'srv_018',
        'errorCode': 'PAYMENT_METHOD_DECLINED',
        'errorMessage': 'Card expired',
        'retryCount': 0,
      },
    ),
    TransactionModel(
      id: 'txn_003_010',
      walletId: 'wallet_customer_003',
      amount: 45.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Hiking Tour - Northern Range Trail',
      timestamp: DateTime(2026, 6, 15, 06, 30, 0),
      metadata: const {
        'serviceId': 'srv_019',
        'bookingId': 'RCP058',
        'paymentMethod': 'creditCard',
        'cardLast4': '7890',
        'trail': 'Northern Range',
        'duration': '4 hours',
      },
    ),
    TransactionModel(
      id: 'txn_003_011',
      walletId: 'wallet_customer_003',
      amount: 120.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Surfing Lessons - Maracas Beach',
      timestamp: DateTime(2026, 6, 12, 09, 00, 0),
      metadata: const {
        'serviceId': 'srv_020',
        'bookingId': 'RCP060',
        'paymentMethod': 'creditCard',
        'cardLast4': '7890',
        'level': 'Beginner',
      },
    ),
    TransactionModel(
      id: 'txn_003_012',
      walletId: 'wallet_customer_003',
      amount: 80.00,
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      description: 'Deposit - Added funds to wallet',
      timestamp: DateTime(2026, 6, 10, 14, 00, 0),
      metadata: const {
        'paymentMethod': 'creditCard',
        'cardLast4': '7890',
        'referenceId': 'DEP_20260610_003',
      },
    ),
    TransactionModel(
      id: 'txn_003_013',
      walletId: 'wallet_customer_003',
      amount: 40.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Basketball League - Team Registration',
      timestamp: DateTime(2026, 6, 8, 20, 00, 0),
      metadata: const {
        'eventId': 'evt_013',
        'ticketId': 'tkt_013_001',
        'paymentMethod': 'creditCard',
        'cardLast4': '7890',
        'team': 'T&T Warriors',
      },
    ),
    TransactionModel(
      id: 'txn_003_014',
      walletId: 'wallet_customer_003',
      amount: 300.00,
      type: TransactionType.debit,
      status: TransactionStatus.completed,
      description: 'Fitness Equipment - Home Gym Setup',
      timestamp: DateTime(2026, 6, 5, 15, 00, 0),
      metadata: const {
        'purchaseType': 'Equipment',
        'itemId': 'eqp_001',
        'paymentMethod': 'creditCard',
        'cardLast4': '7890',
        'items': ['Dumbbells', 'Resistance Bands', 'Yoga Mat'],
      },
    ),
    TransactionModel(
      id: 'txn_003_015',
      walletId: 'wallet_customer_003',
      amount: 20.00,
      type: TransactionType.credit,
      status: TransactionStatus.completed,
      description: 'Cashback reward - Adventure Park purchase',
      timestamp: DateTime(2026, 6, 2, 11, 00, 0),
      metadata: const {
        'promotionCode': 'ADVENTURE10',
        'purchaseId': 'purchase_010',
        'cashbackPercentage': 10.0,
      },
    ),
  ],
);

// ============================================================
// PAYMENT METHODS FOR EACH CUSTOMER
// ============================================================

// Customer 1 Payment Methods
final paymentmethodscustomer_001 = [
  CreditCardModel(
    id: 'pm_001_001',
    userId: 'customer_001',
    isDefault: true,
    isVerified: true,
    addedDate: DateTime(2025, 6, 15),
    cardNumber: '4532 1234 5678 4582',
    holderName: 'James Wilson',
    expiryDate: DateTime(2028, 12, 31),
    cvv: '123',
    cardType: CardType.visa,
  ),
  CreditCardModel(
    id: 'pm_001_002',
    userId: 'customer_001',
    isDefault: false,
    isVerified: true,
    addedDate: DateTime(2025, 9, 20),
    cardNumber: '5555 9876 5432 1122',
    holderName: 'James Wilson',
    expiryDate: DateTime(2027, 6, 30),
    cvv: '456',
    cardType: CardType.mastercard,
  ),
  BankAccountModel(
    id: 'pm_001_003',
    userId: 'customer_001',
    isDefault: false,
    isVerified: true,
    addedDate: DateTime(2025, 12, 1),
    accountNumber: '7890 1234 5678 9012',
    routingNumber: '021000021',
    bankName: 'First Citizens Bank',
    accountType: AccountType.checking,
    accountHolderName: 'James Wilson',
    accountHolderType: 'Individual',
  ),
  PayPalAccountModel(
    id: 'pm_001_004',
    userId: 'customer_001',
    isDefault: false,
    isVerified: true,
    addedDate: DateTime(2026, 2, 14),
    email: 'james.wilson@gmail.com',
    country: 'TT',
    firstName: 'James',
    lastName: 'Wilson',
    payoutsEnabled: true,
    verifiedDate: DateTime(2026, 2, 15),
  ),
];

// Customer 2 Payment Methods
final paymentmethodscustomer_002 = [
  CreditCardModel(
    id: 'pm_002_001',
    userId: 'customer_002',
    isDefault: true,
    isVerified: true,
    addedDate: DateTime(2025, 7, 22),
    cardNumber: '4789 8765 4321 1122',
    holderName: 'Sophia Martinez',
    expiryDate: DateTime(2029, 3, 31),
    cvv: '234',
    cardType: CardType.visa,
  ),
  CreditCardModel(
    id: 'pm_002_002',
    userId: 'customer_002',
    isDefault: false,
    isVerified: true,
    addedDate: DateTime(2025, 10, 15),
    cardNumber: '6011 2233 4455 6677',
    holderName: 'Sophia Martinez',
    expiryDate: DateTime(2028, 7, 31),
    cvv: '567',
    cardType: CardType.amex,
  ),
  BankAccountModel(
    id: 'pm_002_003',
    userId: 'customer_002',
    isDefault: false,
    isVerified: true,
    addedDate: DateTime(2026, 1, 5),
    accountNumber: '3456 7890 1234 5678',
    routingNumber: '021000021',
    bankName: 'Republic Bank',
    accountType: AccountType.savings,
    accountHolderName: 'Sophia Martinez',
    accountHolderType: 'Individual',
  ),
];

// Customer 3 Payment Methods
final paymentmethodscustomer_003 = [
  CreditCardModel(
    id: 'pm_003_001',
    userId: 'customer_003',
    isDefault: true,
    isVerified: true,
    addedDate: DateTime(2025, 8, 5),
    cardNumber: '5489 0123 4567 7890',
    holderName: 'Marcus Thompson',
    expiryDate: DateTime(2029, 5, 31),
    cvv: '345',
    cardType: CardType.mastercard,
  ),
  CreditCardModel(
    id: 'pm_003_002',
    userId: 'customer_003',
    isDefault: false,
    isVerified: false,
    addedDate: DateTime(2026, 2, 10),
    cardNumber: '4532 9900 1122 3344',
    holderName: 'Marcus Thompson',
    expiryDate: DateTime(2027, 9, 30),
    cvv: '678',
    cardType: CardType.visa,
  ),
];

// ============================================================
// MASTER LISTS FOR EASY ACCESS
// ============================================================

final List<WalletModel> mockWallets = [
  walletcustomer_001,
  walletcustomer_002,
  walletcustomer_003,
];

final List<BaseMethod> mockPaymentMethods = [
  ...paymentmethodscustomer_001,
  ...paymentmethodscustomer_002,
  ...paymentmethodscustomer_003,
];

// ============================================================
// HELPER FUNCTIONS
// ============================================================

// Get wallet by user ID
WalletModel? getWalletByUserId(String userId) {
  try {
    return mockWallets.firstWhere(
      (wallet) => wallet.userId == userId,
      orElse: () => throw Exception('Wallet not found for user: $userId'),
    );
  } catch (e) {
    return null;
  }
}

// Get payment methods by user ID
List<BaseMethod> getPaymentMethodsByUserId(String userId) {
  return mockPaymentMethods.where((method) => method.userId == userId).toList();
}

// Get total balance for all customers
double getTotalSystemBalance() {
  return mockWallets.fold(0, (sum, wallet) => sum + wallet.balance);
}

// Get transaction count by type for a specific wallet
Map<TransactionStatus, int> getTransactionStats(String userId) {
  final wallet = getWalletByUserId(userId);
  if (wallet == null) return {};

  return wallet.transactions.fold(<TransactionStatus, int>{}, (map, txn) {
    map[txn.status] = (map[txn.status] ?? 0) + 1;
    return map;
  });
}

// ============================================================
// USAGE EXAMPLE - ADDING TO MOCKDATABASE
// ============================================================
