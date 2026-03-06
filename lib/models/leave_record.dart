import 'package:hive/hive.dart';

part 'leave_record.g.dart';

@HiveType(typeId: 1)
enum LeaveType {
  @HiveField(0)
  annual,

  @HiveField(1)
  sick,

  @HiveField(2)
  birthdayHoliday,

  @HiveField(3)
  bankHoliday,
}

@HiveType(typeId: 2)
class LeaveRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String employeeId;

  @HiveField(2)
  late LeaveType type;

  @HiveField(3)
  late DateTime startDate;

  @HiveField(4)
  late DateTime endDate;

  @HiveField(5)
  String? notes;

  LeaveRecord({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.notes,
  });

  int get durationDays {
    return endDate.difference(startDate).inDays + 1;
  }

  bool containsDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  LeaveRecord copyWith({
    String? id,
    String? employeeId,
    LeaveType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) {
    return LeaveRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
    );
  }
}
