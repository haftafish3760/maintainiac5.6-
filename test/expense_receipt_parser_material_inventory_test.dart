import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test('parser marks material receipt lines ready for inventory handoff', () {
    final parsed = parseExpenseReceiptText('''
LOWE'S HOME CENTERS, LLC
07/09/2021 13:14:57
23536 OATEY 14-OZ PLUMBERS PUTTY 2.99
Subtotal 2.99
Tax 0.25
Total 3.24
''');

    expect(parsed.merchantName, "Lowe's");
    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.category, 'Materials');
    expect(
      parsed.diagnostics.parserDownstreamReadinessStatus,
      'inventory_material_ready',
    );
    expect(
      parsed.diagnostics.parserDownstreamReadinessCount('vendor_ready'),
      1,
    );
    expect(
      parsed.diagnostics.parserDownstreamReadinessCount(
        'inventory_material_ready',
      ),
      greaterThanOrEqualTo(1),
    );
    expect(
      parsed.diagnostics.parserDownstreamReadinessCount('priced_line_ready'),
      1,
    );
    expect(parsed.diagnostics.downstreamReadinessSummaryLabel, isNot(isEmpty));
  });

  test(
    'generic receipt layout keeps unknown gas station receipts parseable',
    () {
      final parsed = parseExpenseReceiptText('''
RIVER ROAD MART #418
18842 HIGHWAY 71
ANYTOWN, TX 78745
SALE
PUMP 04 UNLEADED 10.000 GAL       32.10
ENERGY DRINK                       2.49
SUBTOTAL                          34.59
SALES TAX                          0.21
TOTAL                             34.80
VISA **** 4242
AUTHCODE 104337
THANK YOU
''');

      expect(parsed.merchantName, 'River Road Mart 418');
      expect(parsed.lines.length, greaterThanOrEqualTo(2));
      expect(parsed.lines.any((line) => line.category == 'Fuel'), isTrue);
      expect(parsed.lines.first.ocrSourceLineNumber, 5);
      expect(parsed.enteredSubtotal, 34.59);
      expect(parsed.enteredTax, 0.21);
      expect(parsed.enteredTotal, 34.80);
      expect(
        parsed.diagnostics.genericReceiptStructureStatus,
        'receipt_structure_ready',
      );
      expect(parsed.diagnostics.hasGenericReceiptStructure, isTrue);
      expect(
        parsed.diagnostics.genericReceiptSignalCount('merchantCandidate'),
        greaterThanOrEqualTo(1),
      );
      expect(parsed.diagnostics.genericReceiptSignalCount('itemCandidate'), 2);
      expect(
        parsed.diagnostics.genericReceiptSignalCount('paymentCandidate'),
        greaterThanOrEqualTo(1),
      );
      expect(
        parsed.diagnostics.genericReceiptParserLineNumbers,
        containsAll(<int>[1, 5, 6, 7, 8, 9]),
      );
      expect(
        parsed.diagnostics.genericReceiptStructureActionLabel,
        contains('ready for local merchant'),
      );
    },
  );
}
