import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/student_model.dart';
import 'add_student_screen.dart';

class StudentListScreen extends StatelessWidget {
  const StudentListScreen({super.key});

  // Responsive sizing based on screen width
  double getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 12;
    if (width < 480) return 14;
    if (width < 768) return 16;
    return 20;
  }

  double getResponsiveHeaderFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 24;
    if (width < 480) return 28;
    return 34;
  }

  double getResponsiveNameFontSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 14;
    if (width < 480) return 16;
    return 20;
  }

  double getResponsiveAvatarRadius(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 28;
    if (width < 480) return 32;
    return 35;
  }

  double getResponsiveRightSideWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 85;
    if (width < 480) return 95;
    return 110;
  }

  @override
  Widget build(BuildContext context) {
    final studentsBox = Hive.box<StudentModel>("studentsBox");
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 480;
    final responsivePadding = getResponsivePadding(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),

        elevation: 6,

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddStudentScreen()),
          );
        },

        child: const Icon(Icons.add, size: 34, color: Colors.white),
      ),

      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: studentsBox.listenable(),

          builder: (context, box, _) {
            final students = box.values.toList();

            int activeCount = students.where((e) => e.isActive).length;

            int expiringSoon = students.where((e) {
              final difference = e.expiryDate.difference(DateTime.now()).inDays;

              return difference <= 5 && difference >= 0;
            }).length;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: responsivePadding,
                vertical: responsivePadding,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  /// APP BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(18),

                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 10,
                                  color: Colors.black12,
                                ),
                              ],
                            ),

                            child: Icon(
                              Icons.menu,
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Text(
                            "Students",

                            style: TextStyle(
                              fontSize: getResponsiveHeaderFontSize(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      Row(
                        children: [
                          buildTopIcon(Icons.search, context),

                          const SizedBox(width: 12),

                          buildTopIcon(Icons.tune, context),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  /// SEARCH BAR
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 18,
                    ),

                    height: isMediumScreen ? 56 : 64,

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(24),

                      boxShadow: const [
                        BoxShadow(blurRadius: 10, color: Colors.black12),
                      ],
                    ),

                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          color: Colors.grey.shade500,
                          size: isSmallScreen ? 22 : 28,
                        ),

                        const SizedBox(width: 14),

                        Text(
                          "Search by name, phone or seat no.",

                          style: TextStyle(
                            color: Colors.grey.shade500,

                            fontSize: isSmallScreen ? 12 : 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// STATS
                  Row(
                    children: [
                      Expanded(
                        child: buildStatCard(
                          icon: Icons.people,
                          value: students.length.toString(),

                          label: "Total Students",

                          color: const Color(0xFF2563EB),

                          context: context,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: buildStatCard(
                          icon: Icons.check_circle,

                          value: activeCount.toString(),

                          label: "Active",

                          color: const Color(0xFF16A34A),

                          context: context,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: buildStatCard(
                          icon: Icons.timer_outlined,

                          value: expiringSoon.toString(),

                          label: "Expiring Soon",

                          color: const Color(0xFFF59E0B),

                          context: context,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  /// FILTERS
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,

                    child: Row(
                      children: [
                        buildFilterChip(
                          "All",
                          true,
                          const Color(0xFF0B2A6F),
                          context,
                        ),

                        buildFilterChip(
                          "Active",
                          false,
                          const Color(0xFF16A34A),
                          context,
                        ),

                        buildFilterChip(
                          "Expiring Soon",
                          false,
                          const Color(0xFFF59E0B),
                          context,
                        ),

                        buildFilterChip("Expired", false, Colors.red, context),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

                  /// STUDENTS
                  ...students.map((student) {
                    bool expired = student.expiryDate.isBefore(DateTime.now());

                    bool expiringSoon =
                        !expired &&
                        student.expiryDate.difference(DateTime.now()).inDays <=
                            5;

                    Color sideColor = const Color(0xFF16A34A);

                    String status = "Active";

                    if (expired) {
                      sideColor = Colors.red;

                      status = "Expired";
                    } else if (expiringSoon) {
                      sideColor = const Color(0xFFF59E0B);

                      status = "Expiring Soon";
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 18),

                      decoration: BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.circular(28),

                        boxShadow: const [
                          BoxShadow(blurRadius: 12, color: Colors.black12),
                        ],
                      ),

                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: isMediumScreen ? 130 : 150,

                            decoration: BoxDecoration(
                              color: sideColor,

                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(28),

                                bottomLeft: Radius.circular(28),
                              ),
                            ),
                          ),

                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 10 : 16,
                                vertical: isSmallScreen ? 10 : 14,
                              ),

                              child: Row(
                                children: [
                                  /// PROFILE
                                  CircleAvatar(
                                    radius: getResponsiveAvatarRadius(context),

                                    backgroundColor: sideColor.withValues(
                                      alpha: 0.12,
                                    ),

                                    backgroundImage: student.photoUrl != null
                                        ? NetworkImage(student.photoUrl!)
                                        : null,

                                    child: student.photoUrl == null
                                        ? Icon(
                                            Icons.person,

                                            size: getResponsiveAvatarRadius(
                                              context,
                                            ),

                                            color: sideColor,
                                          )
                                        : null,
                                  ),

                                  const SizedBox(width: 14),

                                  /// INFO
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Text(
                                          student.name,

                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,

                                          style: TextStyle(
                                            fontSize: getResponsiveNameFontSize(
                                              context,
                                            ),

                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 6),

                                        buildInfoRow(
                                          Icons.phone,

                                          student.phone,

                                          context,
                                        ),

                                        const SizedBox(height: 6),

                                        buildInfoRow(
                                          Icons.chair,

                                          "Seat ${student.assignedSeat} • ${student.planType}",

                                          context,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10),

                                  /// RIGHT SIDE
                                  SizedBox(
                                    width: getResponsiveRightSideWidth(context),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,

                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: isSmallScreen ? 8 : 12,

                                            vertical: isSmallScreen ? 4 : 6,
                                          ),

                                          decoration: BoxDecoration(
                                            color: sideColor.withValues(
                                              alpha: 0.12,
                                            ),

                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),

                                          child: Text(
                                            status,

                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,

                                            style: TextStyle(
                                              color: sideColor,

                                              fontWeight: FontWeight.bold,

                                              fontSize: isSmallScreen ? 10 : 12,
                                            ),
                                          ),
                                        ),

                                        SizedBox(
                                          height: isSmallScreen ? 8 : 12,
                                        ),

                                        Text(
                                          "Expires on",

                                          style: TextStyle(
                                            color: Colors.grey.shade600,

                                            fontSize: isSmallScreen ? 9 : 11,
                                          ),
                                        ),

                                        SizedBox(height: isSmallScreen ? 2 : 4),

                                        Text(
                                          "${student.expiryDate.day}/${student.expiryDate.month}/${student.expiryDate.year}",

                                          style: TextStyle(
                                            color: sideColor,

                                            fontWeight: FontWeight.bold,

                                            fontSize: isSmallScreen ? 12 : 14,
                                          ),
                                        ),

                                        SizedBox(
                                          height: isSmallScreen ? 8 : 12,
                                        ),

                                        SizedBox(
                                          height: isSmallScreen ? 34 : 38,

                                          child: OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: Color(0xFF2563EB),
                                              ),

                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),

                                              padding: EdgeInsets.zero,
                                            ),

                                            onPressed: () {},

                                            child: Text(
                                              "Renew",

                                              style: TextStyle(
                                                fontSize: isSmallScreen
                                                    ? 10
                                                    : 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildTopIcon(IconData icon, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isSmallScreenHelperContext(context) ? 10 : 12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),

      child: Icon(icon, size: isSmallScreenHelperContext(context) ? 20 : 24),
    );
  }

  bool isSmallScreenHelperContext(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  Widget buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required BuildContext context,
  }) {
    final isSmall = MediaQuery.of(context).size.width < 360;

    return Container(
      padding: EdgeInsets.all(isSmall ? 14 : 18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(26),

        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 10 : 14),

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),

              shape: BoxShape.circle,
            ),

            child: Icon(icon, color: color, size: isSmall ? 20 : 24),
          ),

          SizedBox(height: isSmall ? 12 : 16),

          Text(
            value,

            style: TextStyle(
              fontSize: isSmall ? 24 : 34,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            label,

            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: isSmall ? 12 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFilterChip(
    String text,
    bool selected,
    Color color,
    BuildContext context,
  ) {
    final isSmall = MediaQuery.of(context).size.width < 360;

    return Container(
      margin: EdgeInsets.only(right: isSmall ? 10 : 14),

      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 18 : 24,
        vertical: isSmall ? 10 : 14,
      ),

      decoration: BoxDecoration(
        color: selected ? color : Colors.white,

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: selected ? color : Colors.grey.shade300),
      ),

      child: Text(
        text,

        style: TextStyle(
          color: selected ? Colors.white : color,

          fontWeight: FontWeight.w600,
          fontSize: isSmall ? 12 : 16,
        ),
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String text, BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;

    return Row(
      children: [
        Icon(icon, size: isSmall ? 14 : 16, color: Colors.grey.shade600),

        SizedBox(width: isSmall ? 4 : 6),

        Expanded(
          child: Text(
            text,

            maxLines: 1,
            overflow: TextOverflow.ellipsis,

            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: isSmall ? 12 : 14,
            ),
          ),
        ),
      ],
    );
  }
}
