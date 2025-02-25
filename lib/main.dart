import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:budget_it/screens/home.dart';
import 'package:get_storage/get_storage.dart';

import 'services/ColorAdapter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Hive.initFlutter();
  Hive.registerAdapter(ColorAdapter());

  await Hive.openBox('data');

  runApp(GetMaterialApp(debugShowCheckedModeBanner: false, home: const Myhome(), darkTheme: ThemeData.dark(), theme: ThemeData.light(), themeMode: ThemeMode.dark));
}
