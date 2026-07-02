import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/incoming_receipt_share.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shared invalid PDF is rejected before app proof storage', () async {
    final documentsDirectory = await _mockDocumentsDirectory(
      'incoming_share_storage_',
    );
    final invalidPdf = File('${Directory.systemTemp.path}/bad_shared.pdf');
    await invalidPdf.writeAsString('not a real pdf', flush: true);
    addTearDown(() async {
      _clearDocumentsDirectoryMock();
      if (invalidPdf.existsSync()) invalidPdf.deleteSync();
      await _deleteIfPresent(documentsDirectory);
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
    final documentsDirectory = await _mockDocumentsDirectory(
      'incoming_share_staging_',
    );
    final source = await _writeSourcePdf('shared_valid.pdf');
    addTearDown(() async {
      _clearDocumentsDirectoryMock();
      if (source.existsSync()) source.deleteSync();
      await _deleteIfPresent(documentsDirectory);
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
    final documentsDirectory = await _mockDocumentsDirectory(
      'incoming_share_encrypted_',
    );
    final source = await _writeSourcePdf(
      'shared_encrypted.pdf',
      body:
          '%PDF-1.7\n'
          '1 0 obj << /Type /Page >> endobj\n'
          'trailer << /Encrypt 2 0 R >>\n'
          '%%EOF',
    );
    addTearDown(() async {
      _clearDocumentsDirectoryMock();
      if (source.existsSync()) source.deleteSync();
      await _deleteIfPresent(documentsDirectory);
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
    final documentsDirectory = await _mockDocumentsDirectory(
      'incoming_share_duplicate_',
    );
    final source = await _writeSourcePdf('shared_duplicate.pdf');
    addTearDown(() async {
      _clearDocumentsDirectoryMock();
      if (source.existsSync()) source.deleteSync();
      await _deleteIfPresent(documentsDirectory);
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
    final documentsDirectory = await _mockDocumentsDirectory(
      'incoming_share_discard_',
    );
    final source = await _writeSourcePdf('shared_discard.pdf');
    addTearDown(() async {
      _clearDocumentsDirectoryMock();
      if (source.existsSync()) source.deleteSync();
      await _deleteIfPresent(documentsDirectory);
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

Future<Directory> _mockDocumentsDirectory(String prefix) async {
  final documentsDirectory = await Directory.systemTemp.createTemp(prefix);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => switch (call.method) {
          'getApplicationDocumentsDirectory' => documentsDirectory.path,
          _ => null,
        },
      );
  return documentsDirectory;
}

void _clearDocumentsDirectoryMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
}

Future<File> _writeSourcePdf(
  String name, {
  String body = '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
}) async {
  final source = File('${Directory.systemTemp.path}/$name');
  await source.writeAsString(body, flush: true);
  return source;
}

Future<void> _deleteIfPresent(Directory directory) async {
  if (await directory.exists()) {
    await directory.delete(recursive: true);
  }
}
