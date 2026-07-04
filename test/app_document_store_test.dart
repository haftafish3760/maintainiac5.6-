import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}

class _FailingAppDocumentStore extends AppDocumentStore {
  _FailingAppDocumentStore() : super.memory();

  @override
  Future<AppDocumentRecord> saveRecord(AppDocumentRecord record) {
    throw StateError('simulated document import failure');
  }
}
