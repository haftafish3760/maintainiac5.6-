part of 'receipt_qa_runner.dart';

const _receiptQaFixtureManifestVersion = 'receipt_qa_fixture_manifest_v1';
const _receiptQaFixtureFormat = 'inline_dart_expected_fields_v1';
const _receiptQaExternalFixtureSchema = 'receipt_qa_fixture_v1';
const _receiptQaExternalFixtureRoot = 'test/fixtures/receipt_qa';
const _receiptQaExternalFixtureSchemaFile =
    'test/fixtures/receipt_qa/receipt_qa_fixture_v1.schema.json';
const _receiptQaExternalFixtureInventoryFile =
    'test/fixtures/receipt_qa/fixture_pack_inventory.json';
const _receiptQaFixtureTextPolicy =
    'raw_text_allowed_only_in_fixture_files_not_reports';

const _receiptQaFixtureSources = {
  'adjustment': 'tool/receipt_qa_fixtures_adjustment_retail.dart',
  'contractor_supply': 'tool/receipt_qa_fixtures_contractor_supply.dart',
  'damaged_ocr': 'tool/receipt_qa_fixtures_damaged_ocr.dart',
  'device_tiers': 'tool/receipt_qa_fixtures_device_tiers.dart',
  'fuel': 'tool/receipt_qa_fixtures_fuel.dart',
  'long_receipt': 'tool/receipt_qa_fixtures_long_receipt.dart',
  'maintenance': 'tool/receipt_qa_fixtures_maintenance.dart',
  'noisy': 'tool/receipt_qa_fixtures_fuel.dart',
  'privacy_admin': 'tool/receipt_qa_fixtures_privacy_admin.dart',
  'retail': 'tool/receipt_qa_fixtures_adjustment_retail.dart',
};

const _receiptQaFixtureRequiredFields = [
  'pack',
  'name',
  'merchantNeedle',
  'text',
  'expectedMerchantName',
  'expectedDateIso',
  'expectedTotal',
  'expectedLineCount',
  'expectedLineCategories',
  'expectedLineFamilies',
  'expectedLineUses',
  'expectedPhotoPrimaryIssueLabel',
  'expectedPhotoReviewActionCode',
  'expectedPhotoShouldRetakeBeforeOcr',
  'expectedPhotoCanContinueWithReview',
  'expectedPhotoNeedsReview',
  'expectedBarcodeCodeCount',
  'expectedQrCodeCount',
  'expectedInventoryLookupCandidateCount',
  'expectedBarcodeFormatBuckets',
  'expectedBarcodeWarningBuckets',
];

Map<String, Object?> _fixtureManifestToJson(List<String> availablePacks) {
  final packs = availablePacks.where((pack) => pack != 'all').toList()..sort();
  return {
    'version': _receiptQaFixtureManifestVersion,
    'format': _receiptQaFixtureFormat,
    'requiredFields': _receiptQaFixtureRequiredFields,
    'packSources': {
      for (final pack in packs) pack: _receiptQaFixtureSources[pack],
    },
    'externalFixturePlan': _externalFixturePlanToJson(packs),
    'realFixtureSupport': _realFixtureSupportToJson(),
    'externalFixtureFilesReady': false,
  };
}

List<String> _fixtureManifestBlockers(List<String> availablePacks) {
  final missing = availablePacks
      .where(
        (pack) => pack != 'all' && !_receiptQaFixtureSources.containsKey(pack),
      )
      .toList();
  if (missing.isEmpty) return const [];
  return [
    'Receipt QA fixture manifest is missing pack source entries: '
        '${missing.join(', ')}.',
  ];
}

Map<String, Object?> _fixtureFieldCoverageToJson(
  List<_ReceiptQaFixture> fixtures,
) {
  final grouped = <String, List<_ReceiptQaFixture>>{};
  for (final fixture in fixtures) {
    grouped.putIfAbsent(fixture.pack, () => []).add(fixture);
  }
  final packs = grouped.keys.toList()..sort();
  return {
    'format': 'fixture_field_coverage_v1',
    'externalFixtureFilesReady': false,
    'allRequiredFields': _receiptQaFixtureRequiredFields,
    'packs': {
      for (final pack in packs)
        pack: _fixturePackFieldCoverageToJson(grouped[pack]!),
    },
  };
}

Map<String, Object?> _fixturePackFieldCoverageToJson(
  List<_ReceiptQaFixture> fixtures,
) {
  final fieldCounts = <String, int>{};
  for (final field in _receiptQaFixtureRequiredFields) {
    fieldCounts[field] = fixtures.where((fixture) {
      return _fixtureHasRequiredField(fixture, field);
    }).length;
  }
  final missingCounts = <String, int>{};
  for (final entry in fieldCounts.entries) {
    final missing = fixtures.length - entry.value;
    if (missing > 0) missingCounts[entry.key] = missing;
  }
  return {
    'fixtureCount': fixtures.length,
    'requiredFields': fieldCounts,
    'missingRequiredFieldCounts': missingCounts,
    'readyForExternalExport': missingCounts.isEmpty,
  };
}

bool _fixtureHasRequiredField(_ReceiptQaFixture fixture, String field) {
  switch (field) {
    case 'pack':
      return fixture.pack.isNotEmpty;
    case 'name':
      return fixture.name.isNotEmpty;
    case 'merchantNeedle':
      return fixture.merchantNeedle.isNotEmpty;
    case 'text':
      return fixture.text.isNotEmpty;
    case 'expectedMerchantName':
      return fixture.expectedMerchantName != null;
    case 'expectedDateIso':
      return fixture.expectedDateIso != null;
    case 'expectedTotal':
      return fixture.expectedTotal != null;
    case 'expectedLineCount':
      return fixture.expectedLineCount != null;
    case 'expectedLineCategories':
      return fixture.expectedLineCategories.isNotEmpty;
    case 'expectedLineFamilies':
      return fixture.expectedLineFamilies.isNotEmpty;
    case 'expectedLineUses':
      return fixture.expectedLineUses.isNotEmpty;
    case 'expectedPhotoPrimaryIssueLabel':
      return fixture.expectedPhotoPrimaryIssueLabel != null;
    case 'expectedPhotoReviewActionCode':
      return fixture.expectedPhotoReviewActionCode != null;
    case 'expectedPhotoShouldRetakeBeforeOcr':
      return fixture.expectedPhotoShouldRetakeBeforeOcr != null;
    case 'expectedPhotoCanContinueWithReview':
      return fixture.expectedPhotoCanContinueWithReview != null;
    case 'expectedPhotoNeedsReview':
      return fixture.expectedPhotoNeedsReview != null;
    case 'expectedBarcodeCodeCount':
      return fixture.expectedBarcodeCodeCount != null;
    case 'expectedQrCodeCount':
      return fixture.expectedQrCodeCount != null;
    case 'expectedInventoryLookupCandidateCount':
      return fixture.expectedInventoryLookupCandidateCount != null;
    case 'expectedBarcodeFormatBuckets':
      return fixture.expectedBarcodeFormatBuckets.isNotEmpty;
    case 'expectedBarcodeWarningBuckets':
      return fixture.expectedBarcodeWarningBuckets.isNotEmpty;
  }
  return false;
}

Map<String, Object?> _externalFixturePlanToJson(List<String> packs) {
  return {
    'schema': _receiptQaExternalFixtureSchema,
    'schemaFile': _receiptQaExternalFixtureSchemaFile,
    'inventoryFile': _receiptQaExternalFixtureInventoryFile,
    'root': _receiptQaExternalFixtureRoot,
    'textPolicy': _receiptQaFixtureTextPolicy,
    'packFiles': {
      for (final pack in packs)
        pack: '$_receiptQaExternalFixtureRoot/$pack.json',
    },
    'summaryReportExcludes': const [
      'text',
      'rawText',
      'ocrText',
      'receiptImagePath',
      'sourceImageBytes',
      'cardNumber',
      'customerName',
    ],
    'requiredBeforeReady': const [
      'external JSON/CSV fixture files exist for every pack',
      'runner loads external fixtures through the schema',
      'summary reports continue to expose counts and outcomes only',
    ],
  };
}

Map<String, Object?> _realFixtureSupportToJson() {
  return const {
    'status': 'schema_ready_no_real_samples',
    'privacyPolicy': 'synthetic_or_redacted_only',
    'expectedOutputsEditable': true,
    'sensitiveThirdPartyDataAllowed': false,
    'artifactPolicy': 'original_capture_preserved_derived_artifacts_separate',
    'fixtureKinds': [
      'synthetic_text',
      'synthetic_image',
      'real_redacted',
      'real_anonymized',
    ],
  };
}
