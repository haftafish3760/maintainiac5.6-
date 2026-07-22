import 'package:flutter_test/flutter_test.dart';

import '../tool/receipt_qa_barcode_summary.dart';

void main() {
  test('barcode QA summary stays privacy-safe and deterministic', () {
    final summary = summarizeReceiptQaBarcodes(
      codes: const [
        ReceiptQaBarcodeCode(
          format: 'ean13',
          valueType: 'product',
          rawValue: '0 12345-67890 5',
        ),
        ReceiptQaBarcodeCode(
          format: 'code128',
          valueType: 'text',
          rawValue: '',
          displayValue: 'LOWES-SKU-14-2-NMB',
        ),
        ReceiptQaBarcodeCode(
          format: 'qrCode',
          valueType: 'wifi',
          rawValue: 'WIFI:T:WPA;S:PrivateNetwork;P:secret;;',
        ),
      ],
      warnings: const [
        'receipt_scanner_inventory_suggestion_only',
        'private vendor warning text',
      ],
    );

    expect(summary.codeCount, 3);
    expect(summary.qrCodeCount, 1);
    expect(summary.inventoryLookupCandidateCount, 2);
    expect(summary.formatBuckets, {'ean13': 1, 'code128': 1, 'qr': 1});
    expect(summary.warningBuckets, [
      'barcode_scan_warning',
      'receipt_scanner_inventory_suggestion_only',
    ]);
    expect(summary.toString(), isNot(contains('secret')));
  });

  test('barcode QA summary rejects oversized and sensitive lookup values', () {
    final summary = summarizeReceiptQaBarcodes(
      codes: [
        const ReceiptQaBarcodeCode(
          format: 'qr',
          valueType: 'email',
          rawValue: 'customer@example.com',
        ),
        ReceiptQaBarcodeCode(
          format: 'unknown',
          valueType: 'text',
          rawValue: 'A' * (receiptQaBarcodeMaxLookupLength + 1),
        ),
      ],
      warnings: const [],
    );

    expect(summary.inventoryLookupCandidateCount, 0);
    expect(summary.formatBuckets, {'qr': 1, 'unknown': 1});
  });
}
