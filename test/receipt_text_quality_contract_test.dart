import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/receipts/receipt_text_quality_contract.dart';

void main() {
  group('evaluateReceiptTextQuality', () {
    test('detects fuel receipt essentials despite OCR zero/O noise', () {
      final signals = evaluateReceiptTextQuality(
        merchantNeedle: 'sheetz',
        text: '''
SHEETZ
O6/19/2O26 O7:15 AM
PUMP O4 UNLEADED 14.25O GAL 47.O1
T0TAL 47.O1
''',
      );

      expect(signals.hasMerchant, isTrue);
      expect(signals.hasDate, isTrue);
      expect(signals.hasFuelQuantity, isTrue);
      expect(signals.hasTotal, isTrue);
      expect(signals.hasBottomTotalCoverage, isTrue);
    });

    test('detects gallon-equivalent and compact renewable fuel quantities', () {
      expect(looksLikeReceiptFuelQuantityLine('GGE 11.500'), isTrue);
      expect(looksLikeReceiptFuelQuantityLine('LNG DGE 13.250'), isTrue);
      expect(looksLikeReceiptFuelQuantityLine('HVO100 18.500 @ 4.199'), isTrue);
      expect(looksLikeReceiptFuelQuantityLine('HVO100 4.199'), isFalse);
    });

    test('detects maintenance services and interval lines', () {
      final signals = evaluateReceiptTextQuality(
        merchantNeedle: 'quick lube',
        text: '''
QUICK LUBE
2026-06-30
5W-20 SYNTHETIC OIL 39.99
OIL FILTER 8.49
TIRE ROTATION 19.99
SALES TAX 4.11
TOTAL 72.58
NEXT SERVICE 92,500 MILES
''',
      );

      expect(signals.hasMerchant, isTrue);
      expect(signals.hasTax, isTrue);
      expect(signals.hasLineItemAmount, isTrue);
      expect(signals.hasMaintenanceService, isTrue);
      expect(signals.hasMaintenanceInterval, isTrue);
    });

    test('flags tender amount rows for privacy/admin review', () {
      final signals = evaluateReceiptTextQuality(
        merchantNeedle: 'pilot',
        text: '''
PILOT TRVL CTR
06/23/2026 05:42 AM
TOTAL 66.95
VISA FLEET CARD 66.95
AUTH 442193
TRACE 77801
''',
      );

      expect(signals.hasTenderLineWithAmount, isTrue);
    });

    test('does not treat totals, taxes, or auth rows as line items', () {
      expect(looksLikeReceiptLineItemAmount('TOTAL 72.58'), isFalse);
      expect(looksLikeReceiptLineItemAmount('SALES TAX 4.11'), isFalse);
      expect(looksLikeReceiptLineItemAmount('AUTH CODE 72.58'), isFalse);
      expect(looksLikeReceiptLineItemAmount('OIL FILTER 8.49'), isTrue);
    });
  });
}
