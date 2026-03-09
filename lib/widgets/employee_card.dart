import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/employee.dart';
import '../models/leave_record.dart';
import '../providers/employees_provider.dart';
import '../providers/leave_records_provider.dart';
import '../screens/team/edit_employee_sheet.dart';
import '../theme/app_theme.dart';
import '../utils/leave_utils.dart';

class EmployeeCard extends ConsumerWidget {
  final Employee employee;

  const EmployeeCard({super.key, required this.employee});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }

  Color _progressColor(int remaining) {
    if (remaining > 10) return AppColors.annualLeave;
    if (remaining >= 5) return AppColors.birthday;
    return AppColors.sickLeave;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLeave = ref.watch(employeeActiveLeaveProvider(employee.id));
    final allRecords = ref.watch(leaveRecordsProvider);
    final total = employee.totalAnnualDays;

    // Bank-holiday records for this employee — used to exclude those days
    // when counting working days in annual-leave records.
    final empBankHolidays = allRecords
        .where((r) =>
            r.employeeId == employee.id && r.type == LeaveType.bankHoliday)
        .toList();

    // Count only working days (no weekends, annual excludes bank holidays).
    final used = allRecords
        .where((r) =>
            r.employeeId == employee.id &&
            (r.type == LeaveType.annual || r.type == LeaveType.bankHoliday))
        .fold<int>(
          0,
          (sum, r) => sum +
              countWorkingDays(
                startDate: r.startDate,
                endDate: r.endDate,
                weekendDays: employee.weekendDays,
                bankHolidayRecords:
                    r.type == LeaveType.annual ? empBankHolidays : const [],
              ),
        );
    final remaining = (total - used).clamp(0, total);
    final progress = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    final progressColor = _progressColor(remaining);
    final avatarColor = Color(employee.color);

    return GestureDetector(
      onTap: () => _showDetails(context, used),
      onLongPress: () => _showActions(context, ref),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
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
                _initials(employee.name),
                style: GoogleFonts.sora(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: avatarColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name row + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          employee.name,
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (activeLeave != null) ...[
                        const SizedBox(width: 8),
                        _StatusBadge(type: activeLeave.type),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  // Birthday + role row
                  Row(
                    children: [
                      const Text('🎂', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('d MMM').format(employee.birthday),
                        style: GoogleFonts.dmMono(
                          fontSize: 11,
                          color: AppColors.birthday,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (employee.role != null &&
                          employee.role!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            employee.role!,
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Days used/remaining labels
                  Row(
                    children: [
                      Text(
                        '$used used',
                        style: GoogleFonts.dmMono(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$remaining left of $total',
                        style: GoogleFonts.dmMono(
                          fontSize: 10,
                          color: AppColors.annualLeave,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, int usedDays) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _EmployeeDetailsSheet(employee: employee, usedDays: usedDays),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _ActionsSheet(
        employee: employee,
        onEdit: () {
          Navigator.of(sheetCtx).pop();
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => EditEmployeeSheet(employee: employee),
          );
        },
        onDelete: () {
          Navigator.of(sheetCtx).pop();
          _confirmDelete(context, ref);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Remove ${employee.name}?',
          style: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        content: Text(
          'This will also delete all their leave records.',
          style: GoogleFonts.sora(fontSize: 13, color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.sora(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(leaveRecordsProvider.notifier)
                  .removeAllForEmployee(employee.id);
              ref
                  .read(employeesProvider.notifier)
                  .removeEmployee(employee.id);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.sora(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.sickLeave,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Actions sheet
// ---------------------------------------------------------------------------

class _ActionsSheet extends StatelessWidget {
  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActionsSheet({
    required this.employee,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Employee name
          Text(
            employee.name,
            style: GoogleFonts.sora(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),
          // Edit button
          _ActionButton(
            emoji: '✏️',
            label: 'Edit',
            color: AppColors.gradientStart,
            onTap: onEdit,
          ),
          const SizedBox(height: 10),
          // Delete button
          _ActionButton(
            emoji: '🗑️',
            label: 'Delete',
            color: AppColors.sickLeave,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: GoogleFonts.sora(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status badge
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  final LeaveType type;
  const _StatusBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (type) {
      LeaveType.annual => (AppColors.annualLeave, 'Away'),
      LeaveType.sick => (AppColors.sickLeave, 'Sick'),
      LeaveType.birthdayHoliday => (AppColors.gradientStart, '🎂'),
      LeaveType.bankHoliday => (AppColors.bankHoliday, '🏦'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.sora(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Employee details sheet (read-only)
// ---------------------------------------------------------------------------

class _EmployeeDetailsSheet extends StatelessWidget {
  final Employee employee;
  final int usedDays;
  const _EmployeeDetailsSheet({required this.employee, required this.usedDays});

  @override
  Widget build(BuildContext context) {
    final avatarColor = Color(employee.color);
    final remaining =
        (employee.totalAnnualDays - usedDays).clamp(0, employee.totalAnnualDays);

    Color remainingColor;
    if (remaining > 10) {
      remainingColor = AppColors.annualLeave;
    } else if (remaining >= 5) {
      remainingColor = AppColors.birthday;
    } else {
      remainingColor = AppColors.sickLeave;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Avatar + name
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: avatarColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: avatarColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(employee.name),
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: avatarColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    if (employee.role != null && employee.role!.isNotEmpty)
                      Text(
                        employee.role!,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'Birthday',
            value: DateFormat('d MMMM').format(employee.birthday),
            valueColor: AppColors.birthday,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Annual Leave Used',
            value: '$usedDays of ${employee.totalAnnualDays} days',
            valueColor: AppColors.text,
          ),
          const SizedBox(height: 12),
          _DetailRow(
            label: 'Days Remaining',
            value: '$remaining days',
            valueColor: remainingColor,
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.sora(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
