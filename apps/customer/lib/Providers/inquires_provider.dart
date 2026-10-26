import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/core/auth/auth_provider.dart';
import 'package:lehwipalancecustomerv1/core/base/api_service.dart';
import 'package:lehwipalancecustomerv1/core/models/inquiries_model.dart';
import 'package:lehwipalancecustomerv1/core/models/receipt_model.dart';

// lib/customer/modules/inquiry/inquiry_screen.dart

class InquiryProvider extends ChangeNotifier {
  final ApiService _apiService;
  final AuthProvider _authProvider;

  List<Inquiry> _inquiries = [];
  bool _isLoading = false;
  String? _error;

  InquiryProvider({
    required ApiService apiService,
    required AuthProvider authProvider,
  }) : _apiService = apiService,
       _authProvider = authProvider {
    _setupAuthListener();
    _loadInquiries();
  }

  // ============= Getters =============
  List<Inquiry> get inquiries => List.unmodifiable(_inquiries);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ============= Auth Listener =============
  void _setupAuthListener() {
    _authProvider.addListener(_onAuthStateChanged);
  }

  void _onAuthStateChanged() {
    if (_authProvider.isAuthenticated) {
      _loadInquiries();
    } else {
      _clearInquiries();
    }
  }

  // ============= Load Inquiries =============
  Future<void> _loadInquiries() async {
    if (!_authProvider.isAuthenticated) {
      _clearInquiries();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String userId;
      if (_authProvider.isCustomer) {
        userId = _authProvider.customerUser!.id;
      } else if (_authProvider.isMember) {
        userId = _authProvider.memberUser!.id;
      } else {
        throw Exception('No authenticated user found');
      }

      _inquiries = await _apiService.getInquiriesByUserId(userId);
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading inquiries: $e');
      _inquiries = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearInquiries() {
    _inquiries = [];
    _error = null;
    notifyListeners();
  }

  // ============= Public Methods =============

  Future<void> refreshInquiries() async {
    await _loadInquiries();
  }

  Future<Inquiry?> createInquiry({
    required List<CartItem> cartItems,
    required String subject,
    required String message,
    String? merchantId,
    String? organisationId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String userId;
      if (_authProvider.isCustomer) {
        userId = _authProvider.customerUser!.id;
      } else if (_authProvider.isMember) {
        userId = _authProvider.memberUser!.id;
      } else {
        throw Exception('No authenticated user found');
      }

      final inquiry = Inquiry.fromCart(
        userId: userId,
        cartItems: cartItems,
        subject: subject,
        message: message,
        merchantId: merchantId,
        organisationId: organisationId,
        metadata: metadata,
      );

      final created = await _apiService.createInquiry(inquiry);
      _inquiries.insert(0, created);
      return created;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error creating inquiry: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Inquiry?> respondToInquiry(String inquiryId, String response) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updated = await _apiService.respondToInquiry(inquiryId, response);
      final index = _inquiries.indexWhere((i) => i.id == inquiryId);
      if (index != -1) {
        _inquiries[index] = updated;
      }
      return updated;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error responding to inquiry: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Inquiry?> updateInquiryStatus(
    String inquiryId,
    InquiryStatus status,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updated = await _apiService.updateInquiryStatus(inquiryId, status);
      final index = _inquiries.indexWhere((i) => i.id == inquiryId);
      if (index != -1) {
        _inquiries[index] = updated;
      }
      return updated;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating inquiry status: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteInquiry(String inquiryId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _apiService.deleteInquiry(inquiryId);
      _inquiries.removeWhere((i) => i.id == inquiryId);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting inquiry: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Inquiry> getInquiriesByStatus(InquiryStatus status) {
    return _inquiries.where((i) => i.status == status).toList();
  }

  int get pendingCount {
    return _inquiries.where((i) => i.isPending).length;
  }

  int get respondedCount {
    return _inquiries.where((i) => i.isResponded).length;
  }

  int get resolvedCount {
    return _inquiries.where((i) => i.isResolved).length;
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}
