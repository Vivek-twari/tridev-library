import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../models/student_model.dart';
import '../services/seat_service.dart';
import '../services/sync_time_service.dart';
import 'history_service.dart';

class ExpiryService {
  static final firestore = FirebaseFirestore.instance;

  static Future<void> checkExpiredStudents() async {
    final studentsBox = Hive.box<StudentModel>("studentsBox");

    final students = studentsBox.values.toList();

    final now = DateTime.now();

    for (final student in students) {
      /// ONLY ACTIVE + EXPIRED
      if (student.isActive && student.expiryDate.isBefore(now)) {
        try {
          /// SERVER SYNC TIME
          final updatedAtEpoch = await SyncTimeService.getServerEpoch();

          /// FREE SEAT
          await SeatService.freeSeat(
            seatNumber: student.assignedSeat,
            planType: student.planType,
          );

          /// UPDATE AVAILABILITY
          await SeatService.updateAvailability(
            seatNumber: student.assignedSeat,
          );

          /// UPDATE STUDENT
          final updatedStudent = student.copyWith(
            isActive: false,
            updatedAtEpoch: updatedAtEpoch,
          );

          /// HIVE
          await studentsBox.put(student.id, updatedStudent);

          /// FIRESTORE
          await firestore
              .collection("students")
              .doc(student.id)
              .set(updatedStudent.toMap());
          await HistoryService.addEntry(
            text: "${student.name} membership expired automatically",

            type: "cancelled",
          );
        } catch (e) {}
      }
    }
  }
}
