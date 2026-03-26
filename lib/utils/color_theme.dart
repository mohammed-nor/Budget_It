import 'package:flutter/material.dart';

class ColorTheme {
  // Primary colors for light and dark themes
  static const Color darkBackground = Color.fromRGBO(20, 20, 20, 1.0);
  static const Color darkCardBackground = Color.fromRGBO(30, 30, 30, 1.0);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color.fromRGBO(189, 189, 189, 1.0);

  static const Color lightBackground = Color.fromRGBO(245, 245, 245, 1.0);
  static const Color lightCardBackground = Colors.white;
  static const Color lightTextPrimary = Color.fromRGBO(33, 33, 33, 1.0);
  static const Color lightTextSecondary = Color.fromRGBO(102, 102, 102, 1.0);

  // Accent green (used for progress bars, highlights, interactive elements)
  static const Color accentGreen = Color.fromRGBO(106, 253, 95, 1.0);
  static const Color accentGreenLight = Color.fromRGBO(165, 255, 155, 1.0);
  static const Color accentGreenDark = Color.fromRGBO(76, 200, 65, 1.0);

  // Status colors
  static const Color successColor = Color.fromRGBO(76, 200, 65, 1.0);
  static const Color errorColor = Color.fromRGBO(229, 95, 95, 1.0);
  static const Color warningColor = Color.fromRGBO(255, 180, 0, 1.0);
  static const Color infoColor = Color.fromRGBO(97, 134, 255, 1.0);

  // Card background color presets
  static final Map<String, Color> cardColorMap = {
    'Red': const Color.fromRGBO(255, 0, 0, 0.1843137254901961),
    'Green': const Color.fromRGBO(0, 46, 2, 1.0),
    'Blue': const Color.fromRGBO(97, 134, 255, 0.1843137254901961),
    'Dark': const Color.fromRGBO(14, 14, 14, 0.1843137254901961),
    'Light': const Color.fromRGBO(157, 157, 157, 1.0),
    'Yellow': const Color.fromRGBO(255, 255, 0, 0.1843137254901961),
    'Purple': const Color.fromRGBO(255, 0, 255, 0.1843137254901961),
  };

  // Accent color presets
  static final Map<String, Color> accentColorMap = {
    'Green': const Color.fromRGBO(106, 253, 95, 1.0),
    'Blue': const Color.fromRGBO(97, 134, 255, 1.0),
    'Purple': const Color.fromRGBO(186, 85, 211, 1.0),
    'Pink': const Color.fromRGBO(255, 105, 180, 1.0),
    'Cyan': const Color.fromRGBO(0, 206, 209, 1.0),
    'Orange': const Color.fromRGBO(255, 140, 0, 1.0),
  };

  /// Get colors based on theme mode
  static Map<String, Color> getThemeColors(bool isDarkMode) {
    return {
      'background': isDarkMode ? darkBackground : lightBackground,
      'card': isDarkMode ? darkCardBackground : lightCardBackground,
      'textPrimary': isDarkMode ? darkTextPrimary : lightTextPrimary,
      'textSecondary': isDarkMode ? darkTextSecondary : lightTextSecondary,
      'input': isDarkMode
          ? const Color.fromRGBO(25, 25, 25, 1.0)
          : const Color.fromRGBO(240, 240, 240, 1.0),
    };
  }

  /// Get card background color with fallback to Dark theme
  static Color getCardColor(String? colorName) {
    return cardColorMap[colorName] ?? cardColorMap['Dark']!;
  }

  /// Get accent color with fallback to Green
  static Color getAccentColor(String? colorName) {
    return accentColorMap[colorName] ?? accentColorMap['Green']!;
  }

  /// Get all card color names
  static List<String> getCardColorNames() => cardColorMap.keys.toList();

  /// Get all accent color names
  static List<String> getAccentColorNames() => accentColorMap.keys.toList();
}
