// ==================== ENUMS ====================
// customer_app/models/enum_models.dart
import 'package:flutter/material.dart';

enum ThemeModeType { light, dark, system }

enum FontFamilyType { montserrat, roboto, inter, poppins }

enum LanguageType {
  system('System'),
  en('English'),
  es('Español'),
  fr('Français'),
  de('Deutsch');

  final String displayName;
  const LanguageType(this.displayName);
}

enum BookingStatus {
  inquired('Inquired'),
  confirmed('Confirmed'),
  booked('Booked'),
  cancelled('Cancelled'),
  pending("Pending"),
  refunded('Refunded');

  final String name;
  const BookingStatus(this.name);
}

enum ColorSchemeType {
  blueTealPurple('Blue Teal Purple'),
  blueOcean('Blue Ocean'),
  tealForest('Teal Forest'),
  purpleDream('Purple Dream');

  final String displayName;

  const ColorSchemeType(this.displayName);

  // Preview colors for the UI selector
  List<Color> get previewColors {
    switch (this) {
      case ColorSchemeType.blueTealPurple:
        return const [
          Color(0xFF009688), // Teal
          Color(0xFF2196F3), // Blue
          Color(0xFF9C27B0), // Purple
        ];
      case ColorSchemeType.blueOcean:
        return const [
          Color(0xFF1565C0), // Dark Blue
          Color(0xFF29B6F6), // Light Blue
          Color(0xFF80DEEA), // Cyan
        ];
      case ColorSchemeType.tealForest:
        return const [
          Color(0xFF00796B), // Dark Teal
          Color(0xFF4DB6AC), // Teal
          Color(0xFFA5D6A7), // Light Green
        ];
      case ColorSchemeType.purpleDream:
        return const [
          Color(0xFF7B1FA2), // Purple
          Color(0xFFBA68C8), // Light Purple
          Color(0xFFE1BEE7), // Lavender
        ];
    }
  }

  // Primary color for each scheme
  Color get primary {
    switch (this) {
      case ColorSchemeType.blueTealPurple:
        return const Color(0xFF009688); // Teal
      case ColorSchemeType.blueOcean:
        return const Color(0xFF1565C0); // Blue
      case ColorSchemeType.tealForest:
        return const Color(0xFF00796B); // Teal
      case ColorSchemeType.purpleDream:
        return const Color(0xFF7B1FA2); // Purple
    }
  }

  // Secondary color for each scheme
  Color get secondary {
    switch (this) {
      case ColorSchemeType.blueTealPurple:
        return const Color(0xFF2196F3); // Blue
      case ColorSchemeType.blueOcean:
        return const Color(0xFF29B6F6); // Light Blue
      case ColorSchemeType.tealForest:
        return const Color(0xFF4DB6AC); // Teal
      case ColorSchemeType.purpleDream:
        return const Color(0xFFBA68C8); // Light Purple
    }
  }

  // Tertiary color for each scheme
  Color get tertiary {
    switch (this) {
      case ColorSchemeType.blueTealPurple:
        return const Color(0xFF9C27B0); // Purple
      case ColorSchemeType.blueOcean:
        return const Color(0xFF80DEEA); // Cyan
      case ColorSchemeType.tealForest:
        return const Color(0xFFA5D6A7); // Light Green
      case ColorSchemeType.purpleDream:
        return const Color(0xFFE1BEE7); // Lavender
    }
  }

  // Helper method to get display name
  String get name => displayName;

  // Get all color schemes for dropdown
  static List<ColorSchemeType> get all => ColorSchemeType.values.toList();

  // Find by display name
  static ColorSchemeType? fromDisplayName(String name) {
    try {
      return ColorSchemeType.values.firstWhere(
        (scheme) => scheme.displayName == name,
      );
    } catch (e) {
      return null;
    }
  }
}
