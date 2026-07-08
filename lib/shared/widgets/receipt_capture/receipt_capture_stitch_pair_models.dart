part of 'receipt_capture_models.dart';

class ReceiptStitchPairResult {
  const ReceiptStitchPairResult({
    required this.pairIndex,
    required this.overlapPixels,
    required this.confidence,
    this.usedManualAdjustment = false,
    this.scaleCorrection = 1,
    this.rotationCorrectionDegrees = 0,
    this.horizontalOffsetPixels = 0,
    this.verticalOffsetPixels = 0,
  });

  final int pairIndex;
  final int overlapPixels;
  final double confidence;
  final bool usedManualAdjustment;
  final double scaleCorrection;
  final double rotationCorrectionDegrees;
  final int horizontalOffsetPixels;
  final int verticalOffsetPixels;

  String get pairLabel => 'Photo ${pairIndex + 1} to ${pairIndex + 2}';
  double get _safeConfidence => _safeStitchUnitInterval(confidence);
  double get _safeScaleCorrection =>
      scaleCorrection.isFinite ? scaleCorrection : 1;
  double get _safeRotationCorrectionDegrees =>
      rotationCorrectionDegrees.isFinite ? rotationCorrectionDegrees : 0;
  int get _safeHorizontalOffsetPixels => horizontalOffsetPixels;
  int get _safeVerticalOffsetPixels => verticalOffsetPixels;
  int get _confidencePercent => (_safeConfidence * 100).round();
  bool get hasTrustedOverlapEvidence =>
      usedManualAdjustment || (overlapPixels > 0 && _safeConfidence >= .50);

  String get summaryLabel {
    final match = overlapPixels <= 0
        ? 'no repeated text'
        : 'repeated text found';
    if (usedManualAdjustment) return '$pairLabel: manual match, $match';
    final rotationText = _safeRotationCorrectionDegrees.abs() >= .5
        ? ', straighten ${_safeRotationCorrectionDegrees.toStringAsFixed(1)} deg'
        : '';
    final driftText = _safeHorizontalOffsetPixels.abs() >= 24
        ? ', shifted ${_safeHorizontalOffsetPixels.abs()} px'
        : '';
    final delayedText = _safeVerticalOffsetPixels >= 24
        ? ', delayed ${_safeVerticalOffsetPixels}px'
        : '';
    if ((_safeScaleCorrection - 1).abs() >= .03) {
      return '$pairLabel: $_confidencePercent% match, $match, zoom adjusted$rotationText$driftText$delayedText';
    }
    return '$pairLabel: $_confidencePercent% match, $match$rotationText$driftText$delayedText';
  }

  String get matchEvidenceLabel {
    if (usedManualAdjustment) return 'manual overlap';
    if (overlapPixels <= 0) return '$_confidencePercent% no overlap';
    if ((_safeScaleCorrection - 1).abs() >= .03) {
      return '$_confidencePercent% with zoom fix';
    }
    if (_safeRotationCorrectionDegrees.abs() >= .5) {
      return '$_confidencePercent% with straightening';
    }
    if (_safeHorizontalOffsetPixels.abs() >= 24) {
      return '$_confidencePercent% with drift fix';
    }
    if (_safeVerticalOffsetPixels >= 24) {
      return '$_confidencePercent% with delayed overlap';
    }
    return '$_confidencePercent% overlap';
  }

  String get diagnosticCode {
    if (usedManualAdjustment) return 'manual_overlap';
    if (overlapPixels <= 0) return 'no_repeated_text';
    if ((_safeScaleCorrection - 1).abs() >= .03 &&
        _safeRotationCorrectionDegrees.abs() >= .5) {
      return 'zoom_and_straighten_adjusted';
    }
    if ((_safeScaleCorrection - 1).abs() >= .03) return 'zoom_adjusted';
    if (_safeRotationCorrectionDegrees.abs() >= .5) {
      return 'straighten_adjusted';
    }
    if (_safeHorizontalOffsetPixels.abs() >= 24) return 'drift_adjusted';
    if (_safeVerticalOffsetPixels >= 24) return 'delayed_overlap_adjusted';
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
    if ((_safeScaleCorrection - 1).abs() >= .03) {
      adjustments.add('zoom difference');
    }
    if (_safeRotationCorrectionDegrees.abs() >= .5) {
      adjustments.add('slight tilt');
    }
    if (_safeHorizontalOffsetPixels.abs() >= 24) {
      adjustments.add('sideways drift');
    }
    if (_safeVerticalOffsetPixels >= 24) {
      adjustments.add('delayed overlap');
    }
    if (adjustments.isEmpty) {
      return '$pairLabel matched repeated receipt text.';
    }
    return '$pairLabel matched repeated text after fixing ${adjustments.join(' and ')}.';
  }
}
