import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'maximum data saver keeps local OCR but trims local catalog work on any phone',
    () {
      final plan = const ReceiptDeviceCapability.highCapacity()
          .cloudAssistPlanFor(dataSaverLevel: ReceiptDataSaverLevel.maximum);

      expect(plan.planCode, 'local_ocr_cloud_ocr_cloud_inventory_optional');
      expect(plan.localOcrAvailable, isTrue);
      expect(plan.localOcrMode, 'lean_local_ocr');
      expect(plan.cloudOcrOptional, isTrue);
      expect(plan.cloudInventoryOptional, isTrue);
      expect(plan.requiresExplicitUserChoice, isTrue);
      expect(plan.localParserScopeCode, 'inventory_matching_local');
      expect(plan.localParserScopeLabel, contains('inventory/material'));
      expect(plan.localCatalogMatchLimit, 250);
      expect(plan.localInventoryCacheLimit, 1000);
      expect(plan.dataSaverLevel, ReceiptDataSaverLevel.maximum);
    },
  );

  test('high capacity phones keep cloud inventory matching optional', () {
    const capability = ReceiptDeviceCapability.highCapacity();

    expect(capability.shouldOfferCloudOcrAssist, isFalse);
    expect(capability.shouldOfferCloudInventoryAssist, isFalse);
    expect(capability.cloudAssistPlan.planCode, 'local_ocr_only');
    expect(capability.cloudAssistPlan.localOcrAvailable, isTrue);
    expect(capability.cloudAssistPlan.localOcrMode, 'full_local_ocr');
    expect(capability.cloudAssistPlan.hasOptionalCloudAssist, isFalse);
    expect(capability.cloudAssistPlan.toPrivacySafeDiagnostics(), {
      'cloudAssistPlan': 'local_ocr_only',
      'ocrDecisionPolicy': 'local_default_only',
      'localOcrAvailable': true,
      'localOcrMode': 'full_local_ocr',
      'localOcrDefault': true,
      'cloudOcrOptional': false,
      'cloudInventoryOptional': false,
      'cloudAssistRequiresExplicitChoice': false,
      'cloudAssistRequiresInternet': false,
      'cameraCaptureCloudRequired': false,
      'receiptReviewCloudRequired': false,
      'parserDepth': 'inventoryMatching',
      'localParserScope': 'inventory_matching_local',
      'localCatalogMatchLimit': 8000,
      'localInventoryCacheLimit': 25000,
      'dataSaverLevel': 'balanced',
      'parserPackCodes': [
        'core_receipt_text_v1',
        'general_expense_lines_v1',
        'materials_inventory_regional_v1',
      ],
      'optionalLocalParserPackCodes': [
        'general_expense_lines_v1',
        'materials_inventory_regional_v1',
      ],
      'cloudFallbackParserPackCodes': <String>[],
      'parserPackAccuracyBands': {
        'core_receipt_text_v1': 'ocr_text_95_99_when_photo_readable',
        'general_expense_lines_v1': 'parser_line_items_90_97_by_vendor_pattern',
        'materials_inventory_regional_v1':
            'inventory_match_80_99_by_installed_trade_pack',
      },
      'estimatedOptionalLocalPackBytes': 124 * 1024 * 1024,
      'baseReceiptBudgetBytes': 40 * 1024 * 1024,
      'includedLocalPackBytes': 0,
      'optionalLocalPackBytes': 124 * 1024 * 1024,
      'baseIncludesHeavyParserPacks': false,
      'footprintCloudFallbackPackCodes': <String>[],
      'lowStorageSafe': false,
      'requiresExplicitDownloadForHeavyPacks': true,
      'userFacingPackDisclosureLabel':
          'Optional local parser add-ons use about 124 MB. Cloud OCR/parser '
          'fallback is off for this setup. Accuracy disclosures: '
          'core_receipt_text_v1: ocr_text_95_99_when_photo_readable; '
          'general_expense_lines_v1: parser_line_items_90_97_by_vendor_pattern; '
          'materials_inventory_regional_v1: '
          'inventory_match_80_99_by_installed_trade_pack.',
      'userFacingFootprintLabel':
          'The core receipt camera and basic local receipt reading stay in the '
          'base app budget. Stronger offline receipt packs can add about '
          '124 MB only after the user chooses to download them. Cloud fallback '
          'is not part of this setup.',
    });
    expect(
      capability.optionalCloudInventoryAssistLabel,
      contains('Local inventory matching is available'),
    );
    expect(
      capability.optionalCloudAssistPlanLabel,
      contains('local receipt assistance remains the default'),
    );
  });

  test(
    'parser pack disclosures explain local size and cloud fallback honestly',
    () {
      final leanPlan = const ReceiptDeviceCapability.highCapacity()
          .cloudAssistPlanFor(dataSaverLevel: ReceiptDataSaverLevel.maximum);
      final fullPlan =
          const ReceiptDeviceCapability.highCapacity().cloudAssistPlan;

      expect(leanPlan.parserPackCodes, [
        'core_receipt_text_v1',
        'general_expense_lines_v1',
        'materials_inventory_regional_v1',
        'cloud_ocr_assist_v1',
      ]);
      expect(
        leanPlan.optionalLocalParserPackCodes,
        contains('general_expense_lines_v1'),
      );
      expect(
        leanPlan.cloudFallbackParserPackCodes,
        containsAll(['materials_inventory_regional_v1', 'cloud_ocr_assist_v1']),
      );
      expect(
        leanPlan.parserPackAccuracyBands['materials_inventory_regional_v1'],
        'inventory_match_80_99_by_installed_trade_pack',
      );
      expect(leanPlan.estimatedOptionalLocalPackBytes, 24 * 1024 * 1024);

      expect(fullPlan.parserPackCodes, [
        'core_receipt_text_v1',
        'general_expense_lines_v1',
        'materials_inventory_regional_v1',
      ]);
      expect(fullPlan.optionalLocalParserPackCodes, [
        'general_expense_lines_v1',
        'materials_inventory_regional_v1',
      ]);
      expect(fullPlan.cloudFallbackParserPackCodes, isEmpty);
      expect(fullPlan.estimatedOptionalLocalPackBytes, 124 * 1024 * 1024);
      expect(
        leanPlan.userFacingPackDisclosureLabel,
        contains('Optional local parser add-ons use about 24 MB'),
      );
      expect(
        leanPlan.userFacingPackDisclosureLabel,
        contains('Cloud OCR/parser fallback needs internet'),
      );
      expect(
        leanPlan.userFacingPackDisclosureLabel,
        contains('ocr_text_95_99_when_photo_readable'),
      );
      expect(
        leanPlan.userFacingPackDisclosureLabel,
        contains('inventory_match_80_99_by_installed_trade_pack'),
      );
    },
  );

  test(
    'receipt footprint plan keeps huge parser intelligence out of the base app',
    () {
      final lowStoragePlan = ReceiptDeviceCapability.fromHardware(
        hardware: const ReceiptHardwareProfile(
          availableRamMb: 2048,
          cpuCores: 4,
          freeStorageMb: 220,
        ),
      ).cloudAssistPlan;
      final highCapacityPlan =
          const ReceiptDeviceCapability.highCapacity().cloudAssistPlan;
      final lowStorageBrain = ReceiptBrainFootprintSummary.fromPlan(
        plan: lowStoragePlan,
        storageClass: ReceiptDeviceStorageClass.critical,
      );
      final highCapacityBrain = ReceiptBrainFootprintSummary.fromPlan(
        plan: highCapacityPlan,
        storageClass: ReceiptDeviceStorageClass.roomy,
      );

      expect(lowStoragePlan.footprintPlan.baseReceiptBudgetLabel, '40 MB');
      expect(lowStoragePlan.footprintPlan.lowStorageSafe, isTrue);
      expect(
        lowStoragePlan.footprintPlan.baseIncludesHeavyParserPacks,
        isFalse,
      );
      expect(lowStoragePlan.footprintPlan.optionalLocalPackBytes, 0);
      expect(
        lowStoragePlan.footprintPlan.cloudFallbackPackCodes,
        contains('cloud_ocr_assist_v1'),
      );
      expect(
        lowStoragePlan.footprintPlan.userFacingFootprintLabel,
        contains('No extra local receipt pack download'),
      );
      expect(
        lowStorageBrain.userFacingBaseVersusFullOfflineSummary,
        contains('First install needs the receipt camera'),
      );
      expect(
        lowStorageBrain.lowStorageDownloadRiskCode,
        'base_safe_optional_brain_deferred_for_low_storage',
      );
      expect(
        lowStorageBrain.userFacingLowStorageDownloadWarning,
        contains('Required receipt camera and basic reading: 40 MB'),
      );
      expect(
        lowStorageBrain.toPrivacySafeDiagnostics(),
        containsPair(
          'receiptBrainUserFacingBaseVersusFullOfflineSummary',
          lowStorageBrain.userFacingBaseVersusFullOfflineSummary,
        ),
      );

      expect(highCapacityPlan.footprintPlan.lowStorageSafe, isFalse);
      expect(
        highCapacityPlan.footprintPlan.requiresExplicitDownloadForHeavyPacks,
        isTrue,
      );
      expect(
        highCapacityPlan.footprintPlan.optionalLocalPackSizeLabel,
        '124 MB',
      );
      expect(
        highCapacityPlan.footprintPlan.baseIncludesHeavyParserPacks,
        isFalse,
      );
      expect(
        highCapacityPlan.footprintPlan.userFacingFootprintLabel,
        contains('only after the user chooses to download them'),
      );
      expect(
        highCapacityBrain.userFacingBaseVersusFullOfflineSummary,
        contains(
          'Full offline receipt intelligence can add about 124 MB later',
        ),
      );
      expect(
        highCapacityBrain.fullOfflineReceiptBrainExceedsRequiredBaseGuardrail,
        isTrue,
      );
      expect(highCapacityBrain.fullOfflineReceiptBrainMustStayOptional, isTrue);
      expect(
        highCapacityBrain.lowStorageDownloadRiskCode,
        'full_offline_large_optional_only',
      );
      expect(
        highCapacityBrain.userFacingLowStorageDownloadWarning,
        contains('must remain an explicit optional download'),
      );
    },
  );

  test('receipt install recommendation protects very low storage phones', () {
    const crampedHardware = ReceiptHardwareProfile(
      availableRamMb: 2048,
      cpuCores: 4,
      freeStorageMb: 190,
    );
    const lowHardware = ReceiptHardwareProfile(
      availableRamMb: 6144,
      cpuCores: 6,
      freeStorageMb: 900,
    );
    const roomyHardware = ReceiptHardwareProfile(
      availableRamMb: 12288,
      cpuCores: 8,
      androidPerformanceClass: 34,
      freeStorageMb: 16000,
      hasOnDeviceAcceleration: true,
    );

    final cramped = crampedHardware.receiptInstallRecommendationFor();
    final low = lowHardware.receiptInstallRecommendationFor(
      mode: ReceiptPerformanceMode.maximumPerformance,
    );
    final roomy = roomyHardware.receiptInstallRecommendationFor();

    expect(cramped.modeCode, 'base_receipt_only');
    expect(cramped.optionalLocalDownloadAllowed, isFalse);
    expect(cramped.cloudFallbackSuggested, isTrue);
    expect(cramped.maxOptionalLocalDownloadBytes, 0);
    expect(cramped.reasonCode, 'critical_storage_protect_base_capture');
    expect(cramped.userFacingLabel, contains('Keep the receipt camera lean'));
    expect(cramped.toPrivacySafeDiagnostics(), {
      'receiptInstallMode': 'base_receipt_only',
      'receiptInstallOptionalLocalDownloadAllowed': false,
      'receiptInstallCloudFallbackSuggested': true,
      'receiptInstallMaxOptionalLocalBytes': 0,
      'receiptInstallReason': 'critical_storage_protect_base_capture',
      'receiptInstallLabel':
          'Keep the receipt camera lean on this phone. Use the base receipt reader now; bigger offline packs can wait.',
    });

    expect(
      low.modeCode,
      anyOf(
        'small_optional_pack_allowed',
        'base_receipt_cloud_assist_preferred',
      ),
    );
    expect(low.maxOptionalLocalDownloadLabel, '24 MB');
    expect(low.reasonCode, 'low_storage_limit_optional_downloads');

    expect(roomy.modeCode, 'full_offline_receipt_packs_allowed');
    expect(roomy.optionalLocalDownloadAllowed, isTrue);
    expect(roomy.maxOptionalLocalDownloadBytes, 124 * 1024 * 1024);
    expect(roomy.userFacingLabel, contains('full offline receipt pack'));
  });
}
