part of 'receipt_assistance_policy.dart';

enum ReceiptCameraResolutionTier {
  medium('Medium'),
  high('High'),
  max('Receipt High');

  const ReceiptCameraResolutionTier(this.label);

  final String label;
}

enum ReceiptDeviceStorageClass {
  unknown('Unknown'),
  critical('Critical'),
  low('Low'),
  comfortable('Comfortable'),
  roomy('Roomy');

  const ReceiptDeviceStorageClass(this.label);

  final String label;
}

class ReceiptCloudAssistPlan {
  const ReceiptCloudAssistPlan({
    required this.localOcrAvailable,
    required this.localOcrMode,
    required this.cloudOcrOptional,
    required this.cloudInventoryOptional,
    required this.requiresExplicitUserChoice,
    required this.parserDepth,
    required this.localCatalogMatchLimit,
    required this.localInventoryCacheLimit,
    required this.dataSaverLevel,
  });

  final bool localOcrAvailable;
  final String localOcrMode;
  final bool cloudOcrOptional;
  final bool cloudInventoryOptional;
  final bool requiresExplicitUserChoice;
  final ReceiptParserDepth parserDepth;
  final int localCatalogMatchLimit;
  final int localInventoryCacheLimit;
  final ReceiptDataSaverLevel dataSaverLevel;

  bool get hasOptionalCloudAssist => cloudOcrOptional || cloudInventoryOptional;

  String get localParserScopeCode {
    return switch (parserDepth) {
      ReceiptParserDepth.proofTotalsOnly => 'vendor_date_totals_local',
      ReceiptParserDepth.lineItems => 'line_items_local',
      ReceiptParserDepth.inventoryMatching => 'inventory_matching_local',
    };
  }

  String get localParserScopeLabel {
    return switch (parserDepth) {
      ReceiptParserDepth.proofTotalsOnly =>
        'Local reading looks for the vendor, date, subtotal, tax, and total first; line items can still be reviewed by hand or with optional cloud help.',
      ReceiptParserDepth.lineItems =>
        'Local reading looks for the vendor, date, totals, item prices, and receipt lines for business, personal, or split review.',
      ReceiptParserDepth.inventoryMatching =>
        'Local reading looks for the vendor, date, totals, item prices, receipt lines, and inventory/material matching hints.',
    };
  }

  String get planCode {
    if (cloudOcrOptional && cloudInventoryOptional) {
      return 'local_ocr_cloud_ocr_cloud_inventory_optional';
    }
    if (cloudOcrOptional) return 'local_ocr_cloud_ocr_optional';
    if (cloudInventoryOptional) return 'local_ocr_cloud_inventory_optional';
    return 'local_ocr_only';
  }

  String get localOcrLabel {
    return localOcrMode == 'lean_local_ocr'
        ? 'Basic on-device receipt assistance'
        : 'Full on-device receipt assistance';
  }

  String get userFacingSummary {
    if (!hasOptionalCloudAssist) {
      return '$localOcrLabel stays available on this phone; local receipt assistance remains the default.';
    }
    final parts = <String>[
      '$localOcrLabel stays available on this phone.',
      localParserScopeLabel,
      if (cloudOcrOptional)
        'cloud OCR can be offered for better accuracy when the user chooses it.',
      if (cloudInventoryOptional)
        'cloud inventory matching can be offered for large catalogs when the user chooses it.',
      if (requiresExplicitUserChoice)
        'Cloud assist must be explicit and requires internet.',
    ];
    return parts.join(' ');
  }

  String get userFacingPackDisclosureLabel {
    final optionalLocalBytes = estimatedOptionalLocalPackBytes;
    final optionalLocal = optionalLocalParserPackCodes.isEmpty
        ? 'No extra local parser download is required for this setup.'
        : 'Optional local parser add-ons use about ${_formatReceiptBytes(optionalLocalBytes)}.';
    final cloud = cloudFallbackParserPackCodes.isEmpty
        ? 'Cloud OCR/parser fallback is off for this setup.'
        : 'Cloud OCR/parser fallback needs internet and must be chosen by the user.';
    final accuracy = parserPackAccuracyBands.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('; ');
    return '$optionalLocal $cloud Accuracy disclosures: $accuracy.';
  }

  List<ReceiptParserPackDisclosure> get parserPackDisclosures {
    final packs = <ReceiptParserPackDisclosure>[
      const ReceiptParserPackDisclosure(
        code: 'core_receipt_text_v1',
        label: 'Core receipt text reading',
        categoryCode: 'all_receipts',
        availability: ReceiptParserPackAvailability.includedLocal,
        targetAccuracyBand: 'ocr_text_95_99_when_photo_readable',
        estimatedBytes: 0,
        requiresInternet: false,
      ),
    ];
    if (parserDepth != ReceiptParserDepth.proofTotalsOnly) {
      packs.add(
        const ReceiptParserPackDisclosure(
          code: 'general_expense_lines_v1',
          label: 'General expense line items',
          categoryCode: 'expenses',
          availability: ReceiptParserPackAvailability.optionalLocalDownload,
          targetAccuracyBand: 'parser_line_items_90_97_by_vendor_pattern',
          estimatedBytes: 24 * 1024 * 1024,
          requiresInternet: false,
        ),
      );
    }
    if (parserDepth == ReceiptParserDepth.inventoryMatching) {
      packs.add(
        ReceiptParserPackDisclosure(
          code: 'materials_inventory_regional_v1',
          label: 'Materials and inventory matching',
          categoryCode: 'materials_inventory',
          availability: cloudInventoryOptional
              ? ReceiptParserPackAvailability.cloudFallback
              : ReceiptParserPackAvailability.optionalLocalDownload,
          targetAccuracyBand: 'inventory_match_80_99_by_installed_trade_pack',
          estimatedBytes: cloudInventoryOptional ? 0 : 100 * 1024 * 1024,
          requiresInternet: cloudInventoryOptional,
        ),
      );
    }
    if (cloudOcrOptional) {
      packs.add(
        const ReceiptParserPackDisclosure(
          code: 'cloud_ocr_assist_v1',
          label: 'Cloud OCR assist',
          categoryCode: 'all_receipts',
          availability: ReceiptParserPackAvailability.cloudFallback,
          targetAccuracyBand: 'cloud_ocr_best_available_provider',
          estimatedBytes: 0,
          requiresInternet: true,
        ),
      );
    }
    return List.unmodifiable(packs);
  }

  ReceiptParserPackInstallChoice get parserPackInstallChoice {
    return ReceiptParserPackInstallChoice.fromDisclosures(
      parserPackDisclosures,
    );
  }

  ReceiptParserPackRoutingPlan get parserPackRoutingPlan {
    return ReceiptParserPackRoutingPlan.fromCloudAssistPlan(this);
  }

  int get estimatedOptionalLocalPackBytes {
    return parserPackInstallChoice.optionalLocalDownloadBytes;
  }

  ReceiptFeatureFootprintPlan get footprintPlan {
    return ReceiptFeatureFootprintPlan.fromCloudAssistPlan(this);
  }

  List<String> get parserPackCodes => [
    for (final pack in parserPackDisclosures) pack.code,
  ];

  List<String> get optionalLocalParserPackCodes => [
    for (final pack in parserPackDisclosures)
      if (pack.isOptionalLocalDownload) pack.code,
  ];

  List<String> get cloudFallbackParserPackCodes => [
    for (final pack in parserPackDisclosures)
      if (pack.isCloudFallback) pack.code,
  ];

  Map<String, String> get parserPackAccuracyBands => {
    for (final pack in parserPackDisclosures)
      pack.code: pack.targetAccuracyBand,
  };

  Map<String, Object?> toPrivacySafeDiagnostics() {
    return {
      'cloudAssistPlan': planCode,
      'ocrDecisionPolicy': hasOptionalCloudAssist
          ? 'local_default_cloud_optional'
          : 'local_default_only',
      'localOcrAvailable': localOcrAvailable,
      'localOcrMode': localOcrMode,
      'localOcrDefault': true,
      'cloudOcrOptional': cloudOcrOptional,
      'cloudInventoryOptional': cloudInventoryOptional,
      'cloudAssistRequiresExplicitChoice': requiresExplicitUserChoice,
      'cloudAssistRequiresInternet': hasOptionalCloudAssist,
      'cameraCaptureCloudRequired': false,
      'receiptReviewCloudRequired': false,
      'parserDepth': parserDepth.name,
      'localParserScope': localParserScopeCode,
      'localCatalogMatchLimit': localCatalogMatchLimit,
      'localInventoryCacheLimit': localInventoryCacheLimit,
      'dataSaverLevel': dataSaverLevel.name,
      'parserPackCodes': parserPackCodes,
      'optionalLocalParserPackCodes': optionalLocalParserPackCodes,
      'cloudFallbackParserPackCodes': cloudFallbackParserPackCodes,
      'parserPackAccuracyBands': parserPackAccuracyBands,
      'estimatedOptionalLocalPackBytes': estimatedOptionalLocalPackBytes,
      ...footprintPlan.toPrivacySafeDiagnostics(),
      'userFacingPackDisclosureLabel': userFacingPackDisclosureLabel,
      'userFacingFootprintLabel': footprintPlan.userFacingFootprintLabel,
    };
  }
}

String _formatReceiptBytes(int bytes) {
  if (bytes <= 0) return '0 MB';
  final mb = bytes / (1024 * 1024);
  if (mb >= 100) return '${mb.round()} MB';
  if (mb == mb.roundToDouble()) return '${mb.round()} MB';
  return '${mb.toStringAsFixed(1)} MB';
}

int _minInt(int value, int ceiling) {
  return value < ceiling ? value : ceiling;
}

int _maxInt(int value, int floor) {
  return value > floor ? value : floor;
}
