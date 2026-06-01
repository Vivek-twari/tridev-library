import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/student_model.dart';
import '../services/sync_service.dart';
import 'add_student_screen.dart';
import 'renew_student_screen.dart';
import 'student_details_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  late TextEditingController _searchController;
  bool _showSearchBar = false;
  Set<String> selectedPlanTypes = {};
  String selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

            // Filter students based on search query and plan types
            final filteredStudents = students.where((student) {
              final query = _searchController.text.toLowerCase();

              // Search filter
              bool matchesSearch =
                  student.name.toLowerCase().contains(query) ||
                  student.phone.contains(query) ||
                  student.assignedSeat.toString().contains(query);

              // Plan type filter
              bool matchesPlan =
                  selectedPlanTypes.isEmpty ||
                  selectedPlanTypes.contains(student.planType);

              // Status filter
              final now = DateTime.now();
              final isExpired = student.expiryDate.isBefore(now);
              final diffDays = student.expiryDate.difference(now).inDays;
              final isExpiringSoon =
                  !isExpired && diffDays <= 5 && diffDays >= 0;

              bool matchesStatus = true;
              if (selectedStatusFilter == 'Expired') {
                matchesStatus = isExpired;
              } else if (selectedStatusFilter == 'Expiring Soon') {
                matchesStatus = isExpiringSoon;
              }

              return matchesSearch && matchesPlan && matchesStatus;
            }).toList();

            int expiredCount = students
                .where((e) => e.expiryDate.isBefore(DateTime.now()))
                .length;

            int expiringSoon = students.where((e) {
              final difference = e.expiryDate.difference(DateTime.now()).inDays;

              return difference <= 5 && difference >= 0;
            }).length;

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsivePadding,
                    vertical: responsivePadding,
                  ),

                  sliver: SliverToBoxAdapter(
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
                                  padding: EdgeInsets.all(
                                    isSmallScreen ? 10 : 12,
                                  ),

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

                                const SizedBox(width: 10),

                                GestureDetector(
                                  onTap: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Syncing students...'),
                                      ),
                                    );

                                    try {
                                      await SyncService.syncStudents();

                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Students synced successfully',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Sync failed: $e'),
                                        ),
                                      );
                                    }
                                  },
                                  child: buildTopIcon(Icons.sync, context),
                                ),

                                const SizedBox(width: 16),

                                Text(
                                  "Students",

                                  style: TextStyle(
                                    fontSize: getResponsiveHeaderFontSize(
                                      context,
                                    ),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _showSearchBar = !_showSearchBar;
                                      if (!_showSearchBar) {
                                        _searchController.clear();
                                      }
                                    });
                                  },
                                  child: buildTopIcon(Icons.search, context),
                                ),

                                const SizedBox(width: 12),

                                GestureDetector(
                                  onTap: () {
                                    _showPlanFilterBottomSheet(
                                      context,
                                      box.values.toList(),
                                    );
                                  },
                                  child: buildTopIcon(Icons.tune, context),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        /// SEARCH BAR
                        if (_showSearchBar)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 18,
                            ),

                            height: isMediumScreen ? 56 : 64,

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(24),

                              boxShadow: const [
                                BoxShadow(
                                  blurRadius: 10,
                                  color: Colors.black12,
                                ),
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

                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) {
                                      setState(() {});
                                    },
                                    decoration: InputDecoration(
                                      hintText:
                                          "Search by name, phone or seat no.",
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: isSmallScreen ? 12 : 16,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (_showSearchBar) const SizedBox(height: 24),

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

                            const SizedBox(width: 12),

                            Expanded(
                              child: buildStatCard(
                                icon: Icons.check_circle,

                                value: expiredCount.toString(),

                                label: "Expired",

                                color: Colors.red,

                                context: context,
                              ),
                            ),

                            const SizedBox(width: 12),

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
                                selectedStatusFilter == 'All',
                                const Color(0xFF0B2A6F),
                                context,
                                () {
                                  setState(() {
                                    selectedStatusFilter = 'All';
                                  });
                                },
                              ),

                              buildFilterChip(
                                "Expiring Soon",
                                selectedStatusFilter == 'Expiring Soon',
                                const Color(0xFFF59E0B),
                                context,
                                () {
                                  setState(() {
                                    selectedStatusFilter = 'Expiring Soon';
                                  });
                                },
                              ),

                              buildFilterChip(
                                "Expired",
                                selectedStatusFilter == 'Expired',
                                Colors.red,
                                context,
                                () {
                                  setState(() {
                                    selectedStatusFilter = 'Expired';
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),
                      ],
                    ),
                  ),
                ),

                // Students list as its own sliver
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final student = filteredStudents[index];

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

                      child: Container(
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
                                      radius: 38,
                                      backgroundImage: student.photoUrl != null
                                          ? CachedNetworkImageProvider(
                                              student.photoUrl!,
                                            )
                                          : null,
                                      child: student.photoUrl == null
                                          ? const Icon(Icons.person)
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
                                              fontSize:
                                                  getResponsiveNameFontSize(
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
                                      width: getResponsiveRightSideWidth(
                                        context,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isSmallScreen
                                                  ? 8
                                                  : 12,
                                              vertical: isSmallScreen ? 4 : 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: sideColor.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            child: Text(
                                              status,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: sideColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isSmallScreen
                                                    ? 10
                                                    : 12,
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
                                          SizedBox(
                                            height: isSmallScreen ? 2 : 4,
                                          ),
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
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        RenewStudentScreen(
                                                          student: student,
                                                        ),
                                                  ),
                                                );
                                              },
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
                      ),
                    );
                  }, childCount: filteredStudents.length),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showPlanFilterBottomSheet(
    BuildContext context,
    List<StudentModel> students,
  ) {
    // Get unique plan types
    // Define all available plan types
    final planTypes = ['Morning', 'Evening', 'Day', 'Night', 'Prime'];

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter by Plan Type',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0),
                  Expanded(
                    child: ListView.builder(
                      itemCount: planTypes.length,
                      itemBuilder: (context, index) {
                        final planType = planTypes[index];
                        final isSelected = selectedPlanTypes.contains(planType);

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                selectedPlanTypes.remove(planType);
                              } else {
                                selectedPlanTypes.add(planType);
                              }
                            });
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            color: isSelected
                                ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                                : Colors.transparent,
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Color(0xFF2563EB),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    planType,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                selectedPlanTypes.clear();
                              });
                              setState(() {});
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2563EB)),
                            ),
                            child: const Text('Clear All'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                            ),
                            child: const Text('Done'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
      padding: EdgeInsets.all(isSmall ? 10 : 12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 8 : 10),

            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),

              shape: BoxShape.circle,
            ),

            child: Icon(icon, color: color, size: isSmall ? 16 : 18),
          ),

          SizedBox(height: isSmall ? 8 : 10),

          Text(
            value,

            style: TextStyle(
              fontSize: isSmall ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          SizedBox(height: isSmall ? 3 : 4),

          Text(
            label,

            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: isSmall ? 10 : 12,
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
    VoidCallback onTap,
  ) {
    final isSmall = MediaQuery.of(context).size.width < 360;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
