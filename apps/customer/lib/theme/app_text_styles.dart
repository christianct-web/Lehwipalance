import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';

import 'package:lehwipalancecustomerv1/theme/model/enum_models.dart';

class AppTextStyles {
  AppTextStyles._();

  /// Default UI font
  static FontFamilyType get _defaultFont => FontFamilyType.montserrat;

  /* =======================
     INTERNAL BUILDER
     ======================= */

  static TextStyle _style({
    required double fontSize,
    required FontWeight fontWeight,
    double? letterSpacing,
    double? height,
    FontFamilyType? fontFamily,
  }) {
    final family = (fontFamily ?? _defaultFont).googleFontFamilyName;

    return GoogleFonts.getFont(
      family,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /* =======================
     DISPLAY
     ======================= */

  static TextStyle displayLarge([FontFamilyType? fontFamily]) => _style(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
    fontFamily: fontFamily,
  );

  static TextStyle displayMedium([FontFamilyType? fontFamily]) => _style(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    height: 1.16,
    fontFamily: fontFamily,
  );

  static TextStyle displaySmall([FontFamilyType? fontFamily]) => _style(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.22,
    fontFamily: fontFamily,
  );

  /* =======================
     HEADLINES
     ======================= */

  static TextStyle headlineLarge([FontFamilyType? fontFamily]) => _style(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
    fontFamily: fontFamily,
  );

  static TextStyle headlineMedium([FontFamilyType? fontFamily]) => _style(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.29,
    fontFamily: fontFamily,
  );

  static TextStyle headlineSmall([FontFamilyType? fontFamily]) => _style(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    fontFamily: fontFamily,
  );

  /* =======================
     TITLES
     ======================= */

  static TextStyle titleLarge([FontFamilyType? fontFamily]) => _style(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
    fontFamily: fontFamily,
  );

  static TextStyle titleMedium([FontFamilyType? fontFamily]) => _style(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
    fontFamily: fontFamily,
  );

  static TextStyle titleSmall([FontFamilyType? fontFamily]) => _style(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
    fontFamily: fontFamily,
  );

  /* =======================
     BODY
     ======================= */

  static TextStyle bodyLarge([FontFamilyType? fontFamily]) => _style(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
    fontFamily: fontFamily,
  );

  static TextStyle bodyMedium([FontFamilyType? fontFamily]) => _style(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
    fontFamily: fontFamily,
  );

  static TextStyle bodySmall([FontFamilyType? fontFamily]) => _style(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    fontFamily: fontFamily,
  );

  /* =======================
     LABELS / BUTTONS
     ======================= */

  static TextStyle labelLarge([FontFamilyType? fontFamily]) => _style(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
    fontFamily: fontFamily,
  );

  static TextStyle labelMedium([FontFamilyType? fontFamily]) => _style(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
    fontFamily: fontFamily,
  );

  static TextStyle labelSmall([FontFamilyType? fontFamily]) => _style(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.27,
    fontFamily: fontFamily,
  );

  static TextStyle button([FontFamilyType? fontFamily]) => _style(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.43,
    fontFamily: fontFamily,
  );

  static TextStyle buttonLarge([FontFamilyType? fontFamily]) => _style(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.5,
    fontFamily: fontFamily,
  );

  /* =======================
     BRAND / LOGO
     ======================= */

  static TextStyle logoLarge() => _style(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.0,
    fontFamily: FontFamilyType.poppins,
  );

  static TextStyle logoMedium() => _style(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.0,
    fontFamily: FontFamilyType.poppins,
  );

  static TextStyle logoSmall() => _style(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.3,
    height: 1.0,
    fontFamily: FontFamilyType.poppins,
  );
}

extension FontFamilyTypeExtensions on FontFamilyType {
  String get displayName {
    switch (this) {
      case FontFamilyType.montserrat:
        return 'Montserrat';
      case FontFamilyType.roboto:
        return 'Roboto';
      case FontFamilyType.poppins:
        return 'Poppins';
      case FontFamilyType.inter:
        return 'Inter';
    }
  }

  String get googleFontFamilyName {
    switch (this) {
      case FontFamilyType.montserrat:
        return 'Montserrat';
      case FontFamilyType.roboto:
        return 'Roboto';
      case FontFamilyType.poppins:
        return 'Poppins';
      case FontFamilyType.inter:
        return 'Inter';
    }
  }
}

extension ContextExtensions on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
      ),
    );
  }
}

extension ColorSchemeGradient on ColorSchemeType {
  /// Returns a LinearGradient for UI previews
  LinearGradient get gradient => LinearGradient(
    colors: previewColors,
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
