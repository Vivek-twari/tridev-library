import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/student_model.dart';
import '../services/student_service.dart';
import '../services/storage_service.dart';
import 'receipt_screen.dart';

class RenewStudentScreen extends StatefulWidget {
  final StudentModel student;

  const RenewStudentScreen({super.key, required this.student});

  @override
  State<RenewStudentScreen> createState() => _RenewStudentScreenState();
}

class _RenewStudentScreenState extends State<RenewStudentScreen> {
  final TextEditingController amountController = TextEditingController();

  final StudentService studentService = StudentService();

  final uuid = const Uuid();

  File? paymentProofImage;

  bool isLoading = false;

  bool useCustomDays = false;

  int selectedMonths = 1;

  int customDays = 30;

  DateTime calculatedExpiryDate = DateTime.now();

  String? receiptUrl;

  late final String paymentId;

  late final String receiptId;

  @override
  void initState() {
    super.initState();

    paymentId = uuid.v4();

    receiptId = uuid.v4();

    calculateExpiryDate();
  }

  bool get isFormValid {
    return paymentProofImage != null &&
        amountController.text.trim().isNotEmpty &&
        int.tryParse(amountController.text.trim()) != null &&
        int.parse(amountController.text.trim()) >= 800;
  }

  Future<void> pickPaymentProof() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (picked == null) return;

    setState(() {
      paymentProofImage = File(picked.path);
    });
  }

  void calculateExpiryDate() {
    final now = DateTime.now();

    final currentExpiry = widget.student.expiryDate;

    final baseDate = currentExpiry.isAfter(now) ? currentExpiry : now;

    if (useCustomDays) {
      calculatedExpiryDate = baseDate.add(Duration(days: customDays));
    } else {
      calculatedExpiryDate = DateTime(
        baseDate.year,
        baseDate.month + selectedMonths,
        baseDate.day,
      );
    }

    setState(() {});
  }

  void setLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  void finishSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Membership Renewed Successfully")),
    );

    Navigator.pop(context);
  }

  void handleError(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(error.toString())),
    );
  }

  Future<void> renewStudent() async {
    try {
      setLoading(true);

      String paymentProofUrl = await StorageService.uploadPaymentProof(
        imageFile: paymentProofImage!,

        paymentId: paymentId,
      );

      await studentService.renewStudent(
        studentId: widget.student.id,

        newExpiryDate: calculatedExpiryDate,
      );

      await studentService.savePayment(
        paymentId: paymentId,
        studentId: widget.student.id,

        paymentProofUrl: paymentProofUrl,

        receiptUrl: "",

        seatNumber: widget.student.assignedSeat,

        planType: widget.student.planType,

        expiryDate: calculatedExpiryDate,

        amountPaid: int.parse(amountController.text.trim()),
      );
      if (!mounted) return;
      final receiptFile = await Navigator.push<File>(
        context,

        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            receiptId: receiptId,

            studentId: widget.student.id,

            paymentId: paymentId,

            studentName: widget.student.name,

            seatNumber: widget.student.assignedSeat,

            planType: widget.student.planType,

            amountPaid: int.parse(amountController.text.trim()),

            paymentDate: DateTime.now(),

            expiryDate: calculatedExpiryDate,

            paymentProofImage: paymentProofImage!,

            phoneNumber: widget.student.phone,
          ),
        ),
      );

      if (receiptFile != null) {
        receiptUrl = await StorageService.uploadReceipt(
          receiptFile: receiptFile,

          receiptId: receiptId,
        );

        await studentService.updatePaymentReceiptUrl(
          paymentId: paymentId,

          studentId: widget.student.id,

          receiptUrl: receiptUrl!,
        );
      }

      finishSuccess();
    } catch (e) {
      handleError(e);
    } finally {
      setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("Renew Membership"),

        backgroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            /// STUDENT CARD
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(24),

                boxShadow: const [
                  BoxShadow(blurRadius: 10, color: Colors.black12),
                ],
              ),

              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,

                    backgroundImage: widget.student.photoUrl != null
                        ? NetworkImage(widget.student.photoUrl!)
                        : null,

                    child: widget.student.photoUrl == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),

                  const SizedBox(height: 14),

                  Text(
                    widget.student.name,

                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Seat ${widget.student.assignedSeat}",

                    style: const TextStyle(fontSize: 18),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    widget.student.planType,

                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: buildInfoBox(
                          title: "Current Expiry",

                          value: DateFormat(
                            "dd MMM yyyy",
                          ).format(widget.student.expiryDate),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: buildInfoBox(
                          title: "New Expiry",

                          value: DateFormat(
                            "dd MMM yyyy",
                          ).format(calculatedExpiryDate),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// DURATION
            Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(24),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "Renewal Duration",

                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  SwitchListTile(
                    value: useCustomDays,

                    title: const Text("Use Custom Days"),

                    onChanged: (value) {
                      setState(() {
                        useCustomDays = value;
                      });

                      calculateExpiryDate();
                    },
                  ),

                  const SizedBox(height: 16),

                  if (!useCustomDays)
                    DropdownButtonFormField<int>(
                      initialValue: selectedMonths,

                      decoration: InputDecoration(
                        labelText: "Select Months",

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                      items: List.generate(12, (index) {
                        final month = index + 1;

                        return DropdownMenuItem(
                          value: month,

                          child: Text("$month Months"),
                        );
                      }),

                      onChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          selectedMonths = value;
                        });

                        calculateExpiryDate();
                      },
                    ),

                  if (useCustomDays)
                    TextFormField(
                      initialValue: customDays.toString(),

                      keyboardType: TextInputType.number,

                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                      decoration: InputDecoration(
                        labelText: "Custom Days",

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                      onChanged: (value) {
                        customDays = int.tryParse(value) ?? 0;

                        calculateExpiryDate();
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// PAYMENT
            Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(24),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "Payment Details",

                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: amountController,

                    keyboardType: TextInputType.number,

                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],

                    decoration: InputDecoration(
                      labelText: "Amount Paid",

                      prefixText: "₹ ",

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: pickPaymentProof,

                    child: Container(
                      height: 180,

                      width: double.infinity,

                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),

                        borderRadius: BorderRadius.circular(18),
                      ),

                      child: paymentProofImage == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                Icon(Icons.upload_file, size: 50),

                                SizedBox(height: 10),

                                Text("Upload Payment Proof"),
                              ],
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(18),

                              child: Image.file(
                                paymentProofImage!,

                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: isFormValid && !isLoading ? renewStudent : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Renew Membership",

                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget buildInfoBox({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),

        borderRadius: BorderRadius.circular(16),
      ),

      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          Text(
            value,

            style: const TextStyle(
              fontSize: 16,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
