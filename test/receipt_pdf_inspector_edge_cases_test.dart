import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_limits.dart';

import 'helpers/receipt_pdf_test_support.dart';

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
    final file = await isolatedTempPdfFile(
      'pdf_edge_active_content_',
      'active_content.pdf',
    );
    await file.writeAsString(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page /AA << /O 2 0 R >> >> endobj\n'
      '2 0 obj << /S /JavaScript /JS (app.alert("x")) >> endobj\n'
      '3 0 obj << /Type /Filespec /F (payload.txt) >> endobj\n'
      '%%EOF',
      flush: true,
    );

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

  test('PDF document signals distinguish text layer from image-only pages', () {
    final textLayer = ReceiptPdfInspector.detectDocumentSignals(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page /Contents 2 0 R >> endobj\n'
              '2 0 obj << >> stream BT /F1 12 Tf (Total 12.34) Tj ET endstream endobj\n'
              '%%EOF'
          .codeUnits,
    );
    final imageOnly = ReceiptPdfInspector.detectDocumentSignals(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page /Resources << /XObject << /Im1 2 0 R >> >> >> endobj\n'
              '2 0 obj << /Type /XObject /Subtype /Image /Width 800 /Height 1200 >> stream data endstream endobj\n'
              '%%EOF'
          .codeUnits,
    );
    final geometry = ReceiptPdfInspector.detectDocumentSignals(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page /Rotate 90 /CropBox [0 0 300 600] >> endobj\n'
              '%%EOF'
          .codeUnits,
    );

    expect(textLayer, contains(ReceiptPdfInspector.textLayerSignal));
    expect(textLayer, contains('total'));
    expect(imageOnly, contains(ReceiptPdfInspector.imageContentSignal));
    expect(imageOnly, isNot(contains(ReceiptPdfInspector.textLayerSignal)));
    expect(geometry, contains(ReceiptPdfInspector.rotatedPageSignal));
    expect(geometry, contains(ReceiptPdfInspector.croppedPageSignal));
  });

  test('PDF document signals distinguish portrait and landscape pages', () {
    final portrait = ReceiptPdfInspector.detectDocumentSignals(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page /MediaBox [0 0 612 792] >> endobj\n'
              '%%EOF'
          .codeUnits,
    );
    final landscape = ReceiptPdfInspector.detectDocumentSignals(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page /MediaBox [0 0 792 612] >> endobj\n'
              '%%EOF'
          .codeUnits,
    );
    final mixed = ReceiptPdfInspector.detectDocumentSignals(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page /MediaBox [0 0 612 792] >> endobj\n'
              '2 0 obj << /Type /Page /MediaBox [0 0 792 612] >> endobj\n'
              '%%EOF'
          .codeUnits,
    );

    expect(portrait, contains(ReceiptPdfInspector.portraitPageSignal));
    expect(portrait, isNot(contains(ReceiptPdfInspector.landscapePageSignal)));
    expect(landscape, contains(ReceiptPdfInspector.landscapePageSignal));
    expect(landscape, isNot(contains(ReceiptPdfInspector.portraitPageSignal)));
    expect(mixed, contains(ReceiptPdfInspector.portraitPageSignal));
    expect(mixed, contains(ReceiptPdfInspector.landscapePageSignal));
  });

  test('PDF page orientation uses true box dimensions and crop boxes', () {
    final offsetPortrait = ReceiptPdfInspector.detectDocumentSignals(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page /MediaBox [72 36 684 828] >> endobj\n'
              '%%EOF'
          .codeUnits,
    );
    final reversedLandscape = ReceiptPdfInspector.detectDocumentSignals(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page /MediaBox [792 612 0 0] >> endobj\n'
              '%%EOF'
          .codeUnits,
    );
    final croppedLandscape = ReceiptPdfInspector.detectDocumentSignals(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page /CropBox [18 18 810 630] >> endobj\n'
              '%%EOF'
          .codeUnits,
    );

    expect(offsetPortrait, contains(ReceiptPdfInspector.portraitPageSignal));
    expect(
      offsetPortrait,
      isNot(contains(ReceiptPdfInspector.landscapePageSignal)),
    );
    expect(
      reversedLandscape,
      contains(ReceiptPdfInspector.landscapePageSignal),
    );
    expect(croppedLandscape, contains(ReceiptPdfInspector.landscapePageSignal));
    expect(croppedLandscape, contains(ReceiptPdfInspector.croppedPageSignal));
  });

  test('PDF text-layer signals include simple hex encoded receipt text', () {
    final hexTextLayer = ReceiptPdfInspector.detectDocumentSignals(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page /Contents 2 0 R >> endobj\n'
              '2 0 obj << >> stream BT /F1 12 Tf <544F54414C2031322E3334> Tj ET endstream endobj\n'
              '%%EOF'
          .codeUnits,
    );

    expect(hexTextLayer, contains(ReceiptPdfInspector.textLayerSignal));
    expect(hexTextLayer, contains('total'));
  });

  test('PDF text-layer signals include UTF-16 hex encoded receipt text', () {
    final utf16TextLayer = ReceiptPdfInspector.detectDocumentSignals(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page /Contents 2 0 R >> endobj\n'
              '2 0 obj << >> stream BT /F1 12 Tf <FEFF0053005500420054004F00540041004C002000310032002E00330034> Tj ET endstream endobj\n'
              '%%EOF'
          .codeUnits,
    );

    expect(utf16TextLayer, contains(ReceiptPdfInspector.textLayerSignal));
    expect(utf16TextLayer, contains('subtotal'));
  });

  test('PDF UTF-16 text signals skip binary hex payloads safely', () {
    final binaryHexLayer = ReceiptPdfInspector.detectDocumentSignals(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page /Contents 2 0 R >> endobj\n'
              '2 0 obj << >> stream BT /F1 12 Tf <FEFF000100020003> Tj ET endstream endobj\n'
              '%%EOF'
          .codeUnits,
    );

    expect(binaryHexLayer, contains(ReceiptPdfInspector.textLayerSignal));
    expect(binaryHexLayer, isNot(contains('subtotal')));
    expect(binaryHexLayer, isNot(contains('total')));
  });

  test(
    'PDF warnings do not expose private embedded text or source paths',
    () async {
      final file = File('${Directory.systemTemp.path}/private_pdf_warning.pdf');
      await file.writeAsString(
        '%PDF-1.7\n'
        '1 0 obj << /Type /Page /Annots [] /JavaScript 2 0 R >> endobj\n'
        '2 0 obj << >> stream BT (Jane Customer private@example.com card 4242 TOTAL 12.34) Tj ET endstream endobj\n'
        '%%EOF',
        flush: true,
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final inspection = await ReceiptPdfInspector.inspect(file.path);
      final warning = inspection.userWarning ?? '';

      expect(warning, contains('embedded JavaScript'));
      expect(warning, isNot(contains('Jane Customer')));
      expect(warning, isNot(contains('private@example.com')));
      expect(warning, isNot(contains('4242')));
      expect(warning, isNot(contains(file.path)));
      expect(inspection.documentSignals, contains('total'));
      expect(inspection.documentSignals, contains('card'));
      expect(inspection.documentSignals, isNot(contains('Jane Customer')));
    },
  );

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
