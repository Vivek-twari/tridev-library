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

    /// CLOUD → LOCAL (Handles updates/edits to student details)
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
    /// Since students cannot be added offline, if a student exists locally
    /// but is missing from the cloud, they were deleted from the server.
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

      if (localSeat == null) {
        await seatsBox.put(cloudSeat.seatNumber, cloudSeat);
        continue;
      }

      if (SyncTimeService.nearlyEqual(
        cloudSeat.updatedAtEpoch,
        localSeat.updatedAtEpoch,
      )) {
        continue;
      }

      if (cloudSeat.updatedAtEpoch > localSeat.updatedAtEpoch) {
        await seatsBox.put(cloudSeat.seatNumber, cloudSeat);
      } else {
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

    if (!doc.exists) {
      if (localAvailability != null) {
        await firestore
            .collection("availability")
            .doc("main")
            .set(localAvailability.toMap());
      }
      return;
    }

    final cloudAvailability = AvailabilityModel.fromMap(doc.data()!);

    if (localAvailability == null) {
      await availabilityBox.put("main", cloudAvailability);
      return;
    }

    if (SyncTimeService.nearlyEqual(
      cloudAvailability.updatedAtEpoch,
      localAvailability.updatedAtEpoch,
    )) {
      return;
    }

    if (cloudAvailability.updatedAtEpoch > localAvailability.updatedAtEpoch) {
      await availabilityBox.put("main", cloudAvailability);
    } else {
      await firestore
          .collection("availability")
          .doc("main")
          .set(localAvailability.toMap());
    }
  }

  static Future<void> syncPayments() async {
    final paymentsBox = Hive.box<PaymentModel>("paymentsBox");
    final Set<String> cloudPaymentIds = {};

    /// 🔥 OPTIMIZATION: Pull ALL payments at once via Collection Group
    final paymentsSnapshot = await firestore.collectionGroup("payments").get();

    /// CLOUD → LOCAL
    for (final paymentDoc in paymentsSnapshot.docs) {
      cloudPaymentIds.add(paymentDoc.id);

      final localPayment = paymentsBox.get(paymentDoc.id);

      /// LOCAL MISSING: Save it locally.
      /// (No timestamp check needed since payments are immutable and never edited!)
      if (localPayment == null) {
        final studentId = paymentDoc.reference.parent.parent!.id;
        final cloudData = Map<String, dynamic>.from(paymentDoc.data());

        cloudData['paymentId'] = paymentDoc.id;
        cloudData['studentId'] = studentId;

        final cloudPayment = PaymentModel.fromMap(cloudData);
        await paymentsBox.put(cloudPayment.paymentId, cloudPayment);
      }
    }

    /// LOCAL ONLY → DELETE
    /// Since payments are never created offline, if a payment ID is found in Hive
    /// but isn't present in the cloud, it means it was deleted. Clean it out.
    for (final localPayment in paymentsBox.values.toList()) {
      if (!cloudPaymentIds.contains(localPayment.paymentId)) {
        await paymentsBox.delete(localPayment.paymentId);
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
    // Fetch students once to optimize student list sync
    final studentsSnapshot = await firestore.collection("students").get();

    await syncStudents(studentsSnapshot);
    await syncSeats();
    await syncAvailability();
    await syncHistory();
    await syncPayments(); // Simplified: completely decoupled from students collection reading!
  }
}
