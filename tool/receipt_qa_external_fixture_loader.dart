part of 'receipt_qa_runner.dart';

const _externallyLoadedReceiptQaPacks = {
  'adjustment',
  'contractor_supply',
  'damaged_ocr',
  'device_tiers',
  'fuel',
  'long_receipt',
  'maintenance',
  'noisy',
  'privacy_admin',
  'retail',
};

class _ExternalReceiptQaFixtureLoad {
  const _ExternalReceiptQaFixtureLoad({
    required this.fixtures,
    required this.blockers,
  });

  final List<_ReceiptQaFixture> fixtures;
  final List<String> blockers;
}

_ExternalReceiptQaFixtureLoad _loadExternalReceiptQaFixtures() {
  final fixtures = <_ReceiptQaFixture>[];
  final blockers = <String>[];
  for (final pack in _externallyLoadedReceiptQaPacks) {
    final path = '$_receiptQaExternalFixtureRoot/$pack.json';
    final file = File(path);
    if (!file.existsSync()) {
      blockers.add('External receipt QA pack is missing: $path.');
      continue;
    }
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('root must be a JSON object');
      }
      if (decoded['schema'] != _receiptQaExternalFixtureSchema) {
        throw FormatException(
          'schema must be $_receiptQaExternalFixtureSchema',
        );
      }
      if (decoded['pack'] != pack) {
        throw FormatException('pack must be $pack');
      }
      final rawFixtures = decoded['fixtures'];
      if (rawFixtures is! List || rawFixtures.isEmpty) {
        throw const FormatException('fixtures must be a non-empty array');
      }
      for (var index = 0; index < rawFixtures.length; index++) {
        final raw = rawFixtures[index];
        if (raw is! Map<String, Object?>) {
          throw FormatException('fixtures[$index] must be an object');
        }
        fixtures.add(_externalReceiptQaFixture(pack, raw, index));
      }
    } on Object catch (error) {
      blockers.add('External receipt QA pack is invalid: $path ($error).');
    }
  }
  return _ExternalReceiptQaFixtureLoad(
    fixtures: List.unmodifiable(fixtures),
    blockers: List.unmodifiable(blockers),
  );
}

_ReceiptQaFixture _externalReceiptQaFixture(
  String pack,
  Map<String, Object?> raw,
  int index,
) {
  final expected = raw['expected'];
  if (expected is! Map<String, Object?>) {
    throw FormatException('fixtures[$index].expected must be an object');
  }
  String requiredString(String key) {
    final value = raw[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('fixtures[$index].$key must be a non-empty string');
  }

  return _ReceiptQaFixture(
    pack: pack,
    name: requiredString('name'),
    merchantNeedle: requiredString('merchantNeedle'),
    text: requiredString('text'),
    expectedMerchantName: _jsonString(expected, 'merchantName'),
    expectFuel: _jsonBool(expected, 'expectFuel') ?? false,
    expectDate: _jsonBool(expected, 'expectDate') ?? true,
    expectTotal: _jsonBool(expected, 'expectTotal') ?? true,
    expectBottomCoverage: _jsonBool(expected, 'expectBottomCoverage') ?? true,
    expectTax: _jsonBool(expected, 'expectTax') ?? false,
    expectLineItems: _jsonBool(expected, 'expectLineItems') ?? false,
    expectMaintenance: _jsonBool(expected, 'expectMaintenance') ?? false,
    allowTenderAmountRows:
        _jsonBool(expected, 'allowTenderAmountRows') ?? false,
    expectedDateIso: _jsonString(expected, 'dateIso'),
    expectedSubtotal: _jsonDouble(expected, 'subtotal'),
    expectedTax: _jsonDouble(expected, 'tax'),
    expectedTotal: _jsonDouble(expected, 'total'),
    expectedLineCount: _jsonInt(expected, 'lineCount'),
    expectedLineSubtotals: _jsonDoubleList(expected, 'lineSubtotals'),
    expectedLineDescriptionNeedles: _jsonStringList(
      expected,
      'lineDescriptionNeedles',
    ),
    expectedLineCategories: _jsonStringList(expected, 'lineCategories'),
    expectedLineFamilies: _jsonStringList(expected, 'lineFamilies'),
    expectedLineUses: _jsonStringList(expected, 'lineUses'),
    expectedLineReviewModes: _jsonStringList(expected, 'lineReviewModes'),
    expectedLineNumberLabels: _jsonStringList(expected, 'lineNumberLabels'),
    expectedNegativeLineCount: _jsonInt(expected, 'negativeLineCount'),
    expectedAdjustmentLineCount: _jsonInt(expected, 'adjustmentLineCount'),
    expectReconciled: _jsonBool(expected, 'expectReconciled'),
    expectedFuelQuantity: _jsonDouble(expected, 'fuelQuantity'),
    expectedFuelUnitPrice: _jsonDouble(expected, 'fuelUnitPrice'),
    expectedFuelType: _jsonString(expected, 'fuelType'),
    expectedFuelUnit: _jsonString(expected, 'fuelUnit'),
    expectedFuelOdometer: _jsonInt(expected, 'fuelOdometer'),
    expectedMaintenanceServiceType: _jsonString(
      expected,
      'maintenanceServiceType',
    ),
    expectedMaintenanceOilWeight: _jsonString(expected, 'maintenanceOilWeight'),
    expectedMaintenanceServiceOdometer: _jsonInt(
      expected,
      'maintenanceServiceOdometer',
    ),
    expectedMaintenanceDueOdometer: _jsonInt(
      expected,
      'maintenanceDueOdometer',
    ),
    expectedMaintenanceIntervalMiles: _jsonInt(
      expected,
      'maintenanceIntervalMiles',
    ),
    expectedMaintenanceIntervalMonths: _jsonInt(
      expected,
      'maintenanceIntervalMonths',
    ),
    expectedBusinessTotal: _jsonDouble(expected, 'businessTotal'),
    expectedPersonalTotal: _jsonDouble(expected, 'personalTotal'),
    expectedReviewLineCount: _jsonInt(expected, 'reviewLineCount'),
    expectedDownstreamReadinessStatus: _jsonString(
      expected,
      'downstreamReadinessStatus',
    ),
    expectedDownstreamReadinessSummary: _jsonString(
      expected,
      'downstreamReadinessSummary',
    ),
    expectedDownstreamReadinessCounts: _jsonIntMap(
      expected,
      'downstreamReadinessCounts',
    ),
    expectedParserTaskCounts: _jsonIntMap(expected, 'parserTaskCounts'),
    deviceCapability: _jsonDeviceCapability(raw),
    expectedCapabilityTier: _jsonEnumByName(
      ReceiptCapabilityTier.values,
      expected,
      'capabilityTier',
    ),
    expectedParserDepth: _jsonEnumByName(
      ReceiptParserDepth.values,
      expected,
      'parserDepth',
    ),
    expectedDataSaverLevel: _jsonEnumByName(
      ReceiptDataSaverLevel.values,
      expected,
      'dataSaverLevel',
    ),
    expectedMaxLocalPhotoCount: _jsonInt(expected, 'maxLocalPhotoCount'),
    expectedMaxLocalPhotoBytes: _jsonInt(expected, 'maxLocalPhotoBytes'),
    expectedAssistedCameraShotCount: _jsonInt(
      expected,
      'assistedCameraShotCount',
    ),
    expectedBestShotCandidateCount: _jsonInt(
      expected,
      'bestShotCandidateCount',
    ),
    expectedMaxStitchOutputPixels: _jsonInt(expected, 'maxStitchOutputPixels'),
    expectedMaxStitchOutputHeight: _jsonInt(expected, 'maxStitchOutputHeight'),
    expectedOptionalLocalPackBytes: _jsonInt(
      expected,
      'optionalLocalPackBytes',
    ),
    expectedCloudOcrOptional: _jsonBool(expected, 'cloudOcrOptional'),
    expectedCloudInventoryOptional: _jsonBool(
      expected,
      'cloudInventoryOptional',
    ),
    expectedAutoCaptureEnabled: _jsonBool(expected, 'autoCaptureEnabled'),
    photoQuality: _jsonPhotoQuality(raw),
    expectedPhotoPrimaryIssueLabel: _jsonString(
      expected,
      'photoPrimaryIssueLabel',
    ),
    expectedPhotoReviewActionCode: _jsonString(
      expected,
      'photoReviewActionCode',
    ),
    expectedPhotoShouldRetakeBeforeOcr: _jsonBool(
      expected,
      'photoShouldRetakeBeforeOcr',
    ),
    expectedPhotoCanContinueWithReview: _jsonBool(
      expected,
      'photoCanContinueWithReview',
    ),
    expectedPhotoNeedsReview: _jsonBool(expected, 'photoNeedsReview'),
    expectedPhotoLightLabel: _jsonString(expected, 'photoLightLabel'),
    expectedPhotoFocusLabel: _jsonString(expected, 'photoFocusLabel'),
    expectedPhotoWarningNeedles: _jsonStringList(
      expected,
      'photoWarningNeedles',
    ),
    expectedPhotoGuidanceNeedles: _jsonStringList(
      expected,
      'photoGuidanceNeedles',
    ),
    barcodeCodes: _jsonBarcodeCodes(raw),
    barcodeWarnings: _jsonStringList(raw, 'barcodeWarnings'),
    expectedBarcodeCodeCount: _jsonInt(expected, 'barcodeCodeCount'),
    expectedQrCodeCount: _jsonInt(expected, 'qrCodeCount'),
    expectedInventoryLookupCandidateCount: _jsonInt(
      expected,
      'inventoryLookupCandidateCount',
    ),
    expectedBarcodeFormatBuckets: _jsonIntMap(expected, 'barcodeFormatBuckets'),
    expectedBarcodeWarningBuckets: _jsonStringList(
      expected,
      'barcodeWarningBuckets',
    ),
    expectedSensitiveLineCount: _jsonInt(expected, 'sensitiveLineCount'),
    expectedTenderPrivacyLineCount: _jsonInt(
      expected,
      'tenderPrivacyLineCount',
    ),
    expectedAddressContactLineCount: _jsonInt(
      expected,
      'addressContactLineCount',
    ),
    expectedPrivateNameLineCount: _jsonInt(expected, 'privateNameLineCount'),
    expectedSensitiveNeedlesExcluded: _jsonStringList(
      expected,
      'sensitiveNeedlesExcluded',
    ),
  );
}

T? _jsonEnumByName<T extends Enum>(
  Iterable<T> values,
  Map<String, Object?> map,
  String key,
) {
  final name = _jsonString(map, key);
  if (name == null) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException('$key has unsupported value $name');
}

ReceiptDeviceCapability? _jsonDeviceCapability(Map<String, Object?> raw) {
  final profile = _jsonString(raw, 'deviceCapabilityProfile');
  return switch (profile) {
    null => null,
    'olderPhone' => const ReceiptDeviceCapability.olderPhone(),
    'standard' => const ReceiptDeviceCapability.standard(),
    'highCapacity' => const ReceiptDeviceCapability.highCapacity(),
    'highCapacityCriticalStorage' =>
      const ReceiptDeviceCapability.highCapacity().withStoragePressure(
        ReceiptDeviceStorageClass.critical,
      ),
    _ => throw FormatException(
      'deviceCapabilityProfile has unsupported value $profile',
    ),
  };
}

ReceiptPhotoQualityCheck? _jsonPhotoQuality(Map<String, Object?> raw) {
  final value = raw['photoQuality'];
  if (value == null) return null;
  if (value is! Map<String, Object?>) {
    throw const FormatException('photoQuality must be an object');
  }
  return ReceiptPhotoQualityCheck(
    width: _requiredJsonInt(value, 'width'),
    height: _requiredJsonInt(value, 'height'),
    focusScore: _requiredJsonDouble(value, 'focusScore'),
    detailScore: _jsonDouble(value, 'detailScore'),
    brightness: _jsonDouble(value, 'brightness') ?? 128,
    contrast: _jsonDouble(value, 'contrast') ?? 28,
    cropScore: _jsonDouble(value, 'cropScore') ?? .72,
    textBandScore: _jsonDouble(value, 'textBandScore') ?? 12,
    largestInteriorTextGapRatio:
        _jsonDouble(value, 'largestInteriorTextGapRatio') ?? 0,
    inkCoverage: _jsonDouble(value, 'inkCoverage') ?? .18,
    isLikelyReadable: _requiredJsonBool(value, 'isLikelyReadable'),
  );
}

List<ReceiptQaBarcodeCode> _jsonBarcodeCodes(Map<String, Object?> raw) {
  final value = raw['barcodeCodes'];
  if (value == null) return const [];
  if (value is! List) {
    throw const FormatException('barcodeCodes must be an array');
  }
  return value.indexed
      .map((entry) {
        final (index, item) = entry;
        if (item is! Map<String, Object?>) {
          throw FormatException('barcodeCodes[$index] must be an object');
        }
        return ReceiptQaBarcodeCode(
          format: _requiredJsonString(item, 'format'),
          valueType: _requiredJsonString(item, 'valueType'),
          rawValue: _jsonString(item, 'rawValue') ?? '',
          displayValue: _jsonString(item, 'displayValue') ?? '',
        );
      })
      .toList(growable: false);
}

String _requiredJsonString(Map<String, Object?> map, String key) {
  final value = _jsonString(map, key);
  if (value != null && value.trim().isNotEmpty) return value;
  throw FormatException('$key must be a non-empty string');
}

int _requiredJsonInt(Map<String, Object?> map, String key) {
  final value = _jsonInt(map, key);
  if (value != null) return value;
  throw FormatException('$key must be an integer');
}

double _requiredJsonDouble(Map<String, Object?> map, String key) {
  final value = _jsonDouble(map, key);
  if (value != null) return value;
  throw FormatException('$key must be a number');
}

bool _requiredJsonBool(Map<String, Object?> map, String key) {
  final value = _jsonBool(map, key);
  if (value != null) return value;
  throw FormatException('$key must be a boolean');
}

String? _jsonString(Map<String, Object?> map, String key) {
  final value = map[key];
  return value is String ? value : null;
}

bool? _jsonBool(Map<String, Object?> map, String key) {
  final value = map[key];
  return value is bool ? value : null;
}

double? _jsonDouble(Map<String, Object?> map, String key) {
  final value = map[key];
  return value is num ? value.toDouble() : null;
}

int? _jsonInt(Map<String, Object?> map, String key) {
  final value = map[key];
  return value is num ? value.toInt() : null;
}

List<String> _jsonStringList(Map<String, Object?> map, String key) {
  final value = map[key];
  return value is List ? value.whereType<String>().toList() : const [];
}

List<double> _jsonDoubleList(Map<String, Object?> map, String key) {
  final value = map[key];
  return value is List
      ? value.whereType<num>().map((item) => item.toDouble()).toList()
      : const [];
}

Map<String, int> _jsonIntMap(Map<String, Object?> map, String key) {
  final value = map[key];
  if (value is! Map<String, Object?>) return const {};
  return {
    for (final entry in value.entries)
      if (entry.value is num) entry.key: (entry.value as num).toInt(),
  };
}
