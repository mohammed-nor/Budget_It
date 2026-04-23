import 'package:flutter/material.dart';
import 'package:budget_it/services/styles%20and%20constants.dart';
import 'package:get/get.dart';

class InsightsTopLists extends StatelessWidget {
  final List<dynamic> top3Spending;
  final List<dynamic> top3Income;

  const InsightsTopLists({
    super.key,
    required this.top3Spending,
    required this.top3Income,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Top spendings
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'top_3_expenses'.tr,
                style: darktextstyle.copyWith(fontSize: fontSize1 * 0.8),
              ),
              const SizedBox(height: 8),
              ...top3Spending.map((it) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${it.amount}',
                          style: darktextstyle.copyWith(
                            fontSize: fontSize1,
                            color: const Color.fromRGBO(253, 95, 95, 1.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        it.title ?? '-',
                        style: darktextstyle.copyWith(fontSize: fontSize1),
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
        // Top incomes
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                'top_3_earnings'.tr,
                style: darktextstyle.copyWith(fontSize: fontSize1 * 0.85),
              ),
              const SizedBox(height: 8),
              ...top3Income.map((it) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${it.amount}',
                          style: darktextstyle.copyWith(
                            fontSize: fontSize1,
                            color: const Color.fromRGBO(106, 253, 95, 1.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        it.title ?? '-',
                        style: darktextstyle.copyWith(fontSize: fontSize1),
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
    );
  }
}
