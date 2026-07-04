import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_handoff.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_pdf_preview_factory.dart';
import 'package:maintaniac/screens/invoices/data/invoice_record.dart';
import 'package:maintaniac/shared/documents/app_document_models.dart';
import 'package:maintaniac/shared/documents/app_document_store.dart';
import 'package:maintaniac/shared/documents/app_generated_pdf_archive_service.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_service.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_storage.dart';

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

  test(
    'expense export summary PDF is deterministic for same snapshot',
    () async {
      final snapshot = buildExpenseExportSnapshot(
        receipts: [
          ExpenseReceiptRecord(
            id: 'receipt-1',
            receiptDate: DateTime(2026, 6, 12),
            merchantName: 'Supply House',
            lines: const [
              ExpenseReceiptLineRecord(
                id: 'line-1',
                description: 'Pipe fittings',
                category: 'Materials',
                use: ExpenseLineUse.business,
                quantity: 1,
                unitsPerPackage: 1,
                unit: 'each',
                subtotal: 42.75,
              ),
            ],
          ),
        ],
        range: ExpenseDateRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
        categoryFilter: ExpenseExportCategoryFilter.all,
        exportedAt: DateTime.utc(2026, 6, 15),
      );

      final first = await buildExpenseExportSummaryPdf(snapshot);
      final second = await buildExpenseExportSummaryPdf(snapshot);

      expect(first.bytes, second.bytes);
      expect(
        sha256.convert(first.bytes).toString(),
        sha256.convert(second.bytes).toString(),
      );
    },
  );

  test('expense export summary uses shared PDF money formatting', () async {
    final snapshot = buildExpenseExportSnapshot(
      receipts: [
        ExpenseReceiptRecord(
          id: 'receipt-money',
          receiptDate: DateTime(2026, 6, 12),
          merchantName: 'Supply House',
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'line-small',
              description: 'Small adjustment',
              category: 'Materials',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 0.1,
            ),
            ExpenseReceiptLineRecord(
              id: 'line-refund',
              description: 'Returned fitting',
              category: 'Materials',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: -0.2,
            ),
          ],
        ),
      ],
      range: ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
      exportedAt: DateTime.utc(2026, 6, 15),
    );

    final document = await buildExpenseExportSummaryPdf(snapshot);
    final source = File(
      'lib/screens/expenses/data/expense_export_handoff.dart',
    ).readAsStringSync();

    expect(document.shareText, contains(r'Total: -$0.10'));
    expect(document.validation.isValid, isTrue);
    expect(source, contains('AppPdfFormatters.money(snapshot.total)'));
    expect(
      source,
      contains('AppPdfFormatters.money(receipt.totalForLine(line))'),
    );
  });

  test('generated PDF service writes safe temporary PDF files', () async {
    final document = await const InvoicePdfPreviewFactory()
        .buildEstimatePreview();
    final generated = await const AppGeneratedPdfService().writeTemporary(
      document,
    );

    expect(generated.path, contains('maintainiac_generated_pdfs'));
    expect(generated.path, endsWith('.pdf'));
    expect(await File(generated.path).exists(), isTrue);
    expect(await File(generated.path).length(), document.byteSize);
  });

  test('generated PDF destination allocator reserves partial files', () async {
    final directory = await temporaryDirectory.createTemp('pdf_names_');
    final existing = File('${directory.path}/invoice.pdf');
    final reserved = File('${directory.path}/invoice-copy-2.pdf.partial');
    await existing.writeAsString('%PDF-1.7\n%%EOF', flush: true);
    await reserved.writeAsString('partial', flush: true);

    final destination = await AppGeneratedPdfStorage.availableDestination(
      directory: directory,
      requestedFileName: 'invoice.pdf',
    );

    expect(destination, isNotNull);
    expect(destination!.path, endsWith('invoice-copy-3.pdf'));
  });

  test('generated PDF service verifies temporary byte count before rename', () {
    final source = File(
      'lib/shared/pdf/app_generated_pdf_service.dart',
    ).readAsStringSync();

    expect(source, contains('final writtenBytes = await partial.length();'));
    expect(source, contains('writtenBytes != document.byteSize'));
    expect(source, contains('final expectedHash = sha256.convert'));
    expect(source, contains('final actualHash = await sha256.bind'));
    expect(source, contains('final writtenHash = await sha256.bind'));
    expect(source, contains('writtenHash.toString() != expectedHash'));
    expect(source, contains('prepared file did not verify'));
    expect(
      source,
      contains("FileSystemException('Generated PDF write did not verify.')"),
    );
    expect(
      source,
      contains("FileSystemException('Generated PDF write was incomplete.')"),
    );
    expect(source, contains('await partial.rename(destination.path);'));
  });

  test('generated PDF share refuses same-size tampered files', () async {
    final document = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice',
      fileName: 'invoice.pdf',
      bytes: Uint8List.fromList('%PDF-1.7\nTotal 12.34\n%%EOF'.codeUnits),
      createdAt: DateTime(2026, 7, 4),
    );
    final tampered = File('${temporaryDirectory.path}/tampered.pdf');
    await tampered.writeAsBytes(
      Uint8List.fromList('%PDF-1.7\nTotal 56.78\n%%EOF'.codeUnits),
      flush: true,
    );

    await expectLater(
      const AppGeneratedPdfService().shareGeneratedFile(
        AppGeneratedPdfFile(
          document: document,
          path: tampered.path,
          byteSize: document.byteSize,
        ),
      ),
      throwsA(
        isA<AppGeneratedPdfException>().having(
          (error) => error.message,
          'message',
          contains('did not verify'),
        ),
      ),
    );
  });

  test('generated PDF model validates sendable PDF bytes and filenames', () {
    final document = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice',
      fileName:
          ' ACME:/invoice*with?bad<characters>|and a very very very very very very very very very very very long customer name ',
      bytes: Uint8List.fromList('%PDF-1.7\n1 0 obj\n%%EOF'.codeUnits),
      createdAt: DateTime(2026, 6, 15),
    );

    expect(document.validation.isValid, isTrue);
    expect(document.isSendablePdf, isTrue);
    expect(document.safeFileName, endsWith('.pdf'));
    expect(document.safeFileName, isNot(contains(':')));
    expect(document.safeFileName, isNot(contains('*')));
    expect(document.safeFileName.length, lessThanOrEqualTo(120));
    final defaultNameDocument = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice',
      fileName: '',
      bytes: Uint8List.fromList('%PDF-1.7\n%%EOF'.codeUnits),
      createdAt: DateTime(2026, 6, 15),
    );
    expect(defaultNameDocument.safeFileName, 'maintainiac-document.pdf');
  });

  test('generated PDF validation rejects invalid and active PDF bytes', () {
    final invalid = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice',
      fileName: 'invoice.pdf',
      bytes: Uint8List.fromList('not a pdf'.codeUnits),
      createdAt: DateTime(2026, 6, 15),
    );
    final active = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice',
      fileName: 'invoice.pdf',
      bytes: Uint8List.fromList(
        '%PDF-1.7\n1 0 obj << /JavaScript (bad) >> endobj\n%%EOF'.codeUnits,
      ),
      createdAt: DateTime(2026, 6, 15),
    );

    expect(invalid.validation.isValid, isFalse);
    expect(invalid.validation.hasIssue('missing_pdf_header'), isTrue);
    expect(invalid.validation.hasIssue('missing_pdf_end_marker'), isTrue);
    expect(active.validation.isValid, isFalse);
    expect(active.validation.hasIssue('active_javascript'), isTrue);
  });

  test('generated PDF validation shares active-content policy coverage', () {
    final active = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice',
      fileName: 'invoice.pdf',
      bytes: Uint8List.fromList(
        '%PDF-1.7\n'
                '1 0 obj << /Type /Page /OpenAction 2 0 R /AA 3 0 R >> endobj\n'
                '2 0 obj << /Launch 4 0 R /RichMedia 5 0 R /SubmitForm 6 0 R >> endobj\n'
                '3 0 obj << /EmbeddedFile 7 0 R /URI (https://example.com) >> endobj\n'
                '%%EOF'
            .codeUnits,
      ),
      createdAt: DateTime(2026, 7, 4),
    );

    expect(active.validation.isValid, isFalse);
    expect(active.validation.hasIssue('auto_open_action'), isTrue);
    expect(active.validation.hasIssue('active_launch_action'), isTrue);
    expect(active.validation.hasIssue('automatic_action'), isTrue);
    expect(active.validation.hasIssue('embedded_file'), isTrue);
    expect(active.validation.hasIssue('embedded_media'), isTrue);
    expect(active.validation.hasIssue('form_submission_action'), isTrue);
    expect(active.validation.hasIssue('external_links'), isTrue);
  });

  test(
    'generated PDF service refuses incomplete PDFs before writing',
    () async {
      final document = AppGeneratedPdfDocument(
        kind: AppGeneratedPdfKind.invoice,
        title: 'Invoice INV-BAD',
        fileName: 'invoice_bad.pdf',
        bytes: Uint8List.fromList('%PDF-1.7\nmissing end marker'.codeUnits),
        createdAt: DateTime(2026, 6, 15),
      );

      await expectLater(
        const AppGeneratedPdfService().writeTemporary(document),
        throwsA(isA<AppGeneratedPdfException>()),
      );
      expect(
        await Directory(
          '${temporaryDirectory.path}/maintainiac_generated_pdfs',
        ).exists(),
        isFalse,
      );
    },
  );

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

  test('generated PDF cleanup does not delete non-PDF files', () async {
    final document = await const InvoicePdfPreviewFactory()
        .buildEstimatePreview();
    final generated = await const AppGeneratedPdfService().writeTemporary(
      document,
    );
    final generatedDirectory = File(generated.path).parent;
    final oldPdf = File(generated.path);
    final oldPartial = File('${generatedDirectory.path}/stale.pdf.partial');
    final keepText = File('${generatedDirectory.path}/do-not-delete.txt');
    final keepImage = File('${generatedDirectory.path}/preview.png');
    final oldStamp = DateTime(2026, 6, 1);

    await oldPartial.writeAsString('partial', flush: true);
    await keepText.writeAsString('operator note', flush: true);
    await keepImage.writeAsBytes([137, 80, 78, 71], flush: true);
    await oldPdf.setLastModified(oldStamp);
    await oldPartial.setLastModified(oldStamp);
    await keepText.setLastModified(oldStamp);
    await keepImage.setLastModified(oldStamp);

    await const AppGeneratedPdfService().cleanOldGeneratedFiles(
      olderThan: Duration(days: 7),
      now: DateTime(2026, 6, 15),
    );

    expect(await oldPdf.exists(), isFalse);
    expect(await oldPartial.exists(), isFalse);
    expect(await keepText.exists(), isTrue);
    expect(await keepImage.exists(), isTrue);
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

  test(
    'record invoice PDF is sendable, safe-named, archived, and not stored in ledger',
    () async {
      final store = AppDocumentStore.memory();
      final record = _invoiceRecord(
        id: 'invoice_lifecycle',
        number: 'INV/42:ACME*June?',
      );

      final document = await const InvoicePdfPreviewFactory()
          .buildRecordPreview(record: record);
      final recordMap = record.toMap();

      expect(document.kind, AppGeneratedPdfKind.invoice);
      expect(document.title, 'Invoice INV/42:ACME*June?');
      expect(document.sourceModule, 'invoices');
      expect(document.sourceRecordId, 'invoice_lifecycle');
      expect(document.safeFileName, endsWith('.pdf'));
      expect(document.safeFileName, isNot(contains('/')));
      expect(document.safeFileName, isNot(contains(':')));
      expect(document.safeFileName, isNot(contains('*')));
      expect(document.validation.isValid, isTrue);
      expect(recordMap.containsKey('pdfBytes'), isFalse);
      expect(recordMap.containsKey('pdfPath'), isFalse);

      final generated = await const AppGeneratedPdfService().writeTemporary(
        document,
      );
      expect(await File(generated.path).length(), document.byteSize);

      final archived = await AppGeneratedPdfArchiveService(
        store: store,
      ).archive(document);

      expect(archived.document.kind, AppDocumentKind.invoiceDocument);
      expect(archived.document.id, 'DOC-invoice-invoice_lifecycle');
      expect(archived.attachment.linkedModule, 'invoices');
      expect(archived.attachment.linkedRecordId, 'invoice_lifecycle');
      expect(archived.attachment.originalFileName, document.safeFileName);
      expect(archived.attachment.byteSize, document.byteSize);
      expect(archived.fileHashSha256, hasLength(64));
      expect(await File(archived.attachment.path).exists(), isTrue);
      expect(store.recordById(archived.document.id), isNotNull);
    },
  );

  test('generated PDF archive replaces old app-owned proof file', () async {
    final store = AppDocumentStore.memory();
    final first = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice INV-REPLACE',
      fileName: 'invoice_replace.pdf',
      bytes: Uint8List.fromList('%PDF-1.7\nTotal 10.00\n%%EOF'.codeUnits),
      createdAt: DateTime(2026, 7, 4),
      sourceModule: 'invoices',
      sourceRecordId: 'invoice_replace',
    );
    final second = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.invoice,
      title: 'Invoice INV-REPLACE',
      fileName: 'invoice_replace.pdf',
      bytes: Uint8List.fromList('%PDF-1.7\nTotal 20.00\n%%EOF'.codeUnits),
      createdAt: DateTime(2026, 7, 4),
      sourceModule: 'invoices',
      sourceRecordId: 'invoice_replace',
    );

    final firstArchived = await AppGeneratedPdfArchiveService(
      store: store,
    ).archive(first);
    final firstPath = firstArchived.attachment.path;
    final secondArchived = await AppGeneratedPdfArchiveService(
      store: store,
    ).archive(second);

    expect(firstArchived.document.id, secondArchived.document.id);
    expect(firstPath, isNot(secondArchived.attachment.path));
    expect(await File(firstPath).exists(), isFalse);
    expect(await File(secondArchived.attachment.path).exists(), isTrue);
    expect(
      store.recordById(secondArchived.document.id)!.attachments.single.path,
      secondArchived.attachment.path,
    );
  });

  test('record estimate PDF archives as invoice document proof', () async {
    final store = AppDocumentStore.memory();
    final record = _invoiceRecord(
      id: 'estimate_lifecycle',
      number: 'EST-12',
      type: InvoiceDocumentType.estimate,
    );

    final document = await const InvoicePdfPreviewFactory().buildRecordPreview(
      record: record,
    );
    final archived = await AppGeneratedPdfArchiveService(
      store: store,
    ).archive(document);

    expect(document.kind, AppGeneratedPdfKind.estimate);
    expect(document.title, 'Estimate EST-12');
    expect(document.sourceRecordId, 'estimate_lifecycle');
    expect(document.validation.isValid, isTrue);
    expect(archived.document.kind, AppDocumentKind.invoiceDocument);
    expect(archived.document.id, 'DOC-estimate-estimate_lifecycle');
    expect(archived.attachment.linkedRecordId, 'estimate_lifecycle');
    expect(archived.fileHashSha256, hasLength(64));
  });

  test(
    'generated PDF archive refuses invalid PDFs before permanent save',
    () async {
      final store = AppDocumentStore.memory();
      final document = AppGeneratedPdfDocument(
        kind: AppGeneratedPdfKind.invoice,
        title: 'Invoice INV-BAD',
        fileName: 'invoice_bad.pdf',
        bytes: Uint8List.fromList('not a pdf'.codeUnits),
        createdAt: DateTime(2026, 6, 15),
        sourceModule: 'invoices',
        sourceRecordId: 'invoice_bad',
      );

      await expectLater(
        AppGeneratedPdfArchiveService(store: store).archive(document),
        throwsA(isA<AppGeneratedPdfArchiveException>()),
      );
      expect(store.recordById('DOC-invoice-invoice_bad'), isNull);
    },
  );

  test(
    'generated PDF archive removes permanent file when record save fails',
    () async {
      final store = _FailingDocumentStore();
      final document = AppGeneratedPdfDocument(
        kind: AppGeneratedPdfKind.invoice,
        title: 'Invoice INV-ROLLBACK',
        fileName: 'invoice_rollback.pdf',
        bytes: Uint8List.fromList('%PDF-1.7\n%%EOF'.codeUnits),
        createdAt: DateTime(2026, 6, 15),
        sourceModule: 'invoices',
        sourceRecordId: 'invoice_rollback',
      );

      await expectLater(
        AppGeneratedPdfArchiveService(store: store).archive(document),
        throwsA(
          isA<AppGeneratedPdfArchiveException>().having(
            (error) => error.message,
            'message',
            contains('PDF file was not kept'),
          ),
        ),
      );

      final generatedDirectory = Directory(
        '${documentsDirectory.path}/app_documents/invoices/generated_pdfs',
      );
      final leftoverFiles = generatedDirectory.existsSync()
          ? generatedDirectory
                .listSync(recursive: true)
                .whereType<File>()
                .toList(growable: false)
          : <File>[];
      expect(leftoverFiles, isEmpty);
    },
  );

  test('generated PDF archive verifies permanent writes by hash', () {
    final source = File(
      'lib/shared/documents/app_generated_pdf_archive_service.dart',
    ).readAsStringSync();

    expect(source, contains('final writtenHash = await _safeHash(partial);'));
    expect(source, contains('sha256.convert(document.bytes).toString()'));
    expect(
      source,
      contains("FileSystemException('Generated PDF write did not verify.')"),
    );
    expect(source, contains('await _deleteIfExists(savedFile);'));
  });
}

InvoiceRecord _invoiceRecord({
  required String id,
  required String number,
  InvoiceDocumentType type = InvoiceDocumentType.invoice,
}) {
  final now = DateTime(2026, 6, 15, 9);
  return InvoiceRecord(
    id: id,
    documentType: type,
    invoiceNumber: number,
    numberMode: InvoiceNumberMode.manual,
    status: InvoiceRecordStatus.draft,
    title: 'Panel replacement',
    issueDate: now,
    dueDate: type == InvoiceDocumentType.invoice
        ? now.add(const Duration(days: 30))
        : null,
    company: const InvoicePartySnapshot(companyName: 'Jane Doe Services'),
    client: const InvoicePartySnapshot(
      displayName: 'Alex Customer',
      street: '987 Oak Road',
      phone: '(555) 123-5512',
    ),
    lines: const [
      InvoiceLineItemRecord(
        id: 'labor',
        name: 'Labor',
        details: 'Troubleshooting and repair time.',
        quantity: 2,
        unit: 'hour',
        unitPrice: 85,
        taxable: false,
      ),
      InvoiceLineItemRecord(
        id: 'materials',
        name: 'Materials',
        details: 'Breakers, wire, and small supplies.',
        quantity: 1,
        unit: 'job',
        unitPrice: 125,
        taxRate: 6,
      ),
    ],
    terms: 'Payment due on receipt.',
    meta: InvoiceSyncMetadata(createdAt: now, updatedAt: now),
  );
}

class _FailingDocumentStore extends AppDocumentStore {
  _FailingDocumentStore() : super.memory();

  @override
  Future<AppDocumentRecord> saveRecord(AppDocumentRecord record) async {
    throw StateError('simulated document-store failure');
  }
}
