import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_proof_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'receipt_proof_storage_hardening_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
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
    if (await documentsDirectory.exists()) {
      await documentsDirectory.delete(recursive: true);
    }
  });

  test('staged PDF proof uses safe app-owned pdf file name', () async {
    final source = File('${Directory.systemTemp.path}/receipt_download.tmp');
    await source.writeAsString(
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final staged = await ReceiptProofStorage.instance.stageAttachment(
      ReceiptAttachmentRecord(
        id: 'receipt id with spaces',
        path: source.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 13),
        originalFileName:
            '../Very Long Store Receipt Name With Spaces & Unsafe Characters.tmp',
      ),
    );

    final savedName = Uri.file(staged.path).pathSegments.last;
    expect(staged.path, contains('receipt_proofs_staging'));
    expect(savedName, endsWith('.pdf'));
    expect(savedName, isNot(contains(' ')));
    expect(savedName, isNot(contains('&')));
    expect(savedName, contains('receipt_id_with_spaces'));
    expect(await File(staged.path).exists(), isTrue);
    expect(await source.exists(), isTrue);
    expect(staged.byteSize, await source.length());
    expect(staged.fileHash, isNotEmpty);
  });

  test('promoted PDF proof keeps hash and immutable proof metadata', () async {
    final source = File('${Directory.systemTemp.path}/immutable_proof.pdf');
    await source.writeAsString(
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final staged = await ReceiptProofStorage.instance.stageAttachment(
      ReceiptAttachmentRecord(
        id: 'pdf-proof',
        path: source.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 13),
      ),
    );
    final promoted = await ReceiptProofStorage.instance.persistAttachment(
      staged.copyWith(linkedModule: 'expenses', linkedRecordId: 'EXP-200'),
    );

    expect(promoted.path, contains('receipt_proofs/pdfs'));
    expect(promoted.path, endsWith('.pdf'));
    expect(promoted.fileHash, isNotEmpty);
    expect(promoted.isOriginalImmutable, isTrue);
    expect(promoted.canEditProofFileInApp, isFalse);
    expect(promoted.storageState, ReceiptAttachmentStorageState.permanent);
    expect(promoted.linkedModule, 'expenses');
    expect(promoted.linkedRecordId, 'EXP-200');
  });

  test(
    'discarding staged proof attachments deletes only staged files',
    () async {
      final stagedSource = File(
        '${Directory.systemTemp.path}/discard_staged.pdf',
      );
      final permanentSource = File(
        '${Directory.systemTemp.path}/keep_permanent.pdf',
      );
      await stagedSource.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      await permanentSource.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      addTearDown(() {
        if (stagedSource.existsSync()) stagedSource.deleteSync();
        if (permanentSource.existsSync()) permanentSource.deleteSync();
      });

      final staged = await ReceiptProofStorage.instance.stageAttachment(
        ReceiptAttachmentRecord(
          id: 'discard-staged',
          path: stagedSource.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 13),
        ),
      );
      final permanent = await ReceiptProofStorage.instance.persistAttachment(
        ReceiptAttachmentRecord(
          id: 'keep-permanent',
          path: permanentSource.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 13),
        ),
      );

      await ReceiptProofStorage.instance.deleteStagedAttachments([
        staged,
        permanent,
      ]);

      expect(await File(staged.path).exists(), isFalse);
      expect(await File(permanent.path).exists(), isTrue);
    },
  );

  test('staged-looking external files are never deleted', () async {
    final external = File('${Directory.systemTemp.path}/external_staged.pdf');
    await external.writeAsString(
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (external.existsSync()) external.deleteSync();
    });

    await ReceiptProofStorage.instance.deleteStagedAttachment(
      ReceiptAttachmentRecord(
        id: 'external-staged',
        path: external.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 14),
        storageState: ReceiptAttachmentStorageState.staged,
      ),
    );

    expect(await external.exists(), isTrue);
  });

  test('only a completed managed proof can be removed', () async {
    final external = File('${Directory.systemTemp.path}/external_receipt.jpg');
    await external.writeAsBytes(const [1, 2, 3], flush: true);
    addTearDown(() {
      if (external.existsSync()) external.deleteSync();
    });
    final managed = await ReceiptProofStorage.instance.persistAttachment(
      ReceiptAttachmentRecord(
        id: 'managed-remove',
        path: external.path,
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 6, 14),
      ),
    );
    expect(
      await ReceiptProofStorage.instance.removeManagedPermanentProof(
        external.path,
      ),
      isFalse,
    );
    expect(await external.exists(), isTrue);
    expect(
      await ReceiptProofStorage.instance.removeManagedPermanentProof(
        managed.path,
      ),
      isTrue,
    );
    expect(await File(managed.path).exists(), isFalse);
  });

  test('storage refuses renamed non-PDF proof files', () async {
    final source = File('${Directory.systemTemp.path}/fake_receipt.pdf');
    await source.writeAsString('not actually a pdf', flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    await expectLater(
      ReceiptProofStorage.instance.stageAttachment(
        ReceiptAttachmentRecord(
          id: 'fake-pdf',
          path: source.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 13),
        ),
      ),
      throwsA(isA<ReceiptProofStorageException>()),
    );

    final stagingRoot = Directory(
      '${documentsDirectory.path}/receipt_proofs_staging',
    );
    if (await stagingRoot.exists()) {
      expect(await stagingRoot.list().isEmpty, isTrue);
    }
  });

  test('storage refuses zero-byte PDF proof files', () async {
    final source = File('${Directory.systemTemp.path}/empty_storage.pdf');
    await source.writeAsBytes(const [], flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    await expectLater(
      ReceiptProofStorage.instance.persistAttachment(
        ReceiptAttachmentRecord(
          id: 'empty-pdf',
          path: source.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 13),
        ),
      ),
      throwsA(isA<ReceiptProofStorageException>()),
    );
  });
}
