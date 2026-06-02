import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'sync_time_service.dart';

import '../models/history_entry_model.dart';
import '../models/history_month_model.dart';

class HistoryService {
  static final firestore = FirebaseFirestore.instance;

  static Future<void> addEntry({
    required String text,

    String type = "general",
  }) async {
    final historyBox = Hive.box<HistoryMonthModel>("historyBox");

    /// MONTH ID
    final now = DateTime.now();

    final monthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    /// CURRENT MONTH MODEL
    HistoryMonthModel? currentMonth = historyBox.get(monthId);

    currentMonth ??= HistoryMonthModel(
      monthId: monthId,

      entries: [],

      added: 0,

      renewed: 0,

      cancelled: 0,

      deleted: 0,

      edited: 0,

      planChanged: 0,

      seatShifted: 0,
      updatedAtEpoch: 0,
    );

    /// NEW ENTRY
    final entry = HistoryEntryModel(
      text: text,

      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final updatedEntries = List<HistoryEntryModel>.from(currentMonth.entries)
      ..insert(0, entry);

    /// COUNTERS
    int added = currentMonth.added;

    int renewed = currentMonth.renewed;

    int cancelled = currentMonth.cancelled;

    int deleted = currentMonth.deleted;

    int edited = currentMonth.edited;

    int planChanged = currentMonth.planChanged;

    int seatShifted = currentMonth.seatShifted;

    switch (type) {
      case "added":
        added++;
        break;

      case "renewed":
        renewed++;
        break;

      case "cancelled":
        cancelled++;
        break;

      case "deleted":
        deleted++;
        break;

      case "edited":
        edited++;
        break;

      case "planChanged":
        planChanged++;
        break;

      case "seatShifted":
        seatShifted++;
        break;
    }

    /// SERVER UPDATED AT
    final updatedAtEpoch = await SyncTimeService.getServerEpoch();

    /// UPDATED MODEL
    final updatedMonth = HistoryMonthModel(
      monthId: monthId,

      entries: updatedEntries,

      added: added,

      renewed: renewed,

      cancelled: cancelled,

      deleted: deleted,

      edited: edited,

      planChanged: planChanged,

      seatShifted: seatShifted,
      updatedAtEpoch: updatedAtEpoch,
    );

    /// HIVE
    await historyBox.put(monthId, updatedMonth);

    /// FIRESTORE
    await firestore
        .collection("history")
        .doc(monthId)
        .set(updatedMonth.toMap());
  }
}
