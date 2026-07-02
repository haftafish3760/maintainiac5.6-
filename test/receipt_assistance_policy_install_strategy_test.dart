import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'receipt brain recommendation keeps low-storage phones on a lean base',
    () {
      const crampedHardware = ReceiptHardwareProfile(
        availableRamMb: 3072,
        cpuCores: 4,
        freeStorageMb: 190,
        cameraCount: 1,
        hasRearCamera: true,
        supportsTapFocus: true,
        supportsZoom: true,
      );
      const lowHardware = ReceiptHardwareProfile(
        availableRamMb: 6144,
        cpuCores: 6,
        freeStorageMb: 900,
        cameraCount: 1,
        hasRearCamera: true,
        supportsTapFocus: true,
        supportsZoom: true,
      );
      const roomyHardware = ReceiptHardwareProfile(
        availableRamMb: 12288,
        cpuCores: 8,
        androidPerformanceClass: 34,
        freeStorageMb: 16000,
        hasOnDeviceAcceleration: true,
        cameraCount: 1,
        hasRearCamera: true,
        supportsTapFocus: true,
        supportsZoom: true,
        supportsExposureCompensation: true,
        maxStillWidth: 4000,
        maxStillHeight: 3000,
      );

      final cramped = crampedHardware.receiptBrainRecommendationFor();
      final low = lowHardware.receiptBrainRecommendationFor(
        mode: ReceiptPerformanceMode.maximumPerformance,
      );
      final roomy = roomyHardware.receiptBrainRecommendationFor();

      expect(cramped.modeCode, 'base_local_reader_only');
      expect(cramped.baseCaptureAlwaysAvailable, isTrue);
      expect(cramped.localReceiptReaderDefault, isTrue);
      expect(cramped.optionalLocalPackAllowed, isFalse);
      expect(cramped.optionalLocalPackBytes, 0);
      expect(cramped.assistFallbackAllowed, isTrue);
      expect(cramped.requiresInternetForAssist, isTrue);
      expect(cramped.keepsBaseInstallLean, isTrue);
      expect(cramped.userFacingSummary, contains('Receipt capture works'));
      expect(
        cramped.userFacingSummary,
        contains('OCR still reads the clearest source first'),
      );
      expect(
        cramped.userFacingStorageWarning,
        contains('Storage is very tight'),
      );
      expect(
        cramped.userFacingStorageWarning,
        contains('fuel receipts, and basic local reading'),
      );
      expect(cramped.toPrivacySafeDiagnostics(), {
        'receiptBrainMode': 'base_local_reader_only',
        'receiptBrainLocalOcrMode': 'lean_local_ocr',
        'receiptBrainBaseCaptureAvailable': true,
        'receiptBrainLocalReaderDefault': true,
        'receiptBrainOptionalLocalPackAllowed': false,
        'receiptBrainOptionalLocalPackBytes': 0,
        'receiptBrainAssistFallbackAllowed': true,
        'receiptBrainRequiresInternetForAssist': true,
        'receiptBrainStorageClass': 'critical',
        'receiptBrainDeviceTier': 'light',
        'receiptBrainKeepsBaseInstallLean': true,
      });

      expect(
        low.modeCode,
        anyOf(
          'base_local_reader_small_pack_optional',
          'base_local_reader_assist_optional',
        ),
      );
      expect(low.optionalLocalPackBytes, lessThanOrEqualTo(24 * 1024 * 1024));
      expect(low.userFacingStorageWarning, contains('Storage is limited'));
      expect(low.userFacingStorageWarning, contains('Fuel receipts still use'));

      expect(roomy.modeCode, 'full_offline_pack_optional');
      expect(roomy.optionalLocalPackAllowed, isTrue);
      expect(roomy.optionalLocalPackSizeLabel, '124 MB');
      expect(roomy.requiresInternetForAssist, isFalse);
      expect(roomy.userFacingStorageWarning, contains('full offline'));
    },
  );

  test(
    'parser pack install choice separates local downloads from cloud fallback',
    () {
      final leanPlan = const ReceiptDeviceCapability.highCapacity()
          .cloudAssistPlanFor(dataSaverLevel: ReceiptDataSaverLevel.maximum);
      final fullPlan =
          const ReceiptDeviceCapability.highCapacity().cloudAssistPlan;

      final leanChoice = leanPlan.parserPackInstallChoice;
      expect(leanChoice.includedLocalPackCodes, ['core_receipt_text_v1']);
      expect(leanChoice.optionalLocalDownloadPackCodes, [
        'general_expense_lines_v1',
      ]);
      expect(leanChoice.cloudFallbackPackCodes, [
        'materials_inventory_regional_v1',
        'cloud_ocr_assist_v1',
      ]);
      expect(leanChoice.optionalLocalDownloadBytes, 24 * 1024 * 1024);
      expect(leanChoice.optionalLocalDownloadSizeLabel, '24 MB');
      expect(leanChoice.requiresInternetForFallback, isTrue);
      expect(leanChoice.canRunFullyOffline, isTrue);
      expect(
        leanChoice.userFacingDownloadChoiceLabel,
        'Download about 24 MB for stronger offline receipt assistance. Cloud fallback is optional, requires internet, and must be chosen by the user.',
      );
      expect(leanChoice.toPrivacySafeDiagnostics(), {
        'includedLocalPackCodes': ['core_receipt_text_v1'],
        'optionalLocalDownloadPackCodes': ['general_expense_lines_v1'],
        'cloudFallbackPackCodes': [
          'materials_inventory_regional_v1',
          'cloud_ocr_assist_v1',
        ],
        'optionalLocalDownloadBytes': 24 * 1024 * 1024,
        'requiresInternetForFallback': true,
        'accuracyBands': {
          'core_receipt_text_v1': 'ocr_text_95_99_when_photo_readable',
          'general_expense_lines_v1':
              'parser_line_items_90_97_by_vendor_pattern',
          'materials_inventory_regional_v1':
              'inventory_match_80_99_by_installed_trade_pack',
          'cloud_ocr_assist_v1': 'cloud_ocr_best_available_provider',
        },
      });

      final fullChoice = fullPlan.parserPackInstallChoice;
      expect(fullChoice.includedLocalPackCodes, ['core_receipt_text_v1']);
      expect(fullChoice.optionalLocalDownloadPackCodes, [
        'general_expense_lines_v1',
        'materials_inventory_regional_v1',
      ]);
      expect(fullChoice.cloudFallbackPackCodes, isEmpty);
      expect(fullChoice.optionalLocalDownloadSizeLabel, '124 MB');
      expect(fullChoice.requiresInternetForFallback, isFalse);
      expect(fullChoice.canRunFullyOffline, isTrue);
      expect(
        fullChoice.userFacingDownloadChoiceLabel,
        'Download about 124 MB for stronger offline receipt assistance. Cloud fallback is off for this setup.',
      );
    },
  );

  test('parser pack routing keeps fuel local and materials optional by pack', () {
    final leanPlan = const ReceiptDeviceCapability.highCapacity()
        .cloudAssistPlanFor(dataSaverLevel: ReceiptDataSaverLevel.maximum);
    final fullPlan =
        const ReceiptDeviceCapability.highCapacity().cloudAssistPlan;

    final leanRoutes = leanPlan.parserPackRoutingPlan;
    final leanFuel = leanRoutes.routeForCategory('fuel')!;
    final leanGeneral = leanRoutes.routeForCategory('general_expense')!;
    final leanMaterials = leanRoutes.routeForCategory('materials_inventory')!;

    expect(leanFuel.localFirst, isTrue);
    expect(leanFuel.localPackCodes, ['core_receipt_text_v1']);
    expect(leanFuel.optionalLocalPackCodes, isEmpty);
    expect(leanFuel.assistFallbackPackCodes, ['cloud_ocr_assist_v1']);
    expect(leanFuel.futureRegionalPackCode, 'fuel_region_patterns_v1');
    expect(
      leanFuel.userFacingLabel,
      contains('Fuel receipt essentials stay local-first'),
    );

    expect(leanGeneral.localFirst, isTrue);
    expect(leanGeneral.optionalLocalPackCodes, ['general_expense_lines_v1']);
    expect(
      leanRoutes.routeLabelForCategory('general_expense'),
      contains('base reader first'),
    );
    expect(
      leanRoutes.userFacingCategoryPackSummary,
      'Fuel receipt essentials stay local-first in the base reader. General '
      'line-item help can be an optional local add-on. Materials and inventory '
      'matching can use optional assist later. Receipt capture works without '
      'downloading these add-ons.',
    );

    expect(leanMaterials.localFirst, isTrue);
    expect(leanMaterials.optionalLocalPackCodes, isEmpty);
    expect(leanMaterials.assistFallbackPackCodes, [
      'materials_inventory_regional_v1',
      'cloud_ocr_assist_v1',
    ]);
    expect(
      leanMaterials.userFacingLabel,
      contains('downloaded by trade or region'),
    );
    expect(leanRoutes.toPrivacySafeDiagnostics(), {
      'parserPackRouteCount': 3,
      'parserPackLocalFirstCategoryCodes': [
        'fuel',
        'general_expense',
        'materials_inventory',
      ],
      'parserPackOptionalLocalCategoryCodes': ['general_expense'],
      'parserPackAssistFallbackCategoryCodes': [
        'fuel',
        'general_expense',
        'materials_inventory',
      ],
      'parserPackFutureRegionalCategoryCodes': [
        'fuel',
        'general_expense',
        'materials_inventory',
      ],
    });

    final fullRoutes = fullPlan.parserPackRoutingPlan;
    final fullMaterials = fullRoutes.routeForCategory('materials_inventory')!;
    expect(fullMaterials.localFirst, isTrue);
    expect(fullMaterials.optionalLocalPackCodes, [
      'materials_inventory_regional_v1',
    ]);
    expect(fullMaterials.assistFallbackPackCodes, isEmpty);
    expect(fullRoutes.assistFallbackCategoryCodes, isEmpty);
    expect(
      fullRoutes.routeLabelForCategory('unknown_category'),
      contains('stronger parser packs can be added later'),
    );
    expect(
      fullRoutes.userFacingCategoryPackSummary,
      contains('Materials and inventory packs can be downloaded by trade'),
    );
  });
}
