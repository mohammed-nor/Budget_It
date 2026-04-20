import 'dart:math';
import 'package:budget_it/services/styles%20and%20constants.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart' as gauge;
import 'package:syncfusion_flutter_charts/charts.dart' as chart;
import 'package:budget_it/models/budget_history.dart';
import 'package:budget_it/models/unexpected_earning.dart';
import 'package:budget_it/models/upcoming_spending.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';

class Statspage extends StatefulWidget {
  const Statspage({super.key});

  @override
  State<Statspage> createState() => _StatspageState();
}

class ChartData {
  ChartData(this.x, this.y, [this.color]);
  final String x;
  final double y;
  final Color? color;
}

class _StatspageState extends State<Statspage> {
  final prefsdata = Hive.box('data');
  Box<BudgetHistory>? historyBox;
  List<BudgetHistory> budgetHistory = [];

  // Dynamic list for monthly stats
  List<Map<String, dynamic>> monthlyStats = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      _initBoxes();
    });
  }

  Future<void> _initBoxes() async {
    historyBox = await Hive.openBox<BudgetHistory>('budget_history');
    if (!Hive.isBoxOpen('unexpected_earnings')) {
      await Hive.openBox<UnexpectedEarning>('unexpected_earnings');
    }
    if (!Hive.isBoxOpen('upcoming_spending')) {
      await Hive.openBox<UpcomingSpending>('upcoming_spending');
    }
    if (historyBox != null) {
      _loadBudgetHistory();
    }
  }

  void _loadBudgetHistory() {
    if (historyBox != null && historyBox!.isNotEmpty) {
      setState(() {
        budgetHistory = historyBox!.values.toList();
        budgetHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _populateIncomeFields();
      });
    } else {
      _populateIncomeFields();
    }
  }

  void _populateIncomeFields() {
    final num currentMntinc = prefsdata.get("mntinc", defaultValue: 4300);
    final int payingDay = prefsdata.get("payingDay", defaultValue: 30);

    final Box<UnexpectedEarning> earningsBox = Hive.box<UnexpectedEarning>(
      'unexpected_earnings',
    );
    final Box<UpcomingSpending> spendingBox = Hive.box<UpcomingSpending>(
      'upcoming_spending',
    );
    final List<UnexpectedEarning> allEarnings = earningsBox.values.toList();
    final List<UpcomingSpending> allSpending = spendingBox.values.toList();

    DateTime now = DateTime.now();
    DateTime oldestDate = now;

    if (allEarnings.isNotEmpty || allSpending.isNotEmpty) {
      final List<DateTime> allDates = [
        ...allEarnings.map((e) => e.date),
        ...allSpending.map((s) => s.date),
      ];
      oldestDate = allDates.reduce((a, b) => a.isBefore(b) ? a : b);
    }

    // Calculate number of months back to oldest entry
    int monthDifference =
        ((now.year - oldestDate.year) * 12) + now.month - oldestDate.month;
    int monthsToShow = monthDifference + 1;

    List<Map<String, dynamic>> stats = [];

    for (int i = 0; i < monthsToShow; i++) {
      DateTime periodEndDate = _getPayingDateForMonth(now, -i, payingDay);
      DateTime periodStartDate = _getPayingDateForMonth(
        now,
        -(i + 1),
        payingDay,
      );

      num unstableSum = 0;
      for (var earning in allEarnings) {
        if ((earning.date.isAfter(periodStartDate) ||
                earning.date.isAtSameMomentAs(periodStartDate)) &&
            earning.date.isBefore(periodEndDate)) {
          unstableSum += earning.amount;
        }
      }

      num spendingSum = 0;
      for (var spending in allSpending) {
        if ((spending.date.isAfter(periodStartDate) ||
                spending.date.isAtSameMomentAs(periodStartDate)) &&
            spending.date.isBefore(periodEndDate)) {
          spendingSum += spending.amount;
        }
      }

      // Use year-month unique keys for persistence
      String keySuffix = "${periodEndDate.year}_${periodEndDate.month}";
      num stableIncome = prefsdata.get(
        "stb_override_$keySuffix",
        defaultValue: currentMntinc,
      );
      num unstableIncome = prefsdata.get(
        "nstb_override_$keySuffix",
        defaultValue: unstableSum,
      );
      num unstableSpending = prefsdata.get(
        "exp_override_$keySuffix",
        defaultValue: spendingSum,
      );

      stats.add({
        'monthName': getMonthName(i),
        'stableIncome': stableIncome,
        'unstableIncome': unstableIncome,
        'unstableSpending': unstableSpending,
        'year': periodEndDate.year,
        'month': periodEndDate.month,
      });
    }

    setState(() {
      monthlyStats = stats;
    });
  }

  void _restoreFromHive() {
    // Clear all overrides in prefsdata
    final keys = prefsdata.keys
        .where(
          (k) =>
              k.toString().startsWith("stb_override_") ||
              k.toString().startsWith("nstb_override_") ||
              k.toString().startsWith("exp_override_"),
        )
        .toList();

    for (var key in keys) {
      prefsdata.delete(key);
    }

    _populateIncomeFields();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "restored_sync".tr,
          style: GoogleFonts.elMessiri(color: Colors.white),
          textAlign: Get.locale?.languageCode == 'ar' ? TextAlign.right : TextAlign.left,
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  DateTime _getPayingDateForMonth(
    DateTime reference,
    int monthOffset,
    int payingDay,
  ) {
    int year = reference.year;
    int month = reference.month + monthOffset;

    while (month <= 0) {
      month += 12;
      year -= 1;
    }
    while (month > 12) {
      month -= 12;
      year += 1;
    }

    int lastDay = DateTime(year, month + 1, 0).day;
    int actualDay = payingDay > lastDay ? lastDay : payingDay;

    return DateTime(year, month, actualDay);
  }

  String getMonthName(int index) {
    final List<String> monthKeys = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];

    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month - index, 1);
    int monthIndex = targetDate.month - 1;

    return monthKeys[monthIndex].tr;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (monthlyStats.isEmpty) return const SizedBox();

    num avgStable =
        monthlyStats
            .map((e) => e['stableIncome'] as num)
            .reduce((a, b) => a + b) /
        monthlyStats.length;
    num avgUnstable =
        monthlyStats
            .map((e) => e['unstableIncome'] as num)
            .reduce((a, b) => a + b) /
        monthlyStats.length;
    num avgSpending =
        monthlyStats
            .map((e) => e['unstableSpending'] as num)
            .reduce((a, b) => a + b) /
        monthlyStats.length;
    num totalAvg = avgStable + avgUnstable;
    num netAvg = totalAvg - avgSpending;

    final dispersionIncome =
        (monthlyStats
                .map(
                  (e) =>
                      (e['stableIncome'] as num) + (e['unstableIncome'] as num),
                )
                .reduce(max) -
            monthlyStats
                .map(
                  (e) =>
                      (e['stableIncome'] as num) + (e['unstableIncome'] as num),
                )
                .reduce(min)) /
        (totalAvg > 0 ? totalAvg : 1);

    final dispersionNet =
        (monthlyStats
                .map(
                  (e) =>
                      (e['stableIncome'] as num) +
                      (e['unstableIncome'] as num) -
                      (e['unstableSpending'] as num),
                )
                .reduce(max) -
            monthlyStats
                .map(
                  (e) =>
                      (e['stableIncome'] as num) +
                      (e['unstableIncome'] as num) -
                      (e['unstableSpending'] as num),
                )
                .reduce(min)) /
        (netAvg.abs() > 1 ? netAvg.abs() : 1);

    final List<ChartData> lineChartData = monthlyStats.reversed
        .take(max(5, monthlyStats.length))
        .toList()
        .map(
          (e) => ChartData(
            e['monthName'],
            (e['stableIncome'] as num).toDouble() +
                (e['unstableIncome'] as num).toDouble(),
          ),
        )
        .toList();

    final pieData = [
      ChartData('stable_income'.tr, avgStable.toDouble(), const Color(0xFF15803D)),
      ChartData('unstable_income'.tr, avgUnstable.toDouble(), const Color(0xFFB91C1C)),
    ];

    return ValueListenableBuilder(
      valueListenable: prefsdata.listenable(
        keys: ['cardcolor', 'fontsize1', 'fontsize2'],
      ),
      builder: (context, box, child) {
        double fontSize1 = box.get("fontsize1", defaultValue: 15.toDouble());
        double fontSize2 = box.get("fontsize2", defaultValue: 15.toDouble());
        final dynamic currentCardColor = box.get(
          "cardcolor",
          defaultValue: const Color.fromRGBO(20, 20, 20, 1.0),
        );
        final Color effectiveCardColor = currentCardColor is Color
            ? currentCardColor
            : const Color.fromRGBO(20, 20, 20, 1.0);
        final bool isCurrentDark = effectiveCardColor.computeLuminance() < 0.5;
        final Color currentTextColor = isCurrentDark
            ? Colors.white
            : Colors.black87;
        final Color currentSecondaryTextColor = isCurrentDark
            ? Colors.white70
            : Colors.black54;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,

          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildSummaryRow(
                totalAvg,
                dispersionIncome,
                effectiveCardColor,
                isCurrentDark,
                currentTextColor,
                currentSecondaryTextColor,
              ),
              const SizedBox(height: 6),

              // Income Section
              _buildSectionHeader(
                "income_analysis".tr,
                Icons.trending_up,
                Colors.green,
                currentTextColor,
              ),
              _buildMainTrendChart(
                lineChartData,
                effectiveCardColor,
                isCurrentDark,
                currentTextColor,
                currentSecondaryTextColor,
              ),
              IntrinsicHeight(
                child: Column(
                  //crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildPieChart(
                            pieData,
                            effectiveCardColor,
                            isCurrentDark,
                            currentTextColor,
                            currentSecondaryTextColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: _buildTopExpensesPie(
                            effectiveCardColor,
                            isCurrentDark,
                            currentTextColor,
                            currentSecondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildStabilityGauges(
                      dispersionIncome,
                      dispersionNet,
                      effectiveCardColor,
                      isCurrentDark,
                      currentTextColor,
                      currentSecondaryTextColor,
                    ),
                  ],
                ),
              ),

              _buildExpensesTrendChart(
                monthlyStats,
                effectiveCardColor,
                isCurrentDark,
                currentTextColor,
                currentSecondaryTextColor,
              ),

              const SizedBox(height: 6),
              _buildSectionHeader(
                "statistical_summary".tr,
                Icons.analytics_rounded,
                Colors.blueAccent,
                currentTextColor,
              ),
              _buildStatisticalDescriptors(
                avgStable,
                avgUnstable,
                avgSpending,
                totalAvg,
                effectiveCardColor,
                isCurrentDark,
                currentTextColor,
                currentSecondaryTextColor,
              ),
              const SizedBox(height: 6),
              _buildHistoryInputsCard(
                effectiveCardColor,
                isCurrentDark,
                currentTextColor,
                currentSecondaryTextColor,
                size,
                fontSize2,
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(
    num totalAvg,
    num dispersion,
    Color cardColor,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildProjectCard(
            title: "monthly_average".tr,
            value: "${totalAvg.toStringAsFixed(0)} ${'currency'.tr}",
            icon: Icons.account_balance_wallet_rounded,
            accentColor: const Color(0xFF00C9FF),
            cardColor: cardColor,
            isDark: isDark,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildProjectCard(
            title: "stability_status".tr,
            value: dispersion < 0.2
                ? "excellent".tr
                : dispersion < 0.5
                ? "good".tr
                : "volatile".tr,
            icon: Icons.trending_up_rounded,
            accentColor: const Color(0xFF15803D),
            cardColor: cardColor,
            isDark: isDark,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
    required Color cardColor,
    required bool isDark,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: Get.locale?.languageCode == 'ar'
                      ? TextAlign.right
                      : TextAlign.left,
                  style: GoogleFonts.elMessiri(
                    color: secondaryTextColor,
                    fontSize: fontSize1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  textAlign: Get.locale?.languageCode == 'ar' ? TextAlign.right : TextAlign.left,
                  style: GoogleFonts.elMessiri(
                    color: textColor,
                    fontSize: fontSize1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainTrendChart(
    List<ChartData> data,
    Color cardColor,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(6),
        child: ExcludeSemantics(
          child: chart.SfCartesianChart(
          key: const ValueKey('trendChartStats'),
          plotAreaBorderWidth: 0,
          margin: EdgeInsets.zero,
          title: chart.ChartTitle(
            text: 'total_income_curve'.tr,
            textStyle: GoogleFonts.elMessiri(
              color: textColor,
              fontSize: fontSize1,
              fontWeight: FontWeight.bold,
            ),
            alignment: chart.ChartAlignment.far,
          ),
          primaryXAxis: chart.CategoryAxis(
            majorGridLines: const chart.MajorGridLines(width: 0),
            labelStyle: GoogleFonts.elMessiri(color: secondaryTextColor),
          ),
          primaryYAxis: chart.NumericAxis(
            majorGridLines: chart.MajorGridLines(
              width: 1,
              color: isDark ? Colors.white10 : Colors.black12,
              dashArray: const [5, 5],
            ),
            axisLine: const chart.AxisLine(width: 0),
            labelStyle: GoogleFonts.elMessiri(color: secondaryTextColor),
          ),
          series: <chart.CartesianSeries<ChartData, String>>[
            chart.SplineAreaSeries<ChartData, String>(
              dataSource: data,
              xValueMapper: (ChartData data, _) => data.x,
              yValueMapper: (ChartData data, _) => data.y,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00C9FF).withValues(alpha: 0.5),
                  const Color(0xFF00C9FF).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderColor: const Color(0xFF00C9FF),
              borderWidth: 3,
              markerSettings: const chart.MarkerSettings(
                isVisible: true,
                color: Color(0xFF00C9FF),
              ),
              animationDuration: 0,
            ),
          ],
          tooltipBehavior: chart.TooltipBehavior(
            enable: true,
            textStyle: GoogleFonts.elMessiri(),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildPieChart(
    List<ChartData> data,
    Color cardColor,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: 250,
        child: ExcludeSemantics(
          child: chart.SfCircularChart(
          palette: [
            const Color.fromARGB(255, 191, 124, 0),
            const Color.fromARGB(255, 109, 33, 180),
          ],
          key: const ValueKey('incomePipeStats'),
          title: chart.ChartTitle(
            text: 'income_distribution'.tr,
            textStyle: GoogleFonts.elMessiri(
              color: textColor,
              fontSize: fontSize1 - 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          legend: chart.Legend(
            isVisible: true,
            position: chart.LegendPosition.bottom,
            textStyle: GoogleFonts.elMessiri(
              color: secondaryTextColor,
              fontSize: 8,
            ),
          ),
          series: <chart.CircularSeries<ChartData, String>>[
            chart.DoughnutSeries<ChartData, String>(
              dataSource: data,
              xValueMapper: (ChartData data, _) => data.x,
              yValueMapper: (ChartData data, _) => data.y,
              pointColorMapper: (ChartData data, _) => data.color,
              dataLabelSettings: chart.DataLabelSettings(
                isVisible: true,
                textStyle: GoogleFonts.elMessiri(
                  fontSize: 12,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              innerRadius: '60%',
              animationDuration: 0,
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStabilityGauges(
    num dispersionInc,
    num dispersionNet,
    Color cardColor,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSingleGauge(
            title: "income_stability".tr,
            dispersion: dispersionInc,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildSingleGauge(
            title: "net_income_stability".tr,
            dispersion: dispersionNet,
            cardColor: cardColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSingleGauge({
    required String title,
    required num dispersion,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    double gaugeValue = (dispersion * 100).clamp(0, 100).toDouble();
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: 180,
        child: ExcludeSemantics(
          child: gauge.SfRadialGauge(
          key: ValueKey('stabilityGauge_$title'),
          title: gauge.GaugeTitle(
            text: title,
            textStyle: GoogleFonts.elMessiri(
              color: textColor,
              fontSize: fontSize1 - 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          axes: <gauge.RadialAxis>[
            gauge.RadialAxis(
              minimum: 0,
              maximum: 100,
              showLabels: false,
              showTicks: false,
              axisLineStyle: const gauge.AxisLineStyle(
                thickness: 0.15,
                cornerStyle: gauge.CornerStyle.bothCurve,
                color: Color.fromRGBO(200, 200, 200, 0.1),
                thicknessUnit: gauge.GaugeSizeUnit.factor,
              ),
              pointers: <gauge.GaugePointer>[
                gauge.RangePointer(
                  value: gaugeValue,
                  width: 0.15,
                  sizeUnit: gauge.GaugeSizeUnit.factor,
                  cornerStyle: gauge.CornerStyle.bothCurve,
                  gradient: const SweepGradient(
                    colors: <Color>[Color(0xFF00C9FF), Color(0xFF15803D)],
                    stops: <double>[0.25, 0.75],
                  ),
                  enableAnimation: false,
                ),
                gauge.MarkerPointer(
                  value: gaugeValue,
                  markerType: gauge.MarkerType.circle,
                  markerHeight: 10,
                  markerWidth: 10,
                  color: textColor,
                  enableAnimation: false,
                ),
              ],
              annotations: <gauge.GaugeAnnotation>[
                gauge.GaugeAnnotation(
                  positionFactor: 0.1,
                  angle: 90,
                  widget: Text(
                    '${gaugeValue.toStringAsFixed(0)}%',
                    style: GoogleFonts.elMessiri(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildExpensesTrendChart(
    List<Map<String, dynamic>> stats,
    Color cardColor,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final expenseData = stats.reversed
        .toList()
        .map(
          (e) => ChartData(
            e['monthName'],
            (e['unstableSpending'] as num).toDouble(),
          ),
        )
        .toList();

    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 230,
        padding: const EdgeInsets.all(6),
        child: ExcludeSemantics(
          child: chart.SfCartesianChart(
          key: const ValueKey('expenseTrendChart'),
          plotAreaBorderWidth: 0,
          margin: EdgeInsets.zero,
          title: chart.ChartTitle(
            text: 'expense_trend_unstable'.tr,
            textStyle: GoogleFonts.elMessiri(
              color: textColor,
              fontSize: fontSize1,
              fontWeight: FontWeight.bold,
            ),
            alignment: chart.ChartAlignment.far,
          ),
          primaryXAxis: chart.CategoryAxis(
            majorGridLines: const chart.MajorGridLines(width: 0),
            labelStyle: GoogleFonts.elMessiri(
              color: secondaryTextColor,
              fontSize: 10,
            ),
          ),
          primaryYAxis: chart.NumericAxis(
            majorGridLines: chart.MajorGridLines(
              width: 1,
              color: isDark ? Colors.white10 : Colors.black12,
              dashArray: const [5, 5],
            ),
            axisLine: const chart.AxisLine(width: 0),
            labelStyle: GoogleFonts.elMessiri(
              color: secondaryTextColor,
              fontSize: 10,
            ),
          ),
          series: <chart.CartesianSeries<ChartData, String>>[
            chart.SplineAreaSeries<ChartData, String>(
              dataSource: expenseData,
              xValueMapper: (ChartData data, _) => data.x,
              yValueMapper: (ChartData data, _) => data.y,
              gradient: LinearGradient(
                colors: [
                  Colors.redAccent.withValues(alpha: 0.4),
                  Colors.redAccent.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderColor: Colors.redAccent,
              borderWidth: 2,
              animationDuration: 0,
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildTopExpensesPie(
    Color cardColor,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final Box<UpcomingSpending> spendingBox = Hive.box<UpcomingSpending>(
      'upcoming_spending',
    );
    final Map<String, double> grouped = {};
    for (var s in spendingBox.values) {
      grouped[s.title] = (grouped[s.title] ?? 0) + s.amount.toDouble();
    }

    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final chartData = sortedEntries
        .take(5)
        .map((e) => ChartData(e.key, e.value))
        .toList();

    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        height: 250,
        child: ExcludeSemantics(
          child: chart.SfCircularChart(
          palette: [
            const Color.fromARGB(255, 191, 124, 0),
            const Color.fromARGB(255, 109, 33, 180),
            const Color.fromARGB(255, 172, 15, 47),
            const Color.fromARGB(255, 184, 0, 184),
            const Color.fromARGB(255, 0, 0, 182),
          ],
          key: const ValueKey('topSpendingPie'),
          title: chart.ChartTitle(
            text: 'top_spending'.tr,
            textStyle: GoogleFonts.elMessiri(
              color: textColor,
              fontSize: fontSize1 - 4,
              fontWeight: FontWeight.bold,
            ),
          ),
          legend: chart.Legend(
            isVisible: true,
            position: chart.LegendPosition.bottom,
            textStyle: GoogleFonts.elMessiri(
              color: secondaryTextColor,
              fontSize: 8,
            ),
            overflowMode: chart.LegendItemOverflowMode.wrap,
          ),
          series: <chart.CircularSeries<ChartData, String>>[
            chart.PieSeries<ChartData, String>(
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.x,
              yValueMapper: (ChartData data, _) => data.y,
              dataLabelSettings: chart.DataLabelSettings(
                isVisible: true,
                textStyle: GoogleFonts.elMessiri(
                  fontSize: 12,
                  color: textColor,
                ),
              ),
              explode: true,
              animationDuration: 0,
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color accentColor,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
      child: Row(
        mainAxisAlignment: Get.locale?.languageCode == 'ar' ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (Get.locale?.languageCode != 'ar') ...[
            Icon(icon, color: accentColor, size: 24),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: GoogleFonts.elMessiri(
              color: textColor,
              fontSize: fontSize1,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (Get.locale?.languageCode == 'ar') ...[
            const SizedBox(width: 6),
            Icon(icon, color: accentColor, size: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildStatisticalDescriptors(
    num avgStable,
    num avgUnstable,
    num avgSpending,
    num totalAvg,
    Color cardColor,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    num maxInc = monthlyStats
        .map((e) => (e['stableIncome'] as num) + (e['unstableIncome'] as num))
        .reduce(max);
    num maxExp = monthlyStats
        .map((e) => e['unstableSpending'] as num)
        .reduce(max);
    num minInc = monthlyStats
        .map((e) => (e['stableIncome'] as num) + (e['unstableIncome'] as num))
        .reduce(min);

    return Column(
      children: [
        _buildDetailRow(
          "highest_total_income".tr,
          "${maxInc.toStringAsFixed(0)} ${'currency'.tr}",
          Icons.keyboard_double_arrow_up_rounded,
          const Color(0xFF15803D),
          cardColor,
          isDark,
          textColor,
          secondaryTextColor,
        ),
        const SizedBox(height: 6),
        _buildDetailRow(
          "lowest_total_income".tr,
          "${minInc.toStringAsFixed(0)} ${'currency'.tr}",
          Icons.keyboard_double_arrow_down_rounded,
          const Color(0xFFB91C1C),
          cardColor,
          isDark,
          textColor,
          secondaryTextColor,
        ),
        const SizedBox(height: 6),
        _buildDetailRow(
          "highest_unstable_expense".tr,
          "${maxExp.toStringAsFixed(0)} ${'currency'.tr}",
          Icons.warning_amber_rounded,
          Colors.redAccent,
          cardColor,
          isDark,
          textColor,
          secondaryTextColor,
        ),
        const SizedBox(height: 6),
        _buildDetailRow(
          "average_unstable_expense".tr,
          "${avgSpending.toStringAsFixed(0)} ${'currency'.tr}",
          Icons.payment_rounded,
          Colors.orangeAccent,
          cardColor,
          isDark,
          textColor,
          secondaryTextColor,
        ),
        const SizedBox(height: 6),
        _buildDetailRow(
          "average_stable_income".tr,
          "${avgStable.toStringAsFixed(0)} ${'currency'.tr}",
          Icons.security_rounded,
          const Color(0xFF00C9FF),
          cardColor,
          isDark,
          textColor,
          secondaryTextColor,
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
    Color accentColor,
    Color cardColor,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (Get.locale?.languageCode != 'ar') ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.elMessiri(
                  color: secondaryTextColor,
                  fontSize: fontSize1,
                ),
              ),
            ],
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.elMessiri(
                color: textColor,
                fontSize: fontSize1,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (Get.locale?.languageCode == 'ar') ...[
              Text(
                label,
                style: GoogleFonts.elMessiri(
                  color: secondaryTextColor,
                  fontSize: fontSize1,
                ),
              ),
              const SizedBox(width: 6),

              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryInputsCard(
    Color cardColor,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
    Size size,
    double fontSize2,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.sync_rounded, size: 20),
                  onPressed: _restoreFromHive,
                  tooltip: "restore_original_values".tr,
                  color: secondaryTextColor,
                ),
                Text(
                  "stats_past_months".tr,
                  style: GoogleFonts.elMessiri(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 6), // Balance the icon button
              ],
            ),
            const SizedBox(height: 6),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2), // Month
                1: FlexColumnWidth(1), // Stable
                2: FlexColumnWidth(1.1), // Unstable Inc
                3: FlexColumnWidth(1), // Expenses
                4: FlexColumnWidth(1.1), // Net
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // Header Row
                TableRow(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: secondaryTextColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ),
                  children: [
                    _buildTableHeader("month_header".tr, secondaryTextColor),
                    _buildTableHeader("stable_income_header".tr, Colors.blue),
                    _buildTableHeader("unstable_income_header".tr, Colors.green),
                    _buildTableHeader("unstable_expense_header".tr, Colors.red),
                    _buildTableHeader("net_income_header".tr, Colors.greenAccent),
                  ],
                ),
                // Data Rows
                ...monthlyStats.asMap().entries.map(
                  (entry) => _buildMonthTableRow(
                    entry.key,
                    isDark,
                    textColor,
                    secondaryTextColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: GoogleFonts.elMessiri(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  TableRow _buildMonthTableRow(
    int index,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final stat = monthlyStats[index];
    num mntincstb = stat['stableIncome'];
    num mntincnstb = stat['unstableIncome'];
    num spending = stat['unstableSpending'];
    num net = mntincstb + mntincnstb - spending;
    String keySuffix = "${stat['year']}_${stat['month']}";

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            stat['monthName'],
            style: GoogleFonts.elMessiri(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        _buildTableInputCell(
          initialValue: mntincstb.toString(),
          onChanged: (val) {
            final v = num.tryParse(val) ?? 0;
            setState(() {
              prefsdata.put("stb_override_$keySuffix", v);
              _populateIncomeFields();
            });
          },
          isDark: isDark,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        _buildTableInputCell(
          initialValue: mntincnstb.toString(),
          onChanged: (val) {
            final v = num.tryParse(val) ?? 0;
            setState(() {
              prefsdata.put("nstb_override_$keySuffix", v);
              _populateIncomeFields();
            });
          },
          isDark: isDark,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        _buildTableInputCell(
          initialValue: spending.toString(),
          onChanged: (val) {
            final v = num.tryParse(val) ?? 0;
            setState(() {
              prefsdata.put("exp_override_$keySuffix", v);
              _populateIncomeFields();
            });
          },
          isDark: isDark,
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            "${net.toStringAsFixed(0)}",
            style: GoogleFonts.elMessiri(
              color: net >= 0 ? textColor : Colors.redAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildTableInputCell({
    required String initialValue,
    required Function(String) onChanged,
    required bool isDark,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        keyboardType: TextInputType.number,
        style: GoogleFonts.elMessiri(color: textColor, fontSize: 10),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 8,
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
