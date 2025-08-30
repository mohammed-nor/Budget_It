import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'upcoming_spending.g.dart';

@HiveType(typeId: 3)
class UpcomingSpending {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final num amount;

  UpcomingSpending({String? id, required this.title, required this.date, required this.amount}) : id = id ?? const Uuid().v4();
}
