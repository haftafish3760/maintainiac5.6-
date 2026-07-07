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
          'scannerDecisionCodes': [
            'ocr_source_full_quality_selected_quality_guard',
          ],
        },
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
      isNot(contains('ocr_reads_saved_proof_fallback_requires_review')),
    );
    expect(
      attachments.single.riskFlags,
      contains('ocr_source_ocr_source_full_quality_selected_quality_guard'),
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
    final saveActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsString();
    final stitchActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_exit_stitch_actions.dart',
    ).readAsString();

    expect(importActions, contains('reviewPickedPhotoPaths('));
    expect(importActions, contains('existing_receipt_photo_import'));
    expect(cameraActions, contains('captureAndReview('));
    expect(cameraActions, contains('_acceptReviewedPhotoResult(result)'));
    expect(cameraActions, contains('native_receipt_camera'));
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
}
