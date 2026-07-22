import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_proof_storage.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documentsDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'receipt_proof_storage_lifecycle_',
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

  test('receipt proof storage copies a picked PDF into app storage', () async {
    final source = File('${Directory.systemTemp.path}/picked_receipt.pdf');
    final pdf = pw.Document()
      ..addPage(pw.Page(build: (_) => pw.Text('Counter receipt')));
    await source.writeAsBytes(await pdf.save(), flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final saved = await ReceiptProofStorage.instance.persistAttachment(
      ReceiptAttachmentRecord(
        id: 'pdf-copy',
        path: source.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 13),
        displayName: 'picked_receipt.pdf',
        byteSize: await source.length(),
      ),
    );

    expect(saved.path, isNot(source.path));
    expect(await File(saved.path).exists(), isTrue);
    expect(saved.byteSize, await File(saved.path).length());
    expect(saved.fileHash, isNotEmpty);
    expect(saved.pageCount, 1);
    expect(saved.originalFileName, 'picked_receipt.pdf');
    expect(saved.mimeType, 'application/pdf');
    expect(saved.isOriginalImmutable, isTrue);
  });

  test(
    'missing proof files remain traceable instead of appearing saved',
    () async {
      final missing = await ReceiptProofStorage.instance.persistAttachment(
        ReceiptAttachmentRecord(
          id: 'missing-proof',
          path: '${documentsDirectory.path}/no-longer-available.pdf',
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 7, 15),
        ),
      );

      expect(missing.storageState, ReceiptAttachmentStorageState.missing);
      expect(missing.path, endsWith('no-longer-available.pdf'));
    },
  );

  test('pdf import stages proof before permanent save', () async {
    final source = File('${Directory.systemTemp.path}/staged_receipt.pdf');
    final pdf = pw.Document()
      ..addPage(pw.Page(build: (_) => pw.Text('Staged receipt')));
    await source.writeAsBytes(await pdf.save(), flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final staged = await ReceiptProofStorage.instance.stageAttachment(
      ReceiptAttachmentRecord(
        id: 'pdf-stage',
        path: source.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 13),
        originalFileName: 'staged_receipt.pdf',
      ),
    );

    expect(staged.path, isNot(source.path));
    expect(staged.path, contains('receipt_proofs_staging'));
    expect(staged.storageState, ReceiptAttachmentStorageState.staged);
    expect(await File(staged.path).exists(), isTrue);
    expect(
      await Directory(
        '${documentsDirectory.path}/receipt_proofs/pdfs',
      ).exists(),
      isFalse,
    );
  });

  test('removing a staged PDF deletes the staged copy only', () async {
    final source = File('${Directory.systemTemp.path}/cancel_receipt.pdf');
    final pdf = pw.Document()
      ..addPage(pw.Page(build: (_) => pw.Text('Cancel receipt')));
    await source.writeAsBytes(await pdf.save(), flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final staged = await ReceiptProofStorage.instance.stageAttachment(
      ReceiptAttachmentRecord(
        id: 'pdf-cancel',
        path: source.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 13),
      ),
    );
    await ReceiptProofStorage.instance.deleteStagedAttachment(staged);

    expect(await File(staged.path).exists(), isFalse);
    expect(await source.exists(), isTrue);
  });

  test('saving a staged PDF promotes it to permanent proof storage', () async {
    final source = File('${Directory.systemTemp.path}/promote_receipt.pdf');
    final pdf = pw.Document()
      ..addPage(pw.Page(build: (_) => pw.Text('Prom receipt')));
    await source.writeAsBytes(await pdf.save(), flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final staged = await ReceiptProofStorage.instance.stageAttachment(
      ReceiptAttachmentRecord(
        id: 'pdf-promote',
        path: source.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 13),
      ),
    );
    final stagedPath = staged.path;
    final promoted = await ReceiptProofStorage.instance.persistAttachment(
      staged.copyWith(linkedModule: 'expenses', linkedRecordId: 'EXP-1'),
    );

    expect(promoted.storageState, ReceiptAttachmentStorageState.permanent);
    expect(promoted.promotedAt, isNotNull);
    expect(promoted.linkedModule, 'expenses');
    expect(promoted.linkedRecordId, 'EXP-1');
    expect(promoted.path, contains('receipt_proofs/pdfs'));
    expect(await File(promoted.path).exists(), isTrue);
    expect(await File(stagedPath).exists(), isFalse);
    expect(await source.exists(), isTrue);
  });

  test(
    'failed batch save restores staged PDFs and removes orphan proof',
    () async {
      final source = File('${Directory.systemTemp.path}/batch_receipt.pdf');
      final bad = File('${Directory.systemTemp.path}/batch_bad.pdf');
      final pdf = pw.Document()
        ..addPage(pw.Page(build: (_) => pw.Text('Batch receipt')));
      await source.writeAsBytes(await pdf.save(), flush: true);
      await bad.writeAsString('not a pdf', flush: true);
      addTearDown(() {
        if (source.existsSync()) source.deleteSync();
        if (bad.existsSync()) bad.deleteSync();
      });

      final staged = await ReceiptProofStorage.instance.stageAttachment(
        ReceiptAttachmentRecord(
          id: 'pdf-batch-good',
          path: source.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 13),
        ),
      );
      final stagedPath = staged.path;

      await expectLater(
        ReceiptProofStorage.instance.persistAttachments([
          staged.copyWith(
            linkedModule: 'expenses',
            linkedRecordId: 'EXP-batch',
          ),
          ReceiptAttachmentRecord(
            id: 'pdf-batch-bad',
            path: bad.path,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 6, 13),
          ),
        ]),
        throwsA(isA<ReceiptProofStorageException>()),
      );

      expect(await File(stagedPath).exists(), isTrue);
      final permanentPdfDir = Directory(
        '${documentsDirectory.path}/receipt_proofs/pdfs',
      );
      final permanentFiles = permanentPdfDir.existsSync()
          ? permanentPdfDir.listSync().whereType<File>().toList()
          : <File>[];
      expect(permanentFiles, isEmpty);
    },
  );

  test('failed batch save removes copied external PDFs', () async {
    final source = File('${Directory.systemTemp.path}/batch_external.pdf');
    final bad = File('${Directory.systemTemp.path}/batch_external_bad.pdf');
    final pdf = pw.Document()
      ..addPage(pw.Page(build: (_) => pw.Text('External batch receipt')));
    await source.writeAsBytes(await pdf.save(), flush: true);
    await bad.writeAsString('not a pdf', flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
      if (bad.existsSync()) bad.deleteSync();
    });

    await expectLater(
      ReceiptProofStorage.instance.persistAttachments([
        ReceiptAttachmentRecord(
          id: 'pdf-batch-external-good',
          path: source.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 13),
        ),
        ReceiptAttachmentRecord(
          id: 'pdf-batch-external-bad',
          path: bad.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 13),
        ),
      ]),
      throwsA(isA<ReceiptProofStorageException>()),
    );

    expect(await source.exists(), isTrue);
    final permanentPdfDir = Directory(
      '${documentsDirectory.path}/receipt_proofs/pdfs',
    );
    final permanentFiles = permanentPdfDir.existsSync()
        ? permanentPdfDir.listSync().whereType<File>().toList()
        : <File>[];
    expect(permanentFiles, isEmpty);
  });

  test(
    'receipt proof storage never auto-deletes permanent proof files',
    () async {
      final kept = File('${Directory.systemTemp.path}/kept_receipt.pdf');
      final orphan = File('${Directory.systemTemp.path}/orphan_receipt.pdf');
      final pdf = pw.Document()
        ..addPage(pw.Page(build: (_) => pw.Text('Counter receipt')));
      await kept.writeAsBytes(await pdf.save(), flush: true);
      await orphan.writeAsBytes(await pdf.save(), flush: true);
      addTearDown(() {
        if (kept.existsSync()) kept.deleteSync();
        if (orphan.existsSync()) orphan.deleteSync();
      });

      final savedKept = await ReceiptProofStorage.instance.persistAttachment(
        ReceiptAttachmentRecord(
          id: 'pdf-kept',
          path: kept.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 13),
        ),
      );
      final savedOrphan = await ReceiptProofStorage.instance.persistAttachment(
        ReceiptAttachmentRecord(
          id: 'pdf-orphan',
          path: orphan.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 13),
        ),
      );

      await ReceiptProofStorage.instance.cleanOrphanProofFiles(
        retainedPaths: [savedKept.path],
      );

      expect(await File(savedKept.path).exists(), isTrue);
      expect(await File(savedOrphan.path).exists(), isTrue);
    },
  );

  test('startup cleanup never ages out recoverable staged PDFs', () async {
    final source = File('${Directory.systemTemp.path}/cleanup_receipt.pdf');
    final pdf = pw.Document()
      ..addPage(pw.Page(build: (_) => pw.Text('Cleanup receipt')));
    await source.writeAsBytes(await pdf.save(), flush: true);
    addTearDown(() {
      if (source.existsSync()) source.deleteSync();
    });

    final retained = await ReceiptProofStorage.instance.stageAttachment(
      ReceiptAttachmentRecord(
        id: 'pdf-retained',
        path: source.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 13),
      ),
    );
    final orphan = await ReceiptProofStorage.instance.stageAttachment(
      ReceiptAttachmentRecord(
        id: 'pdf-old-orphan',
        path: source.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 13),
      ),
    );
    await File(orphan.path).setLastModified(DateTime(2026, 1, 1));

    await ReceiptProofStorage.instance.cleanOldStagedFiles(
      retainedPaths: [retained.path],
      now: DateTime(2026, 6, 13),
    );

    expect(await File(retained.path).exists(), isTrue);
    expect(await File(orphan.path).exists(), isTrue);
  });
}
