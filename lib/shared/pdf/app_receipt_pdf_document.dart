import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'app_generated_pdf_models.dart';
import 'app_pdf_determinism.dart';
import 'app_pdf_formatters.dart';
import 'app_pdf_page_spec.dart';

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

  int get confirmedLineTotalCents =>
      lines.fold<int>(0, (total, line) => total + line.totalCents);

  int get safeTotalCents => totalCents ?? confirmedLineTotalCents;

  String get safeMerchantName {
    final clean = _cleanText(merchantName);
    return clean.isEmpty ? 'Receipt' : clean;
  }

  String get safeReceiptNumber => _cleanText(receiptNumber);

  String get safeBusinessUseLabel => _cleanText(businessUseLabel);

  String get safeNotes => _cleanText(notes);
}

class AppReceiptPdfRenderer {
  const AppReceiptPdfRenderer();

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
          _lineTable(data),
          pw.SizedBox(height: 12),
          _totals(data),
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

  pw.Widget _lineTable(AppReceiptPdfData data) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      headers: const ['Item', 'Category', 'Qty', 'Total'],
      data: [
        for (final line in data.lines)
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

String _cleanText(String value) {
  return value
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
