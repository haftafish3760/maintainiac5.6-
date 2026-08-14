import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_receipt_parser.dart';

void main() {
  test(
    'ignores gift card balance rows so Lowes tender blocks stay out of items',
    () {
      final parsed = parseExpenseReceiptText('''
LOWE'S HOME CENTERS, LLC
07/09/2021
23536 OATEY 14-OZ PLUMBERS PUTT 2.99
SUBTOTAL 2.99
TAX 0.25
INVOICE 18934 TOTAL 3.24
MERCH/GIFT CARDS 3.24
MERCH/GIFT CARD 5715 AUTHCODE 370
BEGIN BAL 6.94
TRANSACTION AMT 3.24
ENDING BAL 3.70
''');

      expect(parsed.lines, hasLength(1));
      expect(parsed.lines.single.description, 'Oatey 14-oz Plumbers Putt');
      expect(parsed.lines.single.subtotal, 2.99);
      expect(parsed.enteredSubtotal, 2.99);
      expect(parsed.enteredTax, 0.25);
      expect(parsed.enteredTotal, 3.24);
      final descriptions = parsed.lines
          .map((line) => line.description.toLowerCase())
          .join(' ');
      expect(descriptions, isNot(contains('merch')));
      expect(descriptions, isNot(contains('authcode')));
      expect(descriptions, isNot(contains('begin bal')));
      expect(descriptions, isNot(contains('transaction amt')));
      expect(descriptions, isNot(contains('ending bal')));
      expect(
        parsed.diagnostics.genericReceiptSignalCount('paymentCandidate'),
        greaterThanOrEqualTo(1),
      );
      expect(
        parsed.diagnostics.parserTaskCount('payment_line_excluded'),
        greaterThanOrEqualTo(3),
      );
      expect(
        parsed.diagnostics.parserTaskCount('stored_value_tender_line_excluded'),
        greaterThanOrEqualTo(2),
      );
      expect(
        parsed.diagnostics.parserTaskCount(
          'tender_balance_detail_line_excluded',
        ),
        greaterThanOrEqualTo(2),
      );
      expect(
        parsed.diagnostics.parserTaskCount('auth_detail_line_excluded'),
        greaterThanOrEqualTo(1),
      );
      expect(
        parsed.diagnostics.parserTaskCount('reference_detail_line_excluded'),
        greaterThanOrEqualTo(1),
      );
      expect(
        parsed.diagnostics.parserTaskCount('private_receipt_line_protected'),
        greaterThanOrEqualTo(3),
      );
      expect(parsed.diagnostics.reconciled, isTrue);
    },
  );

  test('ignores saved, cash back, and change rows when reading totals', () {
    final parsed = parseExpenseReceiptText('''
WALMART
06/20/2026
SHOP TOWELS 8.97
CASE WATER 5.99
YOU SAVED 3.50
TOTAL SAVINGS 3.50
CASH BACK 20.00
CHANGE DUE 0.54
SUBTOTAL 14.96
TAX 1.05
TOTAL 16.01
VISA CARD 36.01
''');

    expect(parsed.enteredSubtotal, 14.96);
    expect(parsed.enteredTax, 1.05);
    expect(parsed.enteredTotal, 16.01);
    expect(parsed.lines, hasLength(2));
    final descriptions = parsed.lines
        .map((line) => line.description.toLowerCase())
        .join(' ');
    expect(descriptions, isNot(contains('saved')));
    expect(descriptions, isNot(contains('cash back')));
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('uses tender amount only when explicit receipt total is missing', () {
    final parsed = parseExpenseReceiptText('''
WALMART
06/20/2026
GEN MDSE 17.48
CASE WATER 5.99
SHOP TOWELS 8.97
GIFT CARD BALANCE 12.00
VISA CARD 32.44
''');

    expect(parsed.enteredTotal, 32.44);
    expect(parsed.lines, hasLength(3));
    final descriptions = parsed.lines
        .map((line) => line.description.toLowerCase())
        .join(' ');
    expect(descriptions, isNot(contains('gift card')));
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test(
    'does not let payment-style totals override stronger receipt totals',
    () {
      final cashBack = parseExpenseReceiptText('''
WALMART
06/20/2026
SHOP TOWELS 8.97
CASE WATER 5.99
SUBTOTAL 14.96
TAX 1.05
TOTAL 16.01
CASH BACK 20.00
AMOUNT PAID 36.01
VISA CARD 36.01
''');

      expect(cashBack.enteredSubtotal, 14.96);
      expect(cashBack.enteredTax, 1.05);
      expect(cashBack.enteredTotal, 16.01);
      expect(cashBack.lines, hasLength(2));
      expect(cashBack.diagnostics.reconciled, isTrue);

      final lowesGiftCard = parseExpenseReceiptText('''
LOWE'S HOME CENTERS, LLC
07/09/2021
23536 OATEY 14-OZ PLUMBERS PUTT 2.99
SUBTOTAL 2.99
TAX 0.25
INVOICE 18934 TOTAL 3.24
MERCH/GIFT CARDS 3.24
TRANSACTION AMT 9.99
ENDING BAL 3.70
''');

      expect(lowesGiftCard.lines, hasLength(1));
      expect(lowesGiftCard.enteredSubtotal, 2.99);
      expect(lowesGiftCard.enteredTax, 0.25);
      expect(lowesGiftCard.enteredTotal, 3.24);
      expect(lowesGiftCard.diagnostics.reconciled, isTrue);
    },
  );

  test('uses single payment-style total when no stronger total is present', () {
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
    expect(transactionAmount.diagnostics.reconciled, isTrue);
  });

  test('parses uncommon hardware summary labels before tender rows', () {
    final parsed = parseExpenseReceiptText('''
OAK HILL HARDWARE
07/01/2026
PVC COUPLING 4.99
SHOP TOWELS 8.97
MERCH TOTAL 13.96
LOCAL TAX 1.12
TOTAL DUE 15.08
VISA CARD 15.08
''');

    expect(parsed.merchantName, 'Oak Hill Hardware');
    expect(parsed.lines, hasLength(2));
    expect(parsed.enteredSubtotal, 13.96);
    expect(parsed.enteredTax, 1.12);
    expect(parsed.enteredTotal, 15.08);
    expect(parsed.diagnostics.reconciled, isTrue);
  });

  test('does not use multiple tender rows as the receipt total', () {
    final parsed = parseExpenseReceiptText('''
COUNTY LINE MARKET
07/01/2026
SHOP TOWELS 8.00
ICE 2.00
VISA CARD 8.00
CASH TENDER 1.00
''');

    expect(parsed.lines, hasLength(2));
    expect(parsed.enteredTotal, 10.00);
    expect(parsed.totalCalculatedFromVisibleLines, isTrue);
    expect(parsed.diagnostics.reconciled, isFalse);
    expect(
      parsed.warnings.any(
        (warning) => warning.contains('add the lower section'),
      ),
      isTrue,
    );
    expect(
      parsed.diagnostics.missingBottomTotalsEvidenceCode,
      'local_text_items_without_summary_totals',
    );
  });

  test('routes split tender matching visible lines to payment review', () {
    final parsed = parseExpenseReceiptText('''
COUNTY LINE MARKET
07/01/2026
SHOP TOWELS 8.00
ICE 2.00
VISA CARD 8.00
CASH TENDER 2.00
THANK YOU FOR SHOPPING
''');

    expect(parsed.lines, hasLength(2));
    expect(parsed.enteredTotal, 10.00);
    expect(parsed.totalCalculatedFromVisibleLines, isTrue);
    expect(
      parsed.warnings,
      contains(
        'Multiple payment rows match the visible receipt lines. Review the split payment before saving.',
      ),
    );
    expect(
      parsed.diagnostics.parserTaskCount(
        'receipt_split_tender_matches_visible_lines_review',
      ),
      1,
    );
    expect(parsed.diagnostics.parserTaskCount('card_tender_line_excluded'), 1);
    expect(parsed.diagnostics.parserTaskCount('cash_tender_line_excluded'), 1);
    expect(
      parsed.diagnostics.parserTaskCount('payment_summary_line_excluded'),
      greaterThanOrEqualTo(1),
    );
    expect(
      parsed.diagnostics.parserTaskCount(
        'receipt_possible_lower_section_missing',
      ),
      0,
    );
    expect(parsed.diagnostics.hasParserPossibleLowerSectionMissing, isFalse);
    expect(parsed.diagnostics.shouldSuggestLowerReceiptSection, isFalse);
    expect(
      parsed.diagnostics.missingBottomTotalsEvidenceCode,
      'local_text_split_tender_matches_visible_lines',
    );
    expect(
      parsed.diagnostics.missingBottomTotalsLocalEvidenceReviewLabel,
      contains('multiple payment rows'),
    );
  });

  test('does not turn barcode or UPC money rows into receipt lines', () {
    final parsed = parseExpenseReceiptText('''
WALMART
06/20/2026
SHOP TOWELS 8.97
UPC 012345678905 8.97
BARCODE 444555666777 8.97
QR CODE 998877665544 8.97
SUBTOTAL 8.97
TAX 0.63
TOTAL 9.60
''');

    expect(parsed.lines, hasLength(1));
    expect(parsed.lines.single.description, 'Shop Towels');
    expect(parsed.lines.single.subtotal, 8.97);
    final descriptions = parsed.lines
        .map((line) => line.description.toLowerCase())
        .join(' ');
    expect(descriptions, isNot(contains('upc')));
    expect(descriptions, isNot(contains('barcode')));
    expect(descriptions, isNot(contains('qr code')));
    expect(parsed.diagnostics.reconciled, isTrue);
  });
}
