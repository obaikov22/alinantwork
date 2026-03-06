import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/leave_record.dart';
import '../../theme/app_theme.dart';

class LeaveRecordsList extends StatelessWidget {
  final List<LeaveRecord> leaveRecords;
  final List<Employee> employees;
  final void Function(LeaveRecord) onDeleteRecord;

  const LeaveRecordsList({
    super.key,
    required this.leaveRecords,
    required this.employees,
    required this.onDeleteRecord,
  });

  Employee? _findEmployee(String employeeId) =>
      employees.where((e) => e.id == employeeId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    if (leaveRecords.isEmpty) {
      return const _EmptyState();
    }

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    final List<LeaveRecord> active = [];
    final List<LeaveRecord> upcoming = [];
    final List<LeaveRecord> past = [];

    for (final r in leaveRecords) {
      final start =
          DateTime(r.startDate.year, r.startDate.month, r.startDate.day);
      final end = DateTime(r.endDate.year, r.endDate.month, r.endDate.day);
      if (!start.isAfter(todayDate) && !end.isBefore(todayDate)) {
        active.add(r);
      } else if (start.isAfter(todayDate)) {
        upcoming.add(r);
      } else {
        past.add(r);
      }
    }

    active.sort((a, b) => a.endDate.compareTo(b.endDate));
    upcoming.sort((a, b) => a.startDate.compareTo(b.startDate));
    past.sort((a, b) => b.startDate.compareTo(a.startDate));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        if (active.isNotEmpty) ...[
          _SectionLabel('Active'),
          const SizedBox(height: 8),
          ...active.map((r) => _RecordItem(
                record: r,
                employee: _findEmployee(r.employeeId),
                onDelete: () => onDeleteRecord(r),
              )),
          const SizedBox(height: 16),
        ],
        if (upcoming.isNotEmpty) ...[
          _SectionLabel('Upcoming'),
          const SizedBox(height: 8),
          ...upcoming.map((r) => _RecordItem(
                record: r,
                employee: _findEmployee(r.employeeId),
                onDelete: () => onDeleteRecord(r),
              )),
          const SizedBox(height: 16),
        ],
        if (past.isNotEmpty) ...[
          _SectionLabel('Past'),
          const SizedBox(height: 8),
          ...past.map((r) => _RecordItem(
                record: r,
                employee: _findEmployee(r.employeeId),
                onDelete: () => onDeleteRecord(r),
              )),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.dmMono(
        fontSize: 10,
        letterSpacing: 1.0,
        color: AppColors.textMuted,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Record item card
// ---------------------------------------------------------------------------

class _RecordItem extends StatelessWidget {
  final LeaveRecord record;
  final Employee? employee;
  final VoidCallback onDelete;

  const _RecordItem({
    required this.record,
    required this.employee,
    required this.onDelete,
  });

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = switch (record.type) {
      LeaveType.annual => AppColors.annualLeave,
      LeaveType.sick => AppColors.sickLeave,
      LeaveType.birthdayHoliday => AppColors.gradientStart,
      LeaveType.bankHoliday => AppColors.bankHoliday,
    };
    final typeLabel = switch (record.type) {
      LeaveType.annual => 'Annual',
      LeaveType.sick => 'Sick',
      LeaveType.birthdayHoliday => '🎂 Birthday',
      LeaveType.bankHoliday => '🏦 Bank Holiday',
    };

    final avatarColor =
        employee != null ? Color(employee!.color) : AppColors.textMuted;
    final initials =
        employee != null ? _initials(employee!.name) : '?';

    final sameYear = record.startDate.year == record.endDate.year;
    final startFmt = sameYear
        ? DateFormat('d MMM').format(record.startDate)
        : DateFormat('d MMM yy').format(record.startDate);
    final endFmt = sameYear
        ? DateFormat('d MMM').format(record.endDate)
        : DateFormat('d MMM yy').format(record.endDate);
    final dateRange = record.durationDays == 1
        ? DateFormat('d MMM').format(record.startDate)
        : '$startFmt – $endFmt';

    final days = record.durationDays;
    final durationLabel = '$days ${days == 1 ? 'day' : 'days'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onLongPress: onDelete,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Accent bar
                  Container(width: 3, color: accentColor),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Avatar
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: avatarColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: avatarColor.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              initials,
                              style: GoogleFonts.sora(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: avatarColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Name + date
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        employee?.name ?? 'Unknown',
                                        style: GoogleFonts.sora(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.text,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Type badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(
                                            alpha: 0.12),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: accentColor.withValues(
                                              alpha: 0.35),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        typeLabel,
                                        style: GoogleFonts.sora(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      dateRange,
                                      style: GoogleFonts.dmMono(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Duration badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface2,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        durationLabel,
                                        style: GoogleFonts.dmMono(
                                          fontSize: 10,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'No leave records yet',
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add the first one',
            style: GoogleFonts.sora(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
