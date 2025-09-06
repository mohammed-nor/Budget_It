import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:budget_it/screens/home.dart';
import 'services/ColorAdapter.dart';
import 'models/budget_history.dart';
import 'models/upcoming_spending.dart';
import 'models/unexpected_earning.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(ColorAdapter());
  Hive.registerAdapter(BudgetHistoryAdapter());
  Hive.registerAdapter(UpcomingSpendingAdapter());
  Hive.registerAdapter(UnexpectedEarningAdapter());

  await Hive.openBox('data');
  await Hive.openBox<BudgetHistory>('budget_history');
  await Hive.openBox<UpcomingSpending>('upcoming_spending');
  await Hive.openBox<UnexpectedEarning>('unexpected_earnings');

  runApp(GetMaterialApp(debugShowCheckedModeBanner: false, home: const Myhome(), darkTheme: ThemeData.dark(), theme: ThemeData.light(), themeMode: ThemeMode.dark));
}
