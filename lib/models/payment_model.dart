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
}
