// lib/features/wallet/providers/wallet_provider.dart

import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/customer_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/models/waller_model.dart';

import 'dart:async';

//import 'package:shared_preferences/shared_preferences.dart';

// lib/features/wallet/providers/wallet_provider.dart

class WalletProvider extends ChangeNotifier {
  final ApiService _apiService;
  final CustomerProvider _customerProvider;

  WalletModel? _wallet;
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;

  WalletProvider({
    required ApiService apiService,
    required CustomerProvider customerProvider,
  }) : _apiService = apiService,
       _customerProvider = customerProvider {
    _customerProvider.addListener(_onCustomerChanged);
  }

  @override
  void dispose() {
    _customerProvider.removeListener(_onCustomerChanged);
    super.dispose();
  }

  void _onCustomerChanged() {
    // Check if customer is authenticated via CustomerProvider
    if (_customerProvider.isAuthenticated &&
        _customerProvider.customer != null) {
      loadWallet(); // Auto-load on authentication
    } else {
      _wallet = null;
      _transactions = [];
      _error = null;
      notifyListeners();
    }
  }

  // Getters
  WalletModel? get wallet => _wallet;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get error => _error;
  double get balance => _wallet?.balance ?? 0.0;
  bool get hasWallet => _wallet != null;
  bool get hasError => _error != null;

  // Load wallet data
  Future<void> loadWallet() async {
    if (_isLoading) return;
    if (!_customerProvider.isAuthenticated) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get the customer ID from CustomerProvider
      final customerId = _customerProvider.customer?.id;
      if (customerId == null || customerId.isEmpty) {
        throw Exception('Customer ID not available');
      }

      final wallet = await _apiService.getWalletByUserId(customerId);
      final transactions = await _apiService.getRecentTransactions(customerId);

      _wallet = wallet;
      _transactions = transactions;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading wallet: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh wallet data
  Future<void> refreshWallet() async {
    if (_isRefreshing) return;
    if (!_customerProvider.isAuthenticated) return;

    _isRefreshing = true;
    _error = null;
    notifyListeners();

    try {
      final customerId = _customerProvider.customer?.id;
      if (customerId == null || customerId.isEmpty) {
        throw Exception('Customer ID not available');
      }

      final wallet = await _apiService.getWalletByUserId(customerId);
      final transactions = await _apiService.getRecentTransactions(customerId);

      _wallet = wallet;
      _transactions = transactions;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error refreshing wallet: $e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Top up wallet
  Future<void> topUp(double amount, String paymentMethodId) async {
    if (!_customerProvider.isAuthenticated) return;

    final customerId = _customerProvider.customer?.id;
    if (customerId == null || customerId.isEmpty) {
      _error = 'Customer ID not available';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedWallet = await _apiService.topUpWallet(
        amount,
        paymentMethodId,
        customerId,
      );
      _wallet = updatedWallet;

      // Refresh transactions after top-up
      final transactions = await _apiService.getRecentTransactions(customerId);
      _transactions = transactions;

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error topping up wallet: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Withdraw from wallet
  Future<void> withdraw(double amount, String paymentMethodId) async {
    if (!_customerProvider.isAuthenticated) return;

    final customerId = _customerProvider.customer?.id;
    if (customerId == null || customerId.isEmpty) {
      _error = 'Customer ID not available';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedWallet = await _apiService.withdrawFromWallet(
        amount,
        paymentMethodId,
        customerId,
      );
      _wallet = updatedWallet;

      // Refresh transactions after withdrawal
      final transactions = await _apiService.getRecentTransactions(customerId);
      _transactions = transactions;

      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error withdrawing from wallet: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset state (for logout)
  void reset() {
    _wallet = null;
    _transactions = [];
    _isLoading = false;
    _isRefreshing = false;
    _error = null;
    notifyListeners();
  }
}
// Updated providers using the new API services
// lib/features/wallet/providers/wallet_provider.dart

// lib/features/wallet/providers/payment_method_provider.dart

// lib/features/wallet/providers/payment_method_provider.dart

class PaymentMethodProvider extends ChangeNotifier {
  final ApiService _apiService;
  final CustomerProvider _customerProvider;

  List<BaseMethod> _methods = [];
  bool _isLoading = false;
  String? _error;

  PaymentMethodProvider({
    required ApiService apiService,
    required CustomerProvider customerProvider,
  }) : _apiService = apiService,
       _customerProvider = customerProvider {
    _customerProvider.addListener(_onCustomerChanged);
  }

  @override
  void dispose() {
    _customerProvider.removeListener(_onCustomerChanged);
    super.dispose();
  }

  void _onCustomerChanged() {
    if (!_customerProvider.isAuthenticated ||
        _customerProvider.customer == null) {
      _methods = [];
      _error = null;
      notifyListeners();
    } else {
      loadPaymentMethods(); // Auto-load when customer is authenticated
    }
  }

  // Getters
  List<BaseMethod> get methods => _methods;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMethods => _methods.isNotEmpty;
  BaseMethod? get defaultMethod => _methods.firstWhere((m) => m.isDefault);

  // Load payment methods
  Future<void> loadPaymentMethods() async {
    if (_isLoading) return;
    if (!_customerProvider.isAuthenticated) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final customerId = _customerProvider.customer?.id;
      if (customerId == null || customerId.isEmpty) {
        throw Exception('Customer ID not available');
      }

      _methods = await _apiService.getPaymentMethodsByUserId(customerId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading payment methods: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh payment methods
  Future<void> refreshPaymentMethods() async {
    if (!_customerProvider.isAuthenticated) return;

    try {
      final customerId = _customerProvider.customer?.id;
      if (customerId == null || customerId.isEmpty) {
        throw Exception('Customer ID not available');
      }

      _methods = await _apiService.getPaymentMethodsByUserId(customerId);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error refreshing payment methods: $e');
    }
  }

  // Add credit card
  Future<void> addCreditCard(CreditCardModel card) async {
    if (!_customerProvider.isAuthenticated) return;

    try {
      final customerId = _customerProvider.customer?.id;
      if (customerId == null || customerId.isEmpty) {
        throw Exception('Customer ID not available');
      }

      // Associate card with customer
      final cardWithUser = card.copyWith(userId: customerId);
      await _apiService.addCreditCard(cardWithUser);
      await refreshPaymentMethods();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding credit card: $e');
      rethrow;
    }
  }

  // Add bank account
  Future<void> addBankAccount(BankAccountModel account) async {
    if (!_customerProvider.isAuthenticated) return;

    try {
      final customerId = _customerProvider.customer?.id;
      if (customerId == null || customerId.isEmpty) {
        throw Exception('Customer ID not available');
      }

      final accountWithUser = account.copyWith(userId: customerId);
      await _apiService.addBankAccount(accountWithUser);
      await refreshPaymentMethods();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding bank account: $e');
      rethrow;
    }
  }

  // Add Stripe account
  Future<void> addStripeAccount(StripeAccountModel account) async {
    if (!_customerProvider.isAuthenticated) return;

    try {
      final customerId = _customerProvider.customer?.id;
      if (customerId == null || customerId.isEmpty) {
        throw Exception('Customer ID not available');
      }

      final accountWithUser = account.copyWith(userId: customerId);
      await _apiService.addStripeAccount(accountWithUser);
      await refreshPaymentMethods();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding Stripe account: $e');
      rethrow;
    }
  }

  // Add PayPal account
  Future<void> addPayPalAccount(PayPalAccountModel account) async {
    if (!_customerProvider.isAuthenticated) return;

    try {
      final customerId = _customerProvider.customer?.id;
      if (customerId == null || customerId.isEmpty) {
        throw Exception('Customer ID not available');
      }

      final accountWithUser = account.copyWith(userId: customerId);
      await _apiService.addPayPalAccount(accountWithUser);
      await refreshPaymentMethods();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding PayPal account: $e');
      rethrow;
    }
  }

  // Set default payment method
  Future<void> setDefault(String id) async {
    if (!_customerProvider.isAuthenticated) return;

    try {
      await _apiService.setDefaultPaymentMethod(id);
      await refreshPaymentMethods();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error setting default payment method: $e');
      rethrow;
    }
  }

  // Delete payment method
  Future<void> deletePaymentMethod(String id) async {
    if (!_customerProvider.isAuthenticated) return;

    try {
      await _apiService.deletePaymentMethod(id);
      await refreshPaymentMethods();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting payment method: $e');
      rethrow;
    }
  }

  // Reset state (for logout)
  void reset() {
    _methods = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
