import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_duplicate_detection_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('detects the same PDF uploaded twice by SHA-256 hash', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(
      _receipt(
        id: 'EXP-original-pdf',
        merchant: 'Advance Auto Parts',
        attachmentKind: ReceiptAttachmentKind.pdf,
        fileHash: 'same-pdf-hash',
      ),
    );

    final result = ledger.checkDuplicatesFor(
      _receipt(
        id: 'EXP-copy-pdf',
        merchant: 'Different Merchant',
        attachmentKind: ReceiptAttachmentKind.pdf,
        fileHash: 'same-pdf-hash',
      ),
      checkedAt: DateTime(2026, 6, 13, 9),
    );

    expect(result.status, ExpenseDuplicateCheckStatus.candidatesFound);
    expect(result.fileHashSha256, 'same-pdf-hash');
    expect(
      result.candidates.single.confidence,
      ExpenseDuplicateConfidence.exactFileMatch,
    );
    expect(result.candidates.single.matchedFileHashSha256, 'same-pdf-hash');
  });

  test(
    'detects the same receipt image imported twice by SHA-256 hash',
    () async {
      final ledger = await ExpenseLedgerController.create();
      await ledger.saveReceipt(
        _receipt(
          id: 'EXP-original-image',
          attachmentKind: ReceiptAttachmentKind.photo,
          fileHash: 'same-image-hash',
        ),
      );

      final result = ledger.checkDuplicatesFor(
        _receipt(
          id: 'EXP-copy-image',
          attachmentKind: ReceiptAttachmentKind.photo,
          fileHash: 'same-image-hash',
        ),
      );

      expect(
        result.candidates.single.confidence,
        ExpenseDuplicateConfidence.exactFileMatch,
      );
    },
  );

  test('detects duplicate staged PDF before proof promotion', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(
      _receipt(
        id: 'EXP-saved-proof',
        attachmentKind: ReceiptAttachmentKind.pdf,
        fileHash: 'same-staged-proof-hash',
      ),
    );

    final stagedCandidate = ledger.checkDuplicatesFor(
      _receipt(
        id: 'EXP-staged-proof',
        attachmentKind: ReceiptAttachmentKind.pdf,
        fileHash: 'same-staged-proof-hash',
        storageState: ReceiptAttachmentStorageState.staged,
      ),
    );

    expect(
      stagedCandidate.candidates.single.confidence,
      ExpenseDuplicateConfidence.exactFileMatch,
    );
    expect(
      stagedCandidate.candidates.single.matchedFileHashSha256,
      'same-staged-proof-hash',
    );
    expect(stagedCandidate.fileHashSha256, 'same-staged-proof-hash');
  });

  test('editing a saved receipt does not flag itself as duplicate', () async {
    final ledger = await ExpenseLedgerController.create();
    final saved = await ledger.saveReceipt(
      _receipt(
        id: 'EXP-edit-existing',
        merchant: 'Advance Auto Parts',
        attachmentKind: ReceiptAttachmentKind.pdf,
        fileHash: 'same-existing-proof',
      ),
    );

    final result = ledger.checkDuplicatesFor(
      saved.copyWith(notes: 'Corrected note while editing.'),
      checkedAt: DateTime(2026, 6, 13, 11),
    );

    expect(result.status, ExpenseDuplicateCheckStatus.clear);
    expect(result.candidates, isEmpty);
    expect(result.fileHashSha256, 'same-existing-proof');
  });

  test('detects same receipt data even when the file hash differs', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(
      _receipt(
        id: 'EXP-original-data',
        merchant: 'Sheetz',
        receiptNumber: '12345',
        fileHash: 'first-hash',
      ),
    );

    final result = ledger.checkDuplicatesFor(
      _receipt(
        id: 'EXP-copy-data',
        merchant: '  SHEETZ ',
        receiptNumber: '12345',
        fileHash: 'second-hash',
      ),
    );

    expect(
      result.candidates.single.confidence,
      ExpenseDuplicateConfidence.veryHigh,
    );
    expect(
      result.candidates.single.reason,
      'Same store, date, total, and receipt number',
    );
  });

  test('detects same merchant date and amount as high confidence', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(_receipt(id: 'EXP-original-high'));

    final result = ledger.checkDuplicatesFor(
      _receipt(id: 'EXP-copy-high', fileHash: 'different-hash'),
    );

    expect(
      result.candidates.single.confidence,
      ExpenseDuplicateConfidence.high,
    );
  });

  test('detects similar amount and close date as possible duplicate', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(_receipt(id: 'EXP-original-possible'));

    final result = ledger.checkDuplicatesFor(
      _receipt(
        id: 'EXP-copy-possible',
        receiptDate: DateTime(2026, 6, 15),
        subtotal: 104.80,
        total: 104.80,
        fileHash: 'nearby-hash',
      ),
    );

    expect(
      result.candidates.single.confidence,
      ExpenseDuplicateConfidence.possible,
    );
  });

  test('stores duplicate audit fields when user saves anyway', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(_receipt(id: 'EXP-original-audit'));

    final current = _receipt(id: 'EXP-current-audit');
    final check = ledger.checkDuplicatesFor(
      current,
      checkedAt: DateTime(2026, 6, 13, 10),
    );
    final saved = await ledger.saveReceipt(
      current.copyWith(
        fileHashSha256: check.fileHashSha256,
        duplicateCheckStatus: ExpenseDuplicateCheckStatus.overrideSaved,
        duplicateCandidates: check.candidates,
        duplicateOverride: true,
        duplicateOverrideReason: 'Second legitimate receipt.',
        duplicateCheckedAt: check.checkedAt,
      ),
    );

    expect(saved.duplicateOverride, isTrue);
    expect(saved.duplicateOverrideReason, 'Second legitimate receipt.');
    expect(
      saved.duplicateCheckStatus,
      ExpenseDuplicateCheckStatus.overrideSaved,
    );
    expect(saved.duplicateCandidates, isNotEmpty);
  });

  test(
    'finds duplicate attachment candidates in the saved expense ledger',
    () async {
      final ledger = await ExpenseLedgerController.create();
      await ledger.saveReceipt(
        _receipt(id: 'EXP-existing-attachment', fileHash: 'proof-hash'),
      );

      final candidates = ledger.duplicateAttachmentCandidatesFor(
        fileHashSha256: 'proof-hash',
      );

      expect(candidates, hasLength(1));
      expect(candidates.single.receiptId, 'EXP-existing-attachment');
      expect(candidates.single.fileHashSha256, 'proof-hash');
      expect(candidates.single.reason, contains('expense receipt'));
    },
  );

  test('finds duplicate attachment candidates in the current receipt form', () {
    final ledger = ExpenseLedgerController.memory();

    final candidates = ledger.duplicateAttachmentCandidatesFor(
      fileHashSha256: 'current-form-hash',
      scope: ExpenseDuplicateAttachmentScope.currentForm,
      currentFormAttachments: [
        ReceiptAttachmentRecord(
          id: 'current-proof',
          path: '/tmp/current-proof.pdf',
          kind: ReceiptAttachmentKind.pdf,
          dataSaverLevel: ReceiptDataSaverLevel.original,
          createdAt: DateTime(2026, 6, 13),
          fileHash: 'current-form-hash',
        ),
      ],
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.attachmentId, 'current-proof');
    expect(candidates.single.reason, contains('receipt form'));
  });

  test(
    'all modules future scope safely includes current form and expenses',
    () async {
      final ledger = await ExpenseLedgerController.create();
      await ledger.saveReceipt(
        _receipt(id: 'EXP-future-scope', fileHash: 'shared-proof-hash'),
      );

      final candidates = ledger.duplicateAttachmentCandidatesFor(
        fileHashSha256: 'shared-proof-hash',
        scope: ExpenseDuplicateAttachmentScope.allModulesFuture,
        currentFormAttachments: [
          ReceiptAttachmentRecord(
            id: 'current-proof',
            path: '/tmp/current-proof.pdf',
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.original,
            createdAt: DateTime(2026, 6, 13),
            fileHash: 'shared-proof-hash',
          ),
        ],
      );

      expect(
        candidates.map((candidate) => candidate.attachmentId),
        contains('current-proof'),
      );
      expect(
        candidates.map((candidate) => candidate.receiptId),
        contains('EXP-future-scope'),
      );
    },
  );

  test('serializes cancel edit and view duplicate save choices', () {
    const cancel = ExpenseDuplicateSaveChoice(
      action: ExpenseDuplicateSaveAction.cancel,
    );
    const editCurrent = ExpenseDuplicateSaveChoice(
      action: ExpenseDuplicateSaveAction.editCurrent,
    );
    const viewExisting = ExpenseDuplicateSaveChoice(
      action: ExpenseDuplicateSaveAction.viewExisting,
    );
    const saveAnyway = ExpenseDuplicateSaveChoice(
      action: ExpenseDuplicateSaveAction.saveAnyway,
      overrideReason: 'Legit repeat purchase',
    );

    expect(cancel.shouldKeepEditingCurrent, isTrue);
    expect(editCurrent.shouldKeepEditingCurrent, isTrue);
    expect(viewExisting.shouldViewExistingFirst, isTrue);
    expect(viewExisting.shouldKeepEditingCurrent, isFalse);
    expect(saveAnyway.shouldSaveAnyway, isTrue);
    expect(saveAnyway.overrideReason, 'Legit repeat purchase');
  });
}

ExpenseReceiptRecord _receipt({
  required String id,
  String merchant = 'Advance Auto Parts',
  DateTime? receiptDate,
  double subtotal = 100,
  double tax = 5.30,
  double total = 105.30,
  String category = 'Repair',
  String vehicleId = 'truck-1',
  String receiptNumber = '',
  String paymentMethod = 'Visa',
  ReceiptAttachmentKind attachmentKind = ReceiptAttachmentKind.pdf,
  String fileHash = 'receipt-hash',
  ReceiptAttachmentStorageState storageState =
      ReceiptAttachmentStorageState.permanent,
}) {
  return ExpenseReceiptRecord(
    id: id,
    receiptDate: receiptDate ?? DateTime(2026, 6, 13),
    merchantName: merchant,
    receiptNumber: receiptNumber,
    paymentMethod: paymentMethod,
    enteredSubtotal: subtotal,
    enteredTax: tax,
    enteredTotal: total,
    vehicleId: vehicleId,
    attachments: [
      ReceiptAttachmentRecord(
        id: '$id-proof',
        path: '/tmp/$id',
        kind: attachmentKind,
        dataSaverLevel: ReceiptDataSaverLevel.original,
        createdAt: DateTime(2026, 6, 13),
        fileHash: fileHash,
        storageState: storageState,
      ),
    ],
    lines: [
      ExpenseReceiptLineRecord(
        id: '$id-line',
        description: 'Brake caliper',
        category: category,
        use: ExpenseLineUse.business,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: subtotal,
      ),
    ],
  );
}
