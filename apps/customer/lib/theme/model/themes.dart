import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lehwipalancecustomerv1/theme/app_colors.dart';
import 'package:lehwipalancecustomerv1/theme/app_constants.dart';
import 'package:lehwipalancecustomerv1/theme/app_text_styles.dart';
import 'package:lehwipalancecustomerv1/theme/model/enum_models.dart';

class AppTheme {
  // Always use blueTealPurple
  static const ColorSchemeType _defaultColorScheme =
      ColorSchemeType.blueTealPurple;

  static ThemeData lightTheme(
    FontFamilyType fontFamily, // REMOVED: colorScheme parameter
  ) {
    final baseColorScheme = ColorSchemes.getLightScheme(_defaultColorScheme);
    final textTheme = _buildTextTheme(fontFamily);

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme,
      fontFamily: fontFamily.googleFontFamilyName,
      scaffoldBackgroundColor: baseColorScheme.surface,
      canvasColor: baseColorScheme.surface,
      cardColor: baseColorScheme.surfaceContainerHighest,
      disabledColor: baseColorScheme.onSurface.withValues(alpha: 38),
      dividerColor: baseColorScheme.outline.withValues(alpha: 12),
      focusColor: baseColorScheme.primary.withValues(alpha: 204),
      highlightColor: baseColorScheme.primary.withValues(alpha: 12),
      hintColor: baseColorScheme.onSurfaceVariant,
      hoverColor: baseColorScheme.onSurface.withValues(alpha: 204),
      primaryColor: baseColorScheme.primary,
      primaryColorDark: baseColorScheme.primary,
      primaryColorLight: baseColorScheme.primaryContainer,
      secondaryHeaderColor: baseColorScheme.secondaryContainer,
      shadowColor: baseColorScheme.shadow.withValues(alpha: 178),
      splashColor: baseColorScheme.primary.withValues(alpha: 30),
      unselectedWidgetColor: baseColorScheme.onSurfaceVariant,

      // Text themes
      textTheme: textTheme,
      primaryTextTheme: textTheme.apply(
        bodyColor: baseColorScheme.onPrimary,
        displayColor: baseColorScheme.onPrimary,
      ),

      // Icon themes
      iconTheme: IconThemeData(
        color: baseColorScheme.onSurfaceVariant,
        size: AppConstants.iconS,
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: baseColorScheme.surface,
        foregroundColor: baseColorScheme.onSurface,
        elevation: AppConstants.elevationS,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        toolbarHeight: 64,
      ),

      // Bottom navigation theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: baseColorScheme.surface,
        selectedItemColor: baseColorScheme.primary,
        unselectedItemColor: baseColorScheme.onSurfaceVariant,
        elevation: AppConstants.elevationM,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: baseColorScheme.surfaceContainerHighest,
        elevation: AppConstants.elevationS,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.marginM,
          vertical: AppConstants.marginS,
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseColorScheme.primary,
          foregroundColor: baseColorScheme.onPrimary,
          disabledBackgroundColor: baseColorScheme.onSurface.withValues(
            alpha: 12,
          ),
          disabledForegroundColor: baseColorScheme.onSurface.withValues(
            alpha: 38,
          ),
          textStyle: AppTextStyles.button(),
          minimumSize: const Size(64, AppConstants.buttonHeightM),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          elevation: AppConstants.elevationM,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: baseColorScheme.primary,
          side: BorderSide(color: baseColorScheme.primary),
          textStyle: AppTextStyles.button(),
          minimumSize: const Size(64, AppConstants.buttonHeightM),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: baseColorScheme.primary,
          textStyle: AppTextStyles.button(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingXS,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseColorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingS,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: baseColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(
            color: baseColorScheme.outline.withValues(alpha: 38),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: baseColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: baseColorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: baseColorScheme.error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: baseColorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: baseColorScheme.onSurfaceVariant,
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: baseColorScheme.surface,
        elevation: AppConstants.elevationXL,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: baseColorScheme.surfaceContainerHighest,
        selectedColor: baseColorScheme.primaryContainer,
        disabledColor: baseColorScheme.onSurface.withValues(alpha: 12),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: baseColorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: baseColorScheme.onSecondaryContainer,
        ),
        brightness: Brightness.light,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingS,
          vertical: AppConstants.space2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
          side: BorderSide(
            color: baseColorScheme.outline.withValues(alpha: 12),
          ),
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: baseColorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: baseColorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        elevation: AppConstants.elevationL,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: baseColorScheme.outline.withValues(alpha: 12),
        thickness: 1,
        space: AppConstants.space4,
      ),
      tabBarTheme: TabBarThemeData(indicatorColor: baseColorScheme.primary),
      // Add to both lightTheme and darkTheme in AppTheme

      // Filled Button Theme (Material 3)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: baseColorScheme.primary,
          foregroundColor: baseColorScheme.onPrimary,
          disabledBackgroundColor: baseColorScheme.onSurface.withValues(
            alpha: 12,
          ),
          disabledForegroundColor: baseColorScheme.onSurface.withValues(
            alpha: 38,
          ),
          textStyle: AppTextStyles.button(),
          minimumSize: const Size(64, AppConstants.buttonHeightM),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
        ),
      ),

      // FAB Theme (Material 3)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: baseColorScheme.primaryContainer,
        foregroundColor: baseColorScheme.onPrimaryContainer,
        elevation: AppConstants.elevationM,
        shape: const CircleBorder(),
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: baseColorScheme.surfaceContainer,
        indicatorColor: baseColorScheme.secondaryContainer,
        elevation: AppConstants.elevationL,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? baseColorScheme.onSurface
                : baseColorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected
                ? baseColorScheme.onSecondaryContainer
                : baseColorScheme.onSurfaceVariant,
            size: AppConstants.iconM,
          );
        }),
      ),

      // Bottom Sheet Theme (Material 3)
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: baseColorScheme.surfaceContainerLow,
        surfaceTintColor: baseColorScheme.surfaceTint,
        modalBackgroundColor: baseColorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXL),
          ),
        ),
        elevation: AppConstants.elevationL,
      ),

      // Popup Menu Theme
      popupMenuTheme: PopupMenuThemeData(
        color: baseColorScheme.surfaceContainer,
        surfaceTintColor: baseColorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        textStyle: textTheme.bodyMedium,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        iconColor: baseColorScheme.onSurfaceVariant,
        textColor: baseColorScheme.onSurface,
        selectedColor: baseColorScheme.primary,
        selectedTileColor: baseColorScheme.primaryContainer.withValues(
          alpha: 0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.space1,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: baseColorScheme.primary,
        linearTrackColor: baseColorScheme.surfaceContainerHighest,
        circularTrackColor: baseColorScheme.surfaceContainerHighest,
      ),

      // Switch Theme (Material 3)
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return baseColorScheme.onPrimary;
          }
          return baseColorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return baseColorScheme.primary;
          }
          return baseColorScheme.surfaceContainerHighest;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return baseColorScheme.primary;
          }
          return null;
        }),
        checkColor: WidgetStatePropertyAll(baseColorScheme.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXS),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return baseColorScheme.primary;
          }
          return baseColorScheme.onSurfaceVariant;
        }),
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: baseColorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: baseColorScheme.onInverseSurface,
        ),
      ),
    );
  }

  static ThemeData darkTheme(
    FontFamilyType fontFamily, // REMOVED: colorScheme parameter
  ) {
    final baseColorScheme = ColorSchemes.getDarkScheme(_defaultColorScheme);
    final textTheme = _buildTextTheme(fontFamily);

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme,
      fontFamily: fontFamily.googleFontFamilyName,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: baseColorScheme.surface,
      canvasColor: baseColorScheme.surface,
      cardColor: baseColorScheme.surfaceContainerHighest,
      disabledColor: baseColorScheme.onSurface.withValues(alpha: 38),
      dividerColor: baseColorScheme.outline.withValues(alpha: 12),
      focusColor: baseColorScheme.primary.withValues(alpha: 12),
      highlightColor: baseColorScheme.primary.withValues(alpha: 12),
      hintColor: baseColorScheme.onSurfaceVariant,
      hoverColor: baseColorScheme.onSurface.withValues(alpha: 8),
      primaryColor: baseColorScheme.primary,
      primaryColorDark: baseColorScheme.primary,
      primaryColorLight: baseColorScheme.primaryContainer,
      secondaryHeaderColor: baseColorScheme.secondaryContainer,
      shadowColor: Colors.black,
      splashColor: baseColorScheme.primary.withValues(alpha: 30),
      unselectedWidgetColor: baseColorScheme.onSurfaceVariant,

      // Text themes
      textTheme: textTheme,
      primaryTextTheme: textTheme.apply(
        bodyColor: baseColorScheme.onPrimary,
        displayColor: baseColorScheme.onPrimary,
      ),

      // Icon themes
      iconTheme: IconThemeData(
        color: baseColorScheme.onSurfaceVariant,
        size: AppConstants.iconS,
      ),

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: baseColorScheme.surface,
        foregroundColor: baseColorScheme.onSurface,
        elevation: AppConstants.elevationS,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        toolbarHeight: 64,
      ),

      // Bottom navigation theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: baseColorScheme.surface,
        selectedItemColor: baseColorScheme.primary,
        unselectedItemColor: baseColorScheme.onSurfaceVariant,
        elevation: AppConstants.elevationM,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: baseColorScheme.surfaceContainerHighest,
        elevation: AppConstants.elevationS,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.marginM,
          vertical: AppConstants.marginS,
        ),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseColorScheme.primary,
          foregroundColor: baseColorScheme.onPrimary,
          disabledBackgroundColor: baseColorScheme.onSurface.withValues(
            alpha: 12,
          ),
          disabledForegroundColor: baseColorScheme.onSurface.withValues(
            alpha: 38,
          ),
          textStyle: AppTextStyles.button(),
          minimumSize: const Size(64, AppConstants.buttonHeightM),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          elevation: AppConstants.elevationM,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: baseColorScheme.primary,
          side: BorderSide(color: baseColorScheme.primary),
          textStyle: AppTextStyles.button(),
          minimumSize: const Size(64, AppConstants.buttonHeightM),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: baseColorScheme.primary,
          textStyle: AppTextStyles.button(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingM,
            vertical: AppConstants.paddingXS,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: baseColorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.paddingS,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: baseColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(
            color: baseColorScheme.outline.withValues(alpha: 38),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: baseColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: baseColorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          borderSide: BorderSide(color: baseColorScheme.error, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: baseColorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: baseColorScheme.onSurfaceVariant,
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: baseColorScheme.surface,
        elevation: AppConstants.elevationXL,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: baseColorScheme.surfaceContainerHighest,
        selectedColor: baseColorScheme.primaryContainer,
        disabledColor: baseColorScheme.onSurface.withValues(alpha: 12),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: baseColorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: baseColorScheme.onSecondaryContainer,
        ),
        brightness: Brightness.dark,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingS,
          vertical: AppConstants.space2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusRound),
          side: BorderSide(
            color: baseColorScheme.outline.withValues(alpha: 12),
          ),
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: baseColorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: baseColorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        elevation: AppConstants.elevationL,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: baseColorScheme.outline.withValues(alpha: 12),
        thickness: 1,
        space: AppConstants.space4,
      ),
      tabBarTheme: TabBarThemeData(indicatorColor: baseColorScheme.primary),
      // Add to both lightTheme and darkTheme in AppTheme

      // Filled Button Theme (Material 3)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: baseColorScheme.primary,
          foregroundColor: baseColorScheme.onPrimary,
          disabledBackgroundColor: baseColorScheme.onSurface.withValues(
            alpha: 12,
          ),
          disabledForegroundColor: baseColorScheme.onSurface.withValues(
            alpha: 38,
          ),
          textStyle: AppTextStyles.button(),
          minimumSize: const Size(64, AppConstants.buttonHeightM),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingL,
            vertical: AppConstants.paddingS,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
        ),
      ),

      // FAB Theme (Material 3)
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: baseColorScheme.primaryContainer,
        foregroundColor: baseColorScheme.onPrimaryContainer,
        elevation: AppConstants.elevationM,
        shape: const CircleBorder(),
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        height: 80,
        backgroundColor: baseColorScheme.surfaceContainer,
        indicatorColor: baseColorScheme.secondaryContainer,
        elevation: AppConstants.elevationL,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? baseColorScheme.onSurface
                : baseColorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected
                ? baseColorScheme.onSecondaryContainer
                : baseColorScheme.onSurfaceVariant,
            size: AppConstants.iconM,
          );
        }),
      ),

      // Bottom Sheet Theme (Material 3)
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: baseColorScheme.surfaceContainerLow,
        surfaceTintColor: baseColorScheme.surfaceTint,
        modalBackgroundColor: baseColorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXL),
          ),
        ),
        elevation: AppConstants.elevationL,
      ),

      // Popup Menu Theme
      popupMenuTheme: PopupMenuThemeData(
        color: baseColorScheme.surfaceContainer,
        surfaceTintColor: baseColorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        textStyle: textTheme.bodyMedium,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        iconColor: baseColorScheme.onSurfaceVariant,
        textColor: baseColorScheme.onSurface,
        selectedColor: baseColorScheme.primary,
        selectedTileColor: baseColorScheme.primaryContainer.withValues(
          alpha: 0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingM,
          vertical: AppConstants.space1,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: baseColorScheme.primary,
        linearTrackColor: baseColorScheme.surfaceContainerHighest,
        circularTrackColor: baseColorScheme.surfaceContainerHighest,
      ),

      // Switch Theme (Material 3)
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return baseColorScheme.onPrimary;
          }
          return baseColorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return baseColorScheme.primary;
          }
          return baseColorScheme.surfaceContainerHighest;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return baseColorScheme.primary;
          }
          return null;
        }),
        checkColor: WidgetStatePropertyAll(baseColorScheme.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusXS),
        ),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return baseColorScheme.primary;
          }
          return baseColorScheme.onSurfaceVariant;
        }),
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: baseColorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusS),
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: baseColorScheme.onInverseSurface,
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(FontFamilyType fontFamily) {
    return TextTheme(
      displayLarge: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 45,
        fontWeight: FontWeight.w400,
        height: 1.16,
      ),
      displaySmall: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.22,
      ),
      headlineLarge: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.29,
      ),
      headlineSmall: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.33,
      ),
      titleLarge: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.27,
      ),
      titleMedium: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      titleSmall: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      bodyLarge: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      ),
      labelLarge: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: GoogleFonts.getFont(
        fontFamily.googleFontFamilyName,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.27,
      ),
    );
  }
}
