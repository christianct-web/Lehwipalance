import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:lehwipalancecustomerv1/core/base/service_locator.dart';
import 'package:lehwipalancecustomerv1/theme/app_colors.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/model/enum_models.dart';
import 'package:lehwipalancecustomerv1/theme/model/themes.dart';
import 'package:lehwipalancecustomerv1/theme/shared_preferences_keys.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferencesService _sharedPrefs =
      GetIt.I<SharedPreferencesService>();

  ThemeModeType _themeModeType = ThemeModeType.system;
  FontFamilyType _fontFamilyType = FontFamilyType.montserrat;
  // REMOVED: _colorSchemeType - always use blueTealPurple
  Locale _locale = const Locale('en', 'US');

  // ---------------------------------------------------------------------------
  // PUBLIC READ-ONLY GETTERS
  // ---------------------------------------------------------------------------

  ThemeModeType get themeModeType => _themeModeType;
  FontFamilyType get fontFamilyType => _fontFamilyType;
  // REMOVED: colorSchemeType getter
  Locale get locale => _locale;

  ThemeMode get themeMode {
    switch (_themeModeType) {
      case ThemeModeType.light:
        return ThemeMode.light;
      case ThemeModeType.dark:
        return ThemeMode.dark;
      case ThemeModeType.system:
        return ThemeMode.system;
    }
  }

  late final ValueNotifier<bool> _isDarkModeNotifier;

  ValueNotifier<bool> get isDarkModeNotifier => _isDarkModeNotifier;

  bool get isDarkMode {
    if (_themeModeType == ThemeModeType.light) return false;
    if (_themeModeType == ThemeModeType.dark) return true;

    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  ThemeData get currentTheme => isDarkMode
      ? AppTheme.darkTheme(_fontFamilyType) // REMOVED: colorScheme parameter
      : AppTheme.lightTheme(_fontFamilyType); // REMOVED: colorScheme parameter

  ColorScheme get colorScheme => isDarkMode
      ? ColorSchemes.getDarkScheme(
          ColorSchemeType.blueTealPurple,
        ) // Always use blueTealPurple
      : ColorSchemes.getLightScheme(
          ColorSchemeType.blueTealPurple,
        ); // Always use blueTealPurple

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  ThemeProvider() {
    _isDarkModeNotifier = ValueNotifier(false);
    _loadPreferences();

    // Listen to system brightness changes (ONLY when system mode is active)
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
          if (_themeModeType == ThemeModeType.system) {
            _syncDarkMode();
            _updateSystemUI();
            notifyListeners();
          }
        };
  }

  // ---------------------------------------------------------------------------
  // LOAD PREFERENCES
  // ---------------------------------------------------------------------------

  Future<void> _loadPreferences() async {
    _themeModeType = await _sharedPrefs.getThemeMode();
    _fontFamilyType = await _sharedPrefs.getFontFamily();
    // REMOVED: _colorSchemeType loading

    final localeString = await _sharedPrefs.getLocale();
    if (localeString != null) {
      final parts = localeString.split('_');
      _locale = parts.length == 2
          ? Locale(parts[0], parts[1])
          : Locale(parts[0]);
    }

    _syncDarkMode();
    _updateSystemUI();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // SETTERS (SAFE EXTENSIONS)
  // ---------------------------------------------------------------------------
  Future<void> setFontFamily(FontFamilyType font) async {
    if (_fontFamilyType == font) return;

    _fontFamilyType = font;
    await _sharedPrefs.setFontFamily(font);

    // Force rebuild the entire app with new font
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeModeType mode) async {
    if (_themeModeType == mode) return;

    _themeModeType = mode;
    await _sharedPrefs.setThemeMode(mode);

    _syncDarkMode();
    _updateSystemUI();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    if (_themeModeType == ThemeModeType.light) {
      await setThemeMode(ThemeModeType.dark);
    } else if (_themeModeType == ThemeModeType.dark) {
      await setThemeMode(ThemeModeType.system);
    } else {
      await setThemeMode(ThemeModeType.light);
    }
  }

  // REMOVED: setColorScheme method - no longer needed

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    await _sharedPrefs.setLocale(
      locale.countryCode == null
          ? locale.languageCode
          : '${locale.languageCode}_${locale.countryCode}',
    );

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // INTERNAL HELPERS
  // ---------------------------------------------------------------------------

  void _syncDarkMode() {
    _isDarkModeNotifier.value = isDarkMode;
  }

  void _updateSystemUI() {
    final style = isDarkMode
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    SystemChrome.setSystemUIOverlayStyle(
      style.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: colorScheme.surface,
      ),
    );
  }
}

extension ThemeContextExtension on BuildContext {
  ThemeProvider get themeProvider => getIt<ThemeProvider>();
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
  bool get isDark => themeProvider.isDarkMode;
}

extension BuildContextSnackBar on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    final colorScheme = Theme.of(this).colorScheme;
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? colorScheme.errorContainer
              : colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
          ),
        ),
      );
  }
}
