import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_service.dart';

import 'helpers/receipt_native_storage_brain_expectations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native service sends storage safety limits through channel', () async {
    const channel = MethodChannel('maintainiac/receipt_camera_storage_test');
    late Map<dynamic, dynamic> sentArguments;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'captureReceipt');
          sentArguments = call.arguments as Map<dynamic, dynamic>;
          return {
            'originalPhotoPaths': ['/tmp/storage-safe-section.jpg'],
            'temporaryCaptureIds': ['native-storage-safe'],
            'capturedAt': '2026-06-28T12:05:00.000Z',
            'captureDiagnostics': {
              'storageSafetyReason': 'tight_storage_tiny_proofs',
            },
          };
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    const capabilities = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      hasRearCamera: true,
    );
    final config =
        const ReceiptNativeCameraSettings(
          dataSaverLevel: ReceiptDataSaverLevel.maximum,
        ).sessionFor(
          deviceCapability: const ReceiptDeviceCapability.highCapacity(),
          nativeCapabilities: capabilities,
        );

    final result = await ReceiptNativeCameraService(
      methodChannel: channel,
    ).captureReceipt(config);

    expect(result.originalPhotoPaths, ['/tmp/storage-safe-section.jpg']);
    expect(sentArguments['dataSaverLevel'], ReceiptDataSaverLevel.maximum.name);
    expect(
      sentArguments['storageSafetyLevel'],
      ReceiptDataSaverLevel.maximum.name,
    );
    expect(sentArguments['storageConstrained'], isTrue);
    expect(sentArguments['storageSafetyReason'], 'tight_storage_tiny_proofs');
    expect(sentArguments['maxSectionCount'], 4);
    expect(sentArguments['ocrUsesOriginalFirst'], isTrue);
    expect(sentArguments['devicePolicyLabel'], 'storage_saver_receipt_camera');
    expect(
      sentArguments['cloudAssistPlan'],
      'local_ocr_cloud_ocr_cloud_inventory_optional',
    );
    expect(sentArguments['ocrDecisionPolicy'], 'local_default_cloud_optional');
    expect(sentArguments['localOcrAvailable'], isTrue);
    expect(sentArguments['localOcrMode'], 'lean_local_ocr');
    expect(sentArguments['localOcrDefault'], isTrue);
    expect(sentArguments['cloudOcrOptional'], isTrue);
    expect(sentArguments['cloudInventoryOptional'], isTrue);
    expect(sentArguments['cloudAssistRequiresExplicitChoice'], isTrue);
    expect(sentArguments['cloudAssistRequiresInternet'], isTrue);
    expect(sentArguments['cameraCaptureCloudRequired'], isFalse);
    expect(sentArguments['receiptReviewCloudRequired'], isFalse);
    expect(sentArguments['receiptInstallMode'], 'base_receipt_only');
    expect(
      sentArguments['receiptInstallOptionalLocalDownloadAllowed'],
      isFalse,
    );
    expect(sentArguments['receiptInstallCloudFallbackSuggested'], isTrue);
    expect(sentArguments['receiptInstallMaxOptionalLocalBytes'], 0);
    expect(
      sentArguments['receiptInstallReason'],
      'critical_storage_protect_base_capture',
    );
    expectStorageSaverReceiptBrainArguments(sentArguments, result);
    expect(sentArguments['parserPackRouteCount'], 3);
    expect(sentArguments['parserPackLocalFirstCategoryCodes'], [
      'fuel',
      'general_expense',
    ]);
    expect(sentArguments['parserPackOptionalLocalCategoryCodes'], [
      'general_expense',
    ]);
    expect(sentArguments['parserPackAssistFallbackCategoryCodes'], [
      'fuel',
      'general_expense',
      'materials_inventory',
    ]);
    expect(sentArguments['parserPackFutureRegionalCategoryCodes'], [
      'fuel',
      'general_expense',
      'materials_inventory',
    ]);
    expect(sentArguments['parserDepth'], ReceiptParserDepth.lineItems.name);
    expect(sentArguments['localParserScope'], 'line_items_local');
    expect(sentArguments['localCatalogMatchLimit'], 250);
    expect(sentArguments['localInventoryCacheLimit'], 1000);
    expect(sentArguments['bestShotCandidateCount'], 3);
    expect(
      sentArguments['cameraWorkloadTier'],
      ReceiptCameraWorkloadTier.light.name,
    );
    expect(sentArguments['maxLiveAnalysisPixels'], 0);
    expect(sentArguments['maxCleanupPixels'], 6000000);
    expect(sentArguments['maxStitchOutputPixels'], 18000000);
    expect(sentArguments['maxStitchOutputHeight'], 24000);
    expect(sentArguments['shadowReductionEnabled'], isFalse);
    expect(
      result.captureDiagnostics['cloudAssistPlan'],
      'local_ocr_cloud_ocr_cloud_inventory_optional',
    );
    expect(
      result.captureDiagnostics['ocrDecisionPolicy'],
      'local_default_cloud_optional',
    );
    expect(result.captureDiagnostics['localOcrAvailable'], isTrue);
    expect(result.captureDiagnostics['localOcrMode'], 'lean_local_ocr');
    expect(result.captureDiagnostics['localOcrDefault'], isTrue);
    expect(result.captureDiagnostics['localParserScope'], 'line_items_local');
    expect(result.captureDiagnostics['cloudOcrOptional'], isTrue);
    expect(result.captureDiagnostics['cloudInventoryOptional'], isTrue);
    expect(
      result.captureDiagnostics['cloudAssistRequiresExplicitChoice'],
      isTrue,
    );
    expect(result.captureDiagnostics['cloudAssistRequiresInternet'], isTrue);
    expect(result.captureDiagnostics['cameraCaptureCloudRequired'], isFalse);
    expect(result.captureDiagnostics['receiptReviewCloudRequired'], isFalse);
    expect(
      result.captureDiagnostics['receiptInstallMode'],
      'base_receipt_only',
    );
    expect(
      result.captureDiagnostics['receiptInstallCloudFallbackSuggested'],
      isTrue,
    );
    expect(result.captureDiagnostics['parserPackRouteCount'], 3);
    expect(result.captureDiagnostics['parserPackOptionalLocalCategoryCodes'], [
      'general_expense',
    ]);
  });

  test(
    'native service sends older-phone stitch caps through channel',
    () async {
      const channel = MethodChannel('maintainiac/receipt_camera_light_test');
      late Map<dynamic, dynamic> sentArguments;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'captureReceipt');
            sentArguments = call.arguments as Map<dynamic, dynamic>;
            return {
              'originalPhotoPaths': ['/tmp/light-phone-section.jpg'],
              'temporaryCaptureIds': ['native-light-phone'],
              'capturedAt': '2026-07-02T06:51:00.000Z',
              'captureDiagnostics': const {},
            };
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      const capabilities = ReceiptNativeCameraCapabilities(
        engine: ReceiptNativeCameraEngine.cameraX,
        available: true,
        cameraPermissionGranted: true,
        hasRearCamera: true,
        supportsYuvLiveFrames: true,
        supportsNativeEdgeSignals: true,
      );
      final config =
          const ReceiptNativeCameraSettings(
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
            autoCaptureEnabled: true,
          ).sessionFor(
            deviceCapability: const ReceiptDeviceCapability.olderPhone(),
            nativeCapabilities: capabilities,
          );

      final result = await ReceiptNativeCameraService(
        methodChannel: channel,
      ).captureReceipt(config);

      expect(result.originalPhotoPaths, ['/tmp/light-phone-section.jpg']);
      expect(sentArguments['deviceTier'], ReceiptCapabilityTier.light.name);
      expect(sentArguments['maxSectionCount'], 4);
      expect(sentArguments['autoCaptureAllowed'], isFalse);
      expect(sentArguments['autoCaptureEnabled'], isFalse);
      expect(
        sentArguments['cameraWorkloadTier'],
        ReceiptCameraWorkloadTier.light.name,
      );
      expect(sentArguments['maxLiveAnalysisPixels'], 0);
      expect(sentArguments['maxCleanupPixels'], 6000000);
      expect(sentArguments['maxStitchOutputPixels'], 9000000);
      expect(sentArguments['maxStitchOutputHeight'], 14000);
      expect(sentArguments['maxLocalPhotoBytes'], 6 * 1024 * 1024);
      expect(
        sentArguments['nativeCaptureMemoryPolicy'],
        'small_local_proof_temporary_source_for_ocr_then_cleanup',
      );
      expect(sentArguments['cloudOcrOptional'], isTrue);
      expect(sentArguments['cameraCaptureCloudRequired'], isFalse);
      expect(sentArguments['ocrUsesOriginalFirst'], isTrue);
    },
  );
}
