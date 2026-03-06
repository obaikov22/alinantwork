import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/leave_record.dart';
import '../../providers/employees_provider.dart';
import '../../providers/leave_records_provider.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider);
    final records = ref.watch(leaveRecordsProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // --- Currently away / sick today ---
    final awayNow = <(Employee, LeaveRecord)>[];
    final sickNow = <(Employee, LeaveRecord)>[];
    final birthdayHolidayNow = <(Employee, LeaveRecord)>[];
    for (final emp in employees) {
      final active = records
          .where((r) => r.employeeId == emp.id && r.containsDate(today))
          .firstOrNull;
      if (active != null) {
        switch (active.type) {
          case LeaveType.annual:
          case LeaveType.bankHoliday:
            awayNow.add((emp, active));
          case LeaveType.sick:
            sickNow.add((emp, active));
          case LeaveType.birthdayHoliday:
            birthdayHolidayNow.add((emp, active));
        }
      }
    }

    // --- Stats (birthday holiday excluded from Away count) ---
    final awayCount = awayNow.length;
    final sickCount = sickNow.length;

    final sevenDaysLater = today.add(const Duration(days: 7));
    final soonIds = <String>{};
    for (final r in records) {
      final start = DateTime(r.startDate.year, r.startDate.month, r.startDate.day);
      if (start.isAfter(today) && !start.isAfter(sevenDaysLater)) {
        soonIds.add(r.employeeId);
      }
    }
    final soonCount = soonIds.length;

    // --- Conflict: first day in next 14 days with 3+ employees on leave ---
    ({DateTime date, int count})? conflict;
    for (var i = 0; i < 14 && conflict == null; i++) {
      final day = today.add(Duration(days: i));
      final onLeave = employees
          .where((emp) => records.any((r) => r.employeeId == emp.id && r.containsDate(day)))
          .length;
      if (onLeave >= 3) conflict = (date: day, count: onLeave);
    }

    // --- Upcoming leave (starts after today, within 7 days) ---
    final upcomingLeave = <(Employee, LeaveRecord)>[];
    for (final r in records) {
      final start = DateTime(r.startDate.year, r.startDate.month, r.startDate.day);
      if (start.isAfter(today) && !start.isAfter(sevenDaysLater)) {
        final emp = employees.where((e) => e.id == r.employeeId).firstOrNull;
        if (emp != null) upcomingLeave.add((emp, r));
      }
    }
    upcomingLeave.sort((a, b) => a.$2.startDate.compareTo(b.$2.startDate));

    // --- Upcoming birthdays (next 30 days, including today) ---
    final upcomingBirthdays = <(Employee, DateTime, int)>[];
    for (final emp in employees) {
      var bday = DateTime(today.year, emp.birthday.month, emp.birthday.day);
      if (bday.isBefore(today)) {
        bday = DateTime(today.year + 1, emp.birthday.month, emp.birthday.day);
      }
      final daysUntil = bday.difference(today).inDays;
      if (daysUntil >= 0 && daysUntil <= 30) {
        upcomingBirthdays.add((emp, bday, daysUntil));
      }
    }
    upcomingBirthdays.sort((a, b) => a.$3.compareTo(b.$3));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 20,
        title: ShaderMask(
          shaderCallback: (bounds) => AppColors.gradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            'Dashboard',
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            color: AppColors.textMuted,
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ── Stats row ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Away',
                      count: awayCount,
                      color: AppColors.annualLeave,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Sick',
                      count: sickCount,
                      color: AppColors.sickLeave,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      label: 'Soon',
                      count: soonCount,
                      color: AppColors.birthday,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Conflict warning ───────────────────────────────────────────
            if (conflict != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ConflictCard(
                  date: conflict.date,
                  count: conflict.count,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Currently Away ─────────────────────────────────────────────
            const _SectionHeader('Currently Away'),
            if (awayNow.isEmpty && birthdayHolidayNow.isEmpty)
              const _EmptyNote('Everyone is in today 🎉')
            else ...[
              ...awayNow.map((pair) {
                final (emp, rec) = pair;
                final returnsDate = rec.endDate.add(const Duration(days: 1));
                final daysLeft = rec.endDate.difference(today).inDays + 1;
                final isBankHoliday = rec.type == LeaveType.bankHoliday;
                final accentColor = isBankHoliday
                    ? AppColors.bankHoliday
                    : AppColors.annualLeave;
                return _PersonCard(
                  employee: emp,
                  accentColor: accentColor,
                  subtitle:
                      'Returns ${DateFormat('d MMM').format(returnsDate)} · '
                      '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
                  badgeLabel: isBankHoliday ? '🏦 Bank Holiday' : 'Annual',
                  badgeColor: accentColor,
                );
              }),
              ...birthdayHolidayNow.map((pair) {
                final (emp, rec) = pair;
                final returnsDate = rec.endDate.add(const Duration(days: 1));
                return _PersonCard(
                  employee: emp,
                  accentColor: AppColors.gradientStart,
                  subtitle:
                      '🎂 Birthday holiday · Returns ${DateFormat('d MMM').format(returnsDate)}',
                  badgeLabel: '🎂 Birthday',
                  badgeColor: AppColors.gradientStart,
                );
              }),
            ],
            const SizedBox(height: 20),

            // ── Currently Sick ─────────────────────────────────────────────
            if (sickNow.isNotEmpty) ...[
              const _SectionHeader('Currently Sick'),
              ...sickNow.map((pair) {
                final (emp, rec) = pair;
                final empSickTally = records
                    .where(
                      (r) =>
                          r.employeeId == emp.id &&
                          r.type == LeaveType.sick &&
                          r.startDate.year == today.year,
                    )
                    .length;
                return _PersonCard(
                  employee: emp,
                  accentColor: AppColors.sickLeave,
                  subtitle:
                      'Since ${DateFormat('d MMM').format(rec.startDate)} · '
                      '${_ordinal(empSickTally)} time this year',
                  badgeLabel: 'Sick',
                  badgeColor: AppColors.sickLeave,
                );
              }),
              const SizedBox(height: 20),
            ],

            // ── Upcoming Leave ─────────────────────────────────────────────
            const _SectionHeader('Upcoming (Next 7 Days)'),
            if (upcomingLeave.isEmpty)
              const _EmptyNote('No leave starting in the next 7 days')
            else
              ...upcomingLeave.map((pair) {
                final (emp, rec) = pair;
                final start = DateTime(
                  rec.startDate.year,
                  rec.startDate.month,
                  rec.startDate.day,
                );
                final daysUntil = start.difference(today).inDays;
                final dur = rec.durationDays;
                return _PersonCard(
                  employee: emp,
                  accentColor: AppColors.birthday,
                  subtitle:
                      'Starts ${DateFormat('d MMM').format(rec.startDate)} · '
                      '$dur ${dur == 1 ? 'day' : 'days'}',
                  badgeLabel: 'In $daysUntil ${daysUntil == 1 ? 'day' : 'days'}',
                  badgeColor: AppColors.birthday,
                );
              }),

            // ── Upcoming Birthdays ─────────────────────────────────────────
            if (upcomingBirthdays.isNotEmpty) ...[
              const SizedBox(height: 20),
              const _SectionHeader('Upcoming Birthdays 🎂'),
              ...upcomingBirthdays.map((triple) {
                final (emp, bday, daysUntil) = triple;
                return _PersonCard(
                  employee: emp,
                  accentColor: AppColors.birthday,
                  subtitle: '🎂 ${DateFormat('d MMM').format(bday)}',
                  badgeLabel: daysUntil == 0
                      ? 'Today!'
                      : 'In $daysUntil ${daysUntil == 1 ? 'day' : 'days'}',
                  badgeColor: AppColors.birthday,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _ordinal(int n) {
  if (n >= 11 && n <= 13) return '${n}th';
  return switch (n % 10) {
    1 => '${n}st',
    2 => '${n}nd',
    3 => '${n}rd',
    _ => '${n}th',
  };
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: GoogleFonts.dmMono(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: count > 0 ? color : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.sora(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConflictCard extends StatelessWidget {
  final DateTime date;
  final int count;

  const _ConflictCard({required this.date, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.birthday.withValues(alpha: 0.078),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.birthday.withValues(alpha: 0.208),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conflict detected',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.birthday,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count people off on ${DateFormat('d MMM').format(date)} simultaneously',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmMono(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;
  const _EmptyNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Text(
        text,
        style: GoogleFonts.sora(fontSize: 12, color: AppColors.textMuted),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Employee employee;
  final Color accentColor;
  final String subtitle;
  final String badgeLabel;
  final Color badgeColor;

  const _PersonCard({
    required this.employee,
    required this.accentColor,
    required this.subtitle,
    required this.badgeLabel,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final avatarColor = Color(employee.color);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent bar
                Container(width: 3, color: accentColor),

                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: avatarColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _initials(employee.name),
                              style: GoogleFonts.sora(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: avatarColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name + subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                employee.name,
                                style: GoogleFonts.sora(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: GoogleFonts.dmMono(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badgeLabel,
                            style: GoogleFonts.sora(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: badgeColor,
                            ),
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
    );
  }
}
