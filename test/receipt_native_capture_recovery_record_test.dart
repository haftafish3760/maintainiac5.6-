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
            'small_local_proof_temporary_source_for_ocr_then_cleanup',
        'cameraWorkloadTier': 'light',
        'latestCapturedExposureMismatch': 'live_ok_capture_dim',
        'assistedReceiptFill': true,
        'receiptText': 'PRIVATE RECEIPT TEXT',
      },
    );

    expect(record.recoveredPhotoCount, 2);
    expect(record.assistedReceiptFillAtCapture, isTrue);
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
      contains(
        'memoryPolicy=small_local_proof_temporary_source_for_ocr_then_cleanup',
      ),
    );
    expect(record.recoveryResumeDetail, isNot(contains('PRIVATE')));
    expect(record.privacySafeRecoveryEvidenceLabel, isNot(contains('PRIVATE')));
  });

  test('recovery record restores saved Receipt Assist choice', () {
    final enabled = ReceiptNativeCaptureRecoveryRecord.fromManifest(
      '/tmp/native-recovery-enabled.json',
      {
        'sessionId': 'enabled',
        'engine': 'cameraX',
        'capturedAt': '2026-07-06T04:00:00.000Z',
        'dataSaverLevel': 'balanced',
        'stagedPhotoPaths': ['/tmp/top.jpg'],
        'captureDiagnostics': {'assistedReceiptFill': true},
      },
    );
    final disabled = ReceiptNativeCaptureRecoveryRecord.fromManifest(
      '/tmp/native-recovery-disabled.json',
      {
        'sessionId': 'disabled',
        'engine': 'cameraX',
        'capturedAt': '2026-07-06T04:00:00.000Z',
        'dataSaverLevel': 'balanced',
        'stagedPhotoPaths': ['/tmp/top.jpg'],
        'captureDiagnostics': {'assistedReceiptFill': 'false'},
      },
    );
    final missing = ReceiptNativeCaptureRecoveryRecord.fromManifest(
      '/tmp/native-recovery-missing.json',
      {
        'sessionId': 'missing',
        'engine': 'cameraX',
        'capturedAt': '2026-07-06T04:00:00.000Z',
        'dataSaverLevel': 'balanced',
        'stagedPhotoPaths': ['/tmp/top.jpg'],
        'captureDiagnostics': const <String, Object?>{},
      },
    );

    expect(enabled.assistedReceiptFillAtCapture, isTrue);
    expect(disabled.assistedReceiptFillAtCapture, isFalse);
    expect(missing.assistedReceiptFillAtCapture, isNull);
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

  test('recovery manifest normalizes staged and attachment photo paths', () {
    final record = ReceiptNativeCaptureRecoveryRecord.fromManifest(
      '/tmp/native-recovery.json',
      {
        'sessionId': 'native-session',
        'engine': ' cameraX ',
        'capturedAt': DateTime(2026, 6, 28, 16).toIso8601String(),
        'dataSaverLevel': ' balanced ',
        'stagedPhotoPaths': [
          ' /tmp/section-one.jpg ',
          '/tmp/section-one.jpg',
          ' /tmp/section-two.jpg ',
        ],
        'attachments': [
          {
            'id': 'attachment-only-photo',
            'path': ' /tmp/attachment-fallback.jpg ',
            'kind': ' photo ',
            'dataSaverLevel': ' balanced ',
            'createdAt': DateTime(2026, 6, 28, 16).toIso8601String(),
          },
        ],
      },
    );
    final attachmentOnly = ReceiptNativeCaptureRecoveryRecord.fromManifest(
      '/tmp/native-attachment-recovery.json',
      {
        'stagedPhotoPaths': const [],
        'attachments': [
          {
            'id': 'attachment-only-photo',
            'path': ' /tmp/attachment-fallback.jpg ',
            'kind': ' photo ',
            'createdAt': DateTime(2026, 6, 28, 16).toIso8601String(),
          },
        ],
      },
    );

    expect(record.stagedPhotoPaths, [
      '/tmp/section-one.jpg',
      '/tmp/section-two.jpg',
    ]);
    expect(record.recoveredPhotoCount, 2);
    expect(record.recoveredCountLabel, '2 ordered receipt sections');
    expect(attachmentOnly.recoverablePhotoPaths, [
      '/tmp/attachment-fallback.jpg',
    ]);
  });
}
