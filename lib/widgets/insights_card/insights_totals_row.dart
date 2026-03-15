import 'package:flutter/material.dart';
import 'package:budget_it/services/styles%20and%20constants.dart';

class InsightsTotalsRow extends StatelessWidget {
  final num totalSpendingMonth;
  final num totalIncomeMonth;
  final num netMonth;

  const InsightsTotalsRow({
    super.key,
    required this.totalSpendingMonth,
    required this.totalIncomeMonth,
    required this.netMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(15, 106, 253, 95),
            const Color.fromARGB(10, 50, 50, 50),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color.fromRGBO(106, 253, 95, 0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Spending Card
          Expanded(
            child: _StatCard(
              title: 'مجموع المصاريف',
              value: totalSpendingMonth.toString(),
              icon: Icons.trending_down,
              colors: [
                const Color.fromRGBO(253, 95, 95, 0.08),
                const Color.fromRGBO(253, 95, 95, 0.02),
              ],
              borderColor: const Color.fromRGBO(253, 95, 95, 0.2),
              valueColor: const Color.fromRGBO(253, 95, 95, 1.0),
              iconColor: const Color.fromRGBO(253, 95, 95, 1.0),
              iconBgColor: const Color.fromRGBO(253, 95, 95, 0.15),
            ),
          ),
          const SizedBox(width: 10),
          // Net Card
          Expanded(
            child: _StatCard(
              title: 'الرصيد الصافي',
              value: netMonth.toString(),
              icon: netMonth >= 0 ? Icons.trending_up : Icons.trending_down,
              colors: [
                netMonth >= 0
                    ? const Color.fromRGBO(106, 253, 95, 0.08)
                    : const Color.fromRGBO(253, 95, 95, 0.08),
                const Color.fromRGBO(50, 50, 50, 0.02),
              ],
              borderColor: netMonth >= 0
                  ? const Color.fromRGBO(106, 253, 95, 0.2)
                  : const Color.fromRGBO(253, 95, 95, 0.2),
              valueColor:
                  netMonth >= 0 ? Colors.green[300]! : Colors.red[300]!,
              iconColor: netMonth >= 0
                  ? const Color.fromRGBO(106, 253, 95, 1.0)
                  : const Color.fromRGBO(253, 95, 95, 1.0),
              iconBgColor: netMonth >= 0
                  ? const Color.fromRGBO(106, 253, 95, 0.15)
                  : const Color.fromRGBO(253, 95, 95, 0.15),
            ),
          ),
          const SizedBox(width: 10),
          // Income Card
          Expanded(
            child: _StatCard(
              title: 'مجموع المداخيل',
              value: totalIncomeMonth.toString(),
              icon: Icons.trending_up,
              colors: [
                const Color.fromRGBO(106, 253, 95, 0.08),
                const Color.fromRGBO(106, 253, 95, 0.02),
              ],
              borderColor: const Color.fromRGBO(106, 253, 95, 0.2),
              valueColor: const Color.fromRGBO(106, 253, 95, 1.0),
              iconColor: const Color.fromRGBO(106, 253, 95, 1.0),
              iconBgColor: const Color.fromRGBO(106, 253, 95, 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final List<Color> colors;
  final Color borderColor;
  final Color valueColor;
  final Color iconColor;
  final Color iconBgColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.colors,
    required this.borderColor,
    required this.valueColor,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$value درهم',
                style: darktextstyle.copyWith(
                  fontSize: fontSize1 * 1.05,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: darktextstyle.copyWith(
              fontSize: fontSize1 * 0.8,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
