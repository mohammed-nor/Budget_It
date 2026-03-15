import 'package:flutter/material.dart';
import 'package:budget_it/services/styles%20and%20constants.dart';

class InsightsHeader extends StatelessWidget {
  const InsightsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(20, 106, 253, 95),
            const Color.fromARGB(10, 106, 253, 95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromRGBO(106, 253, 95, 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(106, 253, 95, 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.analytics,
              color: Color.fromRGBO(106, 253, 95, 1.0),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'تحليل المصاريف والمداخيل',
            style: darktextstyle.copyWith(
              fontSize: fontSize1 * 1.1,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
