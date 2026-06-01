import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/availability_model.dart';

import '../models/seat_model.dart';
import 'sync_time_service.dart';

class SeatService {
  static Future<void> validateSeatAvailability({
    required int seatNumber,

    required String planType,
  }) async {
    final seatDoc = await FirebaseFirestore.instance
        .collection("seats")
        .doc(seatNumber.toString())
        .get();

    if (!seatDoc.exists) {
      throw Exception("Seat does not exist");
    }

    final data = seatDoc.data()!;

    String? currentValue;

    switch (planType) {
      case "Morning":
        currentValue = data["morningStudentId"];

        break;

      case "Evening":
        currentValue = data["eveningStudentId"];

        break;

      case "Day":
        currentValue = data["dayStudentId"];

        break;

      case "Night":
        currentValue = data["nightStudentId"];

        break;

      case "Prime":
        currentValue = data["primeStudentId"];

        break;
    }

    if (currentValue != null && currentValue != "free") {
      throw Exception("Seat slot unavailable");
    }
  }

  static Future<void> updateSeat({
    required int seatNumber,

    required String studentId,

    required String planType,
  }) async {
    String fieldName = "";
    switch (planType) {
      case "Morning":
        fieldName = "morningStudentId";

        break;

      case "Evening":
        fieldName = "eveningStudentId";

        break;

      case "Day":
        fieldName = "dayStudentId";

        break;

      case "Night":
        fieldName = "nightStudentId";

        break;

      case "Prime":
        fieldName = "primeStudentId";

        break;
    }
    final updatedAtEpoch = await SyncTimeService.getServerEpoch();

    await FirebaseFirestore.instance
        .collection("seats")
        .doc(seatNumber.toString())
        .update({fieldName: studentId, "updatedAtEpoch": updatedAtEpoch});
    final seatsBox = Hive.box<SeatModel>("seatsBox");

    final seat = seatsBox.get(seatNumber);
    if (seat == null) return;
    final updatedSeat = SeatModel(
      seatNumber: seat.seatNumber,
      updatedAtEpoch: updatedAtEpoch,
      morningStudentId: seat.morningStudentId,
      eveningStudentId: seat.eveningStudentId,
      dayStudentId: seat.dayStudentId,
      nightStudentId: seat.nightStudentId,
      primeStudentId: seat.primeStudentId,
    );

    switch (planType) {
      case "Morning":
        updatedSeat.morningStudentId = studentId;

        break;

      case "Evening":
        updatedSeat.eveningStudentId = studentId;

        break;

      case "Day":
        updatedSeat.dayStudentId = studentId;

        break;

      case "Night":
        updatedSeat.nightStudentId = studentId;

        break;

      case "Prime":
        updatedSeat.primeStudentId = studentId;

        break;
    }

    await seatsBox.put(seatNumber, updatedSeat);
    await seat.save();
  }

  static Future<void> updateAvailability({required int seatNumber}) async {
    /// GET UPDATED SEAT
    final seatDoc = await FirebaseFirestore.instance
        .collection("seats")
        .doc(seatNumber.toString())
        .get();

    if (!seatDoc.exists) {
      throw Exception("Seat not found");
    }

    final seat = SeatModel.fromMap(seatDoc.data()!);

    /// GET AVAILABILITY
    final availabilityDoc = await FirebaseFirestore.instance
        .collection("availability")
        .doc("main")
        .get();

    if (!availabilityDoc.exists) {
      throw Exception("Availability doc missing");
    }

    final data = availabilityDoc.data()!;

    final morningSeats = List<int>.from(data["morningSeats"]);

    final eveningSeats = List<int>.from(data["eveningSeats"]);

    final daySeats = List<int>.from(data["daySeats"]);

    final nightSeats = List<int>.from(data["nightSeats"]);

    final primeSeats = List<int>.from(data["primeSeats"]);

    /// REMOVE FROM ALL FIRST
    morningSeats.remove(seatNumber);

    eveningSeats.remove(seatNumber);

    daySeats.remove(seatNumber);

    nightSeats.remove(seatNumber);

    primeSeats.remove(seatNumber);

    /// SLOT STATES
    final morningBooked = seat.morningStudentId != null;

    final eveningBooked = seat.eveningStudentId != null;

    final dayBooked = seat.dayStudentId != null;

    final nightBooked = seat.nightStudentId != null;

    final primeBooked = seat.primeStudentId != null;

    /// MORNING
    if (!morningBooked && !dayBooked && !primeBooked) {
      morningSeats.add(seatNumber);
    }

    /// EVENING
    if (!eveningBooked && !dayBooked && !primeBooked) {
      eveningSeats.add(seatNumber);
    }

    /// DAY
    if (!morningBooked && !eveningBooked && !dayBooked && !primeBooked) {
      daySeats.add(seatNumber);
    }

    /// NIGHT
    if (!nightBooked && !primeBooked) {
      nightSeats.add(seatNumber);
    }

    /// PRIME
    if (!morningBooked &&
        !eveningBooked &&
        !dayBooked &&
        !nightBooked &&
        !primeBooked) {
      primeSeats.add(seatNumber);
    }

    /// SORT
    morningSeats.sort();

    eveningSeats.sort();

    daySeats.sort();

    nightSeats.sort();

    primeSeats.sort();

    final updatedAtEpoch = await SyncTimeService.getServerEpoch();

    /// UPDATE FIRESTORE
    await FirebaseFirestore.instance
        .collection("availability")
        .doc("main")
        .update({
          "morningSeats": morningSeats,

          "eveningSeats": eveningSeats,

          "daySeats": daySeats,

          "nightSeats": nightSeats,

          "primeSeats": primeSeats,

          "updatedAtEpoch": updatedAtEpoch,
        });

    /// UPDATE HIVE
    final availabilityBox = Hive.box<AvailabilityModel>("availabilityBox");

    final updatedAvailability = AvailabilityModel(
      morningSeats: morningSeats,

      eveningSeats: eveningSeats,

      daySeats: daySeats,

      nightSeats: nightSeats,

      primeSeats: primeSeats,
      updatedAtEpoch: updatedAtEpoch,
    );

    await availabilityBox.put("main", updatedAvailability);
  }

  static Future<void> freeSeat({
    required int seatNumber,

    required String planType,
  }) async {
    String fieldName = "";

    switch (planType) {
      case "Morning":
        fieldName = "morningStudentId";

        break;

      case "Evening":
        fieldName = "eveningStudentId";

        break;

      case "Day":
        fieldName = "dayStudentId";

        break;

      case "Night":
        fieldName = "nightStudentId";

        break;

      case "Prime":
        fieldName = "primeStudentId";

        break;
    }

    final updatedAtEpoch = await SyncTimeService.getServerEpoch();

    /// FIRESTORE
    await FirebaseFirestore.instance
        .collection("seats")
        .doc(seatNumber.toString())
        .update({fieldName: null, "updatedAtEpoch": updatedAtEpoch});

    /// HIVE
    final seatsBox = Hive.box<SeatModel>("seatsBox");

    final seat = seatsBox.get(seatNumber);

    if (seat == null) return;

    final updatedSeat = SeatModel(
      seatNumber: seat.seatNumber,
      updatedAtEpoch: updatedAtEpoch,
      morningStudentId: seat.morningStudentId,
      eveningStudentId: seat.eveningStudentId,
      dayStudentId: seat.dayStudentId,
      nightStudentId: seat.nightStudentId,
      primeStudentId: seat.primeStudentId,
    );

    switch (planType) {
      case "Morning":
        updatedSeat.morningStudentId = null;

        break;

      case "Evening":
        updatedSeat.eveningStudentId = null;

        break;

      case "Day":
        updatedSeat.dayStudentId = null;

        break;

      case "Night":
        updatedSeat.nightStudentId = null;

        break;

      case "Prime":
        updatedSeat.primeStudentId = null;

        break;
    }

    await seatsBox.put(seatNumber, updatedSeat);
  }
}
