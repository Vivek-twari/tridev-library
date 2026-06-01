import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../models/seat_model.dart';
import '../models/availability_model.dart';
import 'sync_time_service.dart';

class SeatInitializer {
  static final firestore = FirebaseFirestore.instance;

  static Future<void> initialize() async {
    final seatsBox = Hive.box<SeatModel>("seatsBox");

    final availabilityBox = Hive.box<AvailabilityModel>("availabilityBox");

    // Prevent duplicate creation
    if (seatsBox.isNotEmpty) {
      return;
    }

    final updatedAtEpoch = await SyncTimeService.getServerEpoch();

    // Create 43 seats
    for (int i = 1; i <= 43; i++) {
      final seat = SeatModel(seatNumber: i, updatedAtEpoch: updatedAtEpoch);

      // HIVE
      await seatsBox.put(i, seat);

      // FIRESTORE
      await firestore.collection("seats").doc(i.toString()).set(seat.toMap());
    }

    // Create availability model
    final availability = AvailabilityModel(
      morningSeats: List.generate(43, (i) => i + 1),

      eveningSeats: List.generate(43, (i) => i + 1),

      daySeats: List.generate(43, (i) => i + 1),

      nightSeats: List.generate(43, (i) => i + 1),

      primeSeats: List.generate(43, (i) => i + 1),
      updatedAtEpoch: updatedAtEpoch,
    );

    // HIVE
    await availabilityBox.put("main", availability);

    // FIRESTORE
    await firestore
        .collection("availability")
        .doc("main")
        .set(availability.toMap());
  }
}
