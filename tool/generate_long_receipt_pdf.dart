import 'dart:io';

import 'package:maintaniac/shared/pdf/app_receipt_pdf_document.dart';

import 'pdf_tool_typography.dart';

Future<void> main(List<String> args) async {
  final outputPath = args.isEmpty
      ? '/tmp/maintainiac_long_receipt.pdf'
      : args.single;
  final file = File(outputPath);
  await file.parent.create(recursive: true);

  final document = await const AppReceiptPdfRenderer().buildReceiptDocument(
    data: AppReceiptPdfData(
      merchantName: 'LONG RECEIPT SUPPLY HOUSE',
      receiptDate: DateTime(2026, 7, 5),
      receiptNumber: 'LONG-160',
      businessUseLabel: 'Business',
      confirmedByUser: true,
      subtotalCents: 42108,
      taxCents: 3570,
      totalCents: 45678,
      notes: 'Synthetic long receipt generated from confirmed sample data.',
      lines: [
        for (var index = 1; index <= 160; index++)
          AppReceiptPdfLine(
            description: 'Confirmed material line $index',
            category: index.isEven ? 'Materials' : 'Vehicle Supplies',
            quantity: index.isEven ? 2 : 1,
            unit: index.isEven ? 'ea' : 'box',
            totalCents: index.isEven ? 2450 : 1899,
          ),
      ],
    ),
    createdAt: DateTime.utc(2026, 7, 5, 12),
    theme: await PdfToolTypography.loadTheme(),
  );
  await file.writeAsBytes(document.bytes, flush: true);
  stdout.writeln(file.path);
}
