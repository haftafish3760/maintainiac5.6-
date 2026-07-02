import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_limits.dart';

void main() {
  test('valid PDF is accepted with estimated page count status', () async {
    final file = File('${Directory.systemTemp.path}/valid_status_receipt.pdf');
    final pdf = pw.Document()
      ..addPage(pw.Page(build: (_) => pw.Text('Receipt')));
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
    for (
      var index = 0;
      index < ReceiptPdfLimits.hardPdfPageLimit + 1;
      index++
    ) {
      pdf.addPage(pw.Page(build: (_) => pw.Text('Receipt page $index')));
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
