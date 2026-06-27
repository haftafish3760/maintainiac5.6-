import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/app/incoming_receipt_destination_screen.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  testWidgets('message-only share shows notes and no proof summary', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: IncomingReceiptDestinationScreen(
          attachments: [],
          importedText: '',
          messages: [
            'Maintainiac received a link, not a receipt file.',
            'archive.zip could not be imported as receipt proof.',
          ],
        ),
      ),
    );

    expect(find.text('Import Shared Item'), findsOneWidget);
    expect(find.text('No receipt proof attached'), findsOneWidget);
    expect(
      find.textContaining('Choose the destination yourself'),
      findsOneWidget,
    );
    expect(find.text('Shared file notes'), findsOneWidget);
    expect(find.textContaining('received a link'), findsOneWidget);
    expect(find.textContaining('archive.zip'), findsOneWidget);
  });

  testWidgets('multiple shared PDFs show proof count and destination choices', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IncomingReceiptDestinationScreen(
          attachments: [_pdfAttachment('one'), _pdfAttachment('two')],
          importedText: '',
        ),
      ),
    );

    expect(find.text('2 receipt proofs attached'), findsOneWidget);
    expect(find.text('Receipt / Expense'), findsOneWidget);
    expect(find.text('Fuel Receipt'), findsOneWidget);
    expect(find.text('Materials / Inventory Receipt'), findsOneWidget);
    expect(find.text('Maintenance Record'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    expect(find.text('Choose Expense Category'), findsOneWidget);
  });

  testWidgets('generic shared PDF suggests regular receipt review', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IncomingReceiptDestinationScreen(
          attachments: [_pdfAttachment('generic')],
          importedText: '',
        ),
      ),
    );

    expect(find.text('Suggested: Receipt / Expense'), findsOneWidget);
    expect(find.textContaining('%'), findsOneWidget);
  });

  testWidgets('auto parts text suggests repair record', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IncomingReceiptDestinationScreen(
          attachments: [_pdfAttachment('advance')],
          importedText:
              'ADVANCE AUTO PARTS brake caliper oil change subtotal tax total',
        ),
      ),
    );

    expect(find.text('Suggested: Repair Receipt'), findsOneWidget);
    expect(find.textContaining('High'), findsOneWidget);
  });

  testWidgets('wireless bill suggests cell phone receipt', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IncomingReceiptDestinationScreen(
          attachments: [_pdfAttachment('verizon')],
          importedText:
              'Verizon Wireless monthly phone service data plan total 86.42',
        ),
      ),
    );

    expect(find.text('Suggested: Cell Phone Receipt'), findsOneWidget);
    expect(find.textContaining('%'), findsOneWidget);
  });

  testWidgets('other document is enabled and opens document proof flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IncomingReceiptDestinationScreen(
          attachments: [_pdfAttachment('manual')],
          importedText: 'warranty policy manual terms and certificate',
        ),
      ),
    );

    expect(find.text('Suggested: Other Document'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -550));
    await tester.pumpAndSettle();
    expect(find.text('Other Document'), findsOneWidget);
    await tester.tap(find.text('Other Document').last);
    await tester.pumpAndSettle();

    expect(find.text('Other document'), findsOneWidget);
    expect(
      find.textContaining('does not look like a normal receipt'),
      findsOneWidget,
    );
    expect(find.text('Save As Document Proof'), findsOneWidget);
    expect(find.text('Choose Expense Category'), findsWidgets);

    await tester.tap(find.text('Save As Document Proof'));
    await tester.pumpAndSettle();

    expect(find.text('Other Document'), findsWidgets);
    expect(find.textContaining('will not edit or alter'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Save Read-Only Document'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Save Read-Only Document'), findsOneWidget);
  });

  testWidgets('job document suggestion opens document proof flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IncomingReceiptDestinationScreen(
          attachments: [_pdfAttachment('work-order')],
          importedText: 'customer work order invoice proposal job estimate',
        ),
      ),
    );

    await tester.tap(find.text('Suggested: Job / Contractor Document'));
    await tester.pumpAndSettle();

    expect(find.text('Job / contractor document'), findsOneWidget);
    expect(find.textContaining('job, invoice, estimate'), findsOneWidget);
    expect(find.text('Save As Document Proof'), findsOneWidget);
    expect(find.text('Choose Expense Category'), findsWidgets);

    await tester.tap(find.text('Save As Document Proof'));
    await tester.pumpAndSettle();

    expect(find.text('Job / Contractor Document'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Save Read-Only Document'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Save Read-Only Document'), findsOneWidget);
  });

  testWidgets('incoming invoice PDF routes to job document proof', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IncomingReceiptDestinationScreen(
          attachments: [
            _pdfAttachment(
              'invoice-shared',
              originalFileName: 'invoice_INV-2026-0042.pdf',
            ),
          ],
          importedText:
              'Invoice # INV-2026-0042 Bill To Alex Customer Payment Terms Net 30 Balance Due 937.74',
        ),
      ),
    );

    expect(find.text('Suggested: Job / Contractor Document'), findsOneWidget);
    expect(find.textContaining('invoice, estimate, job'), findsOneWidget);

    await tester.tap(find.text('Suggested: Job / Contractor Document'));
    await tester.pumpAndSettle();

    expect(find.text('Job / contractor document'), findsOneWidget);
    expect(find.text('Save As Document Proof'), findsOneWidget);
  });

  testWidgets('incoming estimate PDF does not get mistaken for receipt', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: IncomingReceiptDestinationScreen(
          attachments: [
            _pdfAttachment(
              'estimate-shared',
              originalFileName: 'estimate_panel_replacement.pdf',
            ),
          ],
          importedText:
              'Estimate # EST-12 Scope of Work panel replacement Amount Due 1200.00',
        ),
      ),
    );

    expect(find.text('Suggested: Job / Contractor Document'), findsOneWidget);
    expect(find.text('Suggested: Receipt / Expense'), findsNothing);
  });
}

ReceiptAttachmentRecord _pdfAttachment(
  String id, {
  String originalFileName = '',
}) {
  return ReceiptAttachmentRecord(
    id: id,
    path: '/tmp/$id.pdf',
    kind: ReceiptAttachmentKind.pdf,
    dataSaverLevel: ReceiptDataSaverLevel.original,
    createdAt: DateTime(2026, 6, 14),
    storageState: ReceiptAttachmentStorageState.staged,
    sourceLabel: 'Shared',
    originalFileName: originalFileName,
  );
}
