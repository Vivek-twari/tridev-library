import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/student_model.dart';
import '../models/payment_model.dart';
import 'sync_time_service.dart';
import 'seat_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StudentService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final String collection = "students";

  Future<void> saveStudent(StudentModel student) async {
    /// SAVE TO HIVE
    final studentsBox = Hive.box<StudentModel>("studentsBox");

    await studentsBox.put(student.id, student);

    /// SAVE TO FIRESTORE
    await firestore.collection("students").doc(student.id).set({
      "id": student.id,

      "name": student.name,

      "phone": student.phone,

      "planType": student.planType,

      "joinDate": student.joinDate,

      "expiryDate": student.expiryDate,

      "isActive": student.isActive,

      "assignedSeat": student.assignedSeat,

      "photoUrl": student.photoUrl,
      "adharId": student.adharId,
      "updatedAtEpoch": student.updatedAtEpoch,
    });
  }

  Stream<List<StudentModel>> getStudents() {
    return firestore.collection(collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return StudentModel.fromMap(doc.data());
      }).toList();
    });
  }

  Future<void> updateStudent(StudentModel student) async {
    final updatedAtEpoch = await SyncTimeService.getServerEpoch();

    await firestore.collection(collection).doc(student.id).update({
      ...student.toMap(),
      'updatedAtEpoch': updatedAtEpoch,
    });

    final studentsBox = Hive.box<StudentModel>("studentsBox");
    await studentsBox.put(
      student.id,
      StudentModel(
        id: student.id,
        name: student.name,
        phone: student.phone,
        planType: student.planType,
        joinDate: student.joinDate,
        expiryDate: student.expiryDate,
        isActive: student.isActive,
        assignedSeat: student.assignedSeat,
        photoUrl: student.photoUrl,
        adharId: student.adharId,
        updatedAtEpoch: updatedAtEpoch,
      ),
    );
  }

  Future<void> savePayment({
    required String studentId,

    required String paymentProofUrl,

    required int seatNumber,

    required String planType,

    required DateTime expiryDate,

    required int amountPaid,
    required String receiptUrl,
    required String paymentId,
  }) async {
    await firestore
        .collection("students")
        .doc(studentId)
        .collection("payments")
        .doc(paymentId)
        .set({
          "paymentId": paymentId,
          "paymentProofUrl": paymentProofUrl,

          "seatNumber": seatNumber,

          "planType": planType,

          "expiryDate": expiryDate,

          "amountPaid": amountPaid,

          "paymentDate": DateTime.now(),
          "receiptUrl": receiptUrl,
        });
    final paymentsBox = Hive.box<PaymentModel>("paymentsBox");

    final payment = PaymentModel(
      paymentId: paymentId,

      studentId: studentId,

      paymentProofUrl: paymentProofUrl,

      receiptUrl: receiptUrl,

      seatNumber: seatNumber,

      planType: planType,

      expiryDate: expiryDate,

      amountPaid: amountPaid,

      paymentDate: DateTime.now(),
    );

    await paymentsBox.put(paymentId, payment);
  }

  Future<void> renewStudent({
    required String studentId,

    required DateTime newExpiryDate,
  }) async {
    final updatedAtEpoch = await SyncTimeService.getServerEpoch();

    /// FIRESTORE
    await FirebaseFirestore.instance
        .collection("students")
        .doc(studentId)
        .update({
          "expiryDate": Timestamp.fromDate(newExpiryDate),

          "isActive": true,

          "updatedAtEpoch": updatedAtEpoch,
        });

    /// HIVE
    final studentsBox = Hive.box<StudentModel>("studentsBox");

    final student = studentsBox.get(studentId);

    if (student == null) return;

    final updatedStudent = StudentModel(
      id: student.id,
      name: student.name,
      phone: student.phone,
      planType: student.planType,
      joinDate: student.joinDate,
      expiryDate: newExpiryDate,
      isActive: true,
      assignedSeat: student.assignedSeat,
      photoUrl: student.photoUrl,
      adharId: student.adharId,
      updatedAtEpoch: updatedAtEpoch,
    );

    await studentsBox.put(studentId, updatedStudent);
  }

  Future<void> deleteStudent({required StudentModel student}) async {
    /// PAYMENTS
    final paymentsSnapshot = await FirebaseFirestore.instance
        .collection("students")
        .doc(student.id)
        .collection("payments")
        .get();

    final payments = paymentsSnapshot.docs;

    /// FREE SEAT FIRST
    if (student.isActive) {
      await SeatService.freeSeat(
        seatNumber: student.assignedSeat,

        planType: student.planType,
      );

      /// RECALCULATE AVAILABILITY
      await SeatService.updateAvailability(seatNumber: student.assignedSeat);
    }

    /// DELETE STUDENT PHOTO CACHE
    if (student.photoUrl != null) {
      await CachedNetworkImage.evictFromCache(student.photoUrl!);
    }

    /// DELETE STUDENT PHOTO STORAGE
    if (student.photoUrl != null) {
      try {
        await FirebaseStorage.instance.refFromURL(student.photoUrl!).delete();
      } catch (_) {}
    }

    /// DELETE PAYMENT FILES
    for (final payment in payments) {
      final data = payment.data();

      final paymentProofUrl = data["paymentProofUrl"];

      final receiptUrl = data["receiptUrl"];

      /// DELETE PAYMENT PROOF
      if (paymentProofUrl != null) {
        try {
          await CachedNetworkImage.evictFromCache(paymentProofUrl);

          await FirebaseStorage.instance.refFromURL(paymentProofUrl).delete();
        } catch (_) {}
      }

      /// DELETE RECEIPT
      if (receiptUrl != null) {
        try {
          await CachedNetworkImage.evictFromCache(receiptUrl);

          await FirebaseStorage.instance.refFromURL(receiptUrl).delete();
        } catch (_) {}
      }
    }

    /// DELETE PAYMENTS FIRESTORE
    for (final payment in payments) {
      await payment.reference.delete();
    }

    /// DELETE PAYMENTS HIVE
    final paymentsBox = Hive.box<PaymentModel>("paymentsBox");

    final paymentKeys = paymentsBox.keys.where((key) {
      final payment = paymentsBox.get(key);

      return payment?.studentId == student.id;
    }).toList();

    for (final key in paymentKeys) {
      await paymentsBox.delete(key);
    }

    /// DELETE STUDENT FIRESTORE
    await FirebaseFirestore.instance
        .collection("students")
        .doc(student.id)
        .delete();

    /// DELETE STUDENT HIVE
    final studentsBox = Hive.box<StudentModel>("studentsBox");

    await studentsBox.delete(student.id);
  }

  Future<void> updateStudentSeat({
    required String studentId,

    required int newSeat,
  }) async {
    final updatedAtEpoch = await SyncTimeService.getServerEpoch();

    /// FIRESTORE
    await FirebaseFirestore.instance
        .collection("students")
        .doc(studentId)
        .update({"assignedSeat": newSeat, "updatedAtEpoch": updatedAtEpoch});

    /// HIVE
    final studentsBox = Hive.box<StudentModel>("studentsBox");

    final student = studentsBox.get(studentId);

    if (student == null) return;

    final updatedStudent = StudentModel(
      id: student.id,
      name: student.name,
      phone: student.phone,
      planType: student.planType,
      joinDate: student.joinDate,
      expiryDate: student.expiryDate,
      isActive: student.isActive,
      assignedSeat: newSeat,
      photoUrl: student.photoUrl,
      adharId: student.adharId,
      updatedAtEpoch: updatedAtEpoch,
    );

    await studentsBox.put(studentId, updatedStudent);
  }

  Future<void> updateMembership({
    required String studentId,

    required String newPlanType,

    required int newSeat,

    required DateTime expiryDate,
  }) async {
    final updatedAtEpoch = await SyncTimeService.getServerEpoch();

    /// FIRESTORE
    await FirebaseFirestore.instance
        .collection("students")
        .doc(studentId)
        .update({
          "planType": newPlanType,

          "assignedSeat": newSeat,

          "expiryDate": Timestamp.fromDate(expiryDate),

          "updatedAtEpoch": updatedAtEpoch,
        });

    /// HIVE
    final studentsBox = Hive.box<StudentModel>("studentsBox");

    final student = studentsBox.get(studentId);

    if (student == null) return;

    final updatedStudent = StudentModel(
      id: student.id,
      name: student.name,
      phone: student.phone,
      planType: newPlanType,
      joinDate: student.joinDate,
      expiryDate: expiryDate,
      isActive: student.isActive,
      assignedSeat: newSeat,
      photoUrl: student.photoUrl,
      adharId: student.adharId,
      updatedAtEpoch: updatedAtEpoch,
    );

    await studentsBox.put(studentId, updatedStudent);
  }

  Future<void> updatePaymentReceiptUrl({
    required String studentId,

    required String paymentId,

    required String receiptUrl,
  }) async {
    await FirebaseFirestore.instance
        .collection("students")
        .doc(studentId)
        .collection("payments")
        .doc(paymentId)
        .update({"receiptUrl": receiptUrl});

    final paymentsBox = Hive.box<PaymentModel>("paymentsBox");

    final payment = paymentsBox.get(paymentId);

    if (payment == null) return;

    payment.receiptUrl = receiptUrl;

    await payment.save();
  }
}
