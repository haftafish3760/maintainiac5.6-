import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_file_writer.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_export_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';

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
}
