import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/document_engine/document_engine_core.dart';
import 'package:maintaniac/shared/document_engine/maintainiac_document_engine.dart'
    as document_engine;

void main() {
  test('Document Engine entrypoint exposes canonical shared primitives', () {
    final document = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice',
      fileName: 'invoice.pdf',
      bytes: Uint8List.fromList('%PDF-1.7\nEngine proof\n%%EOF'.codeUnits),
      createdAt: DateTime.utc(2026, 7, 6),
      sourceModule: MaintainiacDocumentSourceModule.documentEngine,
    );

    expect(document.validation.isValid, isTrue);
    expect(AppPdfFormatters.money(12.3), r'$12.30');
    expect(MaintainiacDocumentSourceModule.receipts, 'receipts');
    expect(MaintainiacDocumentSourceModule.jobs, 'jobs');
    expect(
      document_engine.AppGeneratedPdfFileName.clean('invoice.pdf.exe'),
      'invoice.pdf',
    );
  });

  test('Document Engine entrypoints remain inside shared ownership', () {
    final core = File(
      'lib/shared/document_engine/document_engine_core.dart',
    ).readAsStringSync();
    final ui = File(
      'lib/shared/document_engine/document_engine_ui.dart',
    ).readAsStringSync();
    final all = '$core\n$ui';

    expect(all, contains('../pdf/app_generated_pdf_models.dart'));
    expect(all, contains('../documents/app_document_export_manifest.dart'));
    expect(all, contains('document_engine_source_modules.dart'));
    expect(all, isNot(contains('../../screens/')));
    expect(all, isNot(contains('work_supply')));
    expect(all, isNot(contains('camera')));
    expect(all, isNot(contains('ocr')));
  });
}
