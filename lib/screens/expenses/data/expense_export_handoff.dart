import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../shared/pdf/app_generated_pdf_models.dart';
import '../../../shared/pdf/app_generated_pdf_export_estimator.dart';
import '../../../shared/pdf/app_generated_pdf_image_loader.dart';
import '../../../shared/pdf/app_generated_pdf_share_content.dart';
import '../../../shared/pdf/app_generated_pdf_service.dart';
import '../../../shared/storage/app_storage_guard.dart';
import 'expense_export_file_writer.dart';
import 'expense_ledger_models.dart';
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

AppGeneratedPdfExportEstimate estimateExpenseExportPdf({
  required ExpenseExportSnapshot snapshot,
  required AppGeneratedPdfExportMode mode,
  int thumbnailBytes = 0,
  int cloudThumbnailBytes = 0,
  int cloudFullImageBytes = 0,
}) {
  final fullImageBytes = snapshot.receipts.fold<int>(0, (sum, receipt) {
    return sum +
        receipt.attachments.where((attachment) => attachment.isPhoto).fold<int>(
          0,
          (attachmentSum, attachment) {
            return attachmentSum + (attachment.byteSize ?? 0);
          },
        );
  });
  return AppGeneratedPdfExportEstimator.estimate(
    mode: mode,
    receiptCount: snapshot.receiptCount,
    fullImageBytes: fullImageBytes,
    thumbnailBytes: thumbnailBytes,
    cloudFullImageBytes: cloudFullImageBytes,
    cloudThumbnailBytes: cloudThumbnailBytes,
  );
}

AppGeneratedPdfImageLoader expenseReceiptImageLoaderForExport({
  required ExpenseExportSnapshot snapshot,
  Map<String, String> thumbnailPathsByAttachmentId = const {},
}) {
  final fullPathsByAttachmentId = <String, String>{
    for (final receipt in snapshot.receipts)
      for (final attachment in receipt.attachments)
        if (attachment.isPhoto && attachment.path.trim().isNotEmpty)
          attachment.id: attachment.path,
  };
  return ({
    required String attachmentId,
    required AppGeneratedPdfExportMode mode,
  }) async {
    final sourcePath = mode == AppGeneratedPdfExportMode.thumbnails
        ? thumbnailPathsByAttachmentId[attachmentId]
        : fullPathsByAttachmentId[attachmentId];
    if (sourcePath == null || sourcePath.trim().isEmpty) return null;
    final file = File(sourcePath);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  };
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
  ExpenseExportSnapshot snapshot, {
  AppGeneratedPdfExportMode mode = AppGeneratedPdfExportMode.textOnly,
  AppGeneratedPdfImageResolver? imageResolver,
  bool allowFullImageDownload = false,
}) async {
  final imageSections = await _loadReceiptImageSections(
    snapshot: snapshot,
    mode: mode,
    imageResolver: imageResolver,
    allowFullImageDownload: allowFullImageDownload,
  );
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
        if (imageSections.isNotEmpty) ...[
          pw.SizedBox(height: 18),
          pw.Text(
            'Receipt Images',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...imageSections,
        ],
      ],
    ),
  );
  final bytes = await pdf.save();
  final share = AppGeneratedPdfShareContent.expenseExport(
    rangeStart: snapshot.range.start,
    rangeEnd: snapshot.range.end,
    receiptCount: snapshot.receiptCount,
    lineCount: snapshot.lineCount,
    total: '\$${snapshot.total.toStringAsFixed(2)}',
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
    shareSubject: share.subject,
    shareText: share.text,
  );
}

Future<List<pw.Widget>> _loadReceiptImageSections({
  required ExpenseExportSnapshot snapshot,
  required AppGeneratedPdfExportMode mode,
  required AppGeneratedPdfImageResolver? imageResolver,
  required bool allowFullImageDownload,
}) async {
  if (mode == AppGeneratedPdfExportMode.textOnly) return const [];
  final resolver = imageResolver;
  if (resolver == null) {
    throw const AppGeneratedPdfException(
      'This receipt image PDF export needs an image source before it can be generated.',
    );
  }
  final sections = <pw.Widget>[];
  for (final receipt in snapshot.receipts) {
    for (final attachment in receipt.attachments.where(
      (item) => item.isPhoto,
    )) {
      final bytes = await resolver.resolve(
        attachmentId: attachment.id,
        mode: mode,
        allowFullImageDownload: allowFullImageDownload,
      );
      final image = pw.MemoryImage(bytes);
      sections.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('${receipt.merchantName} - ${attachment.id}'),
              pw.SizedBox(height: 4),
              pw.Image(
                image,
                height: mode == AppGeneratedPdfExportMode.thumbnails
                    ? 120
                    : 420,
                fit: pw.BoxFit.contain,
              ),
            ],
          ),
        ),
      );
    }
  }
  return sections;
}

String _shareSubject(ExpenseExportSnapshot snapshot) {
  return AppGeneratedPdfShareContent.expenseExport(
    rangeStart: snapshot.range.start,
    rangeEnd: snapshot.range.end,
    receiptCount: snapshot.receiptCount,
    lineCount: snapshot.lineCount,
    total: '\$${snapshot.total.toStringAsFixed(2)}',
  ).subject;
}

String _shareBody(ExpenseExportSnapshot snapshot) {
  return AppGeneratedPdfShareContent.expenseExport(
    rangeStart: snapshot.range.start,
    rangeEnd: snapshot.range.end,
    receiptCount: snapshot.receiptCount,
    lineCount: snapshot.lineCount,
    total: '\$${snapshot.total.toStringAsFixed(2)}',
  ).text;
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
