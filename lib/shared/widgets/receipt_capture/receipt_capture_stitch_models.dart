part of 'receipt_capture_models.dart';

enum ReceiptStitchStatus { notNeeded, stitched, fallback }

class ReceiptStitchResult {
  ReceiptStitchResult({
    required this.status,
    required List<String> inputPaths,
    required List<String> ocrSourcePaths,
    this.stitchedPath,
    this.confidence = 0,
    List<int> overlapPixels = const [],
    List<ReceiptStitchPairResult> pairs = const [],
    this.failedPairIndex,
    this.stitchedWidth = 0,
    this.stitchedHeight = 0,
    this.warning = '',
    this.usedManualAdjustment = false,
    this.fallbackReasonCode = '',
  }) : _inputPaths = List<String>.unmodifiable(inputPaths),
       _ocrSourcePaths = List<String>.unmodifiable(ocrSourcePaths),
       _overlapPixels = List<int>.unmodifiable(overlapPixels),
       _pairs = List<ReceiptStitchPairResult>.unmodifiable(pairs);

  ReceiptStitchResult.notNeeded(List<String> paths)
    : this(
        status: ReceiptStitchStatus.notNeeded,
        inputPaths: paths,
        ocrSourcePaths: paths,
      );

  ReceiptStitchResult.fallback({
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
  final List<String> _inputPaths;
  final List<String> _ocrSourcePaths;
  final String? stitchedPath;
  final double confidence;
  final List<int> _overlapPixels;
  final List<ReceiptStitchPairResult> _pairs;
  final int? failedPairIndex;
  final int stitchedWidth;
  final int stitchedHeight;
  final String warning;
  final bool usedManualAdjustment;
  final String fallbackReasonCode;

  List<String> get inputPaths => List<String>.unmodifiable(_inputPaths);
  List<String> get ocrSourcePaths => List<String>.unmodifiable(_ocrSourcePaths);
  List<int> get overlapPixels => List<int>.unmodifiable(_overlapPixels);
  List<ReceiptStitchPairResult> get pairs =>
      List<ReceiptStitchPairResult>.unmodifiable(_pairs);
  bool get didStitch => status == ReceiptStitchStatus.stitched;
  bool get usedFallback => status == ReceiptStitchStatus.fallback;
  bool get hasNoInputPaths => inputPaths.isEmpty;
  bool get hasMultipleSections => inputPaths.length > 1;
  int get pairCount => inputPaths.length <= 1 ? 0 : inputPaths.length - 1;
  int get matchedPairCount =>
      pairs.where((pair) => pair.hasTrustedOverlapEvidence).length;
  int get missingPairCount =>
      (pairCount - matchedPairCount).clamp(0, pairCount);
  bool get allPairsHaveOverlapEvidence =>
      pairCount == 0 || matchedPairCount >= pairCount;
  bool get hasLowConfidenceAutomaticOverlap => pairs.any(
    (pair) =>
        !pair.usedManualAdjustment &&
        pair.overlapPixels > 0 &&
        pair.confidence.isFinite &&
        pair.confidence < .70,
  );
  bool get preservesOriginalSectionSources =>
      usedFallback || status == ReceiptStitchStatus.notNeeded;
  bool get usesDerivedCombinedOcrArtifact => didStitch && stitchedPath != null;
  int get stitchedPixelCount => stitchedWidth * stitchedHeight;
  int get overlapPixelTotal {
    var total = 0;
    for (final pixels in overlapPixels) {
      if (pixels > 0) total += pixels;
    }
    return total;
  }

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

  String get ocrSourceContractCode {
    if (inputPaths.isEmpty) {
      return usedFallback ? 'fallback_no_ocr_sources' : 'no_ocr_sources';
    }
    if (_hasInvalidReceiptArtifactPaths(inputPaths)) {
      return _invalidInputSourceContractCode(usedFallback);
    }
    if (_hasInvalidReceiptArtifactPaths(ocrSourcePaths)) {
      return _invalidOcrSourceContractCode(usedFallback);
    }
    if (_hasDuplicateReceiptArtifactPaths(inputPaths)) {
      return usedFallback
          ? 'fallback_duplicate_input_sources'
          : 'duplicate_input_sources';
    }
    if (_hasDuplicateReceiptArtifactPaths(ocrSourcePaths)) {
      return usedFallback
          ? 'fallback_duplicate_ocr_sources'
          : 'duplicate_ocr_sources';
    }
    if (usedFallback && diagnosticReasonLabel == 'decode_failed') {
      return 'fallback_unreadable_input_source';
    }
    if (usedFallback && diagnosticReasonLabel == 'output_too_large') {
      return 'fallback_derived_stitch_too_large';
    }
    if (usedFallback && diagnosticReasonLabel == 'overlap_confidence_low') {
      return 'fallback_overlap_untrusted_sources';
    }
    if (usedFallback && diagnosticReasonLabel == 'duplicate_section_image') {
      return 'fallback_duplicate_section_image';
    }
    if (didStitch) {
      if (stitchedPath == null || ocrSourcePaths.length != 1) {
        return 'stitched_ocr_source_missing';
      }
      if (_receiptArtifactPathSetContains(inputPaths, stitchedPath!)) {
        return 'stitched_ocr_source_reuses_input_section';
      }
      return _sameReceiptArtifactPath(ocrSourcePaths.single, stitchedPath!)
          ? 'stitched_ocr_source_ready'
          : 'stitched_ocr_source_path_mismatch';
    }
    if (inputPaths.length != ocrSourcePaths.length) {
      return usedFallback
          ? 'fallback_ordered_source_count_mismatch'
          : 'ordered_source_count_mismatch';
    }
    for (var index = 0; index < inputPaths.length; index++) {
      if (!_sameReceiptArtifactPath(inputPaths[index], ocrSourcePaths[index])) {
        return usedFallback
            ? 'fallback_ordered_source_path_mismatch'
            : 'ordered_source_path_mismatch';
      }
    }
    if (usedFallback) return 'fallback_ordered_sources_ready';
    return 'ordered_sources_ready';
  }

  bool get hasValidOcrSourceContract {
    return ocrSourceContractCode == 'stitched_ocr_source_ready' ||
        ocrSourceContractCode == 'fallback_ordered_sources_ready' ||
        ocrSourceContractCode == 'ordered_sources_ready';
  }

  bool get requiresOcrSourceReviewBeforeAssistedRead {
    return !hasValidOcrSourceContract ||
        (usedFallback && hasMultipleSections) ||
        (didStitch && hasMultipleSections && hasLowConfidenceAutomaticOverlap);
  }

  String get assistedReadinessCode {
    if (!hasValidOcrSourceContract) return 'stitch_contract_review_required';
    if (didStitch && hasLowConfidenceAutomaticOverlap) {
      return 'stitched_overlap_review_required';
    }
    if (didStitch && allPairsHaveOverlapEvidence) {
      return 'stitched_overlap_verified_ready';
    }
    if (didStitch) return 'stitched_overlap_review_required';
    if (usedFallback && hasMultipleSections) {
      return 'ordered_sections_stitch_fallback_review_required';
    }
    if (inputPaths.length <= 1) return 'single_section_ready';
    return 'ordered_sections_ready';
  }

  String get failedPairLabel {
    final index = failedPairIndex;
    if (index == null) return '';
    return 'Photo ${index + 1} to ${index + 2}';
  }

  String get reviewFocusPairLabel {
    final failed = failedPairLabel;
    if (failed.isNotEmpty) return failed;
    if (!didStitch || !hasLowConfidenceAutomaticOverlap) return '';
    ReceiptStitchPairResult? lowestConfidencePair;
    for (final pair in pairs) {
      if (pair.usedManualAdjustment ||
          pair.overlapPixels <= 0 ||
          !pair.confidence.isFinite ||
          pair.confidence >= .70) {
        continue;
      }
      if (lowestConfidencePair == null ||
          pair.confidence < lowestConfidencePair.confidence) {
        lowestConfidencePair = pair;
      }
    }
    if (lowestConfidencePair == null) return '';
    final pairIndex = lowestConfidencePair.pairIndex;
    return 'Photo ${pairIndex + 1} to ${pairIndex + 2}';
  }

  String get diagnosticReasonLabel {
    if (!usedFallback) return status.name;
    return _safeStitchFallbackReasonCode(fallbackReasonCode);
  }

  String get userFallbackReasonLabel {
    if (!usedFallback) return '';
    return switch (diagnosticReasonLabel) {
      'decode_failed' => 'One photo could not be read',
      'manual_overlap_unsafe' => 'Manual overlap was outside the safe range',
      'invalid_input_paths' => 'Receipt section path was not trusted',
      'duplicate_input_paths' => 'Duplicate receipt section photo',
      'duplicate_section_image' => 'Duplicate receipt section photo',
      'no_input_paths' => 'No receipt photos available',
      'manual_order_review' => 'Receipt section order needs review',
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
    return '${(_safeStitchUnitInterval(confidence) * 100).round()}% match';
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
    if (inputPaths.isEmpty) return 'No receipt photos to review';
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? '1 photo to review'
            : '${inputPaths.length} receipt sections to review',
      ReceiptStitchStatus.stitched => '1 combined receipt image',
      ReceiptStitchStatus.fallback =>
        '${inputPaths.length} receipt sections top to bottom',
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
    if (inputPaths.isEmpty) {
      return 'Before use: add at least one readable receipt photo.';
    }
    if (inputPaths.length <= 1) {
      return 'Before use: confirm the full receipt is visible and readable.';
    }
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        'Before use: keep receipt sections top to bottom and make sure no middle section is missing.',
      ReceiptStitchStatus.stitched =>
        'Before use: check repeated lines joined correctly and no receipt section is missing.',
      ReceiptStitchStatus.fallback =>
        'Before use: photos stay separate, so verify top-to-bottom order and any missing middle section.',
    };
  }

  String get ocrHandoffSafetyCode {
    if (inputPaths.isEmpty) return 'no_receipt_photo_available';
    if (inputPaths.length <= 1) return 'single_section_review_ready';
    return switch (status) {
      ReceiptStitchStatus.notNeeded => 'ordered_sections_review_ready',
      ReceiptStitchStatus.stitched =>
        allPairsHaveOverlapEvidence && !hasLowConfidenceAutomaticOverlap
            ? 'stitched_overlap_verified'
            : 'stitched_overlap_needs_review',
      ReceiptStitchStatus.fallback =>
        'ordered_sections_after_${diagnosticReasonLabel}_fallback',
    };
  }

  String get ocrHandoffSafetyLabel {
    return switch (ocrHandoffSafetyCode) {
      'single_section_review_ready' =>
        'OCR will read one receipt photo after review.',
      'no_receipt_photo_available' =>
        'OCR needs at least one receipt photo before app-assisted review.',
      'ordered_sections_review_ready' =>
        'OCR will read ordered receipt sections from top to bottom.',
      'stitched_overlap_verified' =>
        'OCR will read one stitched receipt image with verified overlap.',
      'stitched_overlap_needs_review' =>
        'OCR will read one stitched image, but overlap evidence still needs review.',
      _ when usedFallback =>
        'OCR will read ordered sections because stitching was not trusted.',
      _ => 'OCR handoff needs receipt-photo review.',
    };
  }

  Map<String, Object?> get privacySafeOcrHandoffSafety {
    return Map.unmodifiable({
      'stitchOcrHandoffSafetyCode': ocrHandoffSafetyCode,
      'stitchOcrHandoffSafetyLabel': ocrHandoffSafetyLabel,
      'stitchOcrHandoffUsesCombinedImage': didStitch,
      'stitchOcrHandoffUsesOrderedSections':
          usedFallback || status == ReceiptStitchStatus.notNeeded,
      'stitchOcrHandoffSourceCount': ocrSourcePaths.length,
      'stitchOcrSourceContractCode': ocrSourceContractCode,
      'stitchOcrSourceContractReady': hasValidOcrSourceContract,
      'stitchAssistedReadinessCode': assistedReadinessCode,
      'stitchRequiresOcrSourceReviewBeforeAssistedRead':
          requiresOcrSourceReviewBeforeAssistedRead,
      'stitchOcrHandoffChecklistLabel': ocrHandoffChecklistLabel,
      if (reviewFocusPairLabel.isNotEmpty)
        'stitchReviewFocusPairLabel': reviewFocusPairLabel,
    });
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
    if (inputPaths.isEmpty) return 'Add a receipt photo before continuing.';
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? 'Receipt details open from this receipt photo.'
            : 'Receipt details open from these receipt sections in order.',
      ReceiptStitchStatus.stitched =>
        'Receipt details open from one combined receipt image.',
      ReceiptStitchStatus.fallback =>
        'Receipt details open from each section, top to bottom.',
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
    if (inputPaths.isEmpty) return 'No receipt photo ready for review.';
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? 'Single receipt photo ready for review.'
            : 'Receipt sections ready for review.',
      ReceiptStitchStatus.stitched =>
        'Receipt sections combined for app-assisted review.',
      ReceiptStitchStatus.fallback =>
        'Receipt sections will be reviewed separately.',
    };
  }

  String get detailLabel {
    if (inputPaths.isEmpty) {
      return warning.trim().isEmpty
          ? 'No receipt photos were available.'
          : warning;
    }
    return switch (status) {
      ReceiptStitchStatus.notNeeded =>
        inputPaths.length <= 1
            ? 'One photo was prepared for receipt details.'
            : '${inputPaths.length} receipt sections were prepared for receipt details.',
      ReceiptStitchStatus.stitched =>
        '${inputPaths.length} receipt sections became 1 receipt image'
            '${stitchedSizeLabel.isEmpty ? '' : ' ($stitchedSizeLabel)'}. '
            '${usedManualAdjustment ? 'Manual match was used.' : 'Photo match confidence ${(_safeStitchUnitInterval(confidence) * 100).round()}%.'}'
            '${pairDiagnosticsLabel.isEmpty ? '' : ' $pairDiagnosticsLabel'}',
      ReceiptStitchStatus.fallback =>
        warning.trim().isEmpty
            ? '${inputPaths.length} receipt sections stayed separate because stitching confidence was too low.'
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
    final providedFinalStitchPath = stitchedPath?.trim().isNotEmpty == true
        ? stitchedPath
        : null;
    final finalStitchedPath =
        providedFinalStitchPath ??
        (status == ReceiptStitchStatus.stitched && ocrSourcePaths.length == 1
            ? ocrSourcePaths.single
            : this.stitchedPath);
    final finalOcrSourcePaths =
        status == ReceiptStitchStatus.stitched &&
            finalStitchedPath != null &&
            finalStitchedPath.trim().isNotEmpty
        ? [finalStitchedPath]
        : ocrSourcePaths;
    return ReceiptStitchResult(
      status: status,
      inputPaths: inputPaths,
      ocrSourcePaths: finalOcrSourcePaths,
      stitchedPath: finalStitchedPath,
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
