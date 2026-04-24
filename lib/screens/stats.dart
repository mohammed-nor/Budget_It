import 'dart:math';
import 'package:budget_it/services/styles%20and%20constants.dart';
import 'package:budget_it/utils/language_controller.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart' as gauge;
import 'package:syncfusion_flutter_charts/charts.dart' as chart;
import 'package:budget_it/models/budget_history.dart';
import 'package:budget_it/models/unexpected_earning.dart';
import 'package:budget_it/models/upcoming_spending.dart';
import 'package:budget_it/models/financial_goal.dart';
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
  Box<FinancialGoal>? goalBox;
  List<BudgetHistory> budgetHistory = [];
  List<FinancialGoal> financialGoals = [];

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
    if (!Hive.isBoxOpen('financial_goals')) {
      await Hive.openBox<FinancialGoal>('financial_goals');
    }
    goalBox = Hive.box<FinancialGoal>('financial_goals');
    _loadGoals();
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

  void _loadGoals() {
    if (goalBox != null) {
      setState(() {
        financialGoals = goalBox!.values.toList();
      });
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
          textAlign: Get.locale?.languageCode == 'ar'
              ? TextAlign.right
              : TextAlign.left,
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

  double _calculateFinancialHealthScore(
    num totalAvg,
    num netAvg,
    num avgSpending,
    num dispersion,
  ) {
    if (totalAvg <= 0) return 0;

    // 1. Savings Rate (40%)
    double savingsRate = (netAvg / totalAvg).clamp(0, 1) * 100;
    double savingsScore = savingsRate * 0.4;

    // 2. Stability (30%)
    double stabilityScore = (1 - dispersion.clamp(0, 1)) * 30;

    // 3. Emergency Fund (30%)
    // Aim for 6 months of spending
    double currentSavings = 0;
    if (historyBox != null && historyBox!.isNotEmpty) {
      currentSavings = historyBox!.values.last.nownetcredit.toDouble();
    }
    double emergencyRatio = avgSpending > 0
        ? (currentSavings / (avgSpending * 6)).clamp(0, 1)
        : 1;
    double emergencyScore = emergencyRatio * 30;

    return (savingsScore + stabilityScore + emergencyScore).clamp(0, 100);
  }

  List<ChartData> _generateWealthProjection(num netAvg) {
    List<ChartData> projection = [];
    double currentWealth = 0;
    if (historyBox != null && historyBox!.isNotEmpty) {
      currentWealth = historyBox!.values.last.nownetcredit.toDouble();
    }

    final now = DateTime.now();
    for (int i = 0; i <= 12; i++) {
      DateTime date = DateTime(now.year, now.month + i, 1);
      String monthKey = [
        'jan',
        'feb',
        'mar',
        'apr',
        'may',
        'jun',
        'jul',
        'aug',
        'sep',
        'oct',
        'nov',
        'dec',
      ][date.month - 1];
      projection.add(
        ChartData("${monthKey.tr} ${date.year}", currentWealth + (netAvg * i)),
      );
    }
    return projection;
  }

  String getMonthName(int index) {
    final List<String> monthKeys = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];

    final now = DateTime.now();
    final targetDate = DateTime(now.year, now.month - index, 1);
    int monthIndex = targetDate.month - 1;

    return monthKeys[monthIndex];
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
            e['monthName'].toString().tr,
            (e['stableIncome'] as num).toDouble() +
                (e['unstableIncome'] as num).toDouble(),
          ),
        )
        .toList();

    final pieData = [
      ChartData(
        'stable_income'.tr,
        avgStable.toDouble(),
        const Color(0xFF15803D),
      ),
      ChartData(
        'unstable_income'.tr,
        avgUnstable.toDouble(),
        const Color(0xFFB91C1C),
      ),
    ];

    return ValueListenableBuilder(
      valueListenable: prefsdata.listenable(
        keys: ['cardcolor', 'fontsize1', 'fontSize1'],
      ),
      builder: (context, box, child) {
        double fontSize1 = box.get("fontsize1", defaultValue: 15.toDouble());
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

              // Expert Analysis Section [NEW]
              _buildExpertAnalysisDashboard(
                totalAvg,
                netAvg,
                avgSpending,
                dispersionIncome,
                effectiveCardColor,
                currentTextColor,
                currentSecondaryTextColor,
              ),
              const SizedBox(height: 6),

              _buildWealthForecastChart(
                netAvg,
                effectiveCardColor,
                isCurrentDark,
                currentTextColor,
                currentSecondaryTextColor,
              ),
              const SizedBox(height: 6),

              _buildGoalsSection(
                netAvg,
                effectiveCardColor,
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

              _buildUnstableTrendsChart(
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
                fontSize1,
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
            value:
                "${totalAvg.toStringAsFixed(0)} ${LanguageController.to.currency.value}",
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
    bool isAr = Get.locale?.languageCode == 'ar';
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
          children: !isAr
              ? [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        textAlign: Get.locale?.languageCode == 'ar'
                            ? TextAlign.right
                            : TextAlign.left,
                        style: GoogleFonts.elMessiri(
                          color: secondaryTextColor,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        textAlign: Get.locale?.languageCode == 'ar'
                            ? TextAlign.right
                            : TextAlign.left,
                        style: GoogleFonts.elMessiri(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                ]
              : [
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        textAlign: Get.locale?.languageCode == 'ar'
                            ? TextAlign.right
                            : TextAlign.left,
                        style: GoogleFonts.elMessiri(
                          color: secondaryTextColor,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        textAlign: Get.locale?.languageCode == 'ar'
                            ? TextAlign.right
                            : TextAlign.left,
                        style: GoogleFonts.elMessiri(
                          color: textColor,
                          fontSize: 15,
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
                fontSize: 11,
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
                fontSize: 11,
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

  Widget _buildUnstableTrendsChart(
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
            e['monthName'].toString().tr,
            (e['unstableSpending'] as num).toDouble(),
          ),
        )
        .toList();

    final earningData = stats.reversed
        .toList()
        .map(
          (e) => ChartData(
            e['monthName'].toString().tr,
            (e['unstableIncome'] as num).toDouble(),
          ),
        )
        .toList();

    final totalIncomeData = stats.reversed
        .toList()
        .map(
          (e) => ChartData(
            e['monthName'].toString().tr,
            (e['stableIncome'] as num).toDouble() +
                (e['unstableIncome'] as num).toDouble(),
          ),
        )
        .toList();

    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(8),
        child: ExcludeSemantics(
          child: chart.SfCartesianChart(
            key: const ValueKey('unstableTrendChart'),
            plotAreaBorderWidth: 0,
            margin: EdgeInsets.zero,
            title: chart.ChartTitle(
              text: 'unstable_trends'.tr,
              textStyle: GoogleFonts.elMessiri(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              alignment: chart.ChartAlignment.center,
            ),
            legend: chart.Legend(
              isVisible: true,
              position: chart.LegendPosition.bottom,
              textStyle: GoogleFonts.elMessiri(
                color: secondaryTextColor,
                fontSize: 10,
              ),
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
              chart.SplineSeries<ChartData, String>(
                name: 'total_income'.tr,
                dataSource: totalIncomeData,
                xValueMapper: (ChartData data, _) => data.x,
                yValueMapper: (ChartData data, _) => data.y,
                color: Colors.blueAccent,
                width: 2,
                dashArray: const <double>[5, 5],
                markerSettings: const chart.MarkerSettings(isVisible: true),
                animationDuration: 0,
              ),
              chart.SplineSeries<ChartData, String>(
                name: 'unstable_income'.tr,
                dataSource: earningData,
                xValueMapper: (ChartData data, _) => data.x,
                yValueMapper: (ChartData data, _) => data.y,
                color: Colors.greenAccent,
                width: 3,
                markerSettings: const chart.MarkerSettings(isVisible: true),
                animationDuration: 0,
              ),
              chart.SplineSeries<ChartData, String>(
                name: 'unstable_spending'.tr,
                dataSource: expenseData,
                xValueMapper: (ChartData data, _) => data.x,
                yValueMapper: (ChartData data, _) => data.y,
                color: Colors.redAccent,
                width: 3,
                markerSettings: const chart.MarkerSettings(isVisible: true),
                animationDuration: 0,
              ),
            ],
            tooltipBehavior: chart.TooltipBehavior(enable: true),
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
                fontSize: 11,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (Get.locale?.languageCode != 'ar') ...[
            Icon(icon, color: accentColor, size: 24),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: GoogleFonts.elMessiri(
              color: textColor,
              fontSize: 15,
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
          "${maxInc.toStringAsFixed(0)} ${LanguageController.to.currency.value}",
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
          "${minInc.toStringAsFixed(0)} ${LanguageController.to.currency.value}",
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
          "${maxExp.toStringAsFixed(0)} ${LanguageController.to.currency.value}",
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
          "${avgSpending.toStringAsFixed(0)} ${LanguageController.to.currency.value}",
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
          "${avgStable.toStringAsFixed(0)} ${LanguageController.to.currency.value}",
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
    bool isAr = Get.locale?.languageCode == 'ar';
    return Card(
      elevation: 2,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: isAr
              ? [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.elMessiri(
                        color: secondaryTextColor,
                        fontSize: fontSize1,
                      ),
                    ),
                  ),

                  Text(
                    value,
                    style: GoogleFonts.elMessiri(
                      color: textColor,
                      fontSize: fontSize1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              : [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.elMessiri(
                        color: secondaryTextColor,
                        fontSize: fontSize1,
                      ),
                    ),
                  ),

                  Text(
                    value,
                    style: GoogleFonts.elMessiri(
                      color: textColor,
                      fontSize: fontSize1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
    double fontSize1,
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
                    _buildTableHeader(
                      "unstable_income_header".tr,
                      Colors.green,
                    ),
                    _buildTableHeader("unstable_expense_header".tr, Colors.red),
                    _buildTableHeader(
                      "net_income_header".tr,
                      Colors.greenAccent,
                    ),
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
            stat['monthName'].toString().tr,
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
            net.toStringAsFixed(0),
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

  // --- EXPERT ANALYSIS WIDGETS ---

  Widget _buildExpertAnalysisDashboard(
    num totalAvg,
    num netAvg,
    num avgSpending,
    num dispersion,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    double healthScore = _calculateFinancialHealthScore(
      totalAvg,
      netAvg,
      avgSpending,
      dispersion,
    );

    return Card(
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withValues(alpha: 0.1),
              Colors.purple.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "financial_health_score".tr,
                        style: GoogleFonts.elMessiri(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        healthScore > 80
                            ? "excellent_standing".tr
                            : healthScore > 60
                            ? "good_standing".tr
                            : "needs_attention".tr,
                        style: GoogleFonts.elMessiri(
                          color: secondaryTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 100,
                    child: gauge.SfRadialGauge(
                      axes: <gauge.RadialAxis>[
                        gauge.RadialAxis(
                          minimum: 0,
                          maximum: 100,
                          showLabels: false,
                          showTicks: false,
                          startAngle: 180,
                          endAngle: 0,
                          canScaleToFit: true,
                          axisLineStyle: const gauge.AxisLineStyle(
                            thickness: 10,
                            cornerStyle: gauge.CornerStyle.bothCurve,
                          ),
                          pointers: <gauge.GaugePointer>[
                            gauge.RangePointer(
                              value: healthScore,
                              width: 10,
                              cornerStyle: gauge.CornerStyle.bothCurve,
                              gradient: const SweepGradient(
                                colors: <Color>[Colors.red, Colors.green],
                                stops: <double>[0.2, 0.8],
                              ),
                            ),
                          ],
                          annotations: <gauge.GaugeAnnotation>[
                            gauge.GaugeAnnotation(
                              widget: Text(
                                healthScore.toStringAsFixed(0),
                                style: GoogleFonts.elMessiri(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              angle: 90,
                              positionFactor: 0.1,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 30, color: Colors.white10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnalysisMetric(
                  "savings_rate".tr,
                  "${(netAvg / (totalAvg > 0 ? totalAvg : 1) * 100).toStringAsFixed(1)}%",
                  Icons.savings_rounded,
                  Colors.greenAccent,
                  textColor,
                ),
                _buildAnalysisMetric(
                  "burn_rate".tr,
                  "${(avgSpending / (totalAvg > 0 ? totalAvg : 1) * 100).toStringAsFixed(1)}%",
                  Icons.local_fire_department_rounded,
                  Colors.orangeAccent,
                  textColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisMetric(
    String label,
    String value,
    IconData icon,
    Color color,
    Color textColor,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.elMessiri(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.elMessiri(fontSize: 10, color: Colors.white60),
        ),
      ],
    );
  }

  Widget _buildWealthForecastChart(
    num netAvg,
    Color cardColor,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final projectionData = _generateWealthProjection(netAvg);

    // Identify Achievement Points
    List<ChartData> goalMarkers = [];
    List<FinancialGoal> upcomingMilestones = [];

    if (netAvg > 0) {
      for (var goal in financialGoals) {
        double remaining = goal.targetAmount - goal.currentAmount;
        int months = (remaining / netAvg).ceil();
        if (months >= 0 && months <= 12) {
          // Add to markers
          goalMarkers.add(
            ChartData(
              projectionData[months].x,
              projectionData[months].y,
              Colors.amber,
            ),
          );
          upcomingMilestones.add(goal);
        }
      }
    }

    return Card(
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withValues(alpha: 0.1),
              Colors.purple.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "wealth_forecast_12m".tr,
                      style: GoogleFonts.elMessiri(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "path_to_wishes".tr,
                      style: GoogleFonts.elMessiri(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Forecast Basis Details
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                title: Row(
                  children: [
                    Icon(Icons.info_outline, color: secondaryTextColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      "forecast_basis".tr,
                      style: GoogleFonts.elMessiri(
                        color: secondaryTextColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildForecastDetail(
                          "current_savings_base".tr,
                          "${projectionData.first.y.toStringAsFixed(0)} ${LanguageController.to.currency.value}",
                          Icons.account_balance_wallet_rounded,
                          Colors.cyanAccent,
                          textColor,
                          secondaryTextColor,
                        ),
                        const SizedBox(height: 8),
                        _buildForecastDetail(
                          "net_monthly_growth".tr,
                          "${netAvg.toStringAsFixed(0)} ${LanguageController.to.currency.value}/${"month".tr}",
                          netAvg >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          netAvg >= 0 ? Colors.greenAccent : Colors.redAccent,
                          textColor,
                          secondaryTextColor,
                        ),
                        const SizedBox(height: 8),
                        _buildForecastDetail(
                          "projected_in_12m".tr,
                          "${projectionData.last.y.toStringAsFixed(0)} ${LanguageController.to.currency.value}",
                          Icons.flag_rounded,
                          Colors.amber,
                          textColor,
                          secondaryTextColor,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "forecast_methodology".tr,
                          style: GoogleFonts.elMessiri(
                            color: secondaryTextColor,
                            fontSize: 9,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: chart.SfCartesianChart(
                plotAreaBorderWidth: 0,
                margin: EdgeInsets.zero,
                primaryXAxis: chart.CategoryAxis(
                  majorGridLines: const chart.MajorGridLines(width: 0),
                  labelStyle: GoogleFonts.elMessiri(
                    color: secondaryTextColor,
                    fontSize: 8,
                  ),
                  axisLine: const chart.AxisLine(width: 0),
                ),
                primaryYAxis: chart.NumericAxis(
                  axisLine: const chart.AxisLine(width: 0),
                  majorTickLines: const chart.MajorTickLines(size: 0),
                  majorGridLines: chart.MajorGridLines(
                    width: 0.5,
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                  labelStyle: GoogleFonts.elMessiri(
                    color: secondaryTextColor,
                    fontSize: 8,
                  ),
                ),
                series: <chart.CartesianSeries<ChartData, String>>[
                  chart.SplineAreaSeries<ChartData, String>(
                    dataSource: projectionData,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    gradient: LinearGradient(
                      colors: [
                        Colors.blueAccent.withValues(alpha: 0.4),
                        Colors.blueAccent.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderColor: Colors.blueAccent,
                    borderWidth: 3,
                    animationDuration: 1500,
                  ),
                  chart.ScatterSeries<ChartData, String>(
                    dataSource: goalMarkers,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    markerSettings: const chart.MarkerSettings(
                      height: 15,
                      width: 15,
                      shape: chart.DataMarkerType.diamond,
                      color: Colors.amber,
                      borderWidth: 2,
                      borderColor: Colors.white,
                    ),
                  ),
                ],
                tooltipBehavior: chart.TooltipBehavior(
                  enable: true,
                  header: "achievement".tr,
                  format: "point.x : point.y",
                ),
              ),
            ),
            if (upcomingMilestones.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                "upcoming_achievements".tr,
                style: GoogleFonts.elMessiri(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: upcomingMilestones.length,
                  itemBuilder: (context, index) {
                    final goal = upcomingMilestones[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            goal.category == 'home'
                                ? Icons.home_rounded
                                : goal.category == 'car'
                                ? Icons.directions_car_rounded
                                : goal.category == 'vacation'
                                ? Icons.beach_access_rounded
                                : Icons.star_rounded,
                            size: 14,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            goal.title,
                            style: GoogleFonts.elMessiri(
                              color: textColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            if (netAvg < 0)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "negative_growth_warning".tr,
                        style: GoogleFonts.elMessiri(
                          color: Colors.redAccent,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastDetail(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.elMessiri(
              color: secondaryTextColor,
              fontSize: 10,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.elMessiri(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsSection(
    num netAvg,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "financial_wishes".tr,
                style: GoogleFonts.elMessiri(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddGoalDialog,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: Text("make_a_wish".tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (financialGoals.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "no_wishes_yet".tr,
                style: GoogleFonts.elMessiri(color: secondaryTextColor),
              ),
            ),
          )
        else
          ...financialGoals.map(
            (goal) => _buildGoalCard(
              goal,
              netAvg,
              cardColor,
              textColor,
              secondaryTextColor,
            ),
          ),
      ],
    );
  }

  Widget _buildGoalCard(
    FinancialGoal goal,
    num netAvg,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    double progress = (goal.currentAmount / goal.targetAmount).clamp(0, 1);
    double remaining = goal.targetAmount - goal.currentAmount;

    // Evaluation Logic
    int monthsToAchieve = netAvg > 0 ? (remaining / netAvg).ceil() : -1;
    DateTime projectedAchieveDate = monthsToAchieve != -1
        ? DateTime.now().add(Duration(days: monthsToAchieve * 30))
        : DateTime.now();

    bool isOnTrack =
        monthsToAchieve != -1 && projectedAchieveDate.isBefore(goal.deadline);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    goal.category == 'home'
                        ? Icons.home_rounded
                        : goal.category == 'car'
                        ? Icons.directions_car_rounded
                        : goal.category == 'vacation'
                        ? Icons.beach_access_rounded
                        : Icons.star_rounded,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: GoogleFonts.elMessiri(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "${"target".tr}: ${goal.targetAmount.toStringAsFixed(0)} ${LanguageController.to.currency.value}",
                        style: GoogleFonts.elMessiri(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () => _deleteGoal(goal.id),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8 ? Colors.greenAccent : Colors.blueAccent,
              ),
              borderRadius: BorderRadius.circular(10),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isOnTrack ? Icons.check_circle_outline : Icons.info_outline,
                    color: isOnTrack ? Colors.greenAccent : Colors.orangeAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthsToAchieve == -1
                              ? "income_too_low_for_goal".tr
                              : isOnTrack
                              ? "${"on_track_to_achieve".tr} ${monthsToAchieve} ${"months".tr}"
                              : "${"requires_boost".tr}: ${(remaining / (goal.deadline.difference(DateTime.now()).inDays / 30)).toStringAsFixed(0)} ${"per_month".tr}",
                          style: GoogleFonts.elMessiri(
                            color: isOnTrack
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${"monthly_requirement".tr}: ${(remaining / (goal.deadline.difference(DateTime.now()).inDays / 30)).toStringAsFixed(0)} ${LanguageController.to.currency.value}/${"month".tr}",
                          style: GoogleFonts.elMessiri(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 365));
    String selectedCategory = 'other';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "make_a_wish".tr,
            style: GoogleFonts.elMessiri(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "goal_title".tr,
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "target_amount".tr,
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "category".tr,
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'home',
                      child: Text("home_loan".tr),
                    ),
                    DropdownMenuItem(value: 'car', child: Text("car_loan".tr)),
                    DropdownMenuItem(
                      value: 'vacation',
                      child: Text("vacation".tr),
                    ),
                    DropdownMenuItem(value: 'other', child: Text("other".tr)),
                  ],
                  onChanged: (v) => setState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(
                    "deadline".tr,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  subtitle: Text(
                    "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: const Icon(
                    Icons.calendar_today,
                    color: Colors.blueAccent,
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => selectedDate = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "cancel".tr,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  _addGoal(
                    titleController.text,
                    double.parse(amountController.text),
                    selectedDate,
                    selectedCategory,
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: Text("add_goal".tr),
            ),
          ],
        ),
      ),
    );
  }

  void _addGoal(
    String title,
    double amount,
    DateTime deadline,
    String category,
  ) {
    if (goalBox != null) {
      final goal = FinancialGoal(
        title: title,
        targetAmount: amount,
        deadline: deadline,
        category: category,
      );
      goalBox!.add(goal);
      _loadGoals();
    }
  }

  void _deleteGoal(String id) {
    if (goalBox != null) {
      final index = goalBox!.values.toList().indexWhere((g) => g.id == id);
      if (index != -1) {
        goalBox!.deleteAt(index);
        _loadGoals();
      }
    }
  }
}
