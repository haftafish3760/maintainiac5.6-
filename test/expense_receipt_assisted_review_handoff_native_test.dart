import 'package:flutter_test/flutter_test.dart';

import 'helpers/expense_receipt_assisted_review_source_fixture.dart';

void main() {
  test('assisted receipt review wires OCR handoff and review controls', () async {
    final source = await readAssistedReviewSourceFixture();
    final entryScreen = source.entryScreen;
    final stateActions = source.stateActions;
    final lineModels = source.lineModels;
    final lineEditorActions = source.lineEditorActions;
    final lineFields = source.lineFields;
    final attachmentOcr = source.attachmentOcr;
    final importActions = source.importActions;
    final photoControls = source.photoControls;
    final photoPreviewControls = source.photoPreviewControls;
    final telemetry = source.telemetry;

    expect(attachmentOcr, contains('await Future<void>.sync'));
    expect(
      attachmentOcr.indexOf('await Future<void>.sync'),
      lessThan(attachmentOcr.indexOf('_receiptReadStatusMessage = message;')),
    );
    expect(
      attachmentOcr.indexOf('widget.onReceiptReadStarted?.call();'),
      lessThan(attachmentOcr.indexOf('recognizeTextFromAttachments')),
    );
    expect(importActions, contains('_readReviewedPhotosForReceiptForm'));
    expect(importActions, contains('settings?.appAssistedEnabledFor'));
    expect(importActions, contains('result.ocrSourcePhotoPaths.isEmpty'));
    expect(importActions, contains('widget.onReceiptReadStarted?.call();'));
    expect(
      importActions,
      contains('widget.onReceiptPhotoReviewAccepted?.call(result);'),
    );
    expect(importActions, contains('_startReviewedPhotoReadStatus(result);'));
    expect(
      importActions,
      contains(
        "receipt_handoff_\${_signalToken(result.acceptedPhotoHandoffOutcome)}",
      ),
    );
    expect(
      importActions,
      contains(
        "receipt_handoff_warning_\${_signalToken(result.acceptedPhotoWarningProfile)}",
      ),
    );
    expect(
      importActions,
      contains(
        "receipt_handoff_stitch_\${_signalToken(result.stitchResult.status.name)}",
      ),
    );
    expect(
      importActions,
      contains(
        'final readResult = await _readReviewedPhotosForReceiptForm(result);',
      ),
    );
    expect(
      importActions.indexOf('_publishAttachmentChange();'),
      lessThan(
        importActions.indexOf('_readReviewedPhotosForReceiptForm(result);'),
      ),
    );
    expect(
      importActions.indexOf('_readReviewedPhotosForReceiptForm(result);'),
      lessThan(
        importActions.indexOf('keptReceiptPhotoPaths: result.photoPaths'),
      ),
    );
    expect(
      importActions,
      contains('required List<String> keptReceiptPhotoPaths'),
    );
    expect(importActions, contains('_shouldDeleteTemporaryOcrPhoto'));
    expect(importActions, contains('_isProtectedReceiptStoragePath'));
    expect(importActions, contains("'/receipt_proofs_staging/'"));
    expect(importActions, contains("'/native_capture_recovery/'"));
    expect(importActions, contains('Directory.systemTemp.path'));
    expect(
      importActions,
      contains(
        'One combined receipt image was read. Review what Maintainiac filled in below.',
      ),
    );
    expect(
      importActions,
      contains(
        'Receipt photos were read from top to bottom. Review what Maintainiac filled in below.',
      ),
    );
    expect(
      importActions,
      contains(
        'Receipt photo was read. Review what Maintainiac filled in below.',
      ),
    );
    expect(stateActions, contains('_setReceiptLineUse'));
    expect(
      stateActions,
      contains('Future<void> _parseImportedReceiptText(String text) async'),
    );
    expect(
      stateActions,
      contains('await _parseImportedReceiptTextWithMemory(text)'),
    );
    expect(stateActions, contains('_chooseSplitBusinessPercent'));
    expect(
      stateActions,
      contains('parserNeedsReview: use == _ExpenseLineUse.split'),
    );
    expect(
      stateActions,
      contains("parserReviewLabel: use == _ExpenseLineUse.split ? 'Review' : 'Good'"),
    );
    expect(stateActions, contains('_scrollToReceiptReview();'));
    expect(
      stateActions,
      contains("_receiptReadHandoffStage = 'Filling receipt details'"),
    );
    expect(
      stateActions,
      contains('_receiptReadHandoffStage = _receiptStageLabelForParsedReceipt'),
    );
    expect(
      stateActions,
      contains("_receiptReadHandoffStage = 'Needs manual review'"),
    );
    expect(stateActions, contains('_applyUnusableParsedReceipt(parsed);'));
    expect(
      stateActions,
      contains('Receipt was read, but the app could not find usable fields.'),
    );
    expect(
      stateActions,
      contains('_lastFieldConfidences = parsed.fieldConfidences'),
    );
    expect(stateActions, contains('_lastFieldConfidences = const {};'));
    expect(stateActions, contains('_parserCategoryBuckets(result)'));
    expect(stateActions, contains('_parserReviewCategoryBuckets(result)'));
    expect(stateActions, contains('_parserFieldConfidenceBuckets(result)'));
    expect(stateActions, contains("'parsedCategoryBuckets': categoryBuckets"));
    expect(
      stateActions,
      contains("'reviewCategoryBuckets': reviewCategoryBuckets"),
    );
    expect(
      stateActions,
      contains("'parserFieldConfidenceBuckets': fieldConfidenceBuckets"),
    );
    expect(
      stateActions.indexOf('_applyParsedReceipt(parsed);'),
      lessThan(stateActions.indexOf('void _applyParsedReceipt')),
    );
    expect(
      stateActions,
      contains("failureKind: 'receipt_review_apply_failed'"),
    );
    expect(
      stateActions,
      contains('receipt_ocr_result_could_not_apply_to_editable_review'),
    );
    expect(lineModels, contains('cameFromAppAssistedReceiptRead'));
    expect(lineEditorActions, contains('_parserReviewLabelForSavedLine'));
    expect(lineEditorActions, contains('_parserReviewReasonForSavedLine'));
    expect(lineEditorActions, contains("'Corrected'"));
    expect(lineEditorActions, contains("'Confirmed'"));
    expect(lineEditorActions, contains('parserNeedsReview: false'));
    expect(
      lineEditorActions,
      contains('User reviewed and corrected this app-filled receipt line.'),
    );
    expect(
      lineEditorActions,
      contains('User reviewed and confirmed this app-filled receipt line.'),
    );
    expect(lineFields, contains('Saving this line marks it reviewed.'));
    expect(stateActions, contains('void _recordAppFilledLineReviewTelemetry'));
    expect(
      stateActions,
      contains('ExpenseTelemetryEventType.appFilledReceiptLineCorrected'),
    );
    expect(
      stateActions,
      contains('ExpenseTelemetryEventType.appFilledReceiptLineConfirmed'),
    );
    expect(stateActions, contains("'lineUse': reviewed.use.name"));
    expect(stateActions, contains("'parserConfidenceBucket'"));
    expect(stateActions, contains('String _confidenceBucket'));
    expect(telemetry, contains('appFilledReceiptLineConfirmed'));
    expect(telemetry, contains('appFilledReceiptLineCorrected'));
    expect(telemetry, contains('appFilledReceiptLineConfirmedCount'));
    expect(telemetry, contains('appFilledReceiptLineCorrectedCount'));
    expect(telemetry, contains('appFilledReceiptLineCorrectionRate'));
    expect(
      lineModels,
      contains('rawReceiptText.trim().isNotEmpty || hasParserReview'),
    );
    expect(stateActions, contains('void _removeAppAssistedReceiptLines()'));
    expect(stateActions, contains('String? _primaryParsedReceiptWarning'));
    expect(stateActions, contains("lower.contains('missing')"));
    expect(stateActions, contains("lower.contains('could not')"));
    expect(stateActions, contains("lower.contains('low confidence')"));
    expect(
      stateActions,
      contains(
        '_lines.removeWhere((line) => line.cameFromAppAssistedReceiptRead)',
      ),
    );
    expect(
      stateActions.indexOf('_removeAppAssistedReceiptLines();'),
      lessThan(
        stateActions.indexOf(
          'for (var index = 0; index < parsed.lines.length; index++)',
        ),
      ),
    );
    expect(
      stateActions.indexOf('_scheduleDraftSave();'),
      lessThan(stateActions.indexOf('_scrollToReceiptReview();')),
    );
    expect(stateActions, contains('Split Receipt Line'));
    expect(stateActions, contains('25% Business'));
    expect(stateActions, contains('50% Business'));
    expect(stateActions, contains('75% Business'));
    expect(stateActions, contains('Custom Business %'));
    expect(photoControls, contains('_ReceiptPreviewActionTray'));
    expect(photoControls, contains('Use Receipt'));
    expect(photoControls, contains('receipt sections are saved locally'));
    expect(photoPreviewControls, contains('Add Bottom Section'));
    expect(photoPreviewControls, contains('minimumSize: const Size(0, 38)'));
    expect(photoPreviewControls, contains('BoxConstraints(maxWidth: 132)'));
    expect(photoPreviewControls, contains('message: label'));
    expect(photoPreviewControls, contains('strings.addAnotherReceiptPhoto'));
    expect(photoControls, contains('Check Photo Match'));
    expect(photoControls, contains('Use this photo'));
    expect(photoControls, contains("'Use Receipt'"));
    expect(entryScreen, contains("'legacyTapFocusSuppressedAfterZoomTotal'"));
    expect(entryScreen, isNot(contains("'tapFocusSuppressedAfterZoomTotal'")));
    expect(entryScreen, contains("'zoomGestureStartTotal'"));
    expect(entryScreen, contains("'zoomUnavailableTotal'"));
    expect(entryScreen, contains("'zoomStatusBuckets'"));
    expect(entryScreen, contains("'backDispatchPathBuckets'"));
    expect(entryScreen, contains("'preCaptureExposureAbortTotal'"));
    expect(entryScreen, contains("'preCaptureExposureAbortReasonBuckets'"));
    expect(entryScreen, contains("'closeRetryTotal'"));
    expect(entryScreen, contains('_ReceiptReadHandoffPanel('));
    expect(entryScreen, contains('_receiptReadHandoffProofCount'));
    expect(entryScreen, contains('_receiptReadHandoffOcrSourceCount'));
    expect(entryScreen, contains('_receiptReadHandoffDecision'));
    expect(entryScreen, contains('_receiptReadHandoffAction'));
    expect(entryScreen, contains('_receiptReadHandoffStage'));
    expect(entryScreen, contains('_receiptReadHandoffRouteResult'));
  });
}
