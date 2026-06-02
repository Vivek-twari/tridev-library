import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'student_model.g.dart';

@HiveType(typeId: 0)
class StudentModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String planType;

  @HiveField(4)
  DateTime joinDate;

  @HiveField(5)
  DateTime expiryDate;

  @HiveField(6)
  bool isActive;

  @HiveField(7)
  int assignedSeat;
  @HiveField(8)
  String? photoUrl;
  @HiveField(9)
  String? adharId;
  @HiveField(10)
  final int updatedAtEpoch;

  StudentModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.planType,
    required this.joinDate,
    required this.expiryDate,
    required this.isActive,
    required this.assignedSeat,
    this.photoUrl,
    required this.adharId,
    required this.updatedAtEpoch,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      planType: map['planType'],
      joinDate: _parseDate(map['joinDate']),
      expiryDate: _parseDate(map['expiryDate']),
      isActive: map['isActive'],
      assignedSeat: map['assignedSeat'],
      photoUrl: map['photoUrl'],
      adharId: map['adharId'],
      updatedAtEpoch: map['updatedAtEpoch'],
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    throw ArgumentError(
      'Invalid date value for StudentModel: ${value.runtimeType}',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'planType': planType,
      'joinDate': joinDate.toIso8601String(),
      'expiryDate': expiryDate.toIso8601String(),
      'isActive': isActive,
      'assignedSeat': assignedSeat,
      'photoUrl': photoUrl,
      'adharId': adharId,
      'updatedAtEpoch': updatedAtEpoch,
    };
  }

  StudentModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? planType,
    DateTime? joinDate,
    DateTime? expiryDate,
    bool? isActive,
    int? assignedSeat,
    String? photoUrl,
    String? adharId,
    int? updatedAtEpoch,
  }) {
    return StudentModel(
      id: id ?? this.id,

      name: name ?? this.name,

      phone: phone ?? this.phone,

      planType: planType ?? this.planType,

      joinDate: joinDate ?? this.joinDate,

      expiryDate: expiryDate ?? this.expiryDate,

      isActive: isActive ?? this.isActive,

      assignedSeat: assignedSeat ?? this.assignedSeat,

      photoUrl: photoUrl ?? this.photoUrl,

      adharId: adharId ?? this.adharId,

      updatedAtEpoch: updatedAtEpoch ?? this.updatedAtEpoch,
    );
  }
}
