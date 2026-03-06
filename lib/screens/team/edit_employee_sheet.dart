import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/employee.dart';
import '../../providers/employees_provider.dart';
import '../../theme/app_theme.dart';
import 'employee_sheet_widgets.dart';

class EditEmployeeSheet extends ConsumerStatefulWidget {
  final Employee employee;

  const EditEmployeeSheet({super.key, required this.employee});

  @override
  ConsumerState<EditEmployeeSheet> createState() => _EditEmployeeSheetState();
}

class _EditEmployeeSheetState extends ConsumerState<EditEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _roleController;
  late final TextEditingController _daysController;

  late DateTime _birthday;
  late int _selectedColorIndex;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _nameController = TextEditingController(text: e.name);
    _roleController = TextEditingController(text: e.role ?? '');
    _daysController =
        TextEditingController(text: e.totalAnnualDays.toString());
    _birthday = e.birthday;
    _selectedColorIndex = _colorIndex(e.color);
  }

  int _colorIndex(int colorValue) {
    for (int i = 0; i < kAvatarColors.length; i++) {
      if (kAvatarColors[i].toARGB32() == colorValue) return i;
    }
    return 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthday() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      helpText: 'Select Birthday',
    );
    if (picked != null) {
      setState(() => _birthday = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final updated = Employee(
      id: widget.employee.id,
      name: _nameController.text.trim(),
      birthday: _birthday,
      totalAnnualDays: int.tryParse(_daysController.text) ?? 28,
      usedAnnualDays: widget.employee.usedAnnualDays,
      color: kAvatarColors[_selectedColorIndex].toARGB32(),
      createdAt: widget.employee.createdAt,
      role: _roleController.text.trim().isEmpty
          ? null
          : _roleController.text.trim(),
    );

    await ref.read(employeesProvider.notifier).updateEmployee(updated);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
              // Title
              Text(
                'Edit Team Member',
                style: GoogleFonts.sora(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              const SheetFieldLabel('Full Name'),
              const SizedBox(height: 6),
              SheetInputField(
                controller: _nameController,
                hint: 'e.g. Sarah Johnson',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Birthday
              const SheetFieldLabel('Birthday'),
              const SizedBox(height: 6),
              SheetDatePickerField(
                value: _birthday,
                onTap: _pickBirthday,
              ),
              const SizedBox(height: 16),

              // Annual Days
              const SheetFieldLabel('Annual Leave Days'),
              const SizedBox(height: 6),
              SheetInputField(
                controller: _daysController,
                hint: '28',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n < 1 || n > 365) {
                    return 'Enter a valid number (1–365)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Role
              const SheetFieldLabel('Role  ', muted: true, optional: true),
              const SizedBox(height: 6),
              SheetInputField(
                controller: _roleController,
                hint: 'e.g. Cleaner',
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              // Color picker
              const SheetFieldLabel('Avatar Color'),
              const SizedBox(height: 10),
              SheetColorPicker(
                selectedIndex: _selectedColorIndex,
                onSelect: (i) => setState(() => _selectedColorIndex = i),
              ),
              const SizedBox(height: 28),

              // Submit button
              SheetGradientButton(
                label: 'Save Changes',
                loading: _saving,
                onTap: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
