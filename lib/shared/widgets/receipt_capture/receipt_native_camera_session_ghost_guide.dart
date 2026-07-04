part of 'receipt_native_camera_contract.dart';

extension ReceiptNativeCameraSessionGhostGuide
    on ReceiptNativeCameraSessionConfig {
  bool get hasPreviousSectionGuide =>
      previousSectionGuidePhotoPath != null &&
      previousSectionGuidePhotoPath!.trim().isNotEmpty;

  String get previousSectionGuideReasonCode =>
      previousSectionReasonCode?.trim().isNotEmpty == true
      ? previousSectionReasonCode!.trim().toLowerCase()
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

  double get previousSectionGhostSourceStartFractionOrDefault {
    final fallback = previousSectionGuideMissingBottomAndTotals ? .80 : .78;
    return _boundedGhostGuideValue(
      previousSectionGhostSourceStartFraction,
      fallback: fallback,
      min: .65,
      max: .92,
    );
  }

  double get previousSectionGhostSourceHeightFractionOrDefault {
    final fallback = previousSectionGuideMissingBottomAndTotals ? .20 : .22;
    return _boundedGhostGuideValue(
      previousSectionGhostSourceHeightFraction,
      fallback: fallback,
      min: .12,
      max: .35,
    );
  }

  double get previousSectionGhostOverlayTopFractionOrDefault =>
      _boundedGhostGuideValue(
        previousSectionGhostOverlayTopFraction,
        fallback: 0,
        min: 0,
        max: .30,
      );

  double get previousSectionGhostOverlayHeightFractionOrDefault =>
      _boundedGhostGuideValue(
        previousSectionGhostOverlayHeightFraction,
        fallback: previousSectionGhostSourceHeightFractionOrDefault,
        min: .12,
        max: .35,
      );

  double get previousSectionGhostOpacityOrDefault {
    final fallback = previousSectionGuideMissingBottomAndTotals ? .36 : .32;
    return _boundedGhostGuideValue(
      previousSectionGhostOpacity,
      fallback: fallback,
      min: .18,
      max: .62,
    );
  }

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

double _boundedGhostGuideValue(
  double? value, {
  required double fallback,
  required double min,
  required double max,
}) {
  final boundedValue = value != null && value.isFinite ? value : fallback;
  if (boundedValue < min) return min;
  if (boundedValue > max) return max;
  return boundedValue;
}
