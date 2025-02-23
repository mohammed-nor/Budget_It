import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:budget_it/myhome.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Hive.initFlutter();
  await Hive.openBox('data');

  runApp(GetMaterialApp(debugShowCheckedModeBanner: false, home: const Myhome(), darkTheme: ThemeData.dark(), theme: ThemeData.light(), themeMode: ThemeMode.dark));
}
