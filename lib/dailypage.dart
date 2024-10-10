import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:budget_calculator/styles.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hijri/hijri_calendar.dart';

class Dailypage extends StatefulWidget {
  const Dailypage({
    super.key,
  });

  @override
  State<Dailypage> createState() => _DailypageState();
}

void initState() {}

class ValueDataSource extends CalendarDataSource {
  ValueDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class _DailypageState extends State<Dailypage> {
  //final box = GetStorage();

  final prefsdata = Hive.box('data');
  DateTime today = DateTime.now();
  late DateTime targetDate;

  @override
  Widget build(BuildContext context) {
    if (today.day == 30) {
      int nextMonth = today.month == 12 ? 1 : today.month + 1;
      int nextYear = today.month == 12 ? today.year + 1 : today.year;
      targetDate = DateTime(nextYear, nextMonth, 30);
    } else {
      targetDate = DateTime(today.year, today.month, 30);
    }
    int daysDifference = targetDate.difference(today).inDays;
    final size = MediaQuery.of(context).size;
    num totsaving = prefsdata.get("totsaving", defaultValue: 50000);
    num nownetcredit = prefsdata.get("nownetcredit", defaultValue: 2000);
    num mntsaving = prefsdata.get("mntsaving", defaultValue: 1000);
    num freemnt = prefsdata.get("freemnt", defaultValue: 2);
    num mntexp = prefsdata.get("mntexp", defaultValue: 2000);
    num annexp = prefsdata.get("annexp", defaultValue: 7000);
    num mntperexp = prefsdata.get("mntperexp", defaultValue: 15);
    num mntinc = prefsdata.get("mntinc", defaultValue: 4300);
    num mntnstblinc = prefsdata.get("mntnstblinc", defaultValue: 2000);
    num mntperinc = prefsdata.get("mntperinc", defaultValue: 40);
    DateTime startDate =
        prefsdata.get("startDate", defaultValue: DateTime(2024, 9, 1));
    DateTime selectedDate =
        prefsdata.get("selectedDate", defaultValue: DateTime(2024, 9, 1));
    DateTime currentWeekStart =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    double calculateSavingsSoFar() {
      if (startDate == null) return 0.0;
      int daysSinceStart = DateTime.now().difference(startDate).inDays;
      return nownetcredit +
          ((0.5 *
                      ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) *
                              (1 - freemnt / 12) -
                          (mntexp + annexp / 12)) /
                      30.5)
                  .roundToDouble() *
              daysSinceStart.toDouble());
    }

    DateTime ramadane =
        HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 9, 1);
    DateTime aidfitr =
        HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 10, 1);
    DateTime aidfadha =
        HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 12, 10);

    double calculateRemainingToGoal() {
      return totsaving - calculateSavingsSoFar();
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: <Widget>[
          Card(
            elevation: 5,
            margin: const EdgeInsets.all(15),
            color: const Color.fromARGB(253, 223, 135, 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /*Text("Total Savings",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${calculateSavingsSoFar().toStringAsFixed(2)}"),
                Text("Daily Limit",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    "${(0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12)) / 30.5).roundToDouble().toStringAsFixed(2)}"),
                Text("Remaining to Goal",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text("\$${calculateRemainingToGoal().toStringAsFixed(2)}"),
                */
                const SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      " المبلغ المسموح إنفاقه في اليوم هو  ${(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / 30.5).roundToDouble()} من أصل ${(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / 30.5).roundToDouble() * (daysDifference.toInt() + 1)} درهم",
                      style: darktextstyle.copyWith(fontSize: 25),
                      textAlign: TextAlign.center,
                    ),
                    Text("", style: darktextstyle.copyWith(fontSize: 15)),
                    Text(
                        " عدد الأيام المتبقية هو ${daysDifference.toInt() + 1} أيام ",
                        style: darktextstyle.copyWith(fontSize: 25)),
                    TableCalendar(
                      focusedDay: today,
                      firstDay: DateTime(2024, 1, 1),
                      lastDay: DateTime(2027, 12, 31),
                      selectedDayPredicate: (day) => isSameDay(day, today),
                      calendarFormat: CalendarFormat.month,
                      //calendarBuilders: CalendarBuilders(),
                      headerStyle: const HeaderStyle(
                          formatButtonVisible: false, titleCentered: true),
                      onDaySelected: _ondayselected,
                      calendarStyle: const CalendarStyle(
                        weekNumberTextStyle:
                            TextStyle(color: Color(0xFFFFFFFF)),
                        weekendTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      " المبلغ الذي يجب أن يكون بحسابك هو ${nownetcredit + (today.difference(startDate).inDays + 1) * -(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / 30.5).roundToDouble() + (today.month - DateTime(startDate.year, startDate.month, 29).month + 12 * (today.year - selectedDate.year)) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp)} درهما ",
                      style: darkteststyle2,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text("تدبير الموارد الخاصة بك", style: darktextstyle),
                const SizedBox(height: 20),
                moneyinput(size, totsaving, "totsaving",
                    "المبلغ الإجمالي المراد جمعه"),

                moneyinput(size, nownetcredit, "nownetcredit",
                    " المبلغ المتوفر حاليا"),
                SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(
                      " تم إحتساب الإدخار إبتداء من تاريخ  ${startDate.year}-${startDate.month}-${startDate.day}",
                      style: darkteststyle2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                moneyinput(size, mntsaving, "mntsaving",
                    "المبلغ الشهري المرتقب إقطاعه"),

                moneyinput(size, freemnt, "freemnt", "تردد أشهر الراحة"),
                const SizedBox(height: 20),
                // ValueListenableBuilder(
                //   valueListenable: prefsdata.listenable(),
                //   builder: (context, box, _) {
                //     return Text(
                //         "${prefsdata.get('totsaving', defaultValue: 5)}");
                //   },
                // ),

                /*HorizontalWeekCalendar(
                  minDate: DateTime(2023, 12, 31),
                  maxDate: DateTime(2025, 1, 31),
                  initialDate: startDate,
                  onDateChange: (DateTime date) {
                    setState(() {
                      prefsdata.put("selectedDate".toString(), date);
                      startDate = prefsdata.get("selectedDate");
                    });
                  },
                ),*/

                /*Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Selected Date",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('dd MMM yyyy').format(selectedDate),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),*/

                /*DateTimeFormField(
                      decoration: const InputDecoration(
                        labelText: 'Enter Date',
                      ),
                      firstDate: DateTime.now().add(const Duration(days: 10)),
                      lastDate: DateTime.now().add(const Duration(days: 40)),
                      initialPickerDateTime:
                          DateTime.now().add(const Duration(days: 20)),
                      onChanged: (DateTime? value) {
                        prefsdata.put("startDate".toString(), Value);
                        startDate = prefsdata.get("startDate");
                      },
                    ),*/

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                          (0.5 *
                                  ((mntinc +
                                              mntnstblinc *
                                                  (1 - 0.01 * mntperinc)) *
                                          (1 - freemnt / 12) -
                                      (mntexp + annexp / 12)) /
                                  30.5)
                              .roundToDouble()
                              .toString(),
                          style: darktextstyle.copyWith(
                            color: ((0.5 *
                                                ((mntinc +
                                                            mntnstblinc *
                                                                (1 -
                                                                    0.01 *
                                                                        mntperinc)) *
                                                        (1 - freemnt / 12) -
                                                    (mntexp + annexp / 12))) /
                                            30.5) /
                                        ((0.5 *
                                                    ((mntinc +
                                                                mntnstblinc *
                                                                    (1 -
                                                                        0.01 *
                                                                            mntperinc)) *
                                                            (1 - freemnt / 12) -
                                                        (mntexp +
                                                            annexp / 12)) -
                                                (mntsaving -
                                                    0.5 *
                                                        ((mntinc + mntnstblinc) *
                                                                (1 -
                                                                    freemnt /
                                                                        12) -
                                                            (mntexp +
                                                                annexp /
                                                                    12)))) /
                                            30.5) >
                                    0.8
                                ? const Color.fromARGB(255, 127, 255, 131)
                                : const Color.fromARGB(255, 216, 19, 1),
                          )),
                      Text("المبلغ الامثل إنفاقه في اليوم",
                          style: darktextstyle),
                    ],
                  ),
                ),
                /*Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                          (30 *
                                  (1 -
                                      (((0.5 *
                                                  ((mntinc +
                                                              mntnstblinc *
                                                                  (1 -
                                                                      0.01 *
                                                                          mntperinc)) *
                                                          (1 - freemnt / 12) -
                                                      (mntexp + annexp / 12))) /
                                              30.5) /
                                          ((0.5 *
                                                      ((mntinc +
                                                                  mntnstblinc *
                                                                      (1 -
                                                                          0.01 *
                                                                              mntperinc)) *
                                                              (1 -
                                                                  freemnt /
                                                                      12) -
                                                          (mntexp +
                                                              annexp / 12)) -
                                                  (mntsaving -
                                                      0.5 *
                                                          ((mntinc + mntnstblinc) *
                                                                  (1 -
                                                                      freemnt /
                                                                          12) -
                                                              (mntexp +
                                                                  annexp /
                                                                      12)))) /
                                              30.5))))
                              .roundToDouble()
                              .toString(),
                          style: darktextstyle),
                      Text("عدد الأيام الإستثنائية لإنفاق المبلغ الأقصى شهريا",
                          style: darktextstyle),
                    ],
                  ),
                ),*/

                infocalculated(
                    (totsaving - nownetcredit) /
                        (0.5 *
                            ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) *
                                    (1 - freemnt / 12) -
                                (mntexp + annexp / 12))),
                    "عدد أشهر الإدخار"),
                infocalculated(
                    0.5 *
                        ((mntinc + mntnstblinc) * (1 - freemnt / 12) -
                            (mntexp + annexp / 12)),
                    "أقصى ما يمكن ادخاره"),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  "${(nownetcredit + (ramadane.difference(startDate).inDays + 1) * -(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / 30.5).roundToDouble() + (ramadane.month - DateTime(startDate.year, startDate.month, 29).month + 12 * (ramadane.year - selectedDate.year)) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp)).round()}",
                                  style: darkteststyle2.copyWith(
                                      color: nownetcredit +
                                                  (ramadane.difference(startDate).inDays +
                                                          1) *
                                                      -(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) *
                                                                      (1 -
                                                                          freemnt /
                                                                              12) -
                                                                  (mntexp +
                                                                      annexp /
                                                                          12) -
                                                                  (mntsaving)) /
                                                              30.5)
                                                          .roundToDouble() +
                                                  (ramadane.month -
                                                          DateTime(startDate.year, startDate.month, 29)
                                                              .month +
                                                          12 *
                                                              (ramadane.year -
                                                                  selectedDate
                                                                      .year)) *
                                                      ((mntinc +
                                                                  mntnstblinc *
                                                                      (1 - 0.01 * mntperinc)) *
                                                              (1 - freemnt / 12) -
                                                          mntexp) >
                                              5000
                                          ? Color(0xF4C3FFBE)
                                          : Color(0xFAFDBFBF)),
                                ),
                              ),
                            ),
                            SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(
                                    "${(nownetcredit + (aidfitr.difference(startDate).inDays + 1) * -(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / 30.5).roundToDouble() + (aidfitr.month - DateTime(startDate.year, startDate.month, 29).month + 12 * (aidfitr.year - selectedDate.year)) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp)).round()}",
                                    style: darkteststyle2.copyWith(
                                        color: nownetcredit +
                                                    (aidfitr.difference(startDate).inDays + 1) *
                                                        -(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) -
                                                                    (mntexp +
                                                                        annexp /
                                                                            12) -
                                                                    (mntsaving)) /
                                                                30.5)
                                                            .roundToDouble() +
                                                    (aidfitr.month -
                                                            DateTime(
                                                                    startDate
                                                                        .year,
                                                                    startDate
                                                                        .month,
                                                                    29)
                                                                .month +
                                                            12 *
                                                                (aidfitr.year -
                                                                    selectedDate
                                                                        .year)) *
                                                        ((mntinc +
                                                                    mntnstblinc *
                                                                        (1 - 0.01 * mntperinc)) *
                                                                (1 - freemnt / 12) -
                                                            mntexp) >
                                                5000
                                            ? Color(0xF4C3FFBE)
                                            : Color(0xFAFDBFBF)),
                                  ),
                                )),
                            SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  "${(nownetcredit + (aidfadha.difference(startDate).inDays + 1) * -(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / 30.5).roundToDouble() + (aidfadha.month - DateTime(startDate.year, startDate.month, 29).month + 12 * (aidfadha.year - selectedDate.year)) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp)).round()}",
                                  style: darkteststyle2.copyWith(
                                      color: nownetcredit +
                                                  (aidfadha.difference(startDate).inDays +
                                                          1) *
                                                      -(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) *
                                                                      (1 -
                                                                          freemnt /
                                                                              12) -
                                                                  (mntexp +
                                                                      annexp /
                                                                          12) -
                                                                  (mntsaving)) /
                                                              30.5)
                                                          .roundToDouble() +
                                                  (aidfadha.month -
                                                          DateTime(startDate.year, startDate.month, 29)
                                                              .month +
                                                          12 *
                                                              (aidfadha.year -
                                                                  selectedDate
                                                                      .year)) *
                                                      ((mntinc +
                                                                  mntnstblinc *
                                                                      (1 - 0.01 * mntperinc)) *
                                                              (1 - freemnt / 12) -
                                                          mntexp) >
                                              5000
                                          ? Color(0xF4C3FFBE)
                                          : Color(0xFAFDBFBF)),
                                ),
                              ),
                            ),
                          ]),
                      /*Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  "<=",
                                  style: darkteststyle2,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  "<=",
                                  style: darkteststyle2,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  "<=",
                                  style: darkteststyle2,
                                ),
                              ),
                            ),
                          ]),*/
                      Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  "${ramadane.year}-${ramadane.month.toString().padLeft(2, '0')}-${ramadane.day.toString().padLeft(2, '0')}",
                                  style: darkteststyle2,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  "${aidfitr.year}-${aidfitr.month.toString().padLeft(2, '0')}-${aidfitr.day.toString().padLeft(2, '0')}",
                                  style: darkteststyle2,
                                ),
                              ),
                            ),
                            SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(
                                    "${aidfadha.year}-${aidfadha.month.toString().padLeft(2, '0')}-${aidfadha.day.toString().padLeft(2, '0')}",
                                    style: darkteststyle2,
                                  ),
                                )),
                          ]),
                      Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(
                                    ":",
                                    style: darkteststyle2,
                                  ),
                                )),
                            SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(
                                    ":",
                                    style: darkteststyle2,
                                  ),
                                )),
                            SizedBox(
                                height: 40,
                                child: Center(
                                  child: Text(
                                    ":",
                                    style: darkteststyle2,
                                  ),
                                )),
                          ]),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  'فاتح رمضان',
                                  style: darktextstyle,
                                ),
                              )),
                          SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  'عيد الفطر',
                                  style: darktextstyle,
                                ),
                              )),
                          SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  'عيد الأضحى',
                                  style: darktextstyle,
                                ),
                              )),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => prefsdata.deleteFromDisk(),
                  child: SizedBox(
                    width: size.width * 0.25,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Icon(Icons.restore, color: Colors.red),
                        Text("إعادة الظبط",
                            style: darktextstyle.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                OutlinedButton(
                  onPressed: () => Get.isDarkMode
                      ? Get.changeTheme(ThemeData.light())
                      : Get.changeTheme(ThemeData.dark()),
                  child: SizedBox(
                    width: size.width * 0.25,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Icon(Icons.dark_mode_outlined, color: Colors.red),
                        Text("تغيير التيم",
                            style: darktextstyle.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          Card(
            elevation: 5,
            margin: const EdgeInsets.all(15),
            color: const Color.fromARGB(251, 250, 101, 72),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text("هيكلة المصاريف الشخصية", style: darktextstyle),
                  const SizedBox(height: 20),
                  moneyinput(size, mntexp, "mntexp", "مصاريف شهرية "),
                  moneyinput(size, annexp, "annexp", "مصاريف سنوية"),
                  moneyinputslider(size, mntperexp, "mntperexp",
                      "نسبة التغير في الإنفاق        "),
                  const SizedBox(height: 20),
                  infocalculated(
                      -(mntsaving -
                          0.5 *
                              ((mntinc + mntnstblinc) * (1 - freemnt / 12) -
                                  (mntexp + annexp / 12))),
                      "فائض / عجز التدبير"),
                  infocalculated((totsaving - nownetcredit) / mntsaving,
                      "عدد أشهر الإدخار المثالي"),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SfLinearGauge(
                          interval: 12,
                          maximum: 48,
                          axisTrackStyle: const LinearAxisTrackStyle(
                              thickness: 10,
                              edgeStyle: LinearEdgeStyle.endCurve),
                          ranges: const [
                            LinearGaugeRange(
                              color: Colors.transparent,
                              startValue: 0,
                              endValue: 84,
                            ),
                          ],
                          markerPointers: [
                            LinearShapePointer(
                              value: (totsaving - nownetcredit) /
                                  (0.5 *
                                      ((mntinc +
                                                  mntnstblinc *
                                                      (1 - 0.01 * mntperinc)) *
                                              (1 - freemnt / 12) -
                                          (mntexp + annexp / 12))),
                            ),
                          ],
                          barPointers: [
                            LinearBarPointer(
                              value: (totsaving - nownetcredit) / mntsaving,
                              thickness: 10,
                              edgeStyle: LinearEdgeStyle.endCurve,
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "مبيان أشهر الإدخار",
                            style: darktextstyle,
                            textAlign: TextAlign.right,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
          ),
          Card(
            elevation: 5,
            margin: const EdgeInsets.all(15),
            color: const Color.fromARGB(249, 67, 154, 43),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Text("هيكلة المداخيل الشخصية", style: darktextstyle),
                  const SizedBox(height: 20),
                  moneyinput(size, mntinc, "mntinc", "المداخيل الشهرية القارة"),
                  moneyinput(size, mntnstblinc, "mntnstblinc",
                      "مداخيل شهرية غير قارة"),
                  moneyinputslider(size, mntperinc, "mntperinc",
                      "نسبة تقلبات المداخيل         "),
                  const SizedBox(height: 20),
                  infocalculated(
                      0.5 *
                              ((mntinc + mntnstblinc * (1 + mntperinc * 0.01)) *
                                  (12 - freemnt)) -
                          (mntexp * (1 - mntperexp * 0.01) + annexp),
                      "أقصى ما يمكن إدخاره سنويا"),
                  infocalculated(
                      0.5 *
                              ((mntinc + mntnstblinc * (1 - mntperinc * 0.01)) *
                                  (12 - freemnt)) -
                          (mntexp * (1 + mntperexp * 0.01) + annexp),
                      "أقل ما يمكن إدخاره سنويا"),
                  const SizedBox(height: 20),
                ]),
          ),
          /*Card(
            elevation: 5,
            margin: const EdgeInsets.all(15),
            color: const Color.fromARGB(249, 67, 154, 43),
            child: Column(
              children: [
                SfCalendar(
                  view: CalendarView.month,
                  dataSource: ValueDataSource(_getDailyEvents()),
                  monthViewSettings: MonthViewSettings(
                    showAgenda: true,
                    // Shows events in a list below the calendar
                  ),
                ),
                SizedBox(
                  height: 50,
                )
              ],
            ),
          ),*/
        ],
      ),
    );
  }

  // Method to get a list of daily events
  List<Appointment> _getDailyEvents() {
    List<Appointment> appointments = <Appointment>[];
    DateTime startDate =
        prefsdata.get("startDate", defaultValue: DateTime(2024, 9, 1));
    //DateTime startDate =DateTime(2024, 9, 1);
    // Starting from September 1st, 2024
    int startingValue = 5;
    int increment = 3;

    for (int i = 0; i < 61; i++) {
      // for September and October (61 days total)
      DateTime date = startDate.add(Duration(days: i));
      int dailyValue = startingValue + (i * increment);

      appointments.add(Appointment(
        startTime: date,
        endTime:
            date.add(Duration(hours: 1)), // Just for a placeholder end time
        subject: 'Value: $dailyValue',
        color: Colors.blue,
        isAllDay: true, // Makes the event appear for the whole day
      ));
    }

    return appointments;
  }

  Widget moneyinput(size, boxvariable, boxvariablename, String textlabel) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 7, top: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            //height: size.height * 0.07,
            width: size.width * 0.3,
            child: TextFormField(
              initialValue: boxvariable.toString(),
              decoration: const InputDecoration(
                  //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                  border: OutlineInputBorder(gapPadding: 1)),
              onChanged: (newval) {
                //box.write('quote', 2);
                final v = int.tryParse(newval);
                if (v == null) {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename, 0);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                    //nownetcredit = 0;
                  });
                } else {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename.toString(), v);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                  });
                }
              },
              keyboardType: TextInputType.number,
              //maxLength: 10,
            ),
          ),
          Text(
            textlabel,
            style: darktextstyle,
            textAlign: TextAlign.right,
          )
        ],
      ),
    );
  }

  Widget moneyinputslider(
      size, boxvariable, boxvariablename, String textlabel) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: size.height * 0.07,
            width: size.width * 0.4,
            child: SfSlider(
              min: 0.0,
              max: 100.0,
              interval: 50,
              showTicks: true,
              showLabels: true,
              enableTooltip: true,
              thumbIcon: const Icon(Icons.percent_rounded,
                  color: Colors.blue, size: 14.0),
              tooltipShape: const SfPaddleTooltipShape(),
              value: boxvariable as num,
              onChanged: (dynamic newValue) {
                setState(() {
                  prefsdata.put(boxvariablename.toString(), newValue);
                  boxvariable = prefsdata.get(boxvariablename.toString());
                });
              },
            ),
          ),
          Text(
            textlabel,
            style: darktextstyle,
            textAlign: TextAlign.right,
          )
        ],
      ),
    );
  }

  Widget infocalculated(num value, labeltext) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value.roundToDouble().toString(), style: darktextstyle),
          Text(labeltext, style: darktextstyle),
        ],
      ),
    );
  }

  Widget coloredinfocalculated(num value, labeltext) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value.roundToDouble().toString(),
              style: darktextstyle.copyWith(
                color: 0.6 > 0.5
                    ? const Color.fromARGB(255, 216, 19, 1)
                    : const Color.fromARGB(255, 127, 255, 131),
              )),
          Text(labeltext, style: darktextstyle),
        ],
      ),
    );
  }

  Future<void> pickStartDate(BuildContext context) async {
    DateTime startDate =
        prefsdata.get("startDate", defaultValue: DateTime(2024, 9, 1));
    DateTime pickedDate = DateTime.now();
    setState(() {
      prefsdata.put("startDate", pickedDate);
      startDate = pickedDate;
    });
  }

  void _ondayselected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });
  }

  /*String getFirstDayOfRamadan(nownetcredit,startDate,mntinc,mntnstblinc,mntperinc) {
    DateTime ramadane =
        HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 9, 1);
    DateTime aidfitr =
        HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 10, 1);
    DateTime aidfadha =
        HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 12, 10);

    return 'First day of Ramadan : ${ramadane.year}-${ramadane.month.toString().padLeft(2, '0')}-${ramadane.day.toString().padLeft(2, '0')}     =>  ${nownetcredit + (ramadane.difference(startDate).inDays + 1) * -(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc) * (1 - prefsdata.get("freemnt") / 12) - (prefsdata.get("mntexp") + prefsdata.get("annexp") / 12) - (prefsdata.get("mntsaving"))) / 30.5).roundToDouble() + (ramadane.month - DateTime(prefsdata.get("startDate").year, prefsdata.get("startDate").month, 29).month + 12 * (ramadane.year - prefsdata.get("selectedDate").year)) * (prefsdata.get("mntinc") - prefsdata.get("mntinc"))).toString()} \n day of aid al fitr : ${aidfitr.year}-${aidfitr.month.toString().padLeft(2, '0')}-${aidfitr.day.toString().padLeft(2, '0')}\n day of aid al adha : ${aidfadha.year}-${aidfadha.month.toString().padLeft(2, '0')}-${aidfadha.day.toString().padLeft(2, '0')}';
  }*/
}
