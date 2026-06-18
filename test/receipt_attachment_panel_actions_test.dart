import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_attachment_panel.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';

void main() {
  testWidgets('removing an imported proof asks before deleting it', (
    tester,
  ) async {
    var hasAttachment = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SharedReceiptAttachmentPanel(
              hasReceipt: true,
              initialAttachments: [_pdfAttachment()],
              onChanged: (value) => hasAttachment = value,
            ),
          ),
        ),
      ),
    );

    expect(find.text('receipt.pdf'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Remove receipt proof?'), findsOneWidget);
    expect(find.text('Remove Proof'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('receipt.pdf'), findsOneWidget);
    expect(hasAttachment, isTrue);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Proof'));
    await tester.pumpAndSettle();

    expect(find.text('receipt.pdf'), findsNothing);
    expect(hasAttachment, isFalse);
  });

  testWidgets('clearing all proofs asks before removing attachments', (
    tester,
  ) async {
    var hasAttachment = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SharedReceiptAttachmentPanel(
              hasReceipt: true,
              initialAttachments: [_pdfAttachment()],
              onChanged: (value) => hasAttachment = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('Clear receipt proof?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('receipt.pdf'), findsOneWidget);
    expect(hasAttachment, isTrue);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear Proof'));
    await tester.pumpAndSettle();

    expect(find.text('receipt.pdf'), findsNothing);
    expect(hasAttachment, isFalse);
  });

  testWidgets('PDF proof row shows read-only and review status', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SharedReceiptAttachmentPanel(
              hasReceipt: true,
              initialAttachments: [
                _pdfAttachment(
                  readState: ReceiptAttachmentReadState.unreadable,
                  riskFlags: const ['external links'],
                  documentSignals: const [
                    ReceiptPdfInspector.imageContentSignal,
                  ],
                ),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('receipt.pdf'), findsOneWidget);
    expect(find.textContaining('read-only PDF proof'), findsOneWidget);
    expect(find.textContaining('Saved, not readable'), findsOneWidget);
    expect(find.textContaining('Scanned/image PDF'), findsOneWidget);
    expect(find.textContaining('Review PDF warnings'), findsOneWidget);
  });
}

ReceiptAttachmentRecord _pdfAttachment({
  ReceiptAttachmentReadState readState = ReceiptAttachmentReadState.notRead,
  List<String> riskFlags = const [],
  List<String> documentSignals = const [],
}) {
  return ReceiptAttachmentRecord(
    id: 'pdf-proof',
    path: '/tmp/receipt.pdf',
    kind: ReceiptAttachmentKind.pdf,
    dataSaverLevel: ReceiptDataSaverLevel.original,
    createdAt: DateTime(2026, 6, 14),
    displayName: 'receipt.pdf',
    byteSize: 2048,
    pageCount: 1,
    pageCountStatus: ReceiptPdfPageCountStatus.estimated,
    validationStatus: ReceiptPdfValidationStatus.valid,
    riskFlags: riskFlags,
    documentSignals: documentSignals,
    storageState: ReceiptAttachmentStorageState.permanent,
    readState: readState,
  );
}
