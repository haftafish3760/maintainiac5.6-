import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_file_writer.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_handoff.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_store.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_service.dart';
import 'package:maintaniac/shared/pdf/app_pdf_privacy_policy.dart';
import 'package:maintaniac/shared/pdf/app_pdf_text_decoder.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      expect(snapshot.toReceiptsCsv(), contains('receipt_export_ref'));
      expect(snapshot.toReceiptsCsv(), isNot(contains('receipt_id')));
      expect(snapshot.toReceiptsCsv(), contains('receipt_0001'));
      expect(snapshot.toReceiptsCsv(), contains('receipt_0002'));
      expect(snapshot.toReceiptsCsv(), isNot(contains('EXP-export')));
      expect(
        snapshot.toReceiptsCsv(),
        isNot(contains('EXP-export-clean-read')),
      );
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
      expect(snapshot.toLineItemsCsv(), contains('line_export_ref'));
      expect(snapshot.toLineItemsCsv(), isNot(contains('line_id')));
      expect(snapshot.toLineItemsCsv(), contains('receipt_0001_line_0001'));
      expect(snapshot.toLineItemsCsv(), contains('receipt_0001_line_0002'));
      expect(snapshot.toLineItemsCsv(), isNot(contains('LINE-business')));
      expect(snapshot.toLineItemsCsv(), isNot(contains('LINE-personal')));
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

  test('expense export allocates receipt pennies deterministically', () async {
    final receipt = ExpenseReceiptRecord(
      id: 'EXP-penny-allocation',
      receiptDate: DateTime(2026, 6, 12),
      merchantName: 'Tiny Tax Store',
      enteredSubtotal: .03,
      enteredTax: .01,
      enteredTotal: .04,
      lines: const [
        ExpenseReceiptLineRecord(
          id: 'LINE-penny-1',
          description: 'Washer 1',
          category: 'Materials',
          use: ExpenseLineUse.business,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'ea',
          subtotal: .01,
        ),
        ExpenseReceiptLineRecord(
          id: 'LINE-penny-2',
          description: 'Washer 2',
          category: 'Materials',
          use: ExpenseLineUse.business,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'ea',
          subtotal: .01,
        ),
        ExpenseReceiptLineRecord(
          id: 'LINE-penny-3',
          description: 'Washer 3',
          category: 'Materials',
          use: ExpenseLineUse.business,
          quantity: 1,
          unitsPerPackage: 1,
          unit: 'ea',
          subtotal: .01,
        ),
      ],
    );
    final snapshot = buildExpenseExportSnapshot(
      receipts: [receipt],
      range: ExpenseDateRange(
        start: DateTime(2026, 6, 1),
        end: DateTime(2026, 6, 30),
      ),
      categoryFilter: ExpenseExportCategoryFilter.all,
      exportedAt: DateTime.utc(2026, 6, 12, 12),
    );

    expect(snapshot.total, .04);
    expect(
      [
        for (final line in snapshot.filteredLinesFor(receipt))
          snapshot.taxAdjustedTotalForLine(receipt, line),
      ],
      [.02, .01, .01],
    );
    expect(snapshot.toLineItemsCsv(), contains('0.02'));
    expect(snapshot.toLineItemsCsv(), contains('0.01'));
    expect(
      AppPdfTextDecoder.textWithDecodedPdfStreams(
        (await buildExpenseExportSummaryPdf(snapshot)).bytes,
      ),
      contains(r'$0.04'),
    );
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

  test(
    'local exports are unlimited and cloud exports count monthly usage',
    () async {
      final store = await ExpenseExportController.create();
      final localSnapshot = buildExpenseExportSnapshot(
        receipts: const [],
        range: ExpenseDateRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
        categoryFilter: ExpenseExportCategoryFilter.all,
        exportedAt: DateTime.utc(2026, 6, 12, 12),
      );
      final cloudSnapshot = buildExpenseExportSnapshot(
        receipts: const [],
        range: ExpenseDateRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
        categoryFilter: ExpenseExportCategoryFilter.all,
        source: ExpenseExportSource.cloudBackup,
        destination: ExpenseExportDestination.print,
        exportedAt: DateTime.utc(2026, 6, 13, 12),
      );

      expect(store.canRunExport(localSnapshot, DateTime(2026, 6, 1)), isTrue);
      expect(store.hasFreeCloudExportAvailable(DateTime(2026, 6, 1)), isTrue);

      final localRecord = await store.markExported(localSnapshot);

      expect(store.lastExport!.id, localRecord.id);
      expect(store.lastExport!.destination, ExpenseExportDestination.share);
      expect(store.lastExport!.source, ExpenseExportSource.localDevice);
      expect(store.exportsUsedInMonth(DateTime(2026, 6, 20)), 1);
      expect(store.cloudExportsUsedInMonth(DateTime(2026, 6, 20)), 0);
      expect(store.canRunExport(localSnapshot, DateTime(2026, 6, 20)), isTrue);
      expect(store.hasFreeCloudExportAvailable(DateTime(2026, 6, 20)), isTrue);

      await store.markExported(cloudSnapshot);

      expect(store.lastExport!.source, ExpenseExportSource.cloudBackup);
      expect(store.cloudExportsUsedInMonth(DateTime(2026, 6, 20)), 1);
      expect(store.canRunExport(localSnapshot, DateTime(2026, 6, 20)), isTrue);
      expect(store.canRunExport(cloudSnapshot, DateTime(2026, 6, 20)), isFalse);
      expect(store.hasFreeCloudExportAvailable(DateTime(2026, 7, 1)), isTrue);
    },
  );

  test('expense export writer creates csv and manifest files', () async {
    final outputDirectory = await Directory.systemTemp.createTemp(
      'maintaniac_export_writer_test_',
    );
    final snapshot = buildExpenseExportSnapshot(
      receipts: [
        ExpenseReceiptRecord(
          id: 'EXP-file',
          receiptDate: DateTime(2026, 6, 11),
          merchantName: 'Fuel Stop',
          enteredSubtotal: 40,
          enteredTax: 2.8,
          enteredTotal: 42.8,
          lines: const [
            ExpenseReceiptLineRecord(
              id: 'LINE-file',
              description: 'Diesel',
              category: 'Fuel',
              use: ExpenseLineUse.business,
              quantity: 10,
              unitsPerPackage: 1,
              unit: 'gallon',
              subtotal: 40,
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

    final files = await ExpenseExportFileWriter(
      baseDirectory: outputDirectory,
    ).writeExpenseExport(snapshot);

    expect(files.files.length, 3);
    expect(
      await File('${files.directoryPath}/expense_receipts.csv').exists(),
      isTrue,
    );
    expect(
      await File('${files.directoryPath}/expense_line_items.csv').exists(),
      isTrue,
    );
    expect(
      await File(
        '${files.directoryPath}/expense_export_manifest.json',
      ).exists(),
      isTrue,
    );
    expect(
      await File('${files.directoryPath}/expense_receipts.csv').readAsString(),
      contains('Fuel Stop'),
    );

    await outputDirectory.delete(recursive: true);
  });

  test(
    'expense export writer uses safe unique directories without partial files',
    () async {
      final outputDirectory = await Directory.systemTemp.createTemp(
        'maintainiac_export_writer_unique_test_',
      );
      final exportedAt = DateTime.utc(2026, 6, 12, 12);
      final existingDirectory = Directory(
        '${outputDirectory.path}/maintainiac_expense_export_2026_06_12T12_00_00_000Z',
      );
      await existingDirectory.create(recursive: true);
      await File(
        '${existingDirectory.path}/expense_receipts.csv',
      ).writeAsString('old export must not be overwritten');

      final snapshot = buildExpenseExportSnapshot(
        receipts: [
          ExpenseReceiptRecord(
            id: 'EXP-file-unique',
            receiptDate: DateTime(2026, 6, 11),
            merchantName: 'Fuel Stop',
            enteredSubtotal: 40,
            enteredTax: 2.8,
            enteredTotal: 42.8,
            lines: const [
              ExpenseReceiptLineRecord(
                id: 'LINE-file-unique',
                description: 'Diesel',
                category: 'Fuel',
                use: ExpenseLineUse.business,
                quantity: 10,
                unitsPerPackage: 1,
                unit: 'gallon',
                subtotal: 40,
              ),
            ],
          ),
        ],
        range: ExpenseDateRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
        categoryFilter: ExpenseExportCategoryFilter.all,
        exportedAt: exportedAt,
      );

      final files = await ExpenseExportFileWriter(
        baseDirectory: outputDirectory,
      ).writeExpenseExport(snapshot);

      expect(
        files.directoryPath,
        endsWith('maintainiac_expense_export_2026_06_12T12_00_00_000Z_1'),
      );
      expect(
        await File(
          '${existingDirectory.path}/expense_receipts.csv',
        ).readAsString(),
        'old export must not be overwritten',
      );
      expect(
        Directory(files.directoryPath)
            .listSync()
            .whereType<File>()
            .map((file) => file.path)
            .where((path) => path.endsWith('.partial')),
        isEmpty,
      );
      expect(
        await File(
          '${files.directoryPath}/expense_export_manifest.json',
        ).readAsString(),
        contains('"destination": "share"'),
      );

      await outputDirectory.delete(recursive: true);
    },
  );

  test(
    'expense export writer skips symlinked export directory names',
    () async {
      final outputDirectory = await Directory.systemTemp.createTemp(
        'maintainiac_export_writer_symlink_test_',
      );
      final outsideDirectory = await Directory.systemTemp.createTemp(
        'maintainiac_export_writer_outside_target_',
      );
      final exportedAt = DateTime.utc(2026, 6, 12, 12);
      final linkedDirectory = Link(
        '${outputDirectory.path}/maintainiac_expense_export_2026_06_12T12_00_00_000Z',
      );
      await linkedDirectory.create(outsideDirectory.path);

      final snapshot = buildExpenseExportSnapshot(
        receipts: [
          ExpenseReceiptRecord(
            id: 'EXP-file-symlink',
            receiptDate: DateTime(2026, 6, 11),
            merchantName: 'Fuel Stop',
            enteredSubtotal: 40,
            enteredTax: 2.8,
            enteredTotal: 42.8,
            lines: const [
              ExpenseReceiptLineRecord(
                id: 'LINE-file-symlink',
                description: 'Diesel',
                category: 'Fuel',
                use: ExpenseLineUse.business,
                quantity: 10,
                unitsPerPackage: 1,
                unit: 'gallon',
                subtotal: 40,
              ),
            ],
          ),
        ],
        range: ExpenseDateRange(
          start: DateTime(2026, 6, 1),
          end: DateTime(2026, 6, 30),
        ),
        categoryFilter: ExpenseExportCategoryFilter.all,
        exportedAt: exportedAt,
      );

      final files = await ExpenseExportFileWriter(
        baseDirectory: outputDirectory,
      ).writeExpenseExport(snapshot);

      expect(
        files.directoryPath,
        endsWith('maintainiac_expense_export_2026_06_12T12_00_00_000Z_1'),
      );
      expect(outsideDirectory.listSync(), isEmpty);
      expect(await linkedDirectory.exists(), isTrue);
      expect(
        await File(
          '${files.directoryPath}/expense_receipts.csv',
        ).readAsString(),
        contains('Fuel Stop'),
      );

      await outputDirectory.delete(recursive: true);
      await outsideDirectory.delete(recursive: true);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test(
    'expense export writer refuses symlinked base export directories',
    () async {
      final outsideDirectory = await Directory.systemTemp.createTemp(
        'maintainiac_export_writer_symlink_base_outside_',
      );
      final parentDirectory = await Directory.systemTemp.createTemp(
        'maintainiac_export_writer_symlink_base_parent_',
      );
      final baseLink = Link('${parentDirectory.path}/exports-link');
      await baseLink.create(outsideDirectory.path);
      final snapshot = buildExpenseExportSnapshot(
        receipts: [
          ExpenseReceiptRecord(
            id: 'EXP-base-symlink',
            receiptDate: DateTime(2026, 6, 11),
            merchantName: 'Fuel Stop',
            enteredSubtotal: 40,
            enteredTax: 2.8,
            enteredTotal: 42.8,
            lines: const [
              ExpenseReceiptLineRecord(
                id: 'LINE-base-symlink',
                description: 'Diesel',
                category: 'Fuel',
                use: ExpenseLineUse.business,
                quantity: 10,
                unitsPerPackage: 1,
                unit: 'gallon',
                subtotal: 40,
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

      await expectLater(
        ExpenseExportFileWriter(
          baseDirectory: Directory(baseLink.path),
        ).writeExpenseExport(snapshot),
        throwsA(
          isA<FileSystemException>().having(
            (error) => error.message,
            'message',
            contains('safe local folder'),
          ),
        ),
      );
      expect(outsideDirectory.listSync(), isEmpty);
      expect(await baseLink.exists(), isTrue);

      await parentDirectory.delete(recursive: true);
      await outsideDirectory.delete(recursive: true);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test(
    'expense export privacy guard blocks private data before files are written',
    () async {
      final outputDirectory = await Directory.systemTemp.createTemp(
        'maintainiac_export_privacy_guard_test_',
      );
      final snapshot = buildExpenseExportSnapshot(
        receipts: [
          ExpenseReceiptRecord(
            id: 'EXP-private',
            receiptDate: DateTime(2026, 6, 11),
            merchantName: 'Contractor Supply',
            enteredSubtotal: 40,
            enteredTax: 2.8,
            enteredTotal: 42.8,
            vehicleId: 'VIN 1HGCM82633A004352',
            notes: 'Passenger: Jane Customer',
            lines: const [
              ExpenseReceiptLineRecord(
                id: 'LINE-private',
                description: 'Plate: ABC 1234',
                category: 'Fuel',
                use: ExpenseLineUse.business,
                quantity: 10,
                unitsPerPackage: 1,
                unit: 'gallon',
                subtotal: 40,
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

      expect(snapshot.canExport, isFalse);
      expect(snapshot.privacyIssueCodes, contains(AppPdfPrivacyPolicy.vin));
      expect(
        snapshot.privacyIssueCodes,
        contains(AppPdfPrivacyPolicy.licensePlate),
      );
      expect(
        snapshot.privacyIssueCodes,
        contains(AppPdfPrivacyPolicy.passengerData),
      );
      await expectLater(
        ExpenseExportFileWriter(
          baseDirectory: outputDirectory,
        ).writeExpenseExport(snapshot),
        throwsA(
          isA<ExpenseExportPrivacyException>().having(
            (error) => error.issues,
            'issues',
            containsAll([
              AppPdfPrivacyPolicy.vin,
              AppPdfPrivacyPolicy.licensePlate,
              AppPdfPrivacyPolicy.passengerData,
            ]),
          ),
        ),
      );
      await expectLater(
        buildExpenseExportSummaryPdf(snapshot),
        throwsA(isA<ExpenseExportPrivacyException>()),
      );
      expect(await outputDirectory.list().isEmpty, isTrue);

      await outputDirectory.delete(recursive: true);
    },
  );

  test(
    'expense export privacy guard covers OCR summary and source metadata',
    () async {
      final outputDirectory = await Directory.systemTemp.createTemp(
        'maintainiac_export_ocr_privacy_surface_test_',
      );
      final snapshot = buildExpenseExportSnapshot(
        receipts: [
          ExpenseReceiptRecord(
            id: 'EXP-ocr-private-source',
            receiptDate: DateTime(2026, 6, 11),
            merchantName: 'Fuel Stop',
            enteredSubtotal: 40,
            enteredTax: 2.8,
            enteredTotal: 42.8,
            ocrReview: const ExpenseReceiptOcrReview(
              severity: 'review',
              source: '/Users/rbbie/private-receipts/fuel-stop.pdf',
              primaryWarningKind: 'receipt_photo_read_failed',
              recoveryAction: 'retry_with_safe_receipt_copy',
              recoveryTarget: 'pdf_source',
              recoverySummary:
                  'Use a safe copy without content://private/receipt.pdf.',
              warningCount: 1,
              reviewWarningCount: 1,
            ),
            lines: const [
              ExpenseReceiptLineRecord(
                id: 'LINE-ocr-private-source',
                description: 'Diesel',
                category: 'Fuel',
                use: ExpenseLineUse.business,
                quantity: 10,
                unitsPerPackage: 1,
                unit: 'gallon',
                subtotal: 40,
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

      expect(snapshot.canExport, isFalse);
      expect(
        snapshot.privacyIssueCodes,
        contains(AppPdfPrivacyPolicy.privateSourcePath),
      );
      await expectLater(
        ExpenseExportFileWriter(
          baseDirectory: outputDirectory,
        ).writeExpenseExport(snapshot),
        throwsA(
          isA<ExpenseExportPrivacyException>().having(
            (error) => error.issues,
            'issues',
            contains(AppPdfPrivacyPolicy.privateSourcePath),
          ),
        ),
      );
      await expectLater(
        buildExpenseExportSummaryPdf(snapshot),
        throwsA(isA<ExpenseExportPrivacyException>()),
      );
      expect(await outputDirectory.list().isEmpty, isTrue);

      await outputDirectory.delete(recursive: true);
    },
  );

  test(
    'expense export package contains only prepared files with safe entry names',
    () async {
      final outputDirectory = await Directory.systemTemp.createTemp(
        'maintainiac_export_zip_safe_test_',
      );
      final snapshot = buildExpenseExportSnapshot(
        receipts: [
          ExpenseReceiptRecord(
            id: 'EXP-zip-safe',
            receiptDate: DateTime(2026, 6, 11),
            merchantName: 'Fuel Stop',
            enteredSubtotal: 40,
            enteredTax: 2.8,
            enteredTotal: 42.8,
            lines: const [
              ExpenseReceiptLineRecord(
                id: 'LINE-zip-safe',
                description: 'Diesel',
                category: 'Fuel',
                use: ExpenseLineUse.business,
                quantity: 10,
                unitsPerPackage: 1,
                unit: 'gallon',
                subtotal: 40,
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
      final files = await ExpenseExportFileWriter(
        baseDirectory: outputDirectory,
      ).writeExpenseExport(snapshot);

      final zipBytes = await buildExpenseExportZipBytes(files);
      final entries = ZipDecoder().decodeBytes(zipBytes).files;

      expect(entries.map((entry) => entry.name), [
        'expense_export_manifest.json',
        'expense_line_items.csv',
        'expense_receipts.csv',
      ]);
      expect(
        entries.map((entry) => entry.name).join('\n'),
        isNot(contains(outputDirectory.path)),
      );
      final receiptsEntry = entries.singleWhere(
        (entry) => entry.name == 'expense_receipts.csv',
      );
      expect(utf8.decode(receiptsEntry.readBytes()!), contains('Fuel Stop'));

      await outputDirectory.delete(recursive: true);
    },
  );

  test(
    'expense export package is deterministic for same prepared files',
    () async {
      final outputDirectory = await Directory.systemTemp.createTemp(
        'maintainiac_export_zip_deterministic_test_',
      );
      final exportDirectory = Directory(
        '${outputDirectory.path}/maintainiac_expense_export_stable',
      );
      await exportDirectory.create(recursive: true);
      final manifest = File(
        '${exportDirectory.path}/expense_export_manifest.json',
      );
      final lines = File('${exportDirectory.path}/expense_line_items.csv');
      final receipts = File('${exportDirectory.path}/expense_receipts.csv');
      await manifest.writeAsString('{"stable":true}', flush: true);
      await lines.writeAsString('line,total\none,1.00\n', flush: true);
      await receipts.writeAsString('receipt,total\none,1.00\n', flush: true);

      final first = await buildExpenseExportZipBytes(
        ExpenseExportFileSet(
          directoryPath: exportDirectory.path,
          files: [receipts.path, lines.path, manifest.path],
        ),
      );
      final second = await buildExpenseExportZipBytes(
        ExpenseExportFileSet(
          directoryPath: exportDirectory.path,
          files: [manifest.path, receipts.path, lines.path],
        ),
      );
      final entryNames = ZipDecoder()
          .decodeBytes(first)
          .files
          .map((entry) => entry.name)
          .toList(growable: false);

      expect(first, second);
      expect(entryNames, [
        'expense_export_manifest.json',
        'expense_line_items.csv',
        'expense_receipts.csv',
      ]);

      await outputDirectory.delete(recursive: true);
    },
  );

  test(
    'expense export package blocks files outside the prepared folder',
    () async {
      final outputDirectory = await Directory.systemTemp.createTemp(
        'maintainiac_export_zip_outside_test_',
      );
      final exportDirectory = Directory(
        '${outputDirectory.path}/maintainiac_expense_export_2026_06_12',
      );
      await exportDirectory.create(recursive: true);
      final inside = File('${exportDirectory.path}/expense_receipts.csv');
      final outside = File('${outputDirectory.path}/outside.csv');
      await inside.writeAsString('safe export', flush: true);
      await outside.writeAsString('outside export', flush: true);

      await expectLater(
        buildExpenseExportZipBytes(
          ExpenseExportFileSet(
            directoryPath: exportDirectory.path,
            files: [inside.path, outside.path],
          ),
        ),
        throwsA(
          isA<AppGeneratedPdfException>().having(
            (error) => error.message,
            'message',
            contains('outside the export folder'),
          ),
        ),
      );

      expect(await inside.exists(), isTrue);
      expect(await outside.exists(), isTrue);

      await outputDirectory.delete(recursive: true);
    },
  );

  test(
    'expense export package refuses duplicate and symlinked file entries',
    () async {
      final outputDirectory = await Directory.systemTemp.createTemp(
        'maintainiac_export_zip_duplicate_test_',
      );
      final firstDirectory = Directory(
        '${outputDirectory.path}/maintainiac_expense_export_first',
      );
      final secondDirectory = Directory(
        '${outputDirectory.path}/maintainiac_expense_export_second',
      );
      await firstDirectory.create(recursive: true);
      await secondDirectory.create(recursive: true);
      final first = File('${firstDirectory.path}/expense_receipts.csv');
      final duplicate = File('${secondDirectory.path}/expense_receipts.csv');
      await first.writeAsString('first export', flush: true);
      await duplicate.writeAsString('duplicate export', flush: true);

      await expectLater(
        buildExpenseExportZipBytes(
          ExpenseExportFileSet(
            directoryPath: outputDirectory.path,
            files: [first.path, duplicate.path],
          ),
        ),
        throwsA(
          isA<AppGeneratedPdfException>().having(
            (error) => error.message,
            'message',
            contains('not unique'),
          ),
        ),
      );

      final target = File('${firstDirectory.path}/expense_line_items.csv');
      await target.writeAsString('line export', flush: true);
      final link = Link('${firstDirectory.path}/linked_manifest.json');
      await link.create(target.path);

      await expectLater(
        buildExpenseExportZipBytes(
          ExpenseExportFileSet(
            directoryPath: firstDirectory.path,
            files: [first.path, link.path],
          ),
        ),
        throwsA(
          isA<AppGeneratedPdfException>().having(
            (error) => error.message,
            'message',
            contains('not a regular file'),
          ),
        ),
      );
      expect(await link.exists(), isTrue);
      expect(await target.exists(), isTrue);

      await outputDirectory.delete(recursive: true);
    },
    skip: Platform.isWindows ? 'POSIX symlink coverage only.' : false,
  );

  test('expense export package enforces file count and byte budgets', () async {
    final outputDirectory = await Directory.systemTemp.createTemp(
      'maintainiac_export_zip_budget_test_',
    );
    final filePaths = <String>[];
    for (var index = 0; index < 3; index++) {
      final file = File('${outputDirectory.path}/export_$index.csv');
      await file.writeAsString('12345', flush: true);
      filePaths.add(file.path);
    }
    final fileSet = ExpenseExportFileSet(
      directoryPath: outputDirectory.path,
      files: filePaths,
    );

    await expectLater(
      buildExpenseExportZipBytes(fileSet, maxSourceFiles: 2),
      throwsA(
        isA<AppGeneratedPdfException>().having(
          (error) => error.message,
          'message',
          contains('too many export files'),
        ),
      ),
    );
    await expectLater(
      buildExpenseExportZipBytes(fileSet, maxSourceFileBytes: 4),
      throwsA(
        isA<AppGeneratedPdfException>().having(
          (error) => error.message,
          'message',
          contains('export file was too large'),
        ),
      ),
    );
    await expectLater(
      buildExpenseExportZipBytes(fileSet, maxTotalSourceBytes: 12),
      throwsA(
        isA<AppGeneratedPdfException>().having(
          (error) => error.message,
          'message',
          contains('prepared export files were too large'),
        ),
      ),
    );

    await outputDirectory.delete(recursive: true);
  });

  test('expense export package write verifies partial and final ZIP files', () {
    final source = File(
      'lib/screens/expenses/data/expense_export_handoff.dart',
    ).readAsStringSync();

    expect(source, contains('Future<void> _writeZipAtomically('));
    expect(source, contains('Future<void> _requireRegularExportPackageFile('));
    expect(
      source,
      contains('await _requireRegularExportPackageFile(partial);'),
    );
    expect(source, contains('partialLength != zipBytes.length'));
    expect(source, contains('await _requireRegularExportPackageFile(target);'));
    expect(source, contains('targetLength != zipBytes.length'));
    expect(
      source,
      contains('_bytesEqual(await partial.readAsBytes(), zipBytes)'),
    );
    expect(
      source,
      contains('_bytesEqual(await target.readAsBytes(), zipBytes)'),
    );
    expect(source, contains('followLinks: false'));
    expect(source, contains('could not save the export package'));
    expect(source, contains('bytes.length != fileLength'));
    expect(source, contains('changed while the package was being prepared'));
  });
}
