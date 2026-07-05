import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_store.dart';
import 'package:maintaniac/screens/invoices/home/invoice_form_screen.dart';
import 'package:maintaniac/shared/documents/app_document_models.dart';
import 'package:maintaniac/shared/documents/app_document_store.dart';
import 'package:maintaniac/shared/documents/app_generated_pdf_archive_service.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_service.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  testWidgets('invoice preview records generated share and print pdf events', (
    tester,
  ) async {
    final appState = AppStateController();
    final odometer = GlobalOdometerController();
    final ledger = InvoiceLedgerStore.memory();
    final recordId = await _createPdfReadyRecord(ledger);
    final pdfService = _FakeGeneratedPdfService(
      tempPath: '${Directory.systemTemp.path}/invoice-preview-actions.pdf',
    );
    addTearDown(appState.dispose);
    addTearDown(odometer.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: GlobalOdometerScope(
          controller: odometer,
          child: InvoiceLedgerScope(
            controller: ledger,
            child: MaterialApp(
              home: InvoiceFormScreen(
                recordId: recordId,
                pdfPreviewService: pdfService,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Preview'),
      find.byType(ListView).first,
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview'));
    await _pumpPdfPreview(tester);

    expect(find.text('Share or Save PDF'), findsOneWidget);
    expect(ledger.records.single.pdfEvents.map((event) => event.type), [
      InvoicePdfDeliveryEventType.generated,
    ]);

    await tester.tap(find.text('Share or Save PDF'));
    await _pumpPdfPreview(tester);
    await tester.tap(find.text('Print PDF'));
    await _pumpPdfPreview(tester);

    final events = ledger.records.single.pdfEvents;
    expect(events.map((event) => event.type), [
      InvoicePdfDeliveryEventType.generated,
      InvoicePdfDeliveryEventType.shared,
      InvoicePdfDeliveryEventType.printed,
    ]);
    expect(events.every((event) => event.fileName.endsWith('.pdf')), isTrue);
    expect(events.every((event) => event.byteSize > 0), isTrue);
    expect(pdfService.writeCount, 1);
  });

  testWidgets('invoice preview records prepare failure then successful retry', (
    tester,
  ) async {
    final appState = AppStateController();
    final odometer = GlobalOdometerController();
    final ledger = InvoiceLedgerStore.memory();
    final recordId = await _createPdfReadyRecord(ledger);
    final pdfService = _FakeGeneratedPdfService(
      tempPath: '${Directory.systemTemp.path}/invoice-preview-retry.pdf',
      failFirstWrite: true,
    );
    addTearDown(appState.dispose);
    addTearDown(odometer.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: GlobalOdometerScope(
          controller: odometer,
          child: InvoiceLedgerScope(
            controller: ledger,
            child: MaterialApp(
              home: InvoiceFormScreen(
                recordId: recordId,
                pdfPreviewService: pdfService,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Preview'),
      find.byType(ListView).first,
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Preview'));
    await _pumpPdfPreview(tester);

    expect(
      find.text('Maintainiac could not prepare this PDF right now.'),
      findsOneWidget,
    );
    var events = ledger.records.single.pdfEvents;
    expect(events.map((event) => event.type), [
      InvoicePdfDeliveryEventType.failed,
    ]);
    expect(events.single.reasonCode, 'prepare_pdf_validation_failed');

    await tester.tap(find.text('Try Again'));
    await _pumpPdfPreview(tester);

    expect(find.text('Share or Save PDF'), findsOneWidget);
    events = ledger.records.single.pdfEvents;
    expect(events.map((event) => event.type), [
      InvoicePdfDeliveryEventType.failed,
      InvoicePdfDeliveryEventType.generated,
    ]);
    expect(events.first.reasonCode, 'prepare_pdf_validation_failed');
    expect(events.last.fileName.endsWith('.pdf'), isTrue);
    expect(events.last.byteSize, greaterThan(0));
    expect(pdfService.writeCount, 2);
  });

  testWidgets(
    'invoice preview records dismissed share and print as cancelled',
    (tester) async {
      final appState = AppStateController();
      final odometer = GlobalOdometerController();
      final ledger = InvoiceLedgerStore.memory();
      final recordId = await _createPdfReadyRecord(ledger);
      final pdfService = _FakeGeneratedPdfService(
        tempPath: '${Directory.systemTemp.path}/invoice-preview-cancelled.pdf',
        shareStatus: ShareResultStatus.dismissed,
        printResult: false,
      );
      addTearDown(appState.dispose);
      addTearDown(odometer.dispose);

      await tester.pumpWidget(
        AppStateScope(
          controller: appState,
          child: GlobalOdometerScope(
            controller: odometer,
            child: InvoiceLedgerScope(
              controller: ledger,
              child: MaterialApp(
                home: InvoiceFormScreen(
                  recordId: recordId,
                  pdfPreviewService: pdfService,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Preview'),
        find.byType(ListView).first,
        const Offset(0, -220),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Preview'));
      await _pumpPdfPreview(tester);
      await tester.tap(find.text('Share or Save PDF'));
      await _pumpPdfPreview(tester);
      await tester.tap(find.text('Print PDF'));
      await _pumpPdfPreview(tester);

      final events = ledger.records.single.pdfEvents;
      expect(events.map((event) => event.type), [
        InvoicePdfDeliveryEventType.generated,
        InvoicePdfDeliveryEventType.cancelled,
        InvoicePdfDeliveryEventType.cancelled,
      ]);
      expect(events[1].reasonCode, 'share_sheet_dismissed');
      expect(events[2].reasonCode, 'print_flow_dismissed');
    },
  );

  testWidgets('final save records generated and archived pdf proof events', (
    tester,
  ) async {
    final appState = AppStateController();
    final odometer = GlobalOdometerController();
    final ledger = InvoiceLedgerStore.memory();
    final recordId = await _createPdfReadyRecord(ledger);
    final documentStore = AppDocumentStore.memory();
    addTearDown(appState.dispose);
    addTearDown(odometer.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: GlobalOdometerScope(
          controller: odometer,
          child: InvoiceLedgerScope(
            controller: ledger,
            child: MaterialApp(
              home: InvoiceFormScreen(
                recordId: recordId,
                pdfArchiveService: _FakeArchiveService(store: documentStore),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.text('Save Invoice'),
      find.byType(ListView).first,
      const Offset(0, -220),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save Invoice'));
    await _pumpUntil(
      tester,
      () => ledger.records.single.pdfEvents
          .where((event) => event.type == InvoicePdfDeliveryEventType.archived)
          .isNotEmpty,
      attempts: 120,
    );

    final record = ledger.records.single;
    final eventSummary = record.pdfEvents
        .map(
          (event) =>
              '${event.type.name}:${event.fileHashSha256}:${event.byteSize}',
        )
        .join('|');
    expect(record.documentHashSha256, hasLength(64), reason: eventSummary);
    expect(record.pdfEvents.map((event) => event.type), [
      InvoicePdfDeliveryEventType.generated,
      InvoicePdfDeliveryEventType.archived,
    ]);
    expect(record.pdfEvents.last.fileHashSha256, record.documentHashSha256);
    expect(record.pdfEvents.last.byteSize, greaterThan(0));
    expect(record.toMap().containsKey('pdfBytes'), isFalse);
    expect(record.toMap().containsKey('pdfPath'), isFalse);
    expect(documentStore.records, hasLength(1));
  });
}

Future<String> _createPdfReadyRecord(InvoiceLedgerStore ledger) async {
  final draft = await ledger.createDraft(
    type: InvoiceDocumentType.invoice,
    now: DateTime(2026, 7, 5, 10),
  );
  final saved = await ledger.saveRecord(
    draft.copyWith(
      company: const InvoicePartySnapshot(companyName: 'Maintainiac Repairs'),
      client: const InvoicePartySnapshot(displayName: 'Confirmed Customer'),
      lines: const [
        InvoiceLineItemRecord(
          id: 'labor-1',
          name: 'Confirmed service labor',
          details: 'User-confirmed invoice line item',
          quantity: 1,
          unit: 'hr',
          unitPrice: 125,
          taxable: false,
        ),
      ],
    ),
  );
  return saved.id;
}

Future<void> _pumpPdfPreview(WidgetTester tester) async {
  for (var index = 0; index < 8; index += 1) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int attempts = 40,
}) async {
  for (var index = 0; index < attempts; index += 1) {
    if (condition()) return;
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(condition(), isTrue, reason: 'Timed out waiting for async condition.');
}

class _FakeGeneratedPdfService extends AppGeneratedPdfService {
  _FakeGeneratedPdfService({
    required this.tempPath,
    this.failFirstWrite = false,
    this.shareStatus = ShareResultStatus.success,
    this.printResult = true,
  });

  final String tempPath;
  final bool failFirstWrite;
  final ShareResultStatus shareStatus;
  final bool printResult;
  var writeCount = 0;

  @override
  Future<AppGeneratedPdfFile> writeTemporary(
    AppGeneratedPdfDocument document,
  ) async {
    writeCount += 1;
    if (failFirstWrite && writeCount == 1) {
      throw const AppGeneratedPdfException(
        'Maintainiac could not prepare this PDF right now.',
      );
    }
    return AppGeneratedPdfFile(
      document: document,
      path: tempPath,
      byteSize: document.byteSize,
    );
  }

  @override
  Future<ShareResultStatus> shareGeneratedFile(
    AppGeneratedPdfFile generated,
  ) async {
    return shareStatus;
  }

  @override
  Future<bool> print(AppGeneratedPdfDocument document) async {
    return printResult;
  }
}

class _FakeArchiveService extends AppGeneratedPdfArchiveService {
  const _FakeArchiveService({required AppDocumentStore store})
    : super(store: store);

  @override
  Future<AppDocumentArchiveResult> archive(
    AppGeneratedPdfDocument document, {
    AppDocumentKind? kind,
    String title = '',
    String notes = '',
  }) async {
    final hash = sha256.convert(document.bytes).toString();
    final now = DateTime.now();
    final attachment = ReceiptAttachmentRecord(
      id: 'fake-${document.sourceRecordId}-pdf',
      path: '/tmp/${document.safeFileName}',
      kind: ReceiptAttachmentKind.pdf,
      dataSaverLevel: ReceiptDataSaverLevel.original,
      createdAt: now,
      displayName: document.safeFileName,
      originalFileName: document.safeFileName,
      mimeType: 'application/pdf',
      byteSize: document.byteSize,
      fileHash: hash,
      linkedModule: document.sourceModule,
      linkedRecordId: document.sourceRecordId,
      storageState: ReceiptAttachmentStorageState.permanent,
      promotedAt: now,
      readState: ReceiptAttachmentReadState.notRead,
    );
    final record = AppDocumentRecord(
      id: 'DOC-${document.kind.name}-${document.sourceRecordId}',
      kind: kind ?? AppDocumentKind.invoiceDocument,
      title: title.trim().isEmpty ? document.title : title.trim(),
      notes: notes,
      sourceLabel: 'Generated PDF',
      createdAt: now,
      updatedAt: now,
      attachments: [attachment],
    );
    final saved = await store!.saveRecord(record);
    return AppDocumentArchiveResult(
      document: saved,
      attachment: attachment,
      fileHashSha256: hash,
    );
  }
}
