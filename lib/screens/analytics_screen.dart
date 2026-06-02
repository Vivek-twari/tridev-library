import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/history_month_model.dart';
import '../models/payment_model.dart';
import '../models/student_model.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late String selectedMonthId;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    selectedMonthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final studentsBox = Hive.box<StudentModel>("studentsBox");

    final paymentsBox = Hive.box<PaymentModel>("paymentsBox");

    final historyBox = Hive.box<HistoryMonthModel>("historyBox");

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("Analytics"),

        backgroundColor: Colors.white,
      ),

      body: ValueListenableBuilder(
        valueListenable: historyBox.listenable(),

        builder: (context, Box<HistoryMonthModel> box, _) {
          final monthData = box.get(selectedMonthId);

          final students = studentsBox.values.toList();

          final payments = paymentsBox.values.toList();

          final now = DateTime.now();

          /// MONTHLY PAYMENT
          int monthlyRevenue = 0;

          for (final payment in payments) {
            if (payment.paymentDate.month == now.month &&
                payment.paymentDate.year == now.year) {
              monthlyRevenue += payment.amountPaid;
            }
          }

          /// EXPIRED
          final expiredCount = students
              .where((student) => !student.isActive)
              .length;

          /// EXPIRING SOON
          final expiringSoon = students.where((student) {
            final days = student.expiryDate.difference(now).inDays;

            return student.isActive && days <= 5 && days >= 0;
          }).length;

          /// PLAN COUNTS
          final Map<String, int> planCounts = {};

          for (final student in students) {
            if (!student.isActive) {
              continue;
            }

            planCounts[student.planType] =
                (planCounts[student.planType] ?? 0) + 1;
          }

          final monthEntries = monthData?.entries ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                /// TOP STATS
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final crossAxisCount = width >= 900
                        ? 3
                        : width >= 600
                        ? 2
                        : 1;
                    final childAspectRatio = width >= 900
                        ? 1.4
                        : width >= 600
                        ? 1.45
                        : 2.2;

                    return GridView(
                      shrinkWrap: true,

                      physics: const NeverScrollableScrollPhysics(),

                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,

                        crossAxisSpacing: 14,

                        mainAxisSpacing: 14,

                        childAspectRatio: childAspectRatio,
                      ),

                      children: [
                        buildStatCard("Revenue", "₹$monthlyRevenue"),

                        buildStatCard("Added", "${monthData?.added ?? 0}"),

                        buildStatCard("Renewed", "${monthData?.renewed ?? 0}"),

                        buildStatCard("Expired", "$expiredCount"),

                        buildStatCard("Expiring Soon", "$expiringSoon"),

                        buildStatCard(
                          "Cancelled",
                          "${monthData?.cancelled ?? 0}",
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 28),

                /// PLAN STATS
                const Text(
                  "Plan Statistics",

                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 18),

                ...planCounts.entries.map((entry) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),

                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(22),
                    ),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        Text(
                          entry.key,

                          style: const TextStyle(
                            fontSize: 16,

                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          "${entry.value} Students",

                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 28),

                /// HISTORY HEADER
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 420) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Monthly History",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          DropdownButton<String>(
                            value: selectedMonthId,
                            isExpanded: true,
                            items: historyBox.keys.map((key) {
                              final monthId = key.toString();
                              final date = DateFormat("yyyy-MM").parse(monthId);
                              return DropdownMenuItem(
                                value: monthId,
                                child: Text(
                                  DateFormat("MMMM yyyy").format(date),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setState(() {
                                selectedMonthId = value;
                              });
                            },
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Flexible(
                          child: Text(
                            "Monthly History",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownButton<String>(
                          value: selectedMonthId,
                          items: historyBox.keys.map((key) {
                            final monthId = key.toString();
                            final date = DateFormat("yyyy-MM").parse(monthId);
                            return DropdownMenuItem(
                              value: monthId,
                              child: Text(DateFormat("MMMM yyyy").format(date)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              selectedMonthId = value;
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 18),

                /// HISTORY
                ListView.builder(
                  shrinkWrap: true,

                  physics: const NeverScrollableScrollPhysics(),

                  itemCount: monthEntries.length,

                  itemBuilder: (context, index) {
                    final entry = monthEntries[index];

                    final date = DateTime.fromMillisecondsSinceEpoch(
                      entry.timestamp,
                    );

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),

                      padding: const EdgeInsets.all(18),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(22),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            entry.text,

                            style: const TextStyle(
                              fontSize: 15,

                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            DateFormat("dd MMM yyyy • hh:mm a").format(date),

                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget buildStatCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,

            style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
          ),

          const SizedBox(height: 10),

          Text(
            value,

            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
