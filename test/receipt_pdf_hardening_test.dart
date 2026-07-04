import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_limits.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_viewer_screen.dart';

import 'helpers/pdf_test_typography.dart';

void main() {
  test('valid PDF is accepted with estimated page count status', () async {
    final file = File('${Directory.systemTemp.path}/valid_status_receipt.pdf');
    final pdfTheme = await PdfTestTypography.loadTheme();
    final pdf = pw.Document()
      ..addPage(pw.Page(theme: pdfTheme, build: (_) => pw.Text('Receipt')));
    await file.writeAsBytes(await pdf.save(), flush: true);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.importBlocker, isNull);
    expect(inspection.validationStatus, ReceiptPdfValidationStatus.valid);
    expect(inspection.pageCountStatus, ReceiptPdfPageCountStatus.estimated);
    expect(inspection.validationWarning, contains('estimated'));
    expect(
      inspection.handlingDisposition,
      ReceiptPdfHandlingDisposition.assistedReadWithWarning,
    );
  });

  test('unknown page count is accepted as proof with safe warning', () async {
    final file = File('${Directory.systemTemp.path}/unknown_pages.pdf');
    await file.writeAsString('%PDF-1.7\n%%EOF', flush: true);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.importBlocker, isNull);
    expect(
      inspection.validationStatus,
      ReceiptPdfValidationStatus.pageCountUnknown,
    );
    expect(inspection.pageCountStatus, ReceiptPdfPageCountStatus.unknown);
    expect(inspection.validationWarning, contains('could not be confirmed'));
  });

  test('invalid PDF header and zero-byte file are rejected', () async {
    final empty = File('${Directory.systemTemp.path}/zero_hardening.pdf');
    final renamed = File('${Directory.systemTemp.path}/renamed_hardening.pdf');
    await empty.writeAsBytes(const [], flush: true);
    await renamed.writeAsString('not a pdf', flush: true);
    addTearDown(() {
      if (empty.existsSync()) empty.deleteSync();
      if (renamed.existsSync()) renamed.deleteSync();
    });

    final emptyInspection = await ReceiptPdfInspector.inspect(empty.path);
    final renamedInspection = await ReceiptPdfInspector.inspect(renamed.path);

    expect(emptyInspection.validationStatus, ReceiptPdfValidationStatus.empty);
    expect(emptyInspection.importBlocker, contains('empty'));
    expect(
      renamedInspection.validationStatus,
      ReceiptPdfValidationStatus.invalidHeader,
    );
    expect(renamedInspection.importBlocker, contains('valid PDF'));
  });

  test(
    'file exactly at hard byte limit is allowed but one byte over blocks',
    () async {
      final allowed = File('${Directory.systemTemp.path}/at_pdf_limit.pdf');
      final blocked = File('${Directory.systemTemp.path}/over_pdf_limit.pdf');
      await _writeSparsePdfHeader(allowed, ReceiptPdfLimits.maxPdfBytes);
      await _writeSparsePdfHeader(blocked, ReceiptPdfLimits.maxPdfBytes + 1);
      addTearDown(() {
        if (allowed.existsSync()) allowed.deleteSync();
        if (blocked.existsSync()) blocked.deleteSync();
      });

      final allowedInspection = await ReceiptPdfInspector.inspect(allowed.path);
      final blockedInspection = await ReceiptPdfInspector.inspect(blocked.path);

      expect(allowedInspection.exceedsImportSizeLimit, isFalse);
      expect(allowedInspection.importBlocker, isNull);
      expect(blockedInspection.exceedsImportSizeLimit, isTrue);
      expect(
        blockedInspection.validationStatus,
        ReceiptPdfValidationStatus.tooLarge,
      );
      expect(blockedInspection.pageCount, isNull);
      expect(
        blockedInspection.pageCountStatus,
        ReceiptPdfPageCountStatus.unknown,
      );
      expect(blockedInspection.importBlocker, contains('too large'));
    },
  );

  test('very long PDF is warned but still attachable as proof', () async {
    final file = File('${Directory.systemTemp.path}/too_many_pages.pdf');
    final pdf = pw.Document();
    final pdfTheme = await PdfTestTypography.loadTheme();
    for (
      var index = 0;
      index < ReceiptPdfLimits.hardPdfPageLimit + 1;
      index++
    ) {
      pdf.addPage(
        pw.Page(theme: pdfTheme, build: (_) => pw.Text('Receipt page $index')),
      );
    }
    await file.writeAsBytes(await pdf.save(), flush: true);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.exceedsHardReceiptPageLimit, isTrue);
    expect(inspection.importBlocker, isNull);
    expect(inspection.canUseAssistedRead, isFalse);
    expect(inspection.assistedReadBlocker, contains('too long'));
    expect(inspection.longReceiptWarning, contains('too long'));
    expect(inspection.longReceiptWarning, contains('read-only proof'));
    expect(inspection.userWarning, contains('estimated'));
    expect(inspection.userWarning, contains('too long'));
  });

  test('large PDFs are sampled without losing safe proof handling', () async {
    final file = File('${Directory.systemTemp.path}/sampled_large_pdf.pdf');
    await _writeSparsePdfWithTail(
      file,
      ReceiptPdfLimits.localAssistedReadBytes + 1024,
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.importBlocker, isNull);
    expect(inspection.pageCount, 1);
    expect(inspection.riskFlags, isNot(contains('missing EOF marker')));
    expect(inspection.exceedsLocalReadSizeLimit, isTrue);
    expect(inspection.canUseAssistedRead, isFalse);
    expect(inspection.canAttachAsProof, isTrue);
  });

  test(
    'PDF active content is flagged as a warning instead of a hard blocker',
    () async {
      final file = File('${Directory.systemTemp.path}/active_content.pdf');
      await file.writeAsString(
        '%PDF-1.7\n'
        '1 0 obj << /Type /Page /Annots [] /JavaScript 2 0 R /URI (https://example.com) >> endobj\n'
        '2 0 obj << /EmbeddedFile 3 0 R /AcroForm 4 0 R >> endobj\n'
        '%%EOF',
        flush: true,
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final inspection = await ReceiptPdfInspector.inspect(file.path);

      expect(inspection.importBlocker, isNull);
      expect(inspection.riskFlags, contains('embedded JavaScript'));
      expect(inspection.riskFlags, contains('external links'));
      expect(inspection.riskFlags, contains('embedded files'));
      expect(inspection.validationWarning, contains('will not run scripts'));
      expect(inspection.canAttachAsProof, isTrue);
      expect(inspection.canUseAssistedRead, isFalse);
      expect(inspection.assistedReadBlocker, contains('active content'));
    },
  );

  test(
    'PDF active actions are warned without blocking read-only proof',
    () async {
      final file = File('${Directory.systemTemp.path}/active_actions.pdf');
      await file.writeAsString(
        '%PDF-1.7\n'
        '1 0 obj << /Type /Page /OpenAction 2 0 R /AA 3 0 R >> endobj\n'
        '2 0 obj << /Launch 4 0 R /RichMedia 5 0 R /SubmitForm 6 0 R >> endobj\n'
        '%%EOF',
        flush: true,
      );
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });

      final inspection = await ReceiptPdfInspector.inspect(file.path);

      expect(inspection.importBlocker, isNull);
      expect(inspection.canAttachAsProof, isTrue);
      expect(inspection.riskFlags, contains('auto-open actions'));
      expect(inspection.riskFlags, contains('launch actions'));
      expect(inspection.riskFlags, contains('automatic actions'));
      expect(inspection.riskFlags, contains('embedded media'));
      expect(inspection.riskFlags, contains('form submission actions'));
      expect(inspection.validationWarning, contains('will not run scripts'));
      expect(inspection.canAttachAsProof, isTrue);
      expect(inspection.canUseAssistedRead, isFalse);
      expect(
        inspection.handlingDisposition,
        ReceiptPdfHandlingDisposition.proofOnly,
      );
    },
  );

  test('PDF risk names avoid accidental substring matches', () async {
    final file = File('${Directory.systemTemp.path}/risk_substrings.pdf');
    await file.writeAsString(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page /Aardvark true /JsonThing true >> endobj\n'
      '%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.importBlocker, isNull);
    expect(inspection.riskFlags, isNot(contains('embedded JavaScript')));
    expect(inspection.riskFlags, isNot(contains('auto-open actions')));
    expect(inspection.riskFlags, isNot(contains('launch actions')));
    expect(inspection.riskFlags, isNot(contains('automatic actions')));
    expect(
      inspection.riskFlags,
      isNot(contains(ReceiptPdfInspector.encryptionRiskFlag)),
    );
  });

  test('PDF encryption marker is flagged for user review', () async {
    final file = File('${Directory.systemTemp.path}/encrypted_marker.pdf');
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

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.importBlocker, isNull);
    expect(inspection.riskFlags, contains('encryption or password security'));
    expect(inspection.assistedReadBlocker, contains('encrypted'));
    expect(
      inspection.handlingDisposition,
      ReceiptPdfHandlingDisposition.proofOnly,
    );
  });

  test('non-receipt looking PDF warns but remains attachable', () async {
    final file = File('${Directory.systemTemp.path}/manual_marker.pdf');
    await file.writeAsString(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page >> stream warranty policy manual endstream endobj\n'
      '%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.importBlocker, isNull);
    expect(inspection.documentSignals, contains('manual'));
    expect(inspection.documentSignals, contains('warranty'));
    expect(inspection.hasNonReceiptSignals, isTrue);
    expect(inspection.hasReceiptSignals, isFalse);
    expect(inspection.documentFitWarning, contains('more like'));
    expect(inspection.userWarning, contains('saved as proof'));
  });

  test('scanned PDF with no text receives a soft proof warning', () async {
    final file = File('${Directory.systemTemp.path}/scanned_no_text.pdf');
    await file.writeAsString(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page /Resources << /XObject << /Im1 2 0 R >> >> >> endobj\n'
      '2 0 obj << /Subtype /Image /Width 100 /Height 400 >> stream image-data-only endstream endobj\n'
      '%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.importBlocker, isNull);
    expect(
      inspection.documentSignals,
      contains(ReceiptPdfInspector.imageContentSignal),
    );
    expect(inspection.documentFitWarning, contains('scanned'));
    expect(inspection.userWarning, contains('saved as proof'));
    expect(inspection.assistedReadBlocker, isNull);
  });

  test('PDF missing EOF is warned but remains attachable as proof', () async {
    final file = File('${Directory.systemTemp.path}/missing_eof_marker.pdf');
    await file.writeAsString(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page >> stream receipt total tax endstream endobj\n',
      flush: true,
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.importBlocker, isNull);
    expect(inspection.riskFlags, contains('missing EOF marker'));
    expect(inspection.validationWarning, contains('missing EOF marker'));
    expect(inspection.canAttachAsProof, isTrue);
  });

  test('blocked PDFs report blocked handling disposition', () async {
    final file = File('${Directory.systemTemp.path}/blocked_disposition.pdf');
    await file.writeAsString('not a pdf', flush: true);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.importBlocker, isNotNull);
    expect(
      inspection.handlingDisposition,
      ReceiptPdfHandlingDisposition.blocked,
    );
    expect(inspection.canAttachAsProof, isFalse);
  });

  test('PDF viewer preview is capped without changing saved proof', () {
    expect(receiptPdfPreviewPageLimit(null), 10);
    expect(receiptPdfPreviewPageLimit(1), 1);
    expect(receiptPdfPreviewPageLimit(10), 10);
    expect(receiptPdfPreviewPageLimit(11), 10);
    expect(
      receiptPdfPreviewPageLimit(
        ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater + 1,
      ),
      5,
    );
    expect(receiptPdfPreviewPageLimit(75), 5);
    expect(
      receiptPdfPreviewPageLimit(ReceiptPdfLimits.hardPdfPageLimit + 1),
      3,
    );
  });

  test('PDF viewer preview plan reduces work for long documents', () {
    final normal = receiptPdfPreviewPlanForPageCount(3);
    final long = receiptPdfPreviewPlanForPageCount(
      ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater + 1,
    );
    final huge = receiptPdfPreviewPlanForPageCount(
      ReceiptPdfLimits.hardPdfPageLimit + 1,
    );

    expect(normal.isReduced, isFalse);
    expect(normal.dpi, 150);
    expect(long.isReduced, isTrue);
    expect(long.pageLimit, 5);
    expect(long.dpi, 132);
    expect(huge.isReduced, isTrue);
    expect(huge.pageLimit, 3);
    expect(huge.dpi, 120);
  });

  test('PDF preview failure states explain saved proof clearly', () {
    expect(ReceiptPdfPreviewStatus.missing.message, contains('reattached'));
    expect(
      ReceiptPdfPreviewStatus.unreadable.message,
      contains('not editable'),
    );
    expect(
      ReceiptPdfPreviewStatus.renderFailed.message,
      contains('saved as read-only proof'),
    );
    expect(
      ReceiptPdfPreviewStatus.tooLargeForPreview.message,
      contains('too large to preview automatically'),
    );
    expect(
      ReceiptPdfPreviewStatus.proofOnlyPreviewSkipped.message,
      contains('skipped automatic preview'),
    );
    expect(
      ReceiptPdfPreviewStatus.noPreviewPages.message,
      contains('saved as read-only proof'),
    );
  });

  test('PDF viewer summary keeps proof read-only and shows read limits', () {
    const inspection = ReceiptPdfInspection(
      path: '/tmp/long.pdf',
      exists: true,
      byteSize: 2048,
      pageCount: ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater + 4,
      hasPdfHeader: true,
      pageCountStatus: ReceiptPdfPageCountStatus.estimated,
      validationStatus: ReceiptPdfValidationStatus.valid,
    );

    final summary = ReceiptPdfViewerSummary.fromInspection(inspection);

    const pageCount = ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater + 4;
    const readLimit = ReceiptPdfLimits.maxPdfPagesForReceiptOcrLater;
    expect(summary.detailLabels, contains('2.0 KB'));
    expect(summary.detailLabels, contains('$pageCount pages'));
    expect(summary.detailLabels, contains('read-only proof'));
    expect(summary.detailLabels, contains('no PDF editing'));
    expect(summary.detailLabels, contains('reads first $readLimit pages'));
    expect(summary.warning, contains('page count is estimated'));
    expect(summary.warning, contains('only read the first $readLimit pages'));
  });

  test('PDF viewer summary marks encrypted PDFs as proof only', () {
    const inspection = ReceiptPdfInspection(
      path: '/tmp/encrypted.pdf',
      exists: true,
      byteSize: 4096,
      pageCount: 1,
      hasPdfHeader: true,
      pageCountStatus: ReceiptPdfPageCountStatus.estimated,
      validationStatus: ReceiptPdfValidationStatus.valid,
      riskFlags: [ReceiptPdfInspector.encryptionRiskFlag],
    );

    final summary = ReceiptPdfViewerSummary.fromInspection(inspection);

    expect(summary.detailLabels, contains('Save as proof only'));
    expect(summary.detailLabels, contains('proof only'));
    expect(summary.detailLabels, contains('no PDF editing'));
    expect(summary.warning, contains('password security'));
  });
}

Future<void> _writeSparsePdfHeader(File file, int length) async {
  final raf = await file.open(mode: FileMode.write);
  try {
    await raf.writeFrom('%PDF-1.7\n'.codeUnits);
    await raf.truncate(length);
  } finally {
    await raf.close();
  }
}

Future<void> _writeSparsePdfWithTail(File file, int length) async {
  final raf = await file.open(mode: FileMode.write);
  try {
    await raf.writeFrom(
      '%PDF-1.7\n'
              '1 0 obj << /Type /Page >> stream receipt total tax endstream endobj\n'
          .codeUnits,
    );
    await raf.setPosition(length - 6);
    await raf.writeFrom('%%EOF\n'.codeUnits);
  } finally {
    await raf.close();
  }
}
