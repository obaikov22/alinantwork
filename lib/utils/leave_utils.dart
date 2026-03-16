import '../models/leave_record.dart';

/// Counts the number of days in [startDate..endDate] that are actual working
/// days for an employee:
///   – Skips any day whose [DateTime.weekday] is in [weekendDays].
///   – Skips any day covered by a bank-holiday record in [bankHolidayRecords].
///
/// Pass an empty list for [bankHolidayRecords] when computing bank-holiday
/// records themselves (they are the bank holidays, nothing to subtract).
int countWorkingDays({
  required DateTime startDate,
  required DateTime endDate,
  required List<int> weekendDays,
  List<LeaveRecord> bankHolidayRecords = const [],
}) {
  int count = 0;
  var d = DateTime(startDate.year, startDate.month, startDate.day);
  final end = DateTime(endDate.year, endDate.month, endDate.day);

  while (!d.isAfter(end)) {
    if (!weekendDays.contains(d.weekday)) {
      final isBankHoliday = bankHolidayRecords.any((r) => r.containsDate(d));
      if (!isBankHoliday) count++;
    }
    d = d.add(const Duration(days: 1));
  }
  return count;
}

/// Counts the unique working days covered by a list of leave records.
/// Each calendar day is counted at most once, even if multiple records overlap
/// on the same day (e.g. an annual leave record that spans a bank holiday).
int countUniqueWorkingDays({
  required List<LeaveRecord> records,
  required List<int> weekendDays,
}) {
  final seen = <String>{};
  for (final r in records) {
    var d = DateTime(r.startDate.year, r.startDate.month, r.startDate.day);
    final end = DateTime(r.endDate.year, r.endDate.month, r.endDate.day);
    while (!d.isAfter(end)) {
      if (!weekendDays.contains(d.weekday)) {
        seen.add('${d.year}-${d.month}-${d.day}');
      }
      d = d.add(const Duration(days: 1));
    }
  }
  return seen.length;
}
