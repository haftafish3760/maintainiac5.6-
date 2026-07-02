part of 'receipt_capture_models.dart';

enum ReceiptStitchStatus { notNeeded, stitched, fallback }

class ReceiptStitchResult {
  const ReceiptStitchResult({
    required this.status,
    required this.inputPaths,
    required this.ocrSourcePaths,
    this.stitchedPath,
    this.confidence = 0,
    this.overlapPixels = const [],
    this.pairs = const [],
    this.failedPairIndex,
    this.stitchedWidth = 0,
    this.stitchedHeight = 0,
    this.warning = '',
    this.usedManualAdjustment = false,
    this.fallbackReasonCode = '',
  });

  const ReceiptStitchResult.notNeeded(List<String> paths)
    : this(
        status: ReceiptStitchStatus.notNeeded,
        inputPaths: paths,
        ocrSourcePaths: paths,
      );

  const ReceiptStitchResult.fallback({
    required List<String> inputPaths,
    required String warning,
    String fallbackReasonCode = 'unknown',
    double confidence = 0,
    int? failedPairIndex,
    List<ReceiptStitchPairResult> pairs = const [],
    int stitchedWidth = 0,
    int stitchedHeight = 0,
  }) : this(
         status: ReceiptStitchStatus.fallback,
         inputPaths: inputPaths,
         ocrSourcePaths: inputPaths,
         warning: warning,
         confidence: confidence,
         failedPairIndex: failedPairIndex,
         pairs: pairs,
         stitchedWidth: stitchedWidth,
         stitchedHeight: stitchedHeight,
         fallbackReasonCode: fallbackReasonCode,
       );

  final ReceiptStitchStatus status;
  final List<String> inputPaths;
  final List<String> ocrSourcePaths;
  final String? stitchedPath;
  final double confidence;
  final List<int> overlapPixels;
  final List<ReceiptStitchPairResult> pairs;
  final int? failedPairIndex;
  final int stitchedWidth;
  final int stitchedHeight;
  final String warning;
  final bool usedManualAdjustment;
  final String fallbackReasonCode;

  bool get didStitch => status == ReceiptStitchStatus.stitched;
  bool get usedFallback => status == ReceiptStitchStatus.fallback;
  bool get hasMultipleSections => inputPaths.length > 1;
  int get pairCount => inputPaths.length <= 1 ? 0 : inputPaths.length - 1;
  int get matchedPairCount =>
      pairs.where((pair) => pair.hasTrustedOverlapEvidence).length;
  int get missingPairCount =>
      (pairCount - matchedPairCount).clamp(0, pairCount);
  bool get allPairsHaveOverlapEvidence =>
      pairCount == 0 || matchedPairCount >= pairCount;
  bool get preservesOriginalSectionSources =>
      usedFallback || status == ReceiptStitchStatus.notNeeded;
  bool get usesDerivedCombinedOcrArtifact => didStitch && stitchedPath != null;
  int get stitchedPixelCount => stitchedWidth * stitchedHeight;
  String get stitchedSizeLabel => stitchedWidth > 0 && stitchedHeight > 0
      ? '$stitchedWidth x $stitchedHeight'
      : '';

  String get overlapCoverageCode {
    if (pairCount == 0) return 'single_section_no_overlap_needed';
    if (usedFallback) {
      final failed = failedPairIndex;
      if (failed != null) return 'fallback_pair_${failed + 1}_to_${failed + 2}';
      return 'fallback_overlap_not_trusted';
    }
    if (allPairsHaveOverlapEvidence) return 'all_pairs_have_overlap_evidence';
    return 'missing_overlap_evidence';
  }

  String get sourcePreservationCode {
    if (usesDerivedCombinedOcrArtifact) {
      return 'original_sections_preserved_derived_stitched_ocr_artifact';
    }
    if (preservesOriginalSectionSources) {
      return 'original_sections_preserved_ordered_ocr_sources';
    }
    return 'original_section_source_policy_unknown';
  }

  String get failedPairLabel {
    final index = failedPairIndex;
    if (index == null) return '';
    return 'Photo ${index + 1} to ${index + 2}';
  }

  String get diagnosticReasonLabel {
    if (!usedFallback) return status.name;
    return fallbackReasonCode.trim().isEmpty ? 'unknown' : fallbackReasonCode;
  }

  String get userFallbackReasonLabel {
    if (!usedFallback) return '';
    return switch (diagnosticReasonLabel) {
      'decode_failed' => 'One photo could not be read',
      'manual_overlap_unsafe' => 'Manual overlap was outside the safe range',
      'overlap_confidence_low' => 'Overlap was not clear enough',
      'output_too_large' => 'Receipt is too long for this device',
      'stitch_exception' => 'Stitching hit a safe fallback',
      _ => 'Stitching was not trusted',
    };
  }

  String get matchConfidenceLabel {
    if (!hasMultipleSections || status == ReceiptStitchStatus.notNeeded) {
      return 'Match not needed';
    }
    if (usedManualAdjustment) return 'Manual match';
    return '${(confidence * 100).round()}% match';
  }

  String get pairDiagnosticsLabel {
    if (pairs.isEmpty) return '';
    return pairs.map((pair) => pair.userCheckLabel).join(' ');
  }

  String get diagnosticCodeLabel {
    if (usedFallback) return diagnosticReasonLabel;
    if (pairs.isEmpty) return status.name;
    return pairs.map((pair) => pair.diagnosticCode).join(',');
  }

  String get reviewPathLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? '1 photo to review'
            : '${inputPaths.length} photos to review',
      ReceiptStitchStatus.stitched => '1 combined receipt image',
      ReceiptStitchStatus.fallback =>
        '${inputPaths.length} photos top to bottom',
    };
  }

  String get reviewDecisionLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded => reviewPathLabel,
      ReceiptStitchStatus.stitched => '$reviewPathLabel, $matchConfidenceLabel',
      ReceiptStitchStatus.fallback => '$reviewPathLabel, $matchConfidenceLabel',
    };
  }

  String get ocrHandoffChecklistLabel {
    if (inputPaths.length <= 1) {
      return 'Before Next: confirm the full receipt is visible and readable.';
    }
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        'Before Next: keep receipt sections top to bottom and make sure no middle section is missing.',
      ReceiptStitchStatus.stitched =>
        'Before Next: check repeated lines joined correctly and no receipt section is missing.',
      ReceiptStitchStatus.fallback =>
        'Before Next: photos stay separate, so verify top-to-bottom order and any missing middle section.',
    };
  }

  String get overlapExpectationLabel {
    if (inputPaths.length <= 1) return 'Full receipt in one photo';
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        'Repeat 3-5 readable lines between sections',
      ReceiptStitchStatus.stitched =>
        usedManualAdjustment
            ? 'Manual overlap accepted'
            : 'Repeated lines matched',
      ReceiptStitchStatus.fallback =>
        'Stitch skipped; order still controls OCR review',
    };
  }

  String get overlapCoverageLabel {
    if (pairCount == 0) return 'No overlap needed for a single receipt photo.';
    if (usedFallback) {
      final failed = failedPairLabel.isEmpty
          ? 'one photo pair'
          : failedPairLabel;
      return '$failed did not have trusted overlap; OCR keeps sections ordered.';
    }
    if (allPairsHaveOverlapEvidence) {
      return 'Every adjacent receipt section has overlap evidence.';
    }
    return 'One or more receipt section overlaps still need review.';
  }

  String get nextStepLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? 'Next reviews this receipt photo.'
            : 'Next reviews these receipt sections in order.',
      ReceiptStitchStatus.stitched =>
        'Next reviews one combined receipt image.',
      ReceiptStitchStatus.fallback =>
        'Next opens receipt details from each section, top to bottom.',
    };
  }

  String get stitchSafetyLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded => 'No stitch needed',
      ReceiptStitchStatus.stitched =>
        usedManualAdjustment
            ? 'Manual match accepted'
            : 'Automatic match accepted',
      ReceiptStitchStatus.fallback => 'Stitch not trusted',
    };
  }

  String get summaryLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? 'Single receipt photo ready for review.'
            : 'Receipt photos ready for review.',
      ReceiptStitchStatus.stitched =>
        'Receipt photos combined for app-assisted review.',
      ReceiptStitchStatus.fallback =>
        'Receipt photos will be reviewed separately.',
    };
  }

  String get detailLabel {
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? 'One photo was prepared for receipt details.'
            : '${inputPaths.length} photos were prepared for receipt details.',
      ReceiptStitchStatus.stitched =>
        '${inputPaths.length} photos became 1 receipt image'
            '${stitchedSizeLabel.isEmpty ? '' : ' ($stitchedSizeLabel)'}. '
            '${usedManualAdjustment ? 'Manual match was used.' : 'Photo match confidence ${(confidence * 100).round()}%.'}'
            '${pairDiagnosticsLabel.isEmpty ? '' : ' $pairDiagnosticsLabel'}',
      ReceiptStitchStatus.fallback =>
        warning.trim().isEmpty
            ? '${inputPaths.length} photos stayed separate because stitching confidence was too low.'
            : failedPairLabel.isEmpty
            ? warning
            : '$failedPairLabel: $warning',
    };
  }

  ReceiptStitchResult copyForFinalOcr({
    required List<String> inputPaths,
    required List<String> ocrSourcePaths,
    String? stitchedPath,
  }) {
    return ReceiptStitchResult(
      status: status,
      inputPaths: inputPaths,
      ocrSourcePaths: ocrSourcePaths,
      stitchedPath: stitchedPath ?? this.stitchedPath,
      confidence: confidence,
      overlapPixels: overlapPixels,
      pairs: pairs,
      failedPairIndex: failedPairIndex,
      stitchedWidth: stitchedWidth,
      stitchedHeight: stitchedHeight,
      warning: warning,
      usedManualAdjustment: usedManualAdjustment,
      fallbackReasonCode: fallbackReasonCode,
    );
  }
}
