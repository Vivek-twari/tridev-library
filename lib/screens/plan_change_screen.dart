import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/student_model.dart';
import '../models/availability_model.dart';
import '../models/seat_model.dart';
import '../services/seat_service.dart';
import '../services/student_service.dart';
import '../services/sync_time_service.dart';
import '../services/history_service.dart';

enum SlotStatus { available, booked, unavailable }

class ChangePlanScreen extends StatefulWidget {
  final StudentModel student;

  const ChangePlanScreen({super.key, required this.student});

  @override
  State<ChangePlanScreen> createState() => _ChangePlanScreenState();
}

class _ChangePlanScreenState extends State<ChangePlanScreen> {
  final StudentService studentService = StudentService();

  bool isLoading = false;

  String? selectedPlan;
  int? selectedSeat;

  bool changeSeat = false;

  List<int> availableSeats = [];
  Set<String> availablePlansForCurrentSeat = {};

  final List<String> plans = ["Morning", "Evening", "Day", "Night", "Prime"];

  @override
  void initState() {
    super.initState();

    selectedPlan = widget.student.planType;
    _loadAvailablePlansForCurrentSeat();
  }

  Future<void> _loadAvailablePlansForCurrentSeat() async {
    final seatsBox = Hive.box<SeatModel>("seatsBox");
    final seat = seatsBox.get(widget.student.assignedSeat);

    if (seat == null) return;

    final bool m = seat.morningStudentId != null;
    final bool e = seat.eveningStudentId != null;
    final bool d = seat.dayStudentId != null;
    final bool n = seat.nightStudentId != null;
    final bool p = seat.primeStudentId != null;

    final available = <String>{};

    // Current plan is always available
    available.add(widget.student.planType);

    // Morning available if not booked, and day/prime not booked
    if (!m && !d && !p) available.add("Morning");

    // Evening available if not booked, and day/prime not booked
    if (!e && !d && !p) available.add("Evening");

    // Day available if not booked, prime not booked, and morning/evening not booked
    if (!d && !p && !m && !e) available.add("Day");

    // Night available if not booked and prime not booked
    if (!n && !p) available.add("Night");

    // Prime available if nothing else is booked
    if (!m && !e && !d && !n && !p) available.add("Prime");

    setState(() {
      availablePlansForCurrentSeat = available;
    });
  }

  Future<void> loadSeats() async {
    final availabilityBox = Hive.box<AvailabilityModel>("availabilityBox");

    final availability = availabilityBox.get("main");

    if (availability == null) return;

    List<int> seats = [];

    switch (selectedPlan) {
      case "Morning":
        seats = availability.morningSeats;
        break;

      case "Evening":
        seats = availability.eveningSeats;
        break;

      case "Day":
        seats = availability.daySeats;
        break;

      case "Night":
        seats = availability.nightSeats;
        break;

      case "Prime":
        seats = availability.primeSeats;
        break;
    }

    seats.sort();

    setState(() {
      availableSeats = seats;
    });
  }

  Future<void> changePlan() async {
    try {
      setState(() {
        isLoading = true;
      });

      final updatedAtEpoch = await SyncTimeService.getServerEpoch();

      int finalSeat = widget.student.assignedSeat;

      /// CHANGE SEAT
      if (changeSeat &&
          selectedSeat != null &&
          selectedSeat != widget.student.assignedSeat) {
        /// FREE OLD SEAT
        await SeatService.freeSeat(
          seatNumber: widget.student.assignedSeat,
          planType: widget.student.planType,
        );

        await SeatService.updateAvailability(
          seatNumber: widget.student.assignedSeat,
        );

        /// ASSIGN NEW SEAT
        await SeatService.updateSeat(
          seatNumber: selectedSeat!,
          studentId: widget.student.id,
          planType: selectedPlan!,
        );

        await SeatService.updateAvailability(seatNumber: selectedSeat!);

        finalSeat = selectedSeat!;
      }

      /// UPDATE STUDENT
      final updatedStudent = widget.student.copyWith(
        planType: selectedPlan,
        assignedSeat: finalSeat,
        updatedAtEpoch: updatedAtEpoch,
      );

      /// HIVE
      final studentsBox = Hive.box<StudentModel>("studentsBox");

      await studentsBox.put(updatedStudent.id, updatedStudent);

      /// FIRESTORE
      await studentService.saveStudent(updatedStudent);
      await HistoryService.addEntry(
        text:
            "Plan changed for ${widget.student.name} from ${widget.student.planType} to $selectedPlan",

        type: "planChanged",
      );

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Plan Changed Successfully")),
      );
    } catch (e) {
      if (!mounted) return;

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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("Change Plan"),

        backgroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(24),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    "Current Plan: ${widget.student.planType}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Current Seat: ${widget.student.assignedSeat}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Select New Plan",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 12,
              runSpacing: 12,

              children: plans
                  .where((plan) {
                    // If not changing seat, only show available plans for current seat
                    if (!changeSeat) {
                      return availablePlansForCurrentSeat.contains(plan);
                    }
                    // If changing seat, show all plans except current
                    return plan != widget.student.planType;
                  })
                  .map((plan) {
                    bool selected = selectedPlan == plan;

                    return GestureDetector(
                      onTap: () async {
                        setState(() {
                          selectedPlan = plan;
                          selectedSeat = null;
                        });

                        if (changeSeat) {
                          await loadSeats();
                        }
                      },

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),

                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF2563EB)
                              : Colors.white,

                          borderRadius: BorderRadius.circular(20),
                        ),

                        child: Text(
                          plan,

                          style: TextStyle(
                            color: selected ? Colors.white : Colors.black,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),

            const SizedBox(height: 28),

            if (!changeSeat)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2563EB)),
                ),
                child: Text(
                  "Available plans for Seat ${widget.student.assignedSeat}: ${availablePlansForCurrentSeat.toList().join(', ')}",
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            if (!changeSeat) const SizedBox(height: 18),

            SwitchListTile(
              value: changeSeat,

              title: const Text("Change Seat"),

              onChanged: (value) async {
                setState(() {
                  changeSeat = value;
                  selectedSeat = null;
                  if (!value) {
                    selectedPlan = widget.student.planType;
                  }
                });

                if (value && selectedPlan != null) {
                  await loadSeats();
                }
              },
            ),

            if (changeSeat) ...[
              const SizedBox(height: 18),

              DropdownButtonFormField<int>(
                value: selectedSeat,

                decoration: InputDecoration(
                  labelText: selectedPlan != null
                      ? "Select Seat for $selectedPlan"
                      : "Select Plan First",
                  border: const OutlineInputBorder(),
                ),

                items: availableSeats
                    .map(
                      (seat) => DropdownMenuItem(
                        value: seat,

                        child: Text("Seat $seat"),
                      ),
                    )
                    .toList(),

                onChanged: selectedPlan != null
                    ? (value) {
                        setState(() {
                          selectedSeat = value;
                        });
                      }
                    : null,
              ),
            ],

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton(
                onPressed: isLoading ? null : changePlan,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),

                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Changes",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
