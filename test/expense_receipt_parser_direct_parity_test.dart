import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_ledger_models.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';
import 'package:maintaniac/shared/receipts/receipt_layout_intelligence.dart';

void main() {
  test('direct parser recognizes OCR parity fuel and transaction totals', () {
    final fuelSale = parseExpenseReceiptText('''
RIVER ROAD FUEL
07/01/2026
PUMP 04
UNLEADED 10.000 GAL 35.00
FUEL SALE 35.00
CARD 35.00
''');

    expect(fuelSale.merchantName, 'River Road Fuel');
    expect(fuelSale.lines, hasLength(1));
    expect(fuelSale.enteredTotal, 35.00);
    expect(fuelSale.diagnostics.hasExplicitTotal, isTrue);
    expect(fuelSale.diagnostics.parserTaskCount('receipt_total_only_ready'), 1);
    expect(fuelSale.diagnostics.shouldSuggestLowerReceiptSection, isFalse);

    final transactionTotal = parseExpenseReceiptText('''
HARDWARE SUPPLY
07/01/2026
WOOD SCREWS 8.97
PAINTERS TAPE 5.99
MERCHANDISE TOTAL 14.96
LOCAL TAX 1.05
TRANSACTION TOTAL 16.01
VISA CARD 16.01
''');

    expect(transactionTotal.lines, hasLength(2));
    expect(transactionTotal.enteredSubtotal, 14.96);
    expect(transactionTotal.enteredTax, 1.05);
    expect(transactionTotal.enteredTotal, 16.01);
    expect(transactionTotal.diagnostics.reconciled, isTrue);

    final transactionAmount = parseExpenseReceiptText('''
MOBILE FUEL MART
07/01/2026
PUMP 02
REGULAR 8.000 GAL 28.00
TRANSACTION AMT 28.00
CARD 28.00
''');

    expect(transactionAmount.lines, hasLength(1));
    expect(transactionAmount.enteredTotal, 28.00);
    expect(transactionAmount.diagnostics.hasExplicitTotal, isTrue);
    expect(
      transactionAmount.diagnostics.shouldSuggestLowerReceiptSection,
      isFalse,
    );
  });

  test('direct parser recovers OCR damaged summary words', () {
    final damagedTotal = parseExpenseReceiptText('''
OAK HILL HARDWARE
07/01/2026
WOOD SCREWS 8.97
PAINTERS TAPE 5.99
SUBT0TAL 14.96
T4X 1.05
T0TAL 16.01
''');

    expect(damagedTotal.lines, hasLength(2));
    expect(damagedTotal.enteredSubtotal, 14.96);
    expect(damagedTotal.enteredTax, 1.05);
    expect(damagedTotal.enteredTotal, 16.01);
    expect(damagedTotal.diagnostics.hasExplicitSubtotal, isTrue);
    expect(damagedTotal.diagnostics.hasExplicitTax, isTrue);
    expect(damagedTotal.diagnostics.hasExplicitTotal, isTrue);
    expect(damagedTotal.diagnostics.reconciled, isTrue);

    final damagedAmountDue = parseExpenseReceiptText('''
RIVER ROAD MARKET
07/01/2026
SHOP TOWELS 8.97
AM0UNT DUE 8.97
''');

    expect(damagedAmountDue.lines, hasLength(1));
    expect(damagedAmountDue.enteredTotal, 8.97);
    expect(damagedAmountDue.diagnostics.hasExplicitTotal, isTrue);
    expect(
      damagedAmountDue.diagnostics.shouldSuggestLowerReceiptSection,
      isFalse,
    );
  });

  test('routes mismatched total-only receipt lines to math review', () {
    final parsed = parseExpenseReceiptText('''
CORNER MART #42
06/12/2026
PUMP 07
UNLEADED FUEL 30.00
TOTAL 35.00
CARD 35.00
''');

    expect(parsed.lines, hasLength(1));
    expect(parsed.enteredTotal, 35.00);
    expect(
      parsed.warnings,
      contains(
        'Receipt total was found, but parsed line amounts do not match it. Review item lines or enter missing subtotal/tax before saving.',
      ),
    );
    expect(
      parsed.diagnostics.parserTaskCount('receipt_total_only_line_math_review'),
      1,
    );
    expect(parsed.diagnostics.parserTaskCount('receipt_total_only_ready'), 0);
    expect(
      parsed.diagnostics.parserDownstreamReadinessStatus,
      'expense_lines_need_review',
    );
    expect(
      parsed.diagnostics.parserDownstreamReadinessCount(
        'receipt_total_only_line_math_review',
      ),
      1,
    );
  });

  test(
    'receipt layout analyzer numbers lines and creates client proof redaction plan',
    () {
      final layout = const ReceiptLayoutAnalyzer().analyzeText('''
UNKNOWN HARDWARE OUTLET
2710 SERVICE ROAD
SALE 07/09/2026 09:15
PVC ADAPTER 1/2 IN                 3.49
WIRE NUT 25PK                      4.99
SUBTOTAL                           8.48
TAX                                0.70
TOTAL                              9.18
MASTERCARD **** 9911
AUTHCODE 882001
THANK YOU
''');

      expect(layout.merchantLine?.lineNumber, 1);
      expect(layout.itemLines.map((line) => line.lineNumber), [4, 5]);
      expect(layout.totalLines.map((line) => line.lineNumber), contains(8));
      expect(layout.paymentLines.map((line) => line.lineNumber), contains(9));
      expect(layout.structureStatus, 'receipt_structure_ready');
      expect(layout.parserLineNumbers, containsAll(<int>[1, 4, 5, 6, 7, 8]));

      final proof = layout.redactionPlanForLineNumbers({
        4,
      }, keepMerchantContext: true);

      expect(proof.visibleLineNumbers, containsAll(<int>[1, 4]));
      expect(proof.hiddenLineNumbers, containsAll(<int>[5, 8, 9, 10]));
      expect(proof.keepsMerchantContext, isTrue);
      expect(proof.keepsTotalsContext, isFalse);
      expect(proof.protectedContentTypes, contains('payment_info'));
      expect(proof.protectedContentTypes, contains('transaction_info'));
      expect(proof.summaryCode, startsWith('receipt_redaction:'));

      final proofWithTotals = layout.redactionPlanForLineNumbers(
        {4},
        keepMerchantContext: true,
        keepTotalsContext: true,
      );

      expect(
        proofWithTotals.visibleLineNumbers,
        containsAll(<int>[1, 4, 6, 7, 8]),
      );
      expect(proofWithTotals.hiddenLineNumbers, containsAll(<int>[5, 9, 10]));
      expect(proofWithTotals.keepsMerchantContext, isTrue);
      expect(proofWithTotals.keepsTotalsContext, isTrue);
      expect(
        proofWithTotals.visibleAnchorCodes,
        containsAll([
          'receipt_line_0006_totals_context',
          'receipt_line_0007_totals_tax',
          'receipt_line_0008_totals_total',
        ]),
      );
    },
  );

  test(
    'parser keeps receipt totals usable when no safe item lines are found',
    () {
      final parsed = parseExpenseReceiptText('''
LOWE'S HOME CENTERS, LLC
6400 BRODIE LANE
AUSTIN, TX 78745
07/09/2021 13:14:57
SUBTOTAL 2.99
TAX 0.25
TOTAL 3.24
THANK YOU FOR SHOPPING LOWE'S.
''');

      expect(parsed.lines, isEmpty);
      expect(parsed.enteredSubtotal, 2.99);
      expect(parsed.enteredTax, 0.25);
      expect(parsed.enteredTotal, 3.24);
      expect(parsed.hasUsableData, isTrue);
      expect(
        parsed.warnings,
        contains(
          'Receipt totals were found, but no safe item-price lines were detected. Continue with the receipt total or add item lines manually.',
        ),
      );
      expect(
        parsed.fieldConfidences['lineItems']?.reason,
        contains('Receipt totals were found'),
      );
      expect(
        parsed.diagnostics.parserDownstreamReadinessStatus,
        'proof_total_only',
      );
      expect(
        parsed.diagnostics.parserDownstreamReadinessCount(
          'totals_found_no_safe_lines',
        ),
        1,
      );
      expect(
        parsed.diagnostics.downstreamReadinessSummaryLabel,
        'Receipt total ready; line detail missing',
      );
    },
  );

  test(
    'previews mixed receipt business and personal tax allocation before save',
    () {
      const parsed = ExpenseReceiptParseResult(
        sourceText: 'manual preview',
        enteredSubtotal: 30,
        enteredTax: 3,
        enteredTotal: 33,
        lines: [
          ExpenseReceiptLineRecord(
            id: 'line-business',
            description: 'Business item',
            category: 'Materials',
            use: ExpenseLineUse.business,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 10,
          ),
          ExpenseReceiptLineRecord(
            id: 'line-personal',
            description: 'Personal item',
            category: 'Personal',
            use: ExpenseLineUse.personal,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 10,
          ),
          ExpenseReceiptLineRecord(
            id: 'line-split',
            description: 'Split item',
            category: 'Cell Phone',
            use: ExpenseLineUse.split,
            businessPercent: .25,
            quantity: 1,
            unitsPerPackage: 1,
            unit: 'each',
            subtotal: 10,
          ),
        ],
      );

      expect(parsed.lineSubtotal, 30);
      expect(parsed.receiptAdjustment, 3);
      expect(parsed.effectiveTaxRate, closeTo(.1, .001));
      expect(parsed.businessLineSubtotal, closeTo(12.5, .001));
      expect(parsed.personalLineSubtotal, closeTo(17.5, .001));
      expect(parsed.businessTotal, closeTo(13.75, .001));
      expect(parsed.personalTotal, closeTo(19.25, .001));
      expect(
        parsed.businessTotalForLine(parsed.lines.last),
        closeTo(2.75, .001),
      );
      expect(
        parsed.personalTotalForLine(parsed.lines.last),
        closeTo(8.25, .001),
      );
    },
  );
}
