import 'dart:io';

import 'package:maintaniac/shared/pdf/app_pdf_determinism.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_tool_typography.dart';

Future<void> main(List<String> args) async {
  final outputPath = args.isEmpty
      ? '/tmp/maintainiac_sample_invoice.pdf'
      : args.single;
  final pdf = pw.Document();
  final pdfTheme = await PdfToolTypography.loadTheme();
  pdf.addPage(
    pw.Page(
      theme: pdfTheme,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('MAINTAINIAC INVOICE'),
          pw.Text('Invoice # INV-2409'),
          pw.Text('Customer: Sample Customer'),
          pw.SizedBox(height: 16),
          pw.Text('Panel replacement labor        720.00'),
          pw.Text('Materials                       165.00'),
          pw.Text('Tax                              52.74'),
          pw.SizedBox(height: 16),
          pw.Text('Total                           937.74'),
        ],
      ),
    ),
  );
  final file = File(outputPath);
  await file.parent.create(recursive: true);
  final bytes = AppPdfDeterminism.normalizeDocumentId(
    await pdf.save(),
    'tool-sample-invoice-v1',
  );
  await file.writeAsBytes(bytes, flush: true);
  stdout.writeln(file.path);
}
