import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/models/receipt_model.dart';
import 'package:lehwipalancecustomerv1/core/utils/logutil.dart';
import 'package:lehwipalancecustomerv1/enum.dart';

// ============================================
// RECEIPT PROVIDER
// ============================================

class ReceiptProvider extends ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider _authProvider;

  List<Receipt> _receipts = [];
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  ReceiptProvider({
    required ApiService apiService,
    required AuthProvider authProvider,
  }) : _apiService = apiService,
       _authProvider = authProvider {
    _setupAuthListener();
    _loadReceipts();
  }

  // ============= Getters =============
  List<Receipt> get receipts => List.unmodifiable(_receipts);
  int get receiptCount => _receipts.length;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDisposed => _isDisposed;

  // ============= Auth Listener =============
  void _setupAuthListener() {
    _authProvider.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (_isDisposed) return;

    if (_authProvider.isAuthenticated) {
      _loadReceipts();
    } else {
      _clearReceipts();
    }
  }

  // ============= Load Receipts =============
  Future<void> _loadReceipts() async {
    if (_isDisposed) return;

    if (!_authProvider.isAuthenticated) {
      _clearReceipts();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _currentUserId();
      if (userId == null) {
        throw Exception('No authenticated user found');
      }

      try {
        _receipts = await _apiService.getReceiptsByUserId(userId);
        AppLogger.info('Loaded ${_receipts.length} receipts from API');
        _error = null;
      } catch (e) {
        AppLogger.error('Error loading receipts from API: $e');
        _error = e.toString();

        // Only fall back to mock data in debug mode; in production,
        // show an empty list and surface the error to the caller.
        if (kDebugMode) {
          _loadMockReceipts();
        } else {
          _receipts = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error loading receipts: $e');
      if (kDebugMode) {
        _loadMockReceipts();
      } else {
        _receipts = [];
      }
    } finally {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _loadMockReceipts() {
    if (_isDisposed) return;
    if (mockReceipts.isNotEmpty) {
      _receipts = List.from(mockReceipts);
      AppLogger.info('Loaded ${_receipts.length} mock receipts');
    }
  }

  void _clearReceipts() {
    if (_isDisposed) return;
    _receipts = [];
    _error = null;
    notifyListeners();
  }

  // ============= Helpers =============

  /// Returns the current authenticated user's ID, or null.
  String? _currentUserId() {
    if (_authProvider.isCustomer && _authProvider.customerUser != null) {
      return _authProvider.customerUser!.id;
    }
    if (_authProvider.isMember && _authProvider.memberUser != null) {
      return _authProvider.memberUser!.id;
    }
    return null;
  }

  // ============= Public Methods =============

  Future<void> refreshReceipts() async {
    if (_isDisposed) return;
    await _loadReceipts();
  }

  /// Create a receipt from cart items. Uses the authenticated user's ID.
  /// `merchantId` and `organisationId` default to `''` because the
  /// `ReceiptApiService` interface declares them as non-nullable.
  Future<Receipt?> createReceiptFromCart({
    required String orderId,
    required List<CartItem> cartItems,
    double tax = 0.0,
    double discount = 0.0,
    String? paymentMethod,
    String? transactionId,
    String? notes,
    Map<String, dynamic>? metadata,
    String merchantId = '',
    String organisationId = '',
  }) async {
    if (_isDisposed) return null;

    final userId = _currentUserId();
    if (userId == null) {
      _error = 'No authenticated user found';
      AppLogger.error(_error!);
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final receipt = await _apiService.createReceiptFromCart(
        orderId: orderId,
        userId: userId,
        cartItems: cartItems,
        tax: tax,
        discount: discount,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        notes: notes,
        metadata: metadata ?? {},
        merchantId: merchantId,
        organisationId: organisationId,
      );

      _receipts = [receipt, ..._receipts];
      _error = null;
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return receipt;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error creating receipt from cart: $e');

      // Fallback: build a local receipt so the user still sees a
      // confirmation screen even when the API is unreachable.
      try {
        final subtotal = cartItems.fold<double>(
          0.0,
          (sum, item) => sum + item.totalPrice,
        );
        final total = subtotal + tax - discount;
        final now = DateTime.now();

        final fallback = Receipt(
          id: 'RCP${now.millisecondsSinceEpoch.toString().substring(5)}',
          orderId: orderId,
          userId: userId,
          merchantId: merchantId.isEmpty ? null : merchantId,
          organisationId: organisationId.isEmpty ? null : organisationId,
          items: List<CartItem>.from(cartItems),
          subtotal: subtotal,
          tax: tax,
          discount: discount,
          total: total,
          paymentMethod: paymentMethod,
          transactionId: transactionId,
          notes: notes,
          metadata: metadata ?? {},
          status: ReceiptStatus.purchased,
          createdAt: now,
          updatedAt: now,
          paidAt: now,
        );

        _receipts = [fallback, ..._receipts];
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return fallback;
      } catch (fallbackError) {
        AppLogger.error(
          'Fallback receipt creation also failed: $fallbackError',
        );
        _isLoading = false;
        if (!_isDisposed) notifyListeners();
        return null;
      }
    }
  }

  /// Create a new receipt.
  Future<Receipt?> createReceipt(Receipt receipt) async {
    if (_isDisposed) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final saved = await _apiService.createReceipt(receipt);
      _receipts = [saved, ..._receipts];
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return saved;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error creating receipt: $e');

      // Fallback: add locally.
      _receipts = [receipt, ..._receipts];
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return receipt;
    }
  }

  // ============= Read =============

  /// Synchronous cache lookup. Returns null if not loaded yet.
  Receipt? getReceiptById(String id) {
    if (_isDisposed) return null;
    try {
      return _receipts.firstWhere((receipt) => receipt.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Fetch a single receipt by ID from the API and cache it.
  /// No-op if already in memory. Safe to call from any screen.
  ///
  /// This is what `ReceiptScreen(receiptId: ...)` calls when it can't
  /// find the receipt in the local cache (e.g. after a page refresh
  /// or on a shared deep link).
  Future<void> loadReceiptsById(String receiptId) async {
    if (_isDisposed) return;

    // Fast path — already cached.
    if (getReceiptById(receiptId) != null) return;

    try {
      final fetched = await _apiService.getReceiptById(receiptId);
      if (fetched == null) return;

      _receipts = [fetched, ..._receipts];
      if (!_isDisposed) notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading receipt $receiptId: $e');
      // Swallow — caller (ReceiptScreen) shows its own error state.
    }
  }

  /// Get receipts by status (from local cache).
  List<Receipt> getReceiptsByStatusLocal(ReceiptStatus status) {
    if (_isDisposed) return [];
    return _receipts.where((r) => r.status == status).toList();
  }

  /// Get receipts by order ID (from local cache).
  List<Receipt> getReceiptsByOrderIdLocal(String orderId) {
    if (_isDisposed) return [];
    return _receipts.where((r) => r.orderId == orderId).toList();
  }

  /// Get receipts by date range (from local cache).
  List<Receipt> getReceiptsByDateRangeLocal(DateTime start, DateTime end) {
    if (_isDisposed) return [];
    return _receipts
        .where((r) => r.createdAt.isAfter(start) && r.createdAt.isBefore(end))
        .toList();
  }

  /// Get receipts by user ID (from API, falls back to local cache).
  Future<List<Receipt>> getReceiptsByUserId(String userId) async {
    if (_isDisposed) return [];
    try {
      return await _apiService.getReceiptsByUserId(userId);
    } catch (e) {
      AppLogger.error('Error getting receipts by user ID: $e');
      return _receipts.where((r) => r.userId == userId).toList();
    }
  }

  /// Get receipts by merchant ID (from API, falls back to local cache).
  Future<List<Receipt>> getReceiptsByMerchantId(String merchantId) async {
    if (_isDisposed) return [];
    try {
      return await _apiService.getReceiptsByMerchantId(merchantId);
    } catch (e) {
      AppLogger.error('Error getting receipts by merchant ID: $e');
      return _receipts.where((r) => r.merchantId == merchantId).toList();
    }
  }

  // ============= Update =============

  Future<Receipt?> updateReceiptStatus(
    String id,
    ReceiptStatus newStatus,
  ) async {
    if (_isDisposed) return null;

    final index = _receipts.indexWhere((r) => r.id == id);
    if (index == -1) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _apiService.updateReceiptStatus(id, newStatus);
      _receipts[index] = updated;
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error updating receipt status: $e');

      // Fallback: update locally.
      final receipt = _receipts[index];
      _receipts[index] = receipt.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
        paidAt: newStatus == ReceiptStatus.purchased
            ? DateTime.now()
            : receipt.paidAt,
      );
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return _receipts[index];
    }
  }

  Future<Receipt?> updateReceiptPaymentInfo(
    String id, {
    String? paymentMethod,
    String? transactionId,
    DateTime? paidAt,
  }) async {
    if (_isDisposed) return null;

    final index = _receipts.indexWhere((r) => r.id == id);
    if (index == -1) return null;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _apiService.updateReceiptPaymentInfo(
        id,
        paymentMethod: paymentMethod,
        transactionId: transactionId,
        paidAt: paidAt,
      );
      _receipts[index] = updated;
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return updated;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error updating receipt payment: $e');
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return null;
    }
  }

  // ============= Delete =============

  Future<bool> deleteReceipt(String id) async {
    if (_isDisposed) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteReceipt(id);
      _receipts.removeWhere((r) => r.id == id);
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error deleting receipt: $e');
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  // ============= Analytics =============

  Future<double> getTotalRevenue({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (_isDisposed) return 0.0;

    try {
      return await _apiService.getTotalRevenue(
        userId: _currentUserId(),
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      AppLogger.error('Error getting total revenue: $e');

      // Fallback: calculate locally.
      return _receipts
          .where(
            (r) =>
                (r.status == ReceiptStatus.purchased ||
                    r.status == ReceiptStatus.checkedIn ||
                    r.status == ReceiptStatus.checked ||
                    r.status == ReceiptStatus.approved) &&
                (startDate == null || r.createdAt.isAfter(startDate)) &&
                (endDate == null || r.createdAt.isBefore(endDate)),
          )
          .fold<double>(0.0, (sum, r) => sum + r.total);
    }
  }

  Future<Map<ReceiptStatus, int>> getStatusCounts() async {
    if (_isDisposed) return {};

    try {
      return await _apiService.getReceiptStatusCounts(userId: _currentUserId());
    } catch (e) {
      AppLogger.error('Error getting status counts: $e');

      // Fallback: count locally.
      final counts = <ReceiptStatus, int>{};
      for (final status in ReceiptStatus.values) {
        counts[status] = _receipts.where((r) => r.status == status).length;
      }
      return counts;
    }
  }

  Future<List<Receipt>> searchReceipts({
    String? query,
    ReceiptStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    double? minTotal,
    double? maxTotal,
  }) async {
    if (_isDisposed) return [];

    try {
      return await _apiService.searchReceipts(
        query: query,
        userId: _currentUserId(),
        status: status,
        startDate: startDate,
        endDate: endDate,
        minTotal: minTotal,
        maxTotal: maxTotal,
      );
    } catch (e) {
      AppLogger.error('Error searching receipts: $e');

      // Fallback: search locally.
      return _receipts.where((receipt) {
        if (query != null) {
          final q = query.toLowerCase();
          final matches =
              receipt.id.toLowerCase().contains(q) ||
              receipt.orderId.toLowerCase().contains(q) ||
              receipt.items.any((item) => item.name.toLowerCase().contains(q));
          if (!matches) return false;
        }
        if (status != null && receipt.status != status) return false;
        if (startDate != null && receipt.createdAt.isBefore(startDate)) {
          return false;
        }
        if (endDate != null && receipt.createdAt.isAfter(endDate)) {
          return false;
        }
        if (minTotal != null && receipt.total < minTotal) return false;
        if (maxTotal != null && receipt.total > maxTotal) return false;
        return true;
      }).toList();
    }
  }

  // ============= Batch =============

  Future<bool> batchUpdateReceiptStatus(
    List<String> receiptIds,
    ReceiptStatus newStatus,
  ) async {
    if (_isDisposed) return false;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.batchUpdateReceiptStatus(receiptIds, newStatus);

      for (final id in receiptIds) {
        final index = _receipts.indexWhere((r) => r.id == id);
        if (index != -1) {
          _receipts[index] = _receipts[index].copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
          );
        }
      }
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Error batch updating receipt statuses: $e');
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return false;
    }
  }

  // ============= Disposal =============

  @override
  void dispose() {
    _isDisposed = true;
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
