import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../models/employee.dart';
import '../../models/leave_record.dart';
import '../../providers/employees_provider.dart';
import '../../providers/leave_records_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/leave_utils.dart';

class AddLeaveSheet extends ConsumerStatefulWidget {
  const AddLeaveSheet({super.key});

  @override
  ConsumerState<AddLeaveSheet> createState() => _AddLeaveSheetState();
}

class _AddLeaveSheetState extends ConsumerState<AddLeaveSheet> {
  String? _selectedEmployeeId;
  LeaveType _leaveType = LeaveType.annual;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _saving = false;

  Future<void> _pickDate({required bool isFrom}) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = isFrom
        ? (_fromDate ?? now)
        : (_toDate ?? _fromDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      helpText: isFrom ? 'Select Start Date' : 'Select End Date',
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
          if (_toDate != null && _toDate!.isBefore(picked)) {
            _toDate = picked;
          }
        } else {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_selectedEmployeeId == null) {
      _showError('Please select an employee');
      return;
    }
    if (_fromDate == null) {
      _showError('Please select a start date');
      return;
    }
    final isBirthdayHoliday = _leaveType == LeaveType.birthdayHoliday;
    if (!isBirthdayHoliday && _toDate == null) {
      _showError('Please select an end date');
      return;
    }
    if (!isBirthdayHoliday && _toDate!.isBefore(_fromDate!)) {
      _showError('End date must be after start date');
      return;
    }

    setState(() => _saving = true);

    final endDate = isBirthdayHoliday ? _fromDate! : _toDate!;

    final record = LeaveRecord(
      id: const Uuid().v4(),
      employeeId: _selectedEmployeeId!,
      type: _leaveType,
      startDate: _fromDate!,
      endDate: endDate,
    );

    await ref.read(leaveRecordsProvider.notifier).addRecord(record);

    if (mounted) Navigator.of(context).pop();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.sora(fontSize: 13)),
        backgroundColor: AppColors.sickLeave,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);
    final allLeaveRecords = ref.watch(leaveRecordsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Compute working-day summary when applicable.
    final countsTowardBalance = _leaveType == LeaveType.annual ||
        _leaveType == LeaveType.bankHoliday;
    final effectiveEnd =
        _leaveType == LeaveType.birthdayHoliday ? _fromDate : _toDate;
    final selectedEmployee = _selectedEmployeeId == null
        ? null
        : employees.where((e) => e.id == _selectedEmployeeId).firstOrNull;
    final showSummary = countsTowardBalance &&
        selectedEmployee != null &&
        _fromDate != null &&
        effectiveEnd != null;

    int calendarDays = 0;
    int workingDays = 0;
    if (showSummary) {
      final empBankHolidays = allLeaveRecords
          .where((r) =>
              r.employeeId == selectedEmployee.id &&
              r.type == LeaveType.bankHoliday)
          .toList();
      calendarDays =
          effectiveEnd!.difference(_fromDate!).inDays + 1;
      workingDays = countWorkingDays(
        startDate: _fromDate!,
        endDate: effectiveEnd,
        weekendDays: selectedEmployee.weekendDays,
        bankHolidayRecords:
            _leaveType == LeaveType.annual ? empBankHolidays : const [],
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
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
            Text(
              'Add Leave',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 24),

            // Employee
            _FieldLabel('Employee'),
            const SizedBox(height: 6),
            _EmployeeDropdown(
              employees: employees,
              value: _selectedEmployeeId,
              onChanged: (id) => setState(() => _selectedEmployeeId = id),
            ),
            const SizedBox(height: 16),

            // Leave type
            _FieldLabel('Leave Type'),
            const SizedBox(height: 8),
            _LeaveTypeToggle(
              value: _leaveType,
              onChanged: (type) => setState(() {
                _leaveType = type;
                // Reset toDate when switching to birthday holiday
                if (type == LeaveType.birthdayHoliday) _toDate = null;
              }),
            ),
            const SizedBox(height: 16),

            // From date
            _FieldLabel(_leaveType == LeaveType.birthdayHoliday ? 'Date' : 'From'),
            const SizedBox(height: 6),
            _DateField(
              value: _fromDate,
              hint: 'Select date',
              onTap: () => _pickDate(isFrom: true),
            ),
            if (_leaveType != LeaveType.birthdayHoliday) ...[
              const SizedBox(height: 12),
              // To date
              _FieldLabel('To'),
              const SizedBox(height: 6),
              _DateField(
                value: _toDate,
                hint: 'Select end date',
                onTap: () => _pickDate(isFrom: false),
              ),
            ],

            // Working-day summary
            if (showSummary) ...[
              const SizedBox(height: 12),
              _WorkingDaySummary(
                calendarDays: calendarDays,
                workingDays: workingDays,
              ),
            ],
            const SizedBox(height: 28),

            // Save
            _GradientButton(
              label: 'Save Leave',
              loading: _saving,
              onTap: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.sora(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _EmployeeDropdown extends StatelessWidget {
  final List<Employee> employees;
  final String? value;
  final void Function(String?) onChanged;

  const _EmployeeDropdown({
    required this.employees,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'No team members — add some first',
          style: GoogleFonts.sora(fontSize: 14, color: AppColors.textMuted),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: AppColors.surface2,
        style: GoogleFonts.sora(fontSize: 14, color: AppColors.text),
        hint: Text(
          'Select employee',
          style: GoogleFonts.sora(fontSize: 14, color: AppColors.textMuted),
        ),
        icon: const Icon(
          Icons.expand_more,
          color: AppColors.textMuted,
          size: 20,
        ),
        onChanged: onChanged,
        items: employees
            .map(
              (emp) => DropdownMenuItem<String>(
                value: emp.id,
                child: Text(
                  emp.name,
                  style:
                      GoogleFonts.sora(fontSize: 14, color: AppColors.text),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _LeaveTypeToggle extends StatelessWidget {
  final LeaveType value;
  final void Function(LeaveType) onChanged;

  const _LeaveTypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ToggleButton(
                label: '🌴 Annual',
                selected: value == LeaveType.annual,
                selectedColor: AppColors.annualLeave,
                onTap: () => onChanged(LeaveType.annual),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ToggleButton(
                label: '🤒 Sick',
                selected: value == LeaveType.sick,
                selectedColor: AppColors.sickLeave,
                onTap: () => onChanged(LeaveType.sick),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _ToggleButton(
                label: '🎂 Birthday',
                selected: value == LeaveType.birthdayHoliday,
                selectedColor: AppColors.gradientStart,
                onTap: () => onChanged(LeaveType.birthdayHoliday),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _ToggleButton(
                label: '🏦 Bank',
                selected: value == LeaveType.bankHoliday,
                selectedColor: AppColors.bankHoliday,
                onTap: () => onChanged(LeaveType.bankHoliday),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 44,
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.15)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? selectedColor : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? selectedColor : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final VoidCallback onTap;

  const _DateField({
    required this.value,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = value != null
        ? '${value!.day} ${_monthName(value!.month)} ${value!.year}'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formatted ?? hint,
                style: GoogleFonts.sora(
                  fontSize: 14,
                  color:
                      formatted != null ? AppColors.text : AppColors.textMuted,
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  static String _monthName(int month) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month];
  }
}

class _WorkingDaySummary extends StatelessWidget {
  final int calendarDays;
  final int workingDays;

  const _WorkingDaySummary({
    required this.calendarDays,
    required this.workingDays,
  });

  @override
  Widget build(BuildContext context) {
    final String calLabel =
        '$calendarDays calendar ${calendarDays == 1 ? 'day' : 'days'}';
    final String workLabel =
        '$workingDays working ${workingDays == 1 ? 'day' : 'days'}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(
            '$calLabel · ',
            style: GoogleFonts.sora(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          Text(
            workLabel,
            style: GoogleFonts.dmMono(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.annualLeave,
            ),
          ),
          Text(
            ' will be deducted',
            style: GoogleFonts.sora(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const _GradientButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              gradient: onTap != null
                  ? AppColors.gradient
                  : const LinearGradient(
                      colors: [Color(0xFF5c3a8a), Color(0xFF8a3a6b)],
                    ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
