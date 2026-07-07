import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  test('native ghost guide contract keeps repeat-line guidance explicit', () async {
    final nativeContract = await readReceiptNativeCameraContractSource();
    final nativeService = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart',
    ).readAsString();
    final nativeGuidance =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_ghost_guidance.dart',
        ).readAsString();
    final reviewActions = await readReceiptPhotoReviewSaveActionsSource();

    expect(
      nativeContract,
      contains('previousSectionGhostGuideRepeatLineTarget'),
    );
    expect(nativeContract, contains('repeat_3_to_5_readable_lines'));
    expect(nativeContract, contains('previousSectionGhostGuidePlacement'));
    expect(nativeContract, contains('top_ghost_slice'));
    expect(nativeContract, contains('previousSectionGhostGuideMatchTarget'));
    expect(nativeContract, contains('subtotal_total_and_final_lines'));
    expect(
      nativeContract,
      contains('previousSectionGhostSourceStartFractionOrDefault'),
    );
    expect(
      nativeContract,
      contains('previousSectionGhostSourceHeightFractionOrDefault'),
    );
    expect(nativeContract, contains('previousSectionGhostSlicePercent'));
    expect(
      nativeService,
      contains('previousSectionGhostGuideRepeatLineTarget'),
    );
    expect(nativeService, contains('previousSectionGhostGuidePlacement'));
    expect(nativeService, contains('previousSectionGhostGuideMatchTarget'));
    expect(nativeService, contains('previousSectionGhostSourceStartFraction'));
    expect(nativeService, contains('previousSectionGhostSourceHeightFraction'));
    expect(nativeService, contains('previousSectionGhostOverlayTopFraction'));
    expect(
      nativeService,
      contains('previousSectionGhostOverlayHeightFraction'),
    );
    expect(nativeService, contains('previousSectionGhostOpacity'));
    expect(nativeService, contains('previousSectionGhostSlicePercent'));
    expect(nativeGuidance, contains('Repeat 3-5 readable lines here'));
    expect(nativeGuidance, contains('Line up 3-5 repeated receipt lines here'));
    expect(
      reviewActions,
      contains('Put 3-5 repeated readable lines in the top ghost slice'),
    );
    expect(
      reviewActions,
      contains(
        'bottom-section ghost guide. Put 3-5 repeated readable lines in the top ghost slice',
      ),
    );
    expect(
      reviewActions,
      contains('subtotal, total, and final lines can be matched'),
    );
  });

  test('photo review surfaces native saved-photo quality warnings', () async {
    final reviewScreen = await readReceiptPhotoReviewScreenSource();
    final controls = await readReceiptPhotoReviewControlsUnit();
    final previewControls =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
        ).readAsString();
    final previewActionTray =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_status.dart',
        ).readAsString();
    final qualityRecovery = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_quality_recovery.dart',
    ).readAsString();
    final models = await readReceiptCaptureModelsSource();
    final importActions = await readReceiptAttachmentImportActionsSource();
    final captureFlow = await readReceiptCaptureFlowSource();

    expect(
      reviewScreen,
      contains(
        'selectedCaptureDiagnostics: _captureDiagnosticsByPath[photoPath]',
      ),
    );
    expect(controls, contains('selectedCaptureDiagnostics'));
    expect(models, contains('latestCapturedExposureMismatch'));
    expect(models, contains('capturedLightingEvidence'));
    expect(models, contains('preCaptureExposureOutcome'));
    expect(models, contains('lifted_for_dim_receipt'));
    expect(models, contains('latestCaptureLiveBrightnessAtShutter'));
    expect(models, contains('latestCapturedLiveToSavedLumaDelta'));
    expect(models, contains('latestCapturedLiveToSavedLumaDeltaBucket'));
    expect(models, contains('latestCapturedPreviewParitySignal'));
    expect(models, contains('saved_photo_darker_than_preview_review_needed'));
    expect(models, contains('saved_photo_brighter_than_preview_review_needed'));
    expect(models, contains('latestCapturedQualitySignal'));
    expect(models, contains('latestCapturedBrightnessBucket'));
    expect(models, contains('latestCapturedSharpnessBucket'));
    expect(models, contains('latestCapturedVerticalQualitySignal'));
    expect(models, contains('saved_photo_bottom_too_dark'));
    expect(models, contains('saved_photo_bottom_soft'));
    expect(
      await readReceiptNativeCaptureStagingSource(),
      contains('latestCapturedBottomLuma'),
    );
    expect(
      await readReceiptNativeCaptureStagingSource(),
      contains('latestCapturedBottomTopLumaDeltaBucket'),
    );
    expect(
      await readReceiptNativeCaptureStagingSource(),
      contains('capturedLightingEvidence'),
    );
    expect(models, contains('bottom_darker_than_top'));
    expect(models, contains('bottom_much_darker_than_top'));
    expect(models, contains("lightingEvidence == 'capture_too_dark'"));
    expect(models, contains('final previewParitySignal ='));
    expect(models, contains("previewParitySignal =="));
    expect(models, contains("lightingEvidence == 'bottom_lighting_risk'"));
    expect(models, contains("lightingEvidence == 'capture_dim_review_needed'"));
    expect(models, contains("lightingEvidence == 'capture_glare_risk'"));
    expect(
      previewActionTray,
      contains('ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics'),
    );
    expect(models, contains('String get actionCode'));
    expect(models, contains('String get parserRiskCode'));
    expect(models, contains('String get parserImpactGuidance'));
    expect(models, contains('String get primaryActionLabel'));
    expect(models, contains("'document_scanner_backup'"));
    expect(models, contains('saved_photo_document_scanner_backup'));
    expect(models, contains('saved_photo_phone_camera_backup'));
    expect(importActions, contains('ocr_source_document_scanner_backup'));
    expect(captureFlow, contains('ocr_source_document_scanner_backup'));
    expect(
      importActions,
      contains(
        'receipt_coverage_evidence_bottom_edge_missing_plus_totals_text_missing',
      ),
    );
    expect(
      captureFlow,
      contains(
        'receipt_coverage_evidence_bottom_edge_missing_plus_totals_text_missing',
      ),
    );
    expect(models, contains('ocr_bottom_total_may_fail'));
    expect(models, contains('ocr_bottom_lines_may_fail'));
    expect(
      models,
      contains('use Add Another Photo for a clearer bottom section'),
    );
    expect(models, contains('savedPhotoWarningActionCounts'));
    expect(models, contains('savedPhotoParserRiskCounts'));
    expect(qualityRecovery, contains('_NativeCaptureReviewWarning.fromModel'));
    expect(controls, contains('nativeWarning: nativeWarning'));
    expect(qualityRecovery, contains('nativeCaptureWarning.title'));
    expect(qualityRecovery, contains('nativeCaptureWarning.detail'));
    expect(
      qualityRecovery,
      contains('nativeCaptureWarning?.prefersAddSection'),
    );
    expect(
      controls,
      contains(
        r"'${nativeWarning.primaryActionLabel}. If the store, date, total, '",
      ),
    );
    expect(controls, contains('you can still use the photo'));
    expect(qualityRecovery, contains('required this.primaryActionLabel'));
    expect(
      qualityRecovery,
      contains('primaryActionLabel: warning.primaryActionLabel'),
    );
    expect(qualityRecovery, contains('shouldEmphasizeAddSection'));
    expect(
      qualityRecovery,
      contains('final actionButtons = shouldEmphasizeAddSection'),
    );
    expect(qualityRecovery, contains('[addButton, cropButton, retakeButton]'));
    expect(qualityRecovery, contains('[retakeButton, cropButton, addButton]'));
    expect(qualityRecovery, contains('warning.parserImpactGuidance'));
    expect(qualityRecovery, contains('nativeCaptureWarning?.panelColor'));
    expect(qualityRecovery, contains('nativeCaptureWarning?.color'));
    expect(models, contains('bool get prefersAddSection'));
    expect(models, contains('saved_photo_soft_blur_risk'));
    expect(models, contains('saved_photo_glare_risk'));
    expect(models, contains('saved_photo_brighter_than_preview'));
    expect(models, contains('reduce_brightness_or_glare'));
    expect(models, contains('_nativeCapturePreviewParityHealthCodes'));
    expect(models, contains('preview_saved_darker_than_live'));
    expect(models, contains('preview_saved_brighter_than_live'));
    expect(models, contains('preview_saved_parity_ok'));
    expect(models, contains('preview_saved_parity_review'));
    expect(
      models,
      contains("'nativeCameraUiHealthOutcome': nativeCameraUiHealthOutcome"),
    );
    expect(models, contains('_isBorderlineDimButReadable'));
    expect(models, contains('_isBrightReadablePaper'));
    expect(controls, isNot(contains("sharpnessBucket == 'captured_soft'")));
    expect(previewControls, contains("label: 'Add Another Photo'"));
    expect(previewControls, isNot(contains("label: 'Add Section'")));
  });
}
