import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/documents/app_document_export_manifest.dart';
import 'package:maintaniac/shared/documents/app_document_export_package_writer.dart';
import 'package:maintaniac/shared/documents/app_document_import_service.dart';
import 'package:maintaniac/shared/documents/app_document_models.dart';
import 'package:maintaniac/shared/documents/app_document_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_proof_storage.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documentsDirectory;
  late File sourcePdf;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'app_document_store_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
    sourcePdf = File('${Directory.systemTemp.path}/job_packet.pdf');
    final pdf = pw.Document()
      ..addPage(pw.Page(build: (_) => pw.Text('Job packet')));
    await sourcePdf.writeAsBytes(await pdf.save(), flush: true);
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
    if (await sourcePdf.exists()) await sourcePdf.delete();
  });

  test(
    'saves app-wide document proof separate from expense receipts',
    () async {
      final store = AppDocumentStore.memory();
      final staged = await ReceiptProofStorage.instance.stageAttachment(
        ReceiptAttachmentRecord(
          id: 'job-pdf',
          path: sourcePdf.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 15),
        ),
      );
      final promoted = await ReceiptProofStorage.instance.persistAttachment(
        staged.copyWith(
          linkedModule: AppDocumentKind.jobContractorDocument.storageModule,
          linkedRecordId: 'DOC-job',
        ),
      );
      final saved = await store.saveRecord(
        AppDocumentRecord(
          id: 'DOC-job',
          kind: AppDocumentKind.jobContractorDocument,
          title: 'Signed estimate',
          sourceLabel: 'Shared import',
          createdAt: DateTime(2026, 6, 15),
          updatedAt: DateTime(2026, 6, 15),
          attachments: [promoted],
        ),
      );

      expect(saved.kind, AppDocumentKind.jobContractorDocument);
      expect(saved.displayTitle, 'Signed estimate');
      expect(saved.attachments.single.linkedModule, 'jobs');
      expect(saved.attachments.single.linkedRecordId, 'DOC-job');
      expect(saved.attachments.single.isReadOnlyProof, isTrue);
      expect(saved.attachments.single.canEditProofFileInApp, isFalse);
      expect(await File(promoted.path).exists(), isTrue);
      expect(await sourcePdf.exists(), isTrue);
    },
  );

  test(
    'deleting app document removes app-owned proof without touching source',
    () async {
      final store = AppDocumentStore.memory();
      final staged = await ReceiptProofStorage.instance.stageAttachment(
        ReceiptAttachmentRecord(
          id: 'delete-job-pdf',
          path: sourcePdf.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 15),
        ),
      );
      final promoted = await ReceiptProofStorage.instance.persistAttachment(
        staged.copyWith(
          linkedModule: AppDocumentKind.jobContractorDocument.storageModule,
          linkedRecordId: 'DOC-delete-job',
        ),
      );
      await store.saveRecord(
        AppDocumentRecord(
          id: 'DOC-delete-job',
          kind: AppDocumentKind.jobContractorDocument,
          title: 'Delete proof',
          createdAt: DateTime(2026, 6, 15),
          updatedAt: DateTime(2026, 6, 15),
          attachments: [promoted],
        ),
      );

      expect(await File(promoted.path).exists(), isTrue);
      await store.deleteRecord('DOC-delete-job');

      expect(store.recordById('DOC-delete-job'), isNull);
      expect(await File(promoted.path).exists(), isFalse);
      expect(await sourcePdf.exists(), isTrue);
    },
  );

  test(
    'deleting app document removes symlink proof without touching target',
    () async {
      final store = AppDocumentStore.memory();
      final appProofDirectory = Directory(
        '${documentsDirectory.path}/receipt_proofs/pdfs',
      );
      await appProofDirectory.create(recursive: true);
      final outsideTarget = File(
        '${Directory.systemTemp.path}/outside_app_document_target.pdf',
      );
      await outsideTarget.writeAsString(
        '%PDF-1.7\nOutside target\n%%EOF',
        flush: true,
      );
      addTearDown(() async {
        if (await outsideTarget.exists()) await outsideTarget.delete();
      });
      final symlink = Link('${appProofDirectory.path}/linked-proof.pdf');
      await symlink.create(outsideTarget.path);
      await store.saveRecord(
        AppDocumentRecord(
          id: 'DOC-symlink-delete',
          kind: AppDocumentKind.jobContractorDocument,
          title: 'Linked proof',
          createdAt: DateTime(2026, 7, 5),
          updatedAt: DateTime(2026, 7, 5),
          attachments: [
            ReceiptAttachmentRecord(
              id: 'linked-proof',
              path: symlink.path,
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.original,
              createdAt: DateTime(2026, 7, 5),
              storageState: ReceiptAttachmentStorageState.permanent,
            ),
          ],
        ),
      );

      await store.deleteRecord('DOC-symlink-delete');

      expect(store.recordById('DOC-symlink-delete'), isNull);
      expect(await symlink.exists(), isFalse);
      expect(await outsideTarget.exists(), isTrue);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test(
    'document import save failure rolls back promoted proof for retry',
    () async {
      final staged = await ReceiptProofStorage.instance.stageAttachment(
        ReceiptAttachmentRecord(
          id: 'rollback-job-pdf',
          path: sourcePdf.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 15),
        ),
      );
      final stagingPath = staged.path;
      final failingService = AppDocumentImportService(
        store: _FailingAppDocumentStore(),
      );

      await expectLater(
        failingService.saveReadOnlyDocument(
          kind: AppDocumentKind.jobContractorDocument,
          attachments: [staged],
          title: 'Rollback proof',
          now: DateTime(2026, 6, 15, 10),
        ),
        throwsA(isA<StateError>()),
      );

      expect(await File(stagingPath).exists(), isTrue);
      final permanentPdfRoot = Directory(
        '${documentsDirectory.path}/receipt_proofs/pdfs',
      );
      if (await permanentPdfRoot.exists()) {
        final leftovers = await permanentPdfRoot
            .list(recursive: true)
            .where((entity) => entity is File)
            .toList();
        expect(leftovers, isEmpty);
      }

      final retryStore = AppDocumentStore.memory();
      final saved = await AppDocumentImportService(store: retryStore)
          .saveReadOnlyDocument(
            kind: AppDocumentKind.jobContractorDocument,
            attachments: [staged],
            title: 'Rollback proof',
            now: DateTime(2026, 6, 15, 10),
          );

      expect(saved.attachments.single.storageState.name, 'permanent');
      expect(await File(saved.attachments.single.path).exists(), isTrue);
      expect(await File(stagingPath).exists(), isFalse);
      expect(retryStore.recordById(saved.id), isNotNull);
      expect(await sourcePdf.exists(), isTrue);
    },
  );

  test('document import refuses empty read-only records', () async {
    final store = AppDocumentStore.memory();

    await expectLater(
      AppDocumentImportService(store: store).saveReadOnlyDocument(
        kind: AppDocumentKind.jobContractorDocument,
        attachments: const [],
        title: 'Empty packet',
        notes: 'Notes are not proof.',
        now: DateTime(2026, 7, 5, 12),
      ),
      throwsA(
        isA<AppDocumentImportException>().having(
          (error) => error.message,
          'message',
          contains('no proof file or imported text'),
        ),
      ),
    );

    expect(store.records, isEmpty);
  });

  test('document import accepts imported text as read-only proof', () async {
    final store = AppDocumentStore.memory();

    final saved = await AppDocumentImportService(store: store)
        .saveReadOnlyDocument(
          kind: AppDocumentKind.jobContractorDocument,
          attachments: const [],
          importedText: '  Confirmed supplier PDF text layer.  ',
          title: 'Supplier packet',
          now: DateTime(2026, 7, 5, 12),
        );

    expect(saved.hasProof, isTrue);
    expect(saved.importedText, 'Confirmed supplier PDF text layer.');
    expect(saved.attachments, isEmpty);
    expect(store.recordById(saved.id), isNotNull);
  });

  test(
    'document package import saves verified proof and cleans extraction',
    () async {
      final store = AppDocumentStore.memory();
      final packageFile = await _writeDocumentExportPackage(
        outputDirectory: Directory('${documentsDirectory.path}/exports'),
        title: 'Imported job packet',
      );
      final extractionParent = Directory('${documentsDirectory.path}/imports');

      final saved = await AppDocumentImportService(store: store)
          .saveDocumentExportPackage(
            packageFile: packageFile,
            extractionParentDirectory: extractionParent,
            now: DateTime(2026, 7, 5, 11),
          );

      expect(saved.kind, AppDocumentKind.jobContractorDocument);
      expect(saved.title, 'Imported job packet');
      expect(saved.sourceLabel, 'Maintainiac document export package');
      expect(saved.attachments, hasLength(1));
      expect(saved.attachments.single.linkedModule, 'jobs');
      expect(saved.attachments.single.linkedRecordId, saved.id);
      expect(saved.attachments.single.isReadOnlyProof, isTrue);
      expect(saved.attachments.single.storageState.name, 'permanent');
      expect(
        saved.attachments.single.sourceLabel,
        packageFile.path.split('/').last,
      );
      expect(await File(saved.attachments.single.path).exists(), isTrue);
      expect(await packageFile.exists(), isTrue);
      expect(await extractionParent.exists(), isTrue);
      final extractedFiles = await extractionParent
          .list(recursive: true)
          .where((entity) => entity is File)
          .toList();
      expect(extractedFiles, isEmpty);
      expect(store.recordById(saved.id), isNotNull);
    },
  );

  test(
    'document package import rollback preserves package and clears extraction',
    () async {
      final packageFile = await _writeDocumentExportPackage(
        outputDirectory: Directory('${documentsDirectory.path}/exports'),
        title: 'Rollback imported package',
      );
      final extractionParent = Directory('${documentsDirectory.path}/imports');

      await expectLater(
        AppDocumentImportService(
          store: _FailingAppDocumentStore(),
        ).saveDocumentExportPackage(
          packageFile: packageFile,
          extractionParentDirectory: extractionParent,
          now: DateTime(2026, 7, 5, 11),
        ),
        throwsA(isA<StateError>()),
      );

      expect(await packageFile.exists(), isTrue);
      if (await extractionParent.exists()) {
        final extractedFiles = await extractionParent
            .list(recursive: true)
            .where((entity) => entity is File)
            .toList();
        expect(extractedFiles, isEmpty);
      }
      final permanentPdfRoot = Directory(
        '${documentsDirectory.path}/receipt_proofs/pdfs',
      );
      if (await permanentPdfRoot.exists()) {
        final leftovers = await permanentPdfRoot
            .list(recursive: true)
            .where((entity) => entity is File)
            .toList();
        expect(leftovers, isEmpty);
      }
    },
  );

  test(
    'document package import cleanup removes stale app-owned folders only',
    () async {
      final importRoot = Directory('${documentsDirectory.path}/imports');
      await importRoot.create(recursive: true);
      final stalePartial = Directory(
        '${importRoot.path}/maintainiac-document-export-abcdef123456.partial',
      );
      final staleComplete = Directory(
        '${importRoot.path}/maintainiac-document-export-abcdef123456-copy-2',
      );
      final foreignPartial = Directory(
        '${importRoot.path}/customer-document-export-abcdef123456.partial',
      );
      for (final directory in [stalePartial, staleComplete, foreignPartial]) {
        await directory.create(recursive: true);
        await File(
          '${directory.path}/proof.pdf',
        ).writeAsString('temporary import proof', flush: true);
      }

      final deleted =
          await AppDocumentImportService.cleanupStaleDocumentPackageImports(
            importRoot,
            now: DateTime.now().add(const Duration(hours: 13)),
          );

      expect(deleted, [
        'maintainiac-document-export-abcdef123456-copy-2',
        'maintainiac-document-export-abcdef123456.partial',
      ]);
      expect(await stalePartial.exists(), isFalse);
      expect(await staleComplete.exists(), isFalse);
      expect(await foreignPartial.exists(), isTrue);
    },
  );

  test(
    'document package import cleanup removes symlink without touching target',
    () async {
      final importRoot = Directory('${documentsDirectory.path}/imports');
      await importRoot.create(recursive: true);
      final outsideTarget = Directory(
        '${Directory.systemTemp.path}/outside_package_import_target',
      );
      await outsideTarget.create(recursive: true);
      await File(
        '${outsideTarget.path}/private-proof.pdf',
      ).writeAsString('%PDF-1.7\nOutside import target\n%%EOF', flush: true);
      addTearDown(() async {
        if (await outsideTarget.exists()) {
          await outsideTarget.delete(recursive: true);
        }
      });
      final staleLink = Link(
        '${importRoot.path}/maintainiac-document-export-abcdef123456.partial',
      );
      await staleLink.create(outsideTarget.path);

      final deleted =
          await AppDocumentImportService.cleanupStaleDocumentPackageImports(
            importRoot,
            now: DateTime.now().add(const Duration(hours: 13)),
          );

      expect(deleted, ['maintainiac-document-export-abcdef123456.partial']);
      expect(await staleLink.exists(), isFalse);
      expect(await outsideTarget.exists(), isTrue);
      expect(
        await File('${outsideTarget.path}/private-proof.pdf').exists(),
        isTrue,
      );
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test(
    'document package import cleanup refuses symlinked import root',
    () async {
      final outsideRoot = Directory(
        '${Directory.systemTemp.path}/outside_package_import_root',
      );
      await outsideRoot.create(recursive: true);
      await File(
        '${outsideRoot.path}/private-proof.pdf',
      ).writeAsString('%PDF-1.7\nOutside import root\n%%EOF', flush: true);
      final importRootLink = Link('${documentsDirectory.path}/imports-link');
      await importRootLink.create(outsideRoot.path);
      addTearDown(() async {
        if (await importRootLink.exists()) await importRootLink.delete();
        if (await outsideRoot.exists()) {
          await outsideRoot.delete(recursive: true);
        }
      });

      await expectLater(
        AppDocumentImportService.cleanupStaleDocumentPackageImports(
          Directory(importRootLink.path),
          now: DateTime.now().add(const Duration(hours: 13)),
        ),
        throwsA(isA<AppDocumentExportPackageException>()),
      );

      expect(await importRootLink.exists(), isTrue);
      expect(
        await File('${outsideRoot.path}/private-proof.pdf').exists(),
        isTrue,
      );
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test('document package import runs stale cleanup before extraction', () async {
    final store = AppDocumentStore.memory();
    final packageFile = await _writeDocumentExportPackage(
      outputDirectory: Directory('${documentsDirectory.path}/exports'),
      title: 'Cleanup before import',
    );
    final extractionParent = Directory('${documentsDirectory.path}/imports');
    await extractionParent.create(recursive: true);
    final stalePartial = Directory(
      '${extractionParent.path}/maintainiac-document-export-abcdef123456.partial',
    );
    await stalePartial.create(recursive: true);
    await File(
      '${stalePartial.path}/orphan.pdf',
    ).writeAsString('old orphaned import', flush: true);

    final saved = await AppDocumentImportService(store: store)
        .saveDocumentExportPackage(
          packageFile: packageFile,
          extractionParentDirectory: extractionParent,
          now: DateTime(2026, 7, 5, 11),
          cleanupNow: DateTime.now().add(const Duration(hours: 13)),
        );

    expect(store.recordById(saved.id), isNotNull);
    expect(await stalePartial.exists(), isFalse);
    expect(await File(saved.attachments.single.path).exists(), isTrue);
    final leftovers = await extractionParent
        .list(recursive: true)
        .where((entity) => entity is File)
        .toList();
    expect(leftovers, isEmpty);
  });

  test('document store cleanup source avoids following symlinks', () {
    final source = File(
      'lib/shared/documents/app_document_store.dart',
    ).readAsStringSync();

    expect(source, contains('FileSystemEntity.type('));
    expect(source, contains('followLinks: false'));
    expect(source, contains('FileSystemEntityType.link'));
    expect(source, contains('await Link(normalized).delete();'));
    expect(source, contains('path.absolute(root.path)'));
  });

  test('document package import cleanup source avoids following symlinks', () {
    final source = File(
      'lib/shared/documents/app_document_import_service.dart',
    ).readAsStringSync();

    expect(source, contains('_deletePackageImportEntity'));
    expect(source, contains('FileSystemEntity.type(entityPath'));
    expect(source, contains('followLinks: false'));
    expect(source, contains('FileSystemEntityType.link'));
    expect(source, contains('await Link(entityPath).delete();'));
  });
}

Future<File> _writeDocumentExportPackage({
  required Directory outputDirectory,
  required String title,
}) async {
  final source = File('${outputDirectory.parent.path}/package_source.pdf');
  final pdf = pw.Document()..addPage(pw.Page(build: (_) => pw.Text(title)));
  final bytes = await pdf.save();
  await source.writeAsBytes(bytes, flush: true);
  final hash = sha256.convert(bytes).toString();
  final result = await AppDocumentExportPackageWriter().writeZipPackage(
    record: AppDocumentRecord(
      id: 'DOC-package-source',
      kind: AppDocumentKind.jobContractorDocument,
      title: title,
      sourceLabel: 'Shared import',
      createdAt: DateTime.utc(2026, 7, 5, 10),
      updatedAt: DateTime.utc(2026, 7, 5, 10),
      attachments: [
        ReceiptAttachmentRecord(
          id: 'package-source-pdf',
          path: source.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime.utc(2026, 7, 5, 10),
          displayName: 'package-source.pdf',
          originalFileName: 'package-source.pdf',
          mimeType: 'application/pdf',
          byteSize: bytes.length,
          fileHash: hash,
          documentSignals: const ['job'],
          linkedModule: 'jobs',
          linkedRecordId: 'DOC-package-source',
          readState: ReceiptAttachmentReadState.notRead,
        ),
      ],
    ),
    outputDirectory: outputDirectory,
    freeStorageReader: () async => 500,
  );
  return File(result.filePath);
}

class _FailingAppDocumentStore extends AppDocumentStore {
  _FailingAppDocumentStore() : super.memory();

  @override
  Future<AppDocumentRecord> saveRecord(AppDocumentRecord record) {
    throw StateError('simulated document import failure');
  }
}
