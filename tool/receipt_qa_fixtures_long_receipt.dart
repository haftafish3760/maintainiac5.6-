part of 'receipt_qa_runner.dart';

const _longReceiptQaFixtures = [
  _ReceiptQaFixture(
    pack: 'long_receipt',
    name: 'top section without bottom total asks for continuation',
    merchantNeedle: 'lowe',
    expectedMerchantName: "Lowe's",
    expectTotal: false,
    expectBottomCoverage: false,
    expectLineItems: true,
    expectedLineCount: 3,
    expectedLineSubtotals: [9.96, 6.98, 34.80],
    expectedLineDescriptionNeedles: ['stud', 'screws', 'romex'],
    expectedLineCategories: ['Materials', 'Materials', 'Materials'],
    expectedLineFamilies: ['materials', 'materials', 'materials'],
    expectedLineUses: ['business', 'business', 'business'],
    text: '''
LOWE'S HOME IMPROVEMENT
06/12/2026
2 @ 4.98 2X4X8 KD STUD 9.96
25PK #8 X 1-1/4 WOOD SCREWS 6.98
12 FT ROMEX 12/2 W/G 34.80
[missing bottom]
''',
  ),
  _ReceiptQaFixture(
    pack: 'long_receipt',
    name: 'middle section overlap still needs bottom total',
    merchantNeedle: 'lowe',
    expectedMerchantName: "Lowe's",
    expectDate: false,
    expectTotal: false,
    expectBottomCoverage: false,
    expectLineItems: true,
    expectedLineCount: 4,
    expectedLineSubtotals: [34.80, 14.50, 7.99, 8.97],
    expectedLineDescriptionNeedles: ['romex', 'pvc pipe', 'pvc glue', 'copper'],
    expectedLineCategories: [
      'Materials',
      'Materials',
      'Materials',
      'Materials',
    ],
    expectedLineFamilies: ['materials', 'materials', 'materials', 'materials'],
    expectedLineUses: ['business', 'business', 'business', 'business'],
    text: '''
LOWE'S CONTINUED
12 FT ROMEX 12/2 W/G 34.80
PVC PIPE SCH40 10 FT 14.50
PVC GLUE 7.99
COPPER COUPLING 8.97
[missing bottom]
''',
  ),
  _ReceiptQaFixture(
    pack: 'long_receipt',
    name: 'bottom section without repeated date still captures totals',
    merchantNeedle: 'lowe',
    expectedMerchantName: "Lowe's",
    expectDate: false,
    expectTax: true,
    expectLineItems: true,
    expectedSubtotal: 59.73,
    expectedTax: 3.58,
    expectedTotal: 63.31,
    expectedLineCount: 1,
    expectedLineSubtotals: [7.99],
    expectedLineDescriptionNeedles: ['pvc glue'],
    expectedLineCategories: ['Materials'],
    expectedLineFamilies: ['materials'],
    expectedLineUses: ['business'],
    expectedBusinessTotal: 63.31,
    expectedPersonalTotal: 0,
    expectedDownstreamReadinessStatus: 'expense_lines_need_review',
    expectedDownstreamReadinessSummary: 'Expense lines need review',
    expectedDownstreamReadinessCounts: {
      'parser_downstream_expense_lines_need_review': 1,
      'date_missing': 1,
      'line_ready': 1,
      'inventory_material_ready': 1,
      'category_family_materials_ready': 1,
    },
    text: '''
LOWE'S CONTINUED
PVC GLUE 7.99
SUBTOTAL 59.73
SALES TAX 3.58
TOTAL 63.31
''',
  ),
  _ReceiptQaFixture(
    pack: 'long_receipt',
    name: 'stitched overlap surfaces duplicate review diagnostics',
    merchantNeedle: 'lowe',
    expectedMerchantName: "Lowe's",
    expectTax: true,
    expectLineItems: true,
    expectedSubtotal: 73.23,
    expectedTax: 4.39,
    expectedTotal: 77.62,
    expectedParserTaskCounts: {
      'long_receipt_duplicate_text': 1,
      'long_receipt_probable_overlap': 1,
    },
    text: '''
LOWE'S HOME IMPROVEMENT
06/12/2026
2 @ 4.98 2X4X8 KD STUD 9.96
25PK #8 X 1-1/4 WOOD SCREWS 6.98
12 FT ROMEX 12/2 W/G 34.80
12 FT ROMEX 12/2 W/G 34.80
PVC PIPE SCH40 10 FT 14.50
PVC GLUE 7.99
SUBTOTAL 73.23
SALES TAX 4.39
TOTAL 77.62
''',
  ),
];
