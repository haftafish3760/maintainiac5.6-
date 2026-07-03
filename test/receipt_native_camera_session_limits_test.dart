import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'session honors device storage pressure even with balanced user setting',
    () {
      const native = ReceiptNativeCameraCapabilities(
        engine: ReceiptNativeCameraEngine.cameraX,
        available: true,
        cameraPermissionGranted: true,
        cameraCount: 3,
        hasRearCamera: true,
        supportsYuvLiveFrames: true,
        supportsNativeEdgeSignals: true,
      );
      final storagePressedDevice = const ReceiptDeviceCapability.highCapacity()
          .withStoragePressure(ReceiptDeviceStorageClass.low);

      final config =
          const ReceiptNativeCameraSettings(
            autoCaptureEnabled: true,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
          ).sessionFor(
            deviceCapability: storagePressedDevice,
            nativeCapabilities: native,
          );

      expect(config.storageConstrained, isTrue);
      expect(config.storageSafetyLevel, ReceiptDataSaverLevel.strong);
      expect(config.storageSafetyReason, 'low_storage_small_proofs');
      expect(config.maxSectionCount, 5);
      expect(config.autoCaptureAllowed, isFalse);
      expect(config.autoCaptureEnabled, isFalse);
      expect(config.ocrSourceProtected, isTrue);
      expect(
        config.cloudAssistPlan.planCode,
        'local_ocr_cloud_ocr_cloud_inventory_optional',
      );
      expect(config.cloudAssistPlan.localOcrAvailable, isTrue);
      expect(config.cloudAssistPlan.localOcrMode, 'lean_local_ocr');
      expect(config.cloudAssistPlan.cloudOcrOptional, isTrue);
      expect(config.cloudAssistPlan.cloudInventoryOptional, isTrue);
      expect(config.cloudAssistPlan.requiresExplicitUserChoice, isTrue);
      expect(config.cloudAssistPlan.localCatalogMatchLimit, 500);
      expect(config.cloudAssistPlan.localInventoryCacheLimit, 1500);
      expect(
        config.installRecommendation.modeCode,
        'small_optional_pack_allowed',
      );
      expect(config.installRecommendation.optionalLocalDownloadAllowed, isTrue);
      expect(config.installRecommendation.cloudFallbackSuggested, isTrue);
      expect(
        config.receiptBrainRecommendation.modeCode,
        'base_local_reader_small_pack_optional',
      );
      expect(
        config.receiptBrainRecommendation.baseCaptureAlwaysAvailable,
        isTrue,
      );
      expect(
        config.receiptBrainRecommendation.localReceiptReaderDefault,
        isTrue,
      );
      expect(
        config.receiptBrainRecommendation.optionalLocalPackAllowed,
        isTrue,
      );
      expect(
        config.receiptBrainRecommendation.optionalLocalPackBytes,
        24 * 1024 * 1024,
      );
      expect(config.receiptBrainRecommendation.assistFallbackAllowed, isTrue);
      expect(config.parserPackRoutingPlan.localFirstCategoryCodes, [
        'fuel',
        'general_expense',
      ]);
      expect(config.parserPackRoutingPlan.optionalLocalCategoryCodes, [
        'general_expense',
      ]);
      expect(config.parserPackRoutingPlan.assistFallbackCategoryCodes, [
        'fuel',
        'general_expense',
        'materials_inventory',
      ]);
    },
  );

  test('session carries previous section guide only for long receipt flow', () {
    const native = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      hasRearCamera: true,
    );
    final withGuide = const ReceiptNativeCameraSettings().sessionFor(
      deviceCapability: const ReceiptDeviceCapability.highCapacity(),
      nativeCapabilities: native,
      previousSectionGuidePhotoPath: ' /tmp/receipt-section-1.jpg ',
      previousSectionReasonCode: ' missing_bottom_edge_and_totals ',
      previousSectionGuidance: ' Add the bottom receipt section. ',
    );
    final guideDisabled =
        const ReceiptNativeCameraSettings(
          previousSectionGhostGuideEnabled: false,
        ).sessionFor(
          deviceCapability: const ReceiptDeviceCapability.highCapacity(),
          nativeCapabilities: native,
          previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
        );
    final longReceiptDisabled =
        const ReceiptNativeCameraSettings(longReceiptMode: false).sessionFor(
          deviceCapability: const ReceiptDeviceCapability.highCapacity(),
          nativeCapabilities: native,
          previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
        );

    expect(withGuide.hasPreviousSectionGuide, isTrue);
    expect(
      withGuide.previousSectionGuidePhotoPath,
      '/tmp/receipt-section-1.jpg',
    );
    expect(
      withGuide.previousSectionGuideReasonCode,
      'missing_bottom_edge_and_totals',
    );
    expect(withGuide.previousSectionGuideMissingBottomAndTotals, isTrue);
    expect(
      withGuide.previousSectionGhostGuidePolicy,
      'bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
    );
    expect(
      withGuide.previousSectionGhostGuideRepeatLineTarget,
      'repeat_3_to_5_readable_lines',
    );
    expect(withGuide.previousSectionGhostGuidePlacement, 'top_ghost_slice');
    expect(
      withGuide.previousSectionGhostGuideMatchTarget,
      'subtotal_total_and_final_lines',
    );
    expect(withGuide.previousSectionGhostSourceStartFractionOrDefault, .80);
    expect(withGuide.previousSectionGhostSourceHeightFractionOrDefault, .20);
    expect(withGuide.previousSectionGhostOverlayTopFractionOrDefault, 0);
    expect(withGuide.previousSectionGhostOverlayHeightFractionOrDefault, .20);
    expect(withGuide.previousSectionGhostOpacityOrDefault, .36);
    expect(withGuide.previousSectionGhostSlicePercent, 20);
    expect(
      withGuide.previousSectionGuideGuidance,
      'Add the bottom receipt section.',
    );
    final bottomGuideWithoutCopy = const ReceiptNativeCameraSettings()
        .sessionFor(
          deviceCapability: const ReceiptDeviceCapability.highCapacity(),
          nativeCapabilities: native,
          previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
          previousSectionReasonCode: 'missing_bottom_edge_and_totals',
        );
    expect(
      bottomGuideWithoutCopy.previousSectionGuideGuidance,
      contains('repeat 3-5 readable lines'),
    );
    expect(
      bottomGuideWithoutCopy.previousSectionGuideGuidance,
      contains('top ghost slice'),
    );
    expect(
      bottomGuideWithoutCopy.previousSectionGuideGuidance,
      contains('subtotal, total, and final lines can be matched'),
    );
    expect(guideDisabled.hasPreviousSectionGuide, isFalse);
    expect(longReceiptDisabled.hasPreviousSectionGuide, isFalse);
    expect(longReceiptDisabled.maxSectionCount, 1);
    expect(
      longReceiptDisabled.capabilityPolicyCodes,
      contains('long_receipt_mode_disabled'),
    );
  });

  test(
    'session bounds previous section ghost guide fractions to usable values',
    () {
      const native = ReceiptNativeCameraCapabilities(
        engine: ReceiptNativeCameraEngine.cameraX,
        available: true,
        cameraPermissionGranted: true,
        hasRearCamera: true,
      );

      final tooSmall = const ReceiptNativeCameraSettings().sessionFor(
        deviceCapability: const ReceiptDeviceCapability.highCapacity(),
        nativeCapabilities: native,
        previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
        previousSectionGhostSourceStartFraction: 0,
        previousSectionGhostSourceHeightFraction: 0,
        previousSectionGhostOverlayTopFraction: 0,
        previousSectionGhostOverlayHeightFraction: 0,
        previousSectionGhostOpacity: 0,
      );
      final tooLarge = const ReceiptNativeCameraSettings().sessionFor(
        deviceCapability: const ReceiptDeviceCapability.highCapacity(),
        nativeCapabilities: native,
        previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
        previousSectionGhostSourceStartFraction: 1,
        previousSectionGhostSourceHeightFraction: 1,
        previousSectionGhostOverlayTopFraction: 1,
        previousSectionGhostOverlayHeightFraction: 1,
        previousSectionGhostOpacity: 1,
      );

      expect(tooSmall.previousSectionGhostSourceStartFractionOrDefault, .65);
      expect(tooSmall.previousSectionGhostSourceHeightFractionOrDefault, .12);
      expect(tooSmall.previousSectionGhostOverlayTopFractionOrDefault, 0);
      expect(tooSmall.previousSectionGhostOverlayHeightFractionOrDefault, .12);
      expect(tooSmall.previousSectionGhostOpacityOrDefault, .18);
      expect(tooSmall.previousSectionGhostSlicePercent, 12);

      expect(tooLarge.previousSectionGhostSourceStartFractionOrDefault, .92);
      expect(tooLarge.previousSectionGhostSourceHeightFractionOrDefault, .35);
      expect(tooLarge.previousSectionGhostOverlayTopFractionOrDefault, .30);
      expect(tooLarge.previousSectionGhostOverlayHeightFractionOrDefault, .35);
      expect(tooLarge.previousSectionGhostOpacityOrDefault, .62);
      expect(tooLarge.previousSectionGhostSlicePercent, 35);
    },
  );
}
