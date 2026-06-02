import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/seat_model.dart';
import '../services/sync_service.dart';
import 'seat_details_screen.dart';

class SeatScreen extends StatelessWidget {
  const SeatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final seatsBox = Hive.box<SeatModel>("seatsBox");

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0B2A6F),

        title: const Text(
          "Seats",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),

        actions: [
          IconButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);

              // manual sync cooldown: 2 minutes
              final prefs = await SharedPreferences.getInstance();
              final lastManual = prefs.getInt('last_manual_sync_epoch') ?? 0;
              final nowEpoch = DateTime.now().millisecondsSinceEpoch;
              const cooldownMs = 2 * 60 * 1000; // 2 minutes

              if (lastManual != 0 && nowEpoch - lastManual < cooldownMs) {
                final waitSeconds =
                    ((cooldownMs - (nowEpoch - lastManual)) / 1000).ceil();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please wait $waitSeconds seconds before syncing again',
                    ),
                  ),
                );
                return;
              }

              messenger.showSnackBar(
                const SnackBar(content: Text('Syncing seats...')),
              );

              try {
                await SyncService.syncSeats();
                await prefs.setInt(
                  'last_manual_sync_epoch',
                  DateTime.now().millisecondsSinceEpoch,
                );
                messenger.showSnackBar(
                  const SnackBar(content: Text('Seats synced successfully')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Sync failed: $e')),
                );
              }
            },
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),

      body: Column(
        children: [
          /// TOP LEGEND
          Container(
            width: double.infinity,
            color: Colors.white,

            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,

              children: const [
                LegendItem(color: Color(0xFF22C55E), title: "Available"),

                LegendItem(color: Color(0xFF3B82F6), title: "Occupied"),

                LegendItem(color: Color(0xFFA855F7), title: "Prime (24H)"),
              ],
            ),
          ),

          Expanded(
            child: ValueListenableBuilder(
              valueListenable: seatsBox.listenable(),

              builder: (context, box, _) {
                final seats = box.values.toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(18),

                  child: Container(
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(28),

                      border: Border.all(color: Colors.red.shade300, width: 2),

                      boxShadow: const [
                        BoxShadow(blurRadius: 12, color: Colors.black12),
                      ],
                    ),

                    child: Wrap(
                      spacing: 18,
                      runSpacing: 18,

                      alignment: WrapAlignment.center,

                      children: seats.map((seat) {
                        bool isPrime = seat.primeStudentId != null;

                        bool occupied =
                            seat.morningStudentId != null ||
                            seat.eveningStudentId != null ||
                            seat.dayStudentId != null ||
                            seat.nightStudentId != null;

                        Color color = const Color(0xFF22C55E);

                        String status = "Available";

                        IconData icon = Icons.circle;

                        if (isPrime) {
                          color = const Color(0xFFA855F7);

                          status = "Prime";

                          icon = Icons.person;
                        } else if (occupied) {
                          color = const Color(0xFF3B82F6);

                          status = "Occupied";

                          icon = Icons.person;
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SeatDetailsScreen(
                                  seatNumber: seat.seatNumber,
                                ),
                              ),
                            );
                          },

                          child: Container(
                            width: seat.seatNumber == 43 ? 140 : 125,

                            padding: const EdgeInsets.symmetric(vertical: 16),

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(20),

                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 8,
                                  color: Colors.black12,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),

                            child: Column(
                              mainAxisSize: MainAxisSize.min,

                              children: [
                                Icon(icon, color: color, size: 24),

                                const SizedBox(height: 8),

                                Text(
                                  seat.seatNumber.toString(),

                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  status,

                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class LegendItem extends StatelessWidget {
  final Color color;
  final String title;

  const LegendItem({super.key, required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,

          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 8),

        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
