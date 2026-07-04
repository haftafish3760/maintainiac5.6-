part of '../../receipts/receipt_ocr_contract.dart';

int _countReceiptTextLines(String text) {
  return text
      .split(RegExp(r'\r?\n'))
      .where((line) => line.trim().isNotEmpty)
      .length;
}

Map<ReceiptOcrWarningKind, int> _warningKindCounts(
  List<ReceiptOcrWarning> warnings,
) {
  final counts = <ReceiptOcrWarningKind, int>{};
  for (final warning in warnings) {
    counts.update(warning.kind, (count) => count + 1, ifAbsent: () => 1);
  }
  return counts;
}

Map<String, int> _parserTaskCountsWithWarnings(
  Map<String, int> base,
  List<ReceiptOcrWarning> warnings,
) {
  final counts = <String, int>{...base};
  void add(String key) {
    counts[key] = (counts[key] ?? 0) + 1;
  }

  for (final warning in warnings) {
    switch (warning.kind) {
      case ReceiptOcrWarningKind.duplicateText:
        add('long_receipt_duplicate_text');
      case ReceiptOcrWarningKind.probableOverlap:
        add('long_receipt_probable_overlap');
      case ReceiptOcrWarningKind.sectionGap:
        add('long_receipt_section_gap');
      case ReceiptOcrWarningKind.noReadableText:
        add('ocr_no_readable_text');
      case ReceiptOcrWarningKind.photoQuality:
        final lower = warning.message.toLowerCase();
        if (lower.contains('tiny') ||
            lower.contains('text is too small') ||
            lower.contains('squeezed') ||
            lower.contains('zoom in')) {
          add('photo_tiny_text_review');
        } else if (lower.contains('small proof') ||
            lower.contains('proof copy is small')) {
          add('photo_small_proof_review');
        } else {
          add('photo_quality_review');
        }
      case ReceiptOcrWarningKind.photoReadFailure:
        add('photo_read_failed');
      case ReceiptOcrWarningKind.noSource:
      case ReceiptOcrWarningKind.sourceSkipped:
      case ReceiptOcrWarningKind.pdfSafety:
      case ReceiptOcrWarningKind.pdfTooLarge:
      case ReceiptOcrWarningKind.pdfUnreadable:
      case ReceiptOcrWarningKind.pluginUnavailable:
      case ReceiptOcrWarningKind.pdfReadFailure:
      case ReceiptOcrWarningKind.unknown:
        break;
    }
  }
  return Map.unmodifiable(counts);
}

Map<String, int> _parserTaskCountsWithReceiptCoverage(
  Map<String, int> base,
  ReceiptOcrResult result,
) {
  final counts = <String, int>{...base};
  void add(String key) {
    counts[key] = (counts[key] ?? 0) + 1;
  }

  final qualityRisks = result.sourceHandoffSummary.photoQualityRiskCounts;
  if ((qualityRisks['ocr_source_quality_action_retake_recommended_continue_allowed'] ??
          0) >
      0) {
    add('photo_retake_recommended_review');
  }
  if ((qualityRisks['ocr_source_quality_action_crop_or_retake_then_next'] ??
          0) >
      0) {
    add('photo_crop_or_retake_review');
  }
  if ((qualityRisks['ocr_source_quality_action_check_readability_or_add_closer_photo'] ??
          0) >
      0) {
    add('photo_readability_or_closer_review');
  }
  if ((qualityRisks['ocr_source_quality_family_retake'] ?? 0) > 0) {
    add('photo_quality_retake_family_review');
  }
  if ((qualityRisks['ocr_source_quality_family_review'] ?? 0) > 0) {
    add('photo_quality_review_family');
  }
  if ((qualityRisks['ocr_source_saved_photo_darker_than_preview'] ?? 0) > 0 ||
      (qualityRisks['ocr_source_saved_photo_brightness_assist_failed_dark'] ??
              0) >
          0 ||
      (qualityRisks['ocr_source_saved_photo_brightness_assist_still_dim'] ??
              0) >
          0 ||
      (qualityRisks['ocr_source_saved_photo_dimmer_than_preview'] ?? 0) > 0 ||
      (qualityRisks['ocr_source_action_retake_with_more_light'] ?? 0) > 0 ||
      (qualityRisks['ocr_source_action_turn_on_light_or_retake'] ?? 0) > 0 ||
      (qualityRisks['ocr_source_action_check_text_or_add_light'] ?? 0) > 0 ||
      (qualityRisks['ocr_source_action_review_or_add_light'] ?? 0) > 0 ||
      (qualityRisks['photo_quality_photo_is_too_dark'] ?? 0) > 0 ||
      (qualityRisks['photo_quality_photo_is_darker_than_ideal_for_receipt_assistance'] ??
              0) >
          0) {
    add('photo_saved_dark_or_exposure_review');
  }
  if ((qualityRisks['ocr_source_saved_photo_soft_blur_risk'] ?? 0) > 0 ||
      (qualityRisks['ocr_source_action_retake_hold_steady'] ?? 0) > 0 ||
      (qualityRisks['photo_quality_photo_looks_blurry'] ?? 0) > 0) {
    add('photo_saved_soft_blur_review');
  }
  if ((qualityRisks['ocr_source_saved_photo_brighter_than_preview'] ?? 0) > 0 ||
      (qualityRisks['ocr_source_saved_photo_glare_risk'] ?? 0) > 0 ||
      (qualityRisks['ocr_source_action_reduce_brightness_or_glare'] ?? 0) > 0 ||
      (qualityRisks['ocr_source_action_reduce_glare_or_retake'] ?? 0) > 0 ||
      (qualityRisks['photo_quality_photo_has_glare_or_is_too_bright'] ?? 0) >
          0 ||
      (qualityRisks['photo_quality_photo_is_bright_check_for_glare_before_continuing'] ??
              0) >
          0) {
    add('photo_saved_glare_review');
  }
  if ((qualityRisks['ocr_source_saved_photo_dirty_lens_or_haze'] ?? 0) > 0 ||
      (qualityRisks['ocr_source_action_wipe_lens_or_retake'] ?? 0) > 0) {
    add('photo_saved_hazy_lens_review');
  }
  if ((qualityRisks['ocr_source_saved_photo_shadow_risk'] ?? 0) > 0 ||
      (qualityRisks['ocr_source_action_move_to_even_light_or_retake'] ?? 0) >
          0) {
    add('photo_saved_shadow_review');
  }
  if ((qualityRisks['ocr_source_saved_photo_bottom_too_dark'] ?? 0) > 0 ||
      (qualityRisks['ocr_source_saved_photo_bottom_soft'] ?? 0) > 0 ||
      (qualityRisks['ocr_source_action_check_bottom_or_raise_brightness'] ??
              0) >
          0 ||
      (qualityRisks['ocr_source_action_check_bottom_or_retake'] ?? 0) > 0) {
    add('photo_saved_bottom_quality_review');
  }

  final totalsTextMissing =
      result.hasText &&
      result.subtotalCandidateLines.isEmpty &&
      result.totalCandidateLines.isEmpty &&
      result.taxCandidateLines.isEmpty;
  final finalTotalMissing =
      result.hasText &&
      result.totalCandidateLines.isEmpty &&
      (result.subtotalCandidateLines.isNotEmpty ||
          result.taxCandidateLines.isNotEmpty);
  if (totalsTextMissing) {
    add('receipt_totals_text_missing_review');
    if (result.itemCandidateLines.isNotEmpty ||
        result.parserHandoff.pricedLineCount > 0) {
      add('receipt_possible_lower_section_missing');
    }
    final userConfirmedComplete =
        result.sourceHandoffSummary.hasUserConfirmedCompleteAfterPrompt;
    if (userConfirmedComplete) {
      add('receipt_user_confirmed_complete_review');
      if (result.sourceHandoffSummary.hasMissingBottomEdgeAndTotalsEvidence) {
        add('receipt_user_confirmed_missing_bottom_review');
      } else {
        add('receipt_user_confirmed_missing_totals_review');
      }
    } else if (result
        .sourceHandoffSummary
        .hasMissingBottomEdgeAndTotalsEvidence) {
      add('receipt_missing_bottom_edge_and_totals');
      add('receipt_bottom_section_continuation_needed');
    } else {
      add('receipt_missing_totals_manual_review');
    }
  } else if (finalTotalMissing) {
    add('receipt_partial_totals_review');
    add('receipt_final_total_missing_review');
    if (result.itemCandidateLines.isNotEmpty ||
        result.parserHandoff.pricedLineCount > 0) {
      add('receipt_possible_lower_section_missing');
    }
  }
  return Map.unmodifiable(counts);
}

ReceiptOcrReviewSeverity _severityFor({
  required bool hasText,
  required List<ReceiptOcrWarning> warnings,
  required ReceiptOcrReadStats stats,
  required bool duplicateOrOverlap,
}) {
  if (!hasText) return ReceiptOcrReviewSeverity.blocked;
  if (warnings.any((warning) => warning.isBlocking)) {
    return ReceiptOcrReviewSeverity.review;
  }
  if (stats.hadSkippedWork) return ReceiptOcrReviewSeverity.partial;
  if (duplicateOrOverlap || warnings.isNotEmpty) {
    return ReceiptOcrReviewSeverity.review;
  }
  return ReceiptOcrReviewSeverity.good;
}
