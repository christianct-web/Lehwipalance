import 'package:lehwipalancecustomerv1/core/models/user_models.dart';

abstract class AuthServiceInterface {
  Stream<AuthState> get authStateChanges;
  Future<UserDTO?> signInWithEmail(String email);
  Future<void> signOut();
  Future<bool> checkAuthStatus();
  UserDTO? getCurrentUser();
}

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

enum MemberStatus { active, suspended, deactivated }

abstract class AuthState {
  final AuthStatus status;
  final UserDTO? user;
  final String? error;
  final String? token;

  const AuthState({required this.status, this.user, this.error, this.token});

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isCustomer => user is CustomerDTO;
  bool get isMember => user is MemberDTO;

  CustomerDTO? get customerUser => user as CustomerDTO?;
  MemberDTO? get memberUser => user as MemberDTO?;
}

// Initial state
class AuthInitial extends AuthState {
  const AuthInitial() : super(status: AuthStatus.initial);
}

// Loading state
class AuthLoading extends AuthState {
  const AuthLoading() : super(status: AuthStatus.loading);
}

// Authenticated state
class Authenticated extends AuthState {
  const Authenticated({required UserDTO user, required String token})
    : super(status: AuthStatus.authenticated, user: user, token: token);
}

// Unauthenticated state
class Unauthenticated extends AuthState {
  const Unauthenticated() : super(status: AuthStatus.unauthenticated);
}

// Error state
class AuthError extends AuthState {
  const AuthError(String message)
    : super(status: AuthStatus.error, error: message);
}
