part of 'receipt_qa_runner.dart';

final _damagedOcrReceiptQaFixtures = [
  _ReceiptQaFixture(
    pack: 'damaged_ocr',
    name: 'wrinkled long receipt top section still asks for continuation',
    merchantNeedle: 'cvs',
    expectedMerchantName: 'CVS Pharmacy',
    expectedDateIso: '2026-06-22',
    expectTotal: false,
    expectBottomCoverage: false,
    expectLineItems: true,
    expectedLineCount: 2,
    expectedLineSubtotals: [12.49, 8.99],
    expectedLineDescriptionNeedles: const ['paper towels', 'trash bags'],
    photoQuality: const ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 15,
      brightness: 142,
      contrast: 30,
      cropScore: .24,
      textBandScore: 12,
      isLikelyReadable: false,
    ),
    expectedPhotoPrimaryIssueLabel: 'check that no text is cut off',
    expectedPhotoReviewActionCode: 'crop_or_retake_then_next',
    expectedPhotoShouldRetakeBeforeOcr: false,
    expectedPhotoCanContinueWithReview: true,
    expectedPhotoNeedsReview: true,
    expectedPhotoLightLabel: 'light OK',
    expectedPhotoFocusLabel: 'sharp',
    expectedPhotoWarningNeedles: const ['every receipt line'],
    expectedPhotoGuidanceNeedles: const ['every line', 'part of the receipt'],
    text: '''
CVS PHARMACY
06/22/2026
PAPER TOWELS 12.49
TRASH BAGS 8.99
[wrinkled middle and missing bottom]
''',
  ),
  _ReceiptQaFixture(
    pack: 'damaged_ocr',
    name: 'smudged long receipt overlap keeps duplicate review diagnostics',
    merchantNeedle: 'advance',
    expectedMerchantName: 'Advance Auto Parts',
    expectedDateIso: '2026-06-24',
    expectedSubtotal: 41.47,
    expectedTax: 2.49,
    expectedTotal: 43.96,
    expectTax: true,
    expectLineItems: true,
    expectedLineCount: 4,
    expectedLineSubtotals: [14.99, 8.49, 8.49, 9.50],
    expectedLineDescriptionNeedles: const [
      'shop towels',
      'brake clean',
      'brake clean',
      'gloves',
    ],
    expectedParserTaskCounts: const {
      'long_receipt_duplicate_text': 1,
      'long_receipt_probable_overlap': 1,
    },
    photoQuality: const ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 10,
      brightness: 146,
      contrast: 14,
      cropScore: .70,
      textBandScore: 10,
      isLikelyReadable: false,
    ),
    expectedPhotoPrimaryIssueLabel: 'low contrast',
    expectedPhotoReviewActionCode: 'check_photo_then_next',
    expectedPhotoShouldRetakeBeforeOcr: false,
    expectedPhotoCanContinueWithReview: true,
    expectedPhotoNeedsReview: true,
    expectedPhotoLightLabel: 'light OK',
    expectedPhotoFocusLabel: 'usable',
    expectedPhotoWarningNeedles: const ['low contrast'],
    expectedPhotoGuidanceNeedles: const ['printed text', 'stands out'],
    text: '''
ADVANCE AUTO PARTS
06/24/2026
SHOP TOWELS 14.99
BRAKE CLEAN 8.49
BRAKE CLEAN 8.49
NITRILE GLOVES 9.50
SUBTOTAL 41.47
SALES TAX 2.49
TOTAL 43.96
''',
  ),
  _ReceiptQaFixture(
    pack: 'damaged_ocr',
    name: 'blurry receipt source requires retake guidance',
    merchantNeedle: 'pilot',
    expectedMerchantName: 'Pilot Flying J',
    expectedDateIso: '2026-06-17',
    expectedSubtotal: 58.44,
    expectedTax: 0,
    expectedTotal: 58.44,
    photoQuality: const ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 4.8,
      brightness: 148,
      contrast: 30,
      cropScore: .72,
      textBandScore: 12,
      isLikelyReadable: false,
    ),
    expectedPhotoPrimaryIssueLabel: 'looks blurry',
    expectedPhotoReviewActionCode: 'retake_recommended_continue_allowed',
    expectedPhotoShouldRetakeBeforeOcr: true,
    expectedPhotoCanContinueWithReview: true,
    expectedPhotoNeedsReview: true,
    expectedPhotoLightLabel: 'light OK',
    expectedPhotoFocusLabel: 'may be blurry',
    expectedPhotoWarningNeedles: const ['blurry'],
    expectedPhotoGuidanceNeedles: const ['Hold steady', 'fuzzy'],
    text: '''
PILOT TRAVEL CENTER
06/17/2026
DIESEL FUEL
15.005 GAL @ 3.895
SUBTOTAL 58.44
TAX 0.00
TOTAL 58.44
''',
  ),
  _ReceiptQaFixture(
    pack: 'damaged_ocr',
    name: 'glare washed receipt source requires retake guidance',
    merchantNeedle: 'casey',
    expectedMerchantName: "Casey's",
    expectedDateIso: '2026-06-18',
    expectedSubtotal: 31.20,
    expectedTax: 0,
    expectedTotal: 31.20,
    photoQuality: const ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 15,
      brightness: 250,
      contrast: 30,
      cropScore: .72,
      textBandScore: 12,
      isLikelyReadable: false,
    ),
    expectedPhotoPrimaryIssueLabel: 'glare or too bright',
    expectedPhotoReviewActionCode: 'retake_recommended_continue_allowed',
    expectedPhotoShouldRetakeBeforeOcr: true,
    expectedPhotoCanContinueWithReview: true,
    expectedPhotoNeedsReview: true,
    expectedPhotoLightLabel: 'glare/too bright',
    expectedPhotoFocusLabel: 'sharp',
    expectedPhotoWarningNeedles: const ['glare', 'too bright'],
    expectedPhotoGuidanceNeedles: const ['Reduce glare', 'tilting'],
    text: '''
CASEY'S GENERAL STORE
06/18/2026
UNLEADED
8.452 GAL @ 3.691
SUBTOTAL 31.20
TAX 0.00
TOTAL 31.20
''',
  ),
  _ReceiptQaFixture(
    pack: 'damaged_ocr',
    name: 'low light receipt source requires retake guidance',
    merchantNeedle: 'sheetz',
    expectedMerchantName: 'Sheetz',
    expectedDateIso: '2026-06-21',
    expectedSubtotal: 14.96,
    expectedTax: 0.90,
    expectedTotal: 15.86,
    expectTax: true,
    photoQuality: const ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 15,
      brightness: 52,
      contrast: 30,
      cropScore: .72,
      textBandScore: 12,
      isLikelyReadable: false,
    ),
    expectedPhotoPrimaryIssueLabel: 'too dark',
    expectedPhotoReviewActionCode: 'retake_recommended_continue_allowed',
    expectedPhotoShouldRetakeBeforeOcr: true,
    expectedPhotoCanContinueWithReview: true,
    expectedPhotoNeedsReview: true,
    expectedPhotoLightLabel: 'too dark',
    expectedPhotoFocusLabel: 'sharp',
    expectedPhotoWarningNeedles: const ['too dark'],
    expectedPhotoGuidanceNeedles: const ['Add light', 'torch'],
    text: '''
SHEETZ
06/21/2026
SHOP TOWELS 8.97
CASE WATER 5.99
SUBTOTAL 14.96
SALES TAX 0.90
TOTAL 15.86
''',
  ),
  _ReceiptQaFixture(
    pack: 'damaged_ocr',
    name: 'partial crop source stays in crop or retake review',
    merchantNeedle: 'lowe',
    expectedMerchantName: "Lowe's",
    expectedDateIso: '2026-06-19',
    expectedSubtotal: 16.94,
    expectedTax: 1.02,
    expectedTotal: 17.96,
    expectTax: true,
    photoQuality: const ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 15,
      brightness: 148,
      contrast: 30,
      cropScore: .24,
      textBandScore: 12,
      isLikelyReadable: false,
    ),
    expectedPhotoPrimaryIssueLabel: 'check that no text is cut off',
    expectedPhotoReviewActionCode: 'crop_or_retake_then_next',
    expectedPhotoShouldRetakeBeforeOcr: false,
    expectedPhotoCanContinueWithReview: true,
    expectedPhotoNeedsReview: true,
    expectedPhotoLightLabel: 'light OK',
    expectedPhotoFocusLabel: 'sharp',
    expectedPhotoWarningNeedles: const ['every receipt line'],
    expectedPhotoGuidanceNeedles: const ['every line', 'part of the receipt'],
    text: '''
LOWE'S HOME IMPROVEMENT
06/19/2026
CAULK WHITE 6.98
PAINTER TAPE 9.96
SUBTOTAL 16.94
SALES TAX 1.02
TOTAL 17.96
''',
  ),
  _ReceiptQaFixture(
    pack: 'damaged_ocr',
    name: 'weak low contrast text asks for review before OCR',
    merchantNeedle: 'quick lube',
    expectedMerchantName: 'Quick Lube',
    expectedDateIso: '2026-06-20',
    expectedSubtotal: 48.48,
    expectedTax: 2.91,
    expectedTotal: 51.39,
    expectTax: true,
    photoQuality: const ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2400,
      focusScore: 13,
      brightness: 132,
      contrast: 12,
      cropScore: .68,
      textBandScore: 5,
      isLikelyReadable: false,
    ),
    expectedPhotoPrimaryIssueLabel: 'low contrast',
    expectedPhotoReviewActionCode: 'check_readability_or_add_closer_photo',
    expectedPhotoShouldRetakeBeforeOcr: false,
    expectedPhotoCanContinueWithReview: true,
    expectedPhotoNeedsReview: true,
    expectedPhotoLightLabel: 'light OK',
    expectedPhotoFocusLabel: 'usable',
    expectedPhotoWarningNeedles: const ['low contrast', 'hard to detect'],
    expectedPhotoGuidanceNeedles: const ['printed text', 'stands out'],
    text: '''
QUICK LUBE
06/20/2026
5W-20 SYNTHETIC OIL 39.99
OIL FILTER 8.49
SUBTOTAL 48.48
SALES TAX 2.91
TOTAL 51.39
''',
  ),
];
