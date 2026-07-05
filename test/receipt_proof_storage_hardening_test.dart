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

  test(
    'storage refuses symlinked receipt proof staging directory',
    () async {
      final source = File('${Directory.systemTemp.path}/symlink_dir.pdf');
      await source.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      final outside = await Directory.systemTemp.createTemp(
        'outside_receipt_staging_',
      );
      final stagingLink = Link(
        '${documentsDirectory.path}/receipt_proofs_staging',
      );
      await stagingLink.create(outside.path);
      addTearDown(() async {
        if (source.existsSync()) source.deleteSync();
        if (await stagingLink.exists()) await stagingLink.delete();
        if (await outside.exists()) await outside.delete(recursive: true);
      });

      await expectLater(
        ReceiptProofStorage.instance.stageAttachment(
          ReceiptAttachmentRecord(
            id: 'symlinked-staging-dir',
            path: source.path,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 7, 5),
          ),
        ),
        throwsA(isA<ReceiptProofStorageException>()),
      );

      expect(await outside.list().isEmpty, isTrue);
      expect(await source.exists(), isTrue);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test('receipt proof copy rechecks source without following links', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_proof_storage_copy.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('await _ensureRegularFileForStorage(source, message);'),
    );
    expect(
      source,
      contains('final expectedSourceBytes = await _safeLength(source);'),
    );
    expect(
      source,
      contains('final expectedSourceHash = await _safeHash(source);'),
    );
    expect(source, contains('await source.copy(temp.path);'));
    expect(source, contains('sourceBytes != expectedSourceBytes'));
    expect(source, contains('sourceHash != expectedSourceHash'));
  });

  test(
    'discarding staged proof symlink deletes link without target',
    () async {
      final stagingRoot = Directory(
        '${documentsDirectory.path}/receipt_proofs_staging',
      );
      await stagingRoot.create(recursive: true);
      final outsideTarget = File('${Directory.systemTemp.path}/outside.pdf');
      await outsideTarget.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      final stagedLink = Link('${stagingRoot.path}/linked-proof.pdf');
      await stagedLink.create(outsideTarget.path);
      addTearDown(() async {
        if (await stagedLink.exists()) await stagedLink.delete();
        if (outsideTarget.existsSync()) outsideTarget.deleteSync();
      });

      await ReceiptProofStorage.instance.deleteStagedAttachment(
        ReceiptAttachmentRecord(
          id: 'staged-link-delete',
          path: stagedLink.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 7, 5),
          storageState: ReceiptAttachmentStorageState.staged,
        ),
      );

      expect(await stagedLink.exists(), isFalse);
      expect(await outsideTarget.exists(), isTrue);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test(
    'orphan cleanup removes proof symlink without deleting target',
    () async {
      final proofRoot = Directory(
        '${documentsDirectory.path}/receipt_proofs/pdfs',
      );
      await proofRoot.create(recursive: true);
      final outsideTarget = File('${Directory.systemTemp.path}/orphan.pdf');
      await outsideTarget.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      final proofLink = Link('${proofRoot.path}/orphan-link.pdf');
      await proofLink.create(outsideTarget.path);
      addTearDown(() async {
        if (await proofLink.exists()) await proofLink.delete();
        if (outsideTarget.existsSync()) outsideTarget.deleteSync();
      });

      await ReceiptProofStorage.instance.cleanOrphanProofFiles(
        retainedPaths: const [],
      );

      expect(await proofLink.exists(), isFalse);
      expect(await outsideTarget.exists(), isTrue);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );
}
