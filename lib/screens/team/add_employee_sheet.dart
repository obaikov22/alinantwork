import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../models/employee.dart';
import '../../providers/employees_provider.dart';
import '../../theme/app_theme.dart';
import 'employee_sheet_widgets.dart';

class AddEmployeeSheet extends ConsumerStatefulWidget {
  const AddEmployeeSheet({super.key});

  @override
  ConsumerState<AddEmployeeSheet> createState() => _AddEmployeeSheetState();
}

class _AddEmployeeSheetState extends ConsumerState<AddEmployeeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _daysController = TextEditingController(text: '28');

  DateTime? _birthday;
  int _selectedColorIndex = 0;
  bool _saving = false;

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
      initialDate: _birthday ?? DateTime(1990, 6, 15),
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
    if (_birthday == null) {
      _showError('Please select a birthday');
      return;
    }

    setState(() => _saving = true);

    final employee = Employee(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      birthday: _birthday!,
      totalAnnualDays: int.tryParse(_daysController.text) ?? 28,
      usedAnnualDays: 0,
      color: kAvatarColors[_selectedColorIndex].toARGB32(),
      createdAt: DateTime.now(),
      role: _roleController.text.trim().isEmpty
          ? null
          : _roleController.text.trim(),
    );

    await ref.read(employeesProvider.notifier).addEmployee(employee);

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
                'Add Team Member',
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
                label: 'Add Member',
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
