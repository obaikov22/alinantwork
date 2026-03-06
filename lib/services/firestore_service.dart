import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/employee.dart';
import '../models/leave_record.dart';
import '../models/note_record.dart';

class FirestoreService {
  static final FirestoreService instance = FirestoreService._();
  FirestoreService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _employees =>
      _db.collection('users').doc(_uid).collection('employees');

  CollectionReference<Map<String, dynamic>> get _leaveRecords =>
      _db.collection('users').doc(_uid).collection('leave_records');

  CollectionReference<Map<String, dynamic>> get _noteRecords =>
      _db.collection('users').doc(_uid).collection('note_records');

  // ── Employees ─────────────────────────────────────────────────────────────

  Future<void> saveEmployee(Employee e) async {
    await _employees.doc(e.id).set(_employeeToMap(e));
  }

  Future<void> deleteEmployee(String id) async {
    await _employees.doc(id).delete();
  }

  Future<void> syncEmployees(List<Employee> list) async {
    if (list.isEmpty) return;
    final batch = _db.batch();
    for (final e in list) {
      batch.set(_employees.doc(e.id), _employeeToMap(e));
    }
    await batch.commit();
  }

  Future<List<Employee>> fetchEmployees() async {
    final snap = await _employees.get();
    final result = <Employee>[];
    for (final d in snap.docs) {
      try {
        result.add(_employeeFromMap(d.data()));
      } catch (_) {}
    }
    return result;
  }

  // ── Leave Records ──────────────────────────────────────────────────────────

  Future<void> saveLeaveRecord(LeaveRecord r) async {
    await _leaveRecords.doc(r.id).set(_leaveToMap(r));
  }

  Future<void> deleteLeaveRecord(String id) async {
    await _leaveRecords.doc(id).delete();
  }

  Future<void> deleteAllLeaveRecordsForEmployee(String employeeId) async {
    final snap = await _leaveRecords
        .where('employeeId', isEqualTo: employeeId)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> syncLeaveRecords(List<LeaveRecord> list) async {
    if (list.isEmpty) return;
    final batch = _db.batch();
    for (final r in list) {
      batch.set(_leaveRecords.doc(r.id), _leaveToMap(r));
    }
    await batch.commit();
  }

  Future<List<LeaveRecord>> fetchLeaveRecords() async {
    final snap = await _leaveRecords.get();
    final result = <LeaveRecord>[];
    for (final d in snap.docs) {
      try {
        result.add(_leaveFromMap(d.data()));
      } catch (_) {}
    }
    return result;
  }

  // ── Note Records ───────────────────────────────────────────────────────────

  Future<void> saveNoteRecord(NoteRecord n) async {
    await _noteRecords.doc(n.id).set(_noteToMap(n));
  }

  Future<void> deleteNoteRecord(String id) async {
    await _noteRecords.doc(id).delete();
  }

  Future<void> syncNoteRecords(List<NoteRecord> list) async {
    if (list.isEmpty) return;
    final batch = _db.batch();
    for (final n in list) {
      batch.set(_noteRecords.doc(n.id), _noteToMap(n));
    }
    await batch.commit();
  }

  Future<List<NoteRecord>> fetchNoteRecords() async {
    final snap = await _noteRecords.get();
    final result = <NoteRecord>[];
    for (final d in snap.docs) {
      try {
        result.add(_noteFromMap(d.data()));
      } catch (_) {}
    }
    return result;
  }

  // ── Serialization: Employee ────────────────────────────────────────────────

  Map<String, dynamic> _employeeToMap(Employee e) => {
        'id': e.id,
        'name': e.name,
        'birthday': e.birthday.toIso8601String(),
        'totalAnnualDays': e.totalAnnualDays,
        'usedAnnualDays': e.usedAnnualDays,
        'color': e.color,
        'createdAt': e.createdAt.toIso8601String(),
        'role': e.role,
      };

  Employee _employeeFromMap(Map<String, dynamic> m) => Employee(
        id: m['id'] as String,
        name: m['name'] as String,
        birthday: DateTime.parse(m['birthday'] as String),
        totalAnnualDays: (m['totalAnnualDays'] as num).toInt(),
        usedAnnualDays: (m['usedAnnualDays'] as num).toInt(),
        color: (m['color'] as num).toInt(),
        createdAt: DateTime.parse(m['createdAt'] as String),
        role: m['role'] as String?,
      );

  // ── Serialization: LeaveRecord ─────────────────────────────────────────────

  Map<String, dynamic> _leaveToMap(LeaveRecord r) => {
        'id': r.id,
        'employeeId': r.employeeId,
        'type': r.type.name,
        'startDate': r.startDate.toIso8601String(),
        'endDate': r.endDate.toIso8601String(),
        'notes': r.notes,
      };

  LeaveRecord _leaveFromMap(Map<String, dynamic> m) => LeaveRecord(
        id: m['id'] as String,
        employeeId: m['employeeId'] as String,
        type: LeaveType.values.byName(m['type'] as String),
        startDate: DateTime.parse(m['startDate'] as String),
        endDate: DateTime.parse(m['endDate'] as String),
        notes: m['notes'] as String?,
      );

  // ── Serialization: NoteRecord ──────────────────────────────────────────────

  Map<String, dynamic> _noteToMap(NoteRecord n) => {
        'id': n.id,
        'date': n.date.toIso8601String(),
        'type': n.type.name,
        'text': n.text,
        'employeeId': n.employeeId,
        'createdAt': n.createdAt.toIso8601String(),
      };

  NoteRecord _noteFromMap(Map<String, dynamic> m) => NoteRecord(
        id: m['id'] as String,
        date: DateTime.parse(m['date'] as String),
        type: NoteType.values.byName(m['type'] as String),
        text: m['text'] as String,
        employeeId: m['employeeId'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );
}
