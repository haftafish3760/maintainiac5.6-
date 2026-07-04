part of 'receipt_qa_runner.dart';

const _receiptQaBarcodeMaxLookupLength = 128;

void _addBarcodeScannerIssues({
  required _ReceiptQaFixture fixture,
  required List<String> issues,
}) {
  final summary = _receiptQaBarcodeSummary(fixture);
  if (fixture.expectedBarcodeCodeCount != null &&
      summary.codeCount != fixture.expectedBarcodeCodeCount) {
    issues.add('barcode_scanner_code_count_mismatch');
  }
  if (fixture.expectedQrCodeCount != null &&
      summary.qrCodeCount != fixture.expectedQrCodeCount) {
    issues.add('barcode_scanner_qr_count_mismatch');
  }
  if (fixture.expectedInventoryLookupCandidateCount != null &&
      summary.inventoryLookupCandidateCount !=
          fixture.expectedInventoryLookupCandidateCount) {
    issues.add('barcode_scanner_inventory_lookup_count_mismatch');
  }
  if (fixture.expectedBarcodeFormatBuckets.isNotEmpty &&
      !_countMapsMatch(
        summary.formatBuckets,
        fixture.expectedBarcodeFormatBuckets,
      )) {
    issues.add('barcode_scanner_format_buckets_mismatch');
  }
  if (fixture.expectedBarcodeWarningBuckets.isNotEmpty &&
      !_stringListsMatch(
        summary.warningBuckets,
        fixture.expectedBarcodeWarningBuckets,
      )) {
    issues.add('barcode_scanner_warning_buckets_mismatch');
  }
}

void _addBarcodeScannerChecks({
  required _ReceiptQaFixture fixture,
  required List<_ReceiptQaCheck> checks,
}) {
  if (!_hasBarcodeExpectations(fixture)) return;
  final summary = _receiptQaBarcodeSummary(fixture);

  void addCheck(String name, bool passed) {
    checks.add(
      _ReceiptQaCheck(
        dimension: 'barcode_qr_scanning',
        name: name,
        passed: passed,
      ),
    );
  }

  if (fixture.expectedBarcodeCodeCount != null) {
    addCheck(
      'barcode_code_count_matched',
      summary.codeCount == fixture.expectedBarcodeCodeCount,
    );
  }
  if (fixture.expectedQrCodeCount != null) {
    addCheck(
      'qr_code_count_matched',
      summary.qrCodeCount == fixture.expectedQrCodeCount,
    );
  }
  if (fixture.expectedInventoryLookupCandidateCount != null) {
    addCheck(
      'inventory_lookup_candidate_count_matched',
      summary.inventoryLookupCandidateCount ==
          fixture.expectedInventoryLookupCandidateCount,
    );
  }
  if (fixture.expectedBarcodeFormatBuckets.isNotEmpty) {
    addCheck(
      'barcode_format_buckets_matched',
      _countMapsMatch(
        summary.formatBuckets,
        fixture.expectedBarcodeFormatBuckets,
      ),
    );
  }
  if (fixture.expectedBarcodeWarningBuckets.isNotEmpty) {
    addCheck(
      'barcode_warning_buckets_matched',
      _stringListsMatch(
        summary.warningBuckets,
        fixture.expectedBarcodeWarningBuckets,
      ),
    );
  }
}

bool _hasBarcodeExpectations(_ReceiptQaFixture fixture) {
  return fixture.expectedBarcodeCodeCount != null ||
      fixture.expectedQrCodeCount != null ||
      fixture.expectedInventoryLookupCandidateCount != null ||
      fixture.expectedBarcodeFormatBuckets.isNotEmpty ||
      fixture.expectedBarcodeWarningBuckets.isNotEmpty;
}

_ReceiptQaBarcodeSummary _receiptQaBarcodeSummary(_ReceiptQaFixture fixture) {
  final formatBuckets = <String, int>{};
  var qrCodeCount = 0;
  var inventoryLookupCandidateCount = 0;
  for (final code in fixture.barcodeCodes) {
    final format = _safeBarcodeFormatBucket(code.format);
    formatBuckets[format] = (formatBuckets[format] ?? 0) + 1;
    if (format == 'qr') qrCodeCount += 1;
    if (_barcodeInventoryLookupValue(code) != null) {
      inventoryLookupCandidateCount += 1;
    }
  }
  return _ReceiptQaBarcodeSummary(
    codeCount: fixture.barcodeCodes.length,
    qrCodeCount: qrCodeCount,
    inventoryLookupCandidateCount: inventoryLookupCandidateCount,
    formatBuckets: Map.unmodifiable(formatBuckets),
    warningBuckets: List.unmodifiable(
      fixture.barcodeWarnings.map(_safeBarcodeWarningBucket).toSet(),
    ),
  );
}

String _safeBarcodeFormatBucket(String format) {
  final normalized = format.trim().replaceAll(RegExp(r'[\s_-]+'), '');
  return switch (normalized.toLowerCase()) {
    'code128' => 'code128',
    'code39' => 'code39',
    'code93' => 'code93',
    'codabar' => 'codabar',
    'datamatrix' => 'dataMatrix',
    'ean13' => 'ean13',
    'ean8' => 'ean8',
    'itf' => 'itf',
    'qrcode' || 'qr' => 'qr',
    'upca' => 'upca',
    'upce' => 'upce',
    'pdf417' => 'pdf417',
    'aztec' => 'aztec',
    _ => 'unknown',
  };
}

String? _barcodeInventoryLookupValue(_ReceiptQaBarcodeCode code) {
  if (_isSensitiveBarcodeValueType(code.valueType)) return null;
  final source = code.rawValue.trim().isEmpty
      ? code.displayValue
      : code.rawValue;
  final normalized = source.replaceAll(RegExp(r'[\s-]+'), '').toUpperCase();
  if (normalized.isEmpty) return null;
  if (normalized.length > _receiptQaBarcodeMaxLookupLength) return null;
  return normalized;
}

bool _isSensitiveBarcodeValueType(String valueType) {
  final normalized = valueType
      .trim()
      .replaceAll(RegExp(r'[\s_-]+'), '')
      .toLowerCase();
  return const {
    'contactinfo',
    'email',
    'phone',
    'sms',
    'wifi',
    'geocoordinates',
    'calendarevent',
    'driverlicense',
  }.contains(normalized);
}

String _safeBarcodeWarningBucket(String warning) {
  final normalized = warning.trim().toLowerCase();
  return switch (normalized) {
    'barcode_scan_invalid_source_path' => 'barcode_scan_invalid_source_path',
    'barcode_scan_platform_failed' => 'barcode_scan_platform_failed',
    'barcode_scan_failed' => 'barcode_scan_failed',
    'receipt_scanner_inventory_suggestion_only' =>
      'receipt_scanner_inventory_suggestion_only',
    _ => 'barcode_scan_warning',
  };
}

bool _countMapsMatch(Map<String, int> actual, Map<String, int> expected) {
  if (actual.length != expected.length) return false;
  for (final entry in expected.entries) {
    if (actual[entry.key] != entry.value) return false;
  }
  return true;
}

bool _stringListsMatch(List<String> actual, List<String> expected) {
  if (actual.length != expected.length) return false;
  for (var index = 0; index < expected.length; index += 1) {
    if (actual[index] != expected[index]) return false;
  }
  return true;
}

class _ReceiptQaBarcodeSummary {
  const _ReceiptQaBarcodeSummary({
    required this.codeCount,
    required this.qrCodeCount,
    required this.inventoryLookupCandidateCount,
    required this.formatBuckets,
    required this.warningBuckets,
  });

  final int codeCount;
  final int qrCodeCount;
  final int inventoryLookupCandidateCount;
  final Map<String, int> formatBuckets;
  final List<String> warningBuckets;
}
