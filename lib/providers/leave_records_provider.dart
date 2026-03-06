import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/leave_record.dart';
import '../services/firestore_service.dart';

class LeaveRecordsNotifier extends StateNotifier<List<LeaveRecord>> {
  LeaveRecordsNotifier() : super([]) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final box = Hive.box<LeaveRecord>('leave_records');
    state = box.values.toList();
  }

  /// Called once after login: fetches from Firestore and updates local cache.
  Future<void> initialize() async {
    try {
      final remote = await FirestoreService.instance.fetchLeaveRecords();
      if (remote.isNotEmpty) {
        final box = Hive.box<LeaveRecord>('leave_records');
        await box.clear();
        for (final r in remote) {
          await box.put(r.id, r);
        }
        state = remote;
      } else if (state.isNotEmpty) {
        await FirestoreService.instance.syncLeaveRecords(state);
      }
    } catch (_) {
      // Keep Hive data on network error.
    }
  }

  Future<void> addRecord(LeaveRecord record) async {
    final box = Hive.box<LeaveRecord>('leave_records');
    await box.put(record.id, record);
    state = [...state, record];
    FirestoreService.instance.saveLeaveRecord(record).ignore();
  }

  Future<void> removeRecord(String id) async {
    final box = Hive.box<LeaveRecord>('leave_records');
    await box.delete(id);
    state = state.where((r) => r.id != id).toList();
    FirestoreService.instance.deleteLeaveRecord(id).ignore();
  }

  Future<void> updateRecord(LeaveRecord record) async {
    final box = Hive.box<LeaveRecord>('leave_records');
    await box.put(record.id, record);
    state = [
      for (final r in state)
        if (r.id == record.id) record else r,
    ];
    FirestoreService.instance.saveLeaveRecord(record).ignore();
  }

  Future<void> removeAllForEmployee(String employeeId) async {
    final box = Hive.box<LeaveRecord>('leave_records');
    final toRemove =
        state.where((r) => r.employeeId == employeeId).toList();
    for (final r in toRemove) {
      await box.delete(r.id);
    }
    state = state.where((r) => r.employeeId != employeeId).toList();
    FirestoreService.instance
        .deleteAllLeaveRecordsForEmployee(employeeId)
        .ignore();
  }
}

final leaveRecordsProvider =
    StateNotifierProvider<LeaveRecordsNotifier, List<LeaveRecord>>(
  (ref) => LeaveRecordsNotifier(),
);

/// Returns the active leave record for a given employee today, or null if at work.
final employeeActiveLeaveProvider =
    Provider.family<LeaveRecord?, String>((ref, employeeId) {
  final records = ref.watch(leaveRecordsProvider);
  final today = DateTime.now();
  return records
      .where((r) => r.employeeId == employeeId && r.containsDate(today))
      .firstOrNull;
});
