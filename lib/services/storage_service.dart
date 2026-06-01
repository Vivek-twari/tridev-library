import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage storage = FirebaseStorage.instance;

  static Future<String> uploadStudentImage({
    required File imageFile,
    required String studentId,
  }) async {
    final ref = storage.ref().child("students").child("$studentId.jpg");

    final compressedFile = await compressImage(imageFile);

    await ref.putFile(compressedFile);

    final downloadUrl = await ref.getDownloadURL();

    return downloadUrl;
  }

  static Future<File> compressImage(File file) async {
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      file.absolute.path,

      quality: 40,

      minWidth: 800,
      minHeight: 800,
    );

    final compressedFile = File("${file.path}_compressed.jpg");

    await compressedFile.writeAsBytes(compressedBytes!);

    return compressedFile;
  }

  static Future<String> uploadPaymentProof({
    required File imageFile,

    required String paymentId,
  }) async {
    final ref = storage.ref().child("payments_proof").child("$paymentId.jpg");

    final compressedFile = await compressImage(imageFile);

    await ref.putFile(compressedFile);

    final downloadUrl = await ref.getDownloadURL();

    return downloadUrl;
  }

  static Future<String> uploadReceipt({
    required File receiptFile,

    required String receiptId,
  }) async {
    final ref = storage.ref().child("receipts").child("$receiptId.jpg");

    final compressedReceipt = await compressImage(receiptFile);

    await ref.putFile(compressedReceipt);

    final downloadUrl = await ref.getDownloadURL();

    return downloadUrl;
  }
}
