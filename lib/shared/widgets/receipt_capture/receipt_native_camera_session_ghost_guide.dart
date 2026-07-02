part of 'receipt_native_camera_contract.dart';

extension ReceiptNativeCameraSessionGhostGuide
    on ReceiptNativeCameraSessionConfig {
  bool get hasPreviousSectionGuide =>
      previousSectionGuidePhotoPath != null &&
      previousSectionGuidePhotoPath!.trim().isNotEmpty;

  String get previousSectionGuideReasonCode =>
      previousSectionReasonCode?.trim().isNotEmpty == true
      ? previousSectionReasonCode!.trim()
      : hasPreviousSectionGuide
      ? 'continue_long_receipt'
      : 'none';

  bool get previousSectionGuideMissingBottomAndTotals =>
      previousSectionGuideReasonCode == 'missing_bottom_edge_and_totals';

  String get previousSectionGhostGuidePolicy {
    if (!hasPreviousSectionGuide) return 'not_requested';
    if (previousSectionGuideMissingBottomAndTotals) {
      return 'bottom_overlap_ghost_at_top_repeat_3_to_5_lines';
    }
    return 'section_overlap_ghost_at_top_repeat_3_to_5_lines';
  }

  String get previousSectionGhostGuideRepeatLineTarget =>
      hasPreviousSectionGuide ? 'repeat_3_to_5_readable_lines' : 'none';

  String get previousSectionGhostGuidePlacement =>
      hasPreviousSectionGuide ? 'top_ghost_slice' : 'none';

  double get previousSectionGhostSourceStartFractionOrDefault =>
      previousSectionGhostSourceStartFraction ??
      (previousSectionGuideMissingBottomAndTotals ? .80 : .78);

  double get previousSectionGhostSourceHeightFractionOrDefault =>
      previousSectionGhostSourceHeightFraction ??
      (previousSectionGuideMissingBottomAndTotals ? .20 : .22);

  double get previousSectionGhostOverlayTopFractionOrDefault =>
      previousSectionGhostOverlayTopFraction ?? 0;

  double get previousSectionGhostOverlayHeightFractionOrDefault =>
      previousSectionGhostOverlayHeightFraction ??
      previousSectionGhostSourceHeightFractionOrDefault;

  double get previousSectionGhostOpacityOrDefault =>
      previousSectionGhostOpacity ??
      (previousSectionGuideMissingBottomAndTotals ? .36 : .32);

  int get previousSectionGhostSlicePercent =>
      (previousSectionGhostSourceHeightFractionOrDefault * 100).round();

  String get previousSectionGhostGuideMatchTarget {
    if (!hasPreviousSectionGuide) return 'none';
    if (previousSectionGuideMissingBottomAndTotals) {
      return 'subtotal_total_and_final_lines';
    }
    return 'repeated_receipt_lines';
  }

  String get previousSectionGuideGuidance {
    final guidance = previousSectionGuidance?.trim();
    if (guidance != null && guidance.isNotEmpty) return guidance;
    if (!hasPreviousSectionGuide) return '';
    if (previousSectionGuideMissingBottomAndTotals) {
      return 'Keep the last readable lines in the top ghost slice, then repeat 3-5 readable lines near the top of the next photo so subtotal, total, and final lines can be matched.';
    }
    return 'Line up the previous receipt section in the top ghost slice and repeat 3-5 readable lines.';
  }
}
