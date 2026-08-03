import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test(
    'keeps compact numbered tax summaries out of Walmart item lines',
    () {
      final parsed = parseExpenseReceiptText('''
WALMART
ST# 01234 OP# 000001 TE# 01 TR# 00001
07/31/2026 02:08:00 PM
SHOP TOWELS 8.97
MOTOR OIL 29.97
AIR FILTER 32.61
# ITEMS SOLD 3
SUBTOTAL 71.55
TAX2 1.0000 % 0.38
TAX1 5.3000 % 1.76
TOTAL 73.69
VISA TEND 73.69
''');

      expect(parsed.merchantName, 'Walmart');
      expect(parsed.enteredSubtotal, 71.55);
      expect(parsed.enteredTax, 2.14);
      expect(parsed.enteredTotal, 73.69);
      expect(parsed.lines.map((line) => line.description), [
        'Shop Towels',
        'Motor Oil',
        'Air Filter',
      ]);
      expect(
        parsed.lines.map((line) => line.description.toUpperCase()),
        isNot(contains(anyOf(contains('TAX1'), contains('TAX2')))),
      );
    },
  );
}
