import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfTortureFixtures {
  PdfTortureFixtures._(this.root, this.files);

  final Directory root;
  final Map<String, File> files;

  static Future<PdfTortureFixtures> create() async {
    final root = await Directory.systemTemp.createTemp('pdf_torture_');
    final files = <String, File>{};

    Future<File> add(String key, String name, Future<List<int>> bytes) async {
      final file = File('${root.path}/$name');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(await bytes, flush: true);
      files[key] = file;
      return file;
    }

    Future<File> addText(String key, String name, String text) async {
      final file = File('${root.path}/$name');
      await file.parent.create(recursive: true);
      await file.writeAsString(text, flush: true);
      files[key] = file;
      return file;
    }

    await add('valid_1_page', 'simple_receipt_1_page.pdf', _receiptPdf(1));
    await add('valid_3_page', 'receipt_3_pages.pdf', _receiptPdf(3));
    await add('valid_10_page', 'receipt_10_pages.pdf', _receiptPdf(10));
    await add('valid_20_page', 'receipt_20_pages.pdf', _receiptPdf(20));
    await add('document_50_page', 'document_50_pages.pdf', _receiptPdf(50));
    await add('blank_pages', 'blank_pages_receipt.pdf', _blankPdf(3));
    await add('rotated_pages', 'rotated_pages_receipt.pdf', _rotatedPdf());
    await add('landscape_pages', 'landscape_receipt.pdf', _landscapePdf());
    await add(
      'long_filename',
      'this_is_a_very_long_receipt_filename_from_a_vendor_counter_that_should_still_import_safely_without_breaking_storage_or_preview_2026_06_14.pdf',
      _receiptPdf(1),
    );
    await add(
      'special_filename',
      'Receipt #42 - Lowe’s @ job_A (paid) [copy].pdf',
      _receiptPdf(1),
    );

    await File(
      '${root.path}/zero_byte.pdf',
    ).writeAsBytes(const [], flush: true);
    files['zero_byte'] = File('${root.path}/zero_byte.pdf');
    await addText('txt_renamed_pdf', 'plain_text_renamed.pdf', 'not a pdf');
    await add(
      'image_renamed_pdf',
      'image_renamed.pdf',
      Future.value(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
    );
    await addText(
      'corrupted_pdf',
      'corrupted.pdf',
      '%PDF-1.7\n1 0 obj << /Type /Page >> stream broken',
    );
    await addText(
      'truncated_pdf',
      'partially_truncated.pdf',
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n',
    );
    await addText(
      'invalid_header',
      'invalid_header.pdf',
      'PDF-1.7 without the percent header',
    );
    await addText(
      'no_pages',
      'no_pages.pdf',
      '%PDF-1.7\n1 0 obj << /Type /Pages /Count 0 /Kids [] >> endobj\n%%EOF',
    );
    await addText(
      'password_marker',
      'password_marker.pdf',
      '%PDF-1.7\n1 0 obj << /Type /Page >> endobj\ntrailer << /Encrypt 2 0 R >>\n%%EOF',
    );

    final duplicateSource = await add(
      'duplicate_original',
      'duplicate_original.pdf',
      _receiptPdf(1, merchant: 'Advance Auto Parts'),
    );
    final duplicateDifferentName = File(
      '${root.path}/duplicate_same_bytes_different_name.pdf',
    );
    await duplicateSource.copy(duplicateDifferentName.path);
    files['duplicate_different_filename'] = duplicateDifferentName;
    final duplicateFolder = Directory('${root.path}/different_folder');
    await duplicateFolder.create();
    final duplicateDifferentPath = File('${duplicateFolder.path}/copy.pdf');
    await duplicateSource.copy(duplicateDifferentPath.path);
    files['duplicate_different_path'] = duplicateDifferentPath;

    await addText(
      'active_actions',
      'active_actions.pdf',
      '%PDF-1.7\n1 0 obj << /Type /Page /OpenAction 2 0 R /AA 3 0 R >> endobj\n'
          '2 0 obj << /Launch 4 0 R /RichMedia 5 0 R /SubmitForm 6 0 R /URI (https://example.com) >> endobj\n%%EOF',
    );
    await addText(
      'manual_document',
      'manual_document.pdf',
      '%PDF-1.7\n1 0 obj << /Type /Page >> stream warranty policy manual terms endstream endobj\n%%EOF',
    );

    return PdfTortureFixtures._(root, files);
  }

  File operator [](String key) => files[key]!;

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }

  static Future<List<int>> _receiptPdf(
    int pages, {
    String merchant = 'SHEETZ',
  }) async {
    final pdf = pw.Document();
    for (var index = 0; index < pages; index += 1) {
      pdf.addPage(
        pw.Page(
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(merchant),
              pw.Text('Receipt page ${index + 1}'),
              pw.Text('Subtotal 10.00'),
              pw.Text('Tax 0.53'),
              pw.Text('Total 10.53'),
              pw.Text('Payment Visa'),
            ],
          ),
        ),
      );
    }
    return pdf.save();
  }

  static Future<List<int>> _blankPdf(int pages) async {
    final pdf = pw.Document();
    for (var index = 0; index < pages; index += 1) {
      pdf.addPage(pw.Page(build: (_) => pw.SizedBox()));
    }
    return pdf.save();
  }

  static Future<List<int>> _rotatedPdf() async {
    final pdf = pw.Document()
      ..addPage(
        pw.Page(
          build: (_) => pw.Center(
            child: pw.Transform.rotate(
              angle: 1.5708,
              child: pw.Text('Rotated receipt Total 12.34'),
            ),
          ),
        ),
      );
    return pdf.save();
  }

  static Future<List<int>> _landscapePdf() async {
    final pdf = pw.Document()
      ..addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (_) => pw.Text('Landscape receipt subtotal tax total'),
        ),
      );
    return pdf.save();
  }
}
