import 'package:budget_it/utils/language_controller.dart';
import 'package:flutter/material.dart';
import 'package:budget_it/services/styles%20and%20constants.dart';
import 'package:get/get.dart';

class InsightsExpensesIncomeSummary extends StatelessWidget {
  final num fixedExpenses;
  final num avgSpendingsPerMonth;
  final num avgEarningsPerMonth;

  const InsightsExpensesIncomeSummary({
    super.key,
    required this.fixedExpenses,
    required this.avgSpendingsPerMonth,
    required this.avgEarningsPerMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),
          // Variable Expenses & Income Row - Enhanced
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Variable Expenses
              Expanded(
                child: _ExpenseIncomeCard(
                  title: 'variable_label'.tr,
                  label: 'average_label'.tr,
                  value: avgSpendingsPerMonth.toStringAsFixed(0),
                  unit:
                      "${LanguageController.to.currency.value}/${'month_header'.tr}",
                  icon: Icons.trending_down,
                  colors: [
                    const Color.fromRGBO(253, 95, 95, 0.08),
                    const Color.fromRGBO(253, 95, 95, 0.02),
                  ],
                  borderColor: const Color.fromRGBO(253, 95, 95, 0.25),
                  titleColor: const Color.fromRGBO(253, 95, 95, 1.0),
                  valueColor: const Color.fromRGBO(253, 95, 95, 1.0),
                  iconColor: const Color.fromRGBO(253, 95, 95, 1.0),
                  iconBgColor: const Color.fromRGBO(253, 95, 95, 0.2),
                ),
              ),
              const SizedBox(width: 8),
              // Fixed Expenses (represented as a locked icon)
              Expanded(
                child: _ExpenseIncomeCard(
                  title: 'fixed_expenses_label'.tr,
                  label: 'monthly_label'.tr,
                  value: fixedExpenses.toStringAsFixed(0),
                  unit:
                      "${LanguageController.to.currency.value}/${'month_header'.tr}",
                  icon: Icons.lock,
                  colors: [
                    const Color.fromRGBO(253, 150, 95, 0.08),
                    const Color.fromRGBO(253, 150, 95, 0.02),
                  ],
                  borderColor: const Color.fromRGBO(253, 150, 95, 0.25),
                  titleColor: const Color.fromRGBO(253, 150, 95, 1.0),
                  valueColor: const Color.fromRGBO(253, 150, 95, 1.0),
                  iconColor: const Color.fromRGBO(253, 150, 95, 1.0),
                  iconBgColor: const Color.fromRGBO(253, 150, 95, 0.2),
                ),
              ),
              const SizedBox(width: 8),
              // Variable Income
              Expanded(
                child: _ExpenseIncomeCard(
                  title: 'variable_earnings_label'.tr,
                  label: 'average_label'.tr,
                  value: avgEarningsPerMonth.toStringAsFixed(0),
                  unit:
                      "${LanguageController.to.currency.value}/${'month_header'.tr}",
                  icon: Icons.trending_up,
                  colors: [
                    const Color.fromRGBO(106, 253, 95, 0.08),
                    const Color.fromRGBO(106, 253, 95, 0.02),
                  ],
                  borderColor: const Color.fromRGBO(106, 253, 95, 0.25),
                  titleColor: const Color.fromRGBO(106, 253, 95, 1.0),
                  valueColor: const Color.fromRGBO(106, 253, 95, 1.0),
                  iconColor: const Color.fromRGBO(106, 253, 95, 1.0),
                  iconBgColor: const Color.fromRGBO(106, 253, 95, 0.2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseIncomeCard extends StatelessWidget {
  final String title;
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final List<Color> colors;
  final Color borderColor;
  final Color titleColor;
  final Color valueColor;
  final Color iconColor;
  final Color iconBgColor;

  const _ExpenseIncomeCard({
    required this.title,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.colors,
    required this.borderColor,
    required this.titleColor,
    required this.valueColor,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: titleColor.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: darktextstyle.copyWith(
                    fontSize: fontSize1 * 0.8,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: darktextstyle.copyWith(
              fontSize: fontSize1 * 0.7,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: darktextstyle.copyWith(
              fontSize: fontSize1 * 1.1,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Obx(
            () => Text(
              unit,
              style: darktextstyle.copyWith(
                fontSize: fontSize1 * 0.65,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
