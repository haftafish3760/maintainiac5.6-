import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_ocr_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('device OCR preserves printed receipt wording and total', (
    tester,
  ) async {
    final directory = await Directory.systemTemp.createTemp(
      'maintainiac_receipt_ocr_device_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/receipt.png');
    await file.writeAsBytes(img.encodePng(_syntheticReceipt()));

    final result = await const ReceiptOcrService()
        .recognizeTextFromAttachments([
          ReceiptAttachmentRecord(
            id: 'device-smoke-receipt',
            path: file.path,
            kind: ReceiptAttachmentKind.photo,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
            createdAt: DateTime(2026, 7, 13),
            sourceLabel: 'Generated device OCR smoke receipt',
          ),
        ]);

    expect(result.hasText, isTrue);
    expect(result.rawText, contains('HDWR'));
    expect(result.rawText, contains('BLK NTR GLV XL'));
    expect(result.rawText, contains('18.37'));
    expect(result.layout.engineIdentity, contains('mlkit'));
    expect(result.layout.pages.single.sourceImageReference, file.path);
  });
}

img.Image _syntheticReceipt() {
  final receipt = img.Image(
    width: 1200,
    height: 1600,
    numChannels: 3,
    backgroundColor: img.ColorRgb8(255, 255, 255),
  );
  const lines = [
    'MAINTAINIAC TEST MART',
    '07/13/2026',
    'HDWR 4.29',
    'BLK NTR GLV XL 12.88',
    'SUBTOTAL 17.17',
    'TAX 1.20',
    'TOTAL 18.37',
  ];
  for (var index = 0; index < lines.length; index++) {
    img.drawString(
      receipt,
      lines[index],
      font: img.arial48,
      x: 90,
      y: 110 + (index * 150),
      color: img.ColorRgb8(0, 0, 0),
    );
  }
  return receipt;
}
