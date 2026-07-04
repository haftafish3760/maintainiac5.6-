import 'package:flutter_test/flutter_test.dart';

void expectNativeCaptureRecoverySafety(Map manifest) {
  expect(
    (manifest['captureDiagnostics'] as Map).containsKey('receiptText'),
    isFalse,
  );
  expect(
    (manifest['recoverySafety'] as Map)['schema'],
    'native_capture_recovery_safety_v1',
  );
  expect((manifest['recoverySafety'] as Map)['manifestBacked'], isTrue);
  expect((manifest['recoverySafety'] as Map)['hiveIndexSaved'], isTrue);
  expect((manifest['recoverySafety'] as Map)['localStagedPhotoCount'], 1);
  expect((manifest['recoverySafety'] as Map)['localExistingPhotoCount'], 1);
  expect((manifest['recoverySafety'] as Map)['allLocalPhotosExist'], isTrue);
  expect(
    (manifest['recoverySafety'] as Map)['privacyScope'],
    'summary_only_no_receipt_content',
  );
  expect(
    (manifest['recoverySafety'] as Map)['contentPolicy'],
    'no_receipt_text_no_customer_content',
  );
  expect(
    (manifest['recoverySafety'] as Map)['attachmentState'],
    'staged_not_attached_until_user_accepts',
  );
  expect(
    (manifest['recoverySafety'] as Map)['resumeAction'],
    'resume_review_before_receipt_details',
  );
  expect(
    (manifest['recoverySafety'] as Map)['resumeCheckpoint'],
    'after_native_capture_before_ocr',
  );
  expect(
    (manifest['recoverySafety'] as Map)['ocrSourcePolicy'],
    'temporary_full_quality_staged_photo_used_before_data_saver_copy',
  );
  expect(
    (manifest['recoverySafety'] as Map)['cleanupPolicy'],
    'discard_only_after_accept_or_user_discard_or_old_cleanup',
  );
  expect(
    (manifest['recoverySafety'] as Map)['writeOrder'],
    'copy_photo_then_manifest_then_hive_index',
  );
  expect(
    (manifest['recoverySafety'] as Map)['interruptionGuarantee'],
    'resume_review_keeps_photos_available_before_receipt_details',
  );
  expect(
    (manifest['recoverySafety'] as Map)['coveredInterruptions'],
    containsAll([
      'app_backgrounded_after_capture',
      'phone_call_after_capture',
      'camera_closed_before_review',
      'review_closed_before_attach',
    ]),
  );
  expect(
    (manifest['recoverySafety'] as Map)['userSafeExit'],
    'local_recovery_kept_until_accept_or_discard',
  );
  expect((manifest['privacy'] as Map)['storesReceiptText'], isFalse);
  expect((manifest['privacy'] as Map)['storesReceiptImageContent'], isFalse);
  expect((manifest['privacy'] as Map)['storesCustomerContent'], isFalse);
  expect(manifest.toString(), isNot(contains('LOWE')));
  expect(manifest.toString(), isNot(contains('receiptText')));
}
