import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';

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

  test('receipt attachment labels identify imported sources', () {
    final email = ReceiptAttachmentRecord(
      id: 'email-1',
      path: '',
      kind: ReceiptAttachmentKind.emailText,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      createdAt: DateTime(2026, 6, 12),
      importedText: 'TOTAL 12.99',
    );
    final pdf = ReceiptAttachmentRecord(
      id: 'pdf-1',
      path: '/tmp/receipt.pdf',
      kind: ReceiptAttachmentKind.pdf,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      createdAt: DateTime(2026, 6, 12),
      displayName: 'Advance Auto receipt.pdf',
    );

    expect(email.label, 'Receipt text');
    expect(email.isImportedText, isTrue);
    expect(pdf.label, 'Advance Auto receipt.pdf');
    expect(pdf.isImportedText, isFalse);
  });

  test('receipt attachment copy keeps source identity while editing text', () {
    final original = ReceiptAttachmentRecord(
      id: 'email-1',
      path: '',
      kind: ReceiptAttachmentKind.emailText,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      createdAt: DateTime(2026, 6, 12),
      displayName: 'Advance Auto email',
      importedText: 'TOTAL 12.99',
      byteSize: 11,
      sourceLabel: 'SMS/Text',
    );

    final edited = original.copyWith(
      displayName: 'Advance Auto corrected',
      importedText: 'OIL FILTER 12.99\nTOTAL 12.99',
      byteSize: 29,
    );

    expect(edited.id, original.id);
    expect(edited.kind, ReceiptAttachmentKind.emailText);
    expect(edited.createdAt, original.createdAt);
    expect(edited.label, 'Advance Auto corrected');
    expect(edited.importedText, contains('OIL FILTER'));
    expect(edited.byteSize, 29);
  });

  test('receipt attachment metadata survives storage maps', () {
    final attachment = ReceiptAttachmentRecord(
      id: 'pdf-1',
      path: '/tmp/receipt.pdf',
      kind: ReceiptAttachmentKind.pdf,
      dataSaverLevel: ReceiptDataSaverLevel.original,
      createdAt: DateTime(2026, 6, 13),
      displayName: 'fuel.pdf',
      byteSize: 1200,
      fileHash: 'abc123',
      pageCount: 3,
      sourceLabel: 'Files/PDF',
      readState: ReceiptAttachmentReadState.readIntoForm,
    );

    final restored = ReceiptAttachmentRecord.fromMap(attachment.toMap());

    expect(restored.fileHash, 'abc123');
    expect(restored.pageCount, 3);
    expect(restored.sourceLabel, 'Files/PDF');
    expect(restored.originalFileName, '');
    expect(restored.mimeType, '');
    expect(restored.linkedModule, '');
    expect(restored.linkedRecordId, '');
    expect(restored.isOriginalImmutable, isTrue);
    expect(restored.readState, ReceiptAttachmentReadState.readIntoForm);
    expect(restored.isReadOnlyProof, isTrue);
    expect(restored.canEditProofFileInApp, isFalse);
    expect(restored.proofAccessLabel, 'read-only PDF proof');
  });

  test('receipt photo quality metadata survives storage maps', () {
    const quality = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 15,
      brightness: 148,
      contrast: 40,
      cropScore: .78,
      textBandScore: 14,
      isLikelyReadable: true,
    );
    final attachment = ReceiptAttachmentRecord(
      id: 'photo-1',
      path: '/tmp/receipt.jpg',
      kind: ReceiptAttachmentKind.photo,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      createdAt: DateTime(2026, 6, 13),
      byteSize: 2200,
    ).withPhotoQuality(quality);

    final restored = ReceiptAttachmentRecord.fromMap(attachment.toMap());

    expect(restored.hasPhotoQualityReview, isTrue);
    expect(restored.photoQualityNeedsReview, isFalse);
    expect(restored.photoQualityScore, quality.reviewScore);
    expect(restored.photoQualityIssueLabel, 'looks readable');
    expect(restored.photoQualityWarnings, isEmpty);
    expect(restored.photoWidth, 1800);
    expect(restored.photoHeight, 2400);
    expect(restored.photoBrightness, 148);
    expect(restored.photoContrast, 40);
    expect(restored.photoFocusScore, 15);
    expect(restored.photoCropScore, .78);
    expect(restored.photoTextBandScore, 14);
    expect(restored.photoQualityLabel, contains('Photo quality'));
  });

  test('photo quality warning does not erase read-into-form proof state', () {
    const quality = ReceiptPhotoQualityCheck(
      width: 900,
      height: 1200,
      focusScore: 5,
      brightness: 84,
      contrast: 18,
      cropScore: .45,
      textBandScore: 4,
      isLikelyReadable: false,
    );
    final attachment = ReceiptAttachmentRecord(
      id: 'photo-read',
      path: '/tmp/read.jpg',
      kind: ReceiptAttachmentKind.photo,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      createdAt: DateTime(2026, 6, 13),
      readState: ReceiptAttachmentReadState.readIntoForm,
    ).withPhotoQuality(quality);

    expect(attachment.photoQualityNeedsReview, isTrue);
    expect(attachment.readState, ReceiptAttachmentReadState.readIntoForm);
  });

  test(
    'imported text remains editable while original proof files stay locked',
    () {
      final text = ReceiptAttachmentRecord(
        id: 'sms-1',
        path: '',
        kind: ReceiptAttachmentKind.textMessageText,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 6, 13),
        importedText: 'TOTAL 24.50',
      );
      final photo = ReceiptAttachmentRecord(
        id: 'photo-1',
        path: '/tmp/receipt.jpg',
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 6, 13),
      );

      expect(text.isReadOnlyProof, isFalse);
      expect(text.proofAccessLabel, 'editable receipt text');
      expect(photo.isReadOnlyProof, isTrue);
      expect(photo.proofAccessLabel, 'read-only receipt photo');
      expect(photo.canEditProofFileInApp, isFalse);
    },
  );

  test('ocr service asks for a receipt photo before scanning', () async {
    final result = await const ReceiptOcrService().recognizeTextFromAttachments(
      const [],
    );

    expect(result.hasText, isFalse);
    expect(result.source, ReceiptProcessingSource.none);
    expect(result.processingSnapshot.stage, ReceiptProcessingStage.noSource);
    expect(result.stats.attachmentsRead, 0);
    expect(result.stats.attachmentsSkipped, 0);
    expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.blocked);
    expect(result.diagnostics.reviewSummaryLabel, contains('Blocked'));
    expect(result.diagnostics.textSummaryLabel, 'No readable text');
    expect(
      result.structuredWarnings.single.kind,
      ReceiptOcrWarningKind.noSource,
    );
    expect(result.structuredWarnings.single.isBlocking, isTrue);
    expect(result.structuredWarnings.single.label, 'No receipt attached');
    expect(
      result.structuredWarnings.single.actionLabel,
      contains('Attach a receipt'),
    );
    expect(result.diagnostics.hasBlockingWarnings, isTrue);
    expect(result.diagnostics.blockingWarningCount, 1);
    expect(result.diagnostics.warningSummaryLabel, '1 blocked OCR warning');
    expect(
      result.warnings.single,
      contains('Attach at least one receipt photo'),
    );
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
      expect(result.diagnostics.warningSummaryLabel, 'No OCR warnings');
      expect(result.warnings, isEmpty);
      expect(result.structuredWarnings, isEmpty);
    },
  );

  test(
    'ocr service can skip photo reading for a limited device profile',
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
      expect(result.structuredWarnings.single.label, 'Receipt reading off');
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
    'ocr service keeps imported text while capping extra photo reads',
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
        contains('Turn on receipt reading'),
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
    'ocr service can disable PDF reading for a limited device profile',
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
        contains('PDF receipt reading is turned off'),
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
    expect(medium.maxPhotoOcrAttachments, 8);
    expect(medium.maxPdfOcrAttachments, 2);
    expect(heavy.maxPhotoOcrAttachments, 12);
    expect(heavy.maxPdfOcrAttachments, 3);
    expect(heavy.pdfPageReadTimeout, const Duration(seconds: 16));
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

  test('pdf inspector estimates page count for receipt proof files', () async {
    final pdf = pw.Document();
    for (var index = 0; index < 12; index++) {
      pdf.addPage(pw.Page(build: (_) => pw.Text('Receipt page ${index + 1}')));
    }
    final file = File('${Directory.systemTemp.path}/receipt_pages_test.pdf');
    await file.writeAsBytes(await pdf.save(), flush: true);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.exists, isTrue);
    expect(inspection.hasPdfHeader, isTrue);
    expect(inspection.pageCount, 12);
    expect(inspection.isProbablyLongReceipt, isTrue);
    expect(inspection.longReceiptWarning, contains('12 pages'));
  });

  test('pdf inspector blocks zero-byte and renamed non-PDF files', () async {
    final empty = File('${Directory.systemTemp.path}/empty_receipt.pdf');
    final renamed = File('${Directory.systemTemp.path}/not_really.pdf');
    await empty.writeAsBytes(const [], flush: true);
    await renamed.writeAsString('this is not actually a pdf', flush: true);
    addTearDown(() {
      if (empty.existsSync()) empty.deleteSync();
      if (renamed.existsSync()) renamed.deleteSync();
    });

    final emptyInspection = await ReceiptPdfInspector.inspect(empty.path);
    final renamedInspection = await ReceiptPdfInspector.inspect(renamed.path);

    expect(emptyInspection.importBlocker, contains('empty'));
    expect(renamedInspection.hasPdfHeader, isFalse);
    expect(renamedInspection.importBlocker, contains('valid PDF'));
  });

  test('pdf inspector blocks files above the import size limit', () async {
    final file = File('${Directory.systemTemp.path}/huge_receipt.pdf');
    final raf = await file.open(mode: FileMode.write);
    try {
      await raf.writeFrom('%PDF-1.7\n'.codeUnits);
      await raf.truncate(ReceiptPdfInspector.importBytesLimit + 1);
    } finally {
      await raf.close();
    }
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.hasPdfHeader, isTrue);
    expect(inspection.exceedsImportSizeLimit, isTrue);
    expect(inspection.importBlocker, contains('too large'));
  });

  test(
    'pdf inspector exposes separate local and cloud reading limits',
    () async {
      final pdf = pw.Document();
      for (var index = 0; index < 55; index++) {
        pdf.addPage(
          pw.Page(build: (_) => pw.Text('Receipt page ${index + 1}')),
        );
      }
      final file = File(
        '${Directory.systemTemp.path}/receipt_many_pages_test.pdf',
      );
      await file.writeAsBytes(await pdf.save(), flush: true);
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final inspection = await ReceiptPdfInspector.inspect(file.path);

      expect(inspection.pageCount, 55);
      expect(inspection.exceedsAssistedReadPageLimit, isTrue);
      expect(inspection.exceedsCloudReadPageLimit, isTrue);
      expect(
        inspection.longReceiptWarning,
        contains(
          'first ${ReceiptPdfInspector.localAssistedReadPageLimit} pages',
        ),
      );
      expect(inspection.cloudCostWarning, contains('smaller PDF'));
    },
  );

  test(
    'ocr service skips encrypted PDFs but keeps the proof warning',
    () async {
      final file = File('${Directory.systemTemp.path}/ocr_encrypted.pdf');
      await file.writeAsString(
        '%PDF-1.7\n'
        '1 0 obj << /Type /Page >> endobj\n'
        'trailer << /Encrypt 2 0 R >>\n'
        '%%EOF',
        flush: true,
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final result = await const ReceiptOcrService()
          .recognizeTextFromAttachments([
            ReceiptAttachmentRecord(
              id: 'encrypted-pdf',
              path: file.path,
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.original,
              createdAt: DateTime(2026, 6, 13),
            ),
          ]);

      expect(result.hasText, isFalse);
      expect(result.textByAttachmentId, isEmpty);
      expect(result.warnings.single, contains('encrypted'));
      expect(
        result.structuredWarnings.single.kind,
        ReceiptOcrWarningKind.pdfSafety,
      );
      expect(result.structuredWarnings.single.label, 'PDF safety warning');
      expect(
        result.structuredWarnings.single.actionLabel,
        contains('safe copy'),
      );
      expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.blocked);
      expect(result.diagnostics.blockingWarningCount, 1);
    },
  );

  test(
    'ocr service keeps pasted text when an attached PDF cannot be read',
    () async {
      final file = File('${Directory.systemTemp.path}/ocr_mixed_encrypted.pdf');
      await file.writeAsString(
        '%PDF-1.7\n'
        '1 0 obj << /Type /Page >> endobj\n'
        'trailer << /Encrypt 2 0 R >>\n'
        '%%EOF',
        flush: true,
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final result = await const ReceiptOcrService(maxPdfOcrPages: 0)
          .recognizeTextFromAttachments([
            ReceiptAttachmentRecord(
              id: 'email-1',
              path: '',
              kind: ReceiptAttachmentKind.emailText,
              dataSaverLevel: ReceiptDataSaverLevel.original,
              createdAt: DateTime(2026, 6, 13),
              importedText: 'ADVANCE AUTO PARTS\nTOTAL 42.18',
            ),
            ReceiptAttachmentRecord(
              id: 'encrypted-pdf',
              path: file.path,
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.original,
              createdAt: DateTime(2026, 6, 13),
            ),
          ]);

      expect(result.hasText, isTrue);
      expect(result.rawText, contains('TOTAL 42.18'));
      expect(result.textByAttachmentId, contains('email-1'));
      expect(result.textByAttachmentId, isNot(contains('encrypted-pdf')));
      expect(result.warnings.single, contains('encrypted'));
      expect(
        result.structuredWarnings.single.kind,
        ReceiptOcrWarningKind.pdfSafety,
      );
      expect(result.diagnostics.severity, ReceiptOcrReviewSeverity.review);
      expect(result.diagnostics.hasBlockingWarnings, isTrue);
      expect(result.diagnostics.warningSummaryLabel, '1 blocked OCR warning');
    },
  );

  test('ocr service warns about active PDF content before reading', () async {
    final file = File('${Directory.systemTemp.path}/ocr_active_content.pdf');
    await file.writeAsString(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page /AA << /S /JavaScript >> >> endobj\n'
      '%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final result = await const ReceiptOcrService(maxPdfOcrPages: 0)
        .recognizeTextFromAttachments([
          ReceiptAttachmentRecord(
            id: 'active-pdf',
            path: file.path,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 6, 13),
          ),
        ]);

    expect(result.warnings.join('\n'), contains('scripts'));
    expect(
      result.structuredWarnings.single.kind,
      ReceiptOcrWarningKind.pdfSafety,
    );
  });

  test('ocr service skips PDFs above the local assisted read size', () async {
    final file = File('${Directory.systemTemp.path}/local_read_too_large.pdf');
    final raf = await file.open(mode: FileMode.write);
    try {
      await raf.writeFrom(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF'.codeUnits,
      );
      await raf.truncate(ReceiptPdfInspector.localAssistedReadBytes + 1);
    } finally {
      await raf.close();
    }
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final result = await const ReceiptOcrService()
        .recognizeTextFromAttachments([
          ReceiptAttachmentRecord(
            id: 'large-local-pdf',
            path: file.path,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 6, 13),
          ),
        ]);

    expect(result.hasText, isFalse);
    expect(result.textByAttachmentId, isEmpty);
    expect(result.warnings.single, contains('smaller file'));
    expect(
      result.structuredWarnings.single.kind,
      ReceiptOcrWarningKind.pdfTooLarge,
    );
    expect(result.diagnostics.blockingWarningCount, 1);
  });
}
