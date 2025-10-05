import 'package:budget_it/services/styles%20and%20constants.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  late Box budgetsBox;

  final List<SpendingCategory> categories = [
    SpendingCategory(title: 'الإستخدام الشخصي', description: 'Electricity and water bills', budget: 150),
    SpendingCategory(title: 'الإستخدام المنزلي', description: 'Groceries and dining', budget: 500),
    SpendingCategory(title: 'النقل', description: 'Gas and public transit', budget: 200),
    SpendingCategory(title: 'الترفيه', description: 'Movies and activities', budget: 100),
    SpendingCategory(title: 'الطوارئ', description: 'Other expenses', budget: 100),
    SpendingCategory(title: 'صدقة', description: 'Car maintenance and insurance', budget: 250),
  ];

  final double maxIncrement = 3000;
  double monthlyIncrement = 3000;

  final Color cardColor = const Color.fromRGBO(30, 30, 30, 1.0);
  final List<double> incrementRatios = [0.55, 0.20, 0.10, 0.05, 0.05, 0.05];

  @override
  void initState() {
    super.initState();
    budgetsBox = Hive.box('budgets');
    for (var i = 0; i < categories.length; i++) {
      final saved = budgetsBox.get(categories[i].title);
      if (saved != null) categories[i].budget = saved;
      super.initState();
      cardcolor = prefsdata.get("cardcolor", defaultValue: const Color.fromRGBO(20, 20, 20, 1.0));
    }
    // Correctly load saved increment
    num monthlyIncrement = budgetsBox.get('monthlyIncrement', defaultValue: 3000);
  }

  double getCategoryIncrement(int index) {
    return monthlyIncrement * incrementRatios[index];
  }

  void saveCategoryUpdate(int index, double amount) {
    final keyDate = '${categories[index].title}_lastUpdateDate';
    final keyAmount = '${categories[index].title}_lastUpdateAmount';
    budgetsBox.put(keyDate, DateTime.now().toIso8601String());
    budgetsBox.put(keyAmount, amount);
  }

  double getCurrentBudget(int index) {
    final keyDate = '${categories[index].title}_lastUpdateDate';
    final keyAmount = '${categories[index].title}_lastUpdateAmount';
    final lastUpdateDateStr = budgetsBox.get(keyDate);
    final lastUpdateAmount = budgetsBox.get(keyAmount, defaultValue: categories[index].budget);

    if (lastUpdateDateStr == null) return categories[index].budget;

    final lastUpdateDate = DateTime.parse(lastUpdateDateStr);
    final now = DateTime.now();
    final daysPassed = now.difference(lastUpdateDate).inDays;

    final dailyDecrement = getCategoryIncrement(index) / 30.5;
    final newBudget = lastUpdateAmount - (daysPassed * dailyDecrement);

    return newBudget < 0 ? 0 : newBudget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          ...List.generate(categories.length, (index) {
            return BudgetCard(
              category: categories[index],
              onBudgetChanged: (newValue) {
                setState(() {
                  categories[index].budget = newValue;
                  budgetsBox.put(categories[index].title, newValue);
                  saveCategoryUpdate(index, newValue);
                });
              },
              cardColor: cardColor,
              index: index,
              getCategoryIncrement: getCategoryIncrement,
              getCurrentBudget: getCurrentBudget,
            );
          }),
          Card(
            color: cardColor,
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('الزيادة الشهرية', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text('حدد قيمة الزيادة الشهرية، لا تتجاوز $maxIncrement درهم', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(text: monthlyIncrement.toString()),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'الزيادة الشهرية', border: const OutlineInputBorder(), suffixText: 'درهم', labelStyle: const TextStyle(color: Colors.white)),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      double val = double.tryParse(value) ?? 0;
                      if (val > maxIncrement) val = maxIncrement;
                      setState(() {
                        monthlyIncrement = val;
                        budgetsBox.put('monthlyIncrement', monthlyIncrement);
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            monthlyIncrement = (monthlyIncrement - 10).clamp(0, maxIncrement);
                            budgetsBox.put('monthlyIncrement', monthlyIncrement);
                          });
                        },
                        child: const Text('-10'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            monthlyIncrement = (monthlyIncrement - 1).clamp(0, maxIncrement);
                            budgetsBox.put('monthlyIncrement', monthlyIncrement);
                          });
                        },
                        child: const Text('-1'),
                      ),
                      const SizedBox(width: 40),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            monthlyIncrement = (monthlyIncrement + 1).clamp(0, maxIncrement);
                            budgetsBox.put('monthlyIncrement', monthlyIncrement);
                          });
                        },
                        child: const Text('+1'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            monthlyIncrement = (monthlyIncrement + 10).clamp(0, maxIncrement);
                            budgetsBox.put('monthlyIncrement', monthlyIncrement);
                          });
                        },
                        child: const Text('+10'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('القيمة الحالية: ${monthlyIncrement.toStringAsFixed(2)} درهم', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.green.shade400)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetCard extends StatelessWidget {
  final SpendingCategory category;
  final Function(double) onBudgetChanged;
  final Color cardColor;
  final int index;
  final double Function(int) getCategoryIncrement;
  final double Function(int) getCurrentBudget;

  const BudgetCard({
    super.key,
    required this.category,
    required this.onBudgetChanged,
    required this.cardColor,
    required this.index,
    required this.getCategoryIncrement,
    required this.getCurrentBudget,
  });

  @override
  Widget build(BuildContext context) {
    final List<double> incrementRatios = [0.55, 0.20, 0.10, 0.05, 0.05, 0.05];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF232323), Color(0xFF1A1A1A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), offset: const Offset(0, 4), blurRadius: 10)],
        border: Border.all(color: Colors.green.withOpacity(0.15), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.wallet, color: Colors.green, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(category.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
              ],
            ),
            const SizedBox(height: 8),
            Text(category.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 16),
            Text(
              'نسبة الزيادة الشهرية: ${(incrementRatios[index] * 100).toStringAsFixed(0)}% (${getCategoryIncrement(index).toStringAsFixed(2)} درهم)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.green.shade400, fontSize: 14),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: getCurrentBudget(index).toStringAsFixed(2)),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'الباقي',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.green, width: 1.2)),
                labelStyle: const TextStyle(color: Colors.white),
                floatingLabelAlignment: FloatingLabelAlignment.center,
                suffixText: 'درهم',
                filled: true,
                fillColor: Colors.black.withOpacity(0.15),
              ),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  onBudgetChanged(double.parse(value));
                }
              },
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade900, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => onBudgetChanged(category.budget - 5),
                  child: const Text('-5'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade900, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => onBudgetChanged(category.budget - 1),
                  child: const Text('-1'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade900, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => onBudgetChanged(category.budget + 1),
                  child: const Text('+1'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade900, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => onBudgetChanged(category.budget + 5),
                  child: const Text('+5'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SpendingCategory {
  final String title;
  final String description;
  double budget;

  SpendingCategory({required this.title, required this.description, required this.budget});
}
