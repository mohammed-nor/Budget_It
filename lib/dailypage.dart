import 'package:flutter/material.dart';
import 'package:budget_it/styles and constants.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hijri/hijri_calendar.dart';

class Dailypage extends StatefulWidget {
  const Dailypage({super.key});

  @override
  State<Dailypage> createState() => _DailypageState();
}

void initState() {}

class _DailypageState extends State<Dailypage> {
  //final box = GetStorage();
  DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final prefsdata = Hive.box('data');
  @override
  Widget build(BuildContext context) {
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
    int daysDifference = NextMonthPaymentDate.difference(today).inDays;
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
    DateTime selectedDate = prefsdata.get("selectedDate", defaultValue: DateTime(2024, 9, 1));
    double fontSize1 = prefsdata.get("fontsize1", defaultValue: 15.toDouble());
    double fontSize2 = prefsdata.get("fontsize2", defaultValue: 15.toDouble());
    double calculateSavingsSoFar() {
      int daysSinceStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).difference(DateTime(startDate.year, startDate.month, startDate.day)).inDays;
      return nowcredit + mntsaving * daysSinceStart.toDouble();
    }

    DateTime ramadane = HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 9, 1);
    DateTime aidfitr = HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 10, 1);
    DateTime aidfadha = HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 12, 10);

    double calculateiningToGoal() {
      return totsaving - calculateSavingsSoFar();
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
            Text(textlabel, style: darktextstyle, textAlign: TextAlign.right),
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
                /*Text("Total Savings",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${calculateSavingsSoFar().toStringAsFixed(2)}"),
                Text("Daily Limit",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                    "${(0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12)) / daysInCurrentMonth).toStringAsFixed(2)}"),
                Text("ining to Goal",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text("\$${calculateiningToGoal().toStringAsFixed(2)}"),
                */
                const SizedBox(height: 20),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      " المبلغ المسموح إنفاقه في اليوم هو  ${((((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)))).round()} من أصل ${((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth) * (daysleftInCurrentMonth() + 1)).round()} درهم",
                      style: darktextstyle.copyWith(fontSize: fontSize1),
                      textAlign: TextAlign.center,
                    ),
                    Text("", style: darktextstyle.copyWith(fontSize: fontSize1)),
                    Text(" عدد الأيام المتبقية هو ${daysleftInCurrentMonth()} أيام ", style: darktextstyle.copyWith(fontSize: fontSize1)),
                    TableCalendar(
                      focusedDay: today,
                      firstDay: DateTime(startDate.year, startDate.month, 1),
                      lastDay: DateTime(2050, 12, 31),
                      selectedDayPredicate: (day) => isSameDay(day, today),
                      calendarFormat: CalendarFormat.month,
                      //calendarBuilders: CalendarBuilders(),
                      headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                      onDaySelected: _ondayselected,
                      calendarStyle: const CalendarStyle(weekNumberTextStyle: TextStyle(color: Color(0xFFFFFFFF)), weekendTextStyle: TextStyle(color: Color(0xFFFFFFFF))),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      " المبلغ الذي يجب أن يكون بحسابك في أول اليوم هو ${((nowcredit + (daysdiff(startDate, today)) * (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) + count30thsPassed(startDate, today) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp))).round()} درهما ",
                      style: darktextstyle.copyWith(fontSize: fontSize1),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      " المبلغ الذي وفرته هو ${(nownetcredit + count30thsPassed(startDate, today) * (mntsaving))} درهما ",
                      style: darktextstyle.copyWith(fontSize: fontSize1, color: const Color.fromRGBO(106, 253, 95, 1.0)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      totsaving - nownetcredit - count30thsPassed(startDate, today) * (mntsaving) > 0
                          ? " المبلغ الذي بقي عليك  أن توفره هو ${totsaving - nownetcredit - count30thsPassed(startDate, today) * (mntsaving)} درهما "
                          : " مبروك , لقد حققت هدفك ",
                      style: darktextstyle.copyWith(
                        fontSize: fontSize1,
                        color: totsaving - nownetcredit - count30thsPassed(startDate, today) * (mntsaving) > 0 ? const Color.fromRGBO(253, 95, 95, 1.0) : const Color.fromRGBO(106, 253, 95, 1.0),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

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
                                              daysInCurrentMonth) /
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
                                              daysInCurrentMonth))))

                              .toString(),
                          style: darktextstyle),
                      Text("عدد الأيام الإستثنائية لإنفاق المبلغ الأقصى شهريا",
                          style: darktextstyle),
                    ],
                  ),
                ),*/
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
                infocalculated((totsaving - nownetcredit) / (0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12))), "عدد أشهر الإدخار"),
                infocalculated(0.5 * ((mntinc + mntnstblinc) * (1 - freemnt / 12) - (mntexp + annexp / 12)), "أقصى ما يمكن ادخاره"),
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
                            height: 40,
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
                            height: 40,
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
                            height: 40,
                            child: Center(child: Text("(${(nownetcredit + count30thsPassed(startDate, ramadane) * (mntsaving))})", style: darktextstyle.copyWith(fontSize: fontSize1))),
                          ),
                          SizedBox(
                            height: 40,
                            child: Center(child: Text("(${(nownetcredit + count30thsPassed(startDate, aidfitr) * (mntsaving))})", style: darktextstyle.copyWith(fontSize: fontSize1))),
                          ),
                          SizedBox(
                            height: 40,
                            child: Center(child: Text("(${(nownetcredit + count30thsPassed(startDate, aidfadha) * (mntsaving))})", style: darktextstyle.copyWith(fontSize: fontSize1))),
                          ),
                        ],
                      ),
                      /*Column(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  "<=",
                                  style: darktextstyle,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  "<=",
                                  style: darktextstyle,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              child: Center(
                                child: Text(
                                  "<=",
                                  style: darktextstyle,
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
                                "${ramadane.year}-${aidfitr.month.toString().padLeft(2, '0')}-${ramadane.day.toString().padLeft(2, '0')}",
                                style: darktextstyle.copyWith(fontSize: fontSize1),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            child: Center(
                              child: Text("${aidfitr.year}-${aidfitr.month.toString().padLeft(2, '0')}-${aidfitr.day.toString().padLeft(2, '0')}", style: darktextstyle.copyWith(fontSize: fontSize1)),
                            ),
                          ),
                          SizedBox(
                            height: 40,
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
                          SizedBox(height: 40, child: Center(child: Text(":", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 40, child: Center(child: Text(":", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 40, child: Center(child: Text(":", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 40, child: Center(child: Text("(يوما", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 40, child: Center(child: Text("(يوما", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 40, child: Center(child: Text("(يوما", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 40, child: Center(child: Text("${daysdiff(DateTime.now(), ramadane).toString()})", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 40, child: Center(child: Text("${daysdiff(DateTime.now(), aidfitr).toString()})", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 40, child: Center(child: Text("${daysdiff(DateTime.now(), aidfadha).toString()})", style: darktextstyle.copyWith(fontSize: fontSize1)))),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(height: 40, child: Center(child: Text('فاتح رمضان', style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 40, child: Center(child: Text('عيد الفطر', style: darktextstyle.copyWith(fontSize: fontSize1)))),
                          SizedBox(height: 40, child: Center(child: Text('عيد الأضحى', style: darktextstyle.copyWith(fontSize: fontSize1)))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                /*OutlinedButton(
                  onPressed: () => prefsdata.deleteFromDisk(),
                  child: SizedBox(
                    width: size.width * 0.25,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Icon(Icons.restore, color: Colors.red),
                        Text("إعادة الظبط", style: darktextstyle.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                OutlinedButton(
                  onPressed: () => Get.isDarkMode ? Get.changeTheme(ThemeData.dark()) : Get.changeTheme(ThemeData.light()),
                  child: SizedBox(
                    width: size.width * 0.25,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Icon(Icons.dark_mode_outlined, color: Colors.red),
                        Text("تغيير التيم", style: darktextstyle.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ),*/
                const SizedBox(height: 40),
              ],
            ),
          ),
          Card(
            elevation: 2,
            color: cardcolor,
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
                    "${(0.5 * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12)) / daysInCurrentMonth).toStringAsFixed(2)}"),
                Text("ining to Goal",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text("\$${calculateiningToGoal().toStringAsFixed(2)}"),
                */
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
                        //height: size.height * 0.07,
                        width: size.width * 0.17 * fontSize2 / 16,
                        child: TextFormField(
                          textAlign: TextAlign.center,
                          style: darktextstyle.copyWith(fontSize: fontSize2),
                          initialValue: nowcredit.toString(),
                          decoration: InputDecoration(
                            hintStyle: darktextstyle.copyWith(fontSize: fontSize2 + 20),
                            //prefixIcon: Icon(Icons.currency_bitcoin_rounded),
                            border: OutlineInputBorder(gapPadding: 1),
                          ),
                          onChanged: (newval) {
                            //box.write('quote', 2);
                            final v = int.tryParse(newval);
                            if (v == null) {
                              setState(() {
                                pickStartDate(context);
                                prefsdata.put("nownetcredit", 0);
                                nownetcredit = prefsdata.get("nownetcredit".toString());
                                print(nownetcredit.toString() + "nownetcredit".toString());
                                //nownetcredit = 0;
                              });
                            } else {
                              setState(() {
                                pickStartDate(context);
                                prefsdata.put("nowcredit".toString(), v);
                                //prefsdata.put("nownetcredit".toString(), v - (((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth) * (daysDifference.toInt() + 1));
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
                        style: darktextstyle,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),

                moneyinput(size, mntsaving, "mntsaving", "المبلغ الشهري المرتقب إقطاعه"),

                moneyinput(size, freemnt, "freemnt", "عدد أشهر الراحة السنوية"),
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
                                              daysInCurrentMonth) /
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
                                              daysInCurrentMonth))))

                              .toString(),
                          style: darktextstyle),
                      Text("عدد الأيام الإستثنائية لإنفاق المبلغ الأقصى شهريا",
                          style: darktextstyle),
                    ],
                  ),
                ),*/
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
                const SizedBox(height: 20),
                infocalculated(-(mntsaving - 0.5 * ((mntinc + mntnstblinc) * (1 - freemnt / 12) - (mntexp + annexp / 12))), "فائض / عجز التدبير"),
                infocalculated((totsaving - nownetcredit) / mntsaving, "عدد أشهر الإدخار المثالي"),
                const SizedBox(height: 20),
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
                      Padding(padding: const EdgeInsets.all(8.0), child: Text("مبيان أشهر الإدخار", style: darktextstyle, textAlign: TextAlign.right)),
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
                Text("هيكلة المداخيل الشخصية", style: darktextstyle),
                const SizedBox(height: 20),
                moneyinput(size, mntinc, "mntinc", "المداخيل الشهرية القارة"),
                moneyinput(size, mntnstblinc, "mntnstblinc", "مداخيل شهرية غير قارة"),
                moneyinputslider(size, mntperinc, "mntperinc", "نسبة تقلبات المداخيل         "),
                const SizedBox(height: 20),
                infocalculated(0.5 * ((mntinc + mntnstblinc * (1 + mntperinc * 0.01)) * (12 - freemnt)) - (mntexp * (1 - mntperexp * 0.01) + annexp), "أقصى ما يمكن إدخاره سنويا"),
                infocalculated(0.5 * ((mntinc + mntnstblinc * (1 - mntperinc * 0.01)) * (12 - freemnt)) - (mntexp * (1 + mntperexp * 0.01) + annexp), "أقل ما يمكن إدخاره سنويا"),
                const SizedBox(height: 20),
              ],
            ),
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

  Widget moneyinput2(size, boxvariable, boxvariablename, String textlabel) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, bottom: 7, top: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            //height: size.height * 0.07,
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
          Text(textlabel, style: darktextstyle, textAlign: TextAlign.right),
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

  /*String getFirstDayOfRamadan(nowcredit,startDate,mntinc,mntnstblinc,mntperinc) {
    DateTime ramadane =
        HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 9, 1);
    DateTime aidfitr =
        HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 10, 1);
    DateTime aidfadha =
        HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 12, 10);

    return 'First day of Ramadan : ${ramadane.year}-${ramadane.month.toString().padLeft(2, '0')}-${ramadane.day.toString().padLeft(2, '0')}     =>  ${nowcredit + (ramadane.difference(startDate).inDays + 1) * -(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc) * (1 - prefsdata.get("freemnt") / 12) - (prefsdata.get("mntexp") + prefsdata.get("annexp") / 12) - (prefsdata.get("mntsaving"))) / daysInCurrentMonth) + (ramadane.month - DateTime(prefsdata.get("startDate").year, prefsdata.get("startDate").month, 29).month + 12 * (ramadane.year - prefsdata.get("selectedDate").year)) * (prefsdata.get("mntinc") - prefsdata.get("mntinc"))).toString()} \n day of aid al fitr : ${aidfitr.year}-${aidfitr.month.toString().padLeft(2, '0')}-${aidfitr.day.toString().padLeft(2, '0')}\n day of aid al adha : ${aidfadha.year}-${aidfadha.month.toString().padLeft(2, '0')}-${aidfadha.day.toString().padLeft(2, '0')}';
  }*/
}
