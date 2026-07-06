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
    snapshot.ensureCanExport();
    final directory = await _createExportDirectory(snapshot.exportedAt);
    final receiptsFile = File('${directory.path}/expense_receipts.csv');
    final linesFile = File('${directory.path}/expense_line_items.csv');
    final manifestFile = File('${directory.path}/expense_export_manifest.json');

    try {
      await _writeStringAtomically(receiptsFile, snapshot.toReceiptsCsv());
      await _writeStringAtomically(linesFile, snapshot.toLineItemsCsv());
      await _writeStringAtomically(
        manifestFile,
        const JsonEncoder.withIndent('  ').convert(snapshot.toManifest()),
      );
    } catch (_) {
      await _deleteExportDirectoryIfOwned(directory);
      rethrow;
    }

    return ExpenseExportFileSet(
      directoryPath: directory.path,
      files: [receiptsFile.path, linesFile.path, manifestFile.path],
    );
  }

  Future<Directory> _createExportDirectory(DateTime exportedAt) async {
    final base = _baseDirectory ?? Directory.systemTemp;
    await _ensureSafeBaseDirectory(base);
    final stamp = exportedAt.toIso8601String().replaceAll(
      RegExp(r'[^0-9A-Za-z]+'),
      '_',
    );
    for (var suffix = 0; suffix < 1000; suffix++) {
      final name = suffix == 0
          ? 'maintainiac_expense_export_$stamp'
          : 'maintainiac_expense_export_${stamp}_$suffix';
      final directory = Directory('${base.path}/$name');
      final type = await FileSystemEntity.type(
        directory.path,
        followLinks: false,
      );
      if (type != FileSystemEntityType.notFound) {
        continue;
      }
      await directory.create(recursive: true);
      return directory;
    }
    throw FileSystemException(
      'Could not create a unique Maintainiac expense export directory.',
      base.path,
    );
  }

  Future<void> _ensureSafeBaseDirectory(Directory base) async {
    var type = await FileSystemEntity.type(base.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      await base.create(recursive: true);
      type = await FileSystemEntity.type(base.path, followLinks: false);
    }
    if (type == FileSystemEntityType.directory) return;
    throw FileSystemException(
      'Maintainiac expense exports require a safe local folder.',
      base.path,
    );
  }

  Future<void> _writeStringAtomically(File target, String contents) async {
    final partial = File('${target.path}.partial');
    if (await partial.exists()) {
      await partial.delete();
    }
    await partial.writeAsString(contents, flush: true);
    await partial.rename(target.path);
  }

  Future<void> _deleteExportDirectoryIfOwned(Directory directory) async {
    final type = await FileSystemEntity.type(
      directory.path,
      followLinks: false,
    );
    if (type != FileSystemEntityType.directory) return;
    final name = directory.uri.pathSegments.lastWhere(
      (segment) => segment.isNotEmpty,
      orElse: () => '',
    );
    if (!name.startsWith('maintainiac_expense_export_')) return;
    await directory.delete(recursive: true);
  }
}
