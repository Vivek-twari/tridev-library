import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'payment_model.g.dart';

@HiveType(typeId: 3)
class PaymentModel extends HiveObject {
  @HiveField(0)
  String paymentId;

  @HiveField(1)
  String studentId;

  @HiveField(2)
  String paymentProofUrl;

  @HiveField(3)
  String receiptUrl;

  @HiveField(4)
  int seatNumber;

  @HiveField(5)
  String planType;

  @HiveField(6)
  DateTime expiryDate;

  @HiveField(7)
  int amountPaid;

  @HiveField(8)
  DateTime paymentDate;

  PaymentModel({
    required this.paymentId,

    required this.studentId,

    required this.paymentProofUrl,

    required this.receiptUrl,

    required this.seatNumber,

    required this.planType,

    required this.expiryDate,

    required this.amountPaid,

    required this.paymentDate,
  });

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw ArgumentError('Invalid date value for PaymentModel date field');
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      paymentId: map['paymentId'] as String,
      studentId: map['studentId'] as String,
      paymentProofUrl: map['paymentProofUrl'] as String,
      receiptUrl: map['receiptUrl'] as String,
      seatNumber: map['seatNumber'] as int,
      planType: map['planType'] as String,
      expiryDate: _parseDate(map['expiryDate']),
      amountPaid: map['amountPaid'] as int,
      paymentDate: _parseDate(map['paymentDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'studentId': studentId,
      'paymentProofUrl': paymentProofUrl,
      'receiptUrl': receiptUrl,
      'seatNumber': seatNumber,
      'planType': planType,
      'expiryDate': expiryDate,
      'amountPaid': amountPaid,
      'paymentDate': paymentDate,
    };
  }
}
