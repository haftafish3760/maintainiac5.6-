import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_staging.dart';

Future<void> expectAcceptedNativeCaptureStagingBasics(
  ReceiptNativeCaptureStagingResult staged, {
  required File source,
}) async {
  final diagnostics =
      staged.captureDiagnosticsByPhotoPath[staged.photoPaths.single]!;
  expect(staged.hasPhotos, isTrue);
  expect(staged.photoPaths, hasLength(1));
  expect(staged.photoPaths.single, isNot(source.path));
  expect(staged.photoPaths.single, contains('receipt_proofs_staging'));
  expect(await File(staged.photoPaths.single).exists(), isTrue);
  expect(staged.recoveryManifestPath, contains('native_capture_recovery'));
  expect(await File(staged.recoveryManifestPath).exists(), isTrue);
  expect(await source.exists(), isTrue);
  expect(staged.originalToStagedPath[source.path], staged.photoPaths.single);
  expect(diagnostics['nativeCapturePersistedLocally'], isTrue);
  expect(diagnostics['nativeCaptureStage'], 'staged_for_receipt_review');
  expect(
    diagnostics['nativeCaptureRecoveryPrivacyScope'],
    'summary_only_no_receipt_content',
  );
  expect(
    diagnostics['nativeCaptureRecoveryContentPolicy'],
    'no_receipt_text_no_customer_content',
  );
  expect(
    diagnostics['nativeCaptureRecoveryAttachmentState'],
    'staged_not_attached',
  );
  expect(
    diagnostics['nativeCaptureRecoveryResumeAction'],
    'resume_review_before_receipt_details',
  );
  expect(
    diagnostics['nativeCaptureRecoveryResumeCheckpoint'],
    'after_native_capture_before_ocr',
  );
  expect(
    diagnostics['nativeCaptureRecoveryOcrSourcePolicy'],
    'original_staged_photo_used_before_data_saver_copy',
  );
  expect(
    diagnostics['nativeCaptureRecoveryCleanupPolicy'],
    'discard_only_after_accept_or_user_discard_or_old_cleanup',
  );
  expect(
    diagnostics['nativeCaptureRecoveryWriteOrder'],
    'copy_photo_then_manifest_then_hive_index',
  );
  expect(
    diagnostics['nativeCaptureRecoveryUserSafeExit'],
    'leave_without_attaching_keeps_local_recovery',
  );
  expect(
    diagnostics['nativeCaptureRecoveryCoveredInterruptions'],
    containsAll([
      'app_backgrounded_after_capture',
      'phone_call_after_capture',
      'camera_closed_before_review',
      'review_closed_before_attach',
    ]),
  );
  expect(diagnostics['nativeCaptureStagedPhotoIndex'], 0);
  expect(diagnostics['nativeCaptureStagedPhotoNumber'], 1);
  expect(diagnostics['nativeCaptureStagedPhotoCount'], 1);
  expect(diagnostics['nativeCaptureRecoveryManifestCreated'], isTrue);
  expect(diagnostics['nativeCaptureAttachmentStorageState'], 'staged');
  expect(diagnostics['nativeCaptureAttachmentKind'], 'photo');
  expect(
    diagnostics['nativeCaptureDataSaverLevel'],
    ReceiptDataSaverLevel.strong.name,
  );
  expect(diagnostics['visibleControlSet'], contains('manual_shutter'));
  expect(
    diagnostics['previewDominanceTarget'],
    'receipt_preview_75_80_percent',
  );
  expect(diagnostics['nativeCaptureByteSizeBucket'], 'tiny_under_100kb');
  expect(diagnostics['nativeCaptureHashPresent'], isTrue);
  expect(diagnostics['latestCapturedPhotoWidth'], 3024);
  expect(diagnostics['deviceTier'], 'heavyweight');
  expect(diagnostics['devicePolicyLabel'], 'flagship_receipt_camera');
  expect(
    diagnostics['cloudAssistPlan'],
    'local_ocr_cloud_ocr_cloud_inventory_optional',
  );
  expect(diagnostics['ocrDecisionPolicy'], 'local_default_cloud_optional');
  expect(diagnostics['localOcrAvailable'], isTrue);
  expect(diagnostics['localOcrMode'], 'lean_local_ocr');
  expect(diagnostics['localOcrDefault'], isTrue);
  expect(diagnostics['parserDepth'], 'inventoryMatching');
  expect(diagnostics['localParserScope'], 'inventory_matching_local');
  expect(diagnostics['cloudOcrOptional'], isTrue);
  expect(diagnostics['cloudInventoryOptional'], isTrue);
  expect(diagnostics['cloudAssistRequiresExplicitChoice'], isTrue);
  expect(diagnostics['cloudAssistRequiresInternet'], isTrue);
  expect(diagnostics['cameraCaptureCloudRequired'], isFalse);
  expect(diagnostics['receiptReviewCloudRequired'], isFalse);
  expect(diagnostics['localCatalogMatchLimit'], 250);
  expect(diagnostics['localInventoryCacheLimit'], 1000);
  expect(diagnostics['capabilityPolicyCodes'], [
    'storage_constrained_small_proofs',
    'heavy_cleanup_policy_limited',
  ]);
}
