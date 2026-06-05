import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/student_model.dart';
import 'sync_time_service.dart';
import '../models/seat_model.dart';
import '../models/availability_model.dart';
import '../models/payment_model.dart';
import '../models/history_month_model.dart';

class SyncService {
  static final firestore = FirebaseFirestore.instance;
  static Future<void> syncStudents([
    QuerySnapshot<Map<String, dynamic>>? studentsSnapshot,
  ]) async {
    final studentsBox = Hive.box<StudentModel>("studentsBox");

    final cloudStudents =
        studentsSnapshot ?? await firestore.collection("students").get();

    /// CLOUD IDS
    final cloudIds = cloudStudents.docs.map((e) => e.id).toSet();

    /// CLOUD → LOCAL
    for (final doc in cloudStudents.docs) {
      late final StudentModel cloudStudent;

      try {
        cloudStudent = StudentModel.fromMap(doc.data());
      } catch (e) {
        debugPrint('Skipping invalid student doc ${doc.id}: $e');

        continue;
      }

      final localStudent = studentsBox.get(cloudStudent.id);

      /// LOCAL MISSING
      if (localStudent == null) {
        await studentsBox.put(cloudStudent.id, cloudStudent);

        continue;
      }

      /// SAME TIMESTAMPS
      if (SyncTimeService.nearlyEqual(
        cloudStudent.updatedAtEpoch,

        localStudent.updatedAtEpoch,
      )) {
        continue;
      }

      /// CLOUD NEWER
      if (cloudStudent.updatedAtEpoch > localStudent.updatedAtEpoch) {
        await studentsBox.put(cloudStudent.id, cloudStudent);
      }
      /// LOCAL NEWER
      else {
        await firestore
            .collection("students")
            .doc(localStudent.id)
            .set(localStudent.toMap());
      }
    }

    /// LOCAL ONLY → DELETE
    /// LOCAL ONLY → DELETE
    for (final localStudent in studentsBox.values.toList()) {
      if (!cloudIds.contains(localStudent.id)) {
        await studentsBox.delete(localStudent.id);
      }
    }
  }

  static Future<void> syncSeats() async {
    final seatsBox = Hive.box<SeatModel>("seatsBox");

    final cloudSeats = await firestore.collection("seats").get();

    for (final doc in cloudSeats.docs) {
      final cloudSeat = SeatModel.fromMap(doc.data());

      final localSeat = seatsBox.get(cloudSeat.seatNumber);

      /// local missing
      if (localSeat == null) {
        await seatsBox.put(cloudSeat.seatNumber, cloudSeat);

        continue;
      }

      /// timestamps same
      if (SyncTimeService.nearlyEqual(
        cloudSeat.updatedAtEpoch,

        localSeat.updatedAtEpoch,
      )) {
        continue;
      }

      /// cloud newer
      if (cloudSeat.updatedAtEpoch > localSeat.updatedAtEpoch) {
        await seatsBox.put(cloudSeat.seatNumber, cloudSeat);
      }
      /// local newer
      else {
        await firestore
            .collection("seats")
            .doc(localSeat.seatNumber.toString())
            .set(localSeat.toMap());
      }
    }
  }

  static Future<void> syncAvailability() async {
    final availabilityBox = Hive.box<AvailabilityModel>("availabilityBox");

    final doc = await firestore.collection("availability").doc("main").get();

    final localAvailability = availabilityBox.get("main");

    /// CLOUD MISSING
    if (!doc.exists) {
      /// LOCAL EXISTS → UPLOAD
      if (localAvailability != null) {
        await firestore
            .collection("availability")
            .doc("main")
            .set(localAvailability.toMap());
      }

      return;
    }

    final cloudAvailability = AvailabilityModel.fromMap(doc.data()!);

    /// LOCAL MISSING
    if (localAvailability == null) {
      await availabilityBox.put("main", cloudAvailability);

      return;
    }

    /// SAME TIMESTAMPS
    if (SyncTimeService.nearlyEqual(
      cloudAvailability.updatedAtEpoch,

      localAvailability.updatedAtEpoch,
    )) {
      return;
    }

    /// CLOUD NEWER
    if (cloudAvailability.updatedAtEpoch > localAvailability.updatedAtEpoch) {
      await availabilityBox.put("main", cloudAvailability);
    }
    /// LOCAL NEWER
    else {
      await firestore
          .collection("availability")
          .doc("main")
          .set(localAvailability.toMap());
    }
  }

  static Future<void> syncPayments([
    QuerySnapshot<Map<String, dynamic>>? studentsSnapshot,
  ]) async {
    final paymentsBox = Hive.box<PaymentModel>("paymentsBox");

    final studentsSnap =
        studentsSnapshot ?? await firestore.collection("students").get();

    // Keep a set of all payment ids present in Firestore to avoid per-doc reads
    final Set<String> cloudPaymentIds = {};

    for (final studentDoc in studentsSnap.docs) {
      final studentId = studentDoc.id;

      final paymentsSnapshot = await firestore
          .collection("students")
          .doc(studentId)
          .collection("payments")
          .get();

      for (final paymentDoc in paymentsSnapshot.docs) {
        cloudPaymentIds.add(paymentDoc.id);

        final cloudData = Map<String, dynamic>.from(paymentDoc.data());
        cloudData['paymentId'] = paymentDoc.id;
        cloudData['studentId'] = studentId;

        final cloudPayment = PaymentModel.fromMap(cloudData);
        final localPayment = paymentsBox.get(cloudPayment.paymentId);

        if (localPayment == null) {
          await paymentsBox.put(cloudPayment.paymentId, cloudPayment);
        }
      }
    }

    // Upload any local payments missing from Firestore using the id set (no extra reads)
    for (final localPayment in paymentsBox.values) {
      if (!cloudPaymentIds.contains(localPayment.paymentId)) {
        await firestore
            .collection("students")
            .doc(localPayment.studentId)
            .collection("payments")
            .doc(localPayment.paymentId)
            .set(localPayment.toMap());
      }
    }
  }

  static Future<void> syncHistory() async {
    final historyBox = Hive.box<HistoryMonthModel>("historyBox");

    final cloudSnapshot = await firestore.collection("history").get();

    for (final doc in cloudSnapshot.docs) {
      final cloud = HistoryMonthModel.fromMap(doc.data());

      final local = historyBox.get(cloud.monthId);

      if (local == null) {
        await historyBox.put(cloud.monthId, cloud);
        continue;
      }

      if (SyncTimeService.nearlyEqual(
        cloud.updatedAtEpoch,
        local.updatedAtEpoch,
      )) {
        continue;
      }

      if (cloud.updatedAtEpoch > local.updatedAtEpoch) {
        await historyBox.put(cloud.monthId, cloud);
      } else {
        await firestore
            .collection("history")
            .doc(local.monthId)
            .set(local.toMap());
      }
    }
  }

  static Future<void> syncAll() async {
    await syncStudents();

    await syncSeats();

    await syncAvailability();
    await syncHistory();
    await syncPayments();
  }
}
