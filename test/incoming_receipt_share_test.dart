import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/incoming_receipt_share.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps shared PDFs, images, and text into receipt attachments', () {
    final receivedAt = DateTime(2026, 6, 12, 9, 30);

    final attachments = receiptAttachmentsFromSharedMedia([
      SharedMediaFile(
        path: '/tmp/lowes.pdf',
        type: SharedMediaType.file,
        mimeType: 'application/pdf',
      ),
      SharedMediaFile(
        path: '/tmp/receipt.jpg',
        type: SharedMediaType.image,
        mimeType: 'image/jpeg',
      ),
      SharedMediaFile(
        path: 'ADVANCE AUTO PARTS\nTOTAL 42.18',
        type: SharedMediaType.text,
        mimeType: 'text/plain',
      ),
    ], receivedAt: receivedAt);

    expect(attachments, hasLength(3));
    expect(attachments[0].kind, ReceiptAttachmentKind.pdf);
    expect(attachments[0].displayName, 'lowes.pdf');
    expect(attachments[0].sourceLabel, 'Shared');
    expect(attachments[1].kind, ReceiptAttachmentKind.photo);
    expect(attachments[1].displayName, 'receipt.jpg');
    expect(attachments[1].sourceLabel, 'Shared');
    expect(attachments[2].kind, ReceiptAttachmentKind.emailText);
    expect(attachments[2].importedText, contains('ADVANCE AUTO PARTS'));
  });

  test('maps multiple shared text items into readable text attachments', () {
    final attachments = receiptAttachmentsFromSharedMedia([
      SharedMediaFile(
        path: 'SIGNED INVOICE\nTOTAL 250.00',
        type: SharedMediaType.text,
        mimeType: 'text/plain',
      ),
      SharedMediaFile(
        path: 'MAINTENANCE REPORT\nOIL CHANGE COMPLETE',
        type: SharedMediaType.text,
        mimeType: 'text/plain',
      ),
    ]);

    expect(attachments, hasLength(2));
    expect(attachments.every((item) => item.isImportedText), isTrue);
    expect(attachments.first.importedText, contains('SIGNED INVOICE'));
    expect(attachments.last.importedText, contains('MAINTENANCE REPORT'));
    expect(attachments.every((item) => item.sourceLabel == 'Shared'), isTrue);
  });

  test('ignores unsupported shared files instead of creating bad receipts', () {
    final attachments = receiptAttachmentsFromSharedMedia([
      SharedMediaFile(
        path: '/tmp/archive.zip',
        type: SharedMediaType.file,
        mimeType: 'application/zip',
      ),
    ]);

    expect(attachments, isEmpty);
  });

  test('incoming share reports unsupported shared files to the user', () {
    final incoming = IncomingReceiptShare.fromMedia([
      SharedMediaFile(
        path: '/tmp/archive.zip',
        type: SharedMediaType.file,
        mimeType: 'application/zip',
      ),
    ]);

    expect(incoming.hasContent, isTrue);
    expect(incoming.attachments, isEmpty);
    expect(incoming.messages.single, contains('archive.zip'));
    expect(incoming.messages.single, contains('PDF'));
  });

  test(
    'incoming share reports links instead of importing them as receipt text',
    () {
      final incoming = IncomingReceiptShare.fromMedia([
        SharedMediaFile(
          path: 'https://drive.example.com/receipt',
          type: SharedMediaType.url,
          mimeType: 'text/uri-list',
        ),
      ]);

      expect(incoming.hasContent, isTrue);
      expect(incoming.attachments, isEmpty);
      expect(incoming.importedText, isEmpty);
      expect(incoming.messages.single, contains('link'));
      expect(incoming.messages.single, contains('actual PDF'));
    },
  );

  test('normalizes iOS file URLs and generic PDF mime types', () {
    final receivedAt = DateTime(2026, 6, 13, 8, 15);

    final attachments = receiptAttachmentsFromSharedMedia([
      SharedMediaFile(
        path: 'file:///tmp/advance-auto.pdf',
        type: SharedMediaType.file,
        mimeType: 'application/octet-stream',
      ),
    ], receivedAt: receivedAt);

    expect(attachments, hasLength(1));
    expect(attachments.single.kind, ReceiptAttachmentKind.pdf);
    expect(attachments.single.path, '/tmp/advance-auto.pdf');
    expect(attachments.single.displayName, 'advance-auto.pdf');
  });

  test('decodes percent-encoded shared PDF file names', () {
    final attachments = receiptAttachmentsFromSharedMedia([
      SharedMediaFile(
        path: 'file:///tmp/Advance%20Auto%20Receipt.pdf',
        type: SharedMediaType.file,
        mimeType: 'application/pdf',
      ),
    ]);

    expect(attachments.single.displayName, 'Advance Auto Receipt.pdf');
    expect(attachments.single.originalFileName, 'Advance Auto Receipt.pdf');
  });

  test('keeps malformed percent file names readable', () {
    final attachments = receiptAttachmentsFromSharedMedia([
      SharedMediaFile(
        path: 'file:///tmp/Advance%Receipt.pdf',
        type: SharedMediaType.file,
        mimeType: 'application/pdf',
      ),
    ]);

    expect(attachments.single.displayName, 'Advance%Receipt.pdf');
    expect(attachments.single.originalFileName, 'Advance%Receipt.pdf');
  });

  test('caps oversized incoming share batches with a user message', () {
    final media = List.generate(
      kMaxIncomingReceiptShareItems + 3,
      (index) => SharedMediaFile(
        path: '/tmp/receipt_$index.pdf',
        type: SharedMediaType.file,
        mimeType: 'application/pdf',
      ),
    );

    final incoming = IncomingReceiptShare.fromMedia(media);

    expect(incoming.attachments, hasLength(kMaxIncomingReceiptShareItems));
    expect(incoming.messages.single, contains('extra item'));
  });

  test('keeps generic shared file as PDF candidate even without extension', () {
    final attachments = receiptAttachmentsFromSharedMedia([
      SharedMediaFile(
        path: '/tmp/shared-receipt-document',
        type: SharedMediaType.file,
        mimeType: 'application/octet-stream',
      ),
    ]);

    expect(attachments, hasLength(1));
    expect(attachments.single.kind, ReceiptAttachmentKind.pdf);
    expect(attachments.single.mimeType, 'application/octet-stream');
    expect(attachments.single.displayName, 'shared-receipt-document');
  });

  test('maps alternate PDF mime types into PDF candidates', () {
    final attachments = receiptAttachmentsFromSharedMedia([
      SharedMediaFile(
        path: '/tmp/receipt-one',
        type: SharedMediaType.file,
        mimeType: 'application/x-pdf',
      ),
      SharedMediaFile(
        path: '/tmp/receipt-two',
        type: SharedMediaType.file,
        mimeType: 'application/vnd.pdf',
      ),
    ]);

    expect(attachments, hasLength(2));
    expect(
      attachments.every((item) => item.kind == ReceiptAttachmentKind.pdf),
      isTrue,
    );
  });

  test('shared invalid PDF is rejected before app proof storage', () async {
    final documentsDirectory = await Directory.systemTemp.createTemp(
      'incoming_share_storage_',
    );
    final invalidPdf = File('${Directory.systemTemp.path}/bad_shared.pdf');
    await invalidPdf.writeAsString('not a real pdf', flush: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      if (invalidPdf.existsSync()) invalidPdf.deleteSync();
      if (await documentsDirectory.exists()) {
        await documentsDirectory.delete(recursive: true);
      }
    });

    final incoming = IncomingReceiptShare(
      attachments: receiptAttachmentsFromSharedMedia([
        SharedMediaFile(
          path: invalidPdf.path,
          type: SharedMediaType.file,
          mimeType: 'application/pdf',
        ),
      ]),
      receivedAt: DateTime(2026, 6, 13),
    );

    final prepared = await prepareIncomingReceiptShareForStorage(incoming);

    expect(prepared.hasContent, isTrue);
    expect(prepared.attachments, isEmpty);
    expect(prepared.messages.single, contains('valid PDF'));
  });

  test('shared valid PDF is staged until the receipt is saved', () async {
    final documentsDirectory = await Directory.systemTemp.createTemp(
      'incoming_share_staging_',
    );
    final source = File('${Directory.systemTemp.path}/shared_valid.pdf');
    await source.writeAsString(
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
      flush: true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      if (source.existsSync()) source.deleteSync();
      if (await documentsDirectory.exists()) {
        await documentsDirectory.delete(recursive: true);
      }
    });

    final incoming = IncomingReceiptShare(
      attachments: receiptAttachmentsFromSharedMedia([
        SharedMediaFile(
          path: source.path,
          type: SharedMediaType.file,
          mimeType: 'application/pdf',
        ),
      ]),
      receivedAt: DateTime(2026, 6, 13),
    );

    final prepared = await prepareIncomingReceiptShareForStorage(incoming);
    final attachment = prepared.attachments.single;

    expect(prepared.messages, isNotEmpty);
    expect(attachment.kind, ReceiptAttachmentKind.pdf);
    expect(attachment.storageState, ReceiptAttachmentStorageState.staged);
    expect(attachment.path, contains('receipt_proofs_staging'));
    expect(attachment.path, isNot(contains('receipt_proofs/pdfs')));
    expect(attachment.fileHash, isNotEmpty);
    expect(attachment.pageCount, 1);
    expect(await File(attachment.path).exists(), isTrue);
    expect(await source.exists(), isTrue);
  });

  test('shared encrypted PDF is saved as unreadable proof only', () async {
    final documentsDirectory = await Directory.systemTemp.createTemp(
      'incoming_share_encrypted_',
    );
    final source = File('${Directory.systemTemp.path}/shared_encrypted.pdf');
    await source.writeAsString(
      '%PDF-1.7\n'
      '1 0 obj << /Type /Page >> endobj\n'
      'trailer << /Encrypt 2 0 R >>\n'
      '%%EOF',
      flush: true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      if (source.existsSync()) source.deleteSync();
      if (await documentsDirectory.exists()) {
        await documentsDirectory.delete(recursive: true);
      }
    });

    final prepared = await prepareIncomingReceiptShareForStorage(
      IncomingReceiptShare(
        attachments: receiptAttachmentsFromSharedMedia([
          SharedMediaFile(
            path: source.path,
            type: SharedMediaType.file,
            mimeType: 'application/pdf',
          ),
        ]),
        receivedAt: DateTime(2026, 6, 13),
      ),
    );

    final attachment = prepared.attachments.single;
    expect(attachment.storageState, ReceiptAttachmentStorageState.staged);
    expect(attachment.readState, ReceiptAttachmentReadState.unreadable);
    expect(attachment.riskFlags, contains('encryption or password security'));
    expect(prepared.messages.join('\n'), contains('encryption'));
  });

  test('shared duplicate PDFs are staged once and reported', () async {
    final documentsDirectory = await Directory.systemTemp.createTemp(
      'incoming_share_duplicate_',
    );
    final source = File('${Directory.systemTemp.path}/shared_duplicate.pdf');
    await source.writeAsString(
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
      flush: true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      if (source.existsSync()) source.deleteSync();
      if (await documentsDirectory.exists()) {
        await documentsDirectory.delete(recursive: true);
      }
    });

    final prepared = await prepareIncomingReceiptShareForStorage(
      IncomingReceiptShare(
        attachments: receiptAttachmentsFromSharedMedia([
          SharedMediaFile(
            path: source.path,
            type: SharedMediaType.file,
            mimeType: 'application/pdf',
          ),
          SharedMediaFile(
            path: source.path,
            type: SharedMediaType.file,
            mimeType: 'application/pdf',
          ),
        ]),
        receivedAt: DateTime(2026, 6, 13),
      ),
    );

    expect(prepared.attachments, hasLength(1));
    expect(prepared.messages.join('\n'), contains('already included'));
  });

  test('discarding an incoming share deletes staged receipt proofs', () async {
    final documentsDirectory = await Directory.systemTemp.createTemp(
      'incoming_share_discard_',
    );
    final source = File('${Directory.systemTemp.path}/shared_discard.pdf');
    await source.writeAsString(
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
      flush: true,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
    addTearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      if (source.existsSync()) source.deleteSync();
      if (await documentsDirectory.exists()) {
        await documentsDirectory.delete(recursive: true);
      }
    });

    final prepared = await prepareIncomingReceiptShareForStorage(
      IncomingReceiptShare(
        attachments: receiptAttachmentsFromSharedMedia([
          SharedMediaFile(
            path: source.path,
            type: SharedMediaType.file,
            mimeType: 'application/pdf',
          ),
        ]),
        receivedAt: DateTime(2026, 6, 13),
      ),
    );
    final stagedPath = prepared.attachments.single.path;

    expect(await File(stagedPath).exists(), isTrue);

    await discardIncomingReceiptShare(prepared);

    expect(await File(stagedPath).exists(), isFalse);
    expect(await source.exists(), isTrue);
  });
}
