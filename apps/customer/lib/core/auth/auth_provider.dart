import 'dart:async';
import 'package:flutter/material.dart';

import 'package:lehwipalancecustomerv1/core/auth/auth_state.dart';
import 'package:lehwipalancecustomerv1/core/base/mock_api_service.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/contact_info.dart';
import 'package:lehwipalancecustomerv1/core/models/common_models/social_links.dart';
import 'package:lehwipalancecustomerv1/core/models/venue_model.dart';
import 'package:lehwipalancecustomerv1/core/models/user_models.dart';

/*
  Key Responsibilities:
    - Manage authentication state (loading, authenticated, unauthenticated, error)
    - Handle login and logout actions
    - Load a specific organisation or UserDTO for the current user
 - Check organisation or UserDTO permissions for accessing different listings   
    - Store and retrieve user session data securely
    - Provide access to current user information and permissions   
  
  
  
  */

AuthProvider get authService => getIt<AuthProvider>();

class MockAuthService implements AuthServiceInterface {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  UserDTO? _currentUser;
  String? _currentToken;
  final _authStateController = StreamController<AuthState>.broadcast();

  // Helper method to get users from MockDatabase
  Map<String, UserDTO> get _users => MockDatabase.users;

  @override
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  @override
  Future<UserDTO?> signInWithEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Find user from MockDatabase
    final user = _users[email];

    if (user == null) {
      _authStateController.add(const AuthError('User not found'));
      return null;
    }

    if (user.isBanned) {
      _authStateController.add(
        AuthError('Account is banned: ${user.banReason ?? "Contact support"}'),
      );
      return null;
    }

    if (!user.isActive) {
      _authStateController.add(const AuthError('Account is deactivated'));
      return null;
    }

    // Successful sign in
    _currentUser = user;
    _currentToken =
        'mock_jwt_token_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

    _authStateController.add(Authenticated(user: user, token: _currentToken!));

    return user;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
    _currentToken = null;
    _authStateController.add(const Unauthenticated());
  }

  @override
  Future<bool> checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentUser != null;
  }

  @override
  UserDTO? getCurrentUser() {
    return _currentUser;
  }

  String? getCurrentToken() {
    return _currentToken;
  }

  // Helper method for testing - sign in as specific type
  Future<UserDTO?> signInAsCustomer() async {
    // Find first customer email
    final customer = MockDatabase.customers.values.firstOrNull;
    if (customer != null) {
      return signInWithEmail(customer.email);
    }
    return null;
  }

  Future<UserDTO?> signInAsMember() async {
    // Find first member email
    final member = MockDatabase.members.values.firstOrNull;
    if (member != null) {
      return signInWithEmail(member.email);
    }
    return null;
  }

  // Register new user (for demo)
  Future<UserDTO> registerCustomer({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (_users.containsKey(email)) {
      throw Exception('User already exists');
    }

    final newCustomer = CustomerDTO(
      id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      updatedAt: null,
      fcmToken: null,
      name: name,
      email: email,
      imageUrl:
          'https://i.pravatar.cc/150?img=${DateTime.now().millisecondsSinceEpoch}',
      bio: null,
      gender: null,
      contactInfo: ContactInfo(
        socialLinks: const SocialLinks(),
        email: email,
        phone: null,
        website: null,
        qrCodeUrl: null,
      ),
      address: AddressModel(
        street: '',
        city: '',
        state: '',
        country: '',
        postalCode: '',
      ),
      language: 'en',
      currency: 'USD',
      walletId: 'wallet_${DateTime.now().millisecondsSinceEpoch}',
      isActive: true,
      isBanned: false,
      banReason: null,
      notificationsEnabled: true,
      filterPreferencesID: 'filter_${DateTime.now().millisecondsSinceEpoch}',
      savedMerchantIds: [],
      followingOrganisationsIds: [],
      bookingIds: [],
      likedMediaIds: [],
    );

    // Add to mock database
    MockDatabase.customers[newCustomer.id] = newCustomer;
    MockDatabase.users[newCustomer.id] = newCustomer;
    MockDatabase.users[email] = newCustomer;

    return newCustomer;
  }

  void dispose() {
    _authStateController.close();
  }
}
// ==================== PROVIDER INTEGRATION ====================

class AuthProvider extends ChangeNotifier {
  final MockAuthService _authService;
  final MockApiService _apiService;
  AuthState _state = const AuthInitial();
  bool _isInitialized = false; // Add this

  AuthProvider({MockAuthService? authService, MockApiService? apiService})
    : _authService = authService ?? MockAuthService(),
      _apiService = apiService ?? MockApiService() {
    _init();
  }

  AuthState get state => _state;
  bool get isAuthenticated => _state.isAuthenticated;
  bool get isCustomer => _state.isCustomer;
  bool get isMember => _state.isMember;

  CustomerDTO? get customerUser => _state.customerUser;
  MemberDTO? get memberUser => _state.memberUser;

  Future<void> _init() async {
    if (_isInitialized) return; // Prevent duplicate initialization
    _isInitialized = true;

    _authService.authStateChanges.listen((newState) {
      _state = newState;
      notifyListeners();
    });

    await _checkInitialAuth(); // Make this async properly
  }

  Future<void> _checkInitialAuth() async {
    _state = const AuthLoading();
    notifyListeners();

    final isAuthenticated = await _authService.checkAuthStatus();

    if (isAuthenticated) {
      final user = _authService.getCurrentUser();
      final token = (_authService).getCurrentToken();
      if (user != null && token != null) {
        _state = Authenticated(user: user, token: token);
      } else {
        _state = const Unauthenticated();
      }
    } else {
      _state = const Unauthenticated();
    }
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email) async {
    _state = const AuthLoading();
    notifyListeners();

    try {
      final user = await _authService.signInWithEmail(email);
      final dbUser = user != null
          ? await _apiService.getUserByEmail(email)
          : null;
      return user != null && dbUser != null;
    } catch (e) {
      _state = AuthError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInAsCustomer() async {
    _state = const AuthLoading();
    notifyListeners();

    try {
      final user = await (_authService).signInAsCustomer();
      if (user != null) {
        final dbUser = await _apiService.getUserByEmail(user.email);
        return dbUser != null;
      }
      return false;
    } catch (e) {
      _state = AuthError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInAsMember() async {
    _state = const AuthLoading();
    notifyListeners();

    try {
      final user = await (_authService).signInAsMember();
      if (user != null) {
        final dbUser = await _apiService.getUserByEmail(user.email);
        return dbUser != null;
      }
      return false;
    } catch (e) {
      _state = AuthError(e.toString());
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _state = const AuthLoading();
    notifyListeners();
    await _authService.signOut();
  }

  // API service passthrough methods
  Future<CustomerDTO?> getCustomerProfile() async {
    if (!isCustomer) return null;
    return _apiService.getCustomerById(_state.user!.id);
  }

  Future<MemberDTO?> getMemberProfile() async {
    if (!isMember) return null;
    return _apiService.getMemberByUserId(_state.user!.id);
  }

  Future<CustomerDTO> addSavedMerchant(String merchantId) async {
    if (!isCustomer) throw Exception('Not a customer');
    return _apiService.addSavedMerchant(_state.user!.id, merchantId);
  }

  @override
  void dispose() {
    (_authService).dispose();
    super.dispose();
  }
}
