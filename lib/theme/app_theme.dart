import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF0b0c18);
  static const surface = Color(0xFF12142a);
  static const surface2 = Color(0xFF1a1d38);
  static const border = Color(0xFF22264a);
  static const text = Color(0xFFe8eaf6);
  static const textMuted = Color(0xFF6b7194);

  // Gradient
  static const gradientStart = Color(0xFFa259ff);
  static const gradientEnd = Color(0xFFff6bbd);

  // Leave & event colors
  static const annualLeave = Color(0xFF3fffa2);
  static const sickLeave = Color(0xFFff6b8a);
  static const birthday = Color(0xFFff9f45);
  static const bankHoliday = Color(0xFF45d4ff);

  static const gradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark();
    final textTheme = GoogleFonts.soraTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.gradientStart,
        secondary: AppColors.gradientEnd,
        onPrimary: AppColors.text,
        onSecondary: AppColors.text,
        onSurface: AppColors.text,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.sora(
          color: AppColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: AppColors.text),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.gradientStart.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final style = GoogleFonts.sora(fontSize: 11);
          if (states.contains(WidgetState.selected)) {
            return style.copyWith(color: AppColors.gradientStart, fontWeight: FontWeight.w600);
          }
          return style.copyWith(color: AppColors.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.gradientStart);
          }
          return const IconThemeData(color: AppColors.textMuted);
        }),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      dividerColor: AppColors.border,
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    );
  }
}
