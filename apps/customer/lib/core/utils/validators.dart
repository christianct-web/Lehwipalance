class ValidationUtils {
  static const int maxResendCount = 3;
  static const Duration invitationExpiry = Duration(days: 7);
  static const int maxTeamMembers = 100;
  static const int maxListingsPerOrganisation = 50;

  static void validateEmail(String email) {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      throw ValidationException('Invalid email format');
    }
  }

  static void validateName(String name, String fieldName,
      {int maxLength = 200}) {
    if (name.isEmpty || name.length > maxLength) {
      throw ValidationException(
          '$fieldName must be between 1 and $maxLength characters');
    }
  }
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.code});
}

class AppException implements Exception {
  final String message;
  final String? code;
  final StackTrace? stackTrace;

  AppException(this.message, {this.code, this.stackTrace});

  @override
  String toString() =>
      'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

class AuthException extends AppException {
  AuthException(super.message, {super.code, super.stackTrace});
}

class AccessException extends AppException {
  final String requiredPermission;

  AccessException(super.message,
      {required this.requiredPermission, super.code});
}
