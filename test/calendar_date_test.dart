import 'package:alinantwork/models/leave_record.dart';
import 'package:alinantwork/utils/calendar_date.dart';
import 'package:alinantwork/utils/leave_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('addCalendarDays keeps calendar dates correct across October DST', () {
    final days = List.generate(
      7,
      (i) => addCalendarDays(DateTime(2026, 10, 19), i),
    );

    expect(days.map((d) => d.day), [19, 20, 21, 22, 23, 24, 25]);
    expect(days.map((d) => d.weekday), [1, 2, 3, 4, 5, 6, 7]);
    expect(addCalendarDays(DateTime(2026, 10, 25), 1), DateTime(2026, 10, 26));
  });

  test('leave duration counts calendar days across DST changes', () {
    final record = LeaveRecord(
      id: 'leave-1',
      employeeId: 'employee-1',
      type: LeaveType.annual,
      startDate: DateTime(2026, 10, 24),
      endDate: DateTime(2026, 10, 26),
    );

    expect(record.durationDays, 3);
    expect(record.containsDate(DateTime(2026, 10, 25)), isTrue);
    expect(record.containsDate(DateTime(2026, 10, 27)), isFalse);
  });

  test('working-day count advances by calendar date', () {
    final workingDays = countWorkingDays(
      startDate: DateTime(2026, 10, 23),
      endDate: DateTime(2026, 10, 27),
      weekendDays: const [6, 7],
    );

    expect(workingDays, 3);
  });

  test('annual balance counts only annual working days in the target year', () {
    final records = [
      LeaveRecord(
        id: 'annual-1',
        employeeId: 'employee-1',
        type: LeaveType.annual,
        startDate: DateTime(2026, 5, 4),
        endDate: DateTime(2026, 5, 8),
      ),
      LeaveRecord(
        id: 'bank-1',
        employeeId: 'employee-1',
        type: LeaveType.bankHoliday,
        startDate: DateTime(2026, 5, 4),
        endDate: DateTime(2026, 5, 4),
      ),
      LeaveRecord(
        id: 'birthday-1',
        employeeId: 'employee-1',
        type: LeaveType.birthdayHoliday,
        startDate: DateTime(2026, 5, 6),
        endDate: DateTime(2026, 5, 6),
      ),
      LeaveRecord(
        id: 'sick-1',
        employeeId: 'employee-1',
        type: LeaveType.sick,
        startDate: DateTime(2026, 5, 7),
        endDate: DateTime(2026, 5, 7),
      ),
      LeaveRecord(
        id: 'annual-previous-year',
        employeeId: 'employee-1',
        type: LeaveType.annual,
        startDate: DateTime(2025, 5, 5),
        endDate: DateTime(2025, 5, 9),
      ),
    ];

    final used = countDeductibleAnnualLeaveDays(
      records: records,
      employeeId: 'employee-1',
      weekendDays: const [6, 7],
      year: 2026,
    );

    expect(used, 2);
  });

  test('annual balance deduplicates overlapping annual records', () {
    final records = [
      LeaveRecord(
        id: 'annual-1',
        employeeId: 'employee-1',
        type: LeaveType.annual,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 3),
      ),
      LeaveRecord(
        id: 'annual-2',
        employeeId: 'employee-1',
        type: LeaveType.annual,
        startDate: DateTime(2026, 6, 3),
        endDate: DateTime(2026, 6, 5),
      ),
    ];

    final used = countDeductibleAnnualLeaveDays(
      records: records,
      employeeId: 'employee-1',
      weekendDays: const [6, 7],
      year: 2026,
    );

    expect(used, 5);
  });
}
