import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
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
