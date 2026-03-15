import 'package:flutter/material.dart';
import 'package:budget_it/services/styles%20and%20constants.dart';
import 'insights_header.dart';
import 'insights_totals_row.dart';
import 'insights_distribution_chart.dart';
import 'insights_expenses_income_summary.dart';
import 'insights_top_lists.dart';

class InsightsCard extends StatelessWidget {
  final List<dynamic> unexpectedEarningsList;
  final List<dynamic> upcomingSpendingList;
  final num mntexp;
  final num annexp;

  const InsightsCard({
    super.key,
    required this.unexpectedEarningsList,
    required this.upcomingSpendingList,
    required this.mntexp,
    required this.annexp,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      color: Theme.of(context).cardColor,
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
                    // Totals row - Enhanced styling
                    InsightsTotalsRow(
                      totalSpendingMonth: totalSpendingMonth,
                      totalIncomeMonth: totalIncomeMonth,
                      netMonth: netMonth,
                    ),
                    const SizedBox(height: 18),
                    // Distribution chart
                    InsightsDistributionChart(
                      chartData: chartData,
                    ),
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

                        // Fixed Expenses: mntexp + annexp/12
                        final num fixedExpenses = mntexp + annexp / 12;

                        // Earnings
                        final totalEarnings = unexpectedEarningsList
                            .fold<num>(0, (sum, e) => sum + e.amount);
                        final avgEarningsPerMonth =
                            totalEarnings / monthsSpan;

                        // Variable Spendings (upcoming spending only)
                        final totalSpendings = upcomingSpendingList
                            .fold<num>(0, (sum, s) => sum + s.amount);
                        final avgSpendingsPerMonth =
                            totalSpendings / monthsSpan;

                        return Column(
                          children: [
                            // Variable Expenses & Income Row
                            InsightsExpensesIncomeSummary(
                              fixedExpenses: fixedExpenses,
                              avgSpendingsPerMonth: avgSpendingsPerMonth,
                              avgEarningsPerMonth: avgEarningsPerMonth,
                            ),
                            const SizedBox(height: 12),
                            // Top-3 lists
                            InsightsTopLists(
                              top3Spending: top3Spending,
                              top3Income: top3Income,
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
