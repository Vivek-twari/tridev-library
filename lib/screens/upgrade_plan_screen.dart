import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'receipt_screen.dart';
import '../models/availability_model.dart';
import '../models/student_model.dart';
import '../services/seat_service.dart';
import '../services/storage_service.dart';
import '../services/student_service.dart';

class UpgradePlanScreen extends StatefulWidget {
  final StudentModel student;

  const UpgradePlanScreen({super.key, required this.student});

  @override
  State<UpgradePlanScreen> createState() => _UpgradePlanScreenState();
}

class _UpgradePlanScreenState extends State<UpgradePlanScreen> {
  final studentService = StudentService();

  final amountController = TextEditingController();

  final uuid = const Uuid();

  String? selectedPlan;

  int? selectedSeat;

  bool changeSeat = false;

  bool isLoading = false;

  File? paymentProofImage;

  late final String paymentId;
  late final String receiptId;
  String? receiptUrl;

  final plans = ["Morning", "Evening", "Day", "Night", "Prime"];

  List<int> availableSeats = [];

  @override
  void initState() {
    super.initState();

    paymentId = uuid.v4();
    receiptId = uuid.v4();
  }

  bool get isFormValid {
    return selectedPlan != null &&
        paymentProofImage != null &&
        amountController.text.trim().isNotEmpty &&
        int.tryParse(amountController.text.trim()) != null &&
        int.parse(amountController.text.trim()) >= 100;
  }

  void loadSeats() {
    final availabilityBox = Hive.box<AvailabilityModel>("availabilityBox");

    final availability = availabilityBox.get("main");

    if (availability == null || selectedPlan == null) {
      return;
    }

    switch (selectedPlan) {
      case "Morning":
        availableSeats = availability.morningSeats;
        break;

      case "Evening":
        availableSeats = availability.eveningSeats;
        break;

      case "Day":
        availableSeats = availability.daySeats;
        break;

      case "Night":
        availableSeats = availability.nightSeats;
        break;

      case "Prime":
        availableSeats = availability.primeSeats;
        break;
    }

    availableSeats.remove(widget.student.assignedSeat);

    setState(() {});
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

  void finishSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Membership upgraded successfully")),
    );

    Navigator.pop(context);
  }

  void handleError(dynamic e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }

  void setLoading(bool value) {
    if (!mounted) return;

    setState(() {
      isLoading = value;
    });
  }

  Future<void> upgradeMembership() async {
    try {
      setLoading(true);

      final paymentProofUrl = await StorageService.uploadPaymentProof(
        imageFile: paymentProofImage!,
        paymentId: paymentId,
      );

      final oldSeat = widget.student.assignedSeat;

      final oldPlan = widget.student.planType;

      final newSeat = selectedSeat ?? oldSeat;

      final newPlan = selectedPlan!;

      final seatChanged = newSeat != oldSeat;

      final planChanged = newPlan != oldPlan;

      if (seatChanged || planChanged) {
        await SeatService.freeSeat(seatNumber: oldSeat, planType: oldPlan);

        await SeatService.updateAvailability(seatNumber: oldSeat);

        await SeatService.updateSeat(
          seatNumber: newSeat,
          studentId: widget.student.id,
          planType: newPlan,
        );

        await SeatService.updateAvailability(seatNumber: newSeat);
      }

      await studentService.updateMembership(
        studentId: widget.student.id,
        newPlanType: newPlan,
        newSeat: newSeat,
        expiryDate: widget.student.expiryDate,
      );

      await studentService.savePayment(
        paymentId: paymentId,
        studentId: widget.student.id,
        paymentProofUrl: paymentProofUrl,
        receiptUrl: "",
        seatNumber: newSeat,
        planType: newPlan,
        expiryDate: widget.student.expiryDate,
        amountPaid: int.parse(amountController.text.trim()),
      );
      final receiptFile = await Navigator.push<File>(
        context,

        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            receiptId: receiptId,

            studentId: widget.student.id,

            paymentId: paymentId,

            studentName: widget.student.name,

            seatNumber: newSeat,

            planType: newPlan,

            amountPaid: int.parse(amountController.text.trim()),

            paymentDate: DateTime.now(),

            expiryDate: widget.student.expiryDate,

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
        title: const Text("Upgrade Membership"),

        backgroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// CURRENT INFO
            Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(20),
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

                  Text("Current Seat: ${widget.student.assignedSeat}"),

                  const SizedBox(height: 10),

                  Text(
                    "Expiry: ${widget.student.expiryDate.toString().split(" ")[0]}",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              "Choose New Plan",

              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 10,
              runSpacing: 10,

              children: plans
                  .where((plan) => plan != widget.student.planType)
                  .map(
                    (plan) => ChoiceChip(
                      label: Text(plan),

                      selected: selectedPlan == plan,

                      onSelected: (_) {
                        setState(() {
                          selectedPlan = plan;

                          selectedSeat = null;
                        });

                        loadSeats();
                      },
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 24),

            SwitchListTile(
              value: changeSeat,

              title: const Text("Change Seat?"),

              onChanged: (value) {
                setState(() {
                  changeSeat = value;

                  selectedSeat = null;
                });

                if (value) {
                  loadSeats();
                }
              },
            ),

            if (changeSeat && selectedPlan != null) ...[
              const SizedBox(height: 12),

              DropdownButtonFormField<int>(
                value: selectedSeat,

                decoration: const InputDecoration(
                  labelText: "Select Seat",

                  border: OutlineInputBorder(),
                ),

                items: availableSeats
                    .map(
                      (seat) => DropdownMenuItem(
                        value: seat,

                        child: Text("Seat $seat"),
                      ),
                    )
                    .toList(),

                onChanged: (value) {
                  setState(() {
                    selectedSeat = value;
                  });
                },
              ),
            ],

            const SizedBox(height: 26),

            TextFormField(
              controller: amountController,

              keyboardType: TextInputType.number,

              inputFormatters: [FilteringTextInputFormatter.digitsOnly],

              decoration: const InputDecoration(
                labelText: "Amount Paid",

                prefixText: "₹ ",

                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,

              height: 52,

              child: OutlinedButton.icon(
                onPressed: pickPaymentProof,

                icon: const Icon(Icons.image),

                label: Text(
                  paymentProofImage == null
                      ? "Upload Payment Proof"
                      : "Proof Selected",
                ),
              ),
            ),

            const SizedBox(height: 34),

            SizedBox(
              width: double.infinity,

              height: 56,

              child: ElevatedButton(
                onPressed: isFormValid && !isLoading ? upgradeMembership : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                ),

                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Upgrade Membership",

                        style: TextStyle(
                          color: Colors.white,

                          fontSize: 18,
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
