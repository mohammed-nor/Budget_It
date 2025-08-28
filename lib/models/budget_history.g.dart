// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetHistoryAdapter extends TypeAdapter<BudgetHistory> {
  @override
  final int typeId = 2;

  @override
  BudgetHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BudgetHistory(
      timestamp: fields[0] as DateTime,
      mntsaving: fields[1] as num,
      freemnt: fields[2] as num,
      nownetcredit: fields[3] as num,
    );
  }

  @override
  void write(BinaryWriter writer, BudgetHistory obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.timestamp)
      ..writeByte(1)
      ..write(obj.mntsaving)
      ..writeByte(2)
      ..write(obj.freemnt)
      ..writeByte(3)
      ..write(obj.nownetcredit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
