import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'shift_seat_dialog.dart';
import '../models/payment_model.dart';
import '../models/student_model.dart';
import '../screens/renew_student_screen.dart';
import 'edit_student_screen.dart';
import '../services/student_service.dart';
import 'upgrade_plan_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StudentDetailsScreen extends StatefulWidget {
  final StudentModel student;

  const StudentDetailsScreen({super.key, required this.student});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  final StudentService studentService = StudentService();
  late StudentModel student;
  List<PaymentModel> payments = [];
  @override
  void initState() {
    super.initState();
    student = widget.student;
  }

  void refreshStudent() {
    final studentsBox = Hive.box<StudentModel>("studentsBox");

    final updatedStudent = studentsBox.get(student.id);

    if (updatedStudent != null) {
      student = updatedStudent;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final daysRemaining = student.expiryDate.difference(DateTime.now()).inDays;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),

        foregroundColor: Colors.white,

        elevation: 0,

        title: const Text("Student Details"),

        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),

            onSelected: (value) async {
              if (value == "renew") {
                await Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => RenewStudentScreen(student: student),
                  ),
                );
                if (!mounted) return;
                refreshStudent();

                setState(() {});
              }

              if (value == "shift") {
                await showDialog(
                  context: this.context,

                  builder: (_) => ShiftSeatDialog(student: student),
                );
                if (!mounted) return;
                refreshStudent();

                setState(() {});
              }

              if (value == "edit") {
                await Navigator.push(
                  this.context,

                  MaterialPageRoute(
                    builder: (_) => EditStudentScreen(student: student),
                  ),
                );
                if (!mounted) return;
                refreshStudent();

                setState(() {});
              }

              if (value == "upgrade") {
                await Navigator.push(
                  this.context,

                  MaterialPageRoute(
                    builder: (_) => UpgradePlanScreen(student: student),
                  ),
                );
                if (!mounted) return;
                refreshStudent();

                setState(() {});
              }

              if (value == "delete") {
                await showDialog(
                  context: this.context,

                  builder: (_) => AlertDialog(
                    title: const Text("Delete Student"),

                    content: Text(
                      "Are you sure you want to delete ${student.name}?",
                    ),

                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },

                        child: const Text("Cancel"),
                      ),

                      TextButton(
                        onPressed: () async {
                          await studentService.deleteStudent(student: student);
                          if (!context.mounted) return;

                          Navigator.pop(context);
                          Navigator.pop(context);
                        },

                        child: const Text(
                          "Delete",

                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },

            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "renew",

                child: Row(
                  children: [
                    Icon(Icons.refresh),

                    SizedBox(width: 12),

                    Text("Renew Membership"),
                  ],
                ),
              ),

              const PopupMenuItem(
                value: "shift",

                child: Row(
                  children: [
                    Icon(Icons.event_seat),

                    SizedBox(width: 12),

                    Text("Shift Seat"),
                  ],
                ),
              ),

              const PopupMenuItem(
                value: "edit",

                child: Row(
                  children: [
                    Icon(Icons.edit),

                    SizedBox(width: 12),

                    Text("Edit Details"),
                  ],
                ),
              ),

              const PopupMenuItem(
                value: "upgrade",

                child: Row(
                  children: [
                    Icon(Icons.upgrade),

                    SizedBox(width: 12),

                    Text("Upgrade Plan"),
                  ],
                ),
              ),

              const PopupMenuItem(
                value: "delete",

                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),

                    SizedBox(width: 12),

                    Text("Delete Student"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [
                  /// TOP CARD
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(24),

                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        /// IMAGE
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),

                          child: student.photoUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: student.photoUrl!,

                                  width: 110,
                                  height: 110,

                                  fit: BoxFit.cover,

                                  placeholder: (_, _) => Container(
                                    width: 110,
                                    height: 110,

                                    color: Colors.grey.shade200,

                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),

                                  errorWidget: (_, _, _) => Container(
                                    width: 110,
                                    height: 110,

                                    color: Colors.grey.shade200,

                                    child: const Icon(Icons.person, size: 50),
                                  ),
                                )
                              : Container(
                                  width: 110,
                                  height: 110,

                                  color: Colors.grey.shade200,

                                  child: const Icon(Icons.person, size: 50),
                                ),
                        ),

                        const SizedBox(width: 18),

                        /// DETAILS
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                student.name,

                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),

                                decoration: BoxDecoration(
                                  color: student.isActive
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,

                                  borderRadius: BorderRadius.circular(10),
                                ),

                                child: Text(
                                  student.isActive
                                      ? "Active Member"
                                      : "Expired",

                                  style: TextStyle(
                                    color: student.isActive
                                        ? Colors.green
                                        : Colors.red,

                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    color: Color(0xFF2563EB),
                                  ),

                                  const SizedBox(width: 10),

                                  Text(student.phone),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.credit_card,
                                    color: Color(0xFF2563EB),
                                  ),

                                  const SizedBox(width: 10),

                                  Expanded(
                                    child: Text(
                                      student.adharId ?? "Aadhaar Not Added",
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  /// INFO CARD
                  Container(
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(24),

                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),

                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: buildInfoTile(
                                icon: Icons.chair_alt_rounded,

                                title: "Seat",

                                value: student.assignedSeat.toString(),
                              ),
                            ),

                            Expanded(
                              child: buildInfoTile(
                                icon: Icons.schedule,

                                title: "Plan",

                                value: student.planType,
                              ),
                            ),

                            Expanded(
                              child: buildInfoTile(
                                icon: Icons.calendar_month,

                                title: "Join Date",

                                value: DateFormat(
                                  "dd MMM yyyy",
                                ).format(student.joinDate),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        Container(
                          padding: const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FF),

                            borderRadius: BorderRadius.circular(18),
                          ),

                          child: Row(
                            children: [
                              Expanded(
                                child: buildInfoTile(
                                  icon: Icons.event_available,

                                  title: "Current Expiry",

                                  value: DateFormat(
                                    "dd MMM yyyy",
                                  ).format(student.expiryDate),
                                ),
                              ),

                              Expanded(
                                child: buildInfoTile(
                                  icon: Icons.timelapse,

                                  title: "Days Left",

                                  value: "$daysRemaining Days",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  /// PAYMENTS TITLE
                  const Align(
                    alignment: Alignment.centerLeft,

                    child: Text(
                      "Payments",

                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// PAYMENTS
                  ValueListenableBuilder(
                    valueListenable: Hive.box<PaymentModel>(
                      "paymentsBox",
                    ).listenable(),

                    builder: (context, Box<PaymentModel> box, _) {
                      final payments = box.values
                          .where((payment) => payment.studentId == student.id)
                          .toList();

                      payments.sort(
                        (a, b) => b.paymentDate.compareTo(a.paymentDate),
                      );

                      return ListView.builder(
                        itemCount: payments.length,

                        shrinkWrap: true,

                        physics: const NeverScrollableScrollPhysics(),

                        itemBuilder: (context, index) {
                          final payment = payments[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 18),

                            padding: const EdgeInsets.all(18),

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(24),

                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 8),
                              ],
                            ),

                            child: Column(
                              children: [
                                /// TOP
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),

                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,

                                        borderRadius: BorderRadius.circular(10),
                                      ),

                                      child: const Text(
                                        "Paid",

                                        style: TextStyle(
                                          color: Colors.green,

                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                    const Spacer(),

                                    Text(
                                      "₹ ${payment.amountPaid}",

                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,

                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    /// LEFT
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,

                                        children: [
                                          buildPaymentRow(
                                            Icons.calendar_month,

                                            "Payment Date",

                                            DateFormat(
                                              "dd MMM yyyy",
                                            ).format(payment.paymentDate),
                                          ),

                                          const SizedBox(height: 14),

                                          buildPaymentRow(
                                            Icons.event,

                                            "Valid Till",

                                            DateFormat(
                                              "dd MMM yyyy",
                                            ).format(payment.expiryDate),
                                          ),

                                          const SizedBox(height: 14),

                                          buildPaymentRow(
                                            Icons.receipt_long,

                                            "Plan",

                                            payment.planType,
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    /// IMAGES
                                    Row(
                                      children: [
                                        /// RECEIPT
                                        Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,

                                                  builder: (_) => Dialog(
                                                    child: InteractiveViewer(
                                                      child: CachedNetworkImage(
                                                        imageUrl:
                                                            payment.receiptUrl,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },

                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(14),

                                                child: CachedNetworkImage(
                                                  imageUrl: payment.receiptUrl,

                                                  width: 80,
                                                  height: 100,

                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            const Text("Receipt"),
                                          ],
                                        ),

                                        const SizedBox(width: 14),

                                        /// PAYMENT PROOF
                                        Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                showDialog(
                                                  context: context,

                                                  builder: (_) => Dialog(
                                                    child: InteractiveViewer(
                                                      child: CachedNetworkImage(
                                                        imageUrl: payment
                                                            .paymentProofUrl,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },

                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(14),

                                                child: CachedNetworkImage(
                                                  imageUrl:
                                                      payment.paymentProofUrl,

                                                  width: 80,
                                                  height: 100,

                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 8),

                                            const Text("Proof"),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2563EB)),

        const SizedBox(height: 8),

        Text(title, style: TextStyle(color: Colors.grey.shade700)),

        const SizedBox(height: 6),

        Text(
          value,

          textAlign: TextAlign.center,

          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget buildPaymentRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Icon(icon, size: 20, color: const Color(0xFF2563EB)),

        const SizedBox(width: 10),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600)),

              const SizedBox(height: 4),

              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}
