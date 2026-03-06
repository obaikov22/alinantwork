import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

class UpdateBanner extends StatefulWidget {
  final Widget child;
  const UpdateBanner({super.key, required this.child});

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner> {
  UpdateInfo? _update;
  bool _dismissed = false;
  double? _progress; // null = not downloading, 0.0–1.0 while downloading

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), _checkForUpdate);
  }

  Future<void> _checkForUpdate() async {
    final update = await UpdateService.checkForUpdate();
    if (mounted && update != null) {
      setState(() => _update = update);
    }
  }

  Future<void> _startDownload() async {
    setState(() => _progress = 0.0);
    await UpdateService.downloadAndInstall(
      _update!.downloadUrl,
      (p) {
        if (mounted) setState(() => _progress = p);
      },
    );
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    final showBanner = _update != null && !_dismissed;

    return Column(
      children: [
        Expanded(child: widget.child),
        if (showBanner) _BannerWidget(
          update: _update!,
          progress: _progress,
          onDismiss: () => setState(() => _dismissed = true),
          onUpdate: _progress == null ? _startDownload : null,
        ),
      ],
    );
  }
}

class _BannerWidget extends StatelessWidget {
  final UpdateInfo update;
  final double? progress;
  final VoidCallback onDismiss;
  final VoidCallback? onUpdate;

  const _BannerWidget({
    required this.update,
    required this.progress,
    required this.onDismiss,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
          left: BorderSide(color: AppColors.gradientStart, width: 3),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '⬆ Update available: v${update.version}',
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                if (progress != null) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.surface2,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.gradientStart,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (progress == null) ...[
            GestureDetector(
              onTap: onUpdate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.gradient,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Update',
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
