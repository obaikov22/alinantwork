import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/leave_record.dart';
import '../../providers/employees_provider.dart';
import '../../providers/leave_records_provider.dart';
import '../../theme/app_theme.dart';
import 'add_leave_sheet.dart';
import 'leave_records_list.dart';
import 'weekly_grid.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _weekStart;
  bool _listMode = false;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
  }

  static DateTime _mondayOf(DateTime date) {
    final weekday = date.weekday; // 1=Mon, 7=Sun
    return DateTime(date.year, date.month, date.day - (weekday - 1));
  }

  void _prevWeek() =>
      setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));

  void _nextWeek() =>
      setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  String _monthYearLabel() {
    final lastDay = _weekStart.add(const Duration(days: 6));
    if (_weekStart.month == lastDay.month) {
      return DateFormat('MMMM yyyy').format(_weekStart);
    }
    if (_weekStart.year == lastDay.year) {
      return '${DateFormat('MMM').format(_weekStart)} / ${DateFormat('MMM yyyy').format(lastDay)}';
    }
    return '${DateFormat('MMM yyyy').format(_weekStart)} / ${DateFormat('MMM yyyy').format(lastDay)}';
  }

  void _confirmDeleteRecord(LeaveRecord record) {
    final (label, color) = switch (record.type) {
      LeaveType.annual => ('Annual Leave', AppColors.annualLeave),
      LeaveType.sick => ('Sick Leave', AppColors.sickLeave),
      LeaveType.birthdayHoliday => ('Birthday Holiday', AppColors.gradientStart),
      LeaveType.bankHoliday => ('Bank Holiday', AppColors.bankHoliday),
    };
    final dateRange = record.durationDays == 1
        ? DateFormat('d MMM yyyy').format(record.startDate)
        : '${DateFormat('d MMM').format(record.startDate)} – ${DateFormat('d MMM yyyy').format(record.endDate)}';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete $label?',
          style: GoogleFonts.sora(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateRange,
              style: GoogleFonts.dmMono(fontSize: 13, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              '${record.durationDays} ${record.durationDays == 1 ? 'day' : 'days'}',
              style: GoogleFonts.sora(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.sora(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(leaveRecordsProvider.notifier).removeRecord(record.id);
            },
            child: Text(
              'Delete',
              style: GoogleFonts.sora(
                color: AppColors.sickLeave,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddLeave() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddLeaveSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);
    final leaveRecords = ref.watch(leaveRecordsProvider);
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.gradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text(
                'Alina',
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              'NTWork',
              style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                DateFormat('d MMM').format(today),
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Week navigation row — grid mode only
          if (!_listMode) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  _NavButton(icon: Icons.chevron_left, onTap: _prevWeek),
                  Expanded(
                    child: Center(
                      child: Text(
                        _monthYearLabel(),
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ),
                  _NavButton(icon: Icons.chevron_right, onTap: _nextWeek),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 12),

          // Legend + toggle (2 rows)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _LegendItem(color: AppColors.annualLeave, label: 'Annual'),
                    const SizedBox(width: 10),
                    _LegendItem(color: AppColors.sickLeave, label: 'Sick'),
                    const SizedBox(width: 10),
                    _LegendItem(color: AppColors.birthday, label: 'Birthday'),
                    const Spacer(),
                    _ViewToggle(
                      isListMode: _listMode,
                      onToggle: () => setState(() => _listMode = !_listMode),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _LegendItem(
                        color: AppColors.gradientStart, label: 'Bday hol.'),
                    const SizedBox(width: 10),
                    _LegendItem(
                        color: AppColors.bankHoliday, label: 'Bank hol.'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: _listMode
                ? LeaveRecordsList(
                    leaveRecords: leaveRecords,
                    employees: employees,
                    onDeleteRecord: _confirmDeleteRecord,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    child: WeeklyGrid(
                      weekStart: _weekStart,
                      employees: employees,
                      leaveRecords: leaveRecords,
                      onDeleteRecord: _confirmDeleteRecord,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _GradientFab(onTap: _openAddLeave),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _ViewToggle extends StatelessWidget {
  final bool isListMode;
  final VoidCallback onToggle;

  const _ViewToggle({required this.isListMode, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            label: 'Grid',
            active: !isListMode,
            onTap: isListMode ? onToggle : null,
          ),
          _ToggleBtn(
            label: 'List',
            active: isListMode,
            onTap: isListMode ? null : onToggle,
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.gradientStart : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.text, size: 20),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.sora(fontSize: 10, color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _GradientFab extends StatelessWidget {
  final VoidCallback onTap;

  const _GradientFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.gradientStart.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
