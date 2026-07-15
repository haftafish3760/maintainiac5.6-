import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_draft_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_proof_storage.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory documentsDirectory;
  late File sourcePdf;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'expense_draft_storage_lifecycle_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getApplicationDocumentsDirectory' => documentsDirectory.path,
            _ => null,
          },
        );
    sourcePdf = File('${Directory.systemTemp.path}/draft_source_receipt.pdf');
    final pdf = pw.Document()
      ..addPage(pw.Page(build: (_) => pw.Text('Draft receipt')));
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
    'background or interruption keeps active draft proof recoverable',
    () async {
      final drafts = ExpenseDraftController.memory();
      final staged = await _stagedPdf('active-interrupted-proof', sourcePdf);
      await File(staged.path).setLastModified(DateTime(2026, 1, 1));

      await drafts.saveDraft(_draft('DRAFT-active', staged));
      final snapshot = await drafts.cleanAbandonedStagedProofs(
        olderThan: const Duration(days: 7),
        now: DateTime(2026, 6, 15),
      );

      expect(snapshot.recoverableDraftIds, contains('DRAFT-active'));
      expect(snapshot.retainedStagedProofPaths, contains(staged.path));
      expect(await File(staged.path).exists(), isTrue);
      expect(await sourcePdf.exists(), isTrue);
    },
  );

  test('discarding a receipt draft deletes staged copy only', () async {
    final drafts = ExpenseDraftController.memory();
    final staged = await _stagedPdf('discarded-proof', sourcePdf);

    await drafts.saveDraft(_draft('DRAFT-discard', staged));
    await drafts.deleteDraft('DRAFT-discard');

    expect(drafts.draftById('DRAFT-discard'), isNull);
    expect(await File(staged.path).exists(), isFalse);
    expect(await sourcePdf.exists(), isTrue);
  });

  test(
    'promoted proof keeps staged recovery copy until permanent path is checkpointed',
    () async {
      final drafts = ExpenseDraftController.memory();
      final staged = await _stagedPdf('checkpoint-proof', sourcePdf);
      final promoted = (await ReceiptProofStorage.instance.persistAttachments([
        staged,
      ], retainStagedSources: true)).single;

      expect(await File(staged.path).exists(), isTrue);
      expect(await File(promoted.path).exists(), isTrue);

      await drafts.saveDraft(_draft('DRAFT-checkpoint', promoted));
      await ReceiptProofStorage.instance.deleteStagedAttachments([staged]);

      final recovered = drafts.draftById('DRAFT-checkpoint')!;
      expect(recovered.attachments.single.path, promoted.path);
      expect(await File(recovered.attachments.single.path).exists(), isTrue);
      expect(await File(staged.path).exists(), isFalse);
      expect(await sourcePdf.exists(), isTrue);
    },
  );
}

Future<ReceiptAttachmentRecord> _stagedPdf(String id, File source) {
  return ReceiptProofStorage.instance.stageAttachment(
    ReceiptAttachmentRecord(
      id: id,
      path: source.path,
      kind: ReceiptAttachmentKind.pdf,
      dataSaverLevel: ReceiptDataSaverLevel.original,
      createdAt: DateTime(2026, 6, 15),
    ),
  );
}

ExpenseReceiptDraftRecord _draft(String id, ReceiptAttachmentRecord proof) {
  return ExpenseReceiptDraftRecord(
    id: id,
    receiptDate: DateTime(2026, 6, 15),
    merchantName: 'Advance Auto Parts',
    hasReceiptProof: true,
    attachments: [proof],
    updatedAt: DateTime(2026, 6, 15),
    lines: const [
      ExpenseReceiptLineRecord(
        id: 'DRAFT-LINE-1',
        description: 'Brake caliper',
        category: 'Repair',
        use: ExpenseLineUse.business,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 96.40,
      ),
    ],
  );
}
