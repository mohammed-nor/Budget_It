import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'color_theme.dart';

class ThemeController extends GetxController {
  late Box<dynamic> _prefsBox;

  final Rx<bool> isDarkMode = Rx<bool>(true);
  final Rx<String> accentColorName = Rx<String>('Green');
  final Rx<Color> accentColor = Rx<Color>(ColorTheme.accentColorMap['Green']!);
  final Rx<double> fontSize1 = Rx<double>(15.0);

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
    fontSize1.value =
        (_prefsBox.get('fontsize1', defaultValue: 15.0) as num).toDouble();
    
    // Apply theme mode on start
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  void updateThemeMode(bool darkMode) {
    isDarkMode.value = darkMode;
    _prefsBox.put('thememode', darkMode);
    
    // Automatically adjust the card background color to match the theme mode
    if (darkMode) {
      _prefsBox.put('selectedColorName', 'Dark');
      _prefsBox.put('cardcolor', const Color.fromRGBO(14, 14, 14, 0.1843137254901961));
    } else {
      _prefsBox.put('selectedColorName', 'Light');
      _prefsBox.put('cardcolor', const Color.fromRGBO(240, 240, 240, 0.85));
    }
    
    Get.changeThemeMode(darkMode ? ThemeMode.dark : ThemeMode.light);
    update();
  }

  void updateAccentColor(String colorName) {
    accentColorName.value = colorName;
    accentColor.value = ColorTheme.getAccentColor(colorName);
    _prefsBox.put('accentcolor', colorName);
    update();
  }
  
  void updateFontSize(double val) {
    fontSize1.value = val;
    _prefsBox.put('fontsize1', val);
    update();
  }

  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}
