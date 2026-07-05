import 'dart:io';

import 'package:maintaniac/shared/pdf/app_receipt_pdf_document.dart';

import 'pdf_tool_typography.dart';

Future<void> main(List<String> args) async {
  final outputPath = args.isEmpty
      ? '/tmp/maintainiac_sample_receipt.pdf'
      : args.single;
  final file = File(outputPath);
  await file.parent.create(recursive: true);

  final document = await const AppReceiptPdfRenderer().buildReceiptDocument(
    data: AppReceiptPdfData(
      merchantName: 'ADVANCE AUTO PARTS',
      receiptDate: DateTime(2026, 6, 13),
      receiptNumber: '4505',
      businessUseLabel: 'Business',
      confirmedByUser: true,
      subtotalCents: 5647,
      taxCents: 340,
      totalCents: 5987,
      notes: 'Synthetic QA receipt generated from confirmed sample data.',
      lines: const [
        AppReceiptPdfLine(
          description: '5W30 FULL SYNTHETIC OIL',
          category: 'Vehicle Supplies',
          totalCents: 3899,
        ),
        AppReceiptPdfLine(
          description: 'OIL FILTER',
          category: 'Vehicle Supplies',
          totalCents: 1299,
        ),
        AppReceiptPdfLine(
          description: 'SHOP TOWELS',
          category: 'Work Supplies',
          totalCents: 449,
        ),
      ],
    ),
    createdAt: DateTime.utc(2026, 6, 13, 12),
    theme: await PdfToolTypography.loadTheme(),
  );
  await file.writeAsBytes(document.bytes, flush: true);
  stdout.writeln(file.path);
}
