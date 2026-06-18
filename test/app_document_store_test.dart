import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
