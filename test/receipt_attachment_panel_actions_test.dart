import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_attachment_panel.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_pdf_inspector.dart';

void main() {
  testWidgets('empty receipt panel stays focused on Add Receipt before capture', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SharedReceiptAttachmentPanel(
              hasReceipt: false,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Add Receipt'), findsOneWidget);
    expect(find.text('Long receipt? Scan top to bottom.'), findsNothing);
    expect(find.text('Need another receipt section?'), findsNothing);
    expect(find.byTooltip('Receipt photo settings'), findsNothing);
  });

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
    expect(find.text('Add Receipt Photo'), findsOneWidget);
  });

  testWidgets('multiple receipt photos are shown in receipt order', (
    tester,
  ) async {
    var hasAttachment = true;
    List<ReceiptAttachmentRecord> published = const [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SharedReceiptAttachmentPanel(
              hasReceipt: true,
              initialAttachments: [
                _photoAttachment(
                  id: 'photo-top',
                  path: '/tmp/top.jpg',
                  quality: const ReceiptPhotoQualityCheck(
                    width: 1800,
                    height: 2400,
                    focusScore: 15,
                    brightness: 148,
                    contrast: 40,
                    cropScore: .78,
                    textBandScore: 14,
                    isLikelyReadable: true,
                  ),
                ),
                _photoAttachment(id: 'photo-middle', path: '/tmp/middle.jpg'),
                _photoAttachment(id: 'photo-bottom', path: '/tmp/bottom.jpg'),
              ],
              onChanged: (value) => hasAttachment = value,
              onAttachmentsChanged: (attachments) => published = attachments,
            ),
          ),
        ),
      ),
    );

    expect(find.text('3 receipt photos attached'), findsOneWidget);
    expect(find.textContaining('Photos kept in receipt order'), findsOneWidget);
    expect(
      find.textContaining('Next checks the clear photo first'),
      findsWidgets,
    );
    expect(find.textContaining('saved proof'), findsWidgets);
    expect(find.text('Receipt photo 1'), findsOneWidget);
    expect(find.text('Receipt photo 2'), findsOneWidget);
    expect(find.text('Receipt photo 3'), findsOneWidget);
    expect(find.textContaining('Photo looks readable'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('Remove receipt photo?'), findsOneWidget);
    expect(
      find.textContaining('make sure the remaining photos still cover'),
      findsOneWidget,
    );
    expect(find.text('Remove Photo'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('3 receipt photos attached'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove Photo'));
    await tester.pumpAndSettle();

    expect(find.text('2 receipt photos attached'), findsOneWidget);
    expect(find.text('Receipt photo 1'), findsOneWidget);
    expect(find.text('Receipt photo 2'), findsOneWidget);
    expect(hasAttachment, isTrue);
    final publishedPhotos = published
        .where((attachment) => attachment.isPhoto)
        .toList();
    expect(publishedPhotos, hasLength(2));
    expect(publishedPhotos.map((attachment) => attachment.id), [
      'photo-middle',
      'photo-bottom',
    ]);
    expect(publishedPhotos.map((attachment) => attachment.path), [
      '/tmp/middle.jpg',
      '/tmp/bottom.jpg',
    ]);
    expect(
      published.any(
        (attachment) =>
            attachment.path == '/tmp/top.jpg' &&
            attachment.photoQualityScore != null,
      ),
      isFalse,
    );
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

ReceiptAttachmentRecord _photoAttachment({
  required String id,
  required String path,
  ReceiptPhotoQualityCheck? quality,
}) {
  return ReceiptAttachmentRecord(
    id: id,
    path: path,
    kind: ReceiptAttachmentKind.photo,
    dataSaverLevel: ReceiptDataSaverLevel.balanced,
    createdAt: DateTime(2026, 6, 14),
    storageState: ReceiptAttachmentStorageState.permanent,
  ).withPhotoQuality(quality);
}
