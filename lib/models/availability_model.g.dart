// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AvailabilityModelAdapter extends TypeAdapter<AvailabilityModel> {
  @override
  final int typeId = 2;

  @override
  AvailabilityModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AvailabilityModel(
      morningSeats: (fields[0] as List).cast<int>(),
      eveningSeats: (fields[1] as List).cast<int>(),
      daySeats: (fields[2] as List).cast<int>(),
      nightSeats: (fields[3] as List).cast<int>(),
      primeSeats: (fields[4] as List).cast<int>(),
      updatedAtEpoch: (fields[5] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, AvailabilityModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.morningSeats)
      ..writeByte(1)
      ..write(obj.eveningSeats)
      ..writeByte(2)
      ..write(obj.daySeats)
      ..writeByte(3)
      ..write(obj.nightSeats)
      ..writeByte(4)
      ..write(obj.primeSeats)
      ..writeByte(5)
      ..write(obj.updatedAtEpoch);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
