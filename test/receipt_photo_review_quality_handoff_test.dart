import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  test('post-capture quality copy leads with action and evidence', () async {
    final controls = await readReceiptPhotoReviewControlsUnit();
    final previewControls =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
        ).readAsString();
    final qualityRecovery = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_quality_recovery.dart',
    ).readAsString();
    final commonControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart',
    ).readAsString();
    final contextControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart',
    ).readAsString();
    final models = await readReceiptCaptureModelsSource();

    expect(models, contains('String get nextReviewActionLabel'));
    expect(models, contains('acceptedPhotoQualityOutcomeCounts'));
    expect(models, contains('acceptedPhotoHandoffOutcome'));
    expect(models, contains('acceptedPhotoHandoffActionLabel'));
    expect(models, contains('acceptedPhotoHandoffEvidenceLabel'));
    expect(models, contains('privacySafeOcrHandoffEvidenceLabel'));
    expect(models, contains('critical_quality_retake_recommended'));
    expect(models, contains('possible_partial_receipt'));
    expect(models, contains('ready_for_receipt_review'));
    expect(models, contains('String get userFacingStatusLabel'));
    expect(models, contains('String get qualityEvidenceLabel'));
    expect(models, contains('String get reviewScoreMeaningLabel'));
    expect(models, contains('class ReceiptPhotoCoverageDecision'));
    expect(models, contains('needsAnotherReceiptSectionBeforeDetails'));
    expect(models, contains('add_next_section_or_confirm_complete_receipt'));
    expect(models, contains('photo_review_add_next_receipt_section'));
    expect(models, contains('receipt_photo_capture_bottom_section'));
    expect(models, contains('Receipt details stay paused'));
    expect(models, contains('acceptedPhotoHandoffMustOpenFilledReview =>'));
    expect(models, contains('acceptedPhotoHandoffMustOpenReceiptDetails =>'));
    expect(models, contains('latestFramingWidthRatio'));
    expect(models, contains('latestFramingHeightRatio'));
    expect(models, contains('final textLikelyTooSmall ='));
    expect(models, contains('native_cut_off_risk'));
    expect(models, contains('missing_bottom_edge_and_totals'));
    expect(
      models,
      contains('bottom_edge_missing_plus_totals_words_and_amount_missing'),
    );
    expect(models, contains('edge_missing_and_totals_words_amount_missing'));
    expect(models, contains('subtotal/total words plus the total amount'));
    expect(models, contains('receiptBottomEdgeDetected'));
    expect(models, contains('receiptSubtotalDetected'));
    expect(models, contains('receiptTotalDetected'));
    expect(models, contains('receiptTotalAmountDetected'));
    expect(models, contains('text_may_be_too_small'));
    expect(
      models,
      contains('Retake recommended; use the photo only if the text is readable'),
    );
    expect(models, contains('Use this photo for receipt details'));
    expect(
      models,
      contains(r'$reviewBandLabel; photo check $reviewScoreLabel'),
    );
    expect(
      controls,
      contains('final coverageDecision = coverageDecisionForSelectedPhoto'),
    );
    expect(controls, contains('coverageDecision.shouldPromptForMorePhotos'));
    expect(controls, contains('coverageDecision.isMissingBottomEdgeAndTotals'));
    expect(
      controls,
      contains(
        'add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice',
      ),
    );
    expect(controls, contains("'Use Photo'"));
    expect(commonControls, isNot(contains("Next: Details If Complete")));
    expect(commonControls, isNot(contains("secondary: 'If Complete'")));
    expect(
      qualityRecovery,
      contains('coverageDecision.shouldEmphasizeAddPhoto'),
    );
    expect(previewControls, contains('Add Another Photo'));
    expect(commonControls, contains("secondary: 'Bottom Section'"));
    expect(
      previewControls,
      contains(
        'final addPhotoLabel = coverageDecision.isMissingBottomEdgeAndTotals',
      ),
    );
    expect(
      previewControls,
      contains(
        'Add bottom receipt section and repeat 3-5 readable lines in the top ghost slice',
      ),
    );
    expect(previewControls, contains("'Add Another Photo'"));
    expect(previewControls, isNot(contains(": 'Add Another';")));
    expect(controls, contains('quality.userFacingStatusLabel'));
    expect(controls, contains('quality.reviewScoreMeaningLabel'));
    expect(
      controls,
      contains('_ReceiptCaptureReadinessReviewCopy.fromDiagnostics'),
    );
    expect(contextControls, contains('Receipt looked steady at capture'));
    expect(
      contextControls,
      contains('before automatic capture considered the frame steady'),
    );
    expect(
      controls,
      contains('selectedCaptureDiagnostics: selectedCaptureDiagnostics'),
    );
    expect(
      contextControls,
      contains('Check that every receipt line is visible'),
    );
    expect(
      contextControls,
      contains('Check sharpness, light, and receipt text'),
    );
    expect(
      qualityRecovery,
      contains(
        "photoQuality.reviewGuidance} \${photoQuality.reviewScoreMeaningLabel}",
      ),
    );
    expect(
      qualityRecovery,
      isNot(
        contains(
          "photoQuality.reviewGuidance} \${photoQuality.qualityEvidenceLabel}",
        ),
      ),
    );
    expect(
      contextControls,
      contains(
        'Photo captured locally. Use this photo, retake it, or add another photo if the receipt continues.',
      ),
    );
    expect(controls, contains('Use Photos'));
    expect(models, contains('Next opens receipt details from each section'));
    final saveActions = await readReceiptPhotoReviewSaveActionsSource();
    final importActions = await readReceiptAttachmentImportActionsSource();
    final ocrActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_actions.dart',
    ).readAsString();
    expect(saveActions, contains('Text(nextLabel)'));
    expect(saveActions, contains('saveAndRead'));
    expect(
      saveActions,
      contains(r'Tap $nextLabel to use $target and open receipt details.'),
    );
    expect(saveActions, contains('result.captureDiagnosticsByPhotoPath('));
    expect(saveActions, contains('pickedPaths,'));
    expect(ocrActions, contains('final ReceiptOcrDiagnostics? ocrDiagnostics'));
    expect(ocrActions, contains('ocrDiagnostics: result.diagnostics'));
    expect(
      importActions,
      contains('mergeOcrTotalsEvidenceIntoAcceptedPhotoDiagnostics'),
    );
    expect(
      importActions,
      contains('diagnostics.receiptTotalsCoverageEvidenceDiagnostics'),
    );
    expect(importActions, contains("'accepted_photo_ocr_read'"));
    expect(importActions, contains("'final_receipt_section'"));
    expect(
      models,
      contains("'captureFallbackSource': 'receipt_camera_result'"),
    );
    expect(
      models,
      contains(
        'Map<String, Object?> get privacySafeReceiptReaderHandoffMetadata',
      ),
    );
    expect(models, contains("'receiptReaderHandoffSchema'"));
    expect(models, contains("'receiptDetailsHandoffSchema'"));
    expect(models, contains("'receiptDetailsHandoffRoute'"));
    expect(models, contains("'receiptDetailsHandoffNextScreen'"));
    expect(models, contains("'receiptDetailsHandoffUserAction'"));
    expect(models, contains("'ocrSourceFirstPolicy'"));
    expect(models, contains('ocr_reads_clear_source_before_saved_proof'));
    expect(models, contains('privacySafeOcrSourceFirstSummary'));
    expect(models, contains('ocrSourceFirstDecisionCode'));
    expect(models, contains('ocrReadsClearSourceBeforeSavedProof'));
    expect(models, contains('ocrUsesSavedProofOnlyAsFallback'));
    expect(models, contains('prepared_receipt_source_before_saved_proof'));
    expect(
      models,
      contains('temporary_full_quality_source_before_saved_proof'),
    );
    expect(
      models,
      isNot(contains('original_receipt_source_before_saved_proof')),
    );
    expect(models, contains('temporary_full_quality_ready'));
    expect(models, isNot(contains('original_source_ready')));
    expect(models, contains('saved_proof_fallback_review_required'));
    expect(models, contains("'ocrSourcePreparationDecisionCounts'"));
    expect(models, contains("'latestCapturedExposureMismatch'"));
    expect(models, contains("'capturedLightingEvidence'"));
    expect(models, contains("'preCaptureExposureOutcome'"));
    expect(models, contains("'latestCaptureLiveBrightnessAtShutter'"));
    expect(models, contains("'latestCapturedLiveToSavedLumaDelta'"));
    expect(models, contains("'latestCapturedLiveToSavedLumaDeltaBucket'"));
    expect(models, contains("'latestCapturedPreviewParitySignal'"));
    expect(models, contains('latestCapturedBottomLuma'));
    expect(models, contains('latestCapturedBottomEdgeScore'));
    expect(models, contains('latestCapturedBottomTopLumaDelta'));
    expect(models, contains('latestCapturedBottomTopLumaDeltaBucket'));
    expect(models, contains('latestCapturedVerticalQualitySignal'));
    expect(models, contains("'scannerDecisionCodes'"));
    expect(saveActions, isNot(contains('captureDiagnosticsByPath: const {},')));
    expect(
      importActions,
      contains('widget.onReceiptPhotoReviewAccepted?.call(result);'),
    );
    expect(importActions, contains('_startReviewedPhotoReadStatus(result);'));
    expect(
      importActions,
      contains('if (flowResult.message.trim().isNotEmpty)'),
    );
    expect(
      importActions,
      contains('await _readReviewedPhotosForReceiptForm(result)'),
    );
    expect(importActions, contains("'proof_data_saver_"));
    expect(
      importActions,
      contains("'ocr_reads_clear_source_before_saved_proof'"),
    );
    expect(importActions, contains("'receipt_review_depth_"));
    expect(importActions, contains("'receipt_match_readiness_"));
    expect(importActions, contains("'native_recovery_"));
    expect(importActions, contains("'native_camera_ui_health_available'"));
    expect(importActions, contains("'native_camera_ui_"));
    expect(importActions, contains("'review_photo_edited'"));
    expect(importActions, contains(r"'review_photo_edit_$editAction'"));
    expect(importActions, contains("'review_photo_edit_source_selected'"));
    expect(
      importActions,
      contains(r"'review_photo_edit_source_selected_$sourceSelection'"),
    );
    expect(importActions, contains('accepted_source_retained'));
    expect(importActions, isNot(contains('original_source_retained')));
    expect(importActions, contains("'review_photo_edit_replaced_original'"));
    expect(
      importActions,
      contains(r"'review_photo_edit_replaced_original_$editAction'"),
    );
    expect(
      importActions,
      contains("'ocr_source_small_proof_copy_review_required'"),
    );
    expect(importActions, contains("'ocr_source_proof_data_saver_"));
    expect(importActions, contains("'ocr_source_match_readiness_"));
    expect(importActions, contains("'ocr_source_native_recovery_"));
    expect(importActions, contains("'ocr_source_review_photo_edited'"));
    expect(
      importActions,
      contains(r"'ocr_source_review_photo_edit_$editAction'"),
    );
    expect(
      importActions,
      contains("'ocr_source_review_photo_edit_source_selected'"),
    );
    expect(
      importActions,
      contains(
        r"'ocr_source_review_photo_edit_source_selected_$sourceSelection'",
      ),
    );
    expect(
      importActions,
      contains('ocr_source_review_photo_edit_source_selected'),
    );
    expect(
      importActions,
      contains("'ocr_source_review_photo_edit_replaced_original'"),
    );
    expect(
      importActions,
      contains(r"'ocr_source_review_photo_edit_replaced_original_$editAction'"),
    );
    expect(importActions, contains('bool _isNativeCameraUiRisk(String value)'));
    final entryScreen = await readExpenseReceiptEntrySource();
    expect(entryScreen, contains('_diagnosticStringListCounts'));
    expect(entryScreen, contains("'nativeCameraEngineBuckets'"));
    expect(entryScreen, contains("'nativeDevicePolicyBuckets'"));
    expect(entryScreen, contains("'nativeCameraWorkloadTierBuckets'"));
    expect(entryScreen, contains("'nativeCameraResolutionTierBuckets'"));
    expect(entryScreen, contains("'nativeRecoveryFreshnessBuckets'"));
    expect(entryScreen, contains("'nativeRecoveryStorageStatusBuckets'"));
    expect(models, contains('nativeRecoveryFreshnessCounts'));
    expect(models, contains('nativeRecoveryStorageStatusCounts'));
    expect(entryScreen, contains("'capabilityPolicyCodeCounts'"));
    expect(controls, isNot(contains('final score =')));
  });
}
