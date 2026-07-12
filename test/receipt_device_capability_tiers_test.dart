import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test(
    'automatic capability assessment picks a light tier for constrained phones',
    () {
      final capability = ReceiptDeviceCapability.fromHardware(
        hardware: const ReceiptHardwareProfile(
          availableRamMb: 3900,
          cpuCores: 4,
          androidSdk: 28,
          freeStorageMb: 900,
        ),
      );

      expect(capability.tier, ReceiptCapabilityTier.light);
      expect(capability.parserDepth, ReceiptParserDepth.proofTotalsOnly);
      expect(capability.maxLocalPhotoCount, 4);
      expect(
        capability.cameraResolutionTier,
        ReceiptCameraResolutionTier.medium,
      );
      expect(capability.assistedCameraShotCount, 2);
      expect(capability.liveAnalysisGapMs, greaterThan(700));
      expect(capability.maxLocalCatalogMatches, lessThan(500));
      expect(capability.enableAdvancedConfidenceScoring, isFalse);
      expect(
        capability.recommendedDataSaverLevel,
        ReceiptDataSaverLevel.strong,
      );
    },
  );

  test(
    'automatic capability assessment picks a medium tier for midrange phones',
    () {
      final capability = ReceiptDeviceCapability.fromHardware(
        hardware: const ReceiptHardwareProfile(
          availableRamMb: 6144,
          cpuCores: 6,
          androidSdk: 31,
          freeStorageMb: 2400,
        ),
      );

      expect(capability.tier, ReceiptCapabilityTier.medium);
      expect(capability.parserDepth, ReceiptParserDepth.lineItems);
      expect(capability.cameraResolutionTier, ReceiptCameraResolutionTier.high);
      expect(capability.assistedCameraShotCount, 4);
      expect(capability.enableTradeClassification, isTrue);
      expect(capability.maxLocalInventoryCacheItems, 5000);
      expect(
        capability.recommendedDataSaverLevel,
        ReceiptDataSaverLevel.balanced,
      );
    },
  );

  test(
    'automatic capability assessment picks a heavyweight tier for capable phones',
    () {
      final capability = ReceiptDeviceCapability.fromHardware(
        hardware: const ReceiptHardwareProfile(
          availableRamMb: 12288,
          cpuCores: 8,
          androidSdk: 35,
          androidPerformanceClass: 34,
          freeStorageMb: 12000,
          hasOnDeviceAcceleration: true,
        ),
      );

      expect(capability.tier, ReceiptCapabilityTier.heavyweight);
      expect(capability.parserDepth, ReceiptParserDepth.inventoryMatching);
      expect(capability.cameraResolutionTier, ReceiptCameraResolutionTier.max);
      expect(capability.assistedCameraShotCount, 5);
      expect(capability.readyHoldMs, lessThan(650));
      expect(capability.enableSkuDetection, isTrue);
      expect(capability.maxLocalCatalogMatches, greaterThan(5000));
      expect(
        capability.recommendedDataSaverLevel,
        ReceiptDataSaverLevel.balanced,
      );
    },
  );

  test(
    'camera workload uses measured capability detail within a shared tier',
    () {
      final capability = ReceiptDeviceCapability.fromHardware(
        hardware: const ReceiptHardwareProfile(
          availableRamMb: 6144,
          cpuCores: 6,
          androidSdk: 33,
          freeStorageMb: 2400,
          cameraPermissionGranted: true,
          hasRearCamera: true,
          supportsContinuousFocus: true,
          supportsExposureCompensation: true,
          supportsZoom: true,
        ),
      );

      expect(capability.tier, ReceiptCapabilityTier.medium);
      expect(capability.cameraWorkloadTier, ReceiptCameraWorkloadTier.enhanced);
      expect(capability.maxLiveAnalysisPixels, 1800000);
    },
  );

  test('manual performance modes override automatic tier selection safely', () {
    const strongHardware = ReceiptHardwareProfile(
      availableRamMb: 12288,
      cpuCores: 8,
      androidPerformanceClass: 34,
      hasOnDeviceAcceleration: true,
    );
    const constrainedHardware = ReceiptHardwareProfile(
      availableRamMb: 3900,
      cpuCores: 4,
      androidSdk: 28,
    );

    expect(
      ReceiptDeviceCapability.fromHardware(
        hardware: strongHardware,
        mode: ReceiptPerformanceMode.batterySaver,
      ).tier,
      ReceiptCapabilityTier.light,
    );
    expect(
      ReceiptDeviceCapability.fromHardware(
        hardware: strongHardware,
        mode: ReceiptPerformanceMode.balanced,
      ).tier,
      ReceiptCapabilityTier.medium,
    );
    expect(
      ReceiptDeviceCapability.fromHardware(
        hardware: constrainedHardware,
        mode: ReceiptPerformanceMode.maximumPerformance,
      ).tier,
      ReceiptCapabilityTier.light,
    );
  });

  test('low storage tightens automatic receipt photo space saving', () {
    final capability = ReceiptDeviceCapability.fromHardware(
      hardware: const ReceiptHardwareProfile(
        availableRamMb: 12288,
        cpuCores: 8,
        androidPerformanceClass: 34,
        freeStorageMb: 320,
        hasOnDeviceAcceleration: true,
      ),
      mode: ReceiptPerformanceMode.maximumPerformance,
    );

    expect(capability.tier, ReceiptCapabilityTier.light);
    expect(capability.recommendedDataSaverLevel, ReceiptDataSaverLevel.maximum);
    expect(capability.usesLeanLocalReceiptReading, isTrue);
    expect(capability.profileName, contains('critical storage'));
    expect(capability.maxLocalPhotoBytes, 4 * 1024 * 1024);
    expect(capability.maxLocalPhotoCount, 4);
    expect(capability.assistedCameraShotCount, 1);
    expect(capability.liveAnalysisGapMs, greaterThanOrEqualTo(1100));
    expect(capability.maxLocalCatalogMatches, 150);
    expect(capability.maxLocalInventoryCacheItems, 400);
    expect(capability.enableSkuDetection, isFalse);
    expect(capability.enableTradeClassification, isFalse);
    expect(capability.enableAdvancedConfidenceScoring, isFalse);
    expect(capability.shouldOfferCloudOcrAssist, isTrue);
    expect(capability.shouldOfferCloudInventoryAssist, isTrue);
    expect(
      capability.cloudAssistPlan.planCode,
      'local_ocr_cloud_ocr_cloud_inventory_optional',
    );
    expect(capability.cloudAssistPlan.localOcrAvailable, isTrue);
    expect(capability.cloudAssistPlan.localOcrMode, 'lean_local_ocr');
    expect(capability.cloudAssistPlan.hasOptionalCloudAssist, isTrue);
    expect(capability.cloudAssistPlan.toPrivacySafeDiagnostics(), {
      'cloudAssistPlan': 'local_ocr_cloud_ocr_cloud_inventory_optional',
      'ocrDecisionPolicy': 'local_default_cloud_optional',
      'localOcrAvailable': true,
      'localOcrMode': 'lean_local_ocr',
      'localOcrDefault': true,
      'cloudOcrOptional': true,
      'cloudInventoryOptional': true,
      'cloudAssistRequiresExplicitChoice': true,
      'cloudAssistRequiresInternet': true,
      'cameraCaptureCloudRequired': false,
      'receiptReviewCloudRequired': false,
      'parserDepth': 'proofTotalsOnly',
      'localParserScope': 'vendor_date_totals_local',
      'localCatalogMatchLimit': 150,
      'localInventoryCacheLimit': 400,
      'dataSaverLevel': 'maximum',
      'parserPackCodes': ['core_receipt_text_v1', 'cloud_ocr_assist_v1'],
      'optionalLocalParserPackCodes': <String>[],
      'cloudFallbackParserPackCodes': ['cloud_ocr_assist_v1'],
      'parserPackAccuracyBands': {
        'core_receipt_text_v1': 'ocr_text_95_99_when_photo_readable',
        'cloud_ocr_assist_v1': 'cloud_ocr_best_available_provider',
      },
      'estimatedOptionalLocalPackBytes': 0,
      'baseReceiptBudgetBytes': 40 * 1024 * 1024,
      'includedLocalPackBytes': 0,
      'optionalLocalPackBytes': 0,
      'baseIncludesHeavyParserPacks': false,
      'footprintCloudFallbackPackCodes': ['cloud_ocr_assist_v1'],
      'lowStorageSafe': true,
      'requiresExplicitDownloadForHeavyPacks': false,
      'userFacingPackDisclosureLabel':
          'No extra local parser download is required for this setup. '
          'Cloud OCR/parser fallback needs internet and must be chosen by the '
          'user. Accuracy disclosures: core_receipt_text_v1: '
          'ocr_text_95_99_when_photo_readable; cloud_ocr_assist_v1: '
          'cloud_ocr_best_available_provider.',
      'userFacingFootprintLabel':
          'The core receipt camera and basic local receipt reading stay in the base app budget. No extra local receipt pack download is needed for this setup. Cloud fallback is optional and requires internet.',
    });
    expect(
      capability.cloudAssistPlan.localParserScopeLabel,
      contains('vendor, date, subtotal, tax, and total'),
    );
    expect(
      capability.localReceiptReadingPlanLabel,
      contains('Basic on-device receipt assistance stays available'),
    );
    expect(capability.optionalCloudAssistLabel, contains('must be explicit'));
    expect(
      capability.optionalCloudInventoryAssistLabel,
      contains('large catalogs'),
    );
    expect(capability.optionalCloudAssistPlanLabel, contains('cloud OCR'));
    expect(
      capability.optionalCloudAssistPlanLabel,
      contains('cloud inventory matching'),
    );
  });
}
