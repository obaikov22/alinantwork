import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/eula_service.dart';
import '../../theme/app_theme.dart';

class EulaScreen extends StatefulWidget {
  const EulaScreen({super.key});

  @override
  State<EulaScreen> createState() => _EulaScreenState();
}

class _EulaScreenState extends State<EulaScreen> {
  bool _agreed = false;

  Future<void> _accept() async {
    await EulaService.instance.accept();
    if (mounted) context.go('/login');
  }

  void _decline() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Agreement Required',
          style: GoogleFonts.sora(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          'You must accept the agreement to use this app.',
          style: GoogleFonts.sora(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'OK',
              style: GoogleFonts.sora(
                color: AppColors.gradientStart,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              // ── App name ──────────────────────────────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.gradient.createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      'Alina',
                      style: GoogleFonts.sora(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    'NTWork',
                    style: GoogleFonts.sora(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'End User License Agreement',
                style: GoogleFonts.sora(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // ── Scrollable EULA text ──────────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _eulaText,
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: AppColors.text,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Checkbox ──────────────────────────────────────────────────
              GestureDetector(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreed,
                        onChanged: (v) =>
                            setState(() => _agreed = v ?? false),
                        activeColor: AppColors.gradientStart,
                        checkColor: Colors.white,
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'I have read and agree to the Terms and License Agreement',
                        style: GoogleFonts.sora(
                          fontSize: 13,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Accept button ─────────────────────────────────────────────
              GestureDetector(
                onTap: _agreed ? _accept : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: _agreed ? AppColors.gradient : null,
                    color: _agreed ? null : AppColors.surface2,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Accept',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _agreed
                          ? Colors.white
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Decline button ────────────────────────────────────────────
              GestureDetector(
                onTap: _decline,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Decline',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

const _eulaText = '''AlinaNTWork — End User License Agreement (EULA)
Version 1.0

IMPORTANT: Please read this agreement carefully before using the application.

1. Grant of Licence
The Developer (Oleg Baikov) grants you a limited, non-exclusive, non-transferable licence to use AlinaNTWork solely for your internal team management purposes.

2. Intellectual Property
The application and all its contents are the exclusive intellectual property of Oleg Baikov, protected by copyright law.

3. Restrictions
You may not: copy, distribute or sell the application; reverse engineer the source code; transfer access to third parties; share login credentials outside your authorised team.

4. Data & Privacy
Data is stored via Google Firebase. By using this app you confirm that all team members have been informed of this. The Developer does not sell user data to third parties.

5. Disclaimer
The application is provided "as is" without warranty of any kind. The Developer is not liable for data loss or business interruption.

6. Termination
The Developer may revoke this licence at any time if these terms are breached.

7. Governing Law
This agreement is governed by the laws of England and Wales.

By tapping "Accept" you confirm you have read and agree to these terms.
© 2025 Oleg Baikov. All rights reserved.''';
