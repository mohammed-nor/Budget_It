import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:budget_it/utils/messages.dart';
import 'package:get/get.dart';

// ─── Hive keys (imported in profil.dart too) ────────────────────────────────
const String kNotifEnabled = 'notif_enabled';
const String kNotifDailyEnabled = 'notif_daily_enabled';
const String kNotifDailyHour = 'notif_daily_hour';
const String kNotifDailyMinute = 'notif_daily_minute';
const String kNotifSalaryEnabled = 'notif_salary_enabled';
const String kNotifLowBudgetEnabled = 'notif_low_budget_enabled';
const String kNotifLowBudgetThreshold = 'notif_low_budget_threshold';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ──────────────────────────────────────────────────────────────── init ──
  Future<void> init() async {
    if (_initialized) return;
    if (!_isSupported()) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Windows: v19 uses WindowsInitializationSettings with appName only
    final windowsInit = WindowsInitializationSettings(
      appName: 'Budget It',
      appUserModelId: 'com.norit.budget_it',
      guid: 'd6b68c3e-4d3e-4a3e-8b3e-1e2d3f4a5b6c',
    );

    final initSettings = InitializationSettings(
      android: androidInit,
      windows: Platform.isWindows ? windowsInit : null,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    _initialized = true;
    debugPrint('NotificationService initialized');

    // Request permissions on first init
    await requestPermissions();

    // Create notification channel for Android
    if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          'budget_it_channel',
          'Budget It Alerts',
          description: 'Daily budget reminders and financial alerts',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
    }
  }

  /// Explicitly request notification permissions from the user.
  /// Returns true if granted, false otherwise.
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) return false;

    // Request POST_NOTIFICATIONS (Android 13+)
    final bool? notifGranted = await android.requestNotificationsPermission();

    debugPrint('Permissions - Notif: $notifGranted');
    return (notifGranted ?? false);
  }

  // ──────────────────────────── Build platform-specific details ────────────
  NotificationDetails _buildDetails() {
    const androidDetails = AndroidNotificationDetails(
      'budget_it_channel',
      'Budget It Alerts',
      channelDescription: 'Daily budget reminders and financial alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    final windowsDetails = Platform.isWindows
        ? const WindowsNotificationDetails()
        : null;

    return NotificationDetails(
      android: androidDetails,
      windows: windowsDetails,
    );
  }

  // ────────────────────────────────────────────── show instant notif ────────
  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_isSupported() || !_notificationsEnabled()) return;
    await _plugin.show(id, title, body, _buildDetails(), payload: payload);
  }

  // ─────────────────────────────── schedule daily reminder at set time ──────
  Future<void> scheduleDailyReminder() async {
    if (!_isSupported()) return;
    final box = Hive.box('data');
    if (!(box.get(kNotifEnabled, defaultValue: true) as bool)) return;
    if (!(box.get(kNotifDailyEnabled, defaultValue: true) as bool)) return;

    final hour = box.get(kNotifDailyHour, defaultValue: 9) as int;
    final minute = box.get(kNotifDailyMinute, defaultValue: 0) as int;

    await _plugin.cancel(1);
    // Safety delay to ensure the OS has cleared the previous notification
    await Future.delayed(const Duration(milliseconds: 100));

    await _plugin.zonedSchedule(
      1,
      _tr('daily_reminder_title'),
      _tr('daily_reminder_body'),
      _nextInstanceOfTime(hour, minute),
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_reminder',
    );
    debugPrint('Daily reminder scheduled at $hour:$minute');
  }

  // ──────────────────────────────── schedule salary-day notification ────────
  Future<void> scheduleSalaryDayNotification() async {
    if (!_isSupported()) return;
    final box = Hive.box('data');
    if (!(box.get(kNotifEnabled, defaultValue: true) as bool)) return;
    if (!(box.get(kNotifSalaryEnabled, defaultValue: true) as bool)) return;

    final payDay = box.get('payingDay', defaultValue: 30) as int;
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, payDay, 8, 0);
    if (scheduled.isBefore(now)) {
      scheduled = tz.TZDateTime(
        tz.local,
        now.month < 12 ? now.year : now.year + 1,
        now.month < 12 ? now.month + 1 : 1,
        payDay,
        8,
        0,
      );
    }

    await _plugin.cancel(2);
    await Future.delayed(const Duration(milliseconds: 100));

    await _plugin.zonedSchedule(
      2,
      _tr('salary_day_title'),
      _tr('salary_day_body'),
      scheduled,
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'salary_day',
    );
    debugPrint('Salary day notification scheduled for $scheduled');
  }

  // ─────────────────────────────────────── low-budget instant alert ─────────
  Future<void> checkAndNotifyLowBudget(double currentBalance) async {
    if (!_isSupported()) return;
    final box = Hive.box('data');
    if (!(box.get(kNotifEnabled, defaultValue: true) as bool)) return;
    if (!(box.get(kNotifLowBudgetEnabled, defaultValue: true) as bool)) return;

    final threshold =
        (box.get(kNotifLowBudgetThreshold, defaultValue: 500) as num)
            .toDouble();

    if (currentBalance <= threshold) {
      await showInstant(
        id: 3,
        title: _tr('low_balance_title'),
        body: _tr(
          'low_balance_body',
        ).replaceFirst('%s', currentBalance.toStringAsFixed(0)),
        payload: 'low_budget',
      );
    }
  }

  // ─────────────────────────────────────────────────── cancel helpers ───────
  Future<void> cancelAll() async => _plugin.cancelAll();
  Future<void> cancelDailyReminder() async => _plugin.cancel(1);
  Future<void> cancelSalaryNotification() async => _plugin.cancel(2);

  // ──────────────────────────────────────────────────── reschedule all ──────
  /// Call whenever settings change.
  Future<void> rescheduleAll() async {
    await scheduleDailyReminder();
    await scheduleSalaryDayNotification();
  }

  // ────────────────────────────────────────────────────── private helpers ───
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  bool _isSupported() => !kIsWeb && (Platform.isAndroid || Platform.isWindows);

  bool _notificationsEnabled() {
    final box = Hive.box('data');
    return box.get(kNotifEnabled, defaultValue: true) as bool;
  }

  String _tr(String key) {
    try {
      // 1. Try standard GetX translation
      final res = key.tr;
      if (res != key) return res;

      // 2. Fallback: manual lookup if GetX isn't ready
      final lang = Get.locale?.languageCode ?? 'en';
      final messages = Messages().keys;
      return messages[lang]?[key] ?? messages['en']?[key] ?? key;
    } catch (_) {
      return key;
    }
  }
}
