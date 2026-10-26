// core/theme/color_schemes.dart
import 'package:flutter/material.dart';
import 'package:lehwipalancecustomerv1/theme/model/enum_models.dart';

class ColorSchemes {
  ColorSchemes._();

  static ColorScheme getLightScheme(ColorSchemeType type) {
    switch (type) {
      case ColorSchemeType.blueTealPurple:
        return const ColorScheme.light(
          primary: Color(0xFF009688),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFB2EBF2),
          onPrimaryContainer: Color(0xFF001F2A),
          secondary: Color(0xFF2196F3),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFE3F2FD),
          onSecondaryContainer: Color(0xFF001D32),
          tertiary: Color(0xFF9C27B0),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFE8DAF2),
          onTertiaryContainer: Color(0xFF24005E),
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          surface: Color(0xFFFAFDFD),
          onSurface: Color(0xFF191C1D),
          surfaceContainerHighest: Color(0xFFDBE4E6),
          onSurfaceVariant: Color(0xFF3F484A),
          outline: Color(0xFF6F797A),
          outlineVariant: Color(0xFFBFC8CA),
          scrim: Colors.black,
          shadow: Colors.black,
        );

      case ColorSchemeType.blueOcean:
        return const ColorScheme.light(
          primary: Color(0xFF1565C0),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFD1E4FF),
          onPrimaryContainer: Color(0xFF001C3A),
          secondary: Color(0xFF29B6F6),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFC6E7FF),
          onSecondaryContainer: Color(0xFF001E30),
          tertiary: Color(0xFF80DEEA),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFC6F2F8),
          onTertiaryContainer: Color(0xFF002022),
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          surface: Color(0xFFFAFCFF),
          onSurface: Color(0xFF1A1C1E),
          surfaceContainerHighest: Color(0xFFE2E2E6),
          onSurfaceVariant: Color(0xFF43474E),
          outline: Color(0xFF73777F),
          outlineVariant: Color(0xFFC3C7CF),
          scrim: Colors.black,
          shadow: Colors.black,
        );

      case ColorSchemeType.tealForest:
        return const ColorScheme.light(
          primary: Color(0xFF00796B),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFA7FFEB),
          onPrimaryContainer: Color(0xFF00201B),
          secondary: Color(0xFF4DB6AC),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFC8FFF4),
          onSecondaryContainer: Color(0xFF00201C),
          tertiary: Color(0xFFA5D6A7),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFC8E6C9),
          onTertiaryContainer: Color(0xFF002004),
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          surface: Color(0xFFFAFDFB),
          onSurface: Color(0xFF191C1B),
          surfaceContainerHighest: Color(0xFFDBE5E3),
          onSurfaceVariant: Color(0xFF3F4947),
          outline: Color(0xFF6F7977),
          outlineVariant: Color(0xFFBFC9C7),
          scrim: Colors.black,
          shadow: Colors.black,
        );

      case ColorSchemeType.purpleDream:
        return const ColorScheme.light(
          primary: Color(0xFF7B1FA2),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFF2DAFF),
          onPrimaryContainer: Color(0xFF280056),
          secondary: Color(0xFFBA68C8),
          onSecondary: Colors.white,
          secondaryContainer: Color(0xFFF2D7FF),
          onSecondaryContainer: Color(0xFF270057),
          tertiary: Color(0xFFE1BEE7),
          onTertiary: Colors.white,
          tertiaryContainer: Color(0xFFF8E7FF),
          onTertiaryContainer: Color(0xFF2D004F),
          error: Color(0xFFBA1A1A),
          onError: Colors.white,
          surface: Color(0xFFFEF7FF),
          onSurface: Color(0xFF1D1B20),
          surfaceContainerHighest: Color(0xFFE7E0EC),
          onSurfaceVariant: Color(0xFF49454E),
          outline: Color(0xFF7A757F),
          outlineVariant: Color(0xFFCAC4D0),
          scrim: Colors.black,
          shadow: Colors.black,
        );
    }
  }

  static ColorScheme getDarkScheme(ColorSchemeType type) {
    switch (type) {
      case ColorSchemeType.blueTealPurple:
        return const ColorScheme.dark(
          primary: Color(0xFF4FD8EB),
          onPrimary: Color(0xFF00363D),
          primaryContainer: Color(0xFF004F59),
          onPrimaryContainer: Color(0xFF97F0FF),
          secondary: Color(0xFF90CAF9),
          onSecondary: Color(0xFF003354),
          secondaryContainer: Color(0xFF004A78),
          onSecondaryContainer: Color(0xFFCAE6FF),
          tertiary: Color(0xFFD0BCFF),
          onTertiary: Color(0xFF371E73),
          tertiaryContainer: Color(0xFF4E378B),
          onTertiaryContainer: Color(0xFFEADDFF),
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
          surface: Color(0xFF191C1D),
          onSurface: Color(0xFFE1E3E3),
          surfaceContainerHighest: Color(0xFF3F484A),
          onSurfaceVariant: Color(0xFFBFC8CA),
          outline: Color(0xFF899294),
          outlineVariant: Color(0xFF3F484A),
          scrim: Colors.black,
          shadow: Colors.black,
        );

      case ColorSchemeType.blueOcean:
        return const ColorScheme.dark(
          primary: Color(0xFF9FC9FF),
          onPrimary: Color(0xFF00315F),
          primaryContainer: Color(0xFF004786),
          onPrimaryContainer: Color(0xFFD1E4FF),
          secondary: Color(0xFF8ACFFF),
          onSecondary: Color(0xFF00344F),
          secondaryContainer: Color(0xFF004B70),
          onSecondaryContainer: Color(0xFFC6E7FF),
          tertiary: Color(0xFFA4E9EF),
          onTertiary: Color(0xFF00363B),
          tertiaryContainer: Color(0xFF004F55),
          onTertiaryContainer: Color(0xFFC6F2F8),
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
          surface: Color(0xFF1A1C1E),
          onSurface: Color(0xFFE2E2E6),
          surfaceContainerHighest: Color(0xFF43474E),
          onSurfaceVariant: Color(0xFFC3C7CF),
          outline: Color(0xFF8D9199),
          outlineVariant: Color(0xFF43474E),
          scrim: Colors.black,
          shadow: Colors.black,
        );

      case ColorSchemeType.tealForest:
        return const ColorScheme.dark(
          primary: Color(0xFF4FDAB5),
          onPrimary: Color(0xFF00382A),
          primaryContainer: Color(0xFF005140),
          onPrimaryContainer: Color(0xFFA7FFEB),
          secondary: Color(0xFF8ADBD2),
          onSecondary: Color(0xFF003733),
          secondaryContainer: Color(0xFF00504A),
          onSecondaryContainer: Color(0xFFC8FFF4),
          tertiary: Color(0xFFB8EAB9),
          onTertiary: Color(0xFF00360A),
          tertiaryContainer: Color(0xFF005215),
          onTertiaryContainer: Color(0xFFC8E6C9),
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
          surface: Color(0xFF191C1B),
          onSurface: Color(0xFFE0E3E1),
          surfaceContainerHighest: Color(0xFF3F4947),
          onSurfaceVariant: Color(0xFFBFC9C7),
          outline: Color(0xFF899390),
          outlineVariant: Color(0xFF3F4947),
          scrim: Colors.black,
          shadow: Colors.black,
        );

      case ColorSchemeType.purpleDream:
        return const ColorScheme.dark(
          primary: Color(0xFFE1B3FF),
          onPrimary: Color(0xFF430075),
          primaryContainer: Color(0xFF5E009E),
          onPrimaryContainer: Color(0xFFF2DAFF),
          secondary: Color(0xFFE6B9FF),
          onSecondary: Color(0xFF420075),
          secondaryContainer: Color(0xFF5D009E),
          onSecondaryContainer: Color(0xFFF2D7FF),
          tertiary: Color(0xFFF2D7FF),
          onTertiary: Color(0xFF46007B),
          tertiaryContainer: Color(0xFF6100A7),
          onTertiaryContainer: Color(0xFFF8E7FF),
          error: Color(0xFFFFB4AB),
          onError: Color(0xFF690005),
          surface: Color(0xFF1D1B20),
          onSurface: Color(0xFFE7E0EC),
          surfaceContainerHighest: Color(0xFF49454E),
          onSurfaceVariant: Color(0xFFCAC4D0),
          outline: Color(0xFF948F99),
          outlineVariant: Color(0xFF49454E),
          scrim: Colors.black,
          shadow: Colors.black,
        );
    }
  }
}

// Extended colors for specific UI elements
class ExtendedColors {
  ExtendedColors._();

  // Success colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color successDark = Color(0xFF388E3C);

  // Warning colors
  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFE0B2);
  static const Color warningDark = Color(0xFFF57C00);

  // Info colors
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFBBDEFB);
  static const Color infoDark = Color(0xFF1976D2);

  // Neutral colors
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFEEEEEE);
  static const Color neutral300 = Color(0xFFE0E0E0);
  static const Color neutral400 = Color(0xFFBDBDBD);
  static const Color neutral500 = Color(0xFF9E9E9E);
  static const Color neutral600 = Color(0xFF757575);
  static const Color neutral700 = Color(0xFF616161);
  static const Color neutral800 = Color(0xFF424242);
  static const Color neutral900 = Color(0xFF212121);
}
