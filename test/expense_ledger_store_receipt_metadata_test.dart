import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_ledger_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('saved receipts keep OCR review metadata', () async {
    final ocr = await const ReceiptOcrService(maxPhotoOcrAttachments: 0)
        .recognizeTextFromAttachments([
          ReceiptAttachmentRecord(
            id: 'photo-1',
            path: '/tmp/receipt.jpg',
            kind: ReceiptAttachmentKind.photo,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
            createdAt: DateTime(2026, 6, 11, 12),
          ),
        ]);
    final ledger = await ExpenseLedgerController.create();

    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-ocr',
        receiptDate: DateTime(2026, 6, 11),
        rawOcrText: ocr.rawText,
        ocrReview: ExpenseReceiptOcrReview.fromDiagnostics(
          diagnostics: ocr.diagnostics,
          warnings: ocr.structuredWarnings,
        ),
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'LINE-ocr',
            description: 'Manual receipt total',
            category: 'Uncategorized',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 12,
          ),
        ],
      ),
    );

    final loaded = ledger.receiptById('EXP-ocr')!;
    expect(loaded.ocrReview.hasData, isTrue);
    expect(loaded.ocrReview.needsReview, isTrue);
    expect(loaded.ocrReview.severity, ReceiptOcrReviewSeverity.blocked.name);
    expect(loaded.ocrReview.warningKinds, [
      ReceiptOcrWarningKind.sourceSkipped.name,
    ]);
    expect(
      loaded.ocrReview.countForWarningKind(
        ReceiptOcrWarningKind.sourceSkipped.name,
      ),
      1,
    );
    expect(loaded.ocrReview.primaryWarningLabel, 'Receipt assistance off');
    expect(
      loaded.ocrReview.primaryWarningKind,
      ReceiptOcrWarningKind.sourceSkipped.name,
    );
    expect(loaded.ocrReview.primaryWarningTargetLabel, 'Check saved proof');
    expect(loaded.ocrReview.recoveryAction, 'review_saved_proof');
    expect(loaded.ocrReview.recoveryTarget, 'receipt_photo');
    expect(
      loaded.ocrReview.recoverySummary,
      'Review the saved proof or turn receipt assistance back on.',
    );
    expect(loaded.ocrReview.commandCenterSummary['source'], 'photo');
    expect(
      loaded.ocrReview.commandCenterSummary['recoveryAction'],
      'review_saved_proof',
    );
    expect(
      loaded.ocrReview.commandCenterSummary['recoveryTarget'],
      'receipt_photo',
    );
    expect(
      loaded.ocrReview.commandCenterPrimaryAction,
      contains('saved proof'),
    );
    expect(ledger.receiptsNeedingOcrReview.map((receipt) => receipt.id), [
      'EXP-ocr',
    ]);
    expect(ledger.ocrRecoveryActionCounts, {'review_saved_proof': 1});
    expect(ledger.ocrRecoveryTargetCounts, {'receipt_photo': 1});
    expect(ledger.topOcrRecoveryAction, 'review_saved_proof');
    expect(ledger.topOcrRecoveryTarget, 'receipt_photo');
  });

  test('saved receipt OCR recovery aggregates stay privacy-safe', () async {
    final ledger = ExpenseLedgerController.memory();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-safe-recovery',
        receiptDate: DateTime(2026, 6, 11),
        ocrReview: const ExpenseReceiptOcrReview(
          severity: 'review',
          source: 'photo',
          primaryWarningKind: 'sectionGap',
          recoveryAction: 'add_missing_section',
          recoveryTarget: 'receipt_sections',
          recoverySummary: 'Add the missing receipt section.',
          warningCount: 1,
        ),
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'LINE-safe',
            description: 'Receipt total',
            category: 'Uncategorized',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 12,
          ),
        ],
      ),
    );
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-private-recovery',
        receiptDate: DateTime(2026, 6, 12),
        ocrReview: const ExpenseReceiptOcrReview(
          severity: 'review',
          source: 'photo',
          primaryWarningKind: 'photoQuality',
          recoveryAction: 'private_store_total_3_24',
          recoveryTarget: 'receipt_photo',
          recoverySummary: 'Lowes total 3.24 needs review.',
          warningCount: 1,
        ),
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'LINE-private',
            description: 'Receipt total',
            category: 'Uncategorized',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 3.24,
          ),
        ],
      ),
    );

    expect(ledger.receiptsNeedingOcrReview.length, 2);
    expect(ledger.ocrRecoveryActionCounts, {'add_missing_section': 1});
    expect(ledger.ocrRecoveryTargetCounts, {
      'receipt_sections': 1,
      'receipt_photo': 1,
    });
    expect(ledger.topOcrRecoveryAction, 'add_missing_section');
    expect(ledger.topOcrRecoveryTarget, 'receipt_photo');
    expect(
      ledger.ocrRecoveryActionCounts.containsKey('private_store_total_3_24'),
      isFalse,
    );
  });

  test(
    'detects duplicate receipts by proof hash and receipt fingerprint',
    () async {
      final ledger = await ExpenseLedgerController.create();
      const line = ExpenseReceiptLineRecord(
        id: 'LINE-1',
        description: 'Diesel',
        category: 'Fuel',
        use: ExpenseLineUse.business,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 42.25,
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-original',
          receiptDate: DateTime(2026, 6, 13),
          merchantName: 'Sheetz',
          attachments: [
            ReceiptAttachmentRecord(
              id: 'pdf-1',
              path: '/tmp/sheetz.pdf',
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.original,
              createdAt: DateTime(2026, 6, 13),
              fileHash: 'same-proof-hash',
            ),
          ],
          lines: const [line],
        ),
      );

      final hashDuplicate = ledger.duplicateCandidatesFor(
        ExpenseReceiptRecord(
          id: 'EXP-hash-copy',
          receiptDate: DateTime(2026, 6, 14),
          merchantName: 'Other Store',
          attachments: [
            ReceiptAttachmentRecord(
              id: 'pdf-2',
              path: '/tmp/copy.pdf',
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.original,
              createdAt: DateTime(2026, 6, 14),
              fileHash: 'same-proof-hash',
            ),
          ],
          lines: const [line],
        ),
      );
      final fingerprintDuplicate = ledger.duplicateCandidatesFor(
        ExpenseReceiptRecord(
          id: 'EXP-manual-copy',
          receiptDate: DateTime(2026, 6, 13),
          merchantName: '  SHEETZ ',
          lines: const [line],
        ),
      );

      expect(hashDuplicate.single.isExactProofMatch, isTrue);
      expect(hashDuplicate.single.reason, 'Same receipt proof file');
      expect(
        fingerprintDuplicate.single.confidence,
        ExpenseDuplicateConfidence.high,
      );
    },
  );

  test('saved receipts keep receipt attachment metadata', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-photo',
        receiptDate: DateTime(2026, 6, 11),
        rawOcrText: 'FUEL 20.00',
        attachments: [
          ReceiptAttachmentRecord(
            id: 'photo-1',
            path: '/tmp/receipt.jpg',
            kind: ReceiptAttachmentKind.photo,
            dataSaverLevel: ReceiptDataSaverLevel.strong,
            createdAt: DateTime(2026, 6, 11, 12),
            byteSize: 64000,
          ),
          ReceiptAttachmentRecord(
            id: 'pdf-1',
            path: '/tmp/receipt.pdf',
            kind: ReceiptAttachmentKind.pdf,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
            createdAt: DateTime(2026, 6, 11, 12),
            displayName: 'Counter receipt.pdf',
            byteSize: 250000,
          ),
          ReceiptAttachmentRecord(
            id: 'text-1',
            path: '',
            kind: ReceiptAttachmentKind.textMessageText,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
            createdAt: DateTime(2026, 6, 11, 12),
            displayName: 'Texted receipt',
            importedText: 'FUEL 20.00',
            byteSize: 10,
          ),
        ],
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'LINE-photo',
            description: 'Fuel',
            category: 'Fuel',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'gallon',
            subtotal: 20,
          ),
        ],
      ),
    );

    final loaded = ledger.receiptById('EXP-photo')!;
    expect(loaded.hasReceiptAttachment, isTrue);
    expect(
      loaded.attachments.first.dataSaverLevel,
      ReceiptDataSaverLevel.strong,
    );
    expect(loaded.attachments.first.byteSize, 64000);
    expect(loaded.attachments[1].kind, ReceiptAttachmentKind.pdf);
    expect(loaded.attachments[1].displayName, 'Counter receipt.pdf');
    expect(loaded.attachments[2].kind, ReceiptAttachmentKind.textMessageText);
    expect(loaded.attachments[2].importedText, 'FUEL 20.00');
    expect(loaded.rawOcrText, 'FUEL 20.00');
  });

  test('saved receipt lines keep parser confidence review metadata', () async {
    final ledger = await ExpenseLedgerController.create();
    await ledger.saveReceipt(
      ExpenseReceiptRecord(
        id: 'EXP-parser-review',
        receiptDate: DateTime(2026, 6, 12),
        rawOcrText: 'LOWES\nCOPPER ELBOW 8.99',
        lines: const [
          ExpenseReceiptLineRecord(
            id: 'LINE-parser-review',
            description: 'Copper elbow',
            category: 'Materials',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 8.99,
            parserConfidence: .72,
            parserReviewLabel: 'Review',
            parserReviewReason: 'Matched materials keyword with total.',
            parserNeedsReview: true,
          ),
        ],
      ),
    );

    final loaded = ledger.receiptById('EXP-parser-review')!.lines.single;

    expect(loaded.parserConfidence, .72);
    expect(loaded.parserReviewLabel, 'Review');
    expect(loaded.parserReviewReason, 'Matched materials keyword with total.');
    expect(loaded.parserNeedsReview, isTrue);
  });
}
