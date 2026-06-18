import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../shared/pdf/app_generated_pdf_models.dart';
import '../../../shared/pdf/app_generated_pdf_service.dart';
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
    final zipBytes = await _buildZipBytes(files);
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
  final zipBytes = await _buildZipBytes(files);
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
  await package.writeAsBytes(zipBytes, flush: true);
  return package;
}

Future<List<int>> _buildZipBytes(ExpenseExportFileSet files) async {
  final archive = Archive();
  for (final path in files.files) {
    final file = File(path);
    final bytes = await file.readAsBytes();
    archive.addFile(ArchiveFile(_fileName(path), bytes.length, bytes));
  }
  return ZipEncoder().encode(archive);
}

Future<AppGeneratedPdfDocument> buildExpenseExportSummaryPdf(
  ExpenseExportSnapshot snapshot,
) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.letter,
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
        pw.Text('Total: \$${snapshot.total.toStringAsFixed(2)}'),
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
              for (final line in receipt.lines)
                [
                  _date(receipt.receiptDate),
                  receipt.merchantName,
                  line.category,
                  line.description,
                  '\$${receipt.totalForLine(line).toStringAsFixed(2)}',
                ],
          ],
        ),
      ],
    ),
  );
  final bytes = await pdf.save();
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
    'Total: \$${snapshot.total.toStringAsFixed(2)}',
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

String _date(DateTime day) => '${day.month}/${day.day}/${day.year}';

String _fileName(String path) => path.split(Platform.pathSeparator).last;
