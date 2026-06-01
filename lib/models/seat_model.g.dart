// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seat_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SeatModelAdapter extends TypeAdapter<SeatModel> {
  @override
  final int typeId = 1;

  @override
  SeatModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SeatModel(
      seatNumber: (fields[0] as num).toInt(),
      updatedAtEpoch: (fields[6] as num).toInt(),
      morningStudentId: fields[1] as String?,
      eveningStudentId: fields[2] as String?,
      dayStudentId: fields[3] as String?,
      nightStudentId: fields[4] as String?,
      primeStudentId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SeatModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.seatNumber)
      ..writeByte(1)
      ..write(obj.morningStudentId)
      ..writeByte(2)
      ..write(obj.eveningStudentId)
      ..writeByte(3)
      ..write(obj.dayStudentId)
      ..writeByte(4)
      ..write(obj.nightStudentId)
      ..writeByte(5)
      ..write(obj.primeStudentId)
      ..writeByte(6)
      ..write(obj.updatedAtEpoch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeatModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
