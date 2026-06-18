import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_limits.dart';

void main() {
  test('blank and missing PDF paths fail safely', () async {
    final blank = await ReceiptPdfInspector.inspect('   ');
    final missing = await ReceiptPdfInspector.inspect(
      '${Directory.systemTemp.path}/maintaniac_missing_receipt.pdf',
    );

    expect(blank.validationStatus, ReceiptPdfValidationStatus.missing);
    expect(blank.importBlocker, contains('could not be found'));
    expect(missing.validationStatus, ReceiptPdfValidationStatus.missing);
    expect(missing.canAttachAsProof, isFalse);
  });

  test('PDF header may appear after leading transport bytes', () async {
    final file = File('${Directory.systemTemp.path}/offset_header.pdf');
    await file.writeAsString(
      'email transport prefix\n%PDF-1.7\n'
      '1 0 obj << /Type /Page >> endobj\n'
      '%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.hasPdfHeader, isTrue);
    expect(inspection.importBlocker, isNull);
    expect(inspection.pageCount, 1);
  });

  test('PDF page counter does not mistake Pages tree for real page', () async {
    final file = File('${Directory.systemTemp.path}/pages_tree_only.pdf');
    await file.writeAsString(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Pages /Count 0 /Kids [] >> endobj\n'
      '%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.importBlocker, contains('does not appear to contain'));
    expect(inspection.pageCount, 0);
    expect(inspection.pageCountStatus, ReceiptPdfPageCountStatus.estimated);
    expect(inspection.canAttachAsProof, isFalse);
  });

  test(
    'PDF structure warnings are soft proof warnings, not hard blockers',
    () async {
      final file = File('${Directory.systemTemp.path}/minimal_structure.pdf');
      await file.writeAsString(
        '%PDF-1.7\n'
        '1 0 obj << /Type /Page >> endobj\n'
        '%%EOF',
        flush: true,
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final inspection = await ReceiptPdfInspector.inspect(file.path);

      expect(inspection.importBlocker, isNull);
      expect(inspection.riskFlags, contains('missing startxref marker'));
      expect(inspection.riskFlags, contains('missing xref table marker'));
      expect(inspection.riskFlags, contains('missing trailer marker'));
      expect(inspection.userWarning, contains('will not run scripts'));
    },
  );

  test('PDF header offset is detected as a review warning', () async {
    final file = File('${Directory.systemTemp.path}/offset_header_warning.pdf');
    await file.writeAsString(
      'download wrapper bytes\n%PDF-1.7\n'
      '1 0 obj << /Type /Page >> endobj\n'
      '%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.importBlocker, isNull);
    expect(
      inspection.riskFlags,
      contains(ReceiptPdfInspector.headerOffsetRiskFlag),
    );
  });

  test('active PDF content stays attachable but is proof-only', () async {
    final file = File('${Directory.systemTemp.path}/active_content.pdf');
    await file.writeAsString(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page /AA << /O 2 0 R >> >> endobj\n'
      '2 0 obj << /S /JavaScript /JS (app.alert("x")) >> endobj\n'
      '3 0 obj << /Type /Filespec /F (payload.txt) >> endobj\n'
      '%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.importBlocker, isNull);
    expect(inspection.canAttachAsProof, isTrue);
    expect(inspection.hasActiveContentRisk, isTrue);
    expect(inspection.canUseAssistedRead, isFalse);
    expect(inspection.assistedReadBlocker, contains('active content'));
    expect(
      inspection.handlingDisposition,
      ReceiptPdfHandlingDisposition.proofOnly,
    );
  });

  test(
    'hard page limit boundary is allowed but next page warns strongly',
    () async {
      final allowedFile = File(
        '${Directory.systemTemp.path}/hard_page_limit_allowed.pdf',
      );
      final overFile = File(
        '${Directory.systemTemp.path}/hard_page_limit_over.pdf',
      );
      await _fakePdfWithPages(
        allowedFile.path,
        ReceiptPdfLimits.hardPdfPageLimit,
      );
      await _fakePdfWithPages(
        overFile.path,
        ReceiptPdfLimits.hardPdfPageLimit + 1,
      );
      addTearDown(() {
        if (allowedFile.existsSync()) allowedFile.deleteSync();
        if (overFile.existsSync()) overFile.deleteSync();
      });

      final allowedInspection = await ReceiptPdfInspector.inspect(
        allowedFile.path,
      );
      final overInspection = await ReceiptPdfInspector.inspect(overFile.path);

      expect(allowedInspection.exceedsHardReceiptPageLimit, isFalse);
      expect(allowedInspection.importBlocker, isNull);
      expect(overInspection.exceedsHardReceiptPageLimit, isTrue);
      expect(overInspection.importBlocker, isNull);
      expect(overInspection.longReceiptWarning, contains('read-only proof'));
    },
  );
}

Future<void> _fakePdfWithPages(String path, int pages) async {
  final buffer = StringBuffer('%PDF-1.7\n');
  for (var index = 0; index < pages; index += 1) {
    buffer.writeln('$index 0 obj << /Type /Page >> endobj');
  }
  buffer.writeln('%%EOF');
  await File(path).writeAsString(buffer.toString(), flush: true);
}
