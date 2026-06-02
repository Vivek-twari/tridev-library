import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import 'history_entry_model.dart';

part 'history_month_model.g.dart';

@HiveType(typeId: 5)
class HistoryMonthModel {
  @HiveField(0)
  final String monthId;

  @HiveField(1)
  final List<HistoryEntryModel> entries;

  @HiveField(2)
  final int added;

  @HiveField(3)
  final int renewed;

  @HiveField(4)
  final int cancelled;

  @HiveField(5)
  final int deleted;

  @HiveField(6)
  final int edited;

  @HiveField(7)
  final int planChanged;

  @HiveField(8)
  final int seatShifted;

  @HiveField(9)
  final int updatedAtEpoch;

  HistoryMonthModel({
    required this.monthId,

    required this.entries,

    required this.added,

    required this.renewed,

    required this.cancelled,

    required this.deleted,

    required this.edited,

    required this.planChanged,

    required this.seatShifted,
    required this.updatedAtEpoch,
  });

  Map<String, dynamic> toMap() {
    return {
      "monthId": monthId,

      "entries": entries.map((e) => e.toMap()).toList(),

      "added": added,

      "renewed": renewed,

      "cancelled": cancelled,

      "deleted": deleted,

      "edited": edited,

      "planChanged": planChanged,

      "seatShifted": seatShifted,
      "updatedAtEpoch": updatedAtEpoch,
    };
  }

  static int _parseEpoch(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    return 0;
  }

  factory HistoryMonthModel.fromMap(Map<String, dynamic> map) {
    return HistoryMonthModel(
      monthId: map["monthId"] ?? "",

      entries:
          (map["entries"] as List?)
              ?.map((e) => HistoryEntryModel.fromMap(e))
              .toList() ??
          [],

      added: map["added"] ?? 0,

      renewed: map["renewed"] ?? 0,

      cancelled: map["cancelled"] ?? 0,

      deleted: map["deleted"] ?? 0,

      edited: map["edited"] ?? 0,

      planChanged: map["planChanged"] ?? 0,

      seatShifted: map["seatShifted"] ?? 0,
      updatedAtEpoch: _parseEpoch(map["updatedAtEpoch"] ?? 0),
    );
  }
}
