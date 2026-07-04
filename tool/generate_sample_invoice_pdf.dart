import 'dart:io';

import 'package:pdf/widgets.dart' as pw;

Future<void> main(List<String> args) async {
  final outputPath = args.isEmpty
      ? '/tmp/maintainiac_sample_invoice.pdf'
      : args.single;
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
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
  await file.writeAsBytes(await pdf.save(), flush: true);
  stdout.writeln(file.path);
}
