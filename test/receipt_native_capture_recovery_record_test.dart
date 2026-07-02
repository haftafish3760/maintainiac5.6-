import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_staging.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recovery record explains resume context without receipt content', () {
    final record = ReceiptNativeCaptureRecoveryRecord(
      manifestPath: '/tmp/recovery.json',
      sessionId: 'native-session',
      engine: ReceiptNativeCameraEngine.cameraX,
      capturedAt: DateTime(2026, 6, 28, 15),
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stagedPhotoPaths: const ['/tmp/section-one.jpg', '/tmp/section-two.jpg'],
      attachments: const [],
      captureDiagnostics: const {
        'closeAction': 'back_returned_captured_sections',
        'storageSafetyLevel': 'strong',
        'maxLocalPhotoBytes': 6291456,
        'nativeCaptureMemoryPolicy':
            'small_local_proof_original_for_ocr_then_cleanup',
        'cameraWorkloadTier': 'light',
        'latestCapturedExposureMismatch': 'live_ok_capture_dim',
        'receiptText': 'PRIVATE RECEIPT TEXT',
      },
    );

    expect(record.recoveredPhotoCount, 2);
    expect(record.recoveryAge(now: DateTime(2026, 6, 29, 15)).inHours, 24);
    expect(
      record.recoveryFreshnessBucket(now: DateTime(2026, 6, 28, 20)),
      'fresh',
    );
    expect(
      record.recoveryFreshnessBucket(now: DateTime(2026, 6, 30, 15)),
      'aging',
    );
    expect(
      record.recoveryFreshnessBucket(now: DateTime(2026, 7, 3, 15)),
      'stale',
    );
    expect(
      record.recoveryFreshnessBucket(now: DateTime(2026, 7, 6, 15)),
      'very_stale',
    );
    expect(
      record.recoveryFreshnessLabel(now: DateTime(2026, 6, 28, 20)),
      'Recently saved',
    );
    expect(
      record.recoveryFreshnessLabel(now: DateTime(2026, 6, 30, 15)),
      'Saved earlier',
    );
    expect(
      record.recoveryFreshnessLabel(now: DateTime(2026, 7, 3, 15)),
      'Older saved receipt',
    );
    expect(
      record.recoveryFreshnessLabel(now: DateTime(2026, 7, 6, 15)),
      'Very old saved receipt',
    );
    expect(record.existingPhotoCount, 0);
    expect(record.missingPhotoCount, 2);
    expect(record.hasCompleteLocalRecovery, isFalse);
    expect(record.recoveryStorageStatus, 'photos_missing');
    expect(record.recoveryResumeOutcomeCode, 'photos_missing');
    expect(
      record.recoveryResumeOutcomeLabel,
      'Saved receipt photos are missing from this device and must be retaken.',
    );
    expect(record.recoveryResumeStatusLabel, 'Photos missing');
    expect(record.recoveryResumeActionLabel, 'Retake receipt photos');
    expect(
      record.recoveryResumeActionDetail,
      'The saved files are no longer on this device. Take the receipt photos again.',
    );
    expect(record.hasMultipleReceiptSections, isTrue);
    expect(record.recoveredCountLabel, '2 ordered receipt sections');
    expect(
      record.recoveryCloseActionLabel,
      'Back was pressed after photos were captured.',
    );
    expect(
      record.recoveryResumeDetail,
      'Back was pressed after photos were captured. Resume keeps the top-to-bottom order for review.',
    );
    expect(record.recoveryNextActionLabel, 'Review saved receipt sections');
    expect(
      record.recoveryNextActionDetail,
      'Resume to review the saved sections in order, then tap Next to open receipt details from the saved proof. Discard only if these saved photos are not needed.',
    );
    expect(record.privacySafeRecoveryEvidenceLabel, contains('freshness='));
    expect(
      record.privacySafeRecoveryEvidenceLabel,
      contains('resumeOutcome=photos_missing'),
    );
    expect(
      record.privacySafeRecoveryEvidenceLabel,
      contains('maxLocalPhotoBytes=6291456'),
    );
    expect(
      record.privacySafeRecoveryEvidenceLabel,
      contains('memoryPolicy=small_local_proof_original_for_ocr_then_cleanup'),
    );
    expect(record.recoveryResumeDetail, isNot(contains('PRIVATE')));
    expect(record.privacySafeRecoveryEvidenceLabel, isNot(contains('PRIVATE')));
  });

  test('recovery record falls back to attachment paths for resume', () async {
    final photo = File(
      '${Directory.systemTemp.path}/native-attachment-only.jpg',
    );
    await photo.writeAsBytes(List<int>.filled(64, 12), flush: true);
    addTearDown(() {
      if (photo.existsSync()) photo.deleteSync();
    });
    final record = ReceiptNativeCaptureRecoveryRecord(
      manifestPath: '/tmp/attachment-only-recovery.json',
      sessionId: 'attachment-only',
      engine: ReceiptNativeCameraEngine.cameraX,
      capturedAt: DateTime(2026, 6, 28, 16),
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stagedPhotoPaths: const [],
      attachments: [
        ReceiptAttachmentRecord(
          id: 'attachment-only-photo',
          path: photo.path,
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 6, 28, 16),
        ),
      ],
      captureDiagnostics: const {
        'closeAction': 'done_returned_captured_sections',
      },
    );

    expect(record.recoverablePhotoPaths, [photo.path]);
    expect(record.recoveredPhotoCount, 1);
    expect(record.hasExistingPhotos, isTrue);
    expect(record.recoveredCountLabel, '1 receipt photo');
  });
}
