import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'color_theme.dart';

class ThemeController extends GetxController {
  late Box<dynamic> _prefsBox;

  final Rx<bool> isDarkMode = Rx<bool>(true);
  final Rx<String> accentColorName = Rx<String>('Green');
  final Rx<Color> accentColor = Rx<Color>(ColorTheme.accentColorMap['Green']!);

  @override
  void onInit() {
    super.onInit();
    _prefsBox = Hive.box('data');
    _loadThemeSettings();
  }

  void _loadThemeSettings() {
    isDarkMode.value = _prefsBox.get('thememode', defaultValue: true) as bool;
    accentColorName.value =
        _prefsBox.get('accentcolor', defaultValue: 'Green') as String;
    accentColor.value = ColorTheme.getAccentColor(accentColorName.value);
  }

  void updateThemeMode(bool darkMode) {
    isDarkMode.value = darkMode;
    _prefsBox.put('thememode', darkMode);
    update();
  }

  void updateAccentColor(String colorName) {
    accentColorName.value = colorName;
    accentColor.value = ColorTheme.getAccentColor(colorName);
    _prefsBox.put('accentcolor', colorName);
    update();
  }

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}
