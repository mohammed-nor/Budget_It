import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_theme.dart';

class AppTheme {
  /// Build a complete ThemeData based on dark mode and accent color
  static ThemeData buildThemeData({
    required bool isDarkMode,
    required Color accentColor,
    double? headingFontSize,
    double? bodyFontSize,
  }) {
    final colors = ColorTheme.getThemeColors(isDarkMode);
    final isDark = isDarkMode;

    // Base text theme
    final textTheme = isDark
        ? GoogleFonts.latoTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.latoTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,

      // Color scheme
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: accentColor,
        onPrimary: isDark ? Colors.black : Colors.white,
        secondary: accentColor.withOpacity(0.7),
        onSecondary: isDark ? Colors.black : Colors.white,
        error: ColorTheme.errorColor,
        onError: Colors.white,
        surface: colors['card']!,
        onSurface: colors['textPrimary']!,
      ),

      // Scaffold and general backgrounds
      scaffoldBackgroundColor: colors['background']!,
      canvasColor: colors['card']!,

      // Text theme with custom styles
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(
          color: colors['textPrimary'],
          fontSize: headingFontSize ?? 32,
        ),
        displayMedium: textTheme.displayMedium?.copyWith(
          color: colors['textPrimary'],
          fontSize: headingFontSize ?? 28,
        ),
        displaySmall: textTheme.displaySmall?.copyWith(
          color: colors['textPrimary'],
          fontSize: headingFontSize ?? 24,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          color: colors['textPrimary'],
          fontSize: headingFontSize ?? 20,
        ),
        headlineSmall: textTheme.headlineSmall?.copyWith(
          color: colors['textPrimary'],
          fontSize: headingFontSize ?? 18,
        ),
        titleLarge: textTheme.titleLarge?.copyWith(
          color: colors['textPrimary'],
          fontSize: headingFontSize ?? 16,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: colors['textPrimary'],
          fontSize: bodyFontSize ?? 14,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          color: colors['textPrimary'],
          fontSize: bodyFontSize ?? 12,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: colors['textPrimary'],
          fontSize: bodyFontSize ?? 14,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: colors['textSecondary'],
          fontSize: bodyFontSize ?? 13,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: colors['textSecondary'],
          fontSize: bodyFontSize ?? 12,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          color: accentColor,
          fontSize: bodyFontSize ?? 12,
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colors['card']!,
        foregroundColor: colors['textPrimary']!,
        elevation: 2,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors['textPrimary']!,
          fontSize: headingFontSize ?? 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors['input']!,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ColorTheme.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ColorTheme.errorColor, width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colors['textSecondary'],
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colors['textSecondary']!.withOpacity(0.6),
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: colors['card']!,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 4,
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentColor,
          side: BorderSide(color: accentColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors['card']!,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors['textPrimary']!,
          fontSize: headingFontSize ?? 18,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors['textPrimary']!,
          fontSize: bodyFontSize ?? 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors['card']!,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 4,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return colors['textSecondary']!.withOpacity(0.5);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor.withOpacity(0.5);
          }
          return colors['textSecondary']!.withOpacity(0.2);
        }),
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: accentColor.withOpacity(0.2),
        thumbColor: accentColor,
        overlayColor: accentColor.withOpacity(0.2),
        valueIndicatorColor: accentColor,
        valueIndicatorTextStyle: textTheme.bodySmall?.copyWith(
          color: isDark ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}
