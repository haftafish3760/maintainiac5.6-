import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepted shared flow clears interrupted native recovery after attach', () async {
    final flow =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_recovery.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_recovery_results.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_helpers.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_continuation_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_native_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_capture_and_review.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_review_result.dart',
        ).readAsString();
    final actions =
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
          'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_continuation_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_native_signal_documents.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_attachment_native_signal_helpers.dart',
        ).readAsString();
    final models = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_models.dart',
    ).readAsString();
    expect(flow, contains('recoveryManifestPath: staged.recoveryManifestPath'));
    expect(
      flow,
      contains(
        'if (!context.mounted) return ReceiptCaptureFlowResult.canceled();\n'
        '  if (!capture.hasPhotos)',
      ),
    );
    expect(flow, contains("reason: 'review_context_closed_after_staging'"));
    expect(flow, contains("action: 'keep_staged_receipt_for_recovery'"));
    expect(flow, contains("stage: 'review_opening'"));
    expect(flow, contains("stage: 'review_accepted'"));
    expect(flow, contains('_previousSectionGuideDiagnostics(options)'));
    expect(flow, contains('previousSectionGuideRequested'));
    expect(flow, contains('previousSectionGuidePhotoAvailable'));
    expect(flow, contains('previousSectionMissingBottomAndTotals'));
    expect(flow, contains('receiptContinuationSource'));
    expect(flow, contains('ocr_missing_bottom_totals'));
    expect(flow, contains('receiptContinuationGhostGuideStatus'));
    expect(flow, contains('ready_with_previous_photo'));
    expect(flow, contains('previousSectionGhostGuidePolicy'));
    expect(flow, contains('_receiptContinuationHandoffDocumentSignalsFor'));
    expect(flow, contains('_receiptContinuationHandoffRiskFlagsFor'));
    expect(flow, contains('_receiptCoverageDecisionDocumentSignalsFor'));
    expect(flow, contains('receipt_coverage_evidence_'));
    expect(flow, contains('decision.evidenceContractCode'));
    expect(flow, contains('receipt_coverage_rationale_'));
    expect(flow, contains('decision.evidenceRationaleCode'));
    expect(
      flow,
      contains('receipt_coverage_bottom_edge_and_totals_missing_together'),
    );
    expect(flow, contains('_receiptCompletionHandoffDocumentSignalsFor'));
    expect(flow, contains('_receiptCompletionHandoffRiskFlagsFor'));
    expect(flow, contains('_ocrSourceContinuationDocumentSignalsFor'));
    expect(flow, contains('_ocrSourceContinuationRiskFlagsFor'));
    expect(flow, contains('receipt_continuation_handoff_'));
    expect(flow, contains('receipt_continuation_ocr_missing_bottom_totals'));
    expect(
      flow,
      contains('receipt_continuation_missing_bottom_edge_and_totals'),
    );
    expect(flow, contains('receipt_continuation_ghost_policy_'));
    expect(
      flow,
      contains('ocr_source_continuation_missing_bottom_totals_review'),
    );
    expect(
      flow,
      contains('ocr_source_continuation_bottom_overlap_ghost_policy'),
    );
    expect(
      flow,
      contains('ocr_source_continuation_ocr_requested_bottom_section_review'),
    );
    expect(flow, contains('receipt_completion_'));
    expect(flow, contains('ocr_source_completion_continue_anyway_review'));
    expect(flow, contains('nativeRecoveryLastStage'));
    expect(flow, contains('nativeRecoveryReviewAccepted'));
    expect(flow, contains('nativeRecoveryOcrPending'));
    expect(flow, contains('nativeRecoveryOcrSourcePhotoCount'));
    expect(flow, contains('_withReviewOpeningDiagnostics'));
    expect(flow, contains("route: 'native_capture_to_photo_review'"));
    expect(flow, contains("route: 'native_recovery_to_photo_review'"));
    expect(flow, contains("'receiptReviewOpeningPolicy':"));
    expect(flow, contains("'open_photo_review_before_ocr_or_receipt_form'"));
    expect(flow, contains("'receiptReviewOpeningExpectedFirstAction':"));
    expect(flow, contains("'next_or_add_photo_visible_before_scroll'"));
    expect(actions, contains('_clearAcceptedNativeRecovery(flowResult)'));
    expect(
      actions,
      contains(
        'if (!mounted) return _MaintainiacNativeCameraPhotoOutcome.canceled;',
      ),
    );
    expect(
      actions,
      contains('if (!result.accepted || result.reviewResult == null) return;'),
    );
    expect(
      actions,
      contains(
        'review.photoPaths.isEmpty || review.ocrSourcePhotoPaths.isEmpty',
      ),
    );
    expect(actions, contains('clearRecoveryManifestPath'));
    expect(models, contains('usedSavedProofAsOcrSourceFallback'));
    expect(flow, contains('receipt_handoff_ocr_source_fallback_saved_proof'));
    expect(
      actions,
      contains('receipt_handoff_ocr_source_fallback_saved_proof'),
    );
    expect(actions, contains('receiptCompletionHandoffDocumentSignalsFor'));
    expect(actions, contains('receiptCompletionHandoffRiskFlagsFor'));
    expect(actions, contains('receiptCoverageDecisionDocumentSignalsFor'));
    expect(actions, contains('receipt_coverage_evidence_'));
    expect(actions, contains('decision.evidenceContractCode'));
    expect(actions, contains('receipt_coverage_rationale_'));
    expect(actions, contains('decision.evidenceRationaleCode'));
    expect(
      actions,
      contains('receipt_coverage_bottom_edge_and_totals_missing_together'),
    );
    expect(actions, contains('receipt_completion_'));
    expect(actions, contains('ocr_source_completion_continue_anyway_review'));
    expect(flow, contains('ocr_source_fallback_saved_proof_review_required'));
    expect(
      actions,
      contains('ocr_source_fallback_saved_proof_review_required'),
    );
    expect(
      actions.indexOf(
        'final accepted = await _acceptReviewedPhotoResult(result)',
      ),
      lessThan(
        actions.indexOf('await _clearAcceptedNativeRecovery(flowResult)'),
      ),
    );
    expect(actions, contains('if (!accepted || !mounted)'));
  });

  test('shared flow exposes reusable interrupted capture review recovery', () async {
    final flow =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_recovery.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_recovery_results.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_handoff_risks.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_native_signals.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_capture_and_review.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_capture_flow_review_result.dart',
        ).readAsString();
    expect(flow, contains('reviewRecoveredCapture('));
    expect(flow, contains('ReceiptNativeCaptureRecoveryRecord record'));
    expect(flow, contains('record.recoverablePhotoPaths'));
    expect(flow, contains('File(photoPath).existsSync()'));
    expect(flow, contains('discardRecoveryRecord(record)'));
    expect(
      flow,
      contains(
        'No receipt photo was added. Tap Take Receipt Photo again, or choose an existing receipt image.',
      ),
    );
    expect(flow, contains('retry_or_import_existing_photo'));
    expect(flow, contains('nativeCaptureOutcome'));
    expect(flow, contains('nativeCaptureFallbackPolicy'));
    expect(flow, contains('user_canceled_without_photo'));
    expect(flow, contains('native_camera_open_failed'));
    expect(flow, contains('native_camera_returned_no_photo'));
    expect(flow, contains('open_backup_or_import'));
    expect(flow, contains('offer_retry_or_import'));
    expect(
      flow,
      contains('retry_receipt_photo_or_import_existing_receipt_image'),
    );
    expect(flow, contains('use_phone_camera_backup_or_import_existing_photo'));
    expect(flow, contains("reason: 'recovery_photos_missing'"));
    expect(flow, contains('recovery_review_interrupted_kept'));
    expect(flow, contains('recovery_review_closed_kept'));
    expect(flow, contains('review_closed_kept_for_later'));
    expect(flow, contains('recovery_review_closed_kept_for_later'));
    expect(flow, contains('resume_saved_receipt_photo_review'));
    expect(flow, contains('reviewResult.keptForLater'));
    expect(flow, contains('recovery_review_accepted_for_receipt_details'));
    expect(flow, contains('nativeRecoveryResumeOutcomeLabel'));
    expect(flow, contains('ReceiptPhotoReviewScreen('));
    expect(flow, contains('initialDataSaverLevel:'));
    expect(flow, contains('options.initialDataSaverLevel ??'));
    expect(flow, contains('record.dataSaverLevel'));
    expect(flow, contains('nativeRecoveryResumeStatus'));
    expect(flow, contains('nativeRecoveryResumeSource'));
    expect(flow, contains('nativeRecoveryResumeRoute'));
    expect(flow, contains('nativeRecoveryRecoveredPhotoCount'));
    expect(flow, contains("stage: 'recovery_review_opening'"));
    expect(flow, contains("stage: 'recovery_review_closed'"));
    expect(flow, contains("stage: 'recovery_review_accepted'"));
    expect(
      flow,
      contains("action: 'open_receipt_photo_review_before_receipt_details'"),
    );
    expect(flow, contains("action: 'open_filled_review_or_save_proof'"));
    expect(flow, contains('native_recovery_recovered_photos'));
    expect(flow, contains('native_recovery_multiple_sections'));
    expect(flow, contains('receipt_match_readiness_'));
    expect(flow, contains('ocr_source_native_recovery_'));
    expect(flow, contains('ocr_source_match_readiness_'));
    expect(flow, contains('ocr_source_native_recovery_multiple_sections'));
    expect(flow, contains('review_photo_edited'));
    expect(flow, contains(r'review_photo_edit_$editAction'));
    expect(flow, contains('review_photo_edit_source_selected'));
    expect(flow, contains(r'review_photo_edit_source_selected_$editAction'));
    expect(flow, contains('review_photo_edit_replaced_original'));
    expect(flow, contains(r'review_photo_edit_replaced_original_$editAction'));
    expect(flow, contains('ocr_source_review_photo_edited'));
    expect(flow, contains(r'ocr_source_review_photo_edit_$editAction'));
    expect(flow, contains('ocr_source_review_photo_edit_source_selected'));
    expect(
      flow,
      contains(r'ocr_source_review_photo_edit_source_selected_$editAction'),
    );
    expect(flow, contains('ocr_source_review_photo_edit_replaced_original'));
    expect(
      flow,
      contains(r'ocr_source_review_photo_edit_replaced_original_$editAction'),
    );
    expect(flow, contains('nativeRecoveryEvidence'));
    expect(flow, contains('nativeRecoveryFreshness'));
    expect(flow, contains("reason: 'recovery_review_closed'"));
    expect(flow, contains("reason: 'recovery_review_closed_kept_for_later'"));
    expect(flow, contains("'receiptReviewKeptForLater': true"));
    expect(flow, contains("action: 'kept_recovery_for_later_resume'"));
    expect(flow, contains("action: 'resume_saved_receipt_photo_review'"));
    expect(flow, contains("reason: 'recovery_review_accepted'"));
    expect(
      flow,
      isNot(contains('cleared_recovery_after_receipt_photos_sent_to_reader')),
    );
    expect(
      flow.indexOf("reason: 'recovery_review_closed'"),
      lessThan(flow.indexOf("reason: 'recovery_review_accepted'")),
    );
  });
}
