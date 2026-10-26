import 'package:lehwipalancecustomerv1/theme/model/enum_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

// shared_preferences_service.dart
class SharedPreferencesService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme Mode
  Future<ThemeModeType> getThemeMode() async {
    final index = _prefs.getInt('theme_mode') ?? 0;
    return ThemeModeType.values[index];
  }

  Future<void> setThemeMode(ThemeModeType mode) async {
    await _prefs.setInt('theme_mode', mode.index);
  }

  // Font Family
  Future<FontFamilyType> getFontFamily() async {
    final index = _prefs.getInt('font_family') ?? 0;
    return FontFamilyType.values[index];
  }

  Future<void> setFontFamily(FontFamilyType font) async {
    await _prefs.setInt('font_family', font.index);
  }

  // Color Scheme
  Future<ColorSchemeType> getColorScheme() async {
    final index = _prefs.getInt('color_scheme') ?? 0;
    return ColorSchemeType.values[index];
  }

  Future<void> setColorScheme(ColorSchemeType scheme) async {
    await _prefs.setInt('color_scheme', scheme.index);
  }

  // Locale
  Future<String?> getLocale() async {
    return _prefs.getString('locale');
  }

  Future<void> setLocale(String locale) async {
    await _prefs.setString('locale', locale);
  }

  // User preferences
  Future<void> setUserId(String userId) async {
    await _prefs.setString('user_id', userId);
  }

  Future<String?> getUserId() async {
    return _prefs.getString('user_id');
  }

  // Clear all preferences
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
