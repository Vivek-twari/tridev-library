import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/seat_model.dart';

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

        actions: [
          TextButton(
            onPressed: () {},

            child: const Text(
              "Edit",

              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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

            SlotCard(
              title: "Morning",
              timing: "6 AM - 12 PM",

              studentId: seat?.morningStudentId,

              icon: Icons.wb_sunny_rounded,

              iconColor: const Color(0xFFF59E0B),
            ),

            SlotCard(
              title: "Evening",
              timing: "12 PM - 6 PM",

              studentId: seat?.eveningStudentId,

              icon: Icons.sunny,

              iconColor: const Color(0xFFFF8C42),
            ),

            SlotCard(
              title: "Day",
              timing: "6 AM - 6 PM",

              studentId: seat?.dayStudentId,

              icon: Icons.light_mode,

              iconColor: const Color(0xFF3B82F6),
            ),

            SlotCard(
              title: "Night",
              timing: "6 PM - 6 AM",

              studentId: seat?.nightStudentId,

              icon: Icons.nightlight_round,

              iconColor: const Color(0xFF8B5CF6),
            ),

            SlotCard(
              title: "Prime (24 Hours)",
              timing: "6 AM - 6 AM",

              studentId: seat?.primeStudentId,

              icon: Icons.workspace_premium,

              iconColor: const Color(0xFFA855F7),
            ),

            const SizedBox(height: 30),

            /// CLEAR BUTTON
            SizedBox(
              width: double.infinity,
              height: 60,

              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade300),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                onPressed: () {},

                icon: const Icon(Icons.delete_outline, color: Colors.red),

                label: const Text(
                  "Clear This Seat",

                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,

                    fontSize: 18,
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

class SlotCard extends StatelessWidget {
  final String title;
  final String timing;

  final String? studentId;

  final IconData icon;
  final Color iconColor;

  const SlotCard({
    super.key,
    required this.title,
    required this.timing,
    required this.studentId,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool booked = studentId != null;

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

                  Text(
                    "Student ID: $studentId",

                    style: const TextStyle(
                      color: Colors.black87,
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
              color: booked ? Colors.red.shade100 : Colors.green.shade100,

              borderRadius: BorderRadius.circular(30),
            ),

            child: Text(
              booked ? "Booked" : "Available",

              style: TextStyle(
                color: booked ? Colors.red : Colors.green,

                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
