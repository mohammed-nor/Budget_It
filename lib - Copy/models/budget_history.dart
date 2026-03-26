import 'package:hive/hive.dart';

part 'budget_history.g.dart';

@HiveType(typeId: 2)
class BudgetHistory {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final num mntsaving;

  @HiveField(2)
  final num freemnt;

  @HiveField(3)
  final num nownetcredit;

  BudgetHistory({required this.timestamp, required this.mntsaving, required this.freemnt, required this.nownetcredit});
}
