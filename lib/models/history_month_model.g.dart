// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_month_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HistoryMonthModelAdapter extends TypeAdapter<HistoryMonthModel> {
  @override
  final int typeId = 5;

  @override
  HistoryMonthModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HistoryMonthModel(
      monthId: fields[0] as String,
      entries: (fields[1] as List).cast<HistoryEntryModel>(),
      added: (fields[2] as num).toInt(),
      renewed: (fields[3] as num).toInt(),
      cancelled: (fields[4] as num).toInt(),
      deleted: (fields[5] as num).toInt(),
      edited: (fields[6] as num).toInt(),
      planChanged: (fields[7] as num).toInt(),
      seatShifted: (fields[8] as num).toInt(),
      updatedAtEpoch: (fields[9] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, HistoryMonthModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.monthId)
      ..writeByte(1)
      ..write(obj.entries)
      ..writeByte(2)
      ..write(obj.added)
      ..writeByte(3)
      ..write(obj.renewed)
      ..writeByte(4)
      ..write(obj.cancelled)
      ..writeByte(5)
      ..write(obj.deleted)
      ..writeByte(6)
      ..write(obj.edited)
      ..writeByte(7)
      ..write(obj.planChanged)
      ..writeByte(8)
      ..write(obj.seatShifted)
      ..writeByte(9)
      ..write(obj.updatedAtEpoch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryMonthModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
