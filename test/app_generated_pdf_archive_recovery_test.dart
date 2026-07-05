import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/documents/app_document_models.dart';
import 'package:maintaniac/shared/documents/app_document_store.dart';
import 'package:maintaniac/shared/documents/app_generated_pdf_archive_service.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'generated_pdf_archive_recovery_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            'getTemporaryDirectory' => documentsDirectory.path,
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

  test('archive cleanup deletes stale generated PDF partials only', () async {
    final directory = await Directory(
      '${documentsDirectory.path}/app_documents/invoices/generated_pdfs',
    ).create(recursive: true);
    final stalePartial = File('${directory.path}/invoice.pdf.partial');
    final freshPartial = File('${directory.path}/fresh.pdf.partial');
    final staleNonPdfPartial = File('${directory.path}/invoice.txt.partial');
    final completePdf = File('${directory.path}/complete.pdf');
    await stalePartial.writeAsString('stale', flush: true);
    await freshPartial.writeAsString('fresh', flush: true);
    await staleNonPdfPartial.writeAsString('not pdf', flush: true);
    await completePdf.writeAsString('%PDF-1.7\n%%EOF', flush: true);
    await stalePartial.setLastModified(DateTime(2026, 7, 4, 8));
    await freshPartial.setLastModified(DateTime(2026, 7, 4, 23));
    await staleNonPdfPartial.setLastModified(DateTime(2026, 7, 4, 8));
    await completePdf.setLastModified(DateTime(2026, 7, 4, 8));

    final deleted = await AppGeneratedPdfArchiveService.deleteStalePartialFiles(
      directory,
      now: DateTime(2026, 7, 5, 5),
    );

    expect(deleted, 1);
    expect(await stalePartial.exists(), isFalse);
    expect(await freshPartial.exists(), isTrue);
    expect(await staleNonPdfPartial.exists(), isTrue);
    expect(await completePdf.exists(), isTrue);
  });

  test(
    'archive clears stale partial blocking the requested filename',
    () async {
      final store = AppDocumentStore.memory();
      final directory = await Directory(
        '${documentsDirectory.path}/app_documents/invoices/generated_pdfs',
      ).create(recursive: true);
      final stalePartial = File('${directory.path}/invoice.pdf.partial');
      await stalePartial.writeAsString('stale', flush: true);
      await stalePartial.setLastModified(DateTime(2020, 1, 1));

      final archived = await AppGeneratedPdfArchiveService(store: store)
          .archive(
            _document(fileName: 'invoice.pdf', sourceRecordId: 'stale_clear'),
          );

      expect(await stalePartial.exists(), isFalse);
      expect(archived.attachment.path, endsWith('/invoice.pdf'));
      expect(await File(archived.attachment.path).exists(), isTrue);
      expect(store.recordById('DOC-invoice-stale_clear'), isNotNull);
    },
  );

  test('archive keeps fresh partial and writes to copy filename', () async {
    final store = AppDocumentStore.memory();
    final directory = await Directory(
      '${documentsDirectory.path}/app_documents/invoices/generated_pdfs',
    ).create(recursive: true);
    final freshPartial = File('${directory.path}/invoice.pdf.partial');
    await freshPartial.writeAsString('fresh', flush: true);
    await freshPartial.setLastModified(DateTime.now());

    final archived = await AppGeneratedPdfArchiveService(
      store: store,
    ).archive(_document(fileName: 'invoice.pdf', sourceRecordId: 'fresh_keep'));

    expect(await freshPartial.exists(), isTrue);
    expect(archived.attachment.path, endsWith('/invoice-copy-2.pdf'));
    expect(await File(archived.attachment.path).exists(), isTrue);
    expect(store.recordById('DOC-invoice-fresh_keep'), isNotNull);
  });

  test('archive stores final file with exact byte count and hash', () async {
    final store = AppDocumentStore.memory();
    final document = _document(
      fileName: 'invoice-integrity.pdf',
      sourceRecordId: 'integrity',
      body: 'Invoice integrity total 42.00',
    );

    final archived = await AppGeneratedPdfArchiveService(
      store: store,
    ).archive(document);
    final file = File(archived.attachment.path);
    final bytes = await file.readAsBytes();

    expect(bytes, document.bytes);
    expect(await file.length(), document.byteSize);
    expect(archived.attachment.byteSize, document.byteSize);
    expect(archived.fileHashSha256, sha256.convert(document.bytes).toString());
    expect(archived.attachment.fileHash, archived.fileHashSha256);
  });

  test(
    'archive removes partial and destination when document save fails',
    () async {
      final store = _FailingDocumentStore();
      final document = _document(
        fileName: 'rollback.pdf',
        sourceRecordId: 'rollback_recovery',
      );

      await expectLater(
        AppGeneratedPdfArchiveService(store: store).archive(document),
        throwsA(isA<AppGeneratedPdfArchiveException>()),
      );

      expect(_filesUnder(documentsDirectory), isEmpty);
    },
  );

  test('archive replacement deletes only old app-owned generated PDF', () async {
    final store = AppDocumentStore.memory();
    final first = await AppGeneratedPdfArchiveService(store: store).archive(
      _document(
        fileName: 'replace.pdf',
        sourceRecordId: 'replace_recovery',
        body: 'Invoice first total 10.00',
      ),
    );
    final unrelated = File(
      '${documentsDirectory.path}/app_documents/invoices/generated_pdfs/manual-note.txt',
    );
    await unrelated.writeAsString('do not delete', flush: true);

    final second = await AppGeneratedPdfArchiveService(store: store).archive(
      _document(
        fileName: 'replace.pdf',
        sourceRecordId: 'replace_recovery',
        body: 'Invoice second total 20.00',
      ),
    );

    expect(first.document.id, second.document.id);
    expect(await File(first.attachment.path).exists(), isFalse);
    expect(await File(second.attachment.path).exists(), isTrue);
    expect(await unrelated.exists(), isTrue);
  });

  test('archive keeps custom title and notes out of filename path', () async {
    final store = AppDocumentStore.memory();
    final archived = await AppGeneratedPdfArchiveService(store: store).archive(
      _document(
        fileName: r'C:\Users\Owner\invoice:unsafe?.pdf',
        sourceRecordId: r'unsafe/../id',
      ),
      title: 'Customer facing title',
      notes: 'Confirmed generated PDF copy.',
    );

    final basename = File(archived.attachment.path).uri.pathSegments.last;
    expect(archived.document.title, 'Customer facing title');
    expect(archived.document.notes, 'Confirmed generated PDF copy.');
    expect(basename, endsWith('.pdf'));
    expect(basename, isNot(contains(RegExp(r'[\\/:*?"<>|]'))));
    expect(basename, isNot(contains('..')));
    expect(archived.document.id, 'DOC-invoice-unsafe-id');
  });

  test(
    'archive refuses private custom title and notes before permanent write',
    () async {
      final store = AppDocumentStore.memory();
      await expectLater(
        AppGeneratedPdfArchiveService(store: store).archive(
          _document(
            fileName: 'private-title.pdf',
            sourceRecordId: 'private_title',
          ),
          title: 'Invoice for VIN 1HGCM82633A004352',
        ),
        throwsA(
          isA<AppGeneratedPdfArchiveException>().having(
            (error) => error.message,
            'message',
            contains('private information'),
          ),
        ),
      );
      await expectLater(
        AppGeneratedPdfArchiveService(store: store).archive(
          _document(
            fileName: 'private-note.pdf',
            sourceRecordId: 'private_note',
          ),
          notes: 'Passenger name: Jane Customer',
        ),
        throwsA(isA<AppGeneratedPdfArchiveException>()),
      );

      expect(store.records, isEmpty);
      expect(_filesUnder(documentsDirectory), isEmpty);
    },
  );

  test('archive keeps source metadata out of human document labels', () async {
    final store = AppDocumentStore.memory();
    final archived = await AppGeneratedPdfArchiveService(store: store).archive(
      _document(fileName: 'metadata-safe.pdf', sourceRecordId: 'metadata_safe'),
      title: 'Customer invoice',
      notes: 'Generated from confirmed invoice data.',
    );

    expect(archived.document.title, 'Customer invoice');
    expect(archived.document.notes, 'Generated from confirmed invoice data.');
    expect(archived.document.title, isNot(contains('metadata_safe')));
    expect(archived.document.notes, isNot(contains('metadata_safe')));
    expect(archived.attachment.linkedRecordId, 'metadata_safe');
  });

  test(
    'archive recovery source keeps final verification and stale cleanup',
    () {
      final source = File(
        'lib/shared/documents/app_generated_pdf_archive_service.dart',
      ).readAsStringSync();

      expect(source, contains('stalePartialAge'));
      expect(source, contains('_deleteStalePartialFiles'));
      expect(source, contains("endsWith('.pdf.partial')"));
      expect(source, contains('_verifyPermanentWrite(destination, document)'));
      expect(source, contains('_ensureSafeArchiveMetadata'));
      expect(source, contains('AppPdfPrivacyPolicy.issueCodesForExport'));
      expect(source, contains("throw const FileSystemException("));
      expect(source, contains("'Generated PDF final file was incomplete.'"));
      expect(source, contains("'Generated PDF final file did not verify.'"));
    },
  );
}

AppGeneratedPdfDocument _document({
  required String fileName,
  required String sourceRecordId,
  String body = 'Invoice archive total 12.34',
}) {
  return AppGeneratedPdfDocument(
    kind: AppGeneratedPdfKind.invoice,
    title: 'Invoice $sourceRecordId',
    fileName: fileName,
    bytes: Uint8List.fromList('%PDF-1.7\n$body\n%%EOF'.codeUnits),
    createdAt: DateTime(2026, 7, 5),
    sourceModule: 'invoices',
    sourceRecordId: sourceRecordId,
  );
}

List<File> _filesUnder(Directory root) {
  if (!root.existsSync()) return const [];
  return root
      .listSync(recursive: true)
      .whereType<File>()
      .toList(growable: false);
}

class _FailingDocumentStore extends AppDocumentStore {
  _FailingDocumentStore() : super.memory();

  @override
  Future<AppDocumentRecord> saveRecord(AppDocumentRecord record) async {
    throw StateError('simulated document-store failure');
  }
}
