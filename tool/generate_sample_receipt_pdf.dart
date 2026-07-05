import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
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
      proofImages: [
        AppReceiptPdfImage(
          bytes: _receiptPng(width: 240, height: 520),
          label: 'Portrait proof',
          sourcePageNumber: 1,
        ),
        AppReceiptPdfImage(
          bytes: _receiptPng(width: 520, height: 240),
          label: 'Landscape proof',
          sourcePageNumber: 2,
        ),
      ],
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

Uint8List _receiptPng({required int width, required int height}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(250, 250, 250));
  for (var y = 18; y < height - 18; y += 32) {
    img.drawLine(
      image,
      x1: 18,
      y1: y,
      x2: width - 18,
      y2: y,
      color: img.ColorRgb8(42, 42, 42),
      thickness: 2,
    );
  }
  img.drawRect(
    image,
    x1: 4,
    y1: 4,
    x2: width - 5,
    y2: height - 5,
    color: img.ColorRgb8(70, 70, 70),
    thickness: 2,
  );
  return Uint8List.fromList(img.encodePng(image));
}
