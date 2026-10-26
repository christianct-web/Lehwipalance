import 'package:flutter_test/flutter_test.dart';
import 'package:lehwipalancecustomerv1/core/utils/validators.dart';

// Starter tests so `flutter test` runs in CI.
// Add widget and provider tests as features are rebuilt.
void main() {
  group('ValidationUtils.validateEmail', () {
    test('accepts a well-formed address', () {
      expect(() => ValidationUtils.validateEmail('promoter@example.com'),
          returnsNormally);
    });

    test('rejects a malformed address', () {
      expect(() => ValidationUtils.validateEmail('not-an-email'),
          throwsA(anything));
    });
  });
}
