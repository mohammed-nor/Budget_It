import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class LanguageController extends GetxController {
  static LanguageController get to => Get.find<LanguageController>();
  late Box _prefsBox;
  
  final Rx<String> language = 'ar'.obs; // Default to Arabic
  final Rx<String> currency = 'DH'.obs; // Default to DH

  @override
  void onInit() {
    super.onInit();
    _prefsBox = Hive.box('data');
    _loadLanguage();
    _loadCurrency();
  }

  void _loadLanguage() {
    String? storedLang = _prefsBox.get('language');
    if (storedLang != null) {
      language.value = storedLang;
    }
  }

  void _loadCurrency() {
    String? storedCurrency = _prefsBox.get('currency');
    if (storedCurrency != null) {
      currency.value = storedCurrency;
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

  void changeCurrency(String currencySymbol) {
    if (currency.value == currencySymbol) return;
    
    currency.value = currencySymbol;
    _prefsBox.put('currency', currencySymbol);
    update();
  }

  Locale get getLocale => Locale(language.value);
}
