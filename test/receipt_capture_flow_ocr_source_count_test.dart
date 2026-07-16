import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_flow.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('attachments use OCR source count instead of saved proof count', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const [
        '/tmp/proof-section-1.jpg',
        '/tmp/proof-section-2.jpg',
        '/tmp/proof-section-3.jpg',
      ],
      ocrSourcePhotoPaths: const ['/tmp/stitched-ocr-source.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.strong,
      stitchResult: ReceiptStitchResult(
        status: ReceiptStitchStatus.stitched,
        inputPaths: [
          '/tmp/proof-section-1.jpg',
          '/tmp/proof-section-2.jpg',
          '/tmp/proof-section-3.jpg',
        ],
        ocrSourcePaths: ['/tmp/stitched-ocr-source.jpg'],
        stitchedPath: '/tmp/stitched-ocr-source.jpg',
      ),
      preparationDiagnosticsByOcrPath: const {
        '/tmp/stitched-ocr-source.jpg': {
          'ocrSourcePath': '/tmp/stitched-ocr-source.jpg',
          'scannerDecisionCodes': [
            'ocr_source_full_quality_selected_quality_guard',
          ],
        },
      },
      photoQualityChecksByPath: const {
        '/tmp/proof-section-1.jpg': ReceiptPhotoQualityCheck(
          width: 1200,
          height: 3200,
          focusScore: 3,
          brightness: 48,
          contrast: 18,
          cropScore: .52,
          textBandScore: 8,
          isLikelyReadable: false,
        ),
        '/tmp/proof-section-2.jpg': ReceiptPhotoQualityCheck(
          width: 1200,
          height: 3200,
          focusScore: 6,
          brightness: 118,
          contrast: 24,
          cropScore: .71,
          textBandScore: 12,
          isLikelyReadable: true,
        ),
        '/tmp/proof-section-3.jpg': ReceiptPhotoQualityCheck(
          width: 1200,
          height: 3200,
          focusScore: 7,
          brightness: 126,
          contrast: 28,
          cropScore: .78,
          textBandScore: 14,
          isLikelyReadable: true,
        ),
      },
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );

    expect(attachments, hasLength(1));
    expect(attachments.single.path, '/tmp/stitched-ocr-source.jpg');
    expect(attachments.single.path, isNot(contains('proof-section')));
    expect(
      attachments.single.documentSignals,
      contains('ocr_reads_clear_source_before_saved_proof'),
    );
    expect(
      attachments.single.documentSignals,
      contains('ocr_source_artifact_available'),
    );
    expect(
      attachments.single.documentSignals,
      isNot(contains('ocr_reads_saved_proof_fallback_requires_review')),
    );
    expect(
      attachments.single.riskFlags,
      contains('ocr_source_quality_action_retake_recommended_continue_allowed'),
    );
    expect(
      attachments.single.riskFlags,
      contains('ocr_source_quality_family_retake'),
    );
    expect(attachments.single.riskFlags, contains('ocr_source_retake_risk'));
    expect(attachments.single.riskFlags, contains('ocr_source_needs_review'));
    expect(attachments.single.riskFlags, contains('ocr_source_dark'));
    expect(attachments.single.riskFlags, contains('ocr_source_soft'));
    expect(
      attachments.single.riskFlags,
      contains('ocr_source_ocr_source_full_quality_selected_quality_guard'),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'receiptReaderHandoffOcrSourceRelationship',
        'combined_clear_source',
      ),
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'receiptDetailsHandoffOcrSourceRelationship',
        'combined_clear_source',
      ),
    );
  });

  test('kept-for-later review does not create OCR attachments', () {
    final result = ReceiptPhotoReviewResult.keptForLater(
      photoPaths: const ['/tmp/manual-proof.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );

    final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
      result,
      ReceiptCaptureFlowModule.expenses,
    );

    expect(result.keptForLater, isTrue);
    expect(result.ocrSourcePhotoPaths, isEmpty);
    expect(attachments, isEmpty);
    expect(result.acceptedPhotoHandoffMustOpenReceiptDetails, isFalse);
    expect(result.acceptedPhotoHandoffMustOpenFilledReview, isFalse);
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('receipt_review_ocr_deferred', 1),
    );
  });

  test('camera and uploaded multi-photo receipts share the OCR stitch handoff', () async {
    final importActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_import_actions.dart',
    ).readAsString();
    final cameraActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
    ).readAsString();
    final cameraFallbackActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_camera_fallback_actions.dart',
    ).readAsString();
    final saveActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsString();
    final stitchActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_exit_stitch_actions.dart',
    ).readAsString();

    expect(importActions, contains('reviewPickedPhotoPaths('));
    expect(importActions, contains('existing_receipt_photo_import'));
    expect(cameraActions, contains('_takeSystemCameraReceiptPhoto()'));
    expect(cameraActions, contains("stage: 'system_camera_platform'"));
    expect(cameraFallbackActions, contains('reviewPickedPhotoPaths('));
    expect(cameraFallbackActions, contains('initialCaptureDiagnosticsByPath'));
    expect(cameraFallbackActions, contains('system_phone_camera_receipt_photo'));
    expect(saveActions, contains('ocrSourcePaths.add(prepared.ocrSourcePath)'));
    expect(
      saveActions,
      contains(
        '_finalStitchResultForOcr(\n        inputPaths: pathsToSave,\n        preparedOcrPaths: ocrSourcePaths,',
      ),
    );
    expect(stitchActions, contains('paths: preparedOcrPaths'));
    expect(stitchActions, isNot(contains('paths: inputPaths')));
  });

  test(
    'imported receipt sources surface explicit upload signals in handoff attachments',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const [
          '/tmp/advance-email-top.png',
          '/tmp/advance-email-bottom.png',
        ],
        ocrSourcePhotoPaths: const [
          '/tmp/advance-email-top-ocr.png',
          '/tmp/advance-email-bottom-ocr.png',
        ],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.notNeeded([
          '/tmp/advance-email-top-ocr.png',
          '/tmp/advance-email-bottom-ocr.png',
        ]),
        captureDiagnosticsByPhotoPath: const {
          '/tmp/advance-email-top.png': {
            'captureFlow': 'existing_receipt_photo_import',
            'existingPhotoImportUsed': true,
          },
          '/tmp/advance-email-bottom.png': {
            'captureFlow': 'existing_receipt_photo_import',
            'existingPhotoImportUsed': true,
          },
        },
      );

      final attachments = ReceiptCaptureFlow.attachmentsFromReviewResult(
        result,
        ReceiptCaptureFlowModule.expenses,
      );

      expect(attachments, hasLength(2));
      for (final attachment in attachments) {
        expect(
          attachment.documentSignals,
          contains('native_capture_source_existing_photo_import'),
        );
        expect(
          attachment.documentSignals,
          contains('receipt_existing_photo_import'),
        );
        expect(
          attachment.documentSignals,
          contains('native_capture_source_health_available'),
        );
      }
    },
  );
}
