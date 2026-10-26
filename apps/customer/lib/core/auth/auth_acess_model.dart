import 'package:lehwipalancecustomerv1/core/auth/auth_state.dart';
import 'package:lehwipalancecustomerv1/core/models/user_models.dart';

// Update AuthRepository interface
abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;
  Future<UserDTO?> signInWithEmail(String email);
  Future<UserDTO> signUpWithEmail(String email);
  Future<void> signOut();
}
