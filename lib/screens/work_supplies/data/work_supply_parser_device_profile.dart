import '../../../shared/widgets/receipt_capture/receipt_assistance_policy.dart';

class WorkSupplyParserDeviceProfile {
  const WorkSupplyParserDeviceProfile({
    required this.parserDepth,
    required this.maxCatalogCandidates,
    required this.maxInventoryCacheItems,
    required this.enableTradeClassification,
    required this.enableAdvancedConfidenceScoring,
    required this.statusLabel,
  });

  factory WorkSupplyParserDeviceProfile.fromCapability(
    ReceiptDeviceCapability capability,
  ) {
    return WorkSupplyParserDeviceProfile(
      parserDepth: capability.parserDepth,
      maxCatalogCandidates: capability.maxLocalCatalogMatches,
      maxInventoryCacheItems: capability.maxLocalInventoryCacheItems,
      enableTradeClassification: capability.enableTradeClassification,
      enableAdvancedConfidenceScoring:
          capability.enableAdvancedConfidenceScoring,
      statusLabel: _statusLabelFor(capability.tier),
    );
  }

  final ReceiptParserDepth parserDepth;
  final int maxCatalogCandidates;
  final int maxInventoryCacheItems;
  final bool enableTradeClassification;
  final bool enableAdvancedConfidenceScoring;
  final String statusLabel;

  bool get canRunInventoryMatching =>
      parserDepth == ReceiptParserDepth.inventoryMatching;
}

String _statusLabelFor(ReceiptCapabilityTier tier) {
  return switch (tier) {
    ReceiptCapabilityTier.light => 'Light receipt assist',
    ReceiptCapabilityTier.medium => 'Standard receipt assist',
    ReceiptCapabilityTier.heavyweight => 'Full inventory receipt assist',
  };
}
