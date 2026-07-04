import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepted photo attachments keep private safe camera health metadata', () async {
    final panel =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_publish_signals.dart',
        ).readAsString();
    final actions =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
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

    expect(panel, contains('_photoCaptureDiagnosticsByPath'));
    expect(actions, contains('result.captureDiagnosticsByPhotoPath'));
    expect(panel, contains('riskFlags: photoRiskFlagsFor(_photoPaths[index])'));
    expect(
      panel,
      contains('documentSignals: photoDocumentSignalsFor(_photoPaths[index])'),
    );
    expect(
      panel,
      contains('ReceiptCaptureDiagnosticKeys.photoCoverageNeedsMorePhotos'),
    );
    expect(panel, contains('ReceiptNativeSavedPhotoReviewWarning'));
    expect(panel, contains('possible_partial_receipt'));
    expect(panel, contains('receipt_photo_dark'));
    expect(panel, contains('receipt_photo_soft'));
    expect(panel, contains('native_capture_critical_review'));

    final disallowedPrivateContent = [
      'receiptText:',
      'customerName:',
      'customerAddress:',
      'phoneNumber:',
      'vendorName:',
      'lineItemDescription:',
    ];
    for (final privateContent in disallowedPrivateContent) {
      expect(panel, isNot(contains(privateContent)));
    }
  });

  test('app assisted OCR reads prepared OCR sources instead of saved backup proof', () async {
    final flow =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_attachment_helpers.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_helpers.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_native_signals.dart',
        ).readAsString();
    final actions =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_continuation_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart',
        ).readAsString();

    expect(flow, contains('result.ocrSourcePhotoPaths[index]'));
    expect(actions, contains('result.ocrSourcePhotoPaths[index]'));
    expect(
      flow,
      contains('final ocrSourcePath = result.ocrSourcePhotoPaths[index];'),
    );
    expect(
      flow,
      contains(
        '_receiptPhotoMapValue(\n'
        '    result.photoQualityChecksByPath,\n'
        '    ocrSourcePath,',
      ),
    );
    expect(
      flow,
      contains(
        '_receiptPhotoMapValue(result.preparationDiagnosticsByOcrPath, path)',
      ),
    );
    expect(
      flow,
      contains(
        '_receiptPhotoMapValue(\n'
        '    result.captureDiagnosticsByPhotoPath,\n'
        '    ocrSourcePath,',
      ),
    );
    expect(
      flow,
      contains(
        '_receiptPhotoMapValue(\n'
        '      result.captureDiagnosticsByPhotoPath,\n'
        '      result.photoPaths[index],',
      ),
    );
    expect(flow, contains('normalizedReceiptPhotoPath(entry.key)'));
    expect(actions, contains('ocr_source_retake_risk'));
    expect(flow, contains("'ocr_reads_prepared_source_not_saved_backup'"));
    expect(actions, contains("'ocr_reads_prepared_source_not_saved_backup'"));
    expect(flow, contains("'receiptReaderHandoffOcrSourcePolicy'"));
    expect(flow, contains("'receiptReaderHandoffOcrSourceOutcome'"));
    expect(flow, contains("'receiptReaderHandoffOcrSourceActionLabel'"));
    expect(flow, contains('result.ocrSourceFirstOutcome'));
    expect(flow, contains('result.ocrSourceFirstActionLabel'));
    expect(
      flow,
      contains('read_original_or_prepared_source_before_saved_proof'),
    );
    expect(flow, contains("'receiptReaderHandoffCompressionPolicy'"));
    expect(flow, contains('saved_proof_created_after_receipt_details_source'));
    expect(flow, contains('receipt_handoff_warning_'));
    expect(actions, contains('receipt_handoff_warning_'));
    expect(flow, contains("sourceLabel: 'Maintainiac OCR source photo'"));
    expect(actions, contains("sourceLabel: 'Maintainiac OCR source photo'"));
    expect(flow, contains('ReceiptAttachmentStorageState.staged'));
    expect(actions, contains('ReceiptAttachmentStorageState.staged'));
    expect(flow, contains('_savedPhotoWarningsForOcrSourceIndex'));
    expect(actions, contains('savedPhotoWarningsForOcrSourceIndex'));
    expect(flow, contains('ocr_source_native_critical_review'));
    expect(actions, contains('ocr_source_native_critical_review'));
    expect(flow, contains('recoveredCount.isFinite'));
    expect(actions, contains('recoveredCount.isFinite'));
    expect(
      flow,
      isNot(contains('recoveredCount is num && recoveredCount > 0')),
    );
    expect(
      actions,
      isNot(contains('recoveredCount is num && recoveredCount > 0')),
    );
    expect(flow, contains('ocr_source_action_'));
    expect(actions, contains('ocr_source_action_'));
    expect(actions, contains('receiptContinuationHandoffDocumentSignalsFor'));
    expect(actions, contains('receiptContinuationHandoffRiskFlagsFor'));
    expect(actions, contains('ocrSourceContinuationDocumentSignalsFor'));
    expect(actions, contains('ocrSourceContinuationRiskFlagsFor'));
    expect(actions, contains('receipt_continuation_handoff_'));
    expect(actions, contains('receipt_continuation_ocr_missing_bottom_totals'));
    expect(
      actions,
      contains('receipt_continuation_missing_bottom_edge_and_totals'),
    );
    expect(actions, contains('receipt_continuation_ghost_policy_'));
    expect(
      actions,
      contains('ocr_source_continuation_missing_bottom_totals_review'),
    );
    expect(
      actions,
      contains('ocr_source_continuation_bottom_overlap_ghost_policy'),
    );
    expect(
      actions,
      contains('ocr_source_continuation_ocr_requested_bottom_section_review'),
    );
    final ocrAttachmentBlock = actions.substring(
      actions.indexOf('final ocrAttachments = ['),
      actions.indexOf('return _readAttachmentsForReceiptForm('),
    );
    expect(ocrAttachmentBlock, contains('result.ocrSourcePhotoPaths.length'));
    expect(
      ocrAttachmentBlock,
      contains('path: result.ocrSourcePhotoPaths[index]'),
    );
    expect(
      ocrAttachmentBlock,
      isNot(
        contains(
          'for (var index = 0; index < result.photoPaths.length; index++)',
        ),
      ),
    );
  });

  test('shared capture keeps UI labels on next/review language', () async {
    final controls =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_status.dart',
        ).readAsString();
    final screen =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_surfaces.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_surface_controls.dart',
        ).readAsString();
    final topBar = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart',
    ).readAsString();
    final commonControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart',
    ).readAsString();
    final previewControls =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
        ).readAsString();
    final models =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_models.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_warnings.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_handoff_labels.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_completion.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_review_result_next_review.dart',
        ).readAsString();

    expect(controls, contains('Next: Review Receipt Details'));
    expect(controls, contains("return 'Next: Review Receipt Details';"));
    expect(screen, contains('_ReceiptReviewMode.preview => .20'));
    expect(screen, contains('_photoPaths.length > 1 ? 164.0 : 142.0'));
    expect(topBar, contains('_ReceiptNextReviewLabel(label: label)'));
    expect(commonControls, isNot(contains("normalized == 'Next: Details'")));
    expect(previewControls, contains("'Add Another Photo'"));
    expect(previewControls, contains('minimumSize: const Size(92, 36)'));
    expect(controls, contains('Next opens receipt'));
    expect(
      controls,
      contains('details with item prices, totals, and business/personal use.'),
    );
    expect(
      models,
      contains('Review receipt details and mark Business, Personal, or Mixed.'),
    );
    expect(models, contains(r'Next reviews $nextReviewSourceLabel'));
    expect(controls, isNot(contains('Read receipt')));
    expect(controls, isNot(contains('Use this photo')));
    expect(controls, isNot(contains('Saved copy')));
  });

  test('photo review UI tweaks keep camera action wiring intact', () async {
    final controls =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart',
        ).readAsString();
    final surfaceControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_surface_controls.dart',
    ).readAsString();
    final screen =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_order_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_async.dart',
        ).readAsString();

    expect(surfaceControls, contains('onAddPhoto: addAnotherReceiptPhoto'));
    expect(surfaceControls, contains('onRetake: retakeCurrentReceiptPhoto'));
    expect(surfaceControls, contains('onContinue: continueReceiptPhotoReview'));
    expect(
      surfaceControls,
      contains('onMoveEarlier: () => moveCurrentReceiptPhoto(-1)'),
    );
    expect(
      surfaceControls,
      contains('onMoveLater: () => moveCurrentReceiptPhoto(1)'),
    );
    expect(
      surfaceControls,
      contains(
        'selectedCaptureDiagnostics: _captureDiagnosticsByPath[photoPath]',
      ),
    );
    expect(
      surfaceControls,
      contains('selectedQualityCheck: _qualityChecksByPath[photoPath]'),
    );
    expect(
      surfaceControls,
      contains('onManualOverlapChanged: _setManualOverlapFraction'),
    );
    expect(
      surfaceControls,
      contains('onClearManualOverlap: _clearManualOverlapFraction'),
    );
    expect(surfaceControls, contains('onApplyCrop: _applyCrop'));
    expect(surfaceControls, contains('onCancelCrop: _cancelCropReview'));
    expect(controls, contains('onAddPhoto'));
    expect(controls, contains('onRetake'));
    expect(controls, contains('onContinue'));
    expect(controls, contains('ReceiptPhotoCoverageDecision.fromSignals'));
    expect(controls, contains('Add Bottom Section'));
    expect(controls, contains('Next: Details If Complete'));
    expect(controls, contains('Next: Review Receipt Details'));
    expect(screen, contains('Future<void> addAnotherReceiptPhoto()'));
    expect(screen, contains('Future<void> retakeCurrentReceiptPhoto()'));
    expect(screen, contains('Future<void> continueReceiptPhotoReview()'));
    expect(screen, contains('Future<void> _applyCrop()'));
    expect(screen, contains('void moveCurrentReceiptPhoto(int direction)'));
    expect(screen, contains('_setManualOverlapFraction'));
    expect(screen, contains('_clearManualOverlapFraction'));
  });
}
