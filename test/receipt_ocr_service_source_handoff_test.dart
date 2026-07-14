import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documentsDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'receipt_proof_storage_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (await documentsDirectory.exists()) {
      await documentsDirectory.delete(recursive: true);
    }
  });

  test(
    'ocr service explains when a PDF cannot be opened for reading',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            ReceiptAttachmentRecord(
              id: 'pdf-1',
              path: '/tmp/advance-auto.pdf',
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 12),
              displayName: 'Advance Auto receipt.pdf',
            ),
          ]);

      expect(result.hasText, isFalse);
      expect(result.textByAttachmentId, isEmpty);
      expect(result.warnings.single, contains('could not be found'));
      expect(
        result.structuredWarnings.single.kind,
        ReceiptOcrWarningKind.pdfUnreadable,
      );
      expect(result.diagnostics.hasBlockingWarnings, isTrue);
    },
  );

  test(
    'ocr service accepts pasted email receipt text without a photo',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            ReceiptAttachmentRecord(
              id: 'email-1',
              path: '',
              kind: ReceiptAttachmentKind.emailText,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 12),
              displayName: 'Advance Auto email receipt',
              importedText: 'ADVANCE AUTO PARTS\nOIL FILTER 12.99\nTOTAL 12.99',
              byteSize: 55,
            ),
          ]);

      expect(result.hasText, isTrue);
      expect(result.source, ReceiptProcessingSource.importedText);
      expect(
        result.processingSnapshot.stage,
        ReceiptProcessingStage.textExtracted,
      );
      expect(result.rawText, contains('OIL FILTER'));
      expect(result.textByAttachmentId['email-1'], contains('TOTAL 12.99'));
      expect(result.stats.importedTextRead, 1);
      expect(result.stats.attachmentsRead, 1);
      expect(result.stats.usedLocalOcr, isFalse);
      expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.good);
      expect(result.diagnostics.sourceLabel, 'Imported text');
      expect(result.diagnostics.readSummaryLabel, '1 source read');
      expect(
        result.diagnostics.textSummaryLabel,
        '3 receipt lines ready for review',
      );
      expect(
        result.diagnostics.warningSummaryLabel,
        'No receipt-reading warnings',
      );
      expect(result.warnings, isEmpty);
      expect(result.structuredWarnings, isEmpty);
    },
  );

  test(
    'ocr service can skip photo assistance for a limited device profile',
    () async {
      final result = await const ReceiptOcrService(maxPhotoOcrAttachments: 0)
          .recognizeTextFromAttachments([
            ReceiptAttachmentRecord(
              id: 'photo-1',
              path: '/tmp/lowes.jpg',
              kind: ReceiptAttachmentKind.photo,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 12),
            ),
          ]);

      expect(result.hasText, isFalse);
      expect(result.source, ReceiptProcessingSource.photo);
      expect(result.textByAttachmentId, isEmpty);
      expect(result.stats.photosRead, 0);
      expect(result.stats.photosSkipped, 1);
      expect(result.stats.hadSkippedWork, isTrue);
      expect(result.warnings.single, contains('turned off'));
      expect(
        result.structuredWarnings.single.kind,
        ReceiptOcrWarningKind.sourceSkipped,
      );
      expect(result.structuredWarnings.single.isBlocking, isTrue);
      expect(result.structuredWarnings.single.label, 'Receipt assistance off');
      expect(result.diagnostics.hasBlockingWarnings, isTrue);
    },
  );

  test('ocr service surfaces photo quality warnings before reading', () async {
    const poorQuality = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 13,
      brightness: 242,
      contrast: 30,
      cropScore: .76,
      textBandScore: 12,
      isLikelyReadable: false,
    );
    final result = await const ReceiptOcrService(maxPhotoOcrAttachments: 0)
        .recognizeTextFromAttachments([
          ReceiptAttachmentRecord(
            id: 'photo-glare',
            path: '/tmp/glare.jpg',
            kind: ReceiptAttachmentKind.photo,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
            createdAt: DateTime(2026, 6, 12),
          ).withPhotoQuality(poorQuality),
        ]);

    expect(result.hasText, isFalse);
    expect(result.stats.photosSkipped, 1);
    expect(
      result.warnings.join(' '),
      contains('Receipt photo quality needs review'),
    );
    expect(result.warnings.join(' '), contains('glare'));
    expect(
      result.structuredWarnings.map((warning) => warning.kind),
      contains(ReceiptOcrWarningKind.photoQuality),
    );
    expect(
      result.structuredWarnings
          .firstWhere(
            (warning) => warning.kind == ReceiptOcrWarningKind.photoQuality,
          )
          .needsReview,
      isTrue,
    );
  });

  test(
    'ocr service keeps imported text while capping extra photo assistance',
    () async {
      final result = await const ReceiptOcrService(maxPhotoOcrAttachments: 0)
          .recognizeTextFromAttachments([
            ReceiptAttachmentRecord(
              id: 'email-1',
              path: '',
              kind: ReceiptAttachmentKind.emailText,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 12),
              importedText: 'LOWES\nPVC COUPLING 2.49\nTOTAL 2.49',
            ),
            ReceiptAttachmentRecord(
              id: 'photo-1',
              path: '/tmp/lowes-front.jpg',
              kind: ReceiptAttachmentKind.photo,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 12),
            ),
            ReceiptAttachmentRecord(
              id: 'photo-2',
              path: '/tmp/lowes-back.jpg',
              kind: ReceiptAttachmentKind.photo,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 12),
            ),
          ]);

      expect(result.hasText, isTrue);
      expect(result.source, ReceiptProcessingSource.mixed);
      expect(result.appFillText, contains('PVC COUPLING'));
      expect(result.textByAttachmentId, contains('email-1'));
      expect(result.textByAttachmentId, isNot(contains('photo-1')));
      expect(result.stats.importedTextRead, 1);
      expect(result.stats.photosRead, 0);
      expect(result.stats.photosSkipped, 2);
      expect(result.stats.attachmentsRead, 1);
      expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.review);
      expect(result.diagnostics.readSummaryLabel, contains('2 saved as proof'));
      expect(result.diagnostics.reviewSummaryLabel, contains('Review'));
      expect(
        result.structuredWarnings.single.kind,
        ReceiptOcrWarningKind.sourceSkipped,
      );
      expect(result.structuredWarnings.single.isBlocking, isTrue);
      expect(
        result.structuredWarnings.single.reviewMessage,
        contains('Turn on receipt assistance'),
      );
      expect(result.diagnostics.blockingWarningCount, 1);
      expect(
        result.reviewMessage(successMessage: 'Receipt text read.'),
        contains('Read 1 pasted/imported text source.'),
      );
      expect(
        result.reviewMessage(successMessage: 'Receipt text read.'),
        contains('2 extra photos were saved as proof only.'),
      );
      expect(result.warnings.single, contains('turned off'));
    },
  );
}
