part of 'receipt_qa_runner.dart';

const _privacyAdminReceiptQaFixtures = [
  _ReceiptQaFixture(
    pack: 'privacy_admin',
    name: 'card auth address and phone stay privacy metadata',
    merchantNeedle: 'lowe',
    expectedMerchantName: "Lowe's",
    allowTenderAmountRows: true,
    expectedDateIso: '2026-06-21',
    expectedSubtotal: 21.47,
    expectedTax: 1.29,
    expectedTotal: 22.76,
    expectTax: true,
    expectedLineCount: 2,
    expectedLineSubtotals: [7.99, 13.48],
    expectedLineDescriptionNeedles: ['pvc glue', 'stud'],
    expectedLineCategories: ['Materials', 'Materials'],
    expectedLineFamilies: ['materials', 'materials'],
    expectedLineUses: ['business', 'business'],
    expectedSensitiveLineCount: 4,
    expectedTenderPrivacyLineCount: 2,
    expectedAddressContactLineCount: 1,
    expectedPrivateNameLineCount: 1,
    expectedSensitiveNeedlesExcluded: [
      'AUTH 998877',
      'CARD 4111',
      'AUSTIN TX',
      'JOHN Q CUSTOMER',
    ],
    text: '''
LOWE'S HOME IMPROVEMENT
123 MAIN ST AUSTIN TX 78745 (512) 555-0188
JOHN Q CUSTOMER
06/21/2026
PVC GLUE 7.99
2 @ 6.74 2X4 STUD 13.48
SUBTOTAL 21.47
SALES TAX 1.29
TOTAL 22.76
VISA CARD 4111 22.76
AUTH 998877
''',
  ),
  _ReceiptQaFixture(
    pack: 'privacy_admin',
    name: 'fleet card and reference rows never become purchase lines',
    merchantNeedle: 'shell',
    expectedMerchantName: 'Shell',
    allowTenderAmountRows: true,
    expectedDateIso: '2026-06-22',
    expectedSubtotal: 46.02,
    expectedTax: 0,
    expectedTotal: 46.02,
    expectFuel: true,
    expectedFuelQuantity: 12.012,
    expectedFuelUnitPrice: 3.831,
    expectedSensitiveLineCount: 3,
    expectedTenderPrivacyLineCount: 3,
    expectedAddressContactLineCount: 0,
    expectedPrivateNameLineCount: 0,
    expectedSensitiveNeedlesExcluded: [
      'FLEET CARD',
      'TRACE 555013',
      'AUTH 112233',
    ],
    text: '''
SHELL
06/22/2026
REGULAR UNLEADED
12.012 GAL @ 3.831
SUBTOTAL 46.02
TAX 0.00
TOTAL 46.02
FLEET CARD 46.02
TRACE 555013
AUTH 112233
''',
  ),
];
