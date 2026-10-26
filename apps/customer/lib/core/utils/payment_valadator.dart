class PaymentValidator {
  static bool isValidCardNumber(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length < 13 || cleaned.length > 19) return false;
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return false;
    return _luhnCheck(cleaned);
  }

  static bool isValidExpiry(String expiry) {
    final parts = expiry.split('/');
    if (parts.length != 2) return false;

    final month = int.tryParse(parts[0]);
    final year = int.tryParse('20${parts[1]}');

    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;

    final now = DateTime.now();
    final expiryDate = DateTime(year, month + 1, 0);
    final currentDate = DateTime(now.year, now.month + 1, 0);

    return expiryDate.isAfter(currentDate) ||
        expiryDate.isAtSameMomentAs(currentDate);
  }

  static bool isValidCVV(String cvv, [String? cardBrand]) {
    final length = cardBrand == 'amex' ? 4 : 3;
    return RegExp(r'^\d{' + length.toString() + r'}$').hasMatch(cvv);
  }

  static String? detectCardBrand(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'\s+'), '');

    if (cleaned.startsWith('4')) {
      return 'visa';
    } else if (RegExp(r'^5[1-5]').hasMatch(cleaned)) {
      return 'mastercard';
    } else if (RegExp(r'^3[47]').hasMatch(cleaned)) {
      return 'amex';
    } else if (RegExp(r'^6(?:011|5)').hasMatch(cleaned)) {
      return 'discover';
    }
    return null;
  }

  static bool _luhnCheck(String cardNumber) {
    int sum = 0;
    bool alternate = false;

    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int n = int.parse(cardNumber[i]);

      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }

      sum += n;
      alternate = !alternate;
    }

    return (sum % 10 == 0);
  }
}
