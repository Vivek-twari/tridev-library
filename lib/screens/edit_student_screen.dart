import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../services/sync_time_service.dart';
import '../services/storage_service.dart';

class EditStudentScreen extends StatefulWidget {
  final StudentModel student;

  const EditStudentScreen({super.key, required this.student});

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  late final TextEditingController nameController;

  late final TextEditingController phoneController;

  late final TextEditingController adharController;

  File? selectedImage;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.student.name);

    phoneController = TextEditingController(text: widget.student.phone);

    adharController = TextEditingController(text: widget.student.adharId ?? "");
  }

  bool get isFormValid {
    final name = nameController.text.trim();

    final phone = phoneController.text.trim();

    final adhar = adharController.text.trim();

    return RegExp(r'^[a-zA-Z\s]+$').hasMatch(name) &&
        name.length <= 30 &&
        phone.length == 10 &&
        RegExp(r'^\d+$').hasMatch(phone) &&
        (adhar.isEmpty || adhar.length == 12);
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,

      imageQuality: 70,
    );

    if (picked == null) return;

    setState(() {
      selectedImage = File(picked.path);
    });
  }

  Future<void> saveChanges() async {
    final messenger = ScaffoldMessenger.of(context);

    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,

      builder: (_) => AlertDialog(
        title: const Text("Save Changes"),

        content: const Text("Are you sure you want to update this student?"),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },

            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },

            child: const Text("Save"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        isLoading = true;
      });

      String? photoUrl = widget.student.photoUrl;

      /// NEW PHOTO
      if (selectedImage != null) {
        /// DELETE OLD CACHE
        if (widget.student.photoUrl != null) {
          await CachedNetworkImage.evictFromCache(widget.student.photoUrl!);
        }

        /// DELETE OLD STORAGE
        if (widget.student.photoUrl != null) {
          try {
            await FirebaseStorage.instance
                .refFromURL(widget.student.photoUrl!)
                .delete();
          } catch (_) {}
        }

        /// UPLOAD NEW
        photoUrl = await StorageService.uploadStudentImage(
          imageFile: selectedImage!,

          studentId: widget.student.id,
        );
      }

      final updatedAtEpoch = await SyncTimeService.getServerEpoch();

      /// FIRESTORE
      await FirebaseFirestore.instance
          .collection("students")
          .doc(widget.student.id)
          .update({
            "name": nameController.text.trim(),

            "phone": phoneController.text.trim(),

            "adharId": adharController.text.trim(),

            "photoUrl": photoUrl,

            "updatedAtEpoch": updatedAtEpoch,
          });

      /// HIVE
      final studentsBox = Hive.box<StudentModel>("studentsBox");

      final student = studentsBox.get(widget.student.id);

      if (student != null) {
        final updatedStudent = StudentModel(
          id: student.id,
          name: nameController.text.trim(),
          phone: phoneController.text.trim(),
          planType: student.planType,
          joinDate: student.joinDate,
          expiryDate: student.expiryDate,
          isActive: student.isActive,
          assignedSeat: student.assignedSeat,
          photoUrl: photoUrl,
          adharId: adharController.text.trim(),
          updatedAtEpoch: updatedAtEpoch,
        );

        await studentsBox.put(widget.student.id, updatedStudent);
      }

      if (!mounted) return;

      navigator.pop();

      messenger.showSnackBar(
        const SnackBar(content: Text("Student Updated Successfully")),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("Edit Details"),

        backgroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            /// PHOTO
            GestureDetector(
              onTap: pickImage,

              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(80),

                    child: selectedImage != null
                        ? Image.file(
                            selectedImage!,

                            width: 140,
                            height: 140,

                            fit: BoxFit.cover,
                          )
                        : widget.student.photoUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.student.photoUrl!,

                            width: 140,
                            height: 140,

                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 140,
                            height: 140,

                            color: Colors.grey.shade300,

                            child: const Icon(Icons.person, size: 60),
                          ),
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,

                    child: Container(
                      padding: const EdgeInsets.all(8),

                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),

                        shape: BoxShape.circle,
                      ),

                      child: const Icon(Icons.edit, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// NAME
            TextFormField(
              controller: nameController,

              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
              ],

              decoration: InputDecoration(
                labelText: "Full Name",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),

            const SizedBox(height: 18),

            /// PHONE
            TextFormField(
              controller: phoneController,

              keyboardType: TextInputType.number,

              maxLength: 10,

              inputFormatters: [FilteringTextInputFormatter.digitsOnly],

              decoration: InputDecoration(
                labelText: "Phone Number",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),

            const SizedBox(height: 18),

            /// ADHAR
            TextFormField(
              controller: adharController,

              keyboardType: TextInputType.number,

              maxLength: 12,

              inputFormatters: [FilteringTextInputFormatter.digitsOnly],

              decoration: InputDecoration(
                labelText: "Aadhaar ID",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),

            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,

              height: 56,

              child: ElevatedButton(
                onPressed: isFormValid && !isLoading ? saveChanges : null,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),

                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save Changes",

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
