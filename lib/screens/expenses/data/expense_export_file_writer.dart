import 'dart:convert';
import 'dart:io';

import 'expense_export_models.dart';

class ExpenseExportFileSet {
  const ExpenseExportFileSet({
    required this.directoryPath,
    required this.files,
  });

  final String directoryPath;
  final List<String> files;
}

class ExpenseExportFileWriter {
  const ExpenseExportFileWriter({Directory? baseDirectory})
    : _baseDirectory = baseDirectory;

  final Directory? _baseDirectory;

  Future<ExpenseExportFileSet> writeExpenseExport(
    ExpenseExportSnapshot snapshot,
  ) async {
    final directory = await _createExportDirectory(snapshot.exportedAt);
    final receiptsFile = File('${directory.path}/expense_receipts.csv');
    final linesFile = File('${directory.path}/expense_line_items.csv');
    final manifestFile = File('${directory.path}/expense_export_manifest.json');

    await receiptsFile.writeAsString(snapshot.toReceiptsCsv(), flush: true);
    await linesFile.writeAsString(snapshot.toLineItemsCsv(), flush: true);
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(snapshot.toManifest()),
      flush: true,
    );

    return ExpenseExportFileSet(
      directoryPath: directory.path,
      files: [receiptsFile.path, linesFile.path, manifestFile.path],
    );
  }

  Future<Directory> _createExportDirectory(DateTime exportedAt) async {
    final base = _baseDirectory ?? Directory.systemTemp;
    final stamp = exportedAt.toIso8601String().replaceAll(
      RegExp(r'[^0-9A-Za-z]+'),
      '_',
    );
    final directory = Directory(
      '${base.path}/maintaniac_expense_export_$stamp',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
