import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

ReceiptAttachmentRecord pdfAttachment(String id, File file) {
  return ReceiptAttachmentRecord(
    id: id,
    path: file.path,
    kind: ReceiptAttachmentKind.pdf,
    dataSaverLevel: ReceiptDataSaverLevel.original,
    createdAt: DateTime(2026, 6, 14),
    displayName: file.uri.pathSegments.last,
    originalFileName: file.uri.pathSegments.last,
    mimeType: 'application/pdf',
  );
}

ExpenseReceiptRecord expenseReceiptWithAttachment(
  String id,
  ReceiptAttachmentRecord attachment,
) {
  return ExpenseReceiptRecord(
    id: id,
    receiptDate: DateTime(2026, 6, 14),
    merchantName: 'Advance Auto Parts',
    receiptNumber: 'A123',
    paymentMethod: 'Visa',
    enteredSubtotal: 100,
    enteredTax: 5.30,
    enteredTotal: 105.30,
    vehicleId: 'truck-1',
    attachments: [attachment],
    lines: [
      ExpenseReceiptLineRecord(
        id: '$id-line',
        description: 'Brake caliper',
        category: 'Repair',
        use: ExpenseLineUse.business,
        quantity: 1,
        unitsPerPackage: 1,
        unit: 'each',
        subtotal: 100,
      ),
    ],
  );
}

void mockDocumentsDirectory(FileSystemEntity entity) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => switch (call.method) {
          'getApplicationDocumentsDirectory' => entity.path,
          _ => null,
        },
      );
}

void clearDocumentsDirectoryMock() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        null,
      );
}

Future<void> writeSparsePdfHeader(File file, int size) async {
  final raf = await file.open(mode: FileMode.write);
  try {
    await raf.writeString('%PDF-1.7\n1 0 obj << /Type /Page >> endobj\n%%EOF');
    await raf.setPosition(size - 1);
    await raf.writeByte(0);
  } finally {
    await raf.close();
  }
}

Future<void> writeFakePdfWithPages(File file, int pages) async {
  final buffer = StringBuffer('%PDF-1.7\n');
  for (var index = 0; index < pages; index += 1) {
    buffer.writeln('$index 0 obj << /Type /Page >> endobj');
  }
  buffer.writeln('%%EOF');
  await file.writeAsString(buffer.toString(), flush: true);
}
