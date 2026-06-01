import 'package:cloud_firestore/cloud_firestore.dart';

class SyncTimeService {
  static final firestore = FirebaseFirestore.instance;

  static Future<int> getServerEpoch() async {
    final ref = firestore.collection("sync_meta").doc("server_time");

    await ref.set({"updatedAt": FieldValue.serverTimestamp()});

    final doc = await ref.get();

    final timestamp = doc["updatedAt"] as Timestamp;

    return timestamp.millisecondsSinceEpoch;
  }

  static bool nearlyEqual(int a, int b) {
    return (a - b).abs() <= 5000;
  }
}
