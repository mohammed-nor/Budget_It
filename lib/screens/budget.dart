import 'package:flutter/material.dart';
import 'package:budget_it/services/styles%20and%20constants.dart';
import 'package:hive/hive.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:budget_it/models/budget_history.dart';
import 'package:intl/intl.dart';

class Budgetpage extends StatefulWidget {
  const Budgetpage({super.key});

  @override
  State<Budgetpage> createState() => _BudgetpageState();
}

void initState() {
  // TODO: implement initState
  cardcolor = prefsdata.get("cardcolor", defaultValue: const Color.fromRGBO(20, 20, 20, 1.0));
}

class _BudgetpageState extends State<Budgetpage> {
  DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  Box<BudgetHistory>? historyBox;
  List<BudgetHistory> budgetHistory = [];

  @override
  void initState() {
    super.initState();
    cardcolor = prefsdata.get("cardcolor", defaultValue: const Color.fromRGBO(20, 20, 20, 1.0));
    _initHistoryBox();
    _loadBudgetHistory();
  }

  Future<void> _initHistoryBox() async {
    historyBox = await Hive.openBox<BudgetHistory>('budget_history');
  }

  void _loadBudgetHistory() {
    if (historyBox != null && historyBox!.isNotEmpty) {
      budgetHistory = historyBox!.values.toList();
      budgetHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }
  }

  void _saveCurrentState() {
    if (historyBox != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Check if we already have an entry for today
      final todayEntry = historyBox!.values.where((entry) => entry.timestamp.year == today.year && entry.timestamp.month == today.month && entry.timestamp.day == today.day).toList();

      if (todayEntry.isEmpty) {
        final newEntry = BudgetHistory(
          timestamp: today,
          mntsaving: prefsdata.get("mntsaving", defaultValue: 1000),
          freemnt: prefsdata.get("freemnt", defaultValue: 2),
          nownetcredit: prefsdata.get("nownetcredit", defaultValue: 2000),
        );

        historyBox!.add(newEntry);
        budgetHistory = historyBox!.values.toList();
        budgetHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
    }
  }

  // Update the moneyinput method to save state when values change
  Widget moneyinput(size, boxvariable, boxvariablename, String textlabel) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 7, top: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 50 * fontSize2 / 16,
            width: size.width * 0.17 * fontSize2 / 16,
            child: TextFormField(
              textAlign: TextAlign.center,
              style: darktextstyle.copyWith(fontSize: fontSize2),
              initialValue: boxvariable.toString(),
              decoration: InputDecoration(hintStyle: darktextstyle.copyWith(fontSize: fontSize2), border: OutlineInputBorder(gapPadding: 1)),
              onChanged: (newval) {
                final v = int.tryParse(newval);
                if (v == null) {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename, 0);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                    print(boxvariable.toString() + boxvariablename.toString());
                    // After any value changes, save current state
                    _saveCurrentState();
                  });
                } else {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename.toString(), v);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                    print(boxvariable.toString() + boxvariablename.toString());
                    // After any value changes, save current state
                    _saveCurrentState();
                  });
                }
              },
              keyboardType: TextInputType.number,
            ),
          ),
          Text(textlabel, style: darktextstyle.copyWith(fontSize: fontSize2), textAlign: TextAlign.right),
        ],
      ),
    );
  }

  // Now, add a new card with budget history visualization
  Widget _buildBudgetHistoryCard(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Get only the last 6 months of data
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    final recentHistory = budgetHistory.where((entry) => entry.timestamp.isAfter(sixMonthsAgo)).toList();

    if (recentHistory.isEmpty) {
      return Card(
        elevation: 5,
        color: cardcolor,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text("لا توجد بيانات تاريخية كافية بعد. استمر في تحديث ميزانيتك لرؤية الرسوم البيانية هنا.", style: darktextstyle.copyWith(fontSize: fontSize1), textAlign: TextAlign.center),
        ),
      );
    }

    // Calculate statistics
    num totalSaved = 0;
    num startCredit = recentHistory.first.nownetcredit;
    num endCredit = recentHistory.last.nownetcredit;
    num savingProgress = endCredit - startCredit;

    // Find months with best/worst performance
    List<MapEntry<DateTime, num>> monthlyChanges = [];
    for (int i = 1; i < recentHistory.length; i++) {
      final change = recentHistory[i].nownetcredit - recentHistory[i - 1].nownetcredit;
      monthlyChanges.add(MapEntry(recentHistory[i].timestamp, change));
    }

    monthlyChanges.sort((a, b) => b.value.compareTo(a.value));
    final bestMonth = monthlyChanges.isNotEmpty ? monthlyChanges.first : null;

    monthlyChanges.sort((a, b) => a.value.compareTo(b.value));
    final worstMonth = monthlyChanges.isNotEmpty ? monthlyChanges.first : null;

    return Card(
      elevation: 5,
      color: cardcolor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("تحليل الأداء - آخر 6 أشهر", style: darktextstyle.copyWith(fontSize: fontSize1 * 1.2, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),

            // Savings Growth Chart
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(dateFormat: DateFormat('MM/dd'), intervalType: DateTimeIntervalType.months, interval: 1),
                primaryYAxis: NumericAxis(numberFormat: NumberFormat('#,###')),
                tooltipBehavior: TooltipBehavior(enable: true),
                legend: Legend(isVisible: true, position: LegendPosition.bottom),
                series: <CartesianSeries>[
                  LineSeries<BudgetHistory, DateTime>(
                    name: 'المدخرات',
                    dataSource: recentHistory,
                    xValueMapper: (BudgetHistory data, _) => data.timestamp,
                    yValueMapper: (BudgetHistory data, _) => data.nownetcredit,
                    color: const Color.fromRGBO(106, 253, 95, 1.0),
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Monthly Saving Target Chart
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(dateFormat: DateFormat('MM/dd'), intervalType: DateTimeIntervalType.months, interval: 1),
                primaryYAxis: NumericAxis(),
                tooltipBehavior: TooltipBehavior(enable: true),
                legend: Legend(isVisible: true, position: LegendPosition.bottom),
                series: <CartesianSeries>[
                  LineSeries<BudgetHistory, DateTime>(
                    name: 'هدف الإدخار الشهري',
                    dataSource: recentHistory,
                    xValueMapper: (BudgetHistory data, _) => data.timestamp,
                    yValueMapper: (BudgetHistory data, _) => data.mntsaving,
                    color: Colors.blue,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                  LineSeries<BudgetHistory, DateTime>(
                    name: 'أشهر الراحة',
                    dataSource: recentHistory,
                    xValueMapper: (BudgetHistory data, _) => data.timestamp,
                    yValueMapper: (BudgetHistory data, _) => data.freemnt,
                    color: Colors.orange,
                    markerSettings: const MarkerSettings(isVisible: true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Statistics
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color.fromRGBO(40, 40, 40, 1.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("ملخص الأداء", style: darktextstyle.copyWith(fontSize: fontSize1, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                  const SizedBox(height: 10),
                  _buildStatRow("التقدم في الإدخار:", "${savingProgress.round()} درهم", savingProgress > 0 ? const Color.fromRGBO(106, 253, 95, 1.0) : const Color.fromRGBO(253, 95, 95, 1.0)),
                  _buildStatRow("متوسط هدف الإدخار الشهري:", "${recentHistory.map((e) => e.mntsaving).reduce((a, b) => a + b) ~/ recentHistory.length} درهم", Colors.white),

                  if (bestMonth != null)
                    _buildStatRow("أفضل شهر أداءً:", "${DateFormat('MMMM yyyy').format(bestMonth.key)} (${bestMonth.value.round()} درهم)", const Color.fromRGBO(106, 253, 95, 1.0)),

                  if (worstMonth != null)
                    _buildStatRow("أسوأ شهر أداءً:", "${DateFormat('MMMM yyyy').format(worstMonth.key)} (${worstMonth.value.round()} درهم)", const Color.fromRGBO(253, 95, 95, 1.0)),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: darktextstyle.copyWith(fontSize: fontSize1, color: valueColor), textAlign: TextAlign.left),
          Text(label, style: darktextstyle.copyWith(fontSize: fontSize1), textAlign: TextAlign.right),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double fontSize1 = prefsdata.get("fontsize1", defaultValue: 15.toDouble());
    double fontSize2 = prefsdata.get("fontsize2", defaultValue: 15.toDouble());
    late DateTime NextMonthPaymentDate;
    late DateTime ThisMonthPaymentDate;
    if (today.day >= 30 && today.month != 1) {
      int nextMonth = today.month == 12 ? 1 : today.month + 1;
      int nextYear = today.month == 12 ? today.year + 1 : today.year;
      NextMonthPaymentDate = DateTime(nextYear, nextMonth, 30);
    } else if (today.day >= 30 && today.month != 2 && today.month == 1) {
      int nextMonth = today.month == 12 ? 1 : today.month + 1;
      int nextYear = today.month == 12 ? today.year + 1 : today.year;
      NextMonthPaymentDate = DateTime(nextYear, nextMonth, 28);
    } else if (today.day >= 28 && today.month == 2) {
      int nextMonth = today.month + 1;
      int nextYear = today.year;
      NextMonthPaymentDate = DateTime(nextYear, nextMonth, 30);
    } else if (today.month == 2) {
      NextMonthPaymentDate = DateTime(today.year, today.month, 28);
    } else {
      NextMonthPaymentDate = DateTime(today.year, today.month, 30);
    }

    if (today.day < 30 && today.month <= 12 && today.month > 3) {
      ThisMonthPaymentDate = DateTime(today.year, today.month - 1, 30);
    } else if (today.day < 30 && today.month == 3) {
      ThisMonthPaymentDate = DateTime(today.year, today.month - 1, 28);
    } else if (today.day < 28 && today.month == 2) {
      ThisMonthPaymentDate = DateTime(today.year, today.month - 1, 30);
    } else if (today.day < 30 && today.month == 1) {
      ThisMonthPaymentDate = DateTime(today.year - 1, 12, 30);
    } else {
      ThisMonthPaymentDate = DateTime(today.year, today.month, 30);
    }
    int daysleftInCurrentMonth() {
      DateTime firstDayNextMonth = (today.month < 12) ? DateTime(today.year, today.month + 1, 1) : DateTime(today.year + 1, 1, 1);

      return firstDayNextMonth.subtract(Duration(days: today.day)).day - 1;
    }

    int daysInCurrentMonth = NextMonthPaymentDate.difference(ThisMonthPaymentDate).inDays;
    final size = MediaQuery.of(context).size;
    num totsaving = prefsdata.get("totsaving", defaultValue: 50000);
    num nownetcredit = prefsdata.get("nownetcredit", defaultValue: 2000);
    num nowcredit = prefsdata.get("nowcredit", defaultValue: 2000);
    num mntsaving = prefsdata.get("mntsaving", defaultValue: 1000);
    num freemnt = prefsdata.get("freemnt", defaultValue: 2);
    num mntexp = prefsdata.get("mntexp", defaultValue: 2000);
    num annexp = prefsdata.get("annexp", defaultValue: 7000);
    num mntperexp = prefsdata.get("mntperexp", defaultValue: 15);
    num mntinc = prefsdata.get("mntinc", defaultValue: 4300);
    num mntnstblinc = prefsdata.get("mntnstblinc", defaultValue: 2000);
    num mntperinc = prefsdata.get("mntperinc", defaultValue: 40);
    DateTime startDate = prefsdata.get("startDate", defaultValue: DateTime(2024, 9, 1));

    double calculateSavingsSoFar() {
      int daysSinceStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).difference(DateTime(startDate.year, startDate.month, startDate.day)).inDays;
      return nowcredit + mntsaving * daysSinceStart.toDouble();
    }

    DateTime ramadane =
        HijriCalendar()
                    .hijriToGregorian(HijriCalendar.now().hYear, 9, 1)
                    .difference(HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, HijriCalendar.now().hMonth, HijriCalendar.now().hDay))
                    .inDays >
                1
            ? HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 9, 1)
            : HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear + 1, 9, 1);
    DateTime aidfitr =
        HijriCalendar()
                    .hijriToGregorian(HijriCalendar.now().hYear, 10, 1)
                    .difference(HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, HijriCalendar.now().hMonth, HijriCalendar.now().hDay))
                    .inDays >
                1
            ? HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 10, 1)
            : HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear + 1, 10, 1);
    DateTime aidfadha =
        HijriCalendar()
                    .hijriToGregorian(HijriCalendar.now().hYear, 12, 10)
                    .difference(HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, HijriCalendar.now().hMonth, HijriCalendar.now().hDay))
                    .inDays >
                1
            ? HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 12, 10)
            : HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear + 1, 12, 10);

    Widget moneyinput(size, boxvariable, boxvariablename, String textlabel) {
      return Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 7, top: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 50 * fontSize2 / 16,
              width: size.width * 0.17 * fontSize2 / 16,
              child: TextFormField(
                textAlign: TextAlign.center,
                style: darktextstyle.copyWith(fontSize: fontSize2),
                initialValue: boxvariable.toString(),
                decoration: InputDecoration(
                  hintStyle: darktextstyle.copyWith(fontSize: fontSize2),
                  //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                  border: OutlineInputBorder(gapPadding: 1),
                ),
                onChanged: (newval) {
                  //box.write('quote', 2);
                  final v = int.tryParse(newval);
                  if (v == null) {
                    setState(() {
                      pickStartDate(context);
                      prefsdata.put(boxvariablename, 0);
                      boxvariable = prefsdata.get(boxvariablename.toString());
                      print(boxvariable.toString() + boxvariablename.toString());
                      //nowcredit = 0;
                    });
                  } else {
                    setState(() {
                      pickStartDate(context);
                      prefsdata.put(boxvariablename.toString(), v);
                      boxvariable = prefsdata.get(boxvariablename.toString());
                      print(boxvariable.toString() + boxvariablename.toString());
                    });
                  }
                },
                keyboardType: TextInputType.number,
                //maxLength: 10,
              ),
            ),
            Text(textlabel, style: darktextstyle.copyWith(fontSize: fontSize2), textAlign: TextAlign.right),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(7),
        children: <Widget>[
          Card(
            elevation: 2,
            color: cardcolor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      " المبلغ المسموح في اليوم هو  ${((((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)))).round()} من ${((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth) * (daysleftInCurrentMonth() + 1)).round()} درهم",
                      style: darktextstyle.copyWith(fontSize: fontSize1),
                      textAlign: TextAlign.center,
                    ),
                    Text(" عدد الأيام المتبقية للأجرة هو ${daysleftInCurrentMonth()} أيام ", style: darktextstyle.copyWith(fontSize: fontSize1)),
                    TableCalendar(
                      focusedDay: today,
                      rowHeight: 45,
                      firstDay: DateTime(startDate.year, startDate.month, 1),
                      lastDay: DateTime(2050, 12, 31),
                      selectedDayPredicate: (day) => isSameDay(day, today),
                      calendarFormat: CalendarFormat.month,

                      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                      onDaySelected: _ondayselected,
                      calendarStyle: CalendarStyle(
                        weekNumberTextStyle: const TextStyle(color: Color(0xFFFFFFFF)),
                        //rangeStartTextStyle: const TextStyle(color: Color(0xFF373737), fontSize: 16.0),
                        weekendTextStyle: TextStyle(fontSize: fontSize1, fontWeight: FontWeight.w900, color: Color(0xFFE82064)),
                        outsideTextStyle: TextStyle(color: const Color(0xFFBEBEBE)),
                        todayDecoration: const BoxDecoration(color: Color(0xFFE696B2), shape: BoxShape.circle),
                        todayTextStyle: TextStyle(color: Color(0xFFFAFAFA), fontSize: fontSize1, fontWeight: FontWeight.w900),
                        selectedDecoration: const BoxDecoration(color: Color(0xFFE82064), shape: BoxShape.circle),
                        selectedTextStyle: TextStyle(color: Color(0xFFFAFAFA), fontSize: fontSize1, fontWeight: FontWeight.w900),
                        defaultTextStyle: TextStyle(fontSize: fontSize1, fontWeight: FontWeight.w900, color: Color(0xFFFFFFFF)),
                      ),
                    ),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),

                    Text(
                      " المبلغ عندك في أول اليوم هو ${((nowcredit + (daysdiff(startDate, today)) * (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) + count30thsPassed(startDate, today) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp))).round()} درهما ",
                      style: darktextstyle.copyWith(fontSize: fontSize1),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      " المبلغ الذي وفرته هو ${(nownetcredit + count30thsPassed(startDate, today) * (mntsaving))} درهما ",
                      style: darktextstyle.copyWith(fontSize: fontSize1, color: const Color.fromRGBO(106, 253, 95, 1.0)),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      totsaving - nownetcredit - count30thsPassed(startDate, today) * (mntsaving) > 0
                          ? " المبلغ الذي ينقصك هو ${totsaving - nownetcredit - count30thsPassed(startDate, today) * (mntsaving)} درهما "
                          : " مبروك , لقد حققت هدفك ",
                      style: darktextstyle.copyWith(
                        fontSize: fontSize1,
                        color: totsaving - nownetcredit - count30thsPassed(startDate, today) * (mntsaving) > 0 ? const Color.fromRGBO(253, 95, 95, 1.0) : const Color.fromRGBO(106, 253, 95, 1.0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        ((0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12)) / daysInCurrentMonth)).round().toString(),
                        style: darktextstyle.copyWith(
                          fontSize: fontSize1,
                          color:
                              ((0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12))) / daysInCurrentMonth) /
                                          ((0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12)) -
                                                  (mntsaving - 0.5 * ((mntinc + mntnstblinc) * (1 - freemnt / 12) - (mntexp + annexp / 12)))) /
                                              daysInCurrentMonth) >
                                      0.8
                                  ? const Color.fromARGB(255, 127, 255, 131)
                                  : const Color.fromARGB(255, 216, 19, 1),
                        ),
                      ),
                      Text("المبلغ الامثل إنفاقه في اليوم", style: darktextstyle.copyWith(fontSize: fontSize1)),
                    ],
                  ),
                ),
                infocalculated((totsaving - nownetcredit) / mntsaving, "عدد أشهر الإدخار"),
                infocalculated((totsaving - nownetcredit) / (0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12))), "عدد أشهر الإذخار الأمثل"),
                infocalculated(0.5 * ((mntinc + mntnstblinc) * (1 - freemnt / 12) - (mntexp + annexp / 12)), "أقصى ما يمكن ادخاره"),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),
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
                            height: 25,
                            child: Center(
                              child: Text(
                                "${(((nowcredit + (daysdiff(startDate, ramadane) + 1) * (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) + count30thsPassed(startDate, ramadane) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp)))).round()}",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                  color:
                                      ((nowcredit +
                                                  (daysdiff(startDate, ramadane) + 1) *
                                                      (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) +
                                                  count30thsPassed(startDate, ramadane) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp)) >
                                              5000
                                          ? const Color(0xF4C3FFBE)
                                          : const Color(0xFAFDBFBF)),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "${(((nowcredit + (daysdiff(startDate, aidfitr) + 1) * (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) + count30thsPassed(startDate, aidfitr) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp)))).round()}",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                  color:
                                      nowcredit +
                                                  (daysdiff(startDate, aidfitr) + 1) *
                                                      (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) +
                                                  count30thsPassed(startDate, aidfitr) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp) >
                                              5000
                                          ? const Color(0xF4C3FFBE)
                                          : const Color(0xFAFDBFBF),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "${(((nowcredit + (daysdiff(startDate, aidfadha) + 1) * (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) + count30thsPassed(startDate, aidfadha) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp)))).round()}",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                  color:
                                      nowcredit +
                                                  (daysdiff(startDate, aidfadha) + 1) *
                                                      (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) +
                                                  count30thsPassed(startDate, aidfadha) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp) >
                                              6000
                                          ? const Color(0xF4C3FFBE)
                                          : const Color(0xFAFDBFBF),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 25,
                            child: Center(child: Text("(${(nownetcredit + count30thsPassed(startDate, ramadane) * (mntsaving))})", style: darktextstyle.copyWith(fontSize: fontSize1))),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(child: Text("(${(nownetcredit + count30thsPassed(startDate, aidfitr) * (mntsaving))})", style: darktextstyle.copyWith(fontSize: fontSize1))),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(child: Text("(${(nownetcredit + count30thsPassed(startDate, aidfadha) * (mntsaving))})", style: darktextstyle.copyWith(fontSize: fontSize1))),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "${ramadane.year}-${aidfitr.month.toString().padLeft(2, '0')}-${ramadane.day.toString().padLeft(2, '0')}",
                                style: darktextstyle.copyWith(fontSize: fontSize1),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text("${aidfitr.year}-${aidfitr.month.toString().padLeft(2, '0')}-${aidfitr.day.toString().padLeft(2, '0')}", style: darktextstyle.copyWith(fontSize: fontSize1)),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "${aidfadha.year}-${aidfadha.month.toString().padLeft(2, '0')}-${aidfadha.day.toString().padLeft(2, '0')}",
                                style: darktextstyle.copyWith(fontSize: fontSize1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 25, child: Center(child: Text(":", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text(":", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text(":", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 25, child: Center(child: Text("(يوما", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text("(يوما", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text("(يوما", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 25, child: Center(child: Text("${daysdiff(DateTime.now(), ramadane).toString()})", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text("${daysdiff(DateTime.now(), aidfitr).toString()})", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text("${daysdiff(DateTime.now(), aidfadha).toString()})", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 25, child: Center(child: Text('فاتح رمضان', style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text('عيد الفطر', style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 25, child: Center(child: Text('عيد الأضحى', style: darktextstyle.copyWith(fontSize: fontSize1)))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _buildBudgetHistoryCard(context),
          Card(
            elevation: 2,
            color: cardcolor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text("تدبير الموارد الخاصة بك", style: darktextstyle.copyWith(fontSize: fontSize1)),
                const SizedBox(height: 20),
                moneyinput(size, totsaving, "totsaving", "المبلغ الإجمالي المراد جمعه"),
                Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15, bottom: 7, top: 7),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 50 * fontSize2 / 16,
                        width: size.width * 0.17 * fontSize2 / 16,
                        child: TextFormField(
                          textAlign: TextAlign.center,
                          style: darktextstyle.copyWith(fontSize: fontSize2),
                          initialValue: nowcredit.toString(),
                          decoration: InputDecoration(hintStyle: darktextstyle.copyWith(fontSize: fontSize2 + 20), border: OutlineInputBorder(gapPadding: 1)),
                          onChanged: (newval) {
                            final v = int.tryParse(newval);
                            if (v == null) {
                              setState(() {
                                pickStartDate(context);
                                prefsdata.put("nownetcredit", 0);
                                nownetcredit = prefsdata.get("nownetcredit".toString());
                                print(nownetcredit.toString() + "nownetcredit".toString());
                              });
                            } else {
                              setState(() {
                                pickStartDate(context);
                                prefsdata.put("nowcredit".toString(), v);
                                prefsdata.put(
                                  "nownetcredit".toString(),
                                  v -
                                      ((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth) *
                                              (daysleftInCurrentMonth()))
                                          .round(),
                                );
                                nownetcredit = prefsdata.get("nownetcredit".toString());
                                print(nownetcredit.toString() + "nownetcredit".toString());
                                print(nowcredit.toString() + "nowcredit".toString());
                              });
                            }
                          },
                          keyboardType: TextInputType.number,
                          //maxLength: 10,
                        ),
                      ),
                      Text(
                        "المبلغ المتوفر بتاريخ اليوم"
                        " ${startDate.year}-${startDate.month}-${startDate.day} "
                        "( ${DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).difference(DateTime(startDate.year, startDate.month, startDate.day)).inDays.toString()} يوم )",
                        style: darktextstyle.copyWith(fontSize: fontSize2),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),

                moneyinput(size, mntsaving, "mntsaving", "المبلغ الشهري المرتقب إقطاعه"),

                moneyinput(size, freemnt, "freemnt", "عدد أشهر الراحة السنوية"),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Card(
            elevation: 5,
            color: cardcolor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text("هيكلة المصاريف الشخصية", style: darktextstyle.copyWith(fontSize: fontSize1)),
                const SizedBox(height: 20),
                moneyinput(size, mntexp, "mntexp", "مصاريف شهرية "),
                moneyinput(size, annexp, "annexp", "مصاريف سنوية"),
                moneyinputslider(size, mntperexp, "mntperexp", "نسبة التغير في الإنفاق        "),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),
                infocalculated(-(mntsaving - 0.5 * ((mntinc + mntnstblinc) * (1 - freemnt / 12) - (mntexp + annexp / 12))), "فائض / عجز التدبير"),

                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SfLinearGauge(
                        interval: 12,
                        maximum: 48,
                        axisTrackStyle: const LinearAxisTrackStyle(thickness: 10, edgeStyle: LinearEdgeStyle.endCurve),
                        ranges: const [LinearGaugeRange(color: Colors.transparent, startValue: 0, endValue: 84)],
                        markerPointers: [
                          LinearShapePointer(value: (totsaving - nownetcredit) / (0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12)))),
                        ],
                        barPointers: [LinearBarPointer(value: (totsaving - nownetcredit) / mntsaving, thickness: 10, edgeStyle: LinearEdgeStyle.endCurve)],
                      ),
                      Padding(padding: const EdgeInsets.all(8.0), child: Text("مبيان أشهر الإدخار", style: darktextstyle.copyWith(fontSize: fontSize1), textAlign: TextAlign.right)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Card(
            elevation: 5,
            color: cardcolor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text("هيكلة المداخيل الشخصية", style: darktextstyle.copyWith(fontSize: fontSize1)),
                const SizedBox(height: 20),
                moneyinput(size, mntinc, "mntinc", "المداخيل الشهرية القارة"),
                moneyinput(size, mntnstblinc, "mntnstblinc", "مداخيل شهرية غير قارة"),
                moneyinputslider(size, mntperinc, "mntperinc", "نسبة تقلبات المداخيل         "),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),
                infocalculated(0.5 * ((mntinc + mntnstblinc * (1 + mntperinc * 0.01)) * (12 - freemnt)) - (mntexp * (1 - mntperexp * 0.01) + annexp), "أقصى ما يمكن إدخاره سنويا"),
                infocalculated(0.5 * ((mntinc + mntnstblinc * (1 - mntperinc * 0.01)) * (12 - freemnt)) - (mntexp * (1 + mntperexp * 0.01) + annexp), "أقل ما يمكن إدخاره سنويا"),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget moneyinput2(size, boxvariable, boxvariablename, String textlabel) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 7, top: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: size.width * 0.17 * fontSize2 / 16,
            child: TextFormField(
              textAlign: TextAlign.center,
              style: darktextstyle.copyWith(fontSize: fontSize2),
              initialValue: boxvariable.toString(),
              decoration: InputDecoration(hintStyle: darktextstyle.copyWith(fontSize: fontSize2), border: OutlineInputBorder(gapPadding: 1)),
              onChanged: (newval) {
                final v = int.tryParse(newval);
                if (v == null) {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename, 0);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                    print(boxvariable.toString() + boxvariablename.toString());
                  });
                } else {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename.toString(), v);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                    print(boxvariable.toString() + boxvariablename.toString());
                  });
                }
              },
              keyboardType: TextInputType.number,
            ),
          ),
          Text(textlabel, style: darktextstyle.copyWith(fontSize: fontSize2), textAlign: TextAlign.right),
        ],
      ),
    );
  }

  int daysdiff(DateTime start, DateTime goal) {
    return -DateTime(start.year, start.month, start.day).difference(DateTime(goal.year, goal.month, goal.day)).inDays;
  }

  Widget moneyinputslider(size, boxvariable, boxvariablename, String textlabel) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: size.height * 0.07,
            width: size.width * 0.3,
            child: SfSlider(
              min: 0.0,
              max: 100.0,
              interval: 50,
              showTicks: true,
              showLabels: true,
              enableTooltip: true,
              thumbIcon: const Icon(Icons.percent_rounded, color: Colors.blue, size: 14.0),
              tooltipShape: const SfPaddleTooltipShape(),
              value: boxvariable as num,
              onChanged: (dynamic newValue) {
                setState(() {
                  prefsdata.put(boxvariablename.toString(), newValue);
                  boxvariable = prefsdata.get(boxvariablename.toString());
                  print(boxvariable.toString() + boxvariablename.toString());
                  _saveCurrentState();
                });
              },
            ),
          ),
          Text(textlabel, style: darktextstyle.copyWith(fontSize: fontSize2), textAlign: TextAlign.right),
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
          Text(value.isNaN ? 0.toString() : value.round().toString(), style: darktextstyle.copyWith(fontSize: fontSize1)),
          Text(labeltext, style: darktextstyle.copyWith(fontSize: fontSize1)),
        ],
      ),
    );
  }

  int count30thsPassed(DateTime startDate, DateTime endDate) {
    if (startDate.isAfter(endDate)) {
      return 0; // Return 0 if the date range is invalid
    }

    int count = 0;
    DateTime current = DateTime(startDate.year, startDate.month, 28);
    if (current.month == 2) {
      current = DateTime(startDate.year, startDate.month, 28);
    } else {
      current = DateTime(startDate.year, startDate.month, 30);
    }
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      if (current.month == 2) {
        current = DateTime(current.year, 2, 28);
        if (current.isAfter(startDate) && (current.isBefore(endDate) || current.isAtSameMomentAs(endDate))) {
          count++;
        }
      } else {
        count++;
      }
      // Move to the next month's 30th (or closest valid date)
      if (current.month == 1) {
        current = DateTime(current.year, current.month + 1, 28);
      } else {
        current = DateTime(current.year, current.month + 1, 30);
      }
    }

    return count;
  }

  Widget coloredinfocalculated(num value, labeltext) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(value.toString(), style: darktextstyle.copyWith(fontSize: fontSize1, color: 0.6 > 0.5 ? const Color.fromARGB(255, 216, 19, 1) : const Color.fromARGB(255, 127, 255, 131))),
          Text(labeltext, style: darktextstyle.copyWith(fontSize: fontSize1)),
        ],
      ),
    );
  }

  Future<void> pickStartDate(BuildContext context) async {
    DateTime startDate = prefsdata.get("startDate", defaultValue: DateTime(2024, 9, 1));
    DateTime pickedDate = DateTime.now();
    setState(() {
      prefsdata.put("startDate", pickedDate);
      startDate = pickedDate;
      debugPrint(startDate.toString());
    });
  }

  void _ondayselected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });
  }
}
