import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

const kAvatarColors = [
  Color(0xFFa259ff),
  Color(0xFFff6bbd),
  Color(0xFF3fffa2),
  Color(0xFFff6b8a),
  Color(0xFFff9f45),
  Color(0xFF45d4ff),
];

class SheetFieldLabel extends StatelessWidget {
  final String text;
  final bool muted;
  final bool optional;

  const SheetFieldLabel(this.text,
      {super.key, this.muted = false, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: muted ? AppColors.textMuted : AppColors.text,
            letterSpacing: 0.4,
          ),
        ),
        if (optional)
          Text(
            'optional',
            style: GoogleFonts.sora(
              fontSize: 11,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}

class SheetInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const SheetInputField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      textCapitalization: textCapitalization,
      style: GoogleFonts.sora(fontSize: 14, color: AppColors.text),
      cursorColor: AppColors.gradientStart,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.sora(fontSize: 14, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.gradientStart, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.sickLeave, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AppColors.sickLeave, width: 1.5),
        ),
        errorStyle: GoogleFonts.sora(fontSize: 11, color: AppColors.sickLeave),
      ),
    );
  }
}

class SheetDatePickerField extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onTap;

  const SheetDatePickerField({super.key, required this.value, required this.onTap});

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
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formatted ?? 'Select birthday',
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

  String _monthName(int month) {
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

class SheetColorPicker extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onSelect;

  const SheetColorPicker(
      {super.key, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(kAvatarColors.length, (i) {
        final color = kAvatarColors[i];
        final selected = i == selectedIndex;
        return Padding(
          padding:
              EdgeInsets.only(right: i < kAvatarColors.length - 1 ? 10 : 0),
          child: GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: selected ? 1.0 : 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? Colors.white : color.withValues(alpha: 0.5),
                  width: selected ? 2.5 : 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class SheetGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const SheetGradientButton({
    super.key,
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
