import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class InsightsDistributionChart extends StatelessWidget {
  final List<Map<String, dynamic>> chartData;

  const InsightsDistributionChart({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = chartData.length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(10, 106, 253, 95),
            const Color.fromARGB(5, 50, 50, 50),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color.fromRGBO(106, 253, 95, 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 145,
        child: ExcludeSemantics(
          child: SfCartesianChart(
          primaryXAxis: CategoryAxis(
            labelRotation: 0,
            interval: (daysInMonth / 4).ceilToDouble(),
            majorGridLines: const MajorGridLines(width: 0),
            edgeLabelPlacement: EdgeLabelPlacement.shift,
          ),
          primaryYAxis: NumericAxis(
            labelFormat: '{value}',
            majorGridLines: const MajorGridLines(width: 0.5),
          ),
          tooltipBehavior: TooltipBehavior(enable: true),
          legend: Legend(isVisible: true, position: LegendPosition.bottom),
          series: <CartesianSeries<Map<String, dynamic>, String>>[
            ColumnSeries<Map<String, dynamic>, String>(
              name: 'دخل',
              dataSource: chartData,
              xValueMapper: (m, _) => m['day'] as String,
              yValueMapper: (m, _) => m['income'] as num,
              color: const Color(0xFF15803D),
              animationDuration: 0,
            ),
            ColumnSeries<Map<String, dynamic>, String>(
              name: 'مصاريف',
              dataSource: chartData,
              xValueMapper: (m, _) => m['day'] as String,
              yValueMapper: (m, _) => m['spend'] as num,
              color: const Color(0xFFB91C1C),
              animationDuration: 0,
            ),
          ],
        ),
      ),
    ),
    );
  }
}
