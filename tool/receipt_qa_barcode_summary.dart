const receiptQaBarcodeMaxLookupLength = 128;

class ReceiptQaBarcodeCode {
  const ReceiptQaBarcodeCode({
    required this.format,
    required this.valueType,
    required this.rawValue,
    this.displayValue = '',
  });

  final String format;
  final String valueType;
  final String rawValue;
  final String displayValue;
}

class ReceiptQaBarcodeSummary {
  const ReceiptQaBarcodeSummary({
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

ReceiptQaBarcodeSummary summarizeReceiptQaBarcodes({
  required List<ReceiptQaBarcodeCode> codes,
  required List<String> warnings,
}) {
  final formatBuckets = <String, int>{};
  var qrCodeCount = 0;
  var inventoryLookupCandidateCount = 0;
  for (final code in codes) {
    final format = _safeBarcodeFormatBucket(code.format);
    formatBuckets[format] = (formatBuckets[format] ?? 0) + 1;
    if (format == 'qr') qrCodeCount += 1;
    if (_barcodeInventoryLookupValue(code) != null) {
      inventoryLookupCandidateCount += 1;
    }
  }
  final warningBuckets =
      warnings.map(_safeBarcodeWarningBucket).toSet().toList()..sort();
  return ReceiptQaBarcodeSummary(
    codeCount: codes.length,
    qrCodeCount: qrCodeCount,
    inventoryLookupCandidateCount: inventoryLookupCandidateCount,
    formatBuckets: Map.unmodifiable(formatBuckets),
    warningBuckets: List.unmodifiable(warningBuckets),
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

String? _barcodeInventoryLookupValue(ReceiptQaBarcodeCode code) {
  if (_isSensitiveBarcodeValueType(code.valueType)) return null;
  final source = code.rawValue.trim().isEmpty
      ? code.displayValue
      : code.rawValue;
  final normalized = source.replaceAll(RegExp(r'[\s-]+'), '').toUpperCase();
  if (normalized.isEmpty ||
      normalized.length > receiptQaBarcodeMaxLookupLength) {
    return null;
  }
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
  return switch (warning.trim().toLowerCase()) {
    'barcode_scan_invalid_source_path' => 'barcode_scan_invalid_source_path',
    'barcode_scan_platform_failed' => 'barcode_scan_platform_failed',
    'barcode_scan_failed' => 'barcode_scan_failed',
    'receipt_scanner_inventory_suggestion_only' =>
      'receipt_scanner_inventory_suggestion_only',
    _ => 'barcode_scan_warning',
  };
}
