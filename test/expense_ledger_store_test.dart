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
    'loads around malformed local receipt values without crashing',
    () async {
      final box = await Hive.openBox<dynamic>(ExpenseLedgerController.boxName);
      await box.put('bad-type', 'not a receipt map');
      await box.put('malformed-map', {
        'id': 42,
        'receiptDate': 20260608,
        'receiptTimeMinutes': '615',
        'merchantName': 12345,
        'hasReceiptProof': 'true',
        'enteredTotal': '18.75',
        'lines': [
          {
            'id': 1,
            'description': 99,
            'category': true,
            'use': 'personal',
            'quantity': '2',
            'unitsPerPackage': '1',
            'subtotal': '9.25',
            'parserNeedsReview': 'yes',
          },
        ],
      });

      final ledger = await ExpenseLedgerController.create();
      final receipts = ledger.storedReceipts;

      expect(receipts, hasLength(1));
      expect(receipts.single.id, '42');
      expect(receipts.single.receiptTimeMinutes, 615);
      expect(receipts.single.hasReceiptProof, isTrue);
      expect(receipts.single.enteredTotal, 18.75);
      expect(receipts.single.lines.single.description, '99');
      expect(receipts.single.lines.single.parserNeedsReview, isTrue);
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
    'calendar day uses receipt date and entered time before entry order',
    () async {
      final ledger = await ExpenseLedgerController.create();
      const line = ExpenseReceiptLineRecord(
        id: 'LINE',
        description: 'Expense',
        category: 'Fuel',
        use: ExpenseLineUse.business,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 10,
      );

      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-friday-entry-tuesday-9am',
          receiptDate: DateTime(2026, 6, 9),
          receiptTimeMinutes: 9 * 60,
          merchantName: 'Tuesday 9 AM',
          createdAt: DateTime(2026, 6, 12, 18),
          lines: const [line],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-friday-entry-tuesday-8am',
          receiptDate: DateTime(2026, 6, 9),
          receiptTimeMinutes: 8 * 60,
          merchantName: 'Tuesday 8 AM',
          createdAt: DateTime(2026, 6, 12, 19),
          lines: const [line],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-friday-entry-tuesday-no-time-first',
          receiptDate: DateTime(2026, 6, 9),
          merchantName: 'No Time First',
          createdAt: DateTime(2026, 6, 12, 20),
          lines: const [line],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-friday-entry-tuesday-no-time-second',
          receiptDate: DateTime(2026, 6, 9),
          merchantName: 'No Time Second',
          createdAt: DateTime(2026, 6, 12, 21),
          lines: const [line],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-actual-friday',
          receiptDate: DateTime(2026, 6, 12),
          receiptTimeMinutes: 7 * 60,
          merchantName: 'Friday',
          createdAt: DateTime(2026, 6, 12, 7),
          lines: const [line],
        ),
      );

      final tuesday = ledger.receiptsForDay(DateTime(2026, 6, 9));
      final friday = ledger.receiptsForDay(DateTime(2026, 6, 12));

      expect(tuesday.map((receipt) => receipt.id), [
        'EXP-friday-entry-tuesday-8am',
        'EXP-friday-entry-tuesday-9am',
        'EXP-friday-entry-tuesday-no-time-first',
        'EXP-friday-entry-tuesday-no-time-second',
      ]);
      expect(friday.map((receipt) => receipt.id), ['EXP-actual-friday']);
    },
  );

  test(
    'backdated receipt edits update day week month and year recaps',
    () async {
      final ledger = await ExpenseLedgerController.create();
      const originalLine = ExpenseReceiptLineRecord(
        id: 'LINE-backdated',
        description: 'Backdated expense',
        category: 'Materials',
        use: ExpenseLineUse.business,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 80,
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-backdated',
          receiptDate: DateTime(2026, 5, 12),
          receiptTimeMinutes: 10 * 60,
          createdAt: DateTime(2026, 6, 12, 18),
          lines: const [originalLine],
        ),
      );

      ExpenseLedgerSummary yearToDate() => ledger.summaryForRange(
        ExpenseDateRange(start: DateTime(2026), end: DateTime(2026, 6, 24)),
      );

      expect(ledger.summaryForDay(DateTime(2026, 5, 12)).total, 80);
      expect(ledger.summaryForWeek(DateTime(2026, 5, 12)).total, 80);
      expect(ledger.summaryForMonth(DateTime(2026, 5, 20)).total, 80);
      expect(yearToDate().total, 80);

      await ledger.replaceLine(
        receiptId: 'EXP-backdated',
        line: const ExpenseReceiptLineRecord(
          id: 'LINE-backdated',
          description: 'Backdated expense',
          category: 'Materials',
          use: ExpenseLineUse.business,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'each',
          subtotal: 125,
        ),
      );

      expect(ledger.summaryForDay(DateTime(2026, 5, 12)).total, 125);
      expect(ledger.summaryForWeek(DateTime(2026, 5, 12)).total, 125);
      expect(ledger.summaryForMonth(DateTime(2026, 5, 20)).total, 125);
      expect(yearToDate().total, 125);
    },
  );

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
    expect(loaded.ocrReview.primaryWarningLabel, 'Receipt reading off');
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
