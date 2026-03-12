import 'package:budget_it/models/budget_history.dart';
import 'package:budget_it/models/upcoming_spending.dart';
import 'package:budget_it/models/unexpected_earning.dart';
import 'package:budget_it/services/styles%20and%20constants.dart';
import 'package:budget_it/utils/color_theme.dart';
import 'package:budget_it/utils/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive/hive.dart';

class Profilpage extends StatefulWidget {
  const Profilpage({super.key});

  @override
  State<Profilpage> createState() => _ProfilpageState();
}

class _ProfilpageState extends State<Profilpage> {
  //Color selectedColor = Colors.white; // Default color
  TextStyle themedTextStyle({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
  }) {
    final isDark = themeController.isDarkMode.value;
    return GoogleFonts.elMessiri(
      fontWeight: fontWeight ?? FontWeight.w700,
      fontSize: fontSize ?? fontSize2.toDouble(),
      color:
          color ??
          (isDark ? ColorTheme.darkTextPrimary : ColorTheme.lightTextPrimary),
    );
  }
  //String selectedColorName = 'Light';

  late ThemeController themeController;

  /// Build a stylish dropdown button with modern design
  Widget _buildStyledDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    Widget? leadingIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.07,
          width: MediaQuery.of(context).size.width * 0.4,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(10, 45, 45, 45),
                const Color.fromARGB(125, 35, 35, 35),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ColorTheme.accentGreen.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: DropdownButton<String>(
              value: value,
              alignment: AlignmentDirectional.centerEnd,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: const Color.fromRGBO(25, 25, 25, 1.0),
              style: themedTextStyle(fontSize: fontSize1 * 0.85),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefsdata = Hive.box('data');
    themeController = Get.find<ThemeController>();

    // No need to redefine darktextstyle, use themedTextStyle instead

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(7),
        children: <Widget>[
          Card(
            elevation: 5,
            //margin: const EdgeInsets.all(10),
            color: cardcolor != null ? cardcolor : Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                bottom: 5,
                top: 5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                  Text(
                    "هذا التطبيق تم تطويره من طرف المطور",
                    style: themedTextStyle(
                      fontSize: fontSize1,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  ClipOval(
                    child: Image.asset('images/1.png', width: 200, height: 200),
                  ),

                  //clipBehavior: Clip.hardEdge,clipper: ,
                  const SizedBox(height: 10),
                  const Text(
                    name,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    email,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Define the URL explicitly (it seems 'githubUrl' might be undefined)
                      const String githubUrl =
                          "https://github.com/mohammed-nor";

                      try {
                        Uri url = Uri.parse(githubUrl);
                        // Use external application to open URLs on mobile
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode
                                .externalApplication, // Changed from inAppWebView
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cannot open $githubUrl'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.link),
                    label: const Text("GitHub"),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "هذا التطبيق هدفه مساعدتك على تسيير ماليتك ، دعمك في الادخار و اعطائك فكرة عن تدبيرك المالي ، لكن عليك استحضار التوازن المالي و المنهج الرباني في التدبير من خلال قوله تعالى",
                    style: themedTextStyle(
                      fontSize: fontSize1 - 2,
                      color: Theme.of(context).hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "وَلَا تَجْعَلْ يَدَكَ مَغْلُولَةً إِلَىٰ عُنُقِكَ وَلَا تَبْسُطْهَا كُلَّ ٱلْبَسْطِ فَتَقْعُدَ مَلُومًا مَّحْسُورًا",
                    style: themedTextStyle(
                      fontSize: fontSize1 + 2,
                      color: Colors.green,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "صدق الله العظيم",
                    style: themedTextStyle(
                      fontSize: fontSize1,
                      color: Theme.of(context).hintColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Card(
            elevation: 5,
            //margin: const EdgeInsets.all(10),
            color: cardcolor != null ? cardcolor : Theme.of(context).cardColor,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                bottom: 5,
                top: 5,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "الإعدادات",
                    style: themedTextStyle(),
                    textAlign: TextAlign.right,
                  ),
                  // Theme Mode Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Obx(
                        () => Switch(
                          value: themeController.isDarkMode.value,
                          onChanged: (value) {
                            themeController.updateThemeMode(value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'تم التبديل للوضع الداكن'
                                      : 'تم التبديل للوضع الفاتح',
                                  style: darktextstyle.copyWith(
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                backgroundColor: Colors.blue.shade700,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.grey,
                        ),
                      ),
                      Text(
                        'الوضع الليلي/النهاري',
                        style: themedTextStyle(),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Accent Color Picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: Obx(
                          () => _buildStyledDropdown(
                            value: themeController.accentColorName.value,
                            items: ColorTheme.getAccentColorNames().map((
                              colorName,
                            ) {
                              return DropdownMenuItem(
                                value: colorName,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: ColorTheme.getAccentColor(
                                          colorName,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: ColorTheme.getAccentColor(
                                              colorName,
                                            ).withOpacity(0.5),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      colorName,
                                      style: TextStyle(
                                        fontSize: fontSize1 * 0.85,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                themeController.updateAccentColor(newValue);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'تم تغيير لون التركيز إلى $newValue',
                                      style: themedTextStyle(
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    backgroundColor: Colors.blue.shade700,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                      Text(
                        'لون التركيز',
                        style: themedTextStyle(),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.07,
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: SfSlider(
                          min: 10.0,
                          max: 30.0,
                          interval: 5,
                          stepSize: 0.1,
                          showTicks: true,
                          showLabels: true,
                          enableTooltip: true,
                          thumbIcon: const Icon(
                            Icons.percent_rounded,
                            color: Colors.blue,
                            size: 14.0,
                          ),
                          tooltipShape: const SfPaddleTooltipShape(),
                          value: fontSize1,
                          onChanged: (newValue) {
                            setState(() {
                              fontSize1 = newValue;
                              prefsdata.put("fontsize1", newValue);
                              ChangeNotifier();
                            });
                          },
                        ),
                      ),
                      Text(
                        ' حجم خط المعلومات',
                        style: themedTextStyle(),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.07,
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: SfSlider(
                          min: 10.0,
                          max: 30.0,
                          interval: 5,
                          showTicks: true,
                          showLabels: true,
                          enableTooltip: true,
                          thumbIcon: const Icon(
                            Icons.percent_rounded,
                            color: Colors.blue,
                            size: 14.0,
                          ),
                          tooltipShape: const SfPaddleTooltipShape(),
                          value: fontSize2,
                          onChanged: (newValue) {
                            setState(() {
                              fontSize2 = newValue;
                              prefsdata.put("fontsize2", newValue);
                              ChangeNotifier();
                            });
                          },
                        ),
                      ),
                      Text(
                        'حجم خط الإعدادات',
                        style: themedTextStyle(),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4,
                        child: _buildStyledDropdown(
                          value: selectedColorName,
                          items: colorMap.keys.map((colorName) {
                            return DropdownMenuItem(
                              value: colorName,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 18,
                                    //height: 18,
                                    decoration: BoxDecoration(
                                      color: colorMap[colorName],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white60,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (colorMap[colorName] ??
                                                      Colors.grey)
                                                  .withOpacity(0.4),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    colorName,
                                    style: TextStyle(
                                      fontSize: fontSize1 * 0.85,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedColorName = newValue!;
                              cardcolor = colorMap[newValue]!;
                              prefsdata.put(
                                "cardcolor",
                                colorMap[newValue] as Color,
                              );
                              prefsdata.put("selectedColorName", newValue);
                              ChangeNotifier();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم تغيير لون الخلفية إلى $newValue',
                                    style: themedTextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                                  backgroundColor: Colors.blue.shade700,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            });
                          },
                        ),
                      ),
                      Text(
                        'لون الخلفية',
                        style: themedTextStyle(),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 5,
                    //color: const Color.fromARGB(0, 183, 28, 28),
                    //margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showResetConfirmationDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.delete_forever, size: 24),
                      label: Text(
                        "إعادة ضبط التطبيق",
                        style: themedTextStyle(fontSize: fontSize1),
                      ),
                    ),
                  ),

                  /*Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                                  const SizedBox(width: 8),
                                  Text(
                                    "خطر! حذف جميع البيانات",
                                    style: darktextstyle.copyWith(
                                      fontSize: fontSize1,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),*/
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceBetween,
          backgroundColor: const Color.fromRGBO(30, 30, 30, 1.0),
          title: Text(
            "تأكيد إعادة ضبط التطبيق",
            style: themedTextStyle(
              fontSize: fontSize1 * 1.2,
              color: Colors.red.shade300,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delete_forever, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                "سيتم حذف جميع البيانات المخزنة في التطبيق بما في ذلك",
                style: themedTextStyle(fontSize: fontSize1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "بيانات الميزانية\nالمصاريف القادمة\nالمداخيل غير المتوقعة\nتاريخ الإدخار\nالإعدادات",
                style: themedTextStyle(
                  fontSize: fontSize1 - 2,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "هذا الإجراء لا يمكن التراجع عنه",
                style: themedTextStyle(
                  fontSize: fontSize1,
                  color: Colors.red.shade300,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                "إلغاء",
                style: themedTextStyle(color: Colors.grey[400]),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child: Text(
                "نعم، أعد الضبط",
                style: themedTextStyle(color: Colors.white),
              ),
              onPressed: () async {
                await _resetAllData();
                Navigator.of(context).pop();

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "تمت إعادة ضبط التطبيق بنجاح",
                      style: themedTextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    backgroundColor: Colors.green.shade800,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
            ),
          ],
        );
      },
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
