import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

import 'helpers/receipt_assistance_policy_fixtures.dart';

void main() {
  test('hardware diagnostics labels unknown and concrete signals clearly', () {
    const unknown = ReceiptHardwareProfile();
    const detected = ReceiptHardwareProfile(
      platformName: 'android',
      platformVersion: 'Android 15',
      availableRamMb: 12288,
      cpuCores: 8,
      androidSdk: 35,
      androidPerformanceClass: 34,
      freeStorageMb: 6144,
      lowPowerMode: true,
      hasOnDeviceAcceleration: true,
      cameraPermissionGranted: true,
      cameraCount: 4,
      hasRearCamera: true,
      supportsTapFocus: true,
      supportsExposureCompensation: true,
      supportsZoom: true,
      supportsYuvLiveFrames: true,
      supportsNativeEdgeSignals: true,
      maxStillWidth: 4032,
      maxStillHeight: 3024,
    );

    expect(unknown.platformLabel, 'Unknown');
    expect(unknown.availableRamLabel, 'Unknown');
    expect(unknown.androidSdkLabel, 'Unavailable');
    expect(unknown.accelerationLabel, 'Not detected');

    expect(detected.platformLabel, 'android');
    expect(detected.platformVersionLabel, 'Android 15');
    expect(detected.availableRamLabel, '12.0 GB');
    expect(detected.cpuCoresLabel, '8 cores');
    expect(detected.androidSdkLabel, 'Android SDK 35');
    expect(detected.androidPerformanceClassLabel, '34');
    expect(detected.freeStorageLabel, '6.0 GB');
    expect(detected.lowPowerModeLabel, 'On');
    expect(detected.accelerationLabel, 'Detected');
    expect(detected.maxStillMegapixels, 12);
    expect(detected.cameraLabel, '4 cameras detected');
    expect(detected.receiptCameraControlLabel, contains('tap focus'));
    expect(detected.receiptCameraControlLabel, contains('pinch zoom'));
    expect(detected.receiptCameraControlLabel, contains('brightness'));
    expect(detected.receiptCameraControlLabel, contains('edge guidance'));
    expect(detected.receiptCameraControlLabel, contains('live readability'));
  });

  test(
    'native camera controls strengthen automatic tier without raw UI exposure',
    () {
      final withNativeReceiptControls = ReceiptDeviceCapability.fromHardware(
        hardware: const ReceiptHardwareProfile(
          availableRamMb: 6144,
          cpuCores: 6,
          androidSdk: 33,
          freeStorageMb: 4096,
          cameraPermissionGranted: true,
          cameraCount: 3,
          hasRearCamera: true,
          supportsTapFocus: true,
          supportsExposureCompensation: true,
          supportsZoom: true,
          supportsYuvLiveFrames: true,
          supportsNativeEdgeSignals: true,
          maxStillWidth: 4032,
          maxStillHeight: 3024,
        ),
      );

      expect(withNativeReceiptControls.tier, ReceiptCapabilityTier.heavyweight);
      expect(
        withNativeReceiptControls.cameraWorkloadTier,
        ReceiptCameraWorkloadTier.flagship,
      );
      expect(withNativeReceiptControls.maxLiveAnalysisPixels, 2200000);
      expect(withNativeReceiptControls.bestShotCandidateCount, 5);
    },
  );

  test(
    'camera defaults scale by capability without exposing raw hardware UI',
    () {
      const light = ReceiptDeviceCapability.olderPhone();
      const standard = ReceiptDeviceCapability.standard();
      const heavy = ReceiptDeviceCapability.highCapacity();

      expect(light.cameraResolutionTier, ReceiptCameraResolutionTier.medium);
      expect(light.cameraWorkloadTier, ReceiptCameraWorkloadTier.light);
      expect(light.assistedCameraShotCount, 2);
      expect(light.bestShotCandidateCount, 1);
      expect(light.liveAnalysisGapMs, greaterThan(700));
      expect(light.maxLiveAnalysisPixels, 900000);
      expect(light.maxCleanupPixels, 6000000);

      expect(standard.cameraResolutionTier, ReceiptCameraResolutionTier.high);
      expect(standard.cameraWorkloadTier, ReceiptCameraWorkloadTier.balanced);
      expect(standard.assistedCameraShotCount, 4);
      expect(standard.bestShotCandidateCount, 3);
      expect(standard.maxLiveAnalysisPixels, 1400000);
      expect(standard.maxCleanupPixels, 10000000);

      expect(heavy.cameraResolutionTier, ReceiptCameraResolutionTier.max);
      expect(heavy.cameraWorkloadTier, ReceiptCameraWorkloadTier.flagship);
      expect(heavy.assistedCameraShotCount, 5);
      expect(heavy.bestShotCandidateCount, 5);
      expect(heavy.liveAnalysisGapMs, lessThan(standard.liveAnalysisGapMs));
      expect(heavy.maxLiveAnalysisPixels, 2200000);
      expect(heavy.maxCleanupPixels, 14000000);
      expect(
        light.stitchLimits.maxOutputPixels,
        lessThan(standard.stitchLimits.maxOutputPixels),
      );
      expect(
        standard.stitchLimits.maxOutputPixels,
        lessThan(heavy.stitchLimits.maxOutputPixels),
      );
    },
  );

  test('large photos stay readable but force review on older phones', () {
    final decision =
        const ReceiptAssistancePolicy(
          device: ReceiptDeviceCapability.olderPhone(),
        ).decideForAttachment(
          receiptAttachmentFixture(
            kind: ReceiptAttachmentKind.photo,
            byteSize: 9 * 1024 * 1024,
          ),
        );

    expect(decision.mode, ReceiptAssistanceMode.localReadWithReview);
    expect(decision.shouldReadLocally, isTrue);
    expect(decision.reason, contains('large for Older phone'));
    expect(decision.warnings.join(' '), contains('slower on older phones'));
  });

  test('low storage phones keep local OCR while cloud OCR stays optional', () {
    final capability = ReceiptDeviceCapability.fromHardware(
      hardware: const ReceiptHardwareProfile(
        availableRamMb: 2048,
        cpuCores: 4,
        androidSdk: 28,
        freeStorageMb: 220,
      ),
    );
    final decision =
        ReceiptAssistancePolicy(
          device: capability,
          cloudAssistedAvailable: true,
        ).decideForAttachment(
          receiptAttachmentFixture(
            kind: ReceiptAttachmentKind.photo,
            byteSize: 5 * 1024 * 1024,
          ),
        );

    expect(capability.tier, ReceiptCapabilityTier.light);
    expect(capability.recommendedDataSaverLevel, ReceiptDataSaverLevel.maximum);
    expect(capability.parserDepth, ReceiptParserDepth.proofTotalsOnly);
    expect(capability.maxLocalCatalogMatches, lessThanOrEqualTo(250));
    expect(capability.shouldOfferCloudOcrAssist, isTrue);
    expect(capability.shouldOfferCloudInventoryAssist, isTrue);
    expect(decision.shouldReadLocally, isTrue);
    expect(decision.mode, ReceiptAssistanceMode.localReadWithReview);
    expect(decision.reason, contains('large for Older phone'));
  });
}
