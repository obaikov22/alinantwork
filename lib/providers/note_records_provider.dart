import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/note_record.dart';
import '../services/firestore_service.dart';

class NoteRecordsNotifier extends StateNotifier<List<NoteRecord>> {
  NoteRecordsNotifier() : super([]) {
    _loadFromHive();
  }

  void _loadFromHive() {
    final box = Hive.box<NoteRecord>('note_records');
    state = box.values.toList();
  }

  /// Called once after login: fetches from Firestore and updates local cache.
  Future<void> initialize() async {
    try {
      final remote = await FirestoreService.instance.fetchNoteRecords();
      if (remote.isNotEmpty) {
        final box = Hive.box<NoteRecord>('note_records');
        await box.clear();
        for (final n in remote) {
          await box.put(n.id, n);
        }
        state = remote;
      } else if (state.isNotEmpty) {
        await FirestoreService.instance.syncNoteRecords(state);
      }
    } catch (_) {
      // Keep Hive data on network error.
    }
  }

  Future<void> addNote(NoteRecord note) async {
    final box = Hive.box<NoteRecord>('note_records');
    await box.put(note.id, note);
    state = [...state, note];
    FirestoreService.instance.saveNoteRecord(note).ignore();
  }

  Future<void> removeNote(String id) async {
    final box = Hive.box<NoteRecord>('note_records');
    await box.delete(id);
    state = state.where((n) => n.id != id).toList();
    FirestoreService.instance.deleteNoteRecord(id).ignore();
  }
}

final noteRecordsProvider =
    StateNotifierProvider<NoteRecordsNotifier, List<NoteRecord>>(
  (ref) => NoteRecordsNotifier(),
);
