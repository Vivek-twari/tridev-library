import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'history_entry_model.g.dart';

@HiveType(typeId: 4)
class HistoryEntryModel {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final int timestamp;

  HistoryEntryModel({required this.text, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {"text": text, "timestamp": timestamp};
  }

  static int _parseTimestamp(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return 0;
  }

  factory HistoryEntryModel.fromMap(Map<String, dynamic> map) {
    return HistoryEntryModel(
      text: map["text"] ?? "",

      timestamp: _parseTimestamp(map["timestamp"] ?? 0),
    );
  }
}
