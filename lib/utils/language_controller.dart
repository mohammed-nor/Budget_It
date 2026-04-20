import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class LanguageController extends GetxController {
  late Box _prefsBox;
  
  final Rx<String> language = 'ar'.obs; // Default to Arabic

  @override
  void onInit() {
    super.onInit();
    _prefsBox = Hive.box('data');
    _loadLanguage();
  }

  void _loadLanguage() {
    String? storedLang = _prefsBox.get('language');
    if (storedLang != null) {
      language.value = storedLang;
      // GetX will handle update in main.dart if we set it there too
    }
  }

  void changeLanguage(String langCode) {
    if (language.value == langCode) return;
    
    language.value = langCode;
    _prefsBox.put('language', langCode);
    
    Locale locale = Locale(langCode);
    Get.updateLocale(locale);
    update();
  }

  Locale get getLocale => Locale(language.value);
}
