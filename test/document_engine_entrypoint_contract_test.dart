import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/document_engine/document_engine_core.dart';
import 'package:maintaniac/shared/document_engine/maintainiac_document_engine.dart'
    as document_engine;

void main() {
  test('Document Engine core entrypoint exposes shared PDF primitives', () {
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
    expect(MaintainiacDocumentSourceModule.expenses, 'expenses');
    expect(MaintainiacDocumentSourceModule.invoices, 'invoices');
    expect(AppPdfPrivacyPolicy.issueCodesForExport(bytes: const []), isEmpty);
    expect(
      document_engine.AppGeneratedPdfFileName.clean('invoice.pdf.exe'),
      'invoice.pdf',
    );
  });

  test('migrated PDF adapters use engine-owned source module constants', () {
    final sourceModuleFiles = {
      'lib/screens/expenses/data/expense_export_handoff.dart':
          MaintainiacDocumentSourceModule.expenses,
      'lib/screens/invoices/data/invoice_pdf_preview_factory.dart':
          MaintainiacDocumentSourceModule.invoices,
    };

    for (final entry in sourceModuleFiles.entries) {
      final source = File(entry.key).readAsStringSync();
      expect(
        source,
        contains('MaintainiacDocumentSourceModule.'),
        reason: '${entry.key} should use the Document Engine module registry.',
      );
      expect(
        source,
        isNot(contains("sourceModule: '${entry.value}'")),
        reason: '${entry.key} should not duplicate engine source labels.',
      );
    }
  });

  test(
    'screen PDF adapters import Document Engine instead of raw PDF parts',
    () {
      final migratedFiles = {
        'lib/screens/expenses/data/expense_export_handoff.dart',
        'lib/screens/invoices/data/invoice_pdf_preview_factory.dart',
        'lib/screens/invoices/data/invoice_pdf_template_renderer.dart',
        'lib/screens/invoices/data/invoice_pdf_export_verifier.dart',
        'lib/screens/invoices/data/invoice_pdf_privacy_guard.dart',
        'lib/screens/expenses/data/expense_export_models.dart',
        'lib/screens/invoices/data/invoice_record.dart',
        'lib/screens/invoices/data/invoice_ledger_models.dart',
        'lib/screens/invoices/home/invoice_form_screen.dart',
        'lib/screens/invoices/home/invoice_template_preview_screen.dart',
      };

      for (final path in migratedFiles) {
        final source = File(path).readAsStringSync();
        expect(
          source,
          contains("shared/document_engine/"),
          reason: '$path should call the shared Document Engine entrypoint.',
        );
        expect(
          source,
          isNot(contains("shared/pdf/")),
          reason: '$path should not reach around the Document Engine boundary.',
        );
        expect(
          source,
          isNot(contains("shared/documents/")),
          reason: '$path should not reach around the Document Engine boundary.',
        );
      }
    },
  );

  test('Document Engine entrypoint stays inside shared ownership', () {
    final core = File(
      'lib/shared/document_engine/document_engine_core.dart',
    ).readAsStringSync();
    final ui = File(
      'lib/shared/document_engine/document_engine_ui.dart',
    ).readAsStringSync();
    final all = '$core\n$ui';

    expect(all, contains("../pdf/app_generated_pdf_models.dart"));
    expect(all, contains("../documents/app_document_export_manifest.dart"));
    expect(all, contains("document_engine_source_modules.dart"));
    expect(all, isNot(contains("../../screens/expenses/")));
    expect(all, isNot(contains("../../screens/invoices/")));
    expect(all, isNot(contains("work_supply")));
    expect(all, isNot(contains("camera")));
    expect(all, isNot(contains("ocr")));
  });
}
