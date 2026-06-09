import '../models/leave_record.dart';
import 'calendar_date.dart';

/// Counts the number of days in [startDate..endDate] that are working days
/// for an employee (i.e. not in [weekendDays]).
int countWorkingDays({
  required DateTime startDate,
  required DateTime endDate,
  required List<int> weekendDays,
}) {
  int count = 0;
  var d = dateOnly(startDate);
  final end = dateOnly(endDate);

  while (!d.isAfter(end)) {
    if (!weekendDays.contains(d.weekday)) count++;
    d = addCalendarDays(d, 1);
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
    var d = dateOnly(r.startDate);
    final end = dateOnly(r.endDate);
    while (!d.isAfter(end)) {
      if (!weekendDays.contains(d.weekday)) {
        seen.add('${d.year}-${d.month}-${d.day}');
      }
      d = addCalendarDays(d, 1);
    }
  }
  return seen.length;
}

/// Counts annual leave days that should be deducted from an employee's annual
/// allowance for [year].
///
/// Deducted days are unique working days covered by annual leave records only.
/// Any day also covered by a non-annual leave record for the same employee is
/// excluded, so bank holidays and birthday holidays do not reduce the balance.
int countDeductibleAnnualLeaveDays({
  required List<LeaveRecord> records,
  required String employeeId,
  required List<int> weekendDays,
  required int year,
}) {
  final nonAnnualDays = <String>{};
  for (final r in records.where(
    (r) => r.employeeId == employeeId && r.type != LeaveType.annual,
  )) {
    var d = dateOnly(r.startDate);
    final end = dateOnly(r.endDate);
    while (!d.isAfter(end)) {
      if (d.year == year) {
        nonAnnualDays.add(_dateKey(d));
      }
      d = addCalendarDays(d, 1);
    }
  }

  final annualDays = <String>{};
  for (final r in records.where(
    (r) => r.employeeId == employeeId && r.type == LeaveType.annual,
  )) {
    var d = dateOnly(r.startDate);
    final end = dateOnly(r.endDate);
    while (!d.isAfter(end)) {
      final key = _dateKey(d);
      if (d.year == year &&
          !weekendDays.contains(d.weekday) &&
          !nonAnnualDays.contains(key)) {
        annualDays.add(key);
      }
      d = addCalendarDays(d, 1);
    }
  }

  return annualDays.length;
}

String _dateKey(DateTime date) => '${date.year}-${date.month}-${date.day}';
