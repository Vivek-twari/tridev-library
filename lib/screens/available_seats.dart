import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/availability_model.dart';

class AvailableSeatsScreen extends StatelessWidget {
  const AvailableSeatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("Available Seats"),

        backgroundColor: Colors.white,
      ),

      body: ValueListenableBuilder(
        valueListenable: Hive.box<AvailabilityModel>(
          "availabilityBox",
        ).listenable(),

        builder: (context, Box<AvailabilityModel> box, _) {
          final availability = box.get("main");

          if (availability == null) {
            return const Center(child: Text("No Availability Data"));
          }

          final plans = {
            "Morning": availability.morningSeats,

            "Evening": availability.eveningSeats,

            "Day": availability.daySeats,

            "Night": availability.nightSeats,

            "Prime": availability.primeSeats,
          };

          return ListView(
            padding: const EdgeInsets.all(18),

            children: plans.entries.map((entry) {
              final seats = List<int>.from(entry.value)..sort();

              return Container(
                margin: const EdgeInsets.only(bottom: 18),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(24),
                ),

                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),

                  title: Text(
                    entry.key,

                    style: const TextStyle(
                      fontSize: 18,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text("${seats.length} seats available"),

                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),

                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,

                        children: seats.map((seat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,

                              vertical: 12,
                            ),

                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),

                              borderRadius: BorderRadius.circular(16),
                            ),

                            child: Text(
                              "Seat $seat",

                              style: const TextStyle(
                                color: Colors.white,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
