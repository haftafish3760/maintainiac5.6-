import 'dart:io';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/document_engine/document_engine_core.dart';
import 'invoice_ledger_models.dart';
import 'invoice_pdf_export_verifier.dart';
import 'invoice_pdf_privacy_guard.dart';
import 'invoice_record.dart';
import 'invoice_template_catalog.dart';

part 'invoice_pdf_content_rules.dart';
part 'invoice_pdf_pagination.dart';

int invoicePdfPageCountForRecord(
  InvoiceRecord record, {
  InvoiceTemplateDefinition? template,
}) {
  return _InvoicePaginator(
    record,
    fixedLineCapacity: template != null && _usesLandscapeArtwork(template)
        ? 7
        : null,
  ).pages.length;
}

class InvoicePdfContentException implements Exception {
  const InvoicePdfContentException(this.issues);

  final List<String> issues;

  String get message => InvoicePdfTemplateRenderer.contentIssueMessage(issues);

  @override
  String toString() {
    return message;
  }
}

class InvoicePdfTemplateRenderer {
  const InvoicePdfTemplateRenderer();

  static const missingLineItems = InvoicePdfContentRules.missingLineItems;
  static const blankLineItem = InvoicePdfContentRules.blankLineItem;
  static const missingInvoiceNumber =
      InvoicePdfContentRules.missingInvoiceNumber;
  static const missingCompanyName = InvoicePdfContentRules.missingCompanyName;
  static const missingClientName = InvoicePdfContentRules.missingClientName;
  static const dueDateBeforeIssueDate =
      InvoicePdfContentRules.dueDateBeforeIssueDate;
  static const nonFiniteLineQuantity =
      InvoicePdfContentRules.nonFiniteLineQuantity;
  static const nonFiniteLineUnitPrice =
      InvoicePdfContentRules.nonFiniteLineUnitPrice;
  static const nonFiniteLineTaxRate =
      InvoicePdfContentRules.nonFiniteLineTaxRate;
  static const negativeLineTaxRate = InvoicePdfContentRules.negativeLineTaxRate;
  static const nonFiniteDiscountValue =
      InvoicePdfContentRules.nonFiniteDiscountValue;
  static const negativeDiscountValue =
      InvoicePdfContentRules.negativeDiscountValue;
  static const excessiveDiscountPercent =
      InvoicePdfContentRules.excessiveDiscountPercent;
  static const excessiveDiscountAmount =
      InvoicePdfContentRules.excessiveDiscountAmount;
  static const nonFinitePaymentAmount =
      InvoicePdfContentRules.nonFinitePaymentAmount;

  Future<Uint8List> buildDocumentBytes({
    required DateTime createdAt,
    required String title,
    required String documentNumber,
    required String totalLabel,
    required InvoiceTemplateDefinition template,
  }) async {
    final record = _sampleRecord(
      createdAt: createdAt,
      title: title,
      documentNumber: documentNumber,
      totalLabel: totalLabel,
      template: template,
    );
    return buildRecordDocumentBytes(record: record, template: template);
  }

  Future<Uint8List> buildRecordDocumentBytes({
    required InvoiceRecord record,
    required InvoiceTemplateDefinition template,
    AppPdfPageSpec? pageSpecOverride,
  }) async {
    _ensureRenderableRecord(record);
    InvoicePdfPrivacyGuard.ensureRecordCanExport(record);
    final pdf = pw.Document();
    final chunks = _InvoicePaginator(
      record,
      fixedLineCapacity: _usesLandscapeArtwork(template) ? 7 : null,
    ).pages;
    final artwork = await _InvoiceTemplateArtwork.load(template);
    final logo = await _InvoiceLogoImage.load(record.company.logoPath);
    final pdfTheme = await AppPdfTypography.loadTheme();
    for (var index = 0; index < chunks.length; index++) {
      final page = chunks[index];
      final pageSpec = pageSpecOverride ?? _pageSpecForTemplate(template);
      pdf.addPage(
        pw.Page(
          pageFormat: pageSpec.format,
          theme: pdfTheme,
          margin: pw.EdgeInsets.zero,
          build: (context) => pw.Stack(
            children: [
              _background(template, pageRole: page.role, artwork: artwork),
              if (_usesLandscapeArtwork(template))
                _landscapeArtworkBody(
                  record: record,
                  page: page,
                  pageNumber: index + 1,
                  pageCount: chunks.length,
                  template: template,
                  logo: logo,
                )
              else
                pw.Padding(
                  padding: const pw.EdgeInsets.fromLTRB(42, 34, 42, 34),
                  child: _documentBody(
                    record: record,
                    page: page,
                    pageNumber: index + 1,
                    pageCount: chunks.length,
                    template: template,
                    logo: logo,
                  ),
                ),
            ],
          ),
        ),
      );
    }
    final bytes = AppPdfDeterminism.normalizeDocumentId(
      await pdf.save(),
      [
        'invoice-template-v1',
        template.id,
        record.documentType.name,
        record.invoiceNumber,
        record.issueDate.toIso8601String(),
        record.dueDate?.toIso8601String() ?? '',
        record.company.bestName,
        record.client.bestName,
        record.lines
            .map(
              (line) => [
                line.name,
                line.details,
                line.quantity,
                line.unit,
                line.unitPrice,
                line.taxRate,
              ].join('|'),
            )
            .join('||'),
        record.discountAmount,
        record.paidTotal,
        record.terms,
      ].join('\n'),
    );
    InvoicePdfExportVerifier.ensureSafeExport(
      record: record,
      template: template,
      bytes: bytes,
    );
    return bytes;
  }

  static List<String> contentIssueCodesForRecord(InvoiceRecord record) {
    return InvoicePdfContentRules.issueCodesForRecord(record);
  }

  static void _ensureRenderableRecord(InvoiceRecord record) {
    final issues = contentIssueCodesForRecord(record);
    if (issues.isEmpty) return;
    throw InvoicePdfContentException(issues);
  }

  static String contentIssueMessage(Iterable<String> issues) {
    return InvoicePdfContentRules.messageFor(issues);
  }

  pw.Widget _landscapeArtworkBody({
    required InvoiceRecord record,
    required _InvoicePageLines page,
    required int pageNumber,
    required int pageCount,
    required InvoiceTemplateDefinition template,
    _InvoiceLogoImage? logo,
  }) {
    final companyLines = _partyLines(
      record.company,
      fallbackName: 'My Company',
    );
    final clientLines = _partyLines(record.client, fallbackName: 'Customer');
    final visibleLines = page.lines.take(7).toList(growable: false);
    return pw.Stack(
      children: [
        if (logo != null)
          pw.Positioned(
            left: 88,
            top: 78,
            child: pw.Container(
              width: 52,
              height: 38,
              child: pw.Image(logo.image, fit: pw.BoxFit.contain),
            ),
          )
        else
          pw.Positioned(
            left: 92,
            top: 82,
            child: _artworkText(
              _companyInitials(record.company.bestName),
              fontSize: 24,
              bold: true,
              color: const PdfColor(0.16, 0.30, 0.15),
              width: 46,
              align: pw.TextAlign.center,
            ),
          ),
        pw.Positioned(
          left: 80,
          top: 125,
          child: _artworkLines(
            companyLines,
            width: 160,
            fontSize: 6.8,
            maxLines: 7,
            align: pw.TextAlign.center,
          ),
        ),
        pw.Positioned(
          left: 362,
          top: 124,
          child: _artworkLines(
            [
              'No. ${record.invoiceNumber}',
              'Date ${_date(record.issueDate)}',
              if (record.dueDate != null) 'Due ${_date(record.dueDate!)}',
              if (pageCount > 1) 'Page $pageNumber of $pageCount',
            ],
            width: 190,
            fontSize: 8.5,
            maxLines: 4,
          ),
        ),
        pw.Positioned(
          left: 74,
          top: 245,
          child: _artworkLines(
            clientLines,
            width: 238,
            fontSize: 8.2,
            maxLines: 6,
          ),
        ),
        pw.Positioned(
          left: 66,
          top: 390,
          child: pw.Column(
            children: [
              for (var index = 0; index < 7; index++)
                _landscapeArtworkLineRow(
                  index < visibleLines.length ? visibleLines[index] : null,
                ),
            ],
          ),
        ),
        if (page.role == _InvoicePageRole.finalPage) ...[
          pw.Positioned(
            left: 68,
            top: 602,
            child: _artworkLines(
              [
                if (record.terms.trim().isEmpty)
                  'Payment due according to the terms shown on this document.'
                else
                  record.terms.trim(),
              ],
              width: 248,
              fontSize: 7.2,
              maxLines: 4,
            ),
          ),
          pw.Positioned(
            left: 446,
            top: 596,
            child: _artworkLines(
              [
                _money(record.subtotal),
                _money(record.taxTotal),
                _money(record.balanceDue),
              ],
              width: 92,
              fontSize: 11,
              maxLines: 3,
              align: pw.TextAlign.right,
              lineGap: 18,
            ),
          ),
        ] else
          pw.Positioned(
            left: 386,
            top: 608,
            child: _artworkText(
              'Continued on next page',
              width: 150,
              fontSize: 9,
              bold: true,
              color: const PdfColor(0.13, 0.30, 0.16),
              align: pw.TextAlign.right,
            ),
          ),
      ],
    );
  }

  pw.Widget _landscapeArtworkLineRow(InvoiceLineItemRecord? line) {
    final top = line == null
        ? ['', '', '', '']
        : [
            line.name.trim().isEmpty ? 'Item' : line.name.trim(),
            _quantity(line.quantity),
            _money(line.unitPrice),
            _money(line.total),
          ];
    final details = line?.details.trim() ?? '';
    return pw.Container(
      width: 470,
      height: 25,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 258,
            padding: const pw.EdgeInsets.only(top: 3),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _artworkText(top[0], width: 242, fontSize: 7.5, bold: true),
                if (details.isNotEmpty)
                  _artworkText(
                    details,
                    width: 242,
                    fontSize: 5.8,
                    color: PdfColors.grey800,
                  ),
              ],
            ),
          ),
          pw.Container(
            width: 68,
            padding: const pw.EdgeInsets.only(top: 5),
            child: _artworkText(top[1], width: 56, fontSize: 7.2),
          ),
          pw.Container(
            width: 67,
            padding: const pw.EdgeInsets.only(top: 5),
            child: _artworkText(
              top[2],
              width: 58,
              fontSize: 7.2,
              align: pw.TextAlign.right,
            ),
          ),
          pw.Container(
            width: 74,
            padding: const pw.EdgeInsets.only(top: 5),
            child: _artworkText(
              top[3],
              width: 66,
              fontSize: 7.2,
              bold: true,
              align: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _artworkLines(
    List<String> lines, {
    required double width,
    required double fontSize,
    int maxLines = 5,
    double lineGap = 2.2,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Column(
      crossAxisAlignment: align == pw.TextAlign.right
          ? pw.CrossAxisAlignment.end
          : align == pw.TextAlign.center
          ? pw.CrossAxisAlignment.center
          : pw.CrossAxisAlignment.start,
      children: [
        for (final line
            in lines
                .where((line) => line.trim().isNotEmpty)
                .take(maxLines)) ...[
          _artworkText(line, width: width, fontSize: fontSize, align: align),
          pw.SizedBox(height: lineGap),
        ],
      ],
    );
  }

  pw.Widget _artworkText(
    String value, {
    required double width,
    required double fontSize,
    bool bold = false,
    PdfColor color = PdfColors.grey900,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      width: width,
      child: pw.Text(
        value,
        maxLines: 1,
        overflow: pw.TextOverflow.span,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _documentBody({
    required InvoiceRecord record,
    required _InvoicePageLines page,
    required int pageNumber,
    required int pageCount,
    required InvoiceTemplateDefinition template,
    _InvoiceLogoImage? logo,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _header(
          record: record,
          pageNumber: pageNumber,
          pageCount: pageCount,
          template: template,
          logo: logo,
        ),
        if (page.role == _InvoicePageRole.first) ...[
          pw.SizedBox(height: 24),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _infoBlock(
                  title: 'From',
                  lines: _partyLines(
                    record.company,
                    fallbackName: 'My Company',
                  ),
                  template: template,
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: _infoBlock(
                  title: 'Bill To',
                  lines: _partyLines(record.client, fallbackName: 'Customer'),
                  template: template,
                ),
              ),
            ],
          ),
        ] else
          pw.SizedBox(height: 16),
        pw.SizedBox(height: page.role == _InvoicePageRole.first ? 22 : 12),
        _lineItems(template: template, lines: page.lines),
        if (page.role == _InvoicePageRole.finalPage) ...[
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _terms(record, template)),
              pw.SizedBox(width: 24),
              pw.Container(
                width: 210,
                child: _totals(record: record, template: template),
              ),
            ],
          ),
          pw.Spacer(),
          _signatureArea(template),
        ] else ...[
          pw.Spacer(),
          _continuationFooter(template),
        ],
      ],
    );
  }

  pw.Widget _header({
    required InvoiceRecord record,
    required int pageNumber,
    required int pageCount,
    required InvoiceTemplateDefinition template,
    _InvoiceLogoImage? logo,
  }) {
    final title = record.isEstimate ? 'Estimate' : 'Invoice';
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (template.hasLogo) ...[
              _logoBlock(record: record, template: template, logo: logo),
              pw.SizedBox(width: 12),
            ],
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  record.company.bestName.isEmpty
                      ? 'My Company'
                      : record.company.bestName,
                  maxLines: 1,
                  overflow: pw.TextOverflow.span,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  record.title.trim().isEmpty
                      ? 'Service document'
                      : record.title.trim(),
                  maxLines: 1,
                  overflow: pw.TextOverflow.span,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.Container(
          width: 180,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: template.accent, width: 1.2),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                title.toUpperCase(),
                style: pw.TextStyle(
                  color: template.accent,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              _singleLine('No. ${record.invoiceNumber}'),
              _singleLine('Date ${_date(record.issueDate)}'),
              if (record.dueDate != null)
                _singleLine('Due ${_date(record.dueDate!)}'),
              if (pageCount > 1) _singleLine('Page $pageNumber of $pageCount'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _logoBlock({
    required InvoiceRecord record,
    required InvoiceTemplateDefinition template,
    required _InvoiceLogoImage? logo,
  }) {
    if (logo != null) {
      return pw.Container(
        width: 54,
        height: 54,
        padding: const pw.EdgeInsets.all(4),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: _softBorder(template), width: 1),
        ),
        child: pw.Image(logo.image, fit: pw.BoxFit.contain),
      );
    }
    return pw.Container(
      width: 54,
      height: 54,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: template.accent,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Text(
        _companyInitials(record.company.bestName),
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _infoBlock({
    required String title,
    required List<String> lines,
    required InvoiceTemplateDefinition template,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _softFill(template),
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: _softBorder(template)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: template.accent,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          for (final line in lines)
            pw.Text(
              line,
              maxLines: 1,
              overflow: pw.TextOverflow.span,
              style: const pw.TextStyle(fontSize: 9.5),
            ),
        ],
      ),
    );
  }

  pw.Widget _lineItems({
    required InvoiceTemplateDefinition template,
    required List<InvoiceLineItemRecord> lines,
  }) {
    return pw.Table(
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(
          color: _softBorder(template),
          width: .5,
        ),
        bottom: pw.BorderSide(color: _softBorder(template), width: .8),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1.25),
        4: pw.FlexColumnWidth(1.4),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: template.accent),
          children: [
            _cell('Item', header: true),
            _cell('Qty', header: true),
            _cell('Unit', header: true),
            _cell('Rate', header: true),
            _cell('Total', header: true),
          ],
        ),
        if (lines.isEmpty)
          pw.TableRow(
            children: [
              _cell('No line items yet'),
              _cell(''),
              _cell(''),
              _cell(''),
              _cell(''),
            ],
          )
        else
          for (final line in lines)
            pw.TableRow(
              children: [
                _itemCell(line),
                _cell(_quantity(line.quantity)),
                _cell(line.unit),
                _cell(_money(line.unitPrice)),
                _cell(_money(line.total)),
              ],
            ),
      ],
    );
  }

  pw.Widget _itemCell(InvoiceLineItemRecord line) {
    final details = line.details.trim();
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            line.name.trim().isEmpty ? 'Item' : line.name.trim(),
            maxLines: 1,
            overflow: pw.TextOverflow.span,
            style: pw.TextStyle(
              color: PdfColors.grey900,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (details.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              details,
              maxLines: 2,
              overflow: pw.TextOverflow.span,
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _cell(String value, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      child: pw.Text(
        value,
        maxLines: 1,
        overflow: pw.TextOverflow.span,
        style: pw.TextStyle(
          color: header ? PdfColors.white : PdfColors.grey900,
          fontSize: header ? 9.5 : 9,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _terms(InvoiceRecord record, InvoiceTemplateDefinition template) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _softBorder(template)),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Terms',
            style: pw.TextStyle(
              color: template.accent,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            record.terms.trim().isEmpty
                ? 'Payment due according to the terms shown on this document. Signing confirms customer approval of the listed price and scope.'
                : record.terms.trim(),
            maxLines: 6,
            overflow: pw.TextOverflow.span,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
          ),
        ],
      ),
    );
  }

  pw.Widget _totals({
    required InvoiceRecord record,
    required InvoiceTemplateDefinition template,
  }) {
    return pw.Column(
      children: [
        _totalRow('Subtotal', _money(record.subtotal)),
        _totalRow('Discount', '-${_money(record.discountAmount)}'),
        _totalRow('Tax', _money(record.taxTotal)),
        if (record.paidTotal > 0)
          _totalRow('Paid', '-${_money(record.paidTotal)}'),
        pw.Container(
          height: 1,
          margin: const pw.EdgeInsets.symmetric(vertical: 7),
          color: template.accent,
        ),
        _totalRow(
          record.paidTotal > 0 ? 'Balance' : 'Total',
          _money(record.balanceDue),
          emphasized: true,
          template: template,
        ),
      ],
    );
  }

  pw.Widget _totalRow(
    String label,
    String value, {
    bool emphasized = false,
    InvoiceTemplateDefinition? template,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            maxLines: 1,
            overflow: pw.TextOverflow.span,
            style: pw.TextStyle(
              fontSize: emphasized ? 12 : 9,
              fontWeight: emphasized
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            maxLines: 1,
            overflow: pw.TextOverflow.span,
            style: pw.TextStyle(
              color: emphasized ? template?.accent : PdfColors.grey900,
              fontSize: emphasized ? 15 : 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _signatureArea(InvoiceTemplateDefinition template) {
    return pw.Row(
      children: [
        pw.Expanded(child: _signatureLine('Authorized Signature', template)),
        pw.SizedBox(width: 22),
        pw.Expanded(child: _signatureLine('Customer Signature', template)),
      ],
    );
  }

  pw.Widget _signatureLine(String label, InvoiceTemplateDefinition template) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(height: 1.2, color: template.accent),
        pw.SizedBox(height: 5),
        _singleLine(label, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  pw.Widget _continuationFooter(InvoiceTemplateDefinition template) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Continued on next page',
        maxLines: 1,
        overflow: pw.TextOverflow.span,
        style: pw.TextStyle(
          color: template.accent,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  pw.Widget _background(
    InvoiceTemplateDefinition template, {
    required _InvoicePageRole pageRole,
    required _InvoiceTemplateArtwork artwork,
  }) {
    final image = artwork.imageFor(pageRole);
    if (image != null) {
      return pw.Stack(
        children: [
          pw.Container(color: _pageTint(template)),
          pw.Positioned.fill(
            child: pw.Opacity(
              opacity: _usesLandscapeArtwork(template) ? 1 : .34,
              child: pw.Image(image, fit: pw.BoxFit.cover),
            ),
          ),
          if (pageRole == _InvoicePageRole.continuation)
            pw.Positioned(
              right: 42,
              top: 34,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: _softBorder(template)),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Continuation',
                  style: pw.TextStyle(
                    color: template.accent,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    final svg = artwork.svgFor(pageRole);
    if (svg != null) {
      return pw.Stack(
        children: [
          pw.Container(color: _pageTint(template)),
          pw.Positioned(
            left: 0,
            top: 0,
            right: 0,
            bottom: 0,
            child: pw.Opacity(
              opacity: .38,
              child: pw.SvgImage(svg: svg, fit: pw.BoxFit.cover),
            ),
          ),
          if (pageRole == _InvoicePageRole.continuation)
            pw.Positioned(
              right: 42,
              top: 34,
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: _softBorder(template)),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Continuation',
                  style: pw.TextStyle(
                    color: template.accent,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    if (template.id == 'printer-friendly') return pw.Container();
    return pw.Stack(
      children: [
        pw.Container(color: _pageTint(template)),
        if (template.industry == InvoiceTemplateIndustry.plumbing)
          _watermarkPattern(
            labels: const ['PVC 90', 'TEE', 'COUPLING', 'VALVE', 'PIPE'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.electrical)
          _watermarkPattern(
            labels: const ['WIRE', 'BREAKER', 'OUTLET', 'GFCI', 'PANEL'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.hvac)
          _watermarkPattern(
            labels: const ['AIR', 'FILTER', 'DUCT', 'VENT', 'LINE SET'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.carpentry)
          _watermarkPattern(
            labels: const ['LUMBER', 'TRIM', 'FASTENER', 'CUT', 'FRAME'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.flooring)
          _watermarkPattern(
            labels: const ['PLANK', 'TRIM', 'UNDERLAY', 'TRANSITION', 'FLOOR'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.excavation)
          _watermarkPattern(
            labels: const ['GRADE', 'TRENCH', 'MINI EX', 'SILT', 'STONE'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.landscaping)
          _watermarkPattern(
            labels: const ['LAWN', 'BED EDGE', 'MULCH', 'PLANT', 'SEED'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.lawnCare)
          _watermarkPattern(
            labels: const ['MOW', 'EDGE', 'TRIM', 'SEED', 'LAWN'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.masonry)
          _watermarkPattern(
            labels: const ['BRICK', 'BLOCK', 'MORTAR', 'WALL', 'STONE'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.roofing)
          _watermarkPattern(
            labels: const ['ROOF', 'SHINGLE', 'FLASHING', 'VENT', 'RIDGE'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.painting)
          _watermarkPattern(
            labels: const ['PAINT', 'TRIM', 'WALL', 'PRIMER', 'FINISH'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.cleaning)
          _watermarkPattern(
            labels: const ['CLEAN', 'DETAIL', 'SUPPLY', 'SERVICE', 'FINISH'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.mobileMechanic)
          _watermarkPattern(
            labels: const ['PARTS', 'LABOR', 'REPAIR', 'DIAG', 'SERVICE'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.towing)
          _watermarkPattern(
            labels: const ['TOW', 'ROAD', 'HOOK', 'MILES', 'SERVICE'],
            template: template,
          ),
        if (template.industry == InvoiceTemplateIndustry.handyman)
          _watermarkPattern(
            labels: const ['TOOLS', 'REPAIR', 'LABOR', 'PARTS', 'SERVICE'],
            template: template,
          ),
        pw.Positioned(
          right: -40,
          bottom: pageRole == _InvoicePageRole.continuation ? -90 : -40,
          child: pw.Container(
            width: 220,
            height: 220,
            decoration: pw.BoxDecoration(
              color: _paleAccent(template),
              borderRadius: pw.BorderRadius.circular(110),
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _watermarkPattern({
    required List<String> labels,
    required InvoiceTemplateDefinition template,
  }) {
    return pw.Positioned(
      left: 0,
      top: 0,
      right: 0,
      bottom: 0,
      child: pw.Padding(
        padding: const pw.EdgeInsets.fromLTRB(14, 92, 14, 80),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            for (var row = 0; row < 5; row++)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  for (var col = 0; col < 3; col++)
                    pw.Text(
                      labels[(row + col) % labels.length],
                      style: pw.TextStyle(
                        color: _paleAccent(template),
                        fontSize: row.isEven ? 28 : 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

pw.Widget _singleLine(String value, {pw.TextStyle? style}) {
  return pw.Text(
    value,
    maxLines: 1,
    overflow: pw.TextOverflow.span,
    style: style,
  );
}

bool _usesLandscapeArtwork(InvoiceTemplateDefinition template) {
  return _pageSpecForTemplate(template).isLandscape;
}

AppPdfPageSpec _pageSpecForTemplate(InvoiceTemplateDefinition template) {
  if (template.id == 'landscaping-garden-artwork-v1') {
    return AppPdfPageSpec.letterLandscape;
  }
  return AppPdfPageSpec.letterPortrait;
}

class _InvoiceTemplateArtwork {
  const _InvoiceTemplateArtwork({
    this.firstPageSvg,
    this.continuationPageSvg,
    this.firstPageImage,
    this.continuationPageImage,
  });

  final String? firstPageSvg;
  final String? continuationPageSvg;
  final pw.MemoryImage? firstPageImage;
  final pw.MemoryImage? continuationPageImage;

  static Future<_InvoiceTemplateArtwork> load(
    InvoiceTemplateDefinition template,
  ) async {
    final firstPath = template.assetForPage(continuation: false);
    final continuationPath = template.assetForPage(continuation: true);
    return _InvoiceTemplateArtwork(
      firstPageSvg: await _loadSanitizedSvg(firstPath),
      continuationPageSvg: continuationPath == firstPath
          ? null
          : await _loadSanitizedSvg(continuationPath),
      firstPageImage: await _loadImage(firstPath),
      continuationPageImage: continuationPath == firstPath
          ? null
          : await _loadImage(continuationPath),
    );
  }

  String? svgFor(_InvoicePageRole role) {
    if (role == _InvoicePageRole.continuation) {
      return continuationPageSvg ?? firstPageSvg;
    }
    return firstPageSvg;
  }

  pw.MemoryImage? imageFor(_InvoicePageRole role) {
    if (role == _InvoicePageRole.continuation) {
      return continuationPageImage ?? firstPageImage;
    }
    return firstPageImage;
  }

  static Future<pw.MemoryImage?> _loadImage(String? assetPath) async {
    if (assetPath == null || !_isSupportedImageAsset(assetPath)) return null;
    try {
      final data = await rootBundle.load(assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _loadSanitizedSvg(String? assetPath) async {
    if (assetPath == null || !assetPath.endsWith('.svg')) return null;
    try {
      final raw = await rootBundle.loadString(assetPath);
      return _stripBakedTemplateText(raw);
    } catch (_) {
      return null;
    }
  }

  static String _stripBakedTemplateText(String svg) {
    return svg
        .replaceAll(RegExp(r'<text\b[^>]*>.*?</text>', dotAll: true), '')
        .replaceAll(RegExp(r'<tspan\b[^>]*>.*?</tspan>', dotAll: true), '');
  }

  static bool _isSupportedImageAsset(String assetPath) {
    final lower = assetPath.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }
}

class _InvoiceLogoImage {
  const _InvoiceLogoImage(this.image);

  final pw.MemoryImage image;

  static Future<_InvoiceLogoImage?> load(String logoPath) async {
    final trimmed = logoPath.trim();
    if (trimmed.isEmpty || !_isSupportedImagePath(trimmed)) return null;
    try {
      final file = File(trimmed);
      if (!await file.exists()) return null;
      return _InvoiceLogoImage(pw.MemoryImage(await file.readAsBytes()));
    } catch (_) {
      return null;
    }
  }

  static bool _isSupportedImagePath(String filePath) {
    final lower = filePath.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg');
  }
}

String _date(DateTime day) => AppPdfFormatters.date(day);

String _companyInitials(String companyName) {
  final words = companyName
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return 'M';
  final initials = words.take(2).map((word) => word[0].toUpperCase()).join();
  return initials.isEmpty ? 'M' : initials;
}

PdfColor _pageTint(InvoiceTemplateDefinition template) {
  return switch (template.industry) {
    InvoiceTemplateIndustry.plumbing => const PdfColor(0.985, 0.973, 0.945),
    InvoiceTemplateIndustry.electrical => const PdfColor(0.965, 0.975, 1),
    InvoiceTemplateIndustry.hvac => const PdfColor(0.945, 0.990, 1),
    InvoiceTemplateIndustry.carpentry => const PdfColor(1, 0.972, 0.935),
    InvoiceTemplateIndustry.flooring => const PdfColor(1, 0.972, 0.935),
    InvoiceTemplateIndustry.excavation => const PdfColor(0.985, 0.976, 0.955),
    InvoiceTemplateIndustry.landscaping => const PdfColor(0.965, 0.985, 0.965),
    InvoiceTemplateIndustry.lawnCare => const PdfColor(0.965, 0.985, 0.965),
    InvoiceTemplateIndustry.masonry => const PdfColor(1, 0.955, 0.945),
    InvoiceTemplateIndustry.roofing => const PdfColor(0.962, 0.972, 0.982),
    InvoiceTemplateIndustry.painting => const PdfColor(0.980, 0.965, 0.995),
    InvoiceTemplateIndustry.cleaning => const PdfColor(0.955, 0.990, 1),
    InvoiceTemplateIndustry.mobileMechanic => const PdfColor(
      0.995,
      0.955,
      0.945,
    ),
    InvoiceTemplateIndustry.towing => const PdfColor(1, 0.980, 0.940),
    InvoiceTemplateIndustry.handyman => const PdfColor(0.965, 0.980, 0.990),
    InvoiceTemplateIndustry.general => const PdfColor(0.982, 0.986, 0.988),
  };
}

PdfColor _softFill(InvoiceTemplateDefinition template) {
  if (template.id == 'printer-friendly') return PdfColors.white;
  return switch (template.industry) {
    InvoiceTemplateIndustry.plumbing => const PdfColor(1, 0.992, 0.975),
    InvoiceTemplateIndustry.electrical => const PdfColor(0.975, 0.985, 1),
    InvoiceTemplateIndustry.hvac => const PdfColor(0.972, 0.995, 1),
    InvoiceTemplateIndustry.carpentry => const PdfColor(1, 0.987, 0.965),
    InvoiceTemplateIndustry.flooring => const PdfColor(1, 0.987, 0.965),
    InvoiceTemplateIndustry.excavation => const PdfColor(1, 0.993, 0.98),
    InvoiceTemplateIndustry.landscaping => const PdfColor(0.985, 1, 0.985),
    InvoiceTemplateIndustry.lawnCare => const PdfColor(0.985, 1, 0.985),
    InvoiceTemplateIndustry.masonry => const PdfColor(1, 0.980, 0.970),
    InvoiceTemplateIndustry.roofing => const PdfColor(0.982, 0.988, 0.994),
    InvoiceTemplateIndustry.painting => const PdfColor(0.992, 0.985, 1),
    InvoiceTemplateIndustry.cleaning => const PdfColor(0.975, 0.995, 1),
    InvoiceTemplateIndustry.mobileMechanic => const PdfColor(1, 0.976, 0.970),
    InvoiceTemplateIndustry.towing => const PdfColor(1, 0.992, 0.970),
    InvoiceTemplateIndustry.handyman => const PdfColor(0.982, 0.992, 1),
    InvoiceTemplateIndustry.general => const PdfColor(0.975, 0.982, 0.988),
  };
}

PdfColor _softBorder(InvoiceTemplateDefinition template) {
  if (template.id == 'printer-friendly') return PdfColors.grey500;
  return const PdfColor(0.78, 0.80, 0.82);
}

PdfColor _paleAccent(InvoiceTemplateDefinition template) {
  return switch (template.industry) {
    InvoiceTemplateIndustry.plumbing => const PdfColor(0.91, 0.78, 0.66),
    InvoiceTemplateIndustry.electrical => const PdfColor(0.74, 0.82, 0.96),
    InvoiceTemplateIndustry.hvac => const PdfColor(0.70, 0.90, 0.94),
    InvoiceTemplateIndustry.carpentry => const PdfColor(0.90, 0.78, 0.64),
    InvoiceTemplateIndustry.flooring => const PdfColor(0.90, 0.78, 0.64),
    InvoiceTemplateIndustry.excavation => const PdfColor(0.88, 0.80, 0.66),
    InvoiceTemplateIndustry.landscaping => const PdfColor(0.74, 0.88, 0.74),
    InvoiceTemplateIndustry.lawnCare => const PdfColor(0.74, 0.88, 0.74),
    InvoiceTemplateIndustry.masonry => const PdfColor(0.88, 0.70, 0.66),
    InvoiceTemplateIndustry.roofing => const PdfColor(0.74, 0.78, 0.84),
    InvoiceTemplateIndustry.painting => const PdfColor(0.82, 0.72, 0.90),
    InvoiceTemplateIndustry.cleaning => const PdfColor(0.70, 0.88, 0.94),
    InvoiceTemplateIndustry.mobileMechanic => const PdfColor(0.90, 0.68, 0.62),
    InvoiceTemplateIndustry.towing => const PdfColor(0.90, 0.76, 0.50),
    InvoiceTemplateIndustry.handyman => const PdfColor(0.72, 0.82, 0.88),
    InvoiceTemplateIndustry.general => const PdfColor(0.82, 0.88, 0.93),
  };
}

List<String> _partyLines(
  InvoicePartySnapshot party, {
  required String fallbackName,
}) {
  final lines = <String>[
    if (party.bestName.isNotEmpty) party.bestName else fallbackName,
    if (party.street.trim().isNotEmpty) party.street.trim(),
    if ([
      party.city,
      party.state,
      party.postalCode,
    ].any((value) => value.trim().isNotEmpty))
      [
        if (party.city.trim().isNotEmpty) party.city.trim(),
        if (party.state.trim().isNotEmpty) party.state.trim(),
        if (party.postalCode.trim().isNotEmpty) party.postalCode.trim(),
      ].join(' '),
    ...party.phoneDisplayLines,
    if (party.email.trim().isNotEmpty) party.email.trim(),
    if (party.website.trim().isNotEmpty) party.website.trim(),
  ];
  return lines;
}

String _money(num value) => AppPdfFormatters.money(value);

String _quantity(num value) => AppPdfFormatters.quantity(value);

InvoiceRecord _sampleRecord({
  required DateTime createdAt,
  required String title,
  required String documentNumber,
  required String totalLabel,
  required InvoiceTemplateDefinition template,
}) {
  final parsedTotal =
      double.tryParse(totalLabel.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1247.62;
  return InvoiceRecord(
    id: 'sample-${template.id}',
    documentType: title.toLowerCase().contains('estimate')
        ? InvoiceDocumentType.estimate
        : InvoiceDocumentType.invoice,
    invoiceNumber: documentNumber,
    numberMode: InvoiceNumberMode.automatic,
    status: InvoiceRecordStatus.draft,
    title: 'Service sample',
    issueDate: createdAt,
    dueDate: createdAt.add(const Duration(days: 30)),
    templateId: template.id,
    company: const InvoicePartySnapshot(
      displayName: 'Jane Doe Services',
      street: '1234 Main Street',
      city: 'Lynchburg',
      state: 'VA',
      postalCode: '24502',
      phone: '(555) 123-5512',
      email: 'janedoe@example.com',
      website: 'example.com',
    ),
    client: const InvoicePartySnapshot(
      displayName: 'Alex Customer',
      street: '987 Oak Ridge Road',
      city: 'Forest',
      state: 'VA',
      postalCode: '24551',
      email: 'alex@example.com',
    ),
    lines: [
      const InvoiceLineItemRecord(
        id: 'labor',
        name: 'Service labor',
        quantity: 4,
        unit: 'hr',
        unitPrice: 85,
        taxable: false,
      ),
      const InvoiceLineItemRecord(
        id: 'materials',
        name: 'Materials from inventory',
        details: 'Receipt-linked supplies used on the job',
        quantity: 12,
        unit: 'ea',
        unitPrice: 18.75,
        taxRate: 5.25,
      ),
      const InvoiceLineItemRecord(
        id: 'trip',
        name: 'Trip / service call',
        quantity: 1,
        unit: 'ea',
        unitPrice: 55,
        taxable: false,
      ),
      InvoiceLineItemRecord(
        id: 'flat',
        name: template.billingStyle == InvoiceBillingStyle.flatRate
            ? 'Flat rate job price'
            : 'Disposal / cleanup',
        quantity: 1,
        unit: 'ea',
        unitPrice: template.billingStyle == InvoiceBillingStyle.flatRate
            ? parsedTotal
            : 45,
        taxable: false,
      ),
    ],
    discount: const InvoiceDiscountRecord(
      type: InvoiceDiscountType.amount,
      value: 25,
    ),
    terms:
        'Payment due within 7 days of invoice date. Signing confirms customer approval of the listed price and scope.',
    meta: InvoiceSyncMetadata(createdAt: createdAt, updatedAt: createdAt),
  );
}
