import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/student_model.dart';
import '../services/student_service.dart';
import '../models/availability_model.dart';
import '../services/storage_service.dart';
import 'package:flutter/services.dart';
import '../services/seat_service.dart';
import 'receipt_screen.dart';
import '../services/sync_time_service.dart';
import '../services/history_service.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final TextEditingController nameController = TextEditingController();
  late String studentId;

  late String paymentId;

  late String receiptId;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController adharController = TextEditingController();

  File? selectedImage;

  final StudentService studentService = StudentService();

  final uuid = const Uuid();

  bool isLoading = false;

  String? selectedPlan;

  int? selectedSeat;

  List<int> availableSeats = [];

  final availabilityBox = Hive.box<AvailabilityModel>("availabilityBox");
  String? photoUrl;
  DateTime selectedJoinDate = DateTime.now();

  int selectedMonths = 1;
  String durationType = "Months";

  int customDays = 1;
  File? paymentProofImage;
  String? studentPhotoUrl;

  String? paymentProofUrl;
  String? receiptUrl;

  final TextEditingController amountController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    adharController.dispose();
    amountController.dispose();
    super.dispose();
  }

  bool get isBasicFormValid {
    final name = nameController.text.trim();

    final phone = phoneController.text.trim();
    final adhar = adharController.text.trim();

    final isNameValid =
        RegExp(r'^[a-zA-Z ]+$').hasMatch(name) && name.length <= 30;

    final isPhoneValid = RegExp(r'^[0-9]{10}$').hasMatch(phone);

    final isAdharValid = RegExp(r'^[0-9]{12}$').hasMatch(adhar);

    return isNameValid &&
        isPhoneValid &&
        isAdharValid &&
        selectedPlan != null &&
        selectedSeat != null;
  }

  bool get isPaymentValid {
    final amount = int.tryParse(amountController.text.trim());

    return paymentProofImage != null && amount != null && amount >= 800;
  }

  bool get canSaveStudent {
    return isBasicFormValid && isPaymentValid;
  }

  DateTime get calculatedExpiryDate {
    if (durationType == "Months") {
      return addMonths(selectedJoinDate, selectedMonths);
    }

    return selectedJoinDate.add(Duration(days: customDays));
  }

  Future<void> pickPaymentProof() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      setState(() {
        paymentProofImage = File(pickedImage.path);
      });
    }
  }

  void generateIds() {
    studentId = uuid.v4();

    paymentId = uuid.v4();

    receiptId = uuid.v4();
  }

  void setLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  Future<void> uploadStudentPhoto() async {
    if (selectedImage == null) return;

    studentPhotoUrl = await StorageService.uploadStudentImage(
      imageFile: selectedImage!,

      studentId: studentId,
    );
  }

  Future<void> uploadPaymentProof() async {
    if (paymentProofImage == null) return;

    paymentProofUrl = await StorageService.uploadPaymentProof(
      imageFile: paymentProofImage!,

      paymentId: paymentId,
    );
  }

  Future<void> addStudent() async {
    try {
      setLoading(true);

      await SeatService.validateSeatAvailability(
        seatNumber: selectedSeat!,

        planType: selectedPlan!,
      );

      generateIds();

      await uploadStudentPhoto();

      await uploadPaymentProof();
      final updatedAtEpoch = await SyncTimeService.getServerEpoch();

      final student = StudentModel(
        id: studentId,

        name: nameController.text.trim(),

        phone: phoneController.text.trim(),

        planType: selectedPlan!,

        joinDate: selectedJoinDate,

        expiryDate: calculatedExpiryDate,

        isActive: true,

        assignedSeat: selectedSeat!,

        photoUrl: studentPhotoUrl,

        adharId: adharController.text.trim(),
        updatedAtEpoch: updatedAtEpoch,
      );

      await studentService.saveStudent(student);

      await SeatService.updateSeat(
        seatNumber: selectedSeat!,
        studentId: studentId,
        planType: selectedPlan!,
      );

      await SeatService.updateAvailability(seatNumber: selectedSeat!);

      await studentService.savePayment(
        paymentId: paymentId,
        studentId: studentId,
        paymentProofUrl: paymentProofUrl!,
        seatNumber: selectedSeat!,
        planType: selectedPlan!,
        expiryDate: calculatedExpiryDate,
        amountPaid: int.parse(amountController.text.trim()),
        receiptUrl: receiptUrl ?? "pending",
      );
      await HistoryService.addEntry(
        text:
            "${student.name} added to Seat ${student.assignedSeat} (${student.planType})",

        type: "added",
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Student Added Successfully")),
      );

      final receiptFile = await Navigator.push<File>(
        context,

        MaterialPageRoute(
          builder: (_) => ReceiptScreen(
            receiptId: receiptId,

            studentId: studentId,

            paymentId: paymentId,

            studentName: nameController.text.trim(),

            seatNumber: selectedSeat!,

            planType: selectedPlan!,

            amountPaid: int.parse(amountController.text),

            paymentDate: DateTime.now(),

            expiryDate: calculatedExpiryDate,

            paymentProofImage: paymentProofImage!,

            phoneNumber: phoneController.text.trim(),
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

          studentId: studentId,

          receiptUrl: receiptUrl!,
        );
      }

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      handleError(e);
    } finally {
      setLoading(false);
    }
  }

  void handleError(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.red, content: Text(error.toString())),
    );
  }

  Future<void> pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      setState(() {
        selectedImage = File(pickedImage.path);
      });
    }
  }

  void updateAvailableSeats(String plan) {
    final availabilityBox = Hive.box<AvailabilityModel>("availabilityBox");

    final availability = availabilityBox.get("main");

    if (availability == null) return;

    setState(() {
      selectedPlan = plan;

      selectedSeat = null;

      switch (plan) {
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

        default:
          availableSeats = [];
      }
    });
  }

  Future<void> pickJoinDate() async {
    final pickedDate = await showDatePicker(
      context: context,

      initialDate: selectedJoinDate,

      firstDate: DateTime(2024),

      lastDate: DateTime(2035),
    );

    if (pickedDate != null) {
      setState(() {
        selectedJoinDate = pickedDate;
      });
    }
  }

  DateTime addMonths(DateTime date, int months) {
    final newMonth = date.month + months;

    final year = date.year + ((newMonth - 1) ~/ 12);

    final month = ((newMonth - 1) % 12) + 1;

    final lastDay = DateTime(year, month + 1, 0).day;

    final day = date.day > lastDay ? lastDay : date.day;

    return DateTime(year, month, day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text("Add Student")),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              GestureDetector(
                onTap: pickImage,

                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 55,

                      backgroundColor: Colors.grey.shade200,

                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : null,

                      child: selectedImage == null
                          ? const Icon(Icons.camera_alt, size: 40)
                          : null,
                    ),

                    const SizedBox(height: 12),

                    const Text("Upload Student Photo"),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              TextFormField(
                controller: nameController,
                onChanged: (_) {
                  setState(() {});
                },

                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),

                  LengthLimitingTextInputFormatter(30),
                ],

                decoration: InputDecoration(
                  labelText: "Student Name",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: phoneController,
                onChanged: (_) {
                  setState(() {});
                },

                keyboardType: TextInputType.phone,

                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,

                  LengthLimitingTextInputFormatter(10),
                ],

                decoration: InputDecoration(
                  labelText: "Phone Number",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: adharController,
                onChanged: (_) {
                  setState(() {});
                },

                keyboardType: TextInputType.number,

                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,

                  LengthLimitingTextInputFormatter(12),
                ],

                decoration: InputDecoration(
                  labelText: "Aadhaar Number",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: selectedPlan,

                decoration: InputDecoration(
                  labelText: "Select Plan",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                items: const [
                  DropdownMenuItem(
                    value: "Morning",
                    child: Text("Morning (6AM - 12PM)"),
                  ),

                  DropdownMenuItem(
                    value: "Evening",
                    child: Text("Evening (12PM - 6PM)"),
                  ),

                  DropdownMenuItem(
                    value: "Day",
                    child: Text("Day (6AM - 6PM)"),
                  ),

                  DropdownMenuItem(
                    value: "Night",
                    child: Text("Night (6PM - 6AM)"),
                  ),

                  DropdownMenuItem(
                    value: "Prime",
                    child: Text("Prime (24 Hours)"),
                  ),
                ],

                onChanged: (value) {
                  if (value != null) {
                    updateAvailableSeats(value);
                  }
                },
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<int>(
                initialValue: selectedSeat,

                decoration: InputDecoration(
                  labelText: "Select Seat",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                items: availableSeats.map((seat) {
                  return DropdownMenuItem(
                    value: seat,
                    child: Text("Seat $seat"),
                  );
                }).toList(),

                onChanged: (value) {
                  setState(() {
                    selectedSeat = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: pickJoinDate,

                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),

                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),

                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text("Join Date"),

                          const SizedBox(height: 6),

                          Text(
                            "${selectedJoinDate.day}/${selectedJoinDate.month}/${selectedJoinDate.year}",

                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const Icon(Icons.calendar_month),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 20),

              DropdownButtonFormField<String>(
                initialValue: durationType,

                decoration: InputDecoration(
                  labelText: "Duration Type",

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                items: const [
                  DropdownMenuItem(value: "Months", child: Text("Months")),

                  DropdownMenuItem(
                    value: "Custom Days",
                    child: Text("Custom Days"),
                  ),
                ],

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      durationType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              durationType == "Months"
                  ? DropdownButtonFormField<int>(
                      initialValue: selectedMonths,

                      decoration: InputDecoration(
                        labelText: "Number of Months",

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                      items: List.generate(12, (index) {
                        final month = index + 1;

                        return DropdownMenuItem(
                          value: month,

                          child: Text("$month Month${month > 1 ? "s" : ""}"),
                        );
                      }),

                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedMonths = value;
                          });
                        }
                      },
                    )
                  : TextFormField(
                      initialValue: customDays.toString(),

                      keyboardType: TextInputType.number,

                      decoration: InputDecoration(
                        labelText: "Custom Days",

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),

                      onChanged: (value) {
                        setState(() {
                          customDays = int.tryParse(value) ?? 1;
                        });
                      },
                    ),
              const SizedBox(height: 28),
              if (!isBasicFormValid)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),

                  child: Text(
                    "Fill all required fields above first",

                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),

                opacity: isBasicFormValid ? 1 : 0.4,

                child: IgnorePointer(
                  ignoring: !isBasicFormValid,

                  child: Container(
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      color: Colors.white,

                      borderRadius: BorderRadius.circular(24),

                      boxShadow: const [
                        BoxShadow(blurRadius: 10, color: Colors.black12),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          "Payment & Receipt",

                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,

                          padding: const EdgeInsets.all(18),

                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF4FF),

                            borderRadius: BorderRadius.circular(18),
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              const Text(
                                "Calculated Expiry Date",

                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                "${calculatedExpiryDate.day}/${calculatedExpiryDate.month}/${calculatedExpiryDate.year}",

                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// PAYMENT PROOF
                        GestureDetector(
                          onTap: pickPaymentProof,

                          child: Container(
                            height: 140,

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),

                              border: Border.all(color: Colors.grey.shade400),
                            ),

                            child: paymentProofImage == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,

                                    children: const [
                                      Icon(Icons.receipt_long, size: 40),

                                      SizedBox(height: 10),

                                      Text("Upload Payment Proof"),
                                    ],
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(20),

                                    child: Image.file(
                                      paymentProofImage!,

                                      fit: BoxFit.cover,

                                      width: double.infinity,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// AMOUNT FIELD
                        TextFormField(
                          controller: amountController,
                          onChanged: (_) {
                            setState(() {});
                          },

                          keyboardType: TextInputType.number,

                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,

                            LengthLimitingTextInputFormatter(6),
                          ],

                          decoration: InputDecoration(
                            labelText: "Amount Paid",

                            prefixText: "₹ ",

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (canSaveStudent) ...[
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,

                  height: 56,

                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),

                    onPressed: isLoading ? null : addStudent,

                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,

                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Add Student",

                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,

                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
