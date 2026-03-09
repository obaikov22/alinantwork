import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/employee.dart';
import '../../models/leave_record.dart';
import '../../theme/app_theme.dart';

const _nameColWidth = 80.0;
const _minCellWidth = 36.0;
const _cellHeight = 22.0;
const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

class WeeklyGrid extends StatelessWidget {
  final DateTime weekStart;
  final List<Employee> employees;
  final List<LeaveRecord> leaveRecords;
  final void Function(LeaveRecord)? onDeleteRecord;

  const WeeklyGrid({
    super.key,
    required this.weekStart,
    required this.employees,
    required this.leaveRecords,
    this.onDeleteRecord,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellWidth =
            max(_minCellWidth, (constraints.maxWidth - _nameColWidth) / 7);
        final double totalWidth = _nameColWidth + 7 * cellWidth;
        final bool needsHScroll = totalWidth > constraints.maxWidth + 1;

        final grid = _GridContent(
          days: days,
          today: today,
          employees: employees,
          leaveRecords: leaveRecords,
          cellWidth: cellWidth,
          onDeleteRecord: onDeleteRecord,
        );

        if (needsHScroll) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: totalWidth, child: grid),
          );
        }
        return grid;
      },
    );
  }
}

class _GridContent extends StatelessWidget {
  final List<DateTime> days;
  final DateTime today;
  final List<Employee> employees;
  final List<LeaveRecord> leaveRecords;
  final double cellWidth;
  final void Function(LeaveRecord)? onDeleteRecord;

  const _GridContent({
    required this.days,
    required this.today,
    required this.employees,
    required this.leaveRecords,
    required this.cellWidth,
    this.onDeleteRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header row
        Row(
          children: [
            const SizedBox(width: _nameColWidth),
            ...List.generate(7, (i) {
              final d = days[i];
              final isToday = _sameDay(d, today);
              return _DayHeader(
                letter: _dayLetters[i],
                number: d.day,
                isToday: isToday,
                width: cellWidth,
              );
            }),
          ],
        ),
        const SizedBox(height: 8),
        if (employees.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Center(
              child: Text(
                'No team members yet',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          )
        else
          ...employees.map(
            (emp) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _EmployeeRow(
                employee: emp,
                days: days,
                today: today,
                leaveRecords: leaveRecords,
                cellWidth: cellWidth,
                onDeleteRecord: onDeleteRecord,
              ),
            ),
          ),
      ],
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _DayHeader extends StatelessWidget {
  final String letter;
  final int number;
  final bool isToday;
  final double width;

  const _DayHeader({
    required this.letter,
    required this.number,
    required this.isToday,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final color = isToday ? AppColors.gradientStart : AppColors.textMuted;
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            letter,
            style: GoogleFonts.sora(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '$number',
            style: GoogleFonts.dmMono(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  final Employee employee;
  final List<DateTime> days;
  final DateTime today;
  final List<LeaveRecord> leaveRecords;
  final double cellWidth;
  final void Function(LeaveRecord)? onDeleteRecord;

  const _EmployeeRow({
    required this.employee,
    required this.days,
    required this.today,
    required this.leaveRecords,
    required this.cellWidth,
    this.onDeleteRecord,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cellHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _nameColWidth,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  employee.name.split(' ').first,
                  style: GoogleFonts.sora(
                    fontSize: 10,
                    color: AppColors.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          ...days.map((day) {
            final record = leaveRecords
                .where(
                  (r) => r.employeeId == employee.id && r.containsDate(day),
                )
                .firstOrNull;
            final isBirthday = employee.birthday.month == day.month &&
                employee.birthday.day == day.day;
            final isToday = _sameDay(day, today);
            final isWeekend = employee.weekendDays.contains(day.weekday);
            return _DayCell(
              day: day,
              record: record,
              isBirthday: isBirthday,
              isToday: isToday,
              isWeekend: isWeekend,
              width: cellWidth,
              onLongPress: record != null && onDeleteRecord != null
                  ? () => onDeleteRecord!(record)
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final LeaveRecord? record;
  final bool isBirthday;
  final bool isToday;
  final bool isWeekend;
  final double width;
  final VoidCallback? onLongPress;

  const _DayCell({
    required this.day,
    required this.record,
    required this.isBirthday,
    required this.isToday,
    required this.isWeekend,
    required this.width,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final style = _computeStyle();
    return SizedBox(
      width: width,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          decoration: BoxDecoration(
            color: style.bgColor,
            borderRadius: style.radius,
            border: style.border,
          ),
          child: style.child != null ? Center(child: style.child) : null,
        ),
      ),
    );
  }

  _CellStyle _computeStyle() {
    if (record != null) return _leaveStyle();
    if (isBirthday) return _birthdayStyle();
    if (isWeekend) return _weekendStyle();
    return _emptyStyle();
  }

  _CellStyle _weekendStyle() {
    return _CellStyle(
      bgColor: AppColors.weekendCell,
      radius: BorderRadius.circular(3),
      border: Border.all(
        color: isToday ? AppColors.gradientStart : AppColors.border,
      ),
      child: null,
    );
  }

  _CellStyle _leaveStyle() {
    final Color baseColor;
    final Widget? child;

    switch (record!.type) {
      case LeaveType.annual:
        baseColor = AppColors.annualLeave;
        child = null;
      case LeaveType.sick:
        baseColor = AppColors.sickLeave;
        child = null;
      case LeaveType.birthdayHoliday:
        baseColor = AppColors.gradientStart;
        child = const Text('🎂', style: TextStyle(fontSize: 11));
      case LeaveType.bankHoliday:
        baseColor = AppColors.bankHoliday;
        child = null;
    }

    final bgColor = baseColor;
    final borderColor = isToday ? AppColors.gradientStart : baseColor;

    return _CellStyle(
      bgColor: bgColor,
      radius: _spanRadius(),
      border: isToday ? Border.all(color: borderColor) : _spanBorder(borderColor),
      child: child,
    );
  }

  _CellStyle _birthdayStyle() {
    final borderColor = isToday ? AppColors.gradientStart : AppColors.birthday;
    return _CellStyle(
      bgColor: AppColors.birthday,
      radius: BorderRadius.circular(3),
      border: Border.all(color: borderColor),
      child: const Text('🎂', style: TextStyle(fontSize: 11)),
    );
  }

  _CellStyle _emptyStyle() {
    final borderColor =
        isToday ? AppColors.gradientStart : AppColors.border;
    return _CellStyle(
      bgColor: AppColors.surface,
      radius: BorderRadius.circular(3),
      border: Border.all(color: borderColor),
      child: null,
    );
  }

  BorderRadius _spanRadius() {
    final start = DateTime(
      record!.startDate.year,
      record!.startDate.month,
      record!.startDate.day,
    );
    final end = DateTime(
      record!.endDate.year,
      record!.endDate.month,
      record!.endDate.day,
    );
    final d = DateTime(day.year, day.month, day.day);
    const r = Radius.circular(3);
    final isStart = d == start;
    final isEnd = d == end;

    if (isStart && isEnd) return const BorderRadius.all(r);
    if (isStart) return const BorderRadius.only(topLeft: r, bottomLeft: r);
    if (isEnd) return const BorderRadius.only(topRight: r, bottomRight: r);
    return BorderRadius.zero;
  }

  BoxBorder _spanBorder(Color color) {
    final start = DateTime(
      record!.startDate.year,
      record!.startDate.month,
      record!.startDate.day,
    );
    final end = DateTime(
      record!.endDate.year,
      record!.endDate.month,
      record!.endDate.day,
    );
    final d = DateTime(day.year, day.month, day.day);
    final isStart = d == start;
    final isEnd = d == end;
    final side = BorderSide(color: color);

    if (isStart && isEnd) return Border.all(color: color);
    if (isStart) {
      return Border(
        top: side,
        bottom: side,
        left: side,
        right: BorderSide.none,
      );
    }
    if (isEnd) {
      return Border(
        top: side,
        bottom: side,
        left: BorderSide.none,
        right: side,
      );
    }
    // Middle of span
    return Border(top: side, bottom: side);
  }
}

class _CellStyle {
  final Color bgColor;
  final BorderRadius radius;
  final BoxBorder border;
  final Widget? child;

  const _CellStyle({
    required this.bgColor,
    required this.radius,
    required this.border,
    required this.child,
  });
}
