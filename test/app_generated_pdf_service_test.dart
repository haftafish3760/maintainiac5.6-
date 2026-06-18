import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_handoff.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_pdf_preview_factory.dart';
import 'package:maintaniac/shared/documents/app_document_models.dart';
import 'package:maintaniac/shared/documents/app_document_store.dart';
import 'package:maintaniac/shared/documents/app_generated_pdf_archive_service.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temporaryDirectory;
  late Directory documentsDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'generated_pdf_service_',
    );
    documentsDirectory = await Directory.systemTemp.createTemp(
      'generated_pdf_archive_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getTemporaryDirectory' => temporaryDirectory.path,
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
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
    if (await documentsDirectory.exists()) {
      await documentsDirectory.delete(recursive: true);
    }
  });

  test('invoice estimate preview creates a generated estimate PDF', () async {
    final document = await const InvoicePdfPreviewFactory()
        .buildEstimatePreview();

    expect(document.kind, AppGeneratedPdfKind.estimate);
    expect(document.safeFileName, 'maintainiac_estimate_preview.pdf');
    expect(document.bytes, isNotEmpty);
    expect(document.shareSubject, contains('estimate'));
  });

  test('expense export summary uses the shared generated PDF model', () async {
    final snapshot = buildExpenseExportSnapshot(
      receipts: const [],
      range: ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
      exportedAt: DateTime.utc(2026, 6, 15),
    );

    final document = await buildExpenseExportSummaryPdf(snapshot);

    expect(document.kind, AppGeneratedPdfKind.expenseExport);
    expect(document.sourceModule, 'expenses');
    expect(document.safeFileName, contains('2026-06-01_to_2026-06-30'));
    expect(document.bytes, isNotEmpty);
  });

  test('generated PDF service writes safe temporary PDF files', () async {
    final document = await const InvoicePdfPreviewFactory()
        .buildEstimatePreview();
    final generated = await const AppGeneratedPdfService().writeTemporary(
      document,
    );

    expect(generated.path, contains('maintaniac_generated_pdfs'));
    expect(generated.path, endsWith('.pdf'));
    expect(await File(generated.path).exists(), isTrue);
    expect(await File(generated.path).length(), document.byteSize);
  });

  test('generated PDF service cleans only old generated files', () async {
    final document = await const InvoicePdfPreviewFactory()
        .buildEstimatePreview();
    final generated = await const AppGeneratedPdfService().writeTemporary(
      document,
    );
    final kept = await const AppGeneratedPdfService().writeTemporary(document);
    final oldFile = File(generated.path);
    final newFile = File(kept.path);
    final oldStamp = DateTime(2026, 6, 1);
    await oldFile.setLastModified(oldStamp);
    await newFile.setLastModified(DateTime(2026, 6, 15));

    await const AppGeneratedPdfService().cleanOldGeneratedFiles(
      olderThan: Duration(days: 7),
      now: DateTime(2026, 6, 15),
    );

    expect(await oldFile.exists(), isFalse);
    expect(await newFile.exists(), isTrue);
  });

  test('generated invoice PDF archives as a permanent app document', () async {
    final store = AppDocumentStore.memory();
    final document = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice INV-42',
      fileName: 'invoice_INV-42.pdf',
      bytes: Uint8List.fromList('%PDF-1.7\n%%EOF'.codeUnits),
      createdAt: DateTime(2026, 6, 15),
      sourceModule: 'invoices',
      sourceRecordId: 'invoice_42',
    );

    final archived = await AppGeneratedPdfArchiveService(
      store: store,
    ).archive(document);

    expect(archived.document.kind, AppDocumentKind.invoiceDocument);
    expect(archived.document.id, 'DOC-invoice-invoice_42');
    expect(archived.attachment.linkedModule, 'invoices');
    expect(archived.attachment.linkedRecordId, 'invoice_42');
    expect(archived.attachment.fileHash, archived.fileHashSha256);
    expect(archived.attachment.storageState.name, 'permanent');
    expect(await File(archived.attachment.path).exists(), isTrue);
    expect(
      archived.attachment.path,
      contains('app_documents/invoices/generated_pdfs'),
    );
    expect(store.recordById('DOC-invoice-invoice_42'), isNotNull);
  });
}
