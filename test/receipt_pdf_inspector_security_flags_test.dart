import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';

void main() {
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

  test('PDF escaped active names are flagged for user review', () async {
    final file = File('${Directory.systemTemp.path}/escaped_active_names.pdf');
    await file.writeAsString(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page /Open#41ction 2 0 R /Java#53cript 3 0 R /Embedded#46ile 4 0 R >> endobj\n'
      '%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });

    final inspection = await ReceiptPdfInspector.inspect(file.path);

    expect(inspection.importBlocker, isNull);
    expect(inspection.riskFlags, contains('embedded JavaScript'));
    expect(inspection.riskFlags, contains('auto-open actions'));
    expect(inspection.riskFlags, contains('embedded files'));
    expect(inspection.canUseAssistedRead, isFalse);
  });
}
