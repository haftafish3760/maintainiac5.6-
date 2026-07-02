part of 'receipt_capture_models.dart';

class ReceiptStitchPairResult {
  const ReceiptStitchPairResult({
    required this.pairIndex,
    required this.overlapPixels,
    required this.confidence,
    this.usedManualAdjustment = false,
    this.scaleCorrection = 1,
    this.rotationCorrectionDegrees = 0,
  });

  final int pairIndex;
  final int overlapPixels;
  final double confidence;
  final bool usedManualAdjustment;
  final double scaleCorrection;
  final double rotationCorrectionDegrees;

  String get pairLabel => 'Photo ${pairIndex + 1} to ${pairIndex + 2}';
  bool get hasTrustedOverlapEvidence =>
      usedManualAdjustment || (overlapPixels > 0 && confidence >= .50);

  String get summaryLabel {
    final match = overlapPixels <= 0
        ? 'no repeated text'
        : 'repeated text found';
    if (usedManualAdjustment) return '$pairLabel: manual match, $match';
    final rotationText = rotationCorrectionDegrees.abs() >= .5
        ? ', straighten ${rotationCorrectionDegrees.toStringAsFixed(1)} deg'
        : '';
    if ((scaleCorrection - 1).abs() >= .03) {
      return '$pairLabel: ${(confidence * 100).round()}% match, $match, zoom adjusted$rotationText';
    }
    return '$pairLabel: ${(confidence * 100).round()}% match, $match$rotationText';
  }

  String get matchEvidenceLabel {
    if (usedManualAdjustment) return 'manual overlap';
    if (overlapPixels <= 0) return '${(confidence * 100).round()}% no overlap';
    if ((scaleCorrection - 1).abs() >= .03) {
      return '${(confidence * 100).round()}% with zoom fix';
    }
    if (rotationCorrectionDegrees.abs() >= .5) {
      return '${(confidence * 100).round()}% with straightening';
    }
    return '${(confidence * 100).round()}% overlap';
  }

  String get diagnosticCode {
    if (usedManualAdjustment) return 'manual_overlap';
    if (overlapPixels <= 0) return 'no_repeated_text';
    if ((scaleCorrection - 1).abs() >= .03 &&
        rotationCorrectionDegrees.abs() >= .5) {
      return 'zoom_and_straighten_adjusted';
    }
    if ((scaleCorrection - 1).abs() >= .03) return 'zoom_adjusted';
    if (rotationCorrectionDegrees.abs() >= .5) return 'straighten_adjusted';
    return 'overlap_matched';
  }

  String get userCheckLabel {
    if (usedManualAdjustment) {
      return '$pairLabel used your manual overlap. Check repeated lines once.';
    }
    if (overlapPixels <= 0) {
      return '$pairLabel did not show repeated receipt text.';
    }
    final adjustments = <String>[];
    if ((scaleCorrection - 1).abs() >= .03) {
      adjustments.add('zoom difference');
    }
    if (rotationCorrectionDegrees.abs() >= .5) {
      adjustments.add('slight tilt');
    }
    if (adjustments.isEmpty) {
      return '$pairLabel matched repeated receipt text.';
    }
    return '$pairLabel matched repeated text after fixing ${adjustments.join(' and ')}.';
  }
}
