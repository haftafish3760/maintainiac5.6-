part of 'receipt_photo_review_screen.dart';

class _NativeCaptureReviewWarning {
  const _NativeCaptureReviewWarning({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
    required this.message,
    required this.primaryActionLabel,
    this.isCritical = false,
    this.prefersAddSection = false,
  });

  factory _NativeCaptureReviewWarning.fromModel(
    ReceiptNativeSavedPhotoReviewWarning warning,
  ) {
    final icon = switch (warning.code) {
      'saved_photo_soft_blur_risk' => Icons.motion_photos_pause_rounded,
      'saved_photo_glare_risk' => Icons.flare_rounded,
      'saved_photo_check_sharpness' => Icons.zoom_in_rounded,
      _ => Icons.light_mode_rounded,
    };
    final color = switch (warning.severity) {
      ReceiptNativeSavedPhotoWarningSeverity.critical => const Color(
        0xFFFFB020,
      ),
      ReceiptNativeSavedPhotoWarningSeverity.warning => const Color(0xFFFFD166),
      ReceiptNativeSavedPhotoWarningSeverity.notice => const Color(0xFF8EF6A4),
    };
    return _NativeCaptureReviewWarning(
      icon: icon,
      color: color,
      title: warning.title,
      detail: [
        warning.guidance,
        warning.parserImpactGuidance,
      ].where((line) => line.trim().isNotEmpty).join(' '),
      isCritical: warning.isCritical,
      prefersAddSection: warning.prefersAddSection,
      message: warning.message,
      primaryActionLabel: warning.primaryActionLabel,
    );
  }

  final IconData icon;
  final Color color;
  final String title;
  final String detail;
  final String message;
  final String primaryActionLabel;
  final bool isCritical;
  final bool prefersAddSection;

  Color get panelColor {
    if (isCritical) return const Color(0xFF2B1F11);
    if (color == const Color(0xFFFFD166)) return const Color(0xFF2B2711);
    return const Color(0xFF1D261B);
  }
}

class _ReceiptPhotoQualityRecoveryStrip extends StatelessWidget {
  const _ReceiptPhotoQualityRecoveryStrip({
    required this.quality,
    required this.nativeWarning,
    required this.compact,
    required this.hasCriticalQualityIssue,
    required this.coverageDecision,
  });

  final ReceiptPhotoQualityCheck? quality;
  final _NativeCaptureReviewWarning? nativeWarning;
  final bool compact;
  final bool hasCriticalQualityIssue;
  final ReceiptPhotoCoverageDecision coverageDecision;

  @override
  Widget build(BuildContext context) {
    final strings = MaintaniacLocalizations.of(context);
    final photoQuality = quality;
    final nativeCaptureWarning = nativeWarning;
    final title = nativeCaptureWarning != null
        ? nativeCaptureWarning.title
        : hasCriticalQualityIssue
        ? strings.retakeRecommended
        : coverageDecision.shouldPromptForMorePhotos
        ? coverageDecision.title
        : photoQuality?.nextReviewActionLabel ?? strings.checkPhotoBeforeUse;
    final detail = nativeCaptureWarning != null
        ? nativeCaptureWarning.detail
        : coverageDecision.shouldPromptForMorePhotos
        ? coverageDecision.guidance
        : photoQuality == null
        ? coverageDecision.guidance
        : '${photoQuality.reviewGuidance} ${photoQuality.reviewScoreMeaningLabel}';
    final accentColor =
        nativeCaptureWarning?.color ??
        (hasCriticalQualityIssue
            ? const Color(0xFFFFB020)
            : const Color(0xFF8EF6A4));
    final panelColor =
        nativeCaptureWarning?.panelColor ??
        (hasCriticalQualityIssue
            ? const Color(0xFF2B1F11)
            : const Color(0xFF1D261B));
    final icon =
        nativeCaptureWarning?.icon ??
        (hasCriticalQualityIssue
            ? Icons.warning_amber_rounded
            : Icons.info_outline_rounded);
    final shouldEmphasizeAddSection =
        coverageDecision.shouldEmphasizeAddPhoto ||
        nativeCaptureWarning?.prefersAddSection == true;
    // Preview already has one persistent action row. Repeating Crop, Retake,
    // and Add Photo inside a warning card steals receipt pixels and gives the
    // user two competing sets of actions. Keep the warning concise and let
    // the primary row own every action.
    final recoveryHint = shouldEmphasizeAddSection
        ? 'Use Add photo below if a receipt section is missing.'
        : 'Use Crop, Retake, or Add photo below if needed.';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accentColor, width: .9),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, compact ? 5 : 7, 8, compact ? 5 : 7),
        child: Row(
          children: [
            Icon(icon, color: accentColor, size: 18),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFE8ECEE),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  if (!compact)
                    Text(
                      '$detail $recoveryHint',
                      style: const TextStyle(
                        color: Color(0xFFC7D0D4),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                        letterSpacing: 0,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
