//import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:budget_calculator/myhome.dart';
//import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Hive.initFlutter();
  await Hive.openBox('data');

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Myhome(),
      darkTheme: ThemeData.dark(),
      theme: ThemeData.light(),
      themeMode: ThemeMode.dark,
    ),
  );
}
