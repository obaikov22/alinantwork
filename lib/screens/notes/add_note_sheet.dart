import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/employee.dart';
import '../../models/note_record.dart';
import '../../providers/employees_provider.dart';
import '../../providers/note_records_provider.dart';
import '../../theme/app_theme.dart';

class AddNoteSheet extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const AddNoteSheet({super.key, required this.selectedDate});

  @override
  ConsumerState<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends ConsumerState<AddNoteSheet> {
  NoteType _noteType = NoteType.general;
  String? _selectedEmployeeId;
  final _textController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showError('Please enter a note');
      return;
    }
    if (_noteType == NoteType.employee && _selectedEmployeeId == null) {
      _showError('Please select an employee');
      return;
    }

    setState(() => _saving = true);

    final note = NoteRecord(
      id: const Uuid().v4(),
      date: widget.selectedDate,
      type: _noteType,
      text: text,
      employeeId: _noteType == NoteType.employee ? _selectedEmployeeId : null,
      createdAt: DateTime.now(),
    );

    await ref.read(noteRecordsProvider.notifier).addNote(note);
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateLabel = DateFormat('d MMM').format(widget.selectedDate);

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
              'Add Note — $dateLabel',
              style: GoogleFonts.sora(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 24),

            // Note type toggle
            _NoteTypeToggle(
              value: _noteType,
              onChanged: (type) => setState(() {
                _noteType = type;
                if (type == NoteType.general) _selectedEmployeeId = null;
              }),
            ),
            const SizedBox(height: 16),

            // Employee dropdown (employee type only)
            if (_noteType == NoteType.employee) ...[
              _FieldLabel('Employee'),
              const SizedBox(height: 6),
              _EmployeeDropdown(
                employees: employees,
                value: _selectedEmployeeId,
                onChanged: (id) => setState(() => _selectedEmployeeId = id),
              ),
              const SizedBox(height: 16),
            ],

            // Note text
            _FieldLabel('Note'),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _textController,
                maxLines: null,
                minLines: 3,
                style: GoogleFonts.sora(fontSize: 14, color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'Write your note here...',
                  hintStyle: GoogleFonts.sora(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Save button
            _GradientButton(
              label: 'Save Note',
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

class _NoteTypeToggle extends StatelessWidget {
  final NoteType value;
  final void Function(NoteType) onChanged;

  const _NoteTypeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            label: '📌 General',
            selected: value == NoteType.general,
            selectedColor: AppColors.gradientStart,
            onTap: () => onChanged(NoteType.general),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToggleButton(
            label: '👤 Employee',
            selected: value == NoteType.employee,
            selectedColor: AppColors.gradientEnd,
            onTap: () => onChanged(NoteType.employee),
          ),
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
        icon: const Icon(Icons.expand_more, color: AppColors.textMuted, size: 20),
        onChanged: onChanged,
        items: employees
            .map(
              (emp) => DropdownMenuItem<String>(
                value: emp.id,
                child: Text(
                  emp.name,
                  style: GoogleFonts.sora(fontSize: 14, color: AppColors.text),
                ),
              ),
            )
            .toList(),
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
