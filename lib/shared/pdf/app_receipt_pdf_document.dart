import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pdf/widgets.dart' as pw;

import 'app_generated_pdf_models.dart';
import 'app_pdf_determinism.dart';
import 'app_pdf_formatters.dart';
import 'app_pdf_page_spec.dart';

const int appReceiptPdfMaxEmbeddedImages = 12;
const int appReceiptPdfMaxEmbeddedImageBytes = 10 * 1024 * 1024;
const int appReceiptPdfMaxTotalEmbeddedImageBytes = 24 * 1024 * 1024;
const int appReceiptPdfLineRowsPerSection = 32;
const double appReceiptPdfMinimumTotalsFreeSpace = 120;
const double appReceiptPdfMinimumProofImageFreeSpace = 380;

class AppReceiptPdfLine {
  const AppReceiptPdfLine({
    required this.description,
    required this.category,
    required this.totalCents,
    this.quantity = 1,
    this.unit = '',
  });

  final String description;
  final String category;
  final int totalCents;
  final num quantity;
  final String unit;

  String get safeDescription => _cleanText(description);

  String get safeCategory => _cleanText(category);

  String get quantityLabel {
    final unitLabel = _cleanText(unit);
    final rendered = AppPdfFormatters.quantity(quantity);
    return unitLabel.isEmpty ? rendered : '$rendered $unitLabel';
  }

  String get totalLabel => AppPdfFormatters.moneyCents(totalCents);
}

class AppReceiptPdfImage {
  const AppReceiptPdfImage({
    required this.bytes,
    this.label = '',
    this.sourcePageNumber,
  });

  final Uint8List bytes;
  final String label;
  final int? sourcePageNumber;

  String get safeLabel => _cleanText(label);

  String get displayLabel {
    final page = sourcePageNumber;
    final base = safeLabel.isEmpty ? 'Receipt proof image' : safeLabel;
    if (page == null || page < 1) return base;
    return '$base $page';
  }

  int get byteSize => bytes.lengthInBytes;

  String get sha256Hex => sha256.convert(bytes).toString();
}

class AppReceiptPdfLineSection {
  const AppReceiptPdfLineSection({
    required this.sectionNumber,
    required this.sectionCount,
    required this.startIndex,
    required this.lines,
  });

  final int sectionNumber;
  final int sectionCount;
  final int startIndex;
  final List<AppReceiptPdfLine> lines;

  String get label {
    if (sectionCount == 1) return 'Receipt line items';
    return 'Receipt line items section $sectionNumber of $sectionCount';
  }
}

class AppReceiptPdfData {
  const AppReceiptPdfData({
    required this.merchantName,
    required this.receiptDate,
    required this.lines,
    required this.confirmedByUser,
    this.receiptNumber = '',
    this.businessUseLabel = '',
    this.sourceRecordId = '',
    this.subtotalCents,
    this.taxCents,
    this.tipCents,
    this.totalCents,
    this.notes = '',
    this.proofImages = const [],
  });

  final String merchantName;
  final DateTime receiptDate;
  final List<AppReceiptPdfLine> lines;
  final bool confirmedByUser;
  final String receiptNumber;
  final String businessUseLabel;
  final String sourceRecordId;
  final int? subtotalCents;
  final int? taxCents;
  final int? tipCents;
  final int? totalCents;
  final String notes;
  final List<AppReceiptPdfImage> proofImages;

  int get confirmedLineTotalCents =>
      lines.fold<int>(0, (total, line) => total + line.totalCents);

  int get safeTotalCents => totalCents ?? confirmedLineTotalCents;

  bool get hasConfirmedLines => lines.isNotEmpty;

  bool get totalsMatchConfirmedLines {
    if (totalCents == null) return true;
    final knownParts =
        (subtotalCents ?? confirmedLineTotalCents) +
        (taxCents ?? 0) +
        (tipCents ?? 0);
    return knownParts == totalCents;
  }

  String get safeMerchantName {
    final clean = _cleanText(merchantName);
    return clean.isEmpty ? 'Receipt' : clean;
  }

  String get safeReceiptNumber => _cleanText(receiptNumber);

  String get safeBusinessUseLabel => _cleanText(businessUseLabel);

  String get safeNotes => _cleanText(notes);

  int get totalProofImageBytes =>
      proofImages.fold<int>(0, (total, image) => total + image.byteSize);
}

class AppReceiptPdfRenderer {
  const AppReceiptPdfRenderer();

  List<AppReceiptPdfLineSection> planLineSections(AppReceiptPdfData data) {
    final sectionCount = (data.lines.length / appReceiptPdfLineRowsPerSection)
        .ceil();
    return [
      for (
        var start = 0;
        start < data.lines.length;
        start += appReceiptPdfLineRowsPerSection
      )
        AppReceiptPdfLineSection(
          sectionNumber: (start ~/ appReceiptPdfLineRowsPerSection) + 1,
          sectionCount: sectionCount,
          startIndex: start,
          lines: List<AppReceiptPdfLine>.unmodifiable(
            data.lines.sublist(
              start,
              (start + appReceiptPdfLineRowsPerSection).clamp(
                0,
                data.lines.length,
              ),
            ),
          ),
        ),
    ];
  }

  Future<AppGeneratedPdfDocument> buildReceiptDocument({
    required AppReceiptPdfData data,
    DateTime? createdAt,
    AppPdfPageSpec pageSpec = AppPdfPageSpec.letterPortrait,
    pw.ThemeData? theme,
  }) async {
    if (!data.confirmedByUser) {
      throw const AppReceiptPdfException(
        'Maintainiac will only export receipt PDFs after the user confirms the receipt data.',
      );
    }
    if (!data.hasConfirmedLines) {
      throw const AppReceiptPdfException(
        'Maintainiac needs at least one confirmed receipt line before creating a receipt PDF.',
      );
    }
    if (!data.totalsMatchConfirmedLines) {
      throw const AppReceiptPdfException(
        'Maintainiac stopped this receipt PDF because the confirmed line totals do not match the receipt total.',
      );
    }
    _validateProofImages(data.proofImages);
    final generatedAt = createdAt ?? DateTime.now();
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: pageSpec.format,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(36, 34, 36, 34),
        header: (context) => _header(data, context.pageNumber),
        footer: (context) => _footer(context.pageNumber, context.pagesCount),
        build: (context) => [
          _receiptSummary(data),
          pw.SizedBox(height: 14),
          ..._lineTables(data),
          pw.SizedBox(height: 12),
          pw.NewPage(freeSpace: appReceiptPdfMinimumTotalsFreeSpace),
          _totals(data),
          if (data.proofImages.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.NewPage(freeSpace: appReceiptPdfMinimumProofImageFreeSpace),
            ..._receiptProofImages(data.proofImages),
          ],
          if (data.safeNotes.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _notes(data.safeNotes),
          ],
        ],
      ),
    );

    final bytes = AppPdfDeterminism.normalizeDocumentId(
      await pdf.save(),
      [
        'maintainiac-receipt-pdf-v1',
        pageSpec.key,
        data.safeMerchantName,
        data.receiptDate.toIso8601String(),
        data.safeReceiptNumber,
        data.safeBusinessUseLabel,
        data.lines
            .map(
              (line) => [
                line.safeDescription,
                line.safeCategory,
                line.quantityLabel,
                line.totalCents,
              ].join('|'),
            )
            .join('||'),
        data.subtotalCents,
        data.taxCents,
        data.tipCents,
        data.safeTotalCents,
        data.safeNotes,
        data.proofImages
            .map(
              (image) => [
                image.displayLabel,
                image.byteSize,
                image.sha256Hex,
              ].join('|'),
            )
            .join('||'),
      ].join('\n'),
    );
    final document = AppGeneratedPdfDocument(
      kind: AppGeneratedPdfKind.receipt,
      title: '${data.safeMerchantName} Receipt',
      fileName: _fileNameFor(data),
      bytes: Uint8List.fromList(bytes),
      createdAt: generatedAt,
      sourceModule: 'receipts',
      sourceRecordId: data.sourceRecordId,
      shareSubject: 'Maintainiac receipt - ${data.safeMerchantName}',
      shareText: [
        'Maintainiac receipt',
        'Merchant: ${data.safeMerchantName}',
        'Date: ${AppPdfFormatters.date(data.receiptDate)}',
        'Total: ${AppPdfFormatters.moneyCents(data.safeTotalCents)}',
      ].join('\n'),
    );
    final validation = document.validation;
    if (validation.isValid) return document;
    throw AppReceiptPdfException(validation.userMessage);
  }

  pw.Widget _header(AppReceiptPdfData data, int pageNumber) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Maintainiac Receipt',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(data.safeMerchantName),
        pw.SizedBox(height: 8),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _footer(int pageNumber, int pageCount) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page $pageNumber of $pageCount',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ),
      ],
    );
  }

  pw.Widget _receiptSummary(AppReceiptPdfData data) {
    final rows = <List<String>>[
      ['Date', AppPdfFormatters.date(data.receiptDate)],
      if (data.safeReceiptNumber.isNotEmpty)
        ['Receipt #', data.safeReceiptNumber],
      if (data.safeBusinessUseLabel.isNotEmpty)
        ['Use', data.safeBusinessUseLabel],
      ['Confirmed lines', data.lines.length.toString()],
    ];
    return pw.TableHelper.fromTextArray(
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headers: const ['Field', 'Value'],
      data: rows,
    );
  }

  List<pw.Widget> _lineTables(AppReceiptPdfData data) {
    final widgets = <pw.Widget>[];
    for (final section in planLineSections(data)) {
      if (section.startIndex > 0) {
        widgets.add(pw.NewPage());
      }
      widgets.add(
        pw.Text(
          section.label,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      );
      widgets.add(pw.SizedBox(height: 6));
      widgets.add(_lineTable(section.lines));
    }
    return widgets;
  }

  pw.Widget _lineTable(List<AppReceiptPdfLine> lines) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headers: const ['Item', 'Category', 'Qty', 'Total'],
      columnWidths: const {
        0: pw.FlexColumnWidth(4.5),
        1: pw.FlexColumnWidth(2.2),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(1.4),
      },
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
      headerAlignment: pw.Alignment.centerLeft,
      data: [
        for (final line in lines)
          [
            line.safeDescription,
            line.safeCategory,
            line.quantityLabel,
            line.totalLabel,
          ],
      ],
    );
  }

  pw.Widget _totals(AppReceiptPdfData data) {
    final rows = <List<String>>[
      if (data.subtotalCents != null)
        ['Subtotal', AppPdfFormatters.moneyCents(data.subtotalCents!)],
      if (data.taxCents != null)
        ['Tax', AppPdfFormatters.moneyCents(data.taxCents!)],
      if (data.tipCents != null)
        ['Tip', AppPdfFormatters.moneyCents(data.tipCents!)],
      ['Total', AppPdfFormatters.moneyCents(data.safeTotalCents)],
    ];
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220,
        child: pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headers: const ['Total', 'Amount'],
          data: rows,
        ),
      ),
    );
  }

  pw.Widget _notes(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Notes', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text(notes, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  List<pw.Widget> _receiptProofImages(List<AppReceiptPdfImage> images) {
    return [
      pw.Text(
        'Receipt Proof Images',
        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 8),
      for (final entry in images.indexed) ...[
        pw.Text(
          entry.$2.displayLabel,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          height: 330,
          width: double.infinity,
          decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
          padding: const pw.EdgeInsets.all(6),
          child: pw.Image(
            pw.MemoryImage(entry.$2.bytes),
            fit: pw.BoxFit.contain,
            alignment: pw.Alignment.center,
          ),
        ),
        pw.Text(
          'Proof image SHA-256: ${entry.$2.sha256Hex}',
          style: const pw.TextStyle(fontSize: 6),
        ),
        if (entry.$1 != images.length - 1) pw.SizedBox(height: 12),
      ],
    ];
  }

  void _validateProofImages(List<AppReceiptPdfImage> proofImages) {
    if (proofImages.length > appReceiptPdfMaxEmbeddedImages) {
      throw const AppReceiptPdfException(
        'Maintainiac stopped this receipt PDF because it has too many receipt proof images.',
      );
    }
    var totalBytes = 0;
    for (final image in proofImages) {
      final byteSize = image.byteSize;
      if (byteSize == 0) {
        throw const AppReceiptPdfException(
          'Maintainiac stopped this receipt PDF because a receipt proof image was empty.',
        );
      }
      if (byteSize > appReceiptPdfMaxEmbeddedImageBytes) {
        throw const AppReceiptPdfException(
          'Maintainiac stopped this receipt PDF because a receipt proof image was too large.',
        );
      }
      if (!_isSupportedReceiptImage(image.bytes)) {
        throw const AppReceiptPdfException(
          'Maintainiac stopped this receipt PDF because a receipt proof image was not a supported image file.',
        );
      }
      totalBytes += byteSize;
    }
    if (totalBytes > appReceiptPdfMaxTotalEmbeddedImageBytes) {
      throw const AppReceiptPdfException(
        'Maintainiac stopped this receipt PDF because the receipt proof images were too large together.',
      );
    }
  }

  String _fileNameFor(AppReceiptPdfData data) {
    final merchant = data.safeMerchantName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final date =
        '${data.receiptDate.year}-${data.receiptDate.month.toString().padLeft(2, '0')}-${data.receiptDate.day.toString().padLeft(2, '0')}';
    final base = merchant.isEmpty ? 'receipt' : merchant;
    return 'maintainiac_receipt_${date}_$base.pdf';
  }
}

class AppReceiptPdfException implements Exception {
  const AppReceiptPdfException(this.message);

  final String message;

  @override
  String toString() => message;
}

bool _isSupportedReceiptImage(Uint8List bytes) {
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return true;
  }
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return true;
  }
  return false;
}

String _cleanText(String value) {
  return value
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
