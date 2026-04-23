import 'package:budget_it/models/budget_history.dart';
import 'package:budget_it/models/upcoming_spending.dart';
import 'package:budget_it/models/unexpected_earning.dart';
import 'package:budget_it/services/styles%20and%20constants.dart';
import 'package:budget_it/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';
import 'package:budget_it/utils/language_controller.dart';
import 'package:get/get.dart';
import 'dart:io';

class Profilpage extends StatefulWidget {
  const Profilpage({super.key});

  @override
  State<Profilpage> createState() => _ProfilpageState();
}

class _ProfilpageState extends State<Profilpage> {
  //Color selectedColor = Colors.white; // Default color
  TextStyle darkteststyle2 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: fontSize1,
    color: Colors.white,
  );

  TextStyle darktextstyle = GoogleFonts.elMessiri(
    fontWeight: FontWeight.w700,
    fontSize: fontSize2.toDouble(),
    color: Colors.white,
  );
  //String selectedColorName = 'Light';

  // ── Notification state ─────────────────────────
  late bool _notifEnabled;
  late bool _notifDailyEnabled;
  late int _notifDailyHour;
  late int _notifDailyMinute;
  late bool _notifSalaryEnabled;
  late bool _notifLowBudgetEnabled;
  late double _notifLowBudgetThreshold;

  bool get _notifSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isWindows);

  @override
  void initState() {
    super.initState();
    final box = Hive.box('data');
    _notifEnabled = box.get(kNotifEnabled, defaultValue: true) as bool;
    _notifDailyEnabled =
        box.get(kNotifDailyEnabled, defaultValue: true) as bool;
    _notifDailyHour = box.get(kNotifDailyHour, defaultValue: 9) as int;
    _notifDailyMinute = box.get(kNotifDailyMinute, defaultValue: 0) as int;
    _notifSalaryEnabled =
        box.get(kNotifSalaryEnabled, defaultValue: true) as bool;
    _notifLowBudgetEnabled =
        box.get(kNotifLowBudgetEnabled, defaultValue: true) as bool;
    _notifLowBudgetThreshold =
        (box.get(kNotifLowBudgetThreshold, defaultValue: 500) as num)
            .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final prefsdata = Hive.box('data');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).colorScheme.primary;

    TextStyle titleStyle = GoogleFonts.elMessiri(
      fontWeight: FontWeight.bold,
      fontSize: fontSize2.toDouble() + 4,
      color: Colors.white,
    );

    TextStyle bodyStyle = GoogleFonts.elMessiri(
      fontWeight: FontWeight.w500,
      fontSize: fontSize1,
      color: Colors.white70,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 20.0),
        children: [
          _buildSectionCard(
            context,
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.35),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'images/1.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person,
                        size: 90,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(name, style: titleStyle),
                Text(
                  email,
                  style: bodyStyle.copyWith(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
                const Divider(height: 32, color: Colors.white10),
                Text(
                  "developed_by".tr,
                  style: bodyStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildSettingsAction(
                  context,
                  label: "github_profile_btn".tr,
                  icon: Icons.link,
                  onTap: () async {
                    const String githubUrl = "https://github.com/mohammed-nor";
                    try {
                      Uri url = Uri.parse(githubUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    } catch (e) {
                      debugPrint("Error launching URL: $e");
                    }
                  },
                  color: accentColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            padding: EdgeInsets.all(6),
            title: "management_approach".tr,
            icon: Icons.auto_awesome,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    "quran_verse".tr,
                    style: bodyStyle.copyWith(
                      fontSize: fontSize1 + 2,
                      color: Colors.green.shade400,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text("quran_truth".tr, style: bodyStyle.copyWith(fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            padding: EdgeInsets.all(6),
            child: Column(
              children: [
                _buildLanguageSwitch(context),
                const Divider(height: 1, color: Colors.white10),
                _buildThemeSwitch(context, prefsdata),
                const Divider(height: 1, color: Colors.white10),
                _buildFontSizeSlider(
                  context,
                  label: "info_font_size".tr,
                  value: fontSize1,
                  onChanged: (val) {
                    setState(() {
                      fontSize1 = val;
                      prefsdata.put("fontsize1", val);
                    });
                  },
                ),
                const Divider(height: 1, color: Colors.white10),
                _buildFontSizeSlider(
                  context,
                  label: "settings_font_size".tr,
                  value: fontSize2,
                  onChanged: (val) {
                    setState(() {
                      fontSize2 = val;
                      prefsdata.put("fontsize2", val);
                    });
                  },
                ),
                const Divider(height: 1, color: Colors.white10),
                _buildPayingDayPicker(context, prefsdata),
                const Divider(height: 1, color: Colors.white10),
                _buildCurrencyPicker(context),
              ],
            ),
          ),
          if (_notifSupported) ...[
            const SizedBox(height: 16),
            _buildNotificationSettings(context, prefsdata),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showResetConfirmationDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.1),
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.withOpacity(0.5)),
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.delete_forever),
            label: Text(
              "reset_app".tr,
              style: bodyStyle.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required Widget child,
    String? title,
    IconData? icon,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardcolor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.elMessiri(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsAction(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeSlider(
    BuildContext context, {
    required String label,
    required double value,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.elMessiri(color: Colors.white70, fontSize: 14),
          ),
          SfSlider(
            min: 10.0,
            max: 30.0,
            interval: 5,
            showTicks: true,
            showLabels: true,
            enableTooltip: true,
            value: value,
            onChanged: (newValue) => onChanged(newValue as double),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSwitch(BuildContext context, Box prefsdata) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        "background_color".tr,
        textAlign: Get.locale?.languageCode == 'ar'
            ? TextAlign.right
            : TextAlign.left,
        style: GoogleFonts.elMessiri(color: Colors.white70),
      ),
      leading: Icon(Icons.palette_outlined, color: Colors.blue.shade300),
      trailing: _buildColorDropdown(prefsdata),
      subtitle: Get.locale?.languageCode == 'en' ? null : null, // Keep it clean
    );
  }

  Widget _buildColorDropdown(Box prefsdata) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: selectedColorName,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF1A1A1A),
        items: colorMap.keys.map((name) {
          return DropdownMenuItem(
            value: name,
            child: Text(name, style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() {
              selectedColorName = val;
              cardcolor = colorMap[val]!;
              prefsdata.put("cardcolor", cardcolor);
              prefsdata.put("selectedColorName", val);
            });
          }
        },
      ),
    );
  }

  Widget _buildLanguageSwitch(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        "lang".tr,
        textAlign: Get.locale?.languageCode == 'ar'
            ? TextAlign.right
            : TextAlign.left,
        style: GoogleFonts.elMessiri(color: Colors.white70),
      ),
      trailing: _buildLanguageDropdown(languageController),
      leading: Icon(Icons.language, color: Colors.purple.shade300),
    );
  }

  Widget _buildLanguageDropdown(LanguageController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: controller.language.value,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF1A1A1A),
        items: [
          DropdownMenuItem(
            value: 'ar',
            child: Text(
              "arabic".tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          DropdownMenuItem(
            value: 'en',
            child: Text(
              "english".tr,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
        onChanged: (val) {
          if (val != null) {
            controller.changeLanguage(val);
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildPayingDayPicker(BuildContext context, Box prefsdata) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        "paying_day".tr,
        textAlign: Get.locale?.languageCode == 'ar'
            ? TextAlign.right
            : TextAlign.left,
        style: GoogleFonts.elMessiri(color: Colors.white70),
      ),
      leading: Icon(
        Icons.calendar_month_outlined,
        color: Colors.green.shade300,
      ),
      trailing: _buildPayingDayDropdown(prefsdata),
    );
  }

  Widget _buildPayingDayDropdown(Box prefsdata) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<int>(
        value: prefsdata.get("payingDay", defaultValue: 30),
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF1A1A1A),
        items: List.generate(31, (index) => index + 1).map((val) {
          return DropdownMenuItem(
            value: val,
            child: Text(
              val.toString(),
              style: const TextStyle(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: (val) {
          if (val != null) {
            setState(() {
              prefsdata.put("payingDay", val);
              NotificationService.instance.rescheduleAll();
            });
          }
        },
      ),
    );
  }

  Widget _buildCurrencyPicker(BuildContext context) {
    final controller = Get.find<LanguageController>();
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        "select_currency".tr,
        textAlign: Get.locale?.languageCode == 'ar'
            ? TextAlign.right
            : TextAlign.left,
        style: GoogleFonts.elMessiri(color: Colors.white70),
      ),
      leading: Icon(
        Icons.monetization_on_outlined,
        color: Colors.amber.shade300,
      ),
      trailing: _buildCurrencyDropdown(controller),
    );
  }

  Widget _buildCurrencyDropdown(LanguageController controller) {
    final currencies = ['DH', 'USD', 'EUR', 'SAR', 'AED', 'GBP', 'KWD', 'DZD'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Obx(
        () => DropdownButton<String>(
          value: controller.currency.value,
          underline: const SizedBox(),
          dropdownColor: const Color(0xFF1A1A1A),
          items: currencies.map((val) {
            return DropdownMenuItem(
              value: val,
              child: Text(val, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              controller.changeCurrency(val);
              setState(() {});
            }
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  NOTIFICATION SETTINGS CARD
  // ══════════════════════════════════════════════════════════════
  Widget _buildNotificationSettings(BuildContext context, Box prefsdata) {
    final accentColor = Theme.of(context).colorScheme.primary;

    void save(String key, dynamic value) {
      prefsdata.put(key, value);
      NotificationService.instance.rescheduleAll();
    }

    return _buildSectionCard(
      context,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      title: "notifications".tr,
      icon: Icons.notifications_active_outlined,
      child: Column(
        children: [
          // ── Master toggle ─────────────────────────────────────
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _notifEnabled,
            activeThumbColor: accentColor,
            title: Text(
              "enable_notifications".tr,
              textAlign: Get.locale?.languageCode == 'ar'
                  ? TextAlign.right
                  : TextAlign.left,
              style: GoogleFonts.elMessiri(
                color: Colors.white,
                fontSize: fontSize1,
              ),
            ),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.notifications_rounded,
                color: accentColor,
                size: 20,
              ),
            ),
            onChanged: (val) async {
              if (val) {
                // When enabling, explicitly ask for OS permission
                final granted = await NotificationService.instance
                    .requestPermissions();
                if (!granted && mounted) {
                  // If denied, tell the user they need to enable it in system settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'notif_permission_msg'.tr,
                        style: GoogleFonts.elMessiri(),
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
              setState(() => _notifEnabled = val);
              save(kNotifEnabled, val);
              if (!val) NotificationService.instance.cancelAll();
            },
          ),

          if (_notifEnabled) ...[
            const Divider(height: 20, color: Colors.white10),

            // ── Daily reminder ───────────────────────────────────
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _notifDailyEnabled,
              activeThumbColor: accentColor,
              title: Text(
                "daily_budget_reminder".tr,
                textAlign: Get.locale?.languageCode == 'ar'
                    ? TextAlign.right
                    : TextAlign.left,
                style: GoogleFonts.elMessiri(
                  color: Colors.white70,
                  fontSize: fontSize1 - 1,
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.alarm_outlined,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              onChanged: (val) {
                setState(() => _notifDailyEnabled = val);
                save(kNotifDailyEnabled, val);
                if (!val) NotificationService.instance.cancelDailyReminder();
              },
            ),

            if (_notifDailyEnabled) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: GestureDetector(
                  onTap: () => _pickDailyTime(context, prefsdata),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${'reminder_time'.tr}: ${_notifDailyHour.toString().padLeft(2, '0')}:${_notifDailyMinute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.elMessiri(
                            color: Colors.orange.shade300,
                            fontSize: fontSize1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Icon(
                          Icons.access_time_rounded,
                          color: Colors.orange.shade300,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const Divider(height: 20, color: Colors.white10),

            // ── Salary day ───────────────────────────────────────
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _notifSalaryEnabled,
              activeThumbColor: accentColor,
              title: Text(
                "salary_day_alert".tr,
                textAlign: Get.locale?.languageCode == 'ar'
                    ? TextAlign.right
                    : TextAlign.left,
                style: GoogleFonts.elMessiri(
                  color: Colors.white70,
                  fontSize: fontSize1 - 1,
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              onChanged: (val) {
                setState(() => _notifSalaryEnabled = val);
                save(kNotifSalaryEnabled, val);
                if (!val) {
                  NotificationService.instance.cancelSalaryNotification();
                }
              },
            ),

            const Divider(height: 20, color: Colors.white10),

            // ── Low balance alert ────────────────────────────────
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _notifLowBudgetEnabled,
              activeThumbColor: accentColor,
              title: Text(
                "low_balance_alert".tr,
                textAlign: Get.locale?.languageCode == 'ar'
                    ? TextAlign.right
                    : TextAlign.left,
                style: GoogleFonts.elMessiri(
                  color: Colors.white70,
                  fontSize: fontSize1 - 1,
                ),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
              onChanged: (val) {
                setState(() => _notifLowBudgetEnabled = val);
                save(kNotifLowBudgetEnabled, val);
              },
            ),

            if (_notifLowBudgetEnabled) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${'alert_threshold'.tr}: ${_notifLowBudgetThreshold.toStringAsFixed(0)} ${LanguageController.to.currency.value}',
                      style: GoogleFonts.elMessiri(
                        color: Colors.redAccent,
                        fontSize: fontSize1 - 1,
                      ),
                    ),
                    Slider(
                      value: _notifLowBudgetThreshold,
                      min: 100,
                      max: 5000,
                      divisions: 49,
                      activeColor: Colors.redAccent,
                      inactiveColor: Colors.red.withValues(alpha: 0.2),
                      label: _notifLowBudgetThreshold.toStringAsFixed(0),
                      onChanged: (val) {
                        setState(() => _notifLowBudgetThreshold = val);
                      },
                      onChangeEnd: (val) {
                        save(kNotifLowBudgetThreshold, val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _pickDailyTime(BuildContext context, Box prefsdata) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _notifDailyHour, minute: _notifDailyMinute),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(
            ctx,
          ).colorScheme.copyWith(primary: Theme.of(ctx).colorScheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _notifDailyHour = picked.hour;
        _notifDailyMinute = picked.minute;
      });
      prefsdata.put(kNotifDailyHour, picked.hour);
      prefsdata.put(kNotifDailyMinute, picked.minute);
      await NotificationService.instance.scheduleDailyReminder();
    }
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "reset_confirmation_title".tr,
          style: GoogleFonts.elMessiri(
            color: Colors.red.shade300,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              "reset_confirmation_msg".tr,
              style: GoogleFonts.elMessiri(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "cancel".tr,
              style: GoogleFonts.elMessiri(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              await _resetAllData();
              nav.pop();
              messenger.showSnackBar(
                SnackBar(content: Text("reset_success".tr)),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              "yes_reset".tr,
              style: GoogleFonts.elMessiri(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllData() async {
    // Get all Hive boxes
    final prefsdata = Hive.box('data');
    final historyBox = await Hive.openBox<BudgetHistory>('budget_history');
    final upcomingSpendingBox = await Hive.openBox<UpcomingSpending>(
      'upcoming_spending',
    );
    final unexpectedEarningsBox = await Hive.openBox<UnexpectedEarning>(
      'unexpected_earnings',
    );

    // Clear all boxes
    await prefsdata.clear();
    await historyBox.clear();
    await upcomingSpendingBox.clear();
    await unexpectedEarningsBox.clear();

    // Reset settings to defaults
    setState(() {
      fontSize1 = 15.0;
      fontSize2 = 15.0;
      selectedColorName = 'Dark';
      cardcolor = colorMap[selectedColorName]!;

      // Save default values
      prefsdata.put("fontsize1", fontSize1);
      prefsdata.put("fontsize2", fontSize2);
      prefsdata.put("selectedColorName", selectedColorName);
      prefsdata.put("cardcolor", cardcolor);

      // Reset other variables to default
      prefsdata.put("totsaving", 50000);
      prefsdata.put("nownetcredit", 2000);
      prefsdata.put("nowcredit", 2000);
      prefsdata.put("mntsaving", 1000);
      prefsdata.put("freemnt", 2);
      prefsdata.put("mntexp", 2000);
      prefsdata.put("annexp", 7000);
      prefsdata.put("mntperexp", 15);
      prefsdata.put("mntinc", 4300);
      prefsdata.put("mntnstblinc", 2000);
      prefsdata.put("mntperinc", 40);
      prefsdata.put(
        "startDate",
        DateTime(DateTime.now().year, DateTime.now().month, 1),
      );
    });
  }
}
