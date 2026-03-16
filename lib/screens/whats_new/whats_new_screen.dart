import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/whats_new_service.dart';
import '../../theme/app_theme.dart';

class WhatsNewScreen extends StatelessWidget {
  const WhatsNewScreen({super.key});

  Future<void> _gotIt(BuildContext context) async {
    await WhatsNewService.instance.markSeen();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final version = WhatsNewService.instance.currentVersion;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // ── Title ─────────────────────────────────────────────────────
              Text(
                "What's New",
                style: GoogleFonts.sora(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Version $version',
                style: GoogleFonts.dmMono(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 32),

              // ── Changelog list ────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: const [
                      _ChangeItem(
                        emoji: '🔢',
                        title: 'Leave balance fix',
                        description:
                            'Fixed an issue where days were counted twice when a bank holiday or birthday holiday fell within an annual leave period. The balance now shows the correct number of unique days used.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Got it button ─────────────────────────────────────────────
              GestureDetector(
                onTap: () => _gotIt(context),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Got it',
                    style: GoogleFonts.sora(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

class _ChangeItem extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;

  const _ChangeItem({
    required this.emoji,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
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
