import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/employee.dart';
import '../../models/note_record.dart';
import '../../providers/employees_provider.dart';
import '../../providers/note_records_provider.dart';
import '../../theme/app_theme.dart';
import 'add_note_sheet.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  late DateTime _displayMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _displayMonth = DateTime(today.year, today.month);
    _selectedDay = today;
  }

  void _prevMonth() => setState(() {
        _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1);
        _selectedDay = _displayMonth;
      });

  void _nextMonth() => setState(() {
        _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1);
        _selectedDay = _displayMonth;
      });

  void _onDayTapped(DateTime day) {
    setState(() => _selectedDay = day);
    _openAddNote(day);
  }

  void _openAddNote(DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddNoteSheet(selectedDate: date),
    );
  }

  Future<void> _deleteNote(NoteRecord note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Delete Note',
          style: GoogleFonts.sora(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this note?',
          style: GoogleFonts.sora(color: AppColors.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.sora(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
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

    if (confirmed == true) {
      await ref.read(noteRecordsProvider.notifier).removeNote(note.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(noteRecordsProvider);
    final employees = ref.watch(employeesProvider);

    final monthNotes = allNotes
        .where(
          (n) =>
              n.date.year == _displayMonth.year &&
              n.date.month == _displayMonth.month,
        )
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final daysWithNotes = {for (final n in monthNotes) n.date.day};
    final employeeMap = {for (final e in employees) e.id: e};
    final monthLabel = DateFormat('MMMM yyyy').format(_displayMonth);

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
            'Notes',
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly mini-calendar
          _MonthCalendar(
            displayMonth: _displayMonth,
            selectedDay: _selectedDay,
            daysWithNotes: daysWithNotes,
            onPrevMonth: _prevMonth,
            onNextMonth: _nextMonth,
            onDayTapped: _onDayTapped,
          ),

          const Divider(height: 1, color: AppColors.border),

          // Section label
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Text(
              'NOTES — ${monthLabel.toUpperCase()}',
              style: GoogleFonts.dmMono(
                fontSize: 10,
                letterSpacing: 1.0,
                color: AppColors.textMuted,
              ),
            ),
          ),

          // Notes list
          Expanded(
            child: monthNotes.isEmpty
                ? const _EmptyNotes()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: monthNotes.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final note = monthNotes[i];
                      return _NoteItem(
                        note: note,
                        employee: note.employeeId != null
                            ? employeeMap[note.employeeId]
                            : null,
                        onDelete: () => _deleteNote(note),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _GradientFab(
        onTap: () => _openAddNote(DateTime.now()),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Monthly calendar
// ---------------------------------------------------------------------------

class _MonthCalendar extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime selectedDay;
  final Set<int> daysWithNotes;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final void Function(DateTime) onDayTapped;

  const _MonthCalendar({
    required this.displayMonth,
    required this.selectedDay,
    required this.daysWithNotes,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDayTapped,
  });

  List<DateTime> _buildCells() {
    final first = DateTime(displayMonth.year, displayMonth.month, 1);
    final leadingDays = first.weekday - 1; // 0 = Monday
    final daysInMonth = DateUtils.getDaysInMonth(displayMonth.year, displayMonth.month);

    final cells = <DateTime>[];

    for (int i = leadingDays; i > 0; i--) {
      cells.add(first.subtract(Duration(days: i)));
    }

    for (int i = 1; i <= daysInMonth; i++) {
      cells.add(DateTime(displayMonth.year, displayMonth.month, i));
    }

    int trailing = 7 - (cells.length % 7);
    if (trailing == 7) trailing = 0;
    for (int i = 1; i <= trailing; i++) {
      cells.add(DateTime(displayMonth.year, displayMonth.month + 1, i));
    }

    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final cells = _buildCells();
    final monthLabel = DateFormat('MMMM yyyy').format(displayMonth);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month navigation row
          Row(
            children: [
              _NavButton(icon: Icons.chevron_left, onTap: onPrevMonth),
              Expanded(
                child: Center(
                  child: Text(
                    monthLabel,
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              _NavButton(icon: Icons.chevron_right, onTap: onNextMonth),
            ],
          ),
          const SizedBox(height: 10),

          // Day of week headers
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: GoogleFonts.dmMono(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),

          // Day grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: cells.length,
            itemBuilder: (_, index) {
              final date = cells[index];
              final isCurrentMonth = date.month == displayMonth.month &&
                  date.year == displayMonth.year;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = isCurrentMonth &&
                  date.year == selectedDay.year &&
                  date.month == selectedDay.month &&
                  date.day == selectedDay.day;
              final hasNotes = isCurrentMonth && daysWithNotes.contains(date.day);

              return _DayCell(
                date: date,
                isCurrentMonth: isCurrentMonth,
                isToday: isToday,
                isSelected: isSelected,
                hasNotes: hasNotes,
                onTap: isCurrentMonth ? () => onDayTapped(date) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final bool hasNotes;
  final VoidCallback? onTap;

  const _DayCell({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.hasNotes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.surface;
    Color borderColor = AppColors.border;
    Color textColor = AppColors.text;
    FontWeight fontWeight = FontWeight.w400;
    double borderWidth = 1.0;

    if (isSelected) {
      bgColor = AppColors.gradientStart;
      borderColor = AppColors.gradientStart;
      textColor = Colors.white;
      fontWeight = FontWeight.w700;
    } else if (isToday) {
      borderColor = AppColors.gradientStart;
      textColor = AppColors.gradientStart;
      fontWeight = FontWeight.w700;
      borderWidth = 1.5;
    }

    Widget cell = GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${date.day}',
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
            if (hasNotes)
              Positioned(
                bottom: 3,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.gradientStart,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!isCurrentMonth) {
      return Opacity(opacity: 0.25, child: cell);
    }
    return cell;
  }
}

// ---------------------------------------------------------------------------
// Notes list items
// ---------------------------------------------------------------------------

class _NoteItem extends StatelessWidget {
  final NoteRecord note;
  final Employee? employee;
  final VoidCallback onDelete;

  const _NoteItem({
    required this.note,
    required this.employee,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isGeneral = note.type == NoteType.general;
    final accentColor = isGeneral ? AppColors.gradientStart : AppColors.gradientEnd;
    final dateLabel = DateFormat('d MMM').format(note.date);

    return GestureDetector(
      onLongPress: onDelete,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: AppColors.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: accentColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: date + tag
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateLabel,
                              style: GoogleFonts.dmMono(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              isGeneral ? '📌 General' : '👤 Employee',
                              style: GoogleFonts.sora(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Note body
                        Text(
                          note.text,
                          style: GoogleFonts.sora(
                            fontSize: 13,
                            color: AppColors.text,
                            height: 1.5,
                          ),
                        ),

                        // Employee name
                        if (employee != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            '→ ${employee!.name}',
                            style: GoogleFonts.sora(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gradientEnd,
                            ),
                          ),
                        ],
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

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📝', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'No notes this month',
            style: GoogleFonts.sora(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

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
