part of 'receipt_qa_runner.dart';

const _adjustmentRetailReceiptQaFixtures = [
  _ReceiptQaFixture(
    pack: 'adjustment',
    name: 'coupon and store discount adjustment rows',
    merchantNeedle: 'cvs',
    expectedMerchantName: 'CVS Pharmacy',
    expectTax: true,
    expectLineItems: true,
    expectedDateIso: '2026-06-20',
    expectedSubtotal: 5.47,
    expectedTax: 0.38,
    expectedTotal: 5.85,
    expectedLineCount: 3,
    expectedLineSubtotals: [8.97, -2.00, -1.50],
    expectedLineDescriptionNeedles: [
      'shop towels',
      'mfr coupon',
      'store discount',
    ],
    expectedLineCategories: [
      'Vehicle Supplies',
      'Receipt Adjustment',
      'Receipt Adjustment',
    ],
    expectedLineFamilies: [
      'vehicle_supplies',
      'receipt_adjustment',
      'receipt_adjustment',
    ],
    expectedLineUses: ['business', 'business', 'business'],
    expectedNegativeLineCount: 2,
    expectedAdjustmentLineCount: 2,
    expectReconciled: true,
    expectedBusinessTotal: 5.85,
    expectedPersonalTotal: 0,
    expectedReviewLineCount: 1,
    expectedDownstreamReadinessStatus: 'expense_lines_need_review',
    expectedDownstreamReadinessSummary: 'Expense lines need review',
    expectedDownstreamReadinessCounts: {
      'parser_downstream_expense_lines_need_review': 1,
      'line_needs_review': 1,
      'line_ready': 2,
      'category_family_vehicle_needs_review': 1,
      'category_family_adjustment_ready': 2,
    },
    text: '''
CVS PHARMACY
06/20/2026
SHOP TOWELS 8.97
MFR COUPON -2.00
STORE DISCOUNT (1.50)
SUBTOTAL 5.47
TAX 0.38
TOTAL 5.85
''',
  ),
  _ReceiptQaFixture(
    pack: 'retail',
    name: 'mixed retail baseline',
    merchantNeedle: 'walmart',
    expectedMerchantName: 'Walmart',
    expectLineItems: true,
    expectedLineCount: 2,
    expectedLineSubtotals: [17.48, 5.99],
    expectedLineDescriptionNeedles: ['general mdse', 'case water'],
    expectedLineCategories: ['Uncategorized', 'Groceries'],
    expectedLineFamilies: ['uncategorized', 'food_or_grocery'],
    expectedLineUses: ['business', 'business'],
    expectedBusinessTotal: 23.47,
    expectedPersonalTotal: 0,
    expectedDownstreamReadinessStatus: 'expense_lines_need_review',
    expectedDownstreamReadinessSummary: 'Expense lines need review',
    expectedDownstreamReadinessCounts: {
      'parser_downstream_expense_lines_need_review': 1,
      'line_needs_review': 1,
      'line_ready': 1,
      'category_family_uncategorized_needs_review': 1,
      'category_family_food_or_grocery_ready': 1,
    },
    text: '''
WALMART
06/12/2026
GENERAL MDSE 17.48
CASE WATER 5.99
TOTAL 23.47
''',
  ),
  _ReceiptQaFixture(
    pack: 'retail',
    name: 'retail tax total with tender row',
    merchantNeedle: 'target',
    expectedMerchantName: 'Target',
    expectTax: true,
    expectLineItems: true,
    allowTenderAmountRows: true,
    expectedDateIso: '2026-07-01',
    expectedSubtotal: 27.47,
    expectedTax: 1.65,
    expectedTotal: 29.12,
    expectedLineCount: 3,
    expectedLineSubtotals: [8.99, 12.49, 5.99],
    expectedLineDescriptionNeedles: ['shop towels', 'work gloves', 'water'],
    expectedLineCategories: ['Vehicle Supplies', 'Safety Gear', 'Groceries'],
    expectedLineFamilies: [
      'vehicle_supplies',
      'general_expense',
      'food_or_grocery',
    ],
    expectedLineUses: ['business', 'business', 'business'],
    expectedBusinessTotal: 29.12,
    expectedPersonalTotal: 0,
    expectedDownstreamReadinessStatus: 'expense_lines_ready',
    expectedDownstreamReadinessSummary: 'Expense line review ready',
    text: '''
TARGET
07/01/2026
SHOP TOWELS 8.99
WORK GLOVES 12.49
BOTTLED WATER 5.99
SUBTOTAL 27.47
TAX 1.65
TOTAL 29.12
VISA CARD 29.12
AUTH 901122
''',
  ),
  _ReceiptQaFixture(
    pack: 'retail',
    name: 'mixed business and personal line allocation',
    merchantNeedle: 'target',
    expectedMerchantName: 'Target',
    expectTax: true,
    expectLineItems: true,
    expectedDateIso: '2026-07-02',
    expectedSubtotal: 20.00,
    expectedTax: 1.20,
    expectedTotal: 21.20,
    expectedLineCount: 2,
    expectedLineSubtotals: [12.00, 8.00],
    expectedLineDescriptionNeedles: ['shop towels', 'snacks'],
    expectedLineCategories: ['Vehicle Supplies', 'Meals'],
    expectedLineFamilies: ['vehicle_supplies', 'food_or_grocery'],
    expectedLineUses: ['business', 'personal'],
    expectedBusinessTotal: 12.72,
    expectedPersonalTotal: 8.48,
    expectedReviewLineCount: 0,
    expectedDownstreamReadinessStatus: 'expense_lines_ready',
    expectedDownstreamReadinessSummary: 'Expense line review ready',
    text: '''
TARGET
07/02/2026
BUSINESS SHOP TOWELS 12.00
PERSONAL SNACKS 8.00
SUBTOTAL 20.00
TAX 1.20
TOTAL 21.20
''',
  ),
  _ReceiptQaFixture(
    pack: 'retail',
    name: 'non business marker line allocation',
    merchantNeedle: 'target',
    expectedMerchantName: 'Target',
    expectLineItems: true,
    expectedDateIso: '2026-07-03',
    expectedTotal: 20.00,
    expectedLineCount: 2,
    expectedLineSubtotals: [5.00, 15.00],
    expectedLineDescriptionNeedles: ['snacks', 'work gloves'],
    expectedLineCategories: ['Meals', 'Safety Gear'],
    expectedLineFamilies: ['food_or_grocery', 'general_expense'],
    expectedLineUses: ['personal', 'business'],
    expectedBusinessTotal: 15.00,
    expectedPersonalTotal: 5.00,
    expectedReviewLineCount: 0,
    expectedDownstreamReadinessStatus: 'expense_lines_ready',
    expectedDownstreamReadinessSummary: 'Expense line review ready',
    text: '''
TARGET
07/03/2026
NON-BUSINESS SNACKS 5.00
BUSINESS WORK GLOVES 15.00
TOTAL 20.00
''',
  ),
];
