import 'dart:io';

import 'package:pdf/widgets.dart' as pw;

import 'pdf_tool_typography.dart';

Future<void> main(List<String> args) async {
  final outputPath = args.isEmpty
      ? '/tmp/maintainiac_sample_receipt.pdf'
      : args.single;
  final file = File(outputPath);
  await file.parent.create(recursive: true);

  final pdf = pw.Document();
  final pdfTheme = await PdfToolTypography.loadTheme();
  pdf.addPage(
    pw.Page(
      theme: pdfTheme,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('ADVANCE AUTO PARTS'),
          pw.Text('123 MAIN ST'),
          pw.Text('LYNCHBURG, VA 24502'),
          pw.SizedBox(height: 16),
          pw.Text('DATE 06/13/2026'),
          pw.Text('RECEIPT # 4505'),
          pw.SizedBox(height: 16),
          pw.Text('5W30 FULL SYNTHETIC OIL      38.99'),
          pw.Text('OIL FILTER                   12.99'),
          pw.Text('SHOP TOWELS                   4.49'),
          pw.SizedBox(height: 16),
          pw.Text('SUBTOTAL                     56.47'),
          pw.Text('SALES TAX                     3.40'),
          pw.Text('TOTAL                        59.87'),
          pw.SizedBox(height: 16),
          pw.Text('THANK YOU FOR YOUR BUSINESS'),
        ],
      ),
    ),
  );

  await file.writeAsBytes(await pdf.save(), flush: true);
  stdout.writeln(file.path);
}
