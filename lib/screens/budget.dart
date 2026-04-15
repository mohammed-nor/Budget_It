import 'package:flutter/material.dart';
import 'package:budget_it/services/styles%20and%20constants.dart';
import 'package:hive/hive.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart' as sfs;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:math' as math;
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:budget_it/models/budget_history.dart';
import 'package:budget_it/models/upcoming_spending.dart';
import 'package:budget_it/models/unexpected_earning.dart';
import 'package:get/get.dart';
import 'package:budget_it/utils/theme_controller.dart';
import 'package:budget_it/utils/color_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class Budgetpage extends StatefulWidget {
  const Budgetpage({super.key});

  @override
  State<Budgetpage> createState() => _BudgetpageState();
}

// Simple private model for candle chart data
class _CandleData {
  final DateTime x;
  final num open;
  final num high;
  final num low;
  final num close;

  _CandleData(this.x, this.open, this.high, this.low, this.close);
}

// Small helper model for Bollinger band points (mid = SMA, upper/lower = bands)
class _BandPoint {
  final DateTime x;
  final num? mid;
  final num? upper;
  final num? lower;

  _BandPoint(this.x, this.mid, this.upper, this.lower);
}

class _BudgetpageState extends State<Budgetpage> {
  late ThemeController themeController;
  Color cardcolor = prefsdata.get(
    "cardcolor",
    defaultValue: const Color.fromRGBO(20, 20, 20, 1.0),
  );
  DateTime today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  Box<BudgetHistory>? historyBox;
  List<BudgetHistory> budgetHistory = [];
  // Candle chart related state
  String chartGranularity = 'Day'; // 'Day', 'Week', 'Month'
  List<_CandleData> candleData = [];
  // Bollinger / display settings (exposed to UI)
  int displayCount = 40; // number of candles to display (window)
  int bbPeriod = 7; // SMA period for Bollinger
  double bbMultiplier = 1.2;
  double vv = 80;
  Box<dynamic>? chartSettingsBox;
  // Std-dev multiplier for Bollinger

  // Simple data class for candle points
  // open/high/low/close will be based on nownetcredit from BudgetHistory
  // (if there's only one point for a period, open=high=low=close)
  // The class is private to this file.
  // Note: using num for values to allow int or double

  Box<UpcomingSpending>? upcomingSpendingBox;
  List<UpcomingSpending> upcomingSpendingList = [];
  bool _isUpcomingSpendingExpanded = false;

  Box<UnexpectedEarning>? unexpectedEarningsBox;
  List<UnexpectedEarning> unexpectedEarningsList = [];
  bool _isUnexpectedEarningsExpanded = false;

  @override
  void initState() {
    super.initState();
    themeController = Get.find<ThemeController>();
    cardcolor = prefsdata.get(
      "cardcolor",
      defaultValue: const Color.fromRGBO(20, 20, 20, 1.0),
    );
    _initHistoryBox();
    _loadBudgetHistory();
    _initUpcomingSpendingBox();
    _initUnexpectedEarningsBox();
    _initChartSettings();
  }

  Future<void> _initChartSettings() async {
    chartSettingsBox = await Hive.openBox('chart_settings');
    setState(() {
      displayCount =
          chartSettingsBox?.get('displayCount', defaultValue: 40) ?? 40;
      bbPeriod = chartSettingsBox?.get('bbPeriod', defaultValue: 7) ?? 7;
      bbMultiplier =
          chartSettingsBox?.get('bbMultiplier', defaultValue: 1.2) ?? 1.2;
      vv = chartSettingsBox?.get('vv', defaultValue: 80.0) ?? 80.0;
    });
  }

  void _saveChartSetting(String key, dynamic value) {
    chartSettingsBox?.put(key, value);
  }

  Future<void> _initHistoryBox() async {
    historyBox = await Hive.openBox<BudgetHistory>('budget_history');
  }

  void _loadBudgetHistory() {
    if (historyBox != null && historyBox!.isNotEmpty) {
      setState(() {
        budgetHistory = historyBox!.values.toList();
        budgetHistory.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _generateCandleData();
      });
    } else {
      setState(() {
        budgetHistory = [];
        candleData = [];
      });
    }
  }

  // Candle data model
  // Defined here (private) so it can be used by the chart series
  // x is the period timestamp (day start, week start, or month start)
  // open/high/low/close are taken from BudgetHistory.nownetcredit

  // Private helper class for chart points
  // Placed inside the state class file scope

  void _generateCandleData() {
    // Aggregate incoming (unexpected earnings) and spending (upcoming spending)
    // by selected granularity and create candle points reflecting cumulative balance.

    // Ensure boxes are available
    final spendBox = upcomingSpendingBox;
    final earnBox = unexpectedEarningsBox;

    // Collect entries
    final List<UpcomingSpending> spends = spendBox != null
        ? spendBox.values.toList().cast<UpcomingSpending>()
        : upcomingSpendingList;
    final List<UnexpectedEarning> earns = earnBox != null
        ? earnBox.values.toList().cast<UnexpectedEarning>()
        : unexpectedEarningsList;

    // Decide periods based on focused calendar month (today)
    //DateTime firstDay = DateTime(today.year, today.month, 1);
    /*DateTime firstDay = prefsdata.get(
      "startDate",
      defaultValue: DateTime(2024, 9, 1),
    );*/
    DateTime firstDay = DateTime(
      today.year,
      today.month,
      1,
    ).subtract(const Duration(days: 140));
    DateTime lastDay = DateTime(
      today.year,
      today.month + 1,
      1,
    ).subtract(const Duration(days: 1));

    List<DateTime> periodStarts = [];

    for (int d = 0; d <= lastDay.difference(firstDay).inDays; d++) {
      periodStarts.add(firstDay.add(Duration(days: d)));
    }

    // Determine baseline cumulative balance: (not used directly in formula-based chart generation)
    // keep a copy of nowcredit and startDate for evaluating the user's opening formula per-day
    final num nowcredit = prefsdata.get("nowcredit", defaultValue: 0);
    final DateTime startDatePref = prefsdata.get(
      "startDate",
      defaultValue: DateTime(2024, 9, 1),
    );
    if (budgetHistory.isNotEmpty) {
      final earlier = budgetHistory
          .where(
            (b) =>
                b.timestamp.isBefore(firstDay) ||
                b.timestamp.isAtSameMomentAs(firstDay),
          )
          .toList();
      if (earlier.isNotEmpty) {
        earlier.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        // previously used to set a baseline; not required for formula-based opening values
      }
    }

    // compute expected daily spending from preferences (same formula used in UI)
    double daysInCurrentMonth = 30.4375;
    num mntinc = prefsdata.get("mntinc", defaultValue: 4300);
    num mntnstblinc = prefsdata.get("mntnstblinc", defaultValue: 2000);
    num mntperinc = prefsdata.get("mntperinc", defaultValue: 40);
    num freemnt = prefsdata.get("freemnt", defaultValue: 2);
    num mntexp = prefsdata.get("mntexp", defaultValue: 2000);
    num annexp = prefsdata.get("annexp", defaultValue: 7000);
    num mntsaving = prefsdata.get("mntsaving", defaultValue: 1000);

    final num dailySpending =
        ((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) *
                        (1 - freemnt / 12) -
                    (mntexp + annexp / 12) -
                    (mntsaving)) /
                daysInCurrentMonth))
            .round();

    // helper to evaluate the opening value using the exact formula provided by the user.

    num evaluateOpening(DateTime todayVar) {
      final num monthlyTerm =
          ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) *
              (1 - freemnt / 12) -
          mntexp);

      // If the requested day is before the stored start date, compute opening at
      // startDatePref then roll it back to todayVar by applying net changes that
      // happened between todayVar (earlier) and startDatePref (later).
      if (todayVar.isBefore(startDatePref)) {
        // Opening computed at startDatePref using the original formula (safe because todayVar == startDatePref is not before)
        final num openingAtStart =
            ((nowcredit +
                    calculateSpendingBetweenDates(
                      startDatePref,
                      startDatePref,
                    ) -
                    calculateEarningsBetweenDates(
                      startDatePref,
                      startDatePref,
                    ) +
                    (daysdiff(startDatePref, startDatePref)) *
                        (-dailySpending) +
                    count30thsPassed(startDatePref, startDatePref) *
                        monthlyTerm))
                .round();

        // Net changes that occurred between the earlier day (todayVar) and startDatePref
        // When moving backward in time, previous spending should be added back and previous earnings removed.
        final num spendsBetween = calculateSpendingBetweenDates(
          todayVar,
          startDatePref,
        );
        final num earnsBetween = calculateEarningsBetweenDates(
          todayVar,
          startDatePref,
        );
        final num dailyAdjust =
            (daysdiff(todayVar, startDatePref)) * (-dailySpending);
        final num thirtiethAdjust =
            count30thsPassed(todayVar, startDatePref) * monthlyTerm;

        // Apply adjustments to roll the opening back to todayVar
        final num openingAtToday =
            (openingAtStart +
                    spendsBetween -
                    earnsBetween -
                    dailyAdjust -
                    thirtiethAdjust)
                .round();

        return openingAtToday;
      }

      // Normal case: startDatePref is on-or-before todayVar — use original formula
      return ((nowcredit -
              calculateSpendingBetweenDates(startDatePref, todayVar) +
              calculateEarningsBetweenDates(startDatePref, todayVar) +
              (daysdiff(startDatePref, todayVar)) * (-dailySpending) +
              count30thsPassed(startDatePref, todayVar) * monthlyTerm))
          .round();
    }

    final List<_CandleData> generated = [];
    // cumulative baseline is no longer simulated here; opening values are computed from the formula directly

    // Precompute daily maps for spends and earns
    final Map<DateTime, num> dailySpends = {};
    final Map<DateTime, num> dailyEarns = {};
    for (var s in spends) {
      final d = DateTime(s.date.year, s.date.month, s.date.day);
      dailySpends[d] = (dailySpends[d] ?? 0) + s.amount;
    }
    for (var e in earns) {
      final d = DateTime(e.date.year, e.date.month, e.date.day);
      dailyEarns[d] = (dailyEarns[d] ?? 0) + e.amount;
    }

    for (var start in periodStarts) {
      DateTime previousday = start.subtract(const Duration(days: 1));
      // We'll use the period start date as the 'today' variable when evaluating the requested formulas.
      // simulate day-by-day from start to overlapEnd (inclusive) applying:
      // - daily unexpected earns/spends
      // - monthly income on day 30 (mntinc)
      // - monthly expense on day 1 (mntexp)
      // overlapEnd no longer required for the simplified open/close computation
      // Compute open/close per the user's requested formulas. The 'today' variable in the formula
      // is set to the period start (for daily granularity that's the day itself). We iterate days
      // when building periodStarts, so start represents the day to use as `today`.
      final num open = evaluateOpening(previousday);
      final num close = evaluateOpening(start)
      /* +
          calculateEarningsBetweenDates(previousday, start) -
          calculateSpendingBetweenDates(previousday, start) -
          dailySpending*/
      ; // per user: close is the rounded daily spending value
      num high = close > open ? close : open;
      num low = close < open ? close : open;

      // Note: we still want the chart to reflect one-off earns/spends and monthly scheduled events,
      // but the user requested specific formulas for open/close. To keep intra-period extremes simple
      // we derive high/low from open/close. If you prefer incorporating daily one-offs into high/low,
      // I can simulate each day and recompute high/low accordingly.

      generated.add(_CandleData(start, open, high, low, close));

      // no cumulative baseline update required for this representation
    }

    setState(() {
      candleData = generated;
    });
  }

  Future<void> _initUpcomingSpendingBox() async {
    upcomingSpendingBox = await Hive.openBox<UpcomingSpending>(
      'upcoming_spending',
    );
    _loadUpcomingSpending();
  }

  void _loadUpcomingSpending() {
    if (upcomingSpendingBox != null && upcomingSpendingBox!.isNotEmpty) {
      setState(() {
        upcomingSpendingList = upcomingSpendingBox!.values.toList();
        // Sort by newest date first
        upcomingSpendingList.sort((a, b) => b.date.compareTo(a.date));
        // regenerate chart data after loading spendings
        _generateCandleData();
      });
    }
  }

  Future<void> _initUnexpectedEarningsBox() async {
    unexpectedEarningsBox = await Hive.openBox<UnexpectedEarning>(
      'unexpected_earnings',
    );
    _loadUnexpectedEarnings();
  }

  void _loadUnexpectedEarnings() {
    if (unexpectedEarningsBox != null && unexpectedEarningsBox!.isNotEmpty) {
      setState(() {
        unexpectedEarningsList = unexpectedEarningsBox!.values.toList();
        // Sort by newest date first
        unexpectedEarningsList.sort((a, b) => b.date.compareTo(a.date));
        // regenerate chart data after loading earnings
        _generateCandleData();
      });
    }
  }

  num calculateSpendingBetweenDates(DateTime startDate, DateTime endDate) {
    if (upcomingSpendingBox == null || upcomingSpendingBox!.isEmpty) {
      return 0;
    }

    final spendingEntries = upcomingSpendingBox!.values
        .where(
          (entry) =>
              (entry.date.isAfter(startDate) ||
                  entry.date.isAtSameMomentAs(startDate)) &&
              (entry.date.isBefore(endDate) ||
                  entry.date.isAtSameMomentAs(endDate)),
        )
        .toList();

    if (spendingEntries.isEmpty) {
      return 0;
    }

    num totalSpending = 0;
    for (var entry in spendingEntries) {
      totalSpending += entry.amount;
    }

    return totalSpending;
  }

  num calculateEarningsBetweenDates(DateTime startDate, DateTime endDate) {
    if (unexpectedEarningsBox == null || unexpectedEarningsBox!.isEmpty) {
      return 0;
    }

    final earningEntries = unexpectedEarningsBox!.values
        .where(
          (entry) =>
              (entry.date.isAfter(startDate) ||
                  entry.date.isAtSameMomentAs(startDate)) &&
              (entry.date.isBefore(endDate) ||
                  entry.date.isAtSameMomentAs(endDate)),
        )
        .toList();

    if (earningEntries.isEmpty) {
      return 0;
    }

    num totalEarnings = 0;
    for (var entry in earningEntries) {
      totalEarnings += entry.amount;
    }

    return totalEarnings;
  }

  void _saveCurrentState() {
    if (historyBox != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final todayEntry = historyBox!.values
          .where(
            (entry) =>
                entry.timestamp.year == today.year &&
                entry.timestamp.month == today.month &&
                entry.timestamp.day == today.day,
          )
          .toList();

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

  Widget moneyinput(size, boxvariable, boxvariablename, String textlabel) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, right: 5, bottom: 7, top: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 50 * fontSize2 / 16,
            width: size.width * 0.17 * fontSize2 / 16,
            child: TextFormField(
              textAlign: TextAlign.center,
              style: themedTextStyle(fontSize: fontSize2),
              initialValue: boxvariable.toString(),
              decoration: InputDecoration(
                hintStyle: themedTextStyle(fontSize: fontSize2),
                border: OutlineInputBorder(gapPadding: 1),
              ),
              onChanged: (newval) {
                final v = int.tryParse(newval);
                if (v == null) {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename, 0);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                    _saveCurrentState();
                  });
                } else {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename.toString(), v);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                    _saveCurrentState();
                  });
                }
              },
              keyboardType: TextInputType.number,
            ),
          ),
          Text(
            textlabel,
            style: darktextstyle.copyWith(fontSize: fontSize2),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingSpendingCard(BuildContext context) {
    return Card(
      elevation: 5,
      color: prefsdata.get(
        "cardcolor",
        defaultValue: Color.fromRGBO(20, 20, 20, 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (upcomingSpendingList.length > 3)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isUpcomingSpendingExpanded =
                                !_isUpcomingSpendingExpanded;
                          });
                        },
                        icon: Icon(
                          _isUpcomingSpendingExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.white70,
                        ),
                        tooltip: _isUpcomingSpendingExpanded
                            ? "عرض أقل"
                            : "عرض المزيد",
                      ),
                    ElevatedButton.icon(
                      onPressed: _showAddSpendingDialog,
                      icon: const Icon(Icons.add),
                      label: Text(
                        "",
                        style: darktextstyle.copyWith(fontSize: fontSize1),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.error.withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  "مصاريف غير قارة",
                  style: themedTextStyle(
                    fontSize: fontSize1 * 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            upcomingSpendingList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      "لا توجد مصاريف قادمة مسجلة",
                      style: themedTextStyle(fontSize: fontSize1),
                    ),
                  )
                : (() {
                    final sortedList = upcomingSpendingList.toList()
                      ..sort((a, b) => b.date.compareTo(a.date));
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _isUpcomingSpendingExpanded
                          ? sortedList.length
                          : (sortedList.length > 3 ? 3 : sortedList.length),
                      itemBuilder: (context, index) {
                        final item = sortedList[index];
                        final daysUntil = item.date
                            .difference(DateTime.now())
                            .inDays;

                        return Card(
                          color: const Color.fromRGBO(40, 40, 40, 0.1),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _deleteUpcomingSpending(item.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        200,
                                        50,
                                        50,
                                        0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        item.title,
                                        style: darktextstyle.copyWith(
                                          fontSize: fontSize1,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}",
                                            style: darktextstyle.copyWith(
                                              fontSize: fontSize1 * 0.85,
                                            ),
                                          ),
                                          Text(
                                            "${daysUntil < 0 ? 'متأخر بـ ${-daysUntil}' : 'متبقي $daysUntil'} يوم",
                                            style: themedTextStyle(
                                              fontSize: fontSize1 * 0.85,
                                              color: daysUntil < 0
                                                  ? Colors.red[300]
                                                  : daysUntil < 7
                                                  ? Colors.orange[300]
                                                  : Colors.green[300],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                      30,
                                      30,
                                      30,
                                      1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${item.amount} درهم",
                                    style: themedTextStyle(
                                      fontSize: fontSize1,
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromRGBO(
                                        253,
                                        95,
                                        95,
                                        1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  })(),
          ],
        ),
      ),
    );
  }

  void _showAddSpendingDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.center,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  controller: titleController,
                  style: themedTextStyle(),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: "عنوان المصروف",
                    labelStyle: themedTextStyle(color: Colors.grey),
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: amountController,
                  style: darktextstyle,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "المبلغ (درهم)",
                    labelStyle: darktextstyle.copyWith(color: Colors.grey),
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        Text(
                          "التاريخ: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                          style: darktextstyle,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(
                              50,
                              50,
                              50,
                              1.0,
                            ),
                          ),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Color.fromRGBO(
                                        106,
                                        253,
                                        95,
                                        1.0,
                                      ),
                                      surface: Color.fromRGBO(30, 30, 30, 1.0),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: const Text("اختر التاريخ"),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 253, 95, 95),
              ),

              child: Text("إلغاء", style: themedTextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(106, 253, 95, 1.0),
              ),
              child: Text("إضافة", style: themedTextStyle(color: Colors.black)),
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  _addUpcomingSpending(
                    titleController.text,
                    num.tryParse(amountController.text) ?? 0,
                    selectedDate,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
          shadowColor: Colors.black54,
        );
      },
    );
  }

  void _addUpcomingSpending(String title, num amount, DateTime date) {
    if (upcomingSpendingBox != null) {
      final newSpending = UpcomingSpending(
        title: title,
        amount: amount,
        date: date,
      );

      upcomingSpendingBox!.add(newSpending);

      setState(() {
        upcomingSpendingList = upcomingSpendingBox!.values.toList();
        upcomingSpendingList.sort((a, b) => b.date.compareTo(a.date));
        // refresh chart to reflect the newly added spending
        _generateCandleData();
      });
    }
  }

  void _deleteUpcomingSpending(String id) {
    if (upcomingSpendingBox != null) {
      final int index = upcomingSpendingBox!.values.toList().indexWhere(
        (item) => item.id == id,
      );

      if (index >= 0) {
        upcomingSpendingBox!.deleteAt(index);

        setState(() {
          upcomingSpendingList = upcomingSpendingBox!.values.toList();
          upcomingSpendingList.sort((a, b) => b.date.compareTo(a.date));
          // refresh chart after deleting a spending
          _generateCandleData();
        });
      }
    }
  }

  Widget _buildUnexpectedEarningsCard(BuildContext context) {
    return Card(
      elevation: 5,
      color: prefsdata.get(
        "cardcolor",
        defaultValue: Color.fromRGBO(20, 20, 20, 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (unexpectedEarningsList.length > 3)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _isUnexpectedEarningsExpanded =
                                !_isUnexpectedEarningsExpanded;
                          });
                        },
                        icon: Icon(
                          _isUnexpectedEarningsExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.white70,
                        ),
                        tooltip: _isUnexpectedEarningsExpanded
                            ? "عرض أقل"
                            : "عرض المزيد",
                      ),
                    ElevatedButton.icon(
                      onPressed: _showAddEarningDialog,
                      icon: const Icon(Icons.add),
                      label: Text(
                        "",
                        style: darktextstyle.copyWith(fontSize: fontSize1),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  "مداخيل غير قارة",
                  style: themedTextStyle(
                    fontSize: fontSize1 * 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Divider then full list of unexpected earnings (existing UX)
            const SizedBox(height: 8),

            unexpectedEarningsList.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "لا توجد مداخيل غير متوقعة مسجلة",
                      style: themedTextStyle(fontSize: fontSize1),
                    ),
                  )
                : (() {
                    final sortedList = unexpectedEarningsList.toList()
                      ..sort((a, b) => b.date.compareTo(a.date));
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _isUnexpectedEarningsExpanded
                          ? sortedList.length
                          : (sortedList.length > 3 ? 3 : sortedList.length),
                      itemBuilder: (context, index) {
                        final item = sortedList[index];
                        final daysAgo = DateTime.now()
                            .difference(item.date)
                            .inDays;

                        return Card(
                          color: const Color.fromRGBO(40, 50, 40, 0.2),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Delete button
                                GestureDetector(
                                  onTap: () =>
                                      _deleteUnexpectedEarning(item.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        200,
                                        50,
                                        50,
                                        0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Item details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        item.title,
                                        style: themedTextStyle(
                                          fontSize: fontSize1,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}",
                                            style: themedTextStyle(
                                              fontSize: fontSize1 * 0.85,
                                            ),
                                          ),
                                          Text(
                                            daysAgo == 0
                                                ? "اليوم"
                                                : daysAgo == 1
                                                ? "بالأمس"
                                                : "منذ $daysAgo يوم",
                                            style: themedTextStyle(
                                              fontSize: fontSize1 * 0.85,
                                              color: daysAgo < 3
                                                  ? Colors.green[300]
                                                  : Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Amount
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(
                                      30,
                                      50,
                                      30,
                                      1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${item.amount} درهم",
                                    style: themedTextStyle(
                                      fontSize: fontSize1,
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromRGBO(
                                        106,
                                        253,
                                        95,
                                        1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  })(),
          ],
        ),
      ),
    );
  }

  void _showAddEarningDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(30, 40, 30, 1.0),
          title: Text(
            "إضافة دخل غير متوقع",
            style: themedTextStyle(fontSize: fontSize1 * 1.2),
            textAlign: TextAlign.right,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title field
                TextField(
                  controller: titleController,
                  style: themedTextStyle(),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: "مصدر الدخل",
                    labelStyle: themedTextStyle(color: Colors.grey),
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Amount field
                TextField(
                  controller: amountController,
                  style: darktextstyle,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "المبلغ (درهم)",
                    labelStyle: darktextstyle.copyWith(color: Colors.grey),
                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                // Date picker
                StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      children: [
                        Text(
                          "التاريخ: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
                          style: themedTextStyle(),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(
                              40,
                              80,
                              40,
                              1.0,
                            ),
                          ),
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: Color.fromRGBO(
                                        106,
                                        253,
                                        95,
                                        1.0,
                                      ),
                                      surface: Color.fromRGBO(30, 40, 30, 1.0),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: const Text("اختر التاريخ"),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromRGBO(253, 95, 95, 1.0),
              ),
              child: Text("إلغاء", style: themedTextStyle()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(106, 253, 95, 1.0),
              ),
              child: Text("إضافة", style: themedTextStyle(color: Colors.black)),
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  _addUnexpectedEarning(
                    titleController.text,
                    num.tryParse(amountController.text) ?? 0,
                    selectedDate,
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _addUnexpectedEarning(String title, num amount, DateTime date) {
    if (unexpectedEarningsBox != null) {
      final newEarning = UnexpectedEarning(
        title: title,
        amount: amount,
        date: date,
      );

      unexpectedEarningsBox!.add(newEarning);

      setState(() {
        unexpectedEarningsList = unexpectedEarningsBox!.values.toList();
        unexpectedEarningsList.sort(
          (a, b) => b.date.compareTo(a.date),
        ); // Sort by newest first
        // refresh chart to include the new earning
        _generateCandleData();
      });
    }
  }

  void _deleteUnexpectedEarning(String id) {
    if (unexpectedEarningsBox != null) {
      final int index = unexpectedEarningsBox!.values.toList().indexWhere(
        (item) => item.id == id,
      );

      if (index >= 0) {
        unexpectedEarningsBox!.deleteAt(index);

        setState(() {
          unexpectedEarningsList = unexpectedEarningsBox!.values.toList();
          unexpectedEarningsList.sort((a, b) => b.date.compareTo(a.date));
          // refresh chart after removing an earning
          _generateCandleData();
        });
      }
    }
  }

  String _getArabicMonthName(int month) {
    const months = [
      '',
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'ماي',
      'يونيو',
      'يوليوز',
      'غشت',
      'شتنبر',
      'أكتوبر',
      'نونبر',
      'دجنبر',
    ];
    return month > 0 && month < months.length ? months[month] : '';
  }

  TextStyle themedTextStyle({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
  }) {
    final isDark = themeController.isDarkMode.value;
    return GoogleFonts.elMessiri(
      fontWeight: fontWeight ?? FontWeight.w700,
      fontSize:
          fontSize ?? prefsdata.get("fontsize2", defaultValue: 15.toDouble()),
      color:
          color ??
          (isDark ? ColorTheme.darkTextPrimary : ColorTheme.lightTextPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    double fontSize1 = prefsdata.get("fontsize1", defaultValue: 15.toDouble());
    double fontSize2 = prefsdata.get("fontsize2", defaultValue: 15.toDouble());
    // Next/This month payment date calculations removed (not used).
    int daysleftInCurrentMonth() {
      int payingDay = prefsdata.get("payingDay", defaultValue: 30);

      // Target for the current month
      int lastDayThisMonth = DateTime(today.year, today.month + 1, 0).day;
      int targetDayThisMonth = payingDay > lastDayThisMonth
          ? lastDayThisMonth
          : payingDay;
      DateTime targetDateThisMonth = DateTime(
        today.year,
        today.month,
        targetDayThisMonth,
      );

      if (!today.isAfter(targetDateThisMonth)) {
        return targetDateThisMonth.difference(today).inDays;
      } else {
        // Target for the next month
        int nextMonth = today.month + 1;
        int nextYear = today.year;
        if (nextMonth > 12) {
          nextMonth = 1;
          nextYear++;
        }
        int lastDayNextMonth = DateTime(nextYear, nextMonth + 1, 0).day;
        int targetDayNextMonth = payingDay > lastDayNextMonth
            ? lastDayNextMonth
            : payingDay;
        DateTime targetDateNextMonth = DateTime(
          nextYear,
          nextMonth,
          targetDayNextMonth,
        );
        return targetDateNextMonth.difference(today).inDays;
      }
    }

    //int daysInCurrentMonth = NextMonthPaymentDate.difference(ThisMonthPaymentDate).inDays;
    double daysInCurrentMonth = 30.4375;
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
    DateTime startDate = prefsdata.get(
      "startDate",
      defaultValue: DateTime(2024, 9, 1),
    );

    DateTime ramadane =
        HijriCalendar()
                .hijriToGregorian(HijriCalendar.now().hYear, 9, 1)
                .difference(
                  HijriCalendar().hijriToGregorian(
                    HijriCalendar.now().hYear,
                    HijriCalendar.now().hMonth,
                    HijriCalendar.now().hDay,
                  ),
                )
                .inDays >
            1
        ? HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 9, 1)
        : HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear + 1, 9, 1);
    DateTime aidfitr =
        HijriCalendar()
                .hijriToGregorian(HijriCalendar.now().hYear, 10, 1)
                .difference(
                  HijriCalendar().hijriToGregorian(
                    HijriCalendar.now().hYear,
                    HijriCalendar.now().hMonth,
                    HijriCalendar.now().hDay,
                  ),
                )
                .inDays >
            1
        ? HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 10, 1)
        : HijriCalendar().hijriToGregorian(
            HijriCalendar.now().hYear + 1,
            10,
            1,
          );
    DateTime aidfadha =
        HijriCalendar()
                .hijriToGregorian(HijriCalendar.now().hYear, 12, 10)
                .difference(
                  HijriCalendar().hijriToGregorian(
                    HijriCalendar.now().hYear,
                    HijriCalendar.now().hMonth,
                    HijriCalendar.now().hDay,
                  ),
                )
                .inDays >
            1
        ? HijriCalendar().hijriToGregorian(HijriCalendar.now().hYear, 12, 10)
        : HijriCalendar().hijriToGregorian(
            HijriCalendar.now().hYear + 1,
            12,
            10,
          );
    Widget moneyinput(size, boxvariable, boxvariablename, String textlabel) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
          border: Border.all(
            color: const Color.fromRGBO(106, 253, 95, 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 48 * fontSize2 / 16,
                  width: size.width * 0.2 * fontSize2 / 16,
                  child: TextFormField(
                    textAlign: TextAlign.center,
                    style: darktextstyle.copyWith(
                      fontSize: fontSize2,
                      fontWeight: FontWeight.bold,
                    ),
                    initialValue: boxvariable.toString(),
                    decoration: InputDecoration(
                      hintStyle: darktextstyle.copyWith(
                        fontSize: fontSize2,
                        color: Colors.grey[600],
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(80, 80, 80, 1.0),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(106, 253, 95, 0.7),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: const Color.fromRGBO(25, 25, 25, 1.0),
                    ),
                    onChanged: (newval) {
                      final v = int.tryParse(newval);
                      if (v == null) {
                        setState(() {
                          pickStartDate(context);
                          prefsdata.put(boxvariablename, 0);
                          boxvariable = prefsdata.get(
                            boxvariablename.toString(),
                          );
                          _saveCurrentState();
                        });
                      } else {
                        setState(() {
                          pickStartDate(context);
                          prefsdata.put(boxvariablename.toString(), v);
                          boxvariable = prefsdata.get(
                            boxvariablename.toString(),
                          );
                          _saveCurrentState();
                        });
                      }
                    },
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[800]!, width: 0.5),
              ),
              child: Text(
                textlabel,
                style: darktextstyle.copyWith(
                  fontSize: fontSize2,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      //backgroundColor: Colors.black,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.all(7),
        children: <Widget>[
          Card(
            elevation: 2,
            //color: Theme.of(context).cardColor,
            color: prefsdata.get(
              "cardcolor",
              defaultValue: Color.fromRGBO(20, 20, 20, 1.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 00,
                        horizontal: 10.0,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromARGB(10, 45, 45, 45),
                            const Color.fromARGB(125, 35, 35, 35),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ],
                        border: Border.all(
                          color: const Color.fromRGBO(106, 253, 95, 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                          106,
                                          253,
                                          95,
                                          0.15,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet,
                                        color: Color.fromRGBO(
                                          106,
                                          253,
                                          95,
                                          1.0,
                                        ),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "المبلغ المسموح في اليوم",
                                          style: themedTextStyle(
                                            fontSize: fontSize1 * 0.7,
                                          ),
                                        ),
                                        Text(
                                          "${((((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)))).round()} درهم",
                                          style: themedTextStyle(
                                            fontSize: fontSize1 * 1.7,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "المبلغ الإجمالي المتبقي",
                                      style: themedTextStyle(
                                        fontSize: fontSize1 * 0.7,
                                      ),
                                    ),
                                    Text(
                                      "${((((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth) * (daysleftInCurrentMonth() + 1)).round()} درهم",
                                      style: themedTextStyle(
                                        fontSize: fontSize1 * 1.7,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            const Divider(
                              height: 1,
                              color: Color.fromRGBO(80, 80, 80, 0.5),
                            ),
                            const SizedBox(height: 14),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.amber.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: Colors.amber[300],
                                        size: 18,
                                      ),
                                      Text(
                                        "    ${daysleftInCurrentMonth()}",
                                        style: darktextstyle.copyWith(
                                          fontSize: fontSize1,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber[300],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(child: SizedBox(width: 5)),
                                Text(
                                  "عدد الأيام المتبقية للأجرة ",
                                  style: themedTextStyle(fontSize: fontSize1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    TableCalendar(
                      focusedDay: today,
                      rowHeight: 45,
                      firstDay: DateTime(startDate.year, startDate.month, 1),
                      lastDay: DateTime(2050, 12, 31),
                      selectedDayPredicate: (day) => isSameDay(day, today),
                      calendarFormat: CalendarFormat.month,

                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                      ),
                      onDaySelected: _ondayselected,
                      calendarStyle: CalendarStyle(
                        weekNumberTextStyle: themedTextStyle(
                          fontSize: fontSize1,
                        ),

                        weekendTextStyle: themedTextStyle(
                          fontSize: fontSize1,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE82064),
                        ),
                        outsideTextStyle: themedTextStyle(
                          color: const Color(0xFFBEBEBE),
                        ),
                        todayDecoration: const BoxDecoration(
                          color: Color(0xFFE696B2),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: themedTextStyle(
                          color: Color(0xFFFAFAFA),
                          fontSize: fontSize1,
                          fontWeight: FontWeight.w900,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: Color(0xFFE82064),
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: themedTextStyle(
                          color: Color(0xFFFAFAFA),
                          fontSize: fontSize1,
                          fontWeight: FontWeight.w900,
                        ),
                        defaultTextStyle: themedTextStyle(
                          fontSize: fontSize1,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                    //Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromARGB(10, 45, 45, 45),
                            const Color.fromARGB(125, 35, 35, 35),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                        border: Border.all(
                          color: const Color.fromRGBO(106, 253, 95, 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(37, 95, 169, 253),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.credit_card,
                                color: Color.fromARGB(255, 154, 156, 255),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "المبلغ عندك في أول اليوم هو ",
                                    style: themedTextStyle(fontSize: fontSize1),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${((nowcredit - calculateSpendingBetweenDates(startDate, today) + calculateEarningsBetweenDates(startDate, today) + (daysdiff(startDate, today)) * (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) + count30thsPassed(startDate, today) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp))).round()} درهما",
                                    style: themedTextStyle(
                                      fontSize: fontSize1 * 1.2,
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromARGB(
                                        255,
                                        154,
                                        156,
                                        255,
                                      ),
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Divider(height: 21)),

                    // (controls moved below the chart; kept for UI but relocated)

                    // Compute Bollinger Bands (SMA + stddev * multiplier)
                    // We do this locally in the build method using existing candleData.close values
                    // without changing any existing open/high/low/close calculations.
                    Builder(
                      builder: (context) {
                        final int bbP = bbPeriod;
                        final double bbM = bbMultiplier;
                        final int dispCount = displayCount;

                        // Compute bands over the full candleData (do NOT change calculation logic)
                        final List<_BandPoint> fullBandData = [];
                        if (candleData.isNotEmpty) {
                          final closesFull = candleData
                              .map((c) => c.close.toDouble())
                              .toList();
                          for (int i = 0; i < candleData.length; i++) {
                            if (i >= bbP - 1) {
                              final window = closesFull.sublist(
                                i - (bbP - 1),
                                i + 1,
                              );
                              final mean =
                                  window.reduce((a, b) => a + b) /
                                  window.length;
                              final variance =
                                  window
                                      .map((v) => (v - mean) * (v - mean))
                                      .reduce((a, b) => a + b) /
                                  window.length;
                              final sd = math.sqrt(variance);
                              final up = mean + bbM * sd;
                              final low = mean - bbM * sd;
                              fullBandData.add(
                                _BandPoint(candleData[i].x, mean, up, low),
                              );
                            } else {
                              fullBandData.add(
                                _BandPoint(candleData[i].x, null, null, null),
                              );
                            }
                          }
                        }

                        // Choose the last `dispCount` candles for plotting (do NOT modify original data)
                        final List<_CandleData> displayCandles =
                            candleData.length > dispCount
                            ? candleData.sublist(candleData.length - dispCount)
                            : List<_CandleData>.from(candleData);

                        // Align band points to the displayed window by slicing the fullBandData
                        final int startIndex = math.max(
                          0,
                          candleData.length - dispCount,
                        );
                        final List<_BandPoint> bandData =
                            fullBandData.length > startIndex
                            ? fullBandData.sublist(startIndex)
                            : fullBandData.isEmpty
                            ? <_BandPoint>[]
                            : List<_BandPoint>.from(fullBandData);

                        return SizedBox(
                          height: 400,
                          child: displayCandles.isEmpty
                              ? Center(
                                  child: Text(
                                    'لا توجد بيانات تاريخية كافية',
                                    style: darktextstyle.copyWith(),
                                  ),
                                )
                              : SfCartesianChart(
                                  primaryXAxis: DateTimeAxis(
                                    dateFormat: DateFormat('d MMM'),
                                    intervalType: DateTimeIntervalType.days,
                                    interval: 7,
                                    majorGridLines: const MajorGridLines(
                                      width: 1,
                                      color: Color.fromRGBO(200, 200, 200, 0.1),
                                    ),
                                    edgeLabelPlacement:
                                        EdgeLabelPlacement.shift,
                                  ),
                                  primaryYAxis: NumericAxis(
                                    minimum:
                                        displayCandles
                                            .map((c) => c.low)
                                            .fold<num>(
                                              double.infinity,
                                              (min, v) => v < min ? v : min,
                                            ) -
                                        1500,
                                    maximum:
                                        displayCandles
                                            .map((c) => c.high)
                                            .fold<num>(
                                              double.negativeInfinity,
                                              (max, v) => v > max ? v : max,
                                            ) +
                                        1500,
                                  ),
                                  tooltipBehavior: TooltipBehavior(
                                    enable: true,
                                  ),
                                  series: <CartesianSeries<dynamic, DateTime>>[
                                    // original candle series (unchanged)
                                    CandleSeries<_CandleData, DateTime>(
                                      dataSource: displayCandles,
                                      xValueMapper: (_CandleData data, _) =>
                                          data.x,
                                      lowValueMapper: (_CandleData data, _) =>
                                          data.low,
                                      highValueMapper: (_CandleData data, _) =>
                                          data.high,
                                      openValueMapper: (_CandleData data, _) =>
                                          data.open,
                                      closeValueMapper: (_CandleData data, _) =>
                                          data.close,
                                      enableTooltip: true,
                                      pointColorMapper: (_CandleData data, _) {
                                        if (isSameDay(data.x, today)) {
                                          return const Color.fromARGB(
                                            255,
                                            255,
                                            191,
                                            0,
                                          );
                                        }
                                        return data.close >= data.open
                                            ? const Color.fromRGBO(
                                                106,
                                                253,
                                                95,
                                                1.0,
                                              )
                                            : const Color.fromRGBO(
                                                253,
                                                95,
                                                95,
                                                1.0,
                                              );
                                      },
                                      bearColor: const Color.fromRGBO(
                                        253,
                                        95,
                                        95,
                                        1.0,
                                      ),
                                      bullColor: const Color.fromRGBO(
                                        106,
                                        253,
                                        95,
                                        1.0,
                                      ),
                                    ),

                                    // Bollinger middle line (SMA)
                                    LineSeries<_BandPoint, DateTime>(
                                      dataSource: bandData,
                                      xValueMapper: (_BandPoint d, _) => d.x,
                                      yValueMapper: (_BandPoint d, _) => d.mid,
                                      color: const Color.fromRGBO(
                                        255,
                                        165,
                                        0,
                                        1.0,
                                      ),
                                      width: 2,
                                      name: 'SMA',
                                    ),

                                    // Bollinger shaded area between upper and lower bands
                                    RangeAreaSeries<_BandPoint, DateTime>(
                                      dataSource: bandData,
                                      xValueMapper: (_BandPoint d, _) => d.x,
                                      lowValueMapper: (_BandPoint d, _) =>
                                          d.lower,
                                      highValueMapper: (_BandPoint d, _) =>
                                          d.upper,
                                      color: const Color.fromRGBO(
                                        255,
                                        165,
                                        0,
                                        0.15,
                                      ),
                                      borderColor: const Color.fromRGBO(
                                        255,
                                        165,
                                        0,
                                        0.5,
                                      ),
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),

                    // Collapsible controls: moved under the chart
                    ExpansionTile(
                      //backgroundcolor: prefsdata.get(        "cardcolor",        defaultValue: Color.fromRGBO(20, 20, 20, 1.0),      ),
                      //collapsedBackgroundcolor: prefsdata.get(        "cardcolor",        defaultValue: Color.fromRGBO(20, 20, 20, 1.0),      ),
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: 1.0,
                        vertical: 0,
                      ),
                      title: Center(
                        child: Text(
                          'مبيان التغييرات',
                          style: darktextstyle.copyWith(fontSize: fontSize1),
                        ),
                      ),
                      initiallyExpanded: false,
                      showTrailingIcon: false,
                      expandedCrossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            //decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: cardcolor.withOpacity(0.05), border: Border.all(color: Colors.grey[800]!, width: 0.5)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,

                              children: [
                                SizedBox(height: 5),

                                Text(
                                  ' عدد الأيام ',
                                  style: darktextstyle.copyWith(
                                    fontSize: fontSize1 * 0.9,
                                  ),
                                ),
                                sfs.SfSlider(
                                  min: 5.0,
                                  max: 105.0,
                                  interval: 20,
                                  showTicks: true,
                                  showLabels: true,
                                  enableTooltip: true,
                                  value: displayCount.toDouble(),
                                  onChanged: (dynamic newValue) {
                                    setState(() {
                                      displayCount = (newValue as double)
                                          .round();
                                      _saveChartSetting(
                                        'displayCount',
                                        displayCount,
                                      );
                                    });
                                  },
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'فترة التعافي',
                                  style: darktextstyle.copyWith(
                                    fontSize: fontSize1 * 0.9,
                                  ),
                                  //textDirection: TextDirection.rtl,
                                ),
                                sfs.SfSlider(
                                  min: 1.0,
                                  max: 31.0,
                                  interval: 2,
                                  showTicks: true,
                                  showLabels: true,
                                  value: bbPeriod.toDouble(),
                                  onChanged: (dynamic newValue) {
                                    setState(() {
                                      bbPeriod = (newValue as double).round();
                                      _saveChartSetting('bbPeriod', bbPeriod);
                                    });
                                  },
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'معامل الحرص',
                                  style: darktextstyle.copyWith(
                                    fontSize: fontSize1 * 0.9,
                                  ),
                                  //textDirection: TextDirection.rtl,
                                ),
                                sfs.SfSlider(
                                  min: 0.0,
                                  max: 100.0,
                                  interval: 20,
                                  showTicks: true,
                                  showLabels: true,
                                  value: vv,
                                  onChanged: (dynamic newValue) {
                                    setState(() {
                                      vv = newValue as double;
                                      bbMultiplier =
                                          ((100 - vv) * 3.5 / 100 + 0.5);
                                      _saveChartSetting('vv', vv);
                                      _saveChartSetting(
                                        'bbMultiplier',
                                        bbMultiplier,
                                      );
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Divider(height: 21),
                    ),

                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromARGB(10, 45, 45, 45),
                            const Color.fromARGB(125, 35, 35, 35),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                        border: Border.all(
                          color: const Color.fromRGBO(106, 253, 95, 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(106, 253, 95, 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.savings,
                                color: Color.fromRGBO(106, 253, 95, 1.0),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "المبلغ الذي وفرته",
                                    style: themedTextStyle(fontSize: fontSize1),

                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${(nownetcredit - calculateSpendingBetweenDates(startDate, today) + calculateEarningsBetweenDates(startDate, today) + count30thsPassed(startDate, today) * (mntsaving))} درهما",
                                    style: darktextstyle.copyWith(
                                      fontSize: fontSize1 * 1.2,
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromRGBO(
                                        106,
                                        253,
                                        95,
                                        1.0,
                                      ),
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromARGB(10, 45, 45, 45),
                            const Color.fromARGB(125, 35, 35, 35),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                        border: Border.all(
                          color:
                              totsaving -
                                      nownetcredit -
                                      count30thsPassed(startDate, today) *
                                          (mntsaving) >
                                  0
                              ? const Color.fromRGBO(253, 95, 95, 0.3)
                              : const Color.fromRGBO(106, 253, 95, 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    totsaving -
                                            nownetcredit -
                                            count30thsPassed(startDate, today) *
                                                (mntsaving) >
                                        0
                                    ? const Color.fromRGBO(253, 95, 95, 0.15)
                                    : const Color.fromRGBO(106, 253, 95, 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                totsaving -
                                            nownetcredit -
                                            count30thsPassed(startDate, today) *
                                                (mntsaving) >
                                        0
                                    ? Icons.track_changes
                                    : Icons.emoji_events,
                                color:
                                    totsaving -
                                            nownetcredit -
                                            count30thsPassed(startDate, today) *
                                                (mntsaving) >
                                        0
                                    ? const Color.fromRGBO(253, 95, 95, 1.0)
                                    : const Color.fromRGBO(106, 253, 95, 1.0),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    totsaving -
                                                calculateSpendingBetweenDates(
                                                  startDate,
                                                  today,
                                                ) +
                                                calculateEarningsBetweenDates(
                                                  startDate,
                                                  today,
                                                ) -
                                                nownetcredit -
                                                count30thsPassed(
                                                      startDate,
                                                      today,
                                                    ) *
                                                    (mntsaving) >
                                            0
                                        ? "المبلغ المتبقي للهدف"
                                        : "تهانينا!",
                                    style: themedTextStyle(fontSize: fontSize1),
                                    textAlign: TextAlign.right,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    totsaving +
                                                calculateEarningsBetweenDates(
                                                  startDate,
                                                  today,
                                                ) -
                                                calculateSpendingBetweenDates(
                                                  startDate,
                                                  today,
                                                ) -
                                                nownetcredit -
                                                count30thsPassed(
                                                      startDate,
                                                      today,
                                                    ) *
                                                    (mntsaving) >
                                            0
                                        ? "${totsaving - calculateEarningsBetweenDates(startDate, today) + calculateSpendingBetweenDates(startDate, today) - nownetcredit - count30thsPassed(startDate, today) * (mntsaving)} درهما"
                                        : "مبروك، لقد حققت هدفك!",
                                    style: darktextstyle.copyWith(
                                      fontSize: fontSize1 * 1.2,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          totsaving -
                                                  nownetcredit -
                                                  count30thsPassed(
                                                        startDate,
                                                        today,
                                                      ) *
                                                      (mntsaving) >
                                              0
                                          ? const Color.fromRGBO(
                                              253,
                                              95,
                                              95,
                                              1.0,
                                            )
                                          : const Color.fromRGBO(
                                              106,
                                              253,
                                              95,
                                              1.0,
                                            ),
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                clrdinfo(
                  mntinc: mntinc,
                  mntnstblinc: mntnstblinc,
                  mntperinc: mntperinc,
                  freemnt: freemnt,
                  mntexp: mntexp,
                  annexp: annexp,
                  daysInCurrentMonth: daysInCurrentMonth.toInt(),
                  fontSize1: fontSize1,
                  mntsaving: mntsaving,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Divider(height: 21),
                ),

                infocalculated(
                  (totsaving - nownetcredit) / mntsaving,
                  "عدد أشهر الإدخار",
                ),
                infocalculated(
                  (totsaving - nownetcredit) /
                      (0.5 *
                          ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) *
                                  (1 - freemnt / 12) -
                              (mntexp + annexp / 12))),
                  "عدد أشهر الإذخار الأمثل",
                ),
                infocalculated(
                  0.5 *
                      ((mntinc + mntnstblinc) * (1 - freemnt / 12) -
                          (mntexp + annexp / 12)),
                  "أقصى ما يمكن ادخاره",
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Divider(height: 21),
                ),
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
                                "${(((nowcredit - calculateSpendingBetweenDates(startDate, ramadane) + calculateEarningsBetweenDates(startDate, ramadane) + (daysdiff(startDate, ramadane) + 1) * (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) + count30thsPassed(startDate, ramadane) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp))).round())}",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                  color:
                                      ((nowcredit -
                                              calculateSpendingBetweenDates(
                                                startDate,
                                                ramadane,
                                              ) +
                                              calculateEarningsBetweenDates(
                                                startDate,
                                                ramadane,
                                              ) +
                                              (daysdiff(startDate, ramadane) +
                                                      1) *
                                                  (-(((mntinc +
                                                                  mntnstblinc *
                                                                      (1 -
                                                                          0.01 *
                                                                              mntperinc)) *
                                                              (1 -
                                                                  freemnt /
                                                                      12) -
                                                          (mntexp +
                                                              annexp / 12) -
                                                          (mntsaving)) /
                                                      daysInCurrentMonth)) +
                                              count30thsPassed(
                                                    startDate,
                                                    ramadane,
                                                  ) *
                                                  ((mntinc +
                                                              mntnstblinc *
                                                                  (1 -
                                                                      0.01 *
                                                                          mntperinc)) *
                                                          (1 - freemnt / 12) -
                                                      mntexp)) >
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
                                "${((nowcredit - calculateSpendingBetweenDates(startDate, aidfitr) + calculateEarningsBetweenDates(startDate, aidfitr) + (daysdiff(startDate, aidfitr) + 1) * (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) + count30thsPassed(startDate, aidfitr) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp))).round()}",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                  color:
                                      nowcredit -
                                              calculateSpendingBetweenDates(
                                                startDate,
                                                aidfitr,
                                              ) +
                                              calculateEarningsBetweenDates(
                                                startDate,
                                                aidfitr,
                                              ) +
                                              (daysdiff(startDate, aidfitr) +
                                                      1) *
                                                  (-(((mntinc +
                                                                  mntnstblinc *
                                                                      (1 -
                                                                          0.01 *
                                                                              mntperinc)) *
                                                              (1 -
                                                                  freemnt /
                                                                      12) -
                                                          (mntexp +
                                                              annexp / 12) -
                                                          (mntsaving)) /
                                                      daysInCurrentMonth)) +
                                              count30thsPassed(
                                                    startDate,
                                                    aidfitr,
                                                  ) *
                                                  ((mntinc +
                                                              mntnstblinc *
                                                                  (1 -
                                                                      0.01 *
                                                                          mntperinc)) *
                                                          (1 - freemnt / 12) -
                                                      mntexp) >
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
                                "${((nowcredit - calculateSpendingBetweenDates(startDate, aidfadha) + calculateEarningsBetweenDates(startDate, aidfadha) + (daysdiff(startDate, aidfadha) + 1) * (-(((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - (mntexp + annexp / 12) - (mntsaving)) / daysInCurrentMonth)) + count30thsPassed(startDate, aidfadha) * ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) * (1 - freemnt / 12) - mntexp))).round()}",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                  color:
                                      nowcredit -
                                              calculateSpendingBetweenDates(
                                                startDate,
                                                aidfadha,
                                              ) +
                                              calculateEarningsBetweenDates(
                                                startDate,
                                                aidfadha,
                                              ) +
                                              (daysdiff(startDate, aidfadha) +
                                                      1) *
                                                  (-(((mntinc +
                                                                  mntnstblinc *
                                                                      (1 -
                                                                          0.01 *
                                                                              mntperinc)) *
                                                              (1 -
                                                                  freemnt /
                                                                      12) -
                                                          (mntexp +
                                                              annexp / 12) -
                                                          (mntsaving)) /
                                                      daysInCurrentMonth)) +
                                              count30thsPassed(
                                                    startDate,
                                                    aidfadha,
                                                  ) *
                                                  ((mntinc +
                                                              mntnstblinc *
                                                                  (1 -
                                                                      0.01 *
                                                                          mntperinc)) *
                                                          (1 - freemnt / 12) -
                                                      mntexp) >
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
                            child: Center(
                              child: Text(
                                "(${(nownetcredit - calculateSpendingBetweenDates(startDate, ramadane) + calculateEarningsBetweenDates(startDate, ramadane) + count30thsPassed(startDate, ramadane) * (mntsaving))})",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "(${(nownetcredit - calculateSpendingBetweenDates(startDate, ramadane) + calculateEarningsBetweenDates(startDate, aidfitr) + count30thsPassed(startDate, aidfitr) * (mntsaving))})",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "(${(nownetcredit - calculateSpendingBetweenDates(startDate, aidfadha) + calculateEarningsBetweenDates(startDate, aidfadha) + count30thsPassed(startDate, aidfadha) * (mntsaving))})",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
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
                            child: Center(
                              child: Text(
                                "${ramadane.year}-${ramadane.month.toString().padLeft(2, '0')}-${ramadane.day.toString().padLeft(2, '0')}",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "${aidfitr.year}-${aidfitr.month.toString().padLeft(2, '0')}-${aidfitr.day.toString().padLeft(2, '0')}",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "${aidfadha.year}-${aidfadha.month.toString().padLeft(2, '0')}-${aidfadha.day.toString().padLeft(2, '0')}",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
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
                            child: Center(
                              child: Text(
                                ":",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                ":",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                ":",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
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
                            child: Center(
                              child: Text(
                                "(يوما",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "(يوما",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "(يوما",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
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
                            child: Center(
                              child: Text(
                                "${daysdiff(DateTime.now(), ramadane).toString()})",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "${daysdiff(DateTime.now(), aidfitr).toString()})",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                "${daysdiff(DateTime.now(), aidfadha).toString()})",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
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
                            child: Center(
                              child: Text(
                                'فاتح رمضان',
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                'عيد الفطر',
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 25,
                            child: Center(
                              child: Text(
                                'عيد الأضحى',
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Candle-like chart card: shows evolution of budget (nownetcredit)
          Card(
            elevation: 5,
            color: prefsdata.get(
              "cardcolor",
              defaultValue: Color.fromRGBO(20, 20, 20, 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // Summary + distribution + top-3
                  Builder(
                    builder: (context) {
                      // Compute month range (current month)
                      final DateTime monthStart = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        1,
                      );
                      final DateTime monthEnd = DateTime(
                        DateTime.now().year,
                        DateTime.now().month + 1,
                        1,
                      ).subtract(const Duration(days: 1));

                      // Totals for the month
                      // Totals for all time
                      num totalIncomeMonth = 0;
                      for (var e in unexpectedEarningsList) {
                        totalIncomeMonth += e.amount;
                      }

                      num totalSpendingMonth = 0;
                      for (var s in upcomingSpendingList) {
                        totalSpendingMonth += s.amount;
                      }

                      final num netMonth =
                          totalIncomeMonth - totalSpendingMonth;

                      // Prepare daily distribution data for the chart (day -> totals)
                      final int daysInMonth = monthEnd.day;
                      // final List<int> days = List<int>.generate(daysInMonth, (i) => i + 1); // unused
                      final List<num> dailyIncome = List<num>.filled(
                        daysInMonth,
                        0,
                      );
                      final List<num> dailySpend = List<num>.filled(
                        daysInMonth,
                        0,
                      );

                      for (var e in unexpectedEarningsList) {
                        if ((e.date.isAfter(monthStart) ||
                                e.date.isAtSameMomentAs(monthStart)) &&
                            (e.date.isBefore(monthEnd) ||
                                e.date.isAtSameMomentAs(monthEnd))) {
                          final idx = e.date.day - 1;
                          if (idx >= 0 && idx < daysInMonth) {
                            dailyIncome[idx] += e.amount;
                          }
                        }
                      }
                      for (var s in upcomingSpendingList) {
                        if ((s.date.isAfter(monthStart) ||
                                s.date.isAtSameMomentAs(monthStart)) &&
                            (s.date.isBefore(monthEnd) ||
                                s.date.isAtSameMomentAs(monthEnd))) {
                          final idx = s.date.day - 1;
                          if (idx >= 0 && idx < daysInMonth) {
                            dailySpend[idx] += s.amount;
                          }
                        }
                      }

                      // Top-3 lists across full data (not limited to month) for visibility
                      final List unexpectedSortedDesc = List.from(
                        unexpectedEarningsList,
                      )..sort((a, b) => b.amount.compareTo(a.amount));
                      final top3Income = unexpectedSortedDesc.take(3).toList();

                      final List upcomingSortedDesc = List.from(
                        upcomingSpendingList,
                      )..sort((a, b) => b.amount.compareTo(a.amount));
                      final top3Spending = upcomingSortedDesc.take(3).toList();

                      // Chart data model
                      final List<Map<String, dynamic>> chartData = [];
                      for (int i = 0; i < daysInMonth; i++) {
                        chartData.add({
                          'day': (i + 1).toString(),
                          'income': dailyIncome[i],
                          'spend': dailySpend[i],
                        });
                      }

                      return Column(
                        children: [
                          // Totals row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${totalSpendingMonth.toString()} درهم',
                                      style: darktextstyle.copyWith(
                                        fontSize: fontSize1 * 1.05,
                                        fontWeight: FontWeight.bold,
                                        color: const Color.fromRGBO(
                                          253,
                                          95,
                                          95,
                                          1.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'مجموع المصاريف',
                                      style: darktextstyle.copyWith(
                                        fontSize: fontSize1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Net
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${netMonth.toString()} درهم',
                                      style: darktextstyle.copyWith(
                                        fontSize: fontSize1 * 1.25,
                                        fontWeight: FontWeight.bold,
                                        color: netMonth >= 0
                                            ? Colors.green[300]
                                            : Colors.red[300],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'الرصيد الصافي',
                                      style: darktextstyle.copyWith(
                                        fontSize: fontSize1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Income
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${totalIncomeMonth.toString()} درهم',
                                      style: darktextstyle.copyWith(
                                        fontSize: fontSize1 * 1.05,
                                        fontWeight: FontWeight.bold,
                                        color: const Color.fromRGBO(
                                          106,
                                          253,
                                          95,
                                          1.0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'مجموع المداخيل',
                                      style: darktextstyle.copyWith(
                                        fontSize: fontSize1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Spending
                            ],
                          ),
                          const SizedBox(height: 12),
                          // --- New: Global statistics for unexpected earnings and spendings ---

                          // --- End statistics ---
                          const SizedBox(height: 12),

                          // Distribution chart (compact)
                          SizedBox(
                            height: 140,
                            child: SfCartesianChart(
                              primaryXAxis: CategoryAxis(
                                labelRotation: 0,
                                interval: (daysInMonth / 4).ceilToDouble(),
                                majorGridLines: const MajorGridLines(
                                  width: 0.5,
                                  color: Color.fromRGBO(200, 200, 200, 0.3),
                                ),
                                edgeLabelPlacement: EdgeLabelPlacement.shift,
                              ),
                              primaryYAxis: NumericAxis(
                                labelFormat: '{value}',
                                majorGridLines: const MajorGridLines(
                                  width: 0.5,
                                  color: Color.fromRGBO(200, 200, 200, 0.3),
                                ),
                              ),
                              tooltipBehavior: TooltipBehavior(enable: true),
                              legend: Legend(
                                isVisible: true,
                                position: LegendPosition.bottom,
                              ),
                              series:
                                  <
                                    CartesianSeries<
                                      Map<String, dynamic>,
                                      String
                                    >
                                  >[
                                    ColumnSeries<Map<String, dynamic>, String>(
                                      name: 'دخل',
                                      dataSource: chartData,
                                      xValueMapper: (m, _) =>
                                          m['day'] as String,
                                      yValueMapper: (m, _) =>
                                          m['income'] as num,
                                      pointColorMapper: (m, _) {
                                        final isToday =
                                            m['day'] == today.day.toString() &&
                                            today.month ==
                                                DateTime.now().month &&
                                            today.year == DateTime.now().year;
                                        return isToday
                                            ? Colors.amber
                                            : const Color.fromRGBO(
                                                106,
                                                253,
                                                95,
                                                1.0,
                                              );
                                      },
                                    ),
                                    ColumnSeries<Map<String, dynamic>, String>(
                                      name: 'مصاريف',
                                      dataSource: chartData,
                                      xValueMapper: (m, _) =>
                                          m['day'] as String,
                                      yValueMapper: (m, _) => m['spend'] as num,
                                      pointColorMapper: (m, _) {
                                        final isToday =
                                            m['day'] == today.day.toString() &&
                                            today.month ==
                                                DateTime.now().month &&
                                            today.year == DateTime.now().year;
                                        return isToday
                                            ? Colors.amber.withOpacity(0.8)
                                            : const Color.fromRGBO(
                                                253,
                                                95,
                                                95,
                                                1.0,
                                              );
                                      },
                                    ),
                                  ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          Builder(
                            builder: (context) {
                              // Gather all dates for range
                              final allDates = <DateTime>[];
                              for (var e in unexpectedEarningsList) {
                                allDates.add(e.date);
                              }
                              for (var s in upcomingSpendingList) {
                                allDates.add(s.date);
                              }
                              if (allDates.isEmpty) {
                                return Text(
                                  'لا توجد بيانات كافية للإحصائيات',
                                  style: darktextstyle.copyWith(
                                    fontSize: fontSize1,
                                  ),
                                );
                              }
                              allDates.sort();
                              final firstDate = allDates.first;
                              final lastDate = allDates.last;
                              final monthsSpan =
                                  ((lastDate.year - firstDate.year) * 12 +
                                          (lastDate.month - firstDate.month) +
                                          1)
                                      .clamp(1, 10000);

                              // Earnings
                              final totalEarnings = unexpectedEarningsList
                                  .fold<num>(0, (sum, e) => sum + e.amount);
                              final avgEarningsPerMonth =
                                  totalEarnings / monthsSpan;
                              final avgEarningsPerEntry =
                                  unexpectedEarningsList.isNotEmpty
                                  ? totalEarnings /
                                        unexpectedEarningsList.length
                                  : 0;

                              // Spendings
                              final totalSpendings = upcomingSpendingList
                                  .fold<num>(0, (sum, s) => sum + s.amount);
                              final avgSpendingsPerMonth =
                                  totalSpendings / monthsSpan;
                              final avgSpendingsPerEntry =
                                  upcomingSpendingList.isNotEmpty
                                  ? totalSpendings / upcomingSpendingList.length
                                  : 0;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'المصاريف غير القارة',
                                              style: darktextstyle.copyWith(
                                                fontSize: fontSize1 * 1.05,
                                                fontWeight: FontWeight.bold,
                                                color: const Color.fromRGBO(
                                                  253,
                                                  95,
                                                  95,
                                                  1.0,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 4),
                                            Text(
                                              'المتوسط/شهر: ${avgSpendingsPerMonth.toStringAsFixed(2)}',
                                              style: darktextstyle.copyWith(
                                                fontSize: fontSize1,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'المتوسط/عملية: ${avgSpendingsPerEntry.toStringAsFixed(2)}',
                                              style: darktextstyle.copyWith(
                                                fontSize: fontSize1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'المداخيل غير القارة',
                                              style: darktextstyle.copyWith(
                                                fontSize: fontSize1,
                                                fontWeight: FontWeight.bold,
                                                color: const Color.fromRGBO(
                                                  106,
                                                  253,
                                                  95,
                                                  1.0,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),

                                            const SizedBox(height: 4),
                                            Text(
                                              'المتوسط/شهر: ${avgEarningsPerMonth.toStringAsFixed(2)}',
                                              style: darktextstyle.copyWith(
                                                fontSize: fontSize1,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'المتوسط/عملية: ${avgEarningsPerEntry.toStringAsFixed(2)}',
                                              style: darktextstyle.copyWith(
                                                fontSize: fontSize1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ), // Top-3 lists side-by-side
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Top incomes

                              // Top spendings
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    Text(
                                      'أكبر 3 مصاريف',
                                      style: darktextstyle.copyWith(
                                        fontSize: fontSize1 * 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...top3Spending.map((it) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${it.amount}',
                                                style: darktextstyle.copyWith(
                                                  fontSize: fontSize1,
                                                  color: const Color.fromRGBO(
                                                    253,
                                                    95,
                                                    95,
                                                    1.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              it.title ?? '-',
                                              style: darktextstyle.copyWith(
                                                fontSize: fontSize1,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    Text(
                                      'أكبر 3 مداخل',
                                      style: darktextstyle.copyWith(
                                        fontSize: fontSize1 * 0.85,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...top3Income.map((it) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${it.amount}',
                                                style: darktextstyle.copyWith(
                                                  fontSize: fontSize1,
                                                  color: const Color.fromRGBO(
                                                    106,
                                                    253,
                                                    95,
                                                    1.0,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              it.title ?? '-',
                                              style: darktextstyle.copyWith(
                                                fontSize: fontSize1,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          _buildUnexpectedEarningsCard(context),
          _buildUpcomingSpendingCard(context),

          Card(
            elevation: 2,
            color: prefsdata.get(
              "cardcolor",
              defaultValue: Color.fromRGBO(20, 20, 20, 1.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  "تدبير الموارد الخاصة بك",
                  style: darktextstyle.copyWith(fontSize: fontSize1),
                ),
                const SizedBox(height: 20),
                moneyinput(
                  size,
                  totsaving,
                  "totsaving",
                  "المبلغ الإجمالي المراد توفيره",
                ),
                /*
                moneyinput(
                  size,
                  nowcredit,
                  "nowcredit",
                  "المبلغ المتوفر يوم"
                      " ${startDate.year}-${startDate.month}-${startDate.day} "
                      "( ${DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).difference(DateTime(startDate.year, startDate.month, startDate.day)).inDays.toString()} يوم )",
                ),*/
                Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                    border: Border.all(
                      color: const Color.fromRGBO(106, 253, 95, 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 48 * fontSize2 / 16,
                            width: size.width * 0.2 * fontSize2 / 16,
                            child: TextFormField(
                              textAlign: TextAlign.center,
                              style: darktextstyle.copyWith(
                                fontSize: fontSize2,
                                fontWeight: FontWeight.bold,
                              ),
                              initialValue: nowcredit.toString(),
                              decoration: InputDecoration(
                                hintStyle: darktextstyle.copyWith(
                                  fontSize: fontSize2,
                                  color: Colors.grey[600],
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color.fromRGBO(80, 80, 80, 1.0),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color.fromRGBO(106, 253, 95, 0.7),
                                    width: 1.5,
                                  ),
                                ),
                                filled: true,
                                fillColor: const Color.fromRGBO(
                                  25,
                                  25,
                                  25,
                                  1.0,
                                ),
                              ),
                              onChanged: (newval) {
                                final v = int.tryParse(newval);
                                if (v == null) {
                                  setState(() {
                                    pickStartDate(context);
                                    prefsdata.put("nownetcredit", 0);
                                    nownetcredit = prefsdata.get(
                                      "nownetcredit".toString(),
                                    );
                                    prefsdata.put("nowcredit", 0);
                                    nowcredit = prefsdata.get(
                                      "nowcredit".toString(),
                                    );
                                    _saveCurrentState();
                                  });
                                } else {
                                  setState(() {
                                    pickStartDate(context);
                                    prefsdata.put(
                                      "nownetcredit",
                                      (v -
                                              ((((mntinc +
                                                                  mntnstblinc *
                                                                      (1 -
                                                                          0.01 *
                                                                              mntperinc)) *
                                                              (1 -
                                                                  freemnt /
                                                                      12) -
                                                          (mntexp +
                                                              annexp / 12) -
                                                          (mntsaving)) /
                                                      daysInCurrentMonth) *
                                                  (daysleftInCurrentMonth())))
                                          .round(),
                                    );
                                    nownetcredit = prefsdata.get(
                                      "nownetcredit".toString(),
                                    );
                                    prefsdata.put("nowcredit".toString(), v);
                                    nowcredit = prefsdata.get(
                                      "nowcredit".toString(),
                                    );
                                    _saveCurrentState();
                                  });
                                }
                              },
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[800]!,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          "المبلغ المتوفر يوم"
                          " ${startDate.year}-${startDate.month}-${startDate.day} "
                          "( ${DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day).difference(DateTime(startDate.year, startDate.month, startDate.day)).inDays.toString()} يوم )",
                          style: darktextstyle.copyWith(
                            fontSize: fontSize2,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                moneyinput(
                  size,
                  mntsaving,
                  "mntsaving",
                  "المبلغ الشهري المرتقب إدخاره",
                ),

                moneyinput(size, freemnt, "freemnt", "عدد أشهر الراحة السنوية"),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Card(
            elevation: 5,
            color: prefsdata.get(
              "cardcolor",
              defaultValue: Color.fromRGBO(20, 20, 20, 1.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  "هيكلة المصاريف الشخصية",
                  style: darktextstyle.copyWith(fontSize: fontSize1),
                ),
                const SizedBox(height: 20),
                moneyinput(size, mntexp, "mntexp", "مصاريف شهرية "),
                moneyinput(size, annexp, "annexp", "مصاريف سنوية"),
                moneyinputslider(
                  size,
                  mntperexp,
                  "mntperexp",
                  "نسبة التغير في الإنفاق        ",
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Divider(height: 21),
                ),
                infocalculated(
                  -(mntsaving -
                      0.5 *
                          ((mntinc + mntnstblinc) * (1 - freemnt / 12) -
                              (mntexp + annexp / 12))),
                  "فائض / عجز التدبير",
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Divider(height: 21),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 0.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromARGB(10, 45, 45, 45),
                          const Color.fromARGB(125, 35, 35, 35),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ],
                      border: Border.all(
                        color: const Color.fromRGBO(106, 253, 95, 0.3),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(
                                    106,
                                    253,
                                    95,
                                    0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.timeline,
                                  color: Color.fromRGBO(106, 253, 95, 1.0),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "مبيان أشهر الإدخار",
                                style: darktextstyle.copyWith(
                                  fontSize: fontSize1,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    ((totsaving - nownetcredit) / mntsaving)
                                        .toStringAsFixed(1),
                                    style: darktextstyle.copyWith(
                                      fontSize: fontSize1 * 1.2,
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromRGBO(
                                        106,
                                        253,
                                        95,
                                        1.0,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "فعلي",
                                    style: darktextstyle.copyWith(
                                      fontSize: fontSize1 * 0.7,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  children: [
                                    SfLinearGauge(
                                      interval: 4,
                                      maximum: 24,
                                      showLabels: false,
                                      showAxisTrack: false,
                                      axisTrackStyle:
                                          const LinearAxisTrackStyle(
                                            thickness: 12,
                                            edgeStyle:
                                                LinearEdgeStyle.bothCurve,
                                            color: Color.fromRGBO(
                                              60,
                                              60,
                                              60,
                                              1.0,
                                            ),
                                            borderColor: Color.fromRGBO(
                                              80,
                                              80,
                                              80,
                                              1.0,
                                            ),
                                            borderWidth: 1,
                                          ),
                                      ranges: const [
                                        LinearGaugeRange(
                                          color: Colors.transparent,
                                          startValue: 0,
                                          endValue: 84,
                                        ),
                                      ],
                                      markerPointers: [
                                        LinearShapePointer(
                                          value:
                                              (totsaving - nownetcredit) /
                                              (0.5 *
                                                  ((mntinc +
                                                              mntnstblinc *
                                                                  (1 -
                                                                      0.01 *
                                                                          mntperinc)) *
                                                          (1 - freemnt / 12) -
                                                      (mntexp + annexp / 12))),
                                          shapeType:
                                              LinearShapePointerType.diamond,
                                          color: Colors.amber,
                                          position: LinearElementPosition.cross,
                                          width: 12,
                                          height: 12,
                                        ),
                                      ],
                                      barPointers: [
                                        LinearBarPointer(
                                          value:
                                              (totsaving - nownetcredit) /
                                              mntsaving,
                                          thickness: 12,
                                          edgeStyle: LinearEdgeStyle.bothCurve,
                                          color: const Color.fromRGBO(
                                            106,
                                            253,
                                            95,
                                            1.0,
                                          ),
                                          position: LinearElementPosition.cross,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 5),

                                    // Month scale indicators
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "0",
                                          style: darktextstyle.copyWith(
                                            fontSize: fontSize1 * 0.7,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "4",
                                          style: darktextstyle.copyWith(
                                            fontSize: fontSize1 * 0.7,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "8",
                                          style: darktextstyle.copyWith(
                                            fontSize: fontSize1 * 0.7,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "12",
                                          style: darktextstyle.copyWith(
                                            fontSize: fontSize1 * 0.7,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "16",
                                          style: darktextstyle.copyWith(
                                            fontSize: fontSize1 * 0.7,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "20",
                                          style: darktextstyle.copyWith(
                                            fontSize: fontSize1 * 0.7,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          "24",
                                          style: darktextstyle.copyWith(
                                            fontSize: fontSize1 * 0.7,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 10),

                              // Optimal months indicator
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    ((totsaving - nownetcredit) /
                                            (0.5 *
                                                ((mntinc +
                                                            mntnstblinc *
                                                                (1 -
                                                                    0.01 *
                                                                        mntperinc)) *
                                                        (1 - freemnt / 12) -
                                                    (mntexp + annexp / 12))))
                                        .toStringAsFixed(1),
                                    style: darktextstyle.copyWith(
                                      fontSize: fontSize1 * 1.2,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  Text(
                                    "أمثل",
                                    style: darktextstyle.copyWith(
                                      fontSize: fontSize1 * 0.7,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Legend explanation
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "المدة المثالية",
                                    style: darktextstyle.copyWith(
                                      fontSize: fontSize1 * 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 20),
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(
                                        106,
                                        253,
                                        95,
                                        1.0,
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    "المدة الفعلية",
                                    style: darktextstyle.copyWith(
                                      fontSize: fontSize1 * 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Card(
            elevation: 5,
            color: prefsdata.get(
              "cardcolor",
              defaultValue: Color.fromRGBO(20, 20, 20, 1.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  "هيكلة المداخيل الشخصية",
                  style: darktextstyle.copyWith(fontSize: fontSize1),
                ),
                const SizedBox(height: 20),
                moneyinput(size, mntinc, "mntinc", "المداخيل الشهرية القارة"),
                moneyinput(
                  size,
                  mntnstblinc,
                  "mntnstblinc",
                  "مداخيل شهرية غير قارة",
                ),
                moneyinputslider(
                  size,
                  mntperinc,
                  "mntperinc",
                  "نسبة تقلبات المداخيل         ",
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Divider(height: 21),
                ),
                infocalculated(
                  0.5 *
                          ((mntinc + mntnstblinc * (1 + mntperinc * 0.01)) *
                              (12 - freemnt)) -
                      (mntexp * (1 - mntperexp * 0.01) + annexp),
                  "أقصى ما يمكن إدخاره سنويا",
                ),
                infocalculated(
                  0.5 *
                          ((mntinc + mntnstblinc * (1 - mntperinc * 0.01)) *
                              (12 - freemnt)) -
                      (mntexp * (1 + mntperexp * 0.01) + annexp),
                  "أقل ما يمكن إدخاره سنويا",
                ),
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
      padding: const EdgeInsets.only(left: 5, right: 5, bottom: 7, top: 7),
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
              decoration: InputDecoration(
                hintStyle: darktextstyle.copyWith(fontSize: fontSize2),
                border: OutlineInputBorder(gapPadding: 1),
              ),
              onChanged: (newval) {
                final v = int.tryParse(newval);
                if (v == null) {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename, 0);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                    print(boxvariable.toString() + boxvariablename.toString());
                    _saveCurrentState();
                  });
                } else {
                  setState(() {
                    pickStartDate(context);
                    prefsdata.put(boxvariablename.toString(), v);
                    boxvariable = prefsdata.get(boxvariablename.toString());
                    print(boxvariable.toString() + boxvariablename.toString());
                    _saveCurrentState();
                  });
                }
              },
              keyboardType: TextInputType.number,
            ),
          ),
          Text(
            textlabel,
            style: darktextstyle.copyWith(fontSize: fontSize2),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  int daysdiff(DateTime start, DateTime goal) {
    return -DateTime(
      start.year,
      start.month,
      start.day,
    ).difference(DateTime(goal.year, goal.month, goal.day)).inDays;
  }

  Widget moneyinputslider(
    size,
    boxvariable,
    boxvariablename,
    String textlabel,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: size.height * 0.07,
            width: size.width * 0.3,
            child: sfs.SfSlider(
              min: 0.0,
              max: 100.0,
              interval: 50,
              showTicks: true,
              showLabels: true,
              enableTooltip: true,
              thumbIcon: const Icon(
                Icons.percent_rounded,
                color: Colors.blue,
                size: 14.0,
              ),
              tooltipShape: const sfs.SfPaddleTooltipShape(),
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
          Text(
            textlabel,
            style: darktextstyle.copyWith(fontSize: fontSize2),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget infocalculated(
    num value,
    String labelText, {
    Color? customColor,
    IconData? icon,
  }) {
    bool isAchieved = labelText.contains("أشهر") && value <= 0;

    // Determine color based on value (positive = green, negative = red, or use custom)
    final Color valueColor =
        customColor ??
        (isAchieved || value > 0
            ? const Color.fromRGBO(106, 253, 95, 1.0)
            : value < 0
            ? const Color.fromRGBO(253, 95, 95, 1.0)
            : Colors.white);

    // Choose icon if not provided
    final IconData displayIcon =
        icon ??
        (isAchieved
            ? Icons.emoji_events
            : labelText.contains("أشهر")
            ? Icons.calendar_month
            : labelText.contains("ادخار")
            ? Icons.savings
            : labelText.contains("سنوي")
            ? Icons.auto_graph
            : Icons.attach_money);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromRGBO(40, 40, 40, 1.0).withOpacity(0.1),
            const Color.fromRGBO(30, 30, 30, 1.0).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
        border: Border.all(color: valueColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Value with icon
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: valueColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(displayIcon, color: valueColor, size: 20),
              ),
              const SizedBox(width: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  isAchieved
                      ? "الهدف محقق"
                      : (value.isNaN ? "0" : value.round().toString()),
                  key: ValueKey<String>(
                    isAchieved ? "الهدف محقق" : value.toString(),
                  ),
                  style: darktextstyle.copyWith(
                    fontSize: isAchieved ? fontSize1 * 0.8 : fontSize1,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ),
            ],
          ),

          // Right side - Label
          Text(
            labelText,
            style: darktextstyle.copyWith(
              fontSize: fontSize1,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  int count30thsPassed(DateTime startDate, DateTime endDate) {
    if (startDate.isAfter(endDate)) {
      return 0;
    }

    int payingDay = prefsdata.get("payingDay", defaultValue: 30);
    int count = 0;

    // Start checking from the current month of startDate
    DateTime currentMonth = DateTime(startDate.year, startDate.month);

    while (true) {
      int year = currentMonth.year;
      int month = currentMonth.month;

      // Get the last day of this month (e.g., handles Feb 28/29, or 30/31)
      int lastDay = DateTime(year, month + 1, 0).day;
      int targetDay = payingDay > lastDay ? lastDay : payingDay;

      DateTime targetDate = DateTime(year, month, targetDay);

      // If targetDate is after endDate, we shouldn't count it or anything after it
      if (targetDate.isAfter(endDate)) {
        break;
      }

      // If targetDate is on or after startDate, it's categorized as "passed"
      if (targetDate.isAfter(startDate) ||
          targetDate.isAtSameMomentAs(startDate)) {
        count++;
      }

      // Move to next month
      currentMonth = DateTime(year, month + 1);
    }

    return count;
  }

  Widget coloredinfocalculated(
    num value,
    String labelText, {
    num? threshold,
    Color? positiveColor,
    Color? negativeColor,
    IconData? icon,
  }) {
    // Set default threshold to 0.5 if not provided
    final num actualThreshold = threshold ?? 0.5;

    // Determine color based on value compared to threshold
    final bool isPositive = value > actualThreshold;
    final Color valueColor = isPositive
        ? (positiveColor ??
              const Color.fromARGB(
                255,
                127,
                255,
                131,
              )) // Green for positive/good
        : (negativeColor ??
              const Color.fromARGB(255, 216, 19, 1)); // Red for negative/bad

    // Choose icon if not provided
    final IconData displayIcon =
        icon ??
        (labelText.contains("مؤشر")
            ? Icons.speed
            : labelText.contains("نسبة")
            ? Icons.percent
            : isPositive
            ? Icons.trending_up
            : Icons.trending_down);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromRGBO(45, 45, 45, 1.0),
            const Color.fromRGBO(35, 35, 35, 1.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
        border: Border.all(color: valueColor.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side - Value with icon and indicator
          Row(
            children: [
              // Icon indicator
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: valueColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: valueColor.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(displayIcon, color: valueColor, size: 20),
              ),
              const SizedBox(width: 12),

              // Value with animation
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: isPositive
                                ? const Offset(0.0, -0.2)
                                : const Offset(0.0, 0.2),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                  );
                },
                child: Row(
                  key: ValueKey<String>(value.toString()),
                  children: [
                    Text(
                      value.toString(),
                      style: darktextstyle.copyWith(
                        fontSize: fontSize1,
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: valueColor,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Right side - Label with subtle styling
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              labelText,
              style: darktextstyle.copyWith(
                fontSize: fontSize1,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> pickStartDate(BuildContext context) async {
    DateTime startDate = prefsdata.get(
      "startDate",
      defaultValue: DateTime(2024, 9, 1),
    );
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

class clrdinfo extends StatelessWidget {
  const clrdinfo({
    super.key,
    required this.mntinc,
    required this.mntnstblinc,
    required this.mntperinc,
    required this.freemnt,
    required this.mntexp,
    required this.annexp,
    required this.daysInCurrentMonth,
    required this.fontSize1,
    required this.mntsaving,
  });

  final num mntinc;
  final num mntnstblinc;
  final num mntperinc;
  final num freemnt;
  final num mntexp;
  final num annexp;
  final int daysInCurrentMonth;
  final double fontSize1;
  final num mntsaving;

  @override
  Widget build(BuildContext context) {
    // Calculate optimal daily spending
    final optimalDailySpending =
        ((0.5 *
                ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) *
                        (1 - freemnt / 12) -
                    (mntexp + annexp / 12)) /
                daysInCurrentMonth))
            .round();

    // Calculate ratio for determining status
    final ratio =
        ((0.5 *
                ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) *
                        (1 - freemnt / 12) -
                    (mntexp + annexp / 12))) /
            daysInCurrentMonth) /
        ((0.5 *
                    ((mntinc + mntnstblinc * (1 - 0.01 * mntperinc)) *
                            (1 - freemnt / 12) -
                        (mntexp + annexp / 12)) -
                (mntsaving -
                    0.5 *
                        ((mntinc + mntnstblinc) * (1 - freemnt / 12) -
                            (mntexp + annexp / 12)))) /
            daysInCurrentMonth);

    // Determine if spending is within optimal range
    final isOptimal = ratio < 0.85;

    // Set color based on status
    final Color valueColor = isOptimal
        ? const Color.fromARGB(255, 127, 255, 131) // Green for optimal
        : const Color.fromARGB(255, 216, 19, 1); // Red for non-optimal

    // Choose icon based on status
    final IconData statusIcon = isOptimal ? Icons.check_circle : Icons.warning;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(10, 45, 45, 45),
            const Color.fromARGB(125, 35, 35, 35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: valueColor.withOpacity(0.2),
            offset: const Offset(0, 3),
            blurRadius: 6,
            spreadRadius: 0.5,
          ),
        ],
        border: Border.all(color: valueColor.withOpacity(0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side - Value with icon and status
            Row(
              children: [
                // Status icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: valueColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: valueColor.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: Icon(statusIcon, color: valueColor, size: 24),
                ),

                const SizedBox(width: 14),

                // Value with animation
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(0.0, -0.3),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                child: child,
                              ),
                            );
                          },
                      child: Text(
                        optimalDailySpending.toString(),
                        key: ValueKey<String>(optimalDailySpending.toString()),
                        style: darktextstyle.copyWith(
                          fontSize: fontSize1 * 1.4,
                          fontWeight: FontWeight.bold,
                          color: valueColor,
                        ),
                      ),
                    ),
                    Text(
                      isOptimal ? "ميزانية مثالية" : "تحتاج للتعديل",
                      style: darktextstyle.copyWith(fontSize: fontSize1 * 0.7),
                    ),
                  ],
                ),
              ],
            ),

            // Right side - Label with subtle styling
            Text(
              "المبلغ الامثل إنفاقه في اليوم",
              style: darktextstyle.copyWith(
                fontSize: fontSize1,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}
