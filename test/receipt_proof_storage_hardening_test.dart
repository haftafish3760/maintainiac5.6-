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
    'rollback restore refuses saved proof symlink sources',
    () async {
      final stagingRoot = Directory(
        '${documentsDirectory.path}/receipt_proofs_staging',
      );
      final proofRoot = Directory('${documentsDirectory.path}/receipt_proofs');
      final proofPdfRoot = Directory('${proofRoot.path}/pdfs');
      await stagingRoot.create(recursive: true);
      await proofPdfRoot.create(recursive: true);

      final outsideTarget = File('${Directory.systemTemp.path}/private.pdf');
      await outsideTarget.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      final savedLink = Link('${proofPdfRoot.path}/saved-link.pdf');
      await savedLink.create(outsideTarget.path);
      final stagedPath = '${stagingRoot.path}/missing-staged.pdf';
      addTearDown(() async {
        if (await savedLink.exists()) await savedLink.delete();
        if (outsideTarget.existsSync()) outsideTarget.deleteSync();
        final staged = File(stagedPath);
        if (staged.existsSync()) staged.deleteSync();
      });

      await ReceiptProofStorage.instance.rollbackPersistedAttachments(
        [
          ReceiptAttachmentRecord(
            id: 'rollback-link',
            path: savedLink.path,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 7, 5),
            storageState: ReceiptAttachmentStorageState.permanent,
          ),
        ],
        [
          ReceiptAttachmentRecord(
            id: 'rollback-link',
            path: stagedPath,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 7, 5),
            storageState: ReceiptAttachmentStorageState.staged,
          ),
        ],
      );

      expect(await File(stagedPath).exists(), isFalse);
      expect(await savedLink.exists(), isFalse);
      expect(await outsideTarget.exists(), isTrue);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test(
    'rollback restore rechecks saved proof before replacing staged copy',
    () {
      final source = File(
        'lib/shared/widgets/receipt_capture/receipt_proof_storage.dart',
      ).readAsStringSync();

      expect(
        source,
        contains('final expectedSavedBytes = await _safeLength(savedFile);'),
      );
      expect(
        source,
        contains('final expectedSavedHash = await _safeHash(savedFile);'),
      );
      expect(source, contains('await _rejectSymlinkedStoragePath'));
      expect(
        source,
        contains(r"final temp = File('${staged.path}.restore_partial');"),
      );
      expect(source, contains('await savedFile.copy(temp.path);'));
      expect(source, contains('currentSavedBytes != expectedSavedBytes'));
      expect(source, contains('currentSavedHash != expectedSavedHash'));
      expect(source, contains('await temp.rename(staged.path);'));
    },
  );

  test(
    'rollback restore refuses symlinked staged parent directory',
    () async {
      final outsideStaging = await Directory.systemTemp.createTemp(
        'outside_rollback_staging_',
      );
      final stagingLink = Link(
        '${documentsDirectory.path}/receipt_proofs_staging',
      );
      await stagingLink.create(outsideStaging.path);

      final proofRoot = Directory('${documentsDirectory.path}/receipt_proofs');
      final proofPdfRoot = Directory('${proofRoot.path}/pdfs');
      await proofPdfRoot.create(recursive: true);
      final saved = File('${proofPdfRoot.path}/saved-proof.pdf');
      await saved.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      final stagedPath = '${stagingLink.path}/restore-target.pdf';
      addTearDown(() async {
        if (saved.existsSync()) saved.deleteSync();
        if (await stagingLink.exists()) await stagingLink.delete();
        if (await outsideStaging.exists()) {
          await outsideStaging.delete(recursive: true);
        }
      });

      await ReceiptProofStorage.instance.rollbackPersistedAttachments(
        [
          ReceiptAttachmentRecord(
            id: 'rollback-symlink-parent',
            path: saved.path,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 7, 5),
            storageState: ReceiptAttachmentStorageState.permanent,
          ),
        ],
        [
          ReceiptAttachmentRecord(
            id: 'rollback-symlink-parent',
            path: stagedPath,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 7, 5),
            storageState: ReceiptAttachmentStorageState.staged,
          ),
        ],
      );

      expect(await File(stagedPath).exists(), isFalse);
      expect(await outsideStaging.list().isEmpty, isTrue);
      expect(await saved.exists(), isFalse);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test(
    'rollback restore replaces stale partial link without touching target',
    () async {
      final stagingRoot = Directory(
        '${documentsDirectory.path}/receipt_proofs_staging',
      );
      final proofRoot = Directory('${documentsDirectory.path}/receipt_proofs');
      final proofPdfRoot = Directory('${proofRoot.path}/pdfs');
      await stagingRoot.create(recursive: true);
      await proofPdfRoot.create(recursive: true);

      final saved = File('${proofPdfRoot.path}/saved-proof.pdf');
      await saved.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      final outsideTarget = File('${Directory.systemTemp.path}/outside.pdf');
      await outsideTarget.writeAsString('do not delete', flush: true);
      final stagedPath = '${stagingRoot.path}/restore-target.pdf';
      final partialLink = Link('$stagedPath.restore_partial');
      await partialLink.create(outsideTarget.path);
      addTearDown(() async {
        if (saved.existsSync()) saved.deleteSync();
        final staged = File(stagedPath);
        if (staged.existsSync()) staged.deleteSync();
        if (await partialLink.exists()) await partialLink.delete();
        if (outsideTarget.existsSync()) outsideTarget.deleteSync();
      });

      await ReceiptProofStorage.instance.rollbackPersistedAttachments(
        [
          ReceiptAttachmentRecord(
            id: 'rollback-partial-link',
            path: saved.path,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 7, 5),
            storageState: ReceiptAttachmentStorageState.permanent,
          ),
        ],
        [
          ReceiptAttachmentRecord(
            id: 'rollback-partial-link',
            path: stagedPath,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 7, 5),
            storageState: ReceiptAttachmentStorageState.staged,
          ),
        ],
      );

      expect(await File(stagedPath).exists(), isTrue);
      expect(await partialLink.exists(), isFalse);
      expect(await outsideTarget.exists(), isTrue);
      expect(await saved.exists(), isFalse);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test(
    'rollback restore refuses staged destinations outside app storage',
    () async {
      final proofRoot = Directory('${documentsDirectory.path}/receipt_proofs');
      final proofPdfRoot = Directory('${proofRoot.path}/pdfs');
      await proofPdfRoot.create(recursive: true);
      final saved = File('${proofPdfRoot.path}/saved-proof.pdf');
      await saved.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      final outsideDir = await Directory.systemTemp.createTemp(
        'outside_restore_destination_',
      );
      final outsideStagedPath = '${outsideDir.path}/restore-target.pdf';
      addTearDown(() async {
        if (saved.existsSync()) saved.deleteSync();
        final outsideStaged = File(outsideStagedPath);
        if (outsideStaged.existsSync()) outsideStaged.deleteSync();
        if (await outsideDir.exists()) await outsideDir.delete(recursive: true);
      });

      await ReceiptProofStorage.instance.rollbackPersistedAttachments(
        [
          ReceiptAttachmentRecord(
            id: 'rollback-outside-destination',
            path: saved.path,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 7, 5),
            storageState: ReceiptAttachmentStorageState.permanent,
          ),
        ],
        [
          ReceiptAttachmentRecord(
            id: 'rollback-outside-destination',
            path: outsideStagedPath,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 7, 5),
            storageState: ReceiptAttachmentStorageState.staged,
          ),
        ],
      );

      expect(await File(outsideStagedPath).exists(), isFalse);
      expect(await saved.exists(), isFalse);
    },
  );

  test(
    'rollback restore leaves existing staged symlink target untouched',
    () async {
      final stagingRoot = Directory(
        '${documentsDirectory.path}/receipt_proofs_staging',
      );
      final proofRoot = Directory('${documentsDirectory.path}/receipt_proofs');
      final proofPdfRoot = Directory('${proofRoot.path}/pdfs');
      await stagingRoot.create(recursive: true);
      await proofPdfRoot.create(recursive: true);

      final saved = File('${proofPdfRoot.path}/saved-proof.pdf');
      await saved.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      final outsideTarget = File('${Directory.systemTemp.path}/existing.pdf');
      await outsideTarget.writeAsString('do not modify', flush: true);
      final stagedLink = Link('${stagingRoot.path}/existing-link.pdf');
      await stagedLink.create(outsideTarget.path);
      addTearDown(() async {
        if (saved.existsSync()) saved.deleteSync();
        if (await stagedLink.exists()) await stagedLink.delete();
        if (outsideTarget.existsSync()) outsideTarget.deleteSync();
      });

      await ReceiptProofStorage.instance.rollbackPersistedAttachments(
        [
          ReceiptAttachmentRecord(
            id: 'rollback-existing-link',
            path: saved.path,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 7, 5),
            storageState: ReceiptAttachmentStorageState.permanent,
          ),
        ],
        [
          ReceiptAttachmentRecord(
            id: 'rollback-existing-link',
            path: stagedLink.path,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 7, 5),
            storageState: ReceiptAttachmentStorageState.staged,
          ),
        ],
      );

      expect(await stagedLink.exists(), isTrue);
      expect(await outsideTarget.exists(), isTrue);
      expect(await outsideTarget.readAsString(), 'do not modify');
      expect(await saved.exists(), isFalse);
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
