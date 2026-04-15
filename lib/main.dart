import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/ColorAdapter.dart';
import 'models/budget_history.dart';
import 'models/upcoming_spending.dart';
import 'models/unexpected_earning.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';
import 'utils/theme_controller.dart';
import 'services/notification_service.dart';

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

  // Initialize ThemeController
  Get.put(ThemeController());

  // Initialize notifications
  await NotificationService.instance.init();
  await NotificationService.instance.rescheduleAll();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return Obx(
          () => GetMaterialApp(
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
            theme: AppTheme.buildThemeData(
              isDarkMode: false,
              accentColor: themeController.accentColor.value,
            ),
            darkTheme: AppTheme.buildThemeData(
              isDarkMode: true,
              accentColor: themeController.accentColor.value,
            ),
            themeMode: themeController.themeMode,
          ),
        );
      },
    );
  }
}
