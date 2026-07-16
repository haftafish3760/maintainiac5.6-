import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  test('native camera shell does not darken the live preview heavily', () async {
    final shell = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_shell.dart',
    ).readAsString();
    final bottomControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_controls.dart',
    ).readAsString();
    final bottomBar = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_bottom_bar.dart',
    ).readAsString();
    final guidance =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_guidance.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_native_camera_shell_ghost_guidance.dart',
        ).readAsString();

    expect(bottomControls, contains('Color(0x30000000)'));
    expect(bottomControls, contains('Color(0x54000000)'));
    expect(bottomBar, isNot(contains('Color(0xB8050607)')));
    expect(guidance, contains('Color(0xB8050607)'));
    expect(bottomControls, contains('stops: [0, .16, .78, 1]'));
    expect(shell, isNot(contains('Color(0x52000000)')));
    expect(shell, isNot(contains('Color(0x76000000)')));
    expect(shell, isNot(contains('Color(0x9A000000)')));
    expect(shell, isNot(contains('Color(0xA6000000)')));
  });

  test('native camera review transition keeps captured photos moving forward', () async {
    final androidSource = await readAndroidReceiptCameraUnit();
    final iosSource = await readIosReceiptCameraUnit();
    final models = await readReceiptCaptureModelsSource();

    expect(
      androidSource,
      contains(
        'nativeCaptureReviewTransitionPolicy" to "captured_photos_must_open_review_then_receipt_details',
      ),
    );
    expect(
      androidSource,
      contains(
        'nativeCaptureReviewTransitionTarget" to "receipt_photo_review_next_to_receipt_details',
      ),
    );
    expect(
      androidSource,
      contains(
        'nativeCaptureReviewDiscardPolicy" to "never_discard_captured_photo_on_back',
      ),
    );
    expect(
      iosSource,
      contains(
        '"nativeCaptureReviewTransitionPolicy": "captured_photos_must_open_review_then_receipt_details"',
      ),
    );
    expect(
      iosSource,
      contains(
        '"nativeCaptureReviewTransitionTarget": "receipt_photo_review_next_to_receipt_details"',
      ),
    );
    expect(
      iosSource,
      contains(
        '"nativeCaptureReviewDiscardPolicy": "never_discard_captured_photo_on_back"',
      ),
    );
    expect(models, contains('native_capture_review_transition_ready'));
    expect(models, contains('native_capture_review_target_receipt_details'));
    expect(models, contains('native_capture_review_discard_protected'));
  });

  test(
    'interrupted native capture banner surfaces freshness and safe diagnostics',
    () async {
      final panel = await readReceiptAttachmentPanelSource();

      expect(panel, contains('record.recoveryFreshnessLabel()'));
      expect(panel, contains("'nativeRecoveryFreshness'"));
      expect(panel, contains("'nativeRecoveryStorageStatus'"));
      expect(panel, contains("'nativeRecoveryExistingPhotoCount'"));
      expect(panel, contains("'nativeRecoveryMissingPhotoCount'"));
      expect(panel, contains('record.privacySafeRecoveryEvidenceLabel'));
      expect(
        panel,
        contains(
          'Resume reviews the saved photos first; receipt details open from the saved proof after review.',
        ),
      );
      expect(
        panel,
        contains(
          'Retake the receipt photos, or discard this interrupted recovery copy.',
        ),
      );
      expect(panel, contains('discarded_no_receipt_details_handoff'));
      expect(panel, isNot(contains('receiptText')));
      expect(panel, isNot(contains('discarded_no_reader_handoff')));
    },
  );

  test('ocr source handoff helpers stay aligned across receipt paths', () async {
    final flow = await readReceiptCaptureFlowSource();
    final importActions = await readReceiptAttachmentImportActionsSource();
    final panelSignals = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_signals.dart',
    ).readAsString();
    final panelRisks = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_ocr_source_risk_flags.dart',
    ).readAsString();

    for (final token in const [
      'proof_data_saver_',
      'receipt_review_depth_',
      'native_recovery_',
      'native_recovery_recovered_photos',
      'native_recovery_multiple_sections',
      'native_camera_ui_health_available',
      'native_camera_ui_',
      'ocr_source_small_proof_copy_review_required',
      'ocr_source_proof_data_saver_',
      'ocr_source_native_recovery_',
      'ocr_source_native_recovery_multiple_sections',
      "code.contains('quality_guard')",
      "code.contains('decode_failed')",
      "code.contains('skipped')",
      'bool _isNativeCameraUiRisk(String value)',
    ]) {
      expect(flow, contains(token), reason: 'main flow missing $token');
      expect(
        importActions,
        contains(token),
        reason: 'import-action flow missing $token',
      );
    }
    for (final token in const [
      'native_recovery_freshness_',
      'native_recovery_storage_',
      'native_capture_source_health_available',
      'native_capture_source_',
      'ocr_source_native_capture_storage_saver',
      'ocr_source_native_capture_older_phone',
      'ocr_source_phone_camera_backup',
      "freshness == 'stale'",
      "storageStatus == 'partial_photos_available'",
    ]) {
      expect(flow, contains(token), reason: 'main flow missing $token');
    }
    for (final token in const [
      'native_recovery_freshness_',
      'native_recovery_storage_',
    ]) {
      expect(
        panelSignals,
        contains(token),
        reason: 'attachment panel signals missing $token',
      );
    }
    for (final token in const [
      "freshness == 'stale'",
      "storageStatus == 'partial_photos_available'",
    ]) {
      expect(
        panelRisks,
        contains(token),
        reason: 'attachment panel risks missing $token',
      );
    }
    final nativeStaging = await readReceiptNativeCaptureStagingSource();
    expect(nativeStaging, contains('resume_review_before_receipt_details'));
    expect(
      nativeStaging,
      contains('resume_review_keeps_photos_available_before_receipt_details'),
    );
    expect(nativeStaging, isNot(contains('before_receipt_read')));
    for (final token in const [
      'nativeCaptureSourcePolicyCounts',
      'nativeCaptureSourcePolicyOutcome',
      '_nativeCaptureSourcePoliciesFor',
    ]) {
      expect(
        await readReceiptCaptureModelsSource(),
        contains(token),
        reason: 'review result model missing $token',
      );
    }
  });

  test('add another photo carries partial receipt reason to ghost guide', () async {
    final actions =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_actions.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_guide.dart',
        ).readAsString();

    expect(actions, contains('alignmentGuidePhotoPath'));
    expect(actions, contains('_showLongReceiptAlignmentGuide'));
    expect(actions, contains('ReceiptImagePicker.takeReceiptPhotoSet'));
    expect(actions, contains('hadPreviousSectionGuide'));
    expect(actions, contains('Image.file'));
    expect(actions, contains('Add Another Receipt Photo'));
    expect(actions, isNot(contains('Add Bottom Receipt Section')));
    expect(actions, contains('coverageDecision.completionDialogMessage'));
    expect(actions, contains('next photo with 3-5 of the same readable lines'));
    expect(actions, contains('return to the numbered receipt review'));
  });
}
