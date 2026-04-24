import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'financial_goal.g.dart';

@HiveType(typeId: 5)
class FinancialGoal extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double targetAmount;

  @HiveField(3)
  final double currentAmount;

  @HiveField(4)
  final DateTime deadline;

  @HiveField(5)
  final String category;

  FinancialGoal({
    String? id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
    required this.deadline,
    this.category = 'other',
  }) : id = id ?? const Uuid().v4();
}
