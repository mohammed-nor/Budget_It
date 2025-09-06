import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'unexpected_earning.g.dart';

@HiveType(typeId: 4)
class UnexpectedEarning {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final DateTime date;
  
  @HiveField(3)
  final num amount;

  UnexpectedEarning({
    String? id,
    required this.title, 
    required this.date, 
    required this.amount
  }) : id = id ?? const Uuid().v4();
}