// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upcoming_spending.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UpcomingSpendingAdapter extends TypeAdapter<UpcomingSpending> {
  @override
  final int typeId = 3;

  @override
  UpcomingSpending read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UpcomingSpending(
      id: fields[0] as String?,
      title: fields[1] as String,
      date: fields[2] as DateTime,
      amount: fields[3] as num,
    );
  }

  @override
  void write(BinaryWriter writer, UpcomingSpending obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpcomingSpendingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
