import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/availability_model.dart';
import '../models/student_model.dart';
import '../services/seat_service.dart';
import '../services/student_service.dart';
import '../services/history_service.dart';

class ShiftSeatDialog extends StatefulWidget {
  final StudentModel student;

  const ShiftSeatDialog({super.key, required this.student});

  @override
  State<ShiftSeatDialog> createState() => _ShiftSeatDialogState();
}

class _ShiftSeatDialogState extends State<ShiftSeatDialog> {
  int? selectedSeat;

  bool isLoading = false;

  List<int> availableSeats = [];

  @override
  void initState() {
    super.initState();

    loadSeats();
  }

  void loadSeats() {
    final availabilityBox = Hive.box<AvailabilityModel>("availabilityBox");

    final availability = availabilityBox.get("main");

    if (availability == null) return;

    switch (widget.student.planType) {
      case "Morning":
        availableSeats = availability.morningSeats;

        break;

      case "Evening":
        availableSeats = availability.eveningSeats;

        break;

      case "Day":
        availableSeats = availability.daySeats;

        break;

      case "Night":
        availableSeats = availability.nightSeats;

        break;

      case "Prime":
        availableSeats = availability.primeSeats;

        break;
    }

    /// REMOVE CURRENT SEAT
    availableSeats.remove(widget.student.assignedSeat);

    setState(() {});
  }

  Future<void> shiftSeat() async {
    if (selectedSeat == null) return;

    try {
      setState(() {
        isLoading = true;
      });

      /// FREE OLD SEAT
      await SeatService.freeSeat(
        seatNumber: widget.student.assignedSeat,

        planType: widget.student.planType,
      );

      /// RECALCULATE OLD
      await SeatService.updateAvailability(
        seatNumber: widget.student.assignedSeat,
      );

      /// ASSIGN NEW
      await SeatService.updateSeat(
        seatNumber: selectedSeat!,

        studentId: widget.student.id,

        planType: widget.student.planType,
      );

      /// RECALCULATE NEW
      await SeatService.updateAvailability(seatNumber: selectedSeat!);

      /// UPDATE STUDENT
      await StudentService().updateStudentSeat(
        studentId: widget.student.id,

        newSeat: selectedSeat!,
      );
      await HistoryService.addEntry(
        text:
            "Seat changed for ${widget.student.name} from ${widget.student.assignedSeat} to $selectedSeat",
        type: "seatShifted",
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Seat shifted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Shift Seat"),

      content: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          Text("Current Seat: ${widget.student.assignedSeat}"),

          const SizedBox(height: 18),

          DropdownButtonFormField<int>(
            initialValue: selectedSeat,

            decoration: const InputDecoration(
              labelText: "Select New Seat",

              border: OutlineInputBorder(),
            ),

            items: availableSeats.map((seat) {
              return DropdownMenuItem(value: seat, child: Text("Seat $seat"));
            }).toList(),

            onChanged: (value) {
              setState(() {
                selectedSeat = value;
              });
            },
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: isLoading
              ? null
              : () {
                  Navigator.pop(context);
                },

          child: const Text("Cancel"),
        ),

        ElevatedButton(
          onPressed: selectedSeat == null || isLoading ? null : shiftSeat,

          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,

                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Confirm"),
        ),
      ],
    );
  }
}
