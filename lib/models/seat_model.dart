import 'package:hive/hive.dart';

part 'seat_model.g.dart';

@HiveType(typeId: 1)
class SeatModel extends HiveObject {
  @HiveField(0)
  int seatNumber;

  @HiveField(1)
  String? morningStudentId;

  @HiveField(2)
  String? eveningStudentId;

  @HiveField(3)
  String? dayStudentId;

  @HiveField(4)
  String? nightStudentId;

  @HiveField(5)
  String? primeStudentId;
  @HiveField(6)
  final int updatedAtEpoch;

  SeatModel({
    required this.seatNumber,
    required this.updatedAtEpoch,

    this.morningStudentId,
    this.eveningStudentId,
    this.dayStudentId,
    this.nightStudentId,
    this.primeStudentId,
  });
  factory SeatModel.fromMap(Map<String, dynamic> map) {
    return SeatModel(
      seatNumber: map['seatNumber'],

      morningStudentId: map['morningStudentId'],

      eveningStudentId: map['eveningStudentId'],

      dayStudentId: map['dayStudentId'],

      nightStudentId: map['nightStudentId'],

      primeStudentId: map['primeStudentId'],
      updatedAtEpoch: map['updatedAtEpoch'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seatNumber': seatNumber,

      'morningStudentId': morningStudentId,

      'eveningStudentId': eveningStudentId,

      'dayStudentId': dayStudentId,

      'nightStudentId': nightStudentId,

      'primeStudentId': primeStudentId,
      'updatedAtEpoch': updatedAtEpoch,
    };
  }
}
