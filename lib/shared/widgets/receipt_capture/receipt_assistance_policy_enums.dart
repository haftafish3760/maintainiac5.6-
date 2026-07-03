part of 'receipt_assistance_policy.dart';

enum ReceiptAssistanceMode {
  localRead('Read on this device'),
  localReadWithReview('Read on this device, then review'),
  proofOnly('Save proof only'),
  cloudCandidate('Can offer cloud-assisted reading later');

  const ReceiptAssistanceMode(this.label);

  final String label;
}

enum ReceiptPerformanceMode {
  automatic('Automatic', 'Let Maintainiac choose the right receipt workload.'),
  batterySaver(
    'Battery Saver',
    'Use the lightest local receipt assistance path.',
  ),
  balanced('Balanced', 'Use a steady receipt assistance path for most phones.'),
  maximumPerformance(
    'Maximum Performance',
    'Use the heaviest local receipt assistance path this phone can handle.',
  );

  const ReceiptPerformanceMode(this.label, this.description);

  final String label;
  final String description;

  static ReceiptPerformanceMode fromName(String? name) {
    final normalized = name?.trim() ?? '';
    return ReceiptPerformanceMode.values.firstWhere(
      (mode) => mode.name == normalized,
      orElse: () => ReceiptPerformanceMode.automatic,
    );
  }
}

enum ReceiptCapabilityTier {
  light('Light'),
  medium('Medium'),
  heavyweight('Heavyweight');

  const ReceiptCapabilityTier(this.label);

  final String label;
}

enum ReceiptParserDepth {
  proofTotalsOnly('Vendor, date, subtotal, tax, and total'),
  lineItems('Line items, business/personal/split, and categories'),
  inventoryMatching(
    'Line items, inventory matching, SKU checks, trade terms, and review scoring',
  );

  const ReceiptParserDepth(this.label);

  final String label;
}

enum ReceiptParserPackAvailability {
  includedLocal,
  optionalLocalDownload,
  cloudFallback,
}
