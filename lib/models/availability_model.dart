import 'package:hive/hive.dart';

part 'availability_model.g.dart';

@HiveType(typeId: 2)
class AvailabilityModel extends HiveObject {
  @HiveField(0)
  List<int> morningSeats;

  @HiveField(1)
  List<int> eveningSeats;

  @HiveField(2)
  List<int> daySeats;

  @HiveField(3)
  List<int> nightSeats;

  @HiveField(4)
  List<int> primeSeats;
  @HiveField(5)
  final int updatedAtEpoch;

  AvailabilityModel({
    required this.morningSeats,
    required this.eveningSeats,
    required this.daySeats,
    required this.nightSeats,
    required this.primeSeats,
    required this.updatedAtEpoch,
  });
  factory AvailabilityModel.fromMap(Map<String, dynamic> map) {
    return AvailabilityModel(
      morningSeats: List<int>.from(map['morningSeats']),

      eveningSeats: List<int>.from(map['eveningSeats']),

      daySeats: List<int>.from(map['daySeats']),

      nightSeats: List<int>.from(map['nightSeats']),

      primeSeats: List<int>.from(map['primeSeats']),
      updatedAtEpoch: map['updatedAtEpoch'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'morningSeats': morningSeats,
      'eveningSeats': eveningSeats,
      'daySeats': daySeats,
      'nightSeats': nightSeats,
      'primeSeats': primeSeats,
      'updatedAtEpoch': updatedAtEpoch,
    };
  }
}
