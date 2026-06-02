import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/seat_model.dart';
import '../models/student_model.dart';
import 'student_details_screen.dart';

enum SlotStatus { available, booked, unavailable }

class SeatDetailsScreen extends StatelessWidget {
  final int seatNumber;

  const SeatDetailsScreen({super.key, required this.seatNumber});

  @override
  Widget build(BuildContext context) {
    final seatBox = Hive.box<SeatModel>("seatsBox");

    final seat = seatBox.get(seatNumber);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B2A6F),

        title: const Text(
          "Seat Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// HEADER CARD
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(28),

                boxShadow: const [
                  BoxShadow(blurRadius: 12, color: Colors.black12),
                ],
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        "Seat No.",

                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        seatNumber.toString(),

                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,

                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),

                  const Icon(
                    Icons.chair_rounded,

                    size: 80,

                    color: Color(0xFF3B82F6),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              "Schedule / Slots",

              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 18),

            Builder(
              builder: (context) {
                final bool m = seat?.morningStudentId != null;
                final bool e = seat?.eveningStudentId != null;
                final bool d = seat?.dayStudentId != null;
                final bool n = seat?.nightStudentId != null;
                final bool p = seat?.primeStudentId != null;

                SlotStatus morningStatus() {
                  if (m) return SlotStatus.booked;
                  if (p) return SlotStatus.unavailable;
                  if (d) return SlotStatus.unavailable;
                  return SlotStatus.available;
                }

                SlotStatus eveningStatus() {
                  if (e) return SlotStatus.booked;
                  if (p) return SlotStatus.unavailable;
                  if (d) return SlotStatus.unavailable;
                  return SlotStatus.available;
                }

                SlotStatus dayStatus() {
                  if (d) return SlotStatus.booked;
                  if (p) return SlotStatus.unavailable;
                  if (m || e) return SlotStatus.unavailable;
                  return SlotStatus.available;
                }

                SlotStatus nightStatus() {
                  if (n) return SlotStatus.booked;
                  if (p) return SlotStatus.unavailable;
                  return SlotStatus.available;
                }

                SlotStatus primeStatus() {
                  if (p) return SlotStatus.booked;
                  if (m || e || d || n) return SlotStatus.unavailable;
                  return SlotStatus.available;
                }

                return Column(
                  children: [
                    SlotCard(
                      title: "Morning",
                      timing: "6 AM - 12 PM",
                      studentId: seat?.morningStudentId,
                      icon: Icons.wb_sunny_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      status: morningStatus(),
                    ),

                    SlotCard(
                      title: "Evening",
                      timing: "12 PM - 6 PM",
                      studentId: seat?.eveningStudentId,
                      icon: Icons.sunny,
                      iconColor: const Color(0xFFFF8C42),
                      status: eveningStatus(),
                    ),

                    SlotCard(
                      title: "Day",
                      timing: "6 AM - 6 PM",
                      studentId: seat?.dayStudentId,
                      icon: Icons.light_mode,
                      iconColor: const Color(0xFF3B82F6),
                      status: dayStatus(),
                    ),

                    SlotCard(
                      title: "Night",
                      timing: "6 PM - 6 AM",
                      studentId: seat?.nightStudentId,
                      icon: Icons.nightlight_round,
                      iconColor: const Color(0xFF8B5CF6),
                      status: nightStatus(),
                    ),

                    SlotCard(
                      title: "Prime (24 Hours)",
                      timing: "6 AM - 6 AM",
                      studentId: seat?.primeStudentId,
                      icon: Icons.workspace_premium,
                      iconColor: const Color(0xFFA855F7),
                      status: primeStatus(),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class SlotCard extends StatelessWidget {
  final String title;
  final String timing;

  final String? studentId;
  final SlotStatus status;

  final IconData icon;
  final Color iconColor;

  const SlotCard({
    super.key,
    required this.title,
    required this.timing,
    required this.studentId,
    required this.status,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool booked = status == SlotStatus.booked;
    final bool unavailable = status == SlotStatus.unavailable;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),

      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),

              borderRadius: BorderRadius.circular(18),
            ),

            child: Icon(icon, color: iconColor, size: 30),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  timing,

                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),

                if (booked) ...[
                  const SizedBox(height: 10),

                  Builder(
                    builder: (context) {
                      final studentsBox = Hive.box<StudentModel>("studentsBox");
                      final student = studentId != null
                          ? studentsBox.get(studentId)
                          : null;

                      if (student != null) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    StudentDetailsScreen(student: student),
                              ),
                            );
                          },
                          child: Text(
                            student.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        );
                      }

                      return Text(
                        "Student ID: $studentId",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ] else if (unavailable) ...[
                  const SizedBox(height: 10),
                  Text(
                    "Unavailable",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),

            decoration: BoxDecoration(
              color: booked
                  ? Colors.red.shade100
                  : (unavailable
                        ? Colors.grey.shade200
                        : Colors.green.shade100),

              borderRadius: BorderRadius.circular(30),
            ),

            child: Text(
              booked ? "Booked" : (unavailable ? "Unavailable" : "Available"),

              style: TextStyle(
                color: booked
                    ? Colors.red
                    : (unavailable ? Colors.grey : Colors.green),

                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
