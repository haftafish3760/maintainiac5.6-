part of 'receipt_qa_runner.dart';

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

ReceiptQaBarcodeSummary _receiptQaBarcodeSummary(_ReceiptQaFixture fixture) =>
    summarizeReceiptQaBarcodes(
      codes: fixture.barcodeCodes,
      warnings: fixture.barcodeWarnings,
    );

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
