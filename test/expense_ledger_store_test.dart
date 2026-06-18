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

  test(
    'saves receipts and derives calendar/day summaries from source records',
    () async {
      final ledger = await ExpenseLedgerController.create();
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-1',
          receiptDate: DateTime(2026, 6, 8),
          receiptTimeMinutes: (9 * 60) + 15,
          merchantName: 'Lowes',
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-1',
              description: 'Materials',
              category: 'Materials',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 100,
            ),
          ],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-2',
          receiptDate: DateTime(2026, 6, 8),
          merchantName: 'Coffee',
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-2',
              description: 'Coffee',
              category: 'Meals',
              use: ExpenseLineUse.personal,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 12,
            ),
          ],
        ),
      );

      final dayRecords = ledger.receiptsForDay(DateTime(2026, 6, 8));
      final day = ledger.summaryForDay(DateTime(2026, 6, 8));
      final week = ledger.summaryForWeek(DateTime(2026, 6, 11));

      expect(dayRecords.map((record) => record.id), ['EXP-1', 'EXP-2']);
      expect(day.total, 112);
      expect(day.business, 100);
      expect(day.personal, 12);
      expect(week.total, 112);
    },
  );

  test(
    'backdated line edits update later summaries without cached totals',
    () async {
      final ledger = await ExpenseLedgerController.create();
      const originalLine = ExpenseReceiptLineRecord(
        id: 'LINE-1',
        description: 'Fuel',
        category: 'Fuel',
        use: ExpenseLineUse.business,
        quantity: 10,
        unitsPerPackage: 1,
        unit: 'gallon',
        subtotal: 40,
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-edit',
          receiptDate: DateTime(2026, 6, 1),
          lines: const [originalLine],
        ),
      );

      expect(ledger.summaryForMonth(DateTime(2026, 6, 20)).total, 40);

      await ledger.replaceLine(
        receiptId: 'EXP-edit',
        line: const ExpenseReceiptLineRecord(
          id: 'LINE-1',
          description: 'Fuel',
          category: 'Fuel',
          use: ExpenseLineUse.business,
          quantity: 10,
          unitsPerPackage: 1,
          unit: 'gallon',
          subtotal: 55,
        ),
      );

      final month = ledger.summaryForMonth(DateTime(2026, 6, 20));
      final loaded = ledger.receiptById('EXP-edit')!;

      expect(month.total, 55);
      expect(month.business, 55);
      expect(loaded.auditEvents, isNotEmpty);
    },
  );

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
