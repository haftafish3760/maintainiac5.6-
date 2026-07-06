import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_camera_source_readers.dart';

void main() {
  test('reviewed camera photos read OCR sources before saved copies', () async {
    final reviewActions = await readReceiptPhotoReviewSaveActionsSource();
    final importActions =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_native_signal_documents.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_native_signal_helpers.dart',
        ).readAsString();

    final imageProcessor = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_processor.dart',
    ).readAsString();
    final imageEnhancementHelpers = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_processor_enhancement_helpers.dart',
    ).readAsString();
    final models =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_models.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_native_brain_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_native_outcomes.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_metadata.dart',
        ).readAsString();
    final expenseParseModels = await File(
      'lib/screens/expenses/data/expense_receipt_parse_models.dart',
    ).readAsString();
    final reviewScreen = await readReceiptPhotoReviewScreenSource();
    final reviewCropAndProofControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart',
    ).readAsString();
    final receiptEntryScreen =
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_core_helpers.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_ocr_actions.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_parser_telemetry_metadata.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_photo_preparation_telemetry.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_photo_preparation_telemetry_metadata.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_photo_preparation_telemetry_tail.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_diagnostic_bucket_helpers.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_capture_diagnostic_helpers.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_read_handoff_helpers.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_scaffold.dart',
        ).readAsString();
    final receiptParseReviewHandoffPanel = await File(
      'lib/screens/expenses/entry/expense_receipt_parse_review_handoff_panel.dart',
    ).readAsString();
    final captureFlow = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart',
    ).readAsString();
    final captureRisks = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart',
    ).readAsString();
    final attachmentPanel = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart',
    ).readAsString();
    expect(reviewActions, contains('prepareForOcrAndBackup'));
    expect(reviewActions, contains('captureDiagnosticsByPath'));
    expect(reviewActions, contains('staged.captureDiagnosticsByPhotoPath'));
    expect(reviewActions, contains('preparationDiagnostics'));
    expect(reviewActions, contains('prepared.preparation'));
    expect(reviewActions, contains('.toDiagnostics()'));
    expect(
      reviewActions,
      contains('preparationDiagnosticsByOcrPath: finalPreparationDiagnostics'),
    );
    expect(
      reviewActions,
      contains('_preparationDiagnosticsForFinalOcrSources'),
    );
    expect(reviewActions, contains('ocr_source_stitched_selected'));
    expect(reviewActions, contains('stitchedOcrSource'));
    expect(reviewActions, contains('sourceOcrPaths'));
    expect(captureFlow, contains('stitch_ocr_source_contract_review_required'));
    expect(
      attachmentPanel,
      contains('stitch_ocr_source_contract_review_required'),
    );
    expect(
      captureRisks,
      contains('ocr_source_stitch_contract_review_required'),
    );
    expect(
      reviewActions,
      contains('captureDiagnosticsByPhotoPath: captureDiagnostics'),
    );
    expect(
      models,
      contains(
        'final Map<String, Map<String, Object?>> captureDiagnosticsByPhotoPath',
      ),
    );
    expect(reviewScreen, contains('previewPreparedBackupFile'));
    expect(reviewScreen, contains('optimizePreparedBackupFile'));
    expect(reviewCropAndProofControls, contains('_ReceiptOcrProofLaneCard'));
    expect(reviewCropAndProofControls, contains('_ReceiptDataSaverReviewCopy'));
    expect(
      reviewCropAndProofControls,
      contains('Receipt Details And Saved Proof'),
    );
    expect(reviewScreen, contains('_deleteGeneratedDataSaverPreviews'));
    expect(reviewScreen, contains('_deleteGeneratedStitchPreview'));
    expect(reviewActions, contains('_deleteUnusedBestShotCandidatePhotos'));
    expect(reviewActions, contains('_deleteGeneratedEditPhotos'));
    expect(imageProcessor, contains('prepareReceiptSourceFile'));
    expect(imageProcessor, contains('prepareReceiptSourceWithReport'));
    expect(imageProcessor, contains('ReceiptImagePreparationReport'));
    expect(imageProcessor, contains('usedEnhancedOcrSource'));
    expect(imageProcessor, contains('cleanupActions'));
    expect(imageProcessor, contains('previewPreparedBackupFile'));
    expect(imageProcessor, contains('optimizePreparedBackupFile'));
    expect(imageProcessor, contains('_deleteFileQuietly'));
    expect(imageProcessor, contains('optimizeFile'));
    expect(imageEnhancementHelpers, contains('_finiteEnhancementMetric'));
    expect(
      imageEnhancementHelpers,
      contains('_finiteEnhancementMetric(quality.textBandScore)'),
    );
    expect(
      imageProcessor.indexOf('prepareReceiptSourceFile'),
      lessThan(imageProcessor.indexOf('optimizeFile')),
    );
    expect(
      reviewActions,
      contains('ocrSourcePaths.add(prepared.ocrSourcePath)'),
    );
    expect(reviewActions, contains('savedPaths.add(prepared.backupPath)'));
    expect(reviewActions, contains('...stitch.ocrSourcePaths'));
    expect(importActions, contains('_readReviewedPhotosForReceiptForm'));
    expect(importActions, contains('markReviewedPhotosReadState'));
    expect(
      importActions,
      contains('widget.onReceiptPhotoReviewAccepted?.call(result)'),
    );
    expect(
      receiptEntryScreen,
      contains('_recordReceiptPhotoPreparationTelemetry(result)'),
    );
    expect(
      receiptEntryScreen,
      contains('preparationDiagnosticsByOcrPath.values'),
    );
    expect(
      receiptEntryScreen,
      contains('captureDiagnosticsByPhotoPath.values'),
    );
    expect(receiptEntryScreen, contains('ocrSourceHandoffStatus'));
    expect(receiptEntryScreen, contains('ocrSourceReviewDepthSignalCounts'));
    expect(receiptEntryScreen, contains('ocrSourceReviewDepthStatus'));
    expect(
      receiptEntryScreen,
      contains('result.usedSavedProofAsOcrSourceFallback'),
    );
    expect(
      receiptEntryScreen,
      contains(
        'Receipt reader is using the saved proof copy because a clearer OCR source was not available.',
      ),
    );
    expect(
      captureFlow,
      contains(
        r'ocr_source_review_risk_${_signalToken(result.ocrSourceReviewRiskCode)}',
      ),
    );
    expect(
      captureFlow,
      contains(
        r'ocr_source_review_requirement_${_signalToken(result.ocrSourceReviewRequirement)}',
      ),
    );
    expect(
      attachmentPanel,
      contains(
        r'ocr_source_review_risk_${attachmentSignalToken(result.ocrSourceReviewRiskCode)}',
      ),
    );
    expect(
      attachmentPanel,
      contains(
        r'ocr_source_review_requirement_${attachmentSignalToken(result.ocrSourceReviewRequirement)}',
      ),
    );
    expect(receiptEntryScreen, contains("'saved_proof_fallback'"));
    expect(receiptEntryScreen, contains('ocrSourceHandoffSignalCounts'));
    expect(receiptEntryScreen, contains('result.receiptReaderHandoffCounts'));
    expect(
      receiptEntryScreen,
      contains('...result.privacySafeReceiptReaderHandoffMetadata'),
    );
    expect(models, contains('receiptBrainBaseSizeDecisionCounts'));
    expect(expenseParseModels, contains('ocrSourceReviewDepthSignalCounts'));
    expect(expenseParseModels, contains('ocrSourceReviewDepthStatus'));
    expect(models, contains('receiptBrainBaseSizeDecisionOutcome'));
    expect(models, contains('receiptBrainBaseNeedsSizeReviewCounts'));
    expect(models, contains('receiptBrainBaseBlocksLowStorageCounts'));
    expect(
      models,
      contains('receiptBrainFullOfflineExceedsBaseGuardrailCounts'),
    );
    expect(models, contains('receiptBrainFullOfflineMustStayOptionalCounts'));
    expect(models, contains('receiptBrainLowStorageDownloadRiskCounts'));
    expect(models, contains('receiptBrainLowStorageDownloadRiskOutcome'));
    expect(models, contains('receiptBrainBaseVersusFullOfflineSummaryCounts'));
    expect(receiptEntryScreen, contains('captureDiagnosticsCount'));
    expect(receiptEntryScreen, contains('_receiptReadHandoffCoverageWarning'));
    expect(receiptEntryScreen, contains('_receiptReadHandoffStage'));
    expect(receiptEntryScreen, contains('Opening receipt details'));
    expect(
      receiptEntryScreen,
      isNot(contains('Preparing saved receipt photo')),
    );
    expect(
      receiptEntryScreen,
      contains('result.hasPossiblePartialReceiptPhotos'),
    );
    expect(receiptEntryScreen, contains('photoCoverageStatuses'));
    expect(receiptEntryScreen, contains('photoCoverageReasons'));
    expect(receiptEntryScreen, contains('photoCoverageNeedsMoreCount'));
    expect(receiptEntryScreen, contains('hasPossiblePartialReceiptPhotos'));
    expect(
      receiptEntryScreen,
      contains('coverageWarningLabel: _receiptReadHandoffCoverageWarning'),
    );
    expect(
      receiptEntryScreen,
      contains('stageLabel: _receiptReadHandoffStage'),
    );
    expect(receiptEntryScreen, contains('One receipt photo may be incomplete'));
    expect(receiptParseReviewHandoffPanel, contains('stageLabel'));
    expect(receiptParseReviewHandoffPanel, contains('coverageWarningLabel'));
    expect(
      receiptParseReviewHandoffPanel,
      contains('Icons.add_photo_alternate_rounded'),
    );
    expect(receiptEntryScreen, contains('brightnessBuckets'));
    expect(receiptEntryScreen, contains('readabilitySignalBuckets'));
    expect(receiptEntryScreen, contains('exposureAssistStatuses'));
    expect(receiptEntryScreen, contains('framingConfidenceBuckets'));
    expect(receiptEntryScreen, contains('focusStatusBuckets'));
    expect(receiptEntryScreen, contains('autoCaptureStatusBuckets'));
    expect(receiptEntryScreen, contains('edgeDetectionEnabledCount'));
    expect(receiptEntryScreen, contains('edgeOverlayEnabledCount'));
    expect(receiptEntryScreen, contains('legacyTapFocusEnabledCount'));
    expect(receiptEntryScreen, isNot(contains("'tapFocusEnabledCount'")));
    expect(receiptEntryScreen, contains('pinchZoomEnabledCount'));
    expect(receiptEntryScreen, contains('brightnessSliderEnabledCount'));
    expect(receiptEntryScreen, contains('shadowWarningEnabledCount'));
    expect(receiptEntryScreen, contains('textTooSmallWarningEnabledCount'));
    expect(receiptEntryScreen, contains('autoCropSuggestionEnabledCount'));
    expect(receiptEntryScreen, contains('grayscalePreviewEnabledCount'));
    expect(receiptEntryScreen, contains('contrastBoostEnabledCount'));
    expect(receiptEntryScreen, contains('shadowReductionEnabledCount'));
    expect(receiptEntryScreen, contains('orientationCorrectionEnabledCount'));
    expect(receiptEntryScreen, contains('legacyTapFocusTotal'));
    expect(receiptEntryScreen, isNot(contains("'tapFocusTotal'")));
    expect(receiptEntryScreen, contains('zoomChangeTotal'));
    expect(receiptEntryScreen, contains('manualBrightnessChangeTotal'));
    expect(receiptEntryScreen, contains('autoCaptureTriggerTotal'));
    expect(receiptEntryScreen, contains('latestFramingConfidence'));
    expect(receiptEntryScreen, contains('_diagnosticStringCounts'));
    expect(receiptEntryScreen, contains('_diagnosticIntSum'));
    expect(receiptEntryScreen, contains('_diagnosticIntValue'));
    expect(receiptEntryScreen, contains('!parsed.isFinite'));
    expect(receiptEntryScreen, contains('_intTelemetryValue'));
    expect(receiptEntryScreen, contains('num() when value.isFinite => value'));
    expect(receiptEntryScreen, contains('_diagnosticBoolTrueCount'));
    expect(receiptEntryScreen, contains('scannerCleanupUsedCount'));
    expect(receiptEntryScreen, contains('cleanupActions'));
    expect(receiptEntryScreen, contains('stitchFallbackReason'));
    expect(receiptEntryScreen, contains('diagnosticReasonLabel'));
    expect(receiptEntryScreen, contains('stitchConfidenceBucket'));
    expect(receiptEntryScreen, isNot(contains('receiptText')));
  });
}
