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
