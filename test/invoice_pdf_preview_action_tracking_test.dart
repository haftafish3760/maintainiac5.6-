import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_models.dart';
import 'package:maintaniac/screens/invoices/data/invoice_ledger_store.dart';
import 'package:maintaniac/screens/invoices/home/invoice_form_screen.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_service.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  testWidgets('invoice preview records generated share and print pdf events', (
    tester,
  ) async {
    final appState = AppStateController();
    final odometer = GlobalOdometerController();
    final ledger = InvoiceLedgerStore.memory();
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
              home: InvoiceFormScreen(pdfPreviewService: pdfService),
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
              home: InvoiceFormScreen(pdfPreviewService: pdfService),
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
      find.text('Maintaniac could not prepare this PDF right now.'),
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
                home: InvoiceFormScreen(pdfPreviewService: pdfService),
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

  testWidgets('final save records PDF metadata without archiving a PDF', (
    tester,
  ) async {
    final appState = AppStateController();
    final odometer = GlobalOdometerController();
    final ledger = InvoiceLedgerStore.memory();
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
                pdfPreviewService: _FakeGeneratedPdfService(
                  tempPath: '/tmp/maintainiac-invoice-final-save.pdf',
                ),
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
          .where((event) => event.type == InvoicePdfDeliveryEventType.generated)
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
    ]);
    expect(record.pdfEvents.single.fileHashSha256, hasLength(64));
    expect(record.pdfEvents.single.byteSize, greaterThan(0));
    expect(record.toMap().containsKey('pdfBytes'), isFalse);
    expect(record.toMap().containsKey('pdfPath'), isFalse);
  });
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
        'Maintaniac could not prepare this PDF right now.',
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
