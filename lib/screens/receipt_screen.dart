import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'package:screenshot/screenshot.dart';

import 'package:share_plus/share_plus.dart';

class ReceiptScreen extends StatelessWidget {
  final ScreenshotController screenshotController = ScreenshotController();

  final String receiptId;
  final String studentId;
  final String paymentId;

  final String studentName;
  final int seatNumber;
  final String planType;
  final String phoneNumber;
  final int amountPaid;

  final DateTime paymentDate;
  final DateTime expiryDate;

  final File paymentProofImage;

  ReceiptScreen({
    super.key,

    required this.receiptId,
    required this.studentId,
    required this.paymentId,

    required this.studentName,
    required this.seatNumber,
    required this.planType,

    required this.amountPaid,

    required this.paymentDate,
    required this.expiryDate,

    required this.paymentProofImage,
    required this.phoneNumber,
  });
  Future<File?> shareReceipt() async {
    final receiptFile = await generateReceiptFile();

    if (receiptFile == null) {
      return null;
    }

    await Share.shareXFiles([
      XFile(receiptFile.path),
    ], text: "TRIDEV LIBRARY Receipt");

    return receiptFile;
  }

  Future<File?> generateReceiptFile() async {
    final Uint8List? imageBytes = await screenshotController.capture();

    if (imageBytes == null) {
      return null;
    }

    final directory = await getTemporaryDirectory();

    final imageFile = File("${directory.path}/$receiptId.png");

    await imageFile.writeAsBytes(imageBytes);

    return imageFile;
  }

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
      "receiptId": receiptId,
      "studentId": studentId,
      "paymentId": paymentId,
      "seatNo": seatNumber,
      "planType": planType,
      "amount": amountPaid,
    });

    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final receiptFile = await generateReceiptFile();

        if (!context.mounted) {
          return;
        }

        Navigator.pop(context, receiptFile);
      },

      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),

        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () async {
                final receiptFile = await shareReceipt();

                if (receiptFile == null) {
                  return;
                }

                if (!context.mounted) {
                  return;
                }

                Navigator.pop(context, receiptFile);
              },

              icon: const Icon(Icons.share),
            ),
          ],
          backgroundColor: const Color(0xFF0B2C66),
          foregroundColor: Colors.white,
          title: const Text("Payment Receipt"),
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Screenshot(
            controller: screenshotController,

            child: Container(
              width: double.infinity,

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(24),

                border: Border.all(color: const Color(0xFF0B2C66), width: 3),

                boxShadow: const [
                  BoxShadow(blurRadius: 12, color: Colors.black12),
                ],
              ),

              child: Column(
                children: [
                  /// TOP BAR
                  Container(
                    height: 18,

                    decoration: const BoxDecoration(
                      color: Color(0xFF0B2C66),

                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// LOGO
                  const Icon(
                    Icons.menu_book_rounded,
                    size: 46,
                    color: Color(0xFF0B2C66),
                  ),

                  const SizedBox(height: 12),

                  /// TITLE
                  const Text(
                    "TRIDEV LIBRARY",

                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0B2C66),

                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// PAYMENT RECEIPT TAG
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 12,
                    ),

                    decoration: BoxDecoration(
                      color: const Color(0xFF0B2C66),

                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: const Text(
                      "PAYMENT RECEIPT",

                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),

                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        /// DETAILS
                        Expanded(
                          flex: 3,

                          child: Column(
                            children: [
                              buildCompactInfoTile(
                                icon: Icons.person,
                                title: "NAME",
                                value: studentName,
                              ),

                              buildCompactInfoTile(
                                icon: Icons.chair_alt_rounded,
                                title: "SEAT",
                                value: seatNumber.toString(),
                              ),

                              buildCompactInfoTile(
                                icon: Icons.schedule,
                                title: "PLAN",
                                value: planType,
                              ),

                              buildCompactInfoTile(
                                icon: Icons.currency_rupee,
                                title: "AMOUNT",
                                value: "₹ $amountPaid",
                              ),

                              buildCompactInfoTile(
                                icon: Icons.calendar_month,
                                title: "PAY DATE",
                                value: DateFormat(
                                  "dd MMM yyyy",
                                ).format(paymentDate),
                              ),

                              buildCompactInfoTile(
                                icon: Icons.event_available,
                                title: "EXPIRY",
                                value: DateFormat(
                                  "dd MMM yyyy",
                                ).format(expiryDate),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 18),

                        /// PAYMENT PROOF
                        Expanded(
                          flex: 2,

                          child: Column(
                            children: [
                              const Text(
                                "PAYMENT PROOF",

                                style: TextStyle(
                                  fontWeight: FontWeight.bold,

                                  color: Color(0xFF0B2C66),
                                ),
                              ),

                              const SizedBox(height: 10),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),

                                child: Image.file(
                                  width: double.infinity,
                                  paymentProofImage,

                                  height: 190,

                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),

                    child: Row(
                      children: [
                        /// QR
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                "SCAN TO VERIFY",

                                style: TextStyle(
                                  fontWeight: FontWeight.bold,

                                  color: Color(0xFF0B2C66),
                                ),
                              ),

                              const SizedBox(height: 12),

                              QrImageView(
                                data: qrData,

                                size: 140,

                                backgroundColor: Colors.white,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        /// RECEIPT ID
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                "RECEIPT ID",

                                style: TextStyle(
                                  fontWeight: FontWeight.bold,

                                  color: Color(0xFF0B2C66),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Container(
                                padding: const EdgeInsets.all(16),

                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),

                                  borderRadius: BorderRadius.circular(14),
                                ),

                                child: Text(
                                  receiptId,

                                  textAlign: TextAlign.center,

                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),

                    child: Column(
                      children: const [
                        Text(
                          "Thank you for choosing TRIDEV LIBRARY.",

                          textAlign: TextAlign.center,

                          style: TextStyle(
                            fontSize: 24,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF0B2C66),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        SizedBox(height: 14),

                        Text(
                          "We wish you a productive and successful journey.",

                          textAlign: TextAlign.center,

                          style: TextStyle(fontSize: 17, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// FOOTER
                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.symmetric(vertical: 20),

                    decoration: const BoxDecoration(
                      color: Color(0xFF0B2C66),

                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),

                    child: const Column(
                      children: [
                        Text(
                          "This is a computer generated receipt.",

                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),

                        SizedBox(height: 6),

                        Text(
                          "No signature required.",

                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),

      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0B2C66), size: 30),

          const SizedBox(width: 20),

          SizedBox(
            width: 120,

            child: Text(
              title,

              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF0B2C66),
              ),
            ),
          ),

          const Text(
            ":",

            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Text(
              value,

              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCompactInfoTile({
    required IconData icon,

    required String title,

    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, size: 18, color: const Color(0xFF0B2C66)),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,

                    fontSize: 12,

                    color: Color(0xFF0B2C66),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,

                  style: const TextStyle(
                    fontSize: 14,

                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
