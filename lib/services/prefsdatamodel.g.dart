// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prefsdatamodel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrefsDataStoreAdapter extends TypeAdapter<PrefsDataStore> {
  @override
  final int typeId = 0;

  @override
  PrefsDataStore read(BinaryReader reader) {
    return PrefsDataStore();
  }

  @override
  void write(BinaryWriter writer, PrefsDataStore obj) {
    writer.writeByte(0);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrefsDataStoreAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
