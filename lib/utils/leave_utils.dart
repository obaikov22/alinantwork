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
