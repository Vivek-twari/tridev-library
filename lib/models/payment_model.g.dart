// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PaymentModelAdapter extends TypeAdapter<PaymentModel> {
  @override
  final int typeId = 3;

  @override
  PaymentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaymentModel(
      paymentId: fields[0] as String,
      studentId: fields[1] as String,
      paymentProofUrl: fields[2] as String,
      receiptUrl: fields[3] as String,
      seatNumber: (fields[4] as num).toInt(),
      planType: fields[5] as String,
      expiryDate: fields[6] as DateTime,
      amountPaid: (fields[7] as num).toInt(),
      paymentDate: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PaymentModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.paymentId)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.paymentProofUrl)
      ..writeByte(3)
      ..write(obj.receiptUrl)
      ..writeByte(4)
      ..write(obj.seatNumber)
      ..writeByte(5)
      ..write(obj.planType)
      ..writeByte(6)
      ..write(obj.expiryDate)
      ..writeByte(7)
      ..write(obj.amountPaid)
      ..writeByte(8)
      ..write(obj.paymentDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
