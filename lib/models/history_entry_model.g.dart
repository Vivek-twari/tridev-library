// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryEntryModelAdapter extends TypeAdapter<HistoryEntryModel> {
  @override
  final int typeId = 4;

  @override
  HistoryEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryEntryModel(
      text: fields[0] as String,
      timestamp: (fields[1] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, HistoryEntryModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
