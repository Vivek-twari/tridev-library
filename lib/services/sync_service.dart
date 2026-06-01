import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/student_model.dart';
import 'sync_time_service.dart';
import '../models/seat_model.dart';
import '../models/availability_model.dart';

class SyncService {
  static final firestore = FirebaseFirestore.instance;
  static Future<void> syncStudents() async {
    final studentsBox = Hive.box<StudentModel>("studentsBox");

    final cloudStudents = await firestore.collection("students").get();

    for (final doc in cloudStudents.docs) {
      final cloudStudent = StudentModel.fromMap(doc.data());

      final localStudent = studentsBox.get(cloudStudent.id);

      /// local missing
      if (localStudent == null) {
        await studentsBox.put(cloudStudent.id, cloudStudent);

        continue;
      }

      /// same timestamps
      if (SyncTimeService.nearlyEqual(
        cloudStudent.updatedAtEpoch,

        localStudent.updatedAtEpoch,
      )) {
        continue;
      }

      /// cloud newer
      if (cloudStudent.updatedAtEpoch > localStudent.updatedAtEpoch) {
        await studentsBox.put(cloudStudent.id, cloudStudent);
      }
      /// local newer
      else {
        await firestore
            .collection("students")
            .doc(localStudent.id)
            .set(localStudent.toMap());
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

    if (!doc.exists) return;

    final cloudAvailability = AvailabilityModel.fromMap(doc.data()!);

    final localAvailability = availabilityBox.get("main");

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

    /// cloud newer
    if (cloudAvailability.updatedAtEpoch > localAvailability.updatedAtEpoch) {
      await availabilityBox.put("main", cloudAvailability);
    }
    /// local newer
    else {
      await firestore
          .collection("availability")
          .doc("main")
          .set(localAvailability.toMap());
    }
  }

  static Future<void> syncAll() async {
    await syncStudents();

    await syncSeats();

    await syncAvailability();
  }
}
