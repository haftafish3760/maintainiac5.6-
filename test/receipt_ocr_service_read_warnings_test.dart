import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
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
    'ocr service keeps source section labels after suppressing overlap lines',
    () async {
      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            ReceiptAttachmentRecord(
              id: 'section-1',
              path: '',
              kind: ReceiptAttachmentKind.emailText,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 12),
              importedText: '''
LOWES
06/12/2026
PVC GLUE 7.99
TOTAL 7.99
''',
            ),
            ReceiptAttachmentRecord(
              id: 'section-2',
              path: '',
              kind: ReceiptAttachmentKind.emailText,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 12),
              importedText: '''
PVC GLUE 7.99
PVC COUPLING 2.49
TOTAL 10.48
''',
            ),
          ]);

      final lines = result.orderedParserLines;
      final couplingIndex = lines.indexOf('PVC COUPLING 2.49');

      expect(result.warnings.join(' '), contains('Ignored 1 repeated'));
      expect(lines.where((line) => line == 'PVC GLUE 7.99'), hasLength(1));
      expect(couplingIndex, greaterThanOrEqualTo(0));
      expect(
        result.parserLineSourceLocations,
        hasLength(result.orderedParserLines.length),
      );

      final couplingDraft = result.parserHandoff.lineDrafts[couplingIndex];
      final localMap = couplingDraft.toLocalReviewMap();
      final safeMap = couplingDraft.toPrivacySafeSummaryMap();

      expect(couplingDraft.text, 'PVC COUPLING 2.49');
      expect(couplingDraft.sourceLocation?.sectionNumber, 2);
      expect(couplingDraft.sourceLocation?.sectionLineNumber, 2);
      expect(couplingDraft.sourceLocationLabel, 'section 2 line 2');
      expect(localMap['sourceLocation'], {
        'sectionNumber': 2,
        'sectionLineNumber': 2,
        'label': 'section 2 line 2',
      });
      expect(safeMap['sourceSectionNumber'], 2);
      expect(safeMap['sourceSectionLineNumber'], 2);
      expect(result.parserHandoff.lineCountsBySourceSection, {
        'section_1': 4,
        'section_2': 2,
      });
      expect(result.parserHandoff.sourceSectionCount, 2);
      expect(result.parserHandoff.sourceSectionNumbersInOrder, [1, 2]);
      expect(result.parserHandoff.uniqueSourceSectionNumbers, [1, 2]);
      expect(
        result.parserHandoff.sourceSectionContinuityStatus,
        'continuous_sections',
      );
      expect(result.parserHandoff.needsSourceSectionContinuityReview, isFalse);
      expect(result.parserHandoff.itemLineCountsBySourceSection, {
        'section_1': 1,
        'section_2': 1,
      });
      expect(
        result.parserHandoff.lineIdsBySourceSection['section_2'],
        contains(couplingDraft.stableLineId),
      );
      expect(
        result.parserHandoff.parserReadyLineIdsBySourceSection['section_2'],
        contains(couplingDraft.stableLineId),
      );
      expect(
        result
            .parserHandoff
            .privacySafeParserHandoffContract['lineCountsBySourceSection'],
        {'section_1': 4, 'section_2': 2},
      );
      expect(
        result
            .parserHandoff
            .privacySafeParserHandoffContract['itemLineCountsBySourceSection'],
        {'section_1': 1, 'section_2': 1},
      );
      expect(
        result
            .parserHandoff
            .privacySafeParserHandoffContract['sourceSectionContinuityStatus'],
        'continuous_sections',
      );
      expect(
        result
            .parserHandoff
            .privacySafeParserHandoffContract['sourceSectionContinuityReviewNeeded'],
        isFalse,
      );
      expect(
        (result
                .parserHandoff
                .privacySafeParserHandoffContract['lineIdsBySourceSection']
            as Map)['section_2'],
        contains(couplingDraft.stableLineId),
      );
      expect(safeMap.toString(), isNot(contains('COUPLING')));
      expect(safeMap.toString(), isNot(contains('LOWES')));
      expect(
        result.parserHandoff.privacySafeParserHandoffContract.toString(),
        isNot(contains('COUPLING')),
      );
      expect(
        result.parserHandoff.privacySafeParserHandoffContract.toString(),
        isNot(contains('LOWES')),
      );
    },
  );

  test(
    'ocr service caps PDFs without inspecting proof-only overflow',
    () async {
      final readable = File(
        '${Directory.systemTemp.path}/ocr_readable_cap.pdf',
      );
      final overflow = File(
        '${Directory.systemTemp.path}/ocr_overflow_cap.pdf',
      );
      await readable.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      await overflow.writeAsString('not actually a pdf', flush: true);
      addTearDown(() {
        if (readable.existsSync()) readable.deleteSync();
        if (overflow.existsSync()) overflow.deleteSync();
      });

      final result =
          await const ReceiptOcrService(
            maxPdfOcrAttachments: 1,
            maxPdfOcrPages: 0,
          ).recognizeTextFromAttachments([
            ReceiptAttachmentRecord(
              id: 'pdf-readable',
              path: readable.path,
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 12),
            ),
            ReceiptAttachmentRecord(
              id: 'pdf-overflow',
              path: overflow.path,
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 12),
            ),
          ]);

      expect(result.hasText, isFalse);
      expect(result.stats.pdfsRead, 1);
      expect(result.stats.pdfsSkipped, 1);
      expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.blocked);
      expect(result.diagnostics.pdfWorkLabel, 'No PDF pages requested');
      expect(result.textByAttachmentId, isEmpty);
      expect(
        result.structuredWarnings.map((warning) => warning.kind),
        contains(ReceiptOcrWarningKind.sourceSkipped),
      );
      expect(result.diagnostics.partialWarningCount, 1);
      expect(
        result.reviewMessage(successMessage: 'Receipt text read.'),
        contains('Only the first 1 receipt PDFs'),
      );
      expect(
        result.warnings.join('\n'),
        contains('Only the first 1 receipt PDFs'),
      );
      expect(result.warnings.join('\n'), isNot(contains('valid PDF')));
    },
  );

  test(
    'ocr service can disable PDF assistance for a limited device profile',
    () async {
      final file = File('${Directory.systemTemp.path}/ocr_pdf_disabled.pdf');
      await file.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final result = await const ReceiptOcrService(maxPdfOcrAttachments: 0)
          .recognizeTextFromAttachments([
            ReceiptAttachmentRecord(
              id: 'pdf-disabled',
              path: file.path,
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime(2026, 6, 12),
            ),
          ]);

      expect(result.hasText, isFalse);
      expect(result.source, ReceiptProcessingSource.pdf);
      expect(result.stats.pdfsRead, 0);
      expect(result.stats.pdfsSkipped, 1);
      expect(
        result.structuredWarnings.single.kind,
        ReceiptOcrWarningKind.sourceSkipped,
      );
      expect(result.structuredWarnings.single.isBlocking, isTrue);
      expect(
        result.warnings.single,
        contains('PDF receipt assistance is turned off'),
      );
    },
  );

  test('ocr service limits are built from receipt capability tiers', () {
    final light = ReceiptOcrService.forDevice(
      const ReceiptDeviceCapability.olderPhone(),
    );
    final medium = ReceiptOcrService.forDevice(
      const ReceiptDeviceCapability.standard(),
    );
    final heavy = ReceiptOcrService.forDevice(
      const ReceiptDeviceCapability.highCapacity(),
    );

    expect(light.maxPhotoOcrAttachments, 4);
    expect(light.maxPdfOcrAttachments, 1);
    expect(light.pdfPageReadTimeout, const Duration(seconds: 8));
    expect(light.photoReadTimeout, const Duration(seconds: 8));
    expect(medium.maxPhotoOcrAttachments, 8);
    expect(medium.maxPdfOcrAttachments, 2);
    expect(medium.photoReadTimeout, const Duration(seconds: 12));
    expect(heavy.maxPhotoOcrAttachments, 12);
    expect(heavy.maxPdfOcrAttachments, 3);
    expect(heavy.pdfPageReadTimeout, const Duration(seconds: 16));
    expect(heavy.photoReadTimeout, const Duration(seconds: 16));
  });

  test('ocr service times out an unresponsive photo read with recovery', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_ocr_service.dart',
    ).readAsStringSync();

    expect(source, contains('.timeout(photoReadTimeout)'));
    expect(source, contains('} on TimeoutException {'));
    expect(source, contains('Reading this receipt photo took too long.'));
    expect(source, contains('timedOutPhotosSkipped ='));
    expect(source, contains('A Dart timeout cannot cancel the native read'));
    expect(source, contains('photosSkipped:\n            skippedPhotoCount +'));
  });

  test('a stalled photo read remains a blocking photo-read failure', () {
    const result = ReceiptOcrResult(
      rawText: '',
      parserText: '',
      textByAttachmentId: {},
      source: ReceiptProcessingSource.photo,
      warnings: [
        'Reading this receipt photo took too long. Try again, use a clearer photo, or continue with the details yourself.',
      ],
    );

    expect(
      result.structuredWarnings.single.kind,
      ReceiptOcrWarningKind.photoReadFailure,
    );
    expect(result.structuredWarnings.single.isBlocking, isTrue);
  });

  test('ocr service uses safe PDF raster byte reads after preflight', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_ocr_service_pdf_read.dart',
    ).readAsStringSync();

    expect(source, contains('Future<Uint8List?> _readPdfRasterBytes'));
    expect(source, contains('on FileSystemException'));
    expect(source, contains('_ReceiptPdfRasterReadException'));
    expect(source, isNot(contains('File(attachment.path).readAsBytes()')));
  });

  test('ocr diagnostics explain device-specific PDF page caps', () {
    const result = ReceiptOcrResult(
      rawText: '',
      parserText: '',
      textByAttachmentId: {},
      source: ReceiptProcessingSource.pdf,
      stats: ReceiptOcrReadStats(pdfPagesRequested: 2, pdfsRead: 1),
      warnings: [
        'Only the first 2 pages of this PDF will be read on this device. The full PDF stays saved as read-only proof.',
      ],
    );

    expect(result.stats.pdfPagesRequested, 2);
    expect(result.diagnostics.pdfWorkLabel, '2 PDF pages requested');
    expect(
      result.structuredWarnings.single.kind,
      ReceiptOcrWarningKind.sourceSkipped,
    );
    expect(result.structuredWarnings.single.isPartial, isTrue);
  });
}
