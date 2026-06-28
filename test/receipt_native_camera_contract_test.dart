import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'native receipt camera defaults protect user control and OCR source',
    () {
      const settings = ReceiptNativeCameraSettings();

      expect(settings.assistedReceiptFill, isTrue);
      expect(settings.reviewDepth, ReceiptNativeReviewDepth.pricesOnly);
      expect(settings.manualShutterAlwaysAvailable, isTrue);
      expect(settings.autoCaptureEnabled, isFalse);
      expect(settings.tapFocusEnabled, isTrue);
      expect(settings.pinchZoomEnabled, isTrue);
      expect(settings.autoExposureAssistEnabled, isTrue);
      expect(settings.edgeDetectionEnabled, isTrue);
      expect(settings.previousSectionGhostGuideEnabled, isTrue);
      expect(settings.saveOriginalTemporarily, isTrue);
      expect(settings.queueAcceptedCaptureLocally, isTrue);
      expect(settings.protectsInterruptedCapture, isTrue);
      expect(settings.ocrUsesOriginalFirst, isTrue);
      expect(settings.dataSaverLevel, ReceiptDataSaverLevel.balanced);
    },
  );

  test('settings descriptors cover the receipt camera control package', () {
    final descriptors = ReceiptNativeCameraSettings.descriptors;
    final ids = descriptors.map((descriptor) => descriptor.id).toSet();

    expect(ids, contains('assisted_receipt_fill'));
    expect(ids, contains('review_depth'));
    expect(ids, contains('auto_capture'));
    expect(ids, contains('tap_focus'));
    expect(ids, contains('pinch_zoom'));
    expect(ids, contains('exposure_slider'));
    expect(ids, contains('auto_exposure_assist'));
    expect(ids, contains('focus_lock'));
    expect(ids, contains('edge_detection'));
    expect(ids, contains('readability_warnings'));
    expect(ids, contains('long_receipt_mode'));
    expect(ids, contains('image_cleanup'));
    expect(ids, contains('safe_capture_queue'));
    expect(ids, contains('save_space_preview'));

    final autoCapture = descriptors.singleWhere(
      (descriptor) => descriptor.id == 'auto_capture',
    );
    expect(autoCapture.defaultEnabled, isFalse);
    expect(autoCapture.description, contains('Optional'));
    expect(autoCapture.description, contains('off by default'));
    expect(
      autoCapture.description,
      contains('several steady, readable receipt frames'),
    );
    expect(
      autoCapture.description,
      contains('shutter button still works anytime'),
    );

    final safeQueue = descriptors.singleWhere(
      (descriptor) => descriptor.id == 'safe_capture_queue',
    );
    expect(safeQueue.description, contains('call, crash, or app switch'));
  });

  test('session disables heavy live work on light phones', () {
    const settings = ReceiptNativeCameraSettings(autoCaptureEnabled: true);
    const native = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      cameraCount: 2,
      hasRearCamera: true,
      supportsYuvLiveFrames: true,
      supportsNativeEdgeSignals: true,
    );

    final config = settings.sessionFor(
      deviceCapability: const ReceiptDeviceCapability.olderPhone(),
      nativeCapabilities: native,
    );

    expect(config.manualCaptureAvailable, isTrue);
    expect(config.interruptionSafe, isTrue);
    expect(config.liveAnalysisEnabled, isFalse);
    expect(config.autoCaptureAllowed, isFalse);
    expect(config.autoCaptureEnabled, isFalse);
    expect(config.maxSectionCount, 4);
  });

  test('session allows stronger live work on capable phones', () {
    const settings = ReceiptNativeCameraSettings(autoCaptureEnabled: true);
    const native = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      cameraCount: 4,
      hasRearCamera: true,
      supportsYuvLiveFrames: true,
      supportsNativeEdgeSignals: true,
    );

    final config = settings.sessionFor(
      deviceCapability: const ReceiptDeviceCapability.highCapacity(),
      nativeCapabilities: native,
    );

    expect(config.liveAnalysisEnabled, isTrue);
    expect(config.edgeDetectionEnabled, isTrue);
    expect(config.autoCaptureAllowed, isTrue);
    expect(config.autoCaptureEnabled, isTrue);
    expect(config.maxSectionCount, 12);
    expect(config.storageConstrained, isFalse);
    expect(config.storageSafetyLevel, ReceiptDataSaverLevel.balanced);
    expect(config.storageSafetyReason, 'normal');
  });

  test('session limits long receipt sections when proof storage is tiny', () {
    const settings = ReceiptNativeCameraSettings(
      autoCaptureEnabled: true,
      dataSaverLevel: ReceiptDataSaverLevel.maximum,
    );
    const native = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      cameraCount: 4,
      hasRearCamera: true,
      supportsYuvLiveFrames: true,
      supportsNativeEdgeSignals: true,
    );

    final config = settings.sessionFor(
      deviceCapability: const ReceiptDeviceCapability.highCapacity(),
      nativeCapabilities: native,
    );

    expect(config.manualCaptureAvailable, isTrue);
    expect(config.ocrSourceProtected, isTrue);
    expect(config.storageConstrained, isTrue);
    expect(config.storageSafetyLevel, ReceiptDataSaverLevel.maximum);
    expect(config.storageSafetyReason, 'tight_storage_tiny_proofs');
    expect(config.maxSectionCount, 4);
    expect(config.liveAnalysisEnabled, isTrue);
    expect(config.autoCaptureAllowed, isFalse);
    expect(config.autoCaptureEnabled, isFalse);
  });

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
      expect(config.maxSectionCount, 6);
      expect(config.autoCaptureAllowed, isFalse);
      expect(config.autoCaptureEnabled, isFalse);
      expect(config.ocrSourceProtected, isTrue);
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
    expect(guideDisabled.hasPreviousSectionGuide, isFalse);
    expect(longReceiptDisabled.hasPreviousSectionGuide, isFalse);
  });

  test(
    'native service reads capabilities through Maintainiac channel',
    () async {
      const channel = MethodChannel('maintainiac/receipt_camera_test');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'readCapabilities');
            return {
              'engine': ReceiptNativeCameraEngine.cameraX.name,
              'available': true,
              'cameraPermissionGranted': true,
              'cameraCount': 3,
              'hasRearCamera': true,
              'hasFrontCamera': true,
              'supportsTapFocus': true,
              'supportsExposureCompensation': true,
              'supportsZoom': true,
              'maxZoom': 8.0,
              'maxStillWidth': 4032,
              'maxStillHeight': 3024,
            };
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });

      final service = ReceiptNativeCameraService(methodChannel: channel);
      final capabilities = await service.readCapabilities();

      expect(capabilities.engine, ReceiptNativeCameraEngine.cameraX);
      expect(capabilities.canOpenReceiptCamera, isTrue);
      expect(capabilities.supportsTapFocus, isTrue);
      expect(capabilities.supportsZoom, isTrue);
      expect(capabilities.maxZoom, 8);
      expect(capabilities.maxStillWidth, 4032);
      expect(capabilities.maxStillHeight, 3024);
    },
  );

  test('native service sends previous section guide through channel', () async {
    const channel = MethodChannel('maintainiac/receipt_camera_guide_test');
    late Map<dynamic, dynamic> sentArguments;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'captureReceipt');
          sentArguments = call.arguments as Map<dynamic, dynamic>;
          return {
            'originalPhotoPaths': ['/tmp/new-section.jpg'],
            'temporaryCaptureIds': ['native-guide-capture'],
            'capturedAt': '2026-06-28T12:00:00.000Z',
            'captureDiagnostics': {'hasPreviousSectionGuide': true},
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
    final config = const ReceiptNativeCameraSettings().sessionFor(
      deviceCapability: const ReceiptDeviceCapability.standard(),
      nativeCapabilities: capabilities,
      previousSectionGuidePhotoPath: '/tmp/section-one.jpg',
    );

    final result = await ReceiptNativeCameraService(
      methodChannel: channel,
    ).captureReceipt(config);

    expect(result.originalPhotoPaths, ['/tmp/new-section.jpg']);
    expect(
      sentArguments['previousSectionGuidePhotoPath'],
      '/tmp/section-one.jpg',
    );
    expect(sentArguments['previousSectionGhostGuideEnabled'], isTrue);
    expect(sentArguments['longReceiptMode'], isTrue);
    expect(sentArguments['autoExposureAssistEnabled'], isTrue);
    expect(sentArguments['autoCaptureAllowed'], isFalse);
    expect(sentArguments['tapFocusEnabled'], isTrue);
    expect(sentArguments['pinchZoomEnabled'], isTrue);
    expect(sentArguments['exposureSliderEnabled'], isTrue);
    expect(sentArguments['exposureResetEnabled'], isTrue);
    expect(
      sentArguments['storageSafetyLevel'],
      ReceiptDataSaverLevel.balanced.name,
    );
    expect(sentArguments['storageConstrained'], isFalse);
    expect(sentArguments['storageSafetyReason'], 'normal');
  });

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
  });

  test('native service preserves ordered long receipt section paths', () async {
    const channel = MethodChannel('maintainiac/receipt_camera_batch_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'captureReceipt');
          return {
            'originalPhotoPaths': [
              '/tmp/section-top.jpg',
              '/tmp/section-middle.jpg',
              '/tmp/section-bottom.jpg',
            ],
            'temporaryCaptureIds': [
              'section-top',
              'section-middle',
              'section-bottom',
            ],
            'capturedAt': '2026-06-28T12:10:00.000Z',
            'captureDiagnostics': {
              'photoCount': 3,
              'maxSectionCount': 12,
              'ocrUsesOriginalFirst': true,
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
    final config = const ReceiptNativeCameraSettings().sessionFor(
      deviceCapability: const ReceiptDeviceCapability.highCapacity(),
      nativeCapabilities: capabilities,
    );

    final result = await ReceiptNativeCameraService(
      methodChannel: channel,
    ).captureReceipt(config);

    expect(result.originalPhotoPaths, [
      '/tmp/section-top.jpg',
      '/tmp/section-middle.jpg',
      '/tmp/section-bottom.jpg',
    ]);
    expect(result.temporaryCaptureIds, [
      'section-top',
      'section-middle',
      'section-bottom',
    ]);
    expect(result.captureDiagnostics['photoCount'], 3);
    expect(result.captureDiagnostics['ocrUsesOriginalFirst'], isTrue);
  });

  test(
    'native service treats camera back/cancel as clean cancellation',
    () async {
      const channel = MethodChannel('maintainiac/receipt_camera_cancel_test');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'captureReceipt');
            throw PlatformException(
              code: 'native_camera_cancelled',
              message: 'Receipt photo capture was cancelled.',
            );
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
      final config = const ReceiptNativeCameraSettings().sessionFor(
        deviceCapability: const ReceiptDeviceCapability.standard(),
        nativeCapabilities: capabilities,
      );

      expect(
        () => ReceiptNativeCameraService(
          methodChannel: channel,
        ).captureReceipt(config),
        throwsA(isA<ReceiptNativeCameraCanceledException>()),
      );
    },
  );

  test(
    'device capability service does not depend on Flutter camera package',
    () async {
      final source = await File(
        'lib/shared/widgets/receipt_capture/receipt_device_capability_service.dart',
      ).readAsString();
      expect(source, isNot(contains("package:camera/camera.dart")));
      expect(source, contains('ReceiptNativeCameraService'));
      expect(source, contains('readCapabilities'));
    },
  );
}
