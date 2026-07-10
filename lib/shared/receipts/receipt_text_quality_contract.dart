class ReceiptTextQualitySignals {
  const ReceiptTextQualitySignals({
    required this.lines,
    required this.hasMerchant,
    required this.hasTotal,
    required this.hasDate,
    required this.hasFuelQuantity,
    required this.hasTax,
    required this.hasLineItemAmount,
    required this.hasMaintenanceService,
    required this.hasMaintenanceInterval,
    required this.hasTenderLineWithAmount,
    required this.hasBottomTotalCoverage,
  });

  final List<String> lines;
  final bool hasMerchant;
  final bool hasTotal;
  final bool hasDate;
  final bool hasFuelQuantity;
  final bool hasTax;
  final bool hasLineItemAmount;
  final bool hasMaintenanceService;
  final bool hasMaintenanceInterval;
  final bool hasTenderLineWithAmount;
  final bool hasBottomTotalCoverage;
}

ReceiptTextQualitySignals evaluateReceiptTextQuality({
  required String text,
  required String merchantNeedle,
}) {
  final normalized = normalizeReceiptTextForQuality(text);
  final lines = normalized
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);

  return ReceiptTextQualitySignals(
    lines: lines,
    hasMerchant: lines.any(
      (line) =>
          line.toLowerCase().contains(merchantNeedle) ||
          normalizeOcrTokenNoise(line).toLowerCase().contains(merchantNeedle),
    ),
    hasTotal: lines.any(looksLikeReceiptTotalLine),
    hasDate: lines.any(looksLikeReceiptDateLine),
    hasFuelQuantity: lines.any(looksLikeReceiptFuelQuantityLine),
    hasTax: lines.any(looksLikeReceiptTaxLine),
    hasLineItemAmount: lines.any(looksLikeReceiptLineItemAmount),
    hasMaintenanceService: lines.any(looksLikeReceiptMaintenanceServiceLine),
    hasMaintenanceInterval: lines.any(looksLikeReceiptMaintenanceIntervalLine),
    hasTenderLineWithAmount: lines.any(looksLikeReceiptTenderLineWithAmount),
    hasBottomTotalCoverage:
        lines.any(looksLikeReceiptTotalLine) &&
        !text.toLowerCase().contains('[missing bottom]'),
  );
}

String normalizeReceiptTextForQuality(String text) {
  return text
      .replaceAll('T0TAL', 'TOTAL')
      .replaceAll('T4X', 'TAX')
      .replaceAll('AM0UNT', 'AMOUNT')
      .replaceAll('SUBT0TAL', 'SUBTOTAL');
}

String normalizeOcrTokenNoise(String text) {
  return text.replaceAll('0', 'O');
}

String normalizeOcrNumericNoise(String text) {
  return text
      .replaceAllMapped(
        RegExp(r'(?<=\d)[Oo](?=\d|\b|[.,])|(?<=\b)[Oo](?=\d)'),
        (_) => '0',
      )
      .replaceAllMapped(RegExp(r'(?<=[.,])[Oo](?=\d)'), (_) => '0');
}

bool looksLikeReceiptDateLine(String line) {
  final normalized = normalizeOcrNumericNoise(line);
  return RegExp(r'\b\d{1,2}/\d{1,2}/\d{2,4}\b').hasMatch(normalized) ||
      RegExp(r'\b\d{1,2}-\d{1,2}-\d{2,4}\b').hasMatch(normalized) ||
      RegExp(r'\b\d{4}-\d{2}-\d{2}\b').hasMatch(normalized);
}

bool looksLikeReceiptTotalLine(String line) {
  final normalized = normalizeOcrNumericNoise(line);
  final upper = normalizeOcrTokenNoise(normalized).toUpperCase();
  return (upper.contains('TOTAL') ||
          upper.contains('AMOUNT PAID') ||
          upper.contains('FUEL SALE')) &&
      RegExp(r'\d+[.,]\d{2}\b').hasMatch(normalized);
}

bool looksLikeReceiptTaxLine(String line) {
  final normalized = normalizeOcrNumericNoise(line);
  final upper = normalized.toUpperCase();
  return upper.contains('TAX') &&
      RegExp(r'\d+[.,]\d{2}\b').hasMatch(normalized);
}

bool looksLikeReceiptFuelQuantityLine(String line) {
  final normalized = normalizeOcrNumericNoise(line);
  final upper = normalized.toUpperCase();
  return upper.contains('GAL') ||
      upper.contains('GALS') ||
      upper.contains('GALLONS') ||
      upper.contains('QTY') ||
      upper.contains('GGE') ||
      upper.contains('DGE') ||
      upper.contains('KWH') ||
      upper.contains('KILOWATT HOUR') ||
      upper.contains('LITER') ||
      RegExp(r'\bKG\b').hasMatch(upper) ||
      RegExp(r'\bHVO\s?\d{1,3}\b\s+\d+[.,]\d{2,3}\s*(?:@|X)\s*\d')
          .hasMatch(upper);
}

bool looksLikeReceiptLineItemAmount(String line) {
  final normalized = normalizeOcrNumericNoise(line);
  final upper = normalized.toUpperCase();
  if (looksLikeReceiptTotalLine(line) || looksLikeReceiptTaxLine(line)) {
    return false;
  }
  if (upper.contains('AUTH') || upper.contains('TRACE')) return false;
  return RegExp(r'[A-Z][A-Z0-9 /.-]{2,}\s+\d+[.,]\d{2}\b').hasMatch(upper);
}

bool looksLikeReceiptMaintenanceServiceLine(String line) {
  final upper = line.toUpperCase();
  return upper.contains('OIL') ||
      upper.contains('TIRE ROTATION') ||
      upper.contains('ROTATE') ||
      upper.contains('FILTER') ||
      RegExp(r'\b(0W|5W|10W|15W)-?\d{2}\b').hasMatch(upper);
}

bool looksLikeReceiptMaintenanceIntervalLine(String line) {
  final upper = normalizeOcrNumericNoise(line).toUpperCase();
  return upper.contains('NEXT SERVICE') ||
      upper.contains('NEXT OIL') ||
      upper.contains('MILE') ||
      RegExp(r'\b\d{2,3}[, ]?\d{3}\b').hasMatch(upper);
}

bool looksLikeReceiptTenderLineWithAmount(String line) {
  final normalized = normalizeOcrNumericNoise(line);
  final upper = normalized.toUpperCase();
  final tender =
      upper.contains('VISA') ||
      upper.contains('CARD') ||
      upper.contains('AUTH') ||
      upper.contains('TRACE');
  return tender && RegExp(r'\d+[.,]\d{2}\b').hasMatch(normalized);
}
