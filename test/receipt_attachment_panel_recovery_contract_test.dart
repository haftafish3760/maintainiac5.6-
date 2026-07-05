import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt attachment panel has plain recovery states', () {
    final panelSource =
        _readReceiptSource('receipt_attachment_panel.dart') +
        _readReceiptSource('receipt_attachment_initial_state.dart') +
        _readReceiptSource('receipt_attachment_panel_build.dart') +
        _readReceiptSource('receipt_attachment_publish_helpers.dart') +
        _readReceiptSource('receipt_attachment_publish_signals.dart') +
        _readReceiptSource('receipt_attachment_recovery_actions.dart') +
        _readReceiptSource('receipt_attachment_status_widgets.dart') +
        _readReceiptSource('receipt_interrupted_capture_banner.dart');
    final importActions =
        _readReceiptSource('receipt_attachment_import_actions.dart') +
        _readReceiptSource('receipt_attachment_camera_actions.dart') +
        _readReceiptSource('receipt_attachment_review_read_actions.dart') +
        _readReceiptSource('receipt_attachment_text_document_actions.dart');
    final captureFlow =
        _readReceiptSource('receipt_capture_flow.dart') +
        _readReceiptSource('receipt_capture_flow_recovery.dart') +
        _readReceiptSource('receipt_capture_flow_recovery_results.dart');
    final stagingSource =
        _readReceiptSource('receipt_native_capture_staging.dart') +
        _readReceiptSource(
          'receipt_native_capture_staging_recovery_record.dart',
        );
    final ocrSource =
        _readReceiptSource('receipt_attachment_ocr_actions.dart') +
        _readReceiptSource('receipt_attachment_ocr_recovery_advice.dart');

    expect(panelSource, contains('_ReceiptReadStatusKind.failed'));
    expect(panelSource, contains('_normalizedInitialPhotoAttachments'));
    expect(panelSource, contains('final photoAttachments ='));
    expect(panelSource, contains('final path = attachment.path.trim();'));
    expect(panelSource, contains('path.isEmpty || !seenPaths.add(path)'));
    expect(panelSource, contains('attachment.copyWith(path: path)'));
    expect(panelSource, contains('_ReceiptReadStatusKind.warning'));
    expect(panelSource, contains('Receipt Could Not Be Read'));
    expect(
      panelSource,
      contains(
        'Use a clearer photo, use Add Receipt Photo for a long receipt, or keep the proof and fill the receipt by hand.',
      ),
    );
    expect(panelSource, contains('Receipt Ready For Review'));
    expect(panelSource, contains('Add Receipt Photo'));
    expect(panelSource, contains("'Reading Receipt'"));
    expect(panelSource, contains('_openingPicker || _readingForReview'));
    expect(
      ocrSource,
      contains(
        r'The app could not finish reading $sourceSummary before the review fields could be filled.',
      ),
    );
    expect(ocrSource, contains('_receiptReadRecoveryAdvice(readable)'));
    expect(ocrSource, contains('class _ReceiptReadRecoveryAdvice'));
    expect(ocrSource, contains('Receipt photo text was not readable enough.'));
    expect(ocrSource, contains('recoveryAdvice.primaryAction'));
    expect(ocrSource, contains('recoveryAdvice.shortAction'));
    expect(panelSource, contains('_ReceiptInterruptedCaptureBanner'));
    expect(panelSource, contains('_loadRecoverableNativeCaptures'));
    expect(panelSource, contains('recoverableNativeCaptures()'));
    expect(panelSource, contains('_resumeRecoverableNativeCapture'));
    expect(panelSource, contains('var _panelDisposed = false;'));
    expect(panelSource, contains('_panelDisposed = true;'));
    expect(
      panelSource,
      contains('bool updateAttachmentState(VoidCallback update)'),
    );
    expect(
      panelSource,
      contains('if (!mounted || _panelDisposed) return false;'),
    );
    expect(
      panelSource,
      contains(
        'if (!updateAttachmentState(() => _openingPicker = true)) return;',
      ),
    );
    expect(
      panelSource,
      contains('if (updateAttachmentState(() => _openingPicker = false))'),
    );
    expect(panelSource, contains('initialCaptureDiagnosticsByPath'));
    expect(captureFlow, contains('record.captureDiagnostics'));
    expect(captureFlow, contains('record.recoverablePhotoPaths'));
    expect(captureFlow, contains('File(path).existsSync()'));
    expect(captureFlow, contains('if (photoPaths.isEmpty)'));
    expect(captureFlow, contains('stage: \'native_capture_recovery\''));
    expect(captureFlow, contains('reason: \'recovery_photos_missing\''));
    expect(captureFlow, contains('action: \'retake_receipt_photos\''));
    expect(captureFlow, contains('nativeRecoveryResumeStatus'));
    expect(captureFlow, contains('resume_review_started'));
    expect(captureFlow, contains('nativeRecoveryRecoveredPhotoCount'));
    expect(captureFlow, contains('nativeRecoveryMultipleSections'));
    expect(
      panelSource,
      contains('final accepted = await _acceptReviewedPhotoResult('),
    );
    expect(
      panelSource,
      contains(
        'if (accepted && result.recoveryManifestPath.trim().isNotEmpty)',
      ),
    );
    expect(
      panelSource,
      contains('ReceiptNativeCaptureStaging().clearRecoveryManifestPath('),
    );
    expect(captureFlow, contains('reason: \'recovery_review_accepted\''));
    expect(
      captureFlow,
      contains('action: \'open_filled_review_or_save_proof\''),
    );
    expect(captureFlow, contains('nativeRecoveryAcceptedPhotoCount'));
    expect(captureFlow, contains('nativeRecoveryAcceptedMultipleSections'));
    expect(captureFlow, contains('nativeRecoveryOutcome'));
    expect(
      captureFlow,
      contains('recovery_review_accepted_for_receipt_details'),
    );
    expect(captureFlow, contains('nativeRecoveryUserNextStep'));
    expect(captureFlow, contains('nativeRecoveryResumeOutcome'));
    expect(captureFlow, contains('nativeRecoveryResumeOutcomeLabel'));
    expect(captureFlow, contains('nativeRecoveryEvidence'));
    expect(captureFlow, contains('reason: \'recovery_review_closed\''));
    expect(captureFlow, contains('action: \'kept_recovery_for_later_resume\''));
    expect(captureFlow, contains('nativeRecoveryKeptPhotoCount'));
    expect(captureFlow, contains('nativeRecoveryKeptMultipleSections'));
    expect(
      captureFlow,
      contains(
        'Those saved receipt photos are no longer on this device. Take the receipt photos again.',
      ),
    );
    expect(captureFlow, contains('record.recoverablePhotoPaths'));
    expect(captureFlow, contains('_existingUniqueRecoveryPhotoPaths'));
    expect(captureFlow, contains('_recoveryDiagnosticsByPhotoPath'));
    expect(captureFlow, contains('seen.add(path)'));
    expect(captureFlow, contains('File(path).existsSync()'));
    expect(captureFlow, isNot(contains('path: recoveryDiagnostics')));
    expect(panelSource, contains('Resume Interrupted Receipt Photos'));
    expect(panelSource, contains('were saved locally before review finished'));
    expect(panelSource, contains('record.recoveryResumeStatusLabel'));
    expect(panelSource, contains('record.recoveryResumeActionLabel'));
    expect(panelSource, contains('record.recoveryResumeActionDetail'));
    expect(panelSource, contains('record.hasCompleteLocalRecovery'));
    expect(panelSource, contains('recovered_review_screen_unavailable'));
    expect(panelSource, contains('recovery_review_unavailable_kept'));
    expect(
      panelSource,
      contains(
        'Recovered receipt photo review did not open. Resume these saved photos again, or retake the receipt photos.',
      ),
    );
    expect(
      stagingSource,
      contains('tap Next to open receipt details from the saved proof'),
    );
    expect(panelSource, contains('record.recoveredCountLabel'));
    expect(panelSource, contains('discardRecoveryRecord(record)'));
    expect(panelSource, contains('reason: \'user_discarded_recovery\''));
    expect(
      panelSource,
      contains('action: \'discarded_interrupted_receipt_photos\''),
    );
    expect(panelSource, contains('nativeRecoveryDiscardedPhotoCount'));
    expect(panelSource, contains('nativeRecoveryDiscardedMultipleSections'));
    expect(panelSource, contains('recovery_discarded_by_user'));
    expect(panelSource, contains('discarded_no_receipt_details_handoff'));
    expect(panelSource, contains('record.recoveryResumeOutcomeCode'));
    expect(panelSource, contains('record.recoveryResumeOutcomeLabel'));
    expect(panelSource, contains('privacySafeRecoveryEvidenceLabel'));
    expect(stagingSource, contains('Discard only if these saved photos'));
    expect(panelSource, contains("label: const Text('Discard')"));
    expect(panelSource, contains('void showPickerError(String message)'));
    expect(panelSource, contains('void showPickerMessage(String message)'));
    expect(panelSource, contains('if (!mounted) return;'));
    expect(importActions, contains('Future<bool> reviewPickedPhotoPaths'));
    expect(importActions, contains('..._photoCaptureDiagnosticsByPath'));
    expect(importActions, contains('...initialCaptureDiagnosticsByPath'));
    expect(importActions, contains('review_screen_unavailable'));
    expect(
      importActions,
      contains(
        'Receipt photo review did not open. Try Capture Receipt Photo again, or choose an existing receipt image instead.',
      ),
    );
    expect(importActions, contains('return true;'));
    expect(importActions, contains('return false;'));
  });
}

String _readReceiptSource(String fileName) {
  return File(
    'lib/shared/widgets/receipt_capture/$fileName',
  ).readAsStringSync();
}
