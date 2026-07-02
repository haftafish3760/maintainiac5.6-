import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_draft_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_proof_storage.dart';

import 'helpers/receipt_pdf_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late Directory documentsDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_draft_store_test_',
    );
    documentsDirectory = await Directory.systemTemp.createTemp(
      'expense_draft_documents_test_',
    );
    mockDocumentsDirectory(documentsDirectory);
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    clearDocumentsDirectoryMock();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
    if (documentsDirectory.existsSync()) {
      await documentsDirectory.delete(recursive: true);
    }
  });

  test('drafts keep receipt attachment metadata', () async {
    final drafts = await ExpenseDraftController.create();
    final draft = ExpenseReceiptDraftRecord(
      id: 'draft-photo',
      receiptDate: DateTime(2026, 6, 11),
      updatedAt: DateTime(2026, 6, 11, 12),
      attachments: [
        ReceiptAttachmentRecord(
          id: 'photo-1',
          path: '/tmp/receipt.jpg',
          kind: ReceiptAttachmentKind.photo,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 6, 11, 12),
          byteSize: 120000,
        ),
        ReceiptAttachmentRecord(
          id: 'email-1',
          path: '',
          kind: ReceiptAttachmentKind.emailText,
          dataSaverLevel: ReceiptDataSaverLevel.balanced,
          createdAt: DateTime(2026, 6, 11, 12),
          displayName: 'Advance Auto email receipt',
          importedText: 'OIL FILTER 12.99',
          byteSize: 16,
        ),
      ],
    );

    await drafts.saveDraft(draft);

    final loaded = drafts.draftById('draft-photo')!;
    expect(loaded.hasReceiptAttachment, isTrue);
    expect(loaded.attachments.first.path, '/tmp/receipt.jpg');
    expect(loaded.attachments.first.byteSize, 120000);
    expect(loaded.attachments.last.kind, ReceiptAttachmentKind.emailText);
    expect(loaded.attachments.last.displayName, 'Advance Auto email receipt');
    expect(loaded.attachments.last.importedText, contains('OIL FILTER'));
  });

  test('drafts report missing receipt proof files for recovery', () async {
    final drafts = await ExpenseDraftController.create();
    final existingProof = File('${Directory.systemTemp.path}/draft-proof.pdf');
    await existingProof.writeAsString('%PDF-1.7\n%%EOF', flush: true);
    addTearDown(() {
      if (existingProof.existsSync()) existingProof.deleteSync();
    });
    final missingPath = '${Directory.systemTemp.path}/missing-draft-proof.pdf';
    if (File(missingPath).existsSync()) File(missingPath).deleteSync();

    await drafts.saveDraft(
      ExpenseReceiptDraftRecord(
        id: 'draft-missing-proof',
        receiptDate: DateTime(2026, 6, 11),
        updatedAt: DateTime(2026, 6, 11, 12),
        attachments: [
          ReceiptAttachmentRecord(
            id: 'existing-pdf',
            path: existingProof.path,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 6, 11, 12),
            storageState: ReceiptAttachmentStorageState.staged,
          ),
          ReceiptAttachmentRecord(
            id: 'missing-pdf',
            path: missingPath,
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 6, 11, 12),
            storageState: ReceiptAttachmentStorageState.staged,
          ),
          ReceiptAttachmentRecord(
            id: 'text-proof',
            path: '',
            kind: ReceiptAttachmentKind.emailText,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 6, 11, 12),
            importedText: 'EMAIL TOTAL 10.00',
          ),
        ],
      ),
    );

    final missing = drafts.missingAttachmentsForDraft('draft-missing-proof');

    expect(drafts.draftHasMissingProof('draft-missing-proof'), isTrue);
    expect(missing.map((attachment) => attachment.id), ['missing-pdf']);
  });

  test(
    'recovery snapshot summarizes restorable and missing proof drafts',
    () async {
      final drafts = await ExpenseDraftController.create();
      final existingProof = File('${Directory.systemTemp.path}/snapshot.pdf');
      await existingProof.writeAsString('%PDF-1.7\n%%EOF', flush: true);
      addTearDown(() {
        if (existingProof.existsSync()) existingProof.deleteSync();
      });
      final missingPath = '${Directory.systemTemp.path}/snapshot-missing.pdf';
      if (File(missingPath).existsSync()) File(missingPath).deleteSync();

      await drafts.saveDraft(
        ExpenseReceiptDraftRecord(
          id: 'recoverable-draft',
          receiptDate: DateTime(2026, 6, 14),
          updatedAt: DateTime(2026, 6, 14, 12),
          merchantName: 'Advance Auto',
          attachments: [
            ReceiptAttachmentRecord(
              id: 'existing',
              path: existingProof.path,
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.original,
              createdAt: DateTime(2026, 6, 14),
              storageState: ReceiptAttachmentStorageState.staged,
            ),
            ReceiptAttachmentRecord(
              id: 'missing',
              path: missingPath,
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.original,
              createdAt: DateTime(2026, 6, 14),
              storageState: ReceiptAttachmentStorageState.staged,
            ),
          ],
        ),
      );

      final snapshot = drafts.recoverySnapshot();

      expect(snapshot.hasRecoverableWork, isTrue);
      expect(snapshot.draftCount, 1);
      expect(snapshot.recoverableDraftIds, ['recoverable-draft']);
      expect(snapshot.hasMissingProof, isTrue);
      expect(snapshot.missingProofDraftCount, 1);
      expect(snapshot.missingProofCount, 1);
      expect(snapshot.retainedStagedProofPaths, contains(existingProof.path));
      expect(snapshot.retainedStagedProofPaths, contains(missingPath));
    },
  );

  test(
    'startup cleanup keeps active draft proofs and removes old orphan staging',
    () async {
      final drafts = await ExpenseDraftController.create();
      final retainedSource = File(
        '${Directory.systemTemp.path}/retained-draft.pdf',
      );
      final orphanSource = File(
        '${Directory.systemTemp.path}/orphan-draft.pdf',
      );
      await retainedSource.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      await orphanSource.writeAsString(
        '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
        flush: true,
      );
      addTearDown(() {
        if (retainedSource.existsSync()) retainedSource.deleteSync();
        if (orphanSource.existsSync()) orphanSource.deleteSync();
      });

      final retained = await ReceiptProofStorage.instance.stageAttachment(
        ReceiptAttachmentRecord(
          id: 'retained-draft-pdf',
          path: retainedSource.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 14),
        ),
      );
      final orphan = await ReceiptProofStorage.instance.stageAttachment(
        ReceiptAttachmentRecord(
          id: 'orphan-draft-pdf',
          path: orphanSource.path,
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 14),
        ),
      );
      await File(retained.path).setLastModified(DateTime(2026, 1, 1));
      await File(orphan.path).setLastModified(DateTime(2026, 1, 1));

      await drafts.saveDraft(
        ExpenseReceiptDraftRecord(
          id: 'active-draft',
          receiptDate: DateTime(2026, 6, 14),
          updatedAt: DateTime(2026, 6, 14, 12),
          attachments: [retained],
        ),
      );

      final snapshot = await drafts.cleanAbandonedStagedProofs(
        now: DateTime(2026, 6, 14),
      );

      expect(snapshot.recoverableDraftIds, ['active-draft']);
      expect(await File(retained.path).exists(), isTrue);
      expect(await File(orphan.path).exists(), isFalse);
      expect(await retainedSource.exists(), isTrue);
      expect(await orphanSource.exists(), isTrue);
    },
  );

  test('deleting a draft removes only app-staged receipt proofs', () async {
    final drafts = await ExpenseDraftController.create();
    final original = File('${Directory.systemTemp.path}/draft-delete.pdf');
    await original.writeAsString(
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (original.existsSync()) original.deleteSync();
    });

    final staged = await ReceiptProofStorage.instance.stageAttachment(
      ReceiptAttachmentRecord(
        id: 'draft-delete-pdf',
        path: original.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 14),
      ),
    );

    await drafts.saveDraft(
      ExpenseReceiptDraftRecord(
        id: 'draft-delete',
        receiptDate: DateTime(2026, 6, 14),
        updatedAt: DateTime(2026, 6, 14, 12),
        attachments: [staged],
      ),
    );

    expect(await File(staged.path).exists(), isTrue);
    await drafts.deleteDraft('draft-delete');

    expect(drafts.draftById('draft-delete'), isNull);
    expect(await File(staged.path).exists(), isFalse);
    expect(await original.exists(), isTrue);
  });

  test('clearing drafts removes retained staged proof copies', () async {
    final drafts = await ExpenseDraftController.create();
    final original = File('${Directory.systemTemp.path}/draft-clear.pdf');
    await original.writeAsString(
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF',
      flush: true,
    );
    addTearDown(() {
      if (original.existsSync()) original.deleteSync();
    });

    final staged = await ReceiptProofStorage.instance.stageAttachment(
      ReceiptAttachmentRecord(
        id: 'draft-clear-pdf',
        path: original.path,
        kind: ReceiptAttachmentKind.pdf,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 14),
      ),
    );

    await drafts.saveDraft(
      ExpenseReceiptDraftRecord(
        id: 'draft-clear',
        receiptDate: DateTime(2026, 6, 14),
        updatedAt: DateTime(2026, 6, 14, 12),
        attachments: [staged],
      ),
    );

    await drafts.clear();

    expect(drafts.drafts, isEmpty);
    expect(await File(staged.path).exists(), isFalse);
    expect(await original.exists(), isTrue);
  });
}
