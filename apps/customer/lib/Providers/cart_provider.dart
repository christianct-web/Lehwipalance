import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/Providers/receipt_provider.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/models/receipt_model.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

class CartProvider extends ChangeNotifier {
  final AuthProvider _authProvider;

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  CartProvider({required AuthProvider authProvider})
    : _authProvider = authProvider {
    _setupAuthListener();
    _loadCart();
  }

  // ============= Getters =============
  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);
  String get totalPriceDisplay => '\$${totalPrice.toStringAsFixed(2)}';
  bool get isCartEmpty => _items.isEmpty;

  // ============= Auth Listener =============
  void _setupAuthListener() {
    _authProvider.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (_authProvider.isAuthenticated) {
      _loadCart();
    } else {
      _clearCart();
    }
  }

  // ============= Load Cart =============
  Future<void> _loadCart() async {
    if (!_authProvider.isAuthenticated) {
      _clearCart();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Since there's no direct getCart method in the API,
      // we'll maintain cart in memory and only sync when needed
      // For a real implementation, you'd add getCart/saveCart to the API
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading cart: $e');
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearCart() {
    _items = [];
    _error = null;
    notifyListeners();
  }

  // ============= Public Methods =============

  /// Add item to cart
  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere(
      (i) => i.id == item.id && i.type == item.type,
    );

    if (existingIndex != -1) {
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + item.quantity,
      );
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  /// Remove item from cart
  void removeItem(String id, CartItemType type) {
    _items.removeWhere((item) => item.id == id && item.type == type);
    notifyListeners();
  }

  /// Update item quantity
  void updateQuantity(String id, CartItemType type, int quantity) {
    if (quantity <= 0) {
      removeItem(id, type);
      return;
    }

    final index = _items.indexWhere(
      (item) => item.id == id && item.type == type,
    );
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
    }
  }

  /// Update entire item
  void updateItem(CartItem updatedItem) {
    final index = _items.indexWhere(
      (item) => item.id == updatedItem.id && item.type == updatedItem.type,
    );
    if (index != -1) {
      _items[index] = updatedItem;
      notifyListeners();
    }
  }

  /// Clear cart
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  /// Checkout — convert cart to receipt using ReceiptProvider
  Future<Receipt?> checkout({
    required String orderId,
    required ReceiptProvider receiptProvider,
    double tax = 0.0,
    double discount = 0.0,
    String? paymentMethod,
    String? transactionId,
    String? notes,
    Map<String, dynamic>? metadata,
    String merchantId = '', // 👈 was String?
    String organisationId = '', // 👈 was String?
  }) async {
    if (_items.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return null;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final receipt = await receiptProvider.createReceiptFromCart(
        orderId: orderId,
        cartItems: _items,
        tax: tax,
        discount: discount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        notes: notes,
        metadata: metadata,
        merchantId: merchantId, // now matches — both String
        organisationId: organisationId, // now matches — both String
      );

      if (receipt != null) {
        clearCart();
      }

      return receipt;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error during checkout: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get items grouped by type
  Map<CartItemType, List<CartItem>> getItemsGroupedByType() {
    final Map<CartItemType, List<CartItem>> grouped = {};
    for (final type in CartItemType.values) {
      grouped[type] = _items.where((item) => item.type == type).toList();
    }
    return grouped;
  }

  /// Get total by type
  Map<CartItemType, double> getTotalsByType() {
    final Map<CartItemType, double> totals = {};
    for (final type in CartItemType.values) {
      totals[type] = _items
          .where((item) => item.type == type)
          .fold(0.0, (sum, item) => sum + item.totalPrice);
    }
    return totals;
  }

  /// Check if cart contains a specific item
  bool containsItem(String id, CartItemType type) {
    return _items.any((item) => item.id == id && item.type == type);
  }

  /// Get quantity of a specific item
  int getItemQuantity(String id, CartItemType type) {
    final item = _items.firstWhere(
      (item) => item.id == id && item.type == type,
      orElse: () => throw Exception('Item not found'),
    );
    return item.quantity;
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
