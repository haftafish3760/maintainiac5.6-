import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'expense_export_test_',
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
    'expense export uses stored receipts and includes tax-adjusted totals',
    () async {
      final ledger = await ExpenseLedgerController.create();
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-export',
          receiptDate: DateTime(2026, 6, 11),
          merchantName: 'Parts Store',
          enteredSubtotal: 100,
          enteredTax: 7,
          enteredTotal: 107,
          vehicleId: 'truck-1',
          odometerReading: 151000,
          hasReceiptProof: true,
          attachments: [
            ReceiptAttachmentRecord(
              id: 'proof-photo',
              path: '/tmp/receipt-proof.jpg',
              kind: ReceiptAttachmentKind.photo,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime.utc(2026, 6, 11, 14),
              byteSize: 248000,
            ),
            ReceiptAttachmentRecord(
              id: 'proof-pdf',
              path: '/tmp/receipt-proof.pdf',
              kind: ReceiptAttachmentKind.pdf,
              dataSaverLevel: ReceiptDataSaverLevel.balanced,
              createdAt: DateTime.utc(2026, 6, 11, 14, 1),
              byteSize: 520000,
            ),
          ],
          ocrReview: const ExpenseReceiptOcrReview(
            severity: 'review',
            source: 'photo',
            primaryWarningKind: 'sectionGap',
            primaryWarningLabelOverride: 'Possible missing receipt section',
            primaryWarningTargetLabel: 'Check missing receipt section',
            primaryWarningTargetInstruction:
                'Check the receipt photos from top to bottom and add the missing middle section if needed.',
            recoveryAction: 'add_missing_section',
            recoveryTarget: 'receipt_sections',
            recoverySummary:
                'Add the missing receipt section or confirm the photos are in order.',
            warningCount: 1,
            reviewWarningCount: 1,
            parserLineCount: 2,
            pdfPagesRequested: 1,
          ),
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-business',
              description: 'Materials',
              category: 'Materials',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 80,
            ),
            ExpenseReceiptLineRecord(
              id: 'LINE-personal',
              description: 'Personal item',
              category: 'Supplies',
              use: ExpenseLineUse.personal,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 20,
            ),
          ],
        ),
      );
      await ledger.saveReceipt(
        ExpenseReceiptRecord(
          id: 'EXP-export-clean-read',
          receiptDate: DateTime(2026, 6, 12),
          merchantName: 'Parts Store',
          enteredSubtotal: 10,
          enteredTax: 0.8,
          enteredTotal: 10.8,
          ocrReview: const ExpenseReceiptOcrReview(
            severity: 'good',
            source: 'photo',
            attachmentsRead: 1,
            rawLineCount: 7,
            parserLineCount: 2,
            usedLocalOcr: true,
          ),
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-clean-read',
              description: 'Shop towels',
              category: 'Supplies',
              use: ExpenseLineUse.business,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 10,
            ),
          ],
        ),
      );

      final snapshot = buildExpenseExportSnapshot(
        receipts: ledger.storedReceipts,
        range: ExpenseDateRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
        categoryFilter: ExpenseExportCategoryFilter.all,
        destination: ExpenseExportDestination.email,
        exportedAt: DateTime.utc(2026, 6, 12, 12),
      );

      expect(snapshot.receiptCount, 2);
      expect(snapshot.lineCount, 3);
      expect(snapshot.total, 117.8);
      expect(snapshot.toReceiptsCsv(), contains('sales_tax'));
      expect(snapshot.toReceiptsCsv(), contains('receipt_proof_count'));
      expect(snapshot.toReceiptsCsv(), contains('saved_proof_bytes'));
      expect(snapshot.toReceiptsCsv(), contains('ocr_review_status'));
      expect(snapshot.toReceiptsCsv(), contains('ocr_warning_count'));
      expect(snapshot.toReceiptsCsv(), contains('ocr_primary_warning_kind'));
      expect(snapshot.toReceiptsCsv(), contains('ocr_recovery_action'));
      expect(snapshot.toReceiptsCsv(), contains('ocr_recovery_target'));
      expect(snapshot.toReceiptsCsv(), contains('ocr_primary_issue'));
      expect(snapshot.toReceiptsCsv(), contains('ocr_primary_action'));
      expect(snapshot.toReceiptsCsv(), contains('photo|pdf'));
      expect(snapshot.toReceiptsCsv(), contains('768000'));
      expect(snapshot.toReceiptsCsv(), contains('review'));
      expect(snapshot.toReceiptsCsv(), contains('sectionGap'));
      expect(snapshot.toReceiptsCsv(), contains('add_missing_section'));
      expect(snapshot.toReceiptsCsv(), contains('receipt_sections'));
      expect(
        snapshot.toReceiptsCsv(),
        contains('Check missing receipt section'),
      );
      expect(
        snapshot.toReceiptsCsv(),
        contains('receipt photos from top to bottom'),
      );
      expect(snapshot.toReceiptsCsv(), contains('odometer_reading'));
      expect(snapshot.toReceiptsCsv(), contains('151000'));
      expect(snapshot.toReceiptsCsv(), contains('107.00'));
      expect(snapshot.toLineItemsCsv(), contains('85.60'));
      expect(snapshot.toLineItemsCsv(), contains('21.40'));
      expect(snapshot.toManifest()['source'], 'localDevice');
      expect(snapshot.toManifest()['destination'], 'email');
      expect(snapshot.toManifest()['receiptProofCount'], 2);
      expect(snapshot.toManifest()['receiptProofBytes'], 768000);
      expect(snapshot.toManifest()['receiptsMissingProof'], 1);
      expect(snapshot.toManifest()['receiptsWithOcrReview'], 2);
      expect(snapshot.toManifest()['receiptsNeedingOcrReview'], 1);
      expect(snapshot.toManifest()['ocrReadStatus'], '1 need review');
      expect(snapshot.toManifest()['ocrReadsSaved'], 2);
      expect(snapshot.toManifest()['ocrCleanReadCount'], 1);
      expect(
        snapshot.toManifest()['ocrTopCheck'],
        'Check missing receipt section',
      );
      expect(
        snapshot.toManifest()['ocrReadSummary'],
        '2 reads saved | 1 need review | 1 saved clean | Top check: Check missing receipt section',
      );
      expect(snapshot.toManifest()['ocrWarningCount'], 1);
      expect(snapshot.toManifest()['ocrReviewWarningCount'], 1);
      expect(snapshot.toManifest()['ocrSourceCounts'], {'photo': 2});
      expect(snapshot.toManifest()['ocrTopSource'], 'photo');
      expect(snapshot.toManifest()['ocrPrimaryWarningKindCounts'], {
        'sectionGap': 1,
      });
      expect(snapshot.toManifest()['ocrRecoveryActionCounts'], {
        'add_missing_section': 1,
      });
      expect(snapshot.toManifest()['ocrRecoveryTargetCounts'], {
        'receipt_sections': 1,
      });
      expect(
        snapshot.toManifest()['ocrTopRecoveryAction'],
        'add_missing_section',
      );
      expect(snapshot.toManifest()['ocrTopRecoveryTarget'], 'receipt_sections');
      expect(
        snapshot.toManifest()['ocrTopPrimaryIssue'],
        'Check missing receipt section',
      );
      expect(
        snapshot.toManifest()['ocrTopPrimaryAction'],
        contains('receipt photos from top to bottom'),
      );
      final commandCenterContract =
          snapshot.toManifest()['commandCenterOcrContract']
              as Map<String, Object?>;
      expect(
        commandCenterContract['schema'],
        ExpenseExportSnapshot.commandCenterOcrContractSchema,
      );
      expect(
        commandCenterContract['privacyScope'],
        ExpenseExportSnapshot.commandCenterOcrPrivacyScope,
      );
      expect(
        commandCenterContract['contentPolicy'],
        ExpenseExportSnapshot.commandCenterOcrContentPolicy,
      );
      expect(commandCenterContract['receiptCount'], 2);
      expect(commandCenterContract['receiptsWithOcrReview'], 2);
      expect(commandCenterContract['receiptsNeedingOcrReview'], 1);
      expect(commandCenterContract['ocrReadsSaved'], 2);
      expect(commandCenterContract['ocrCleanReadCount'], 1);
      expect(commandCenterContract['ocrReadStatus'], '1 need review');
      expect(
        commandCenterContract['ocrReadSummary'],
        '2 reads saved | 1 need review | 1 saved clean | Top check: Check missing receipt section',
      );
      expect(commandCenterContract['ocrWarningCount'], 1);
      expect(commandCenterContract['ocrReviewWarningCount'], 1);
      expect(commandCenterContract['ocrSourceCounts'], {'photo': 2});
      expect(commandCenterContract['ocrPrimaryWarningKindCounts'], {
        'sectionGap': 1,
      });
      expect(commandCenterContract['ocrRecoveryActionCounts'], {
        'add_missing_section': 1,
      });
      expect(commandCenterContract['ocrRecoveryTargetCounts'], {
        'receipt_sections': 1,
      });
      expect(
        commandCenterContract['ocrTopPrimaryIssue'],
        'Check missing receipt section',
      );
      expect(
        commandCenterContract['ocrTopPrimaryAction'],
        contains('receipt photos from top to bottom'),
      );
      expect(
        commandCenterContract.keys.toSet(),
        ExpenseExportSnapshot.commandCenterOcrAllowedKeys,
      );
      expect(snapshot.commandCenterOcrContractPrivacyFindings, isEmpty);
      expect('$commandCenterContract', isNot(contains('private_store')));
      expect('$commandCenterContract', isNot(contains('Shop towels')));
      expect(
        '$commandCenterContract',
        isNot(contains('retake_photo_or_add_section')),
      );
      expect(snapshot.toManifest()['privacyNote'], contains('Raw OCR text'));
      expect('${snapshot.toManifest()}', isNot(contains('private_store')));
      expect('${snapshot.toManifest()}', isNot(contains('Shop towels')));
      expect(
        '${snapshot.toManifest()}',
        isNot(contains('retake_photo_or_add_section')),
      );
    },
  );

  test('business and personal exports exclude lines awaiting classification', () {
    final receipt = ExpenseReceiptRecord(
      id: 'EXP-review-export',
      receiptDate: DateTime(2026, 7, 15),
      lines: const [
        ExpenseReceiptLineRecord(
          id: 'LINE-review', description: 'Original receipt text',
          category: 'Tools', use: ExpenseLineUse.unclassified,
          quantity: 1, unitsPerPackage: 1, unit: 'each', subtotal: 18,
        ),
      ],
    );
    final range = ExpenseDateRange(
      start: DateTime(2026, 7, 1), end: DateTime(2026, 7, 31),
    );
    expect(
      buildExpenseExportSnapshot(
        receipts: [receipt], range: range,
        categoryFilter: ExpenseExportCategoryFilter.business,
      ).lineCount,
      0,
    );
    expect(
      buildExpenseExportSnapshot(
        receipts: [receipt], range: range,
        categoryFilter: ExpenseExportCategoryFilter.personal,
      ).lineCount,
      0,
    );
  });

  test('command center OCR contract privacy audit catches unsafe drift', () {
    final safeContract = ExpenseExportSnapshot(
      exportedAt: DateTime.utc(2026, 6, 12, 12),
      range: ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
      receipts: const [],
    ).commandCenterOcrContract;

    expect(
      ExpenseExportSnapshot.commandCenterOcrContractFindingsFor(safeContract),
      isEmpty,
    );

    final unsafeContract = Map<String, Object?>.from(safeContract)
      ..['merchantName'] = 'Private Store'
      ..['ocrTopPrimaryIssue'] = 'Lowes total 3.24 needs review'
      ..['ocrRecoveryActionCounts'] = {
        'add_missing_section': 1,
        'private_store_total_3_24': 1,
      }
      ..['ocrSourceCounts'] = {'photo': 1, '/tmp/receipt-proof.jpg': 1};

    final findings = ExpenseExportSnapshot.commandCenterOcrContractFindingsFor(
      unsafeContract,
    );

    expect(findings, contains('unexpected_key:merchantName'));
    expect(findings, contains('private_text:merchantName'));
    expect(findings, contains('private_text:ocrTopPrimaryIssue'));
    expect(
      findings,
      contains(
        'private_map_key:ocrRecoveryActionCounts.private_store_total_3_24',
      ),
    );
    expect(
      findings,
      contains('private_map_key:ocrSourceCounts./tmp/receipt-proof.jpg'),
    );
  });

  test('expense export includes explicit split percentages', () {
    final snapshot = buildExpenseExportSnapshot(
      receipts: [
        ExpenseReceiptRecord(
          id: 'EXP-split-export',
          receiptDate: DateTime(2026, 6, 12),
          merchantName: 'Phone Carrier',
          enteredSubtotal: 100,
          enteredTax: 8,
          enteredTotal: 108,
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-split',
              description: 'Shared phone bill',
              category: 'Cell Phone',
              use: ExpenseLineUse.split,
              businessPercent: .8,
              quantity: 1,
              unitsPerPackage: 1,
              unit: 'each',
              subtotal: 100,
            ),
          ],
        ),
      ],
      range: ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
      exportedAt: DateTime.utc(2026, 6, 12, 12),
    );

    final linesCsv = snapshot.toLineItemsCsv();

    expect(linesCsv, contains('business_percent'));
    expect(linesCsv, contains('personal_percent'));
    expect(linesCsv, contains('0.8000'));
    expect(linesCsv, contains('0.2000'));
    expect(linesCsv, contains('86.40'));
    expect(linesCsv, contains('21.60'));
  });

  test('empty stored ledger exports no dummy receipt data', () async {
    final ledger = await ExpenseLedgerController.create();
    final snapshot = buildExpenseExportSnapshot(
      receipts: ledger.storedReceipts,
      range: ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
      destination: ExpenseExportDestination.print,
      exportedAt: DateTime.utc(2026, 6, 12, 12),
    );

    expect(ledger.receipts, isEmpty);
    expect(ledger.storedReceipts, isEmpty);
    expect(snapshot.receiptCount, 0);
    expect(snapshot.lineCount, 0);
  });
}
