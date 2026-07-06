import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../shared/pdf/app_generated_pdf_models.dart';
import '../../../shared/pdf/app_generated_pdf_service.dart';
import '../../../shared/pdf/app_pdf_determinism.dart';
import '../../../shared/pdf/app_pdf_formatters.dart';
import '../../../shared/pdf/app_pdf_typography.dart';
import '../../../shared/storage/app_storage_guard.dart';
import 'expense_export_file_writer.dart';
import 'expense_export_models.dart';

class ExpenseExportHandoffResult {
  const ExpenseExportHandoffResult({
    required this.title,
    required this.message,
    required this.completed,
    this.savedPath,
  });

  final String title;
  final String message;
  final bool completed;
  final String? savedPath;
}

class ExpenseExportHandoff {
  const ExpenseExportHandoff();

  Future<ExpenseExportHandoffResult> send({
    required ExpenseExportSnapshot snapshot,
    required ExpenseExportFileSet files,
  }) async {
    return switch (snapshot.destination) {
      ExpenseExportDestination.share => _sharePackage(
        snapshot: snapshot,
        files: files,
        title: 'Export Shared',
        message:
            'Choose where to send, save, or back up the export package from your phone.',
      ),
      ExpenseExportDestination.saveFiles => _saveZip(snapshot, files),
      ExpenseExportDestination.email => _sharePackage(
        snapshot: snapshot,
        files: files,
        title: 'Email Export',
        message:
            'Choose your email app, then address and send the export from there.',
      ),
      ExpenseExportDestination.textMessage => _sharePackage(
        snapshot: snapshot,
        files: files,
        title: 'Text Export',
        message:
            'Choose Messages or your texting app. Add the phone number before sending.',
      ),
      ExpenseExportDestination.print => _printSummary(snapshot),
    };
  }

  Future<ExpenseExportHandoffResult> _saveZip(
    ExpenseExportSnapshot snapshot,
    ExpenseExportFileSet files,
  ) async {
    final zipBytes = await buildExpenseExportZipBytes(files);
    final fileName = _exportPackageName(snapshot);
    final path = await FilePicker.saveFile(
      dialogTitle: 'Save Maintainiac export',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const ['zip'],
      bytes: Uint8List.fromList(zipBytes),
    );

    if (path == null) {
      return const ExpenseExportHandoffResult(
        title: 'Save Cancelled',
        message:
            'The export files were prepared, but no save location was chosen.',
        completed: false,
      );
    }

    return ExpenseExportHandoffResult(
      title: 'Export Saved',
      message: 'Saved export package to:\n$path',
      completed: true,
      savedPath: path,
    );
  }

  Future<ExpenseExportHandoffResult> _sharePackage({
    required ExpenseExportSnapshot snapshot,
    required ExpenseExportFileSet files,
    required String title,
    required String message,
  }) async {
    final package = await _writeZipPackage(snapshot, files);
    final result = await SharePlus.instance.share(
      ShareParams(
        title: 'Maintainiac Export',
        subject: _shareSubject(snapshot),
        text: _shareBody(snapshot),
        files: [XFile(package.path)],
      ),
    );

    final completed =
        result.status == ShareResultStatus.success ||
        result.status == ShareResultStatus.unavailable;
    return ExpenseExportHandoffResult(
      title: completed ? title : 'Share Cancelled',
      message: completed
          ? '$message\n\nPackage:\n${package.path}'
          : 'The export files were prepared, but the share sheet was closed.',
      completed: completed,
      savedPath: package.path,
    );
  }

  Future<ExpenseExportHandoffResult> _printSummary(
    ExpenseExportSnapshot snapshot,
  ) async {
    final printed = await const AppGeneratedPdfService().print(
      await buildExpenseExportSummaryPdf(snapshot),
    );
    return ExpenseExportHandoffResult(
      title: printed ? 'Print Started' : 'Print Cancelled',
      message: printed
          ? 'The phone opened the print flow for this export summary.'
          : 'The print flow was closed before printing.',
      completed: printed,
    );
  }
}

Future<File> _writeZipPackage(
  ExpenseExportSnapshot snapshot,
  ExpenseExportFileSet files,
) async {
  final zipBytes = await buildExpenseExportZipBytes(files);
  final storageCheck = await AppStorageGuard.checkForBytes(
    operationBytes: zipBytes.length + (1024 * 1024),
    purpose: AppStoragePurpose.exportFile,
  );
  if (!storageCheck.hasEnoughSpace) {
    throw AppGeneratedPdfException(storageCheck.blockingMessage());
  }
  final package = File(
    '${files.directoryPath}/${_exportPackageName(snapshot)}',
  );
  await _writeZipAtomically(package, zipBytes);
  return package;
}

Future<List<int>> buildExpenseExportZipBytes(ExpenseExportFileSet files) async {
  final root = Directory(files.directoryPath);
  final rootType = await FileSystemEntity.type(root.path, followLinks: false);
  if (rootType != FileSystemEntityType.directory) {
    throw const AppGeneratedPdfException(
      'Maintainiac could not build the export package because the prepared export folder is missing.',
    );
  }
  final rootPath = p.canonicalize(await root.resolveSymbolicLinks());
  final archive = Archive();
  final entryNames = <String>{};
  for (final filePath in files.files) {
    final file = File(filePath);
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.file) {
      throw const AppGeneratedPdfException(
        'Maintainiac could not build the export package because an export file was not a regular file.',
      );
    }
    final canonicalFilePath = p.canonicalize(await file.resolveSymbolicLinks());
    if (!p.isWithin(rootPath, canonicalFilePath)) {
      throw const AppGeneratedPdfException(
        'Maintainiac blocked this export package because a prepared file was outside the export folder.',
      );
    }
    final name = p.basename(file.path);
    if (name.isEmpty || !entryNames.add(name)) {
      throw const AppGeneratedPdfException(
        'Maintainiac could not build the export package because export file names were not unique.',
      );
    }
    final bytes = await file.readAsBytes();
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }
  return ZipEncoder().encode(archive);
}

Future<void> _writeZipAtomically(File target, List<int> zipBytes) async {
  final targetType = await FileSystemEntity.type(
    target.path,
    followLinks: false,
  );
  if (targetType != FileSystemEntityType.notFound) {
    throw const AppGeneratedPdfException(
      'Maintainiac could not save the export package because the destination already exists.',
    );
  }
  final partial = File('${target.path}.partial');
  final partialType = await FileSystemEntity.type(
    partial.path,
    followLinks: false,
  );
  if (partialType == FileSystemEntityType.file) {
    await partial.delete();
  } else if (partialType != FileSystemEntityType.notFound) {
    throw const AppGeneratedPdfException(
      'Maintainiac could not save the export package because a stale partial file was unsafe.',
    );
  }
  try {
    await partial.writeAsBytes(zipBytes, flush: true);
    await _requireRegularExportPackageFile(partial);
    final partialLength = await partial.length();
    if (partialLength != zipBytes.length) {
      throw const FileSystemException('Export package write was incomplete.');
    }
    await _requireRegularExportPackageFile(partial);
    await partial.rename(target.path);
    await _requireRegularExportPackageFile(target);
    final targetLength = await target.length();
    if (targetLength != zipBytes.length) {
      throw const FileSystemException('Export package verification failed.');
    }
  } catch (_) {
    if (await partial.exists()) {
      await partial.delete();
    }
    throw const AppGeneratedPdfException(
      'Maintainiac could not save the export package. Please free up storage and try again.',
    );
  }
}

Future<void> _requireRegularExportPackageFile(File file) async {
  final type = await FileSystemEntity.type(file.path, followLinks: false);
  if (type == FileSystemEntityType.file) return;
  throw const FileSystemException('Export package file was unsafe.');
}

Future<AppGeneratedPdfDocument> buildExpenseExportSummaryPdf(
  ExpenseExportSnapshot snapshot,
) async {
  snapshot.ensureCanExport();
  final pdf = pw.Document();
  final pdfTheme = await AppPdfTypography.loadTheme();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
      theme: pdfTheme,
      build: (context) => [
        pw.Text(
          'Maintainiac Expense Export',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Date range: ${_date(snapshot.range.start)} - ${_date(snapshot.range.end)}',
        ),
        pw.Text('Category set: ${snapshot.categoryFilter.label}'),
        pw.Text('Receipts: ${snapshot.receiptCount}'),
        pw.Text('Line items: ${snapshot.lineCount}'),
        pw.Text('Total: ${AppPdfFormatters.money(snapshot.total)}'),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headers: const [
            'Date',
            'Merchant',
            'Category',
            'Description',
            'Total',
          ],
          data: [
            for (final receipt in snapshot.receipts)
              for (final line in snapshot.filteredLinesFor(receipt))
                [
                  _date(receipt.receiptDate),
                  receipt.merchantName,
                  line.category,
                  line.description,
                  AppPdfFormatters.money(
                    snapshot.taxAdjustedTotalForLine(receipt, line),
                  ),
                ],
          ],
        ),
      ],
    ),
  );
  final bytes = AppPdfDeterminism.normalizeDocumentId(
    await pdf.save(),
    [
      'expense-export-summary-v1',
      snapshot.range.start.toIso8601String(),
      snapshot.range.end.toIso8601String(),
      snapshot.categoryFilter.name,
      snapshot.exportedAt.toIso8601String(),
      snapshot.receipts.length,
      snapshot.lineCount,
      AppPdfFormatters.money(snapshot.total),
      snapshot.receipts
          .map(
            (receipt) => [
              receipt.id,
              receipt.receiptDate.toIso8601String(),
              receipt.merchantName,
              snapshot
                  .filteredLinesFor(receipt)
                  .map(
                    (line) => [
                      line.category,
                      line.description,
                      AppPdfFormatters.money(
                        snapshot.taxAdjustedTotalForLine(receipt, line),
                      ),
                    ].join('|'),
                  )
                  .join('::'),
            ].join('|'),
          )
          .join('||'),
    ].join('\n'),
  );
  final fileName =
      'maintainiac_expense_export_${_fileDate(snapshot.range.start)}_to_${_fileDate(snapshot.range.end)}.pdf';
  return AppGeneratedPdfDocument(
    kind: AppGeneratedPdfKind.expenseExport,
    title: 'Maintainiac Expense Export',
    fileName: fileName,
    bytes: bytes,
    createdAt: snapshot.exportedAt,
    sourceModule: 'expenses',
    shareSubject: _shareSubject(snapshot),
    shareText: _shareBody(snapshot),
  );
}

String _shareSubject(ExpenseExportSnapshot snapshot) {
  return 'Maintainiac expense export ${_date(snapshot.range.start)} - ${_date(snapshot.range.end)}';
}

String _shareBody(ExpenseExportSnapshot snapshot) {
  return [
    'Maintainiac expense export',
    'Date range: ${_date(snapshot.range.start)} - ${_date(snapshot.range.end)}',
    'Receipts: ${snapshot.receiptCount}',
    'Line items: ${snapshot.lineCount}',
    'Total: ${AppPdfFormatters.money(snapshot.total)}',
  ].join('\n');
}

String _exportPackageName(ExpenseExportSnapshot snapshot) {
  final start = _fileDate(snapshot.range.start);
  final end = _fileDate(snapshot.range.end);
  return 'maintainiac_expense_export_${start}_to_$end.zip';
}

String _fileDate(DateTime day) {
  return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}

String _date(DateTime day) => AppPdfFormatters.date(day);
