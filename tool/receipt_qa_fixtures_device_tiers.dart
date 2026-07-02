part of 'receipt_qa_runner.dart';

final _criticalStorageFlagship = const ReceiptDeviceCapability.highCapacity()
    .withStoragePressure(ReceiptDeviceStorageClass.critical);

final _deviceTierReceiptQaFixtures = [
  _ReceiptQaFixture(
    pack: 'device_tiers',
    name: 'older phone keeps receipt OCR workload lean',
    merchantNeedle: 'casey',
    expectedMerchantName: "Casey's",
    expectedDateIso: '2026-06-14',
    expectedSubtotal: 42.41,
    expectedTax: 0,
    expectedTotal: 42.41,
    deviceCapability: ReceiptDeviceCapability.olderPhone(),
    expectedCapabilityTier: ReceiptCapabilityTier.light,
    expectedParserDepth: ReceiptParserDepth.proofTotalsOnly,
    expectedDataSaverLevel: ReceiptDataSaverLevel.strong,
    expectedMaxLocalPhotoCount: 4,
    expectedMaxLocalPhotoBytes: 6 * 1024 * 1024,
    expectedAssistedCameraShotCount: 2,
    expectedBestShotCandidateCount: 1,
    expectedMaxStitchOutputPixels: 9000000,
    expectedMaxStitchOutputHeight: 14000,
    expectedOptionalLocalPackBytes: 0,
    expectedCloudOcrOptional: true,
    expectedCloudInventoryOptional: true,
    expectedAutoCaptureEnabled: false,
    text: '''
CASEY'S GENERAL STORE
06/14/2026
UNLEADED
11.482 GAL @ 3.693
SUBTOTAL 42.41
TAX 0.00
TOTAL 42.41
''',
  ),
  _ReceiptQaFixture(
    pack: 'device_tiers',
    name: 'critical storage defers optional packs and cloud assists',
    merchantNeedle: 'lowe',
    expectedMerchantName: "Lowe's",
    expectedDateIso: '2026-06-15',
    expectedSubtotal: 19.94,
    expectedTax: 1.20,
    expectedTotal: 21.14,
    expectTax: true,
    expectedLineCount: 2,
    expectedLineSubtotals: [9.96, 9.98],
    expectedLineDescriptionNeedles: ['stud', 'connector'],
    expectedLineCategories: ['Materials', 'Uncategorized'],
    expectedLineFamilies: ['materials', 'uncategorized'],
    expectedLineUses: ['business', 'business'],
    deviceCapability: _criticalStorageFlagship,
    expectedCapabilityTier: ReceiptCapabilityTier.light,
    expectedParserDepth: ReceiptParserDepth.proofTotalsOnly,
    expectedDataSaverLevel: ReceiptDataSaverLevel.maximum,
    expectedMaxLocalPhotoCount: 4,
    expectedMaxLocalPhotoBytes: 4 * 1024 * 1024,
    expectedAssistedCameraShotCount: 1,
    expectedBestShotCandidateCount: 1,
    expectedMaxStitchOutputPixels: 9000000,
    expectedMaxStitchOutputHeight: 14000,
    expectedOptionalLocalPackBytes: 0,
    expectedCloudOcrOptional: true,
    expectedCloudInventoryOptional: true,
    expectedAutoCaptureEnabled: false,
    text: '''
LOWE'S HOME IMPROVEMENT
06/15/2026
2 @ 4.98 2X4X8 KD STUD 9.96
METAL CONNECTOR PACK 9.98
SUBTOTAL 19.94
SALES TAX 1.20
TOTAL 21.14
''',
  ),
];
