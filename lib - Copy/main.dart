import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/ColorAdapter.dart';
import 'models/budget_history.dart';
import 'models/upcoming_spending.dart';
import 'models/unexpected_earning.dart';
import 'screens/splash_screen.dart';

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
  await Hive.openBox('budgets');

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: GoogleFonts.latoTextTheme(ThemeData.dark().textTheme),
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: GoogleFonts.latoTextTheme(ThemeData.light().textTheme),
      ),
      themeMode: ThemeMode.dark,
    ),
  );
}
