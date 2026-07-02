import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native service rejects stock camera UI capture results', () async {
    const channel = MethodChannel('maintainiac/receipt_camera_stock_ui_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'captureReceipt');
          return {
            'originalPhotoPaths': ['/tmp/stock-camera-receipt.jpg'],
            'temporaryCaptureIds': ['stock-camera-capture'],
            'capturedAt': '2026-06-29T12:20:00.000Z',
            'captureDiagnostics': {'stockCameraUiUsed': true},
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

    await expectLater(
      const ReceiptNativeCameraService(
        methodChannel: channel,
      ).captureReceipt(config),
      throwsA(
        isA<ReceiptNativeCameraUnavailableException>().having(
          (error) => error.message,
          'message',
          contains('stock camera UI'),
        ),
      ),
    );
  });

  test(
    'native service rejects mismatched native camera surface results',
    () async {
      const channel = MethodChannel(
        'maintainiac/receipt_camera_wrong_surface_test',
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'captureReceipt');
            return {
              'originalPhotoPaths': ['/tmp/wrong-surface-receipt.jpg'],
              'temporaryCaptureIds': ['wrong-surface-capture'],
              'capturedAt': '2026-06-29T12:21:00.000Z',
              'captureDiagnostics': {
                'captureSurface': 'system_stock_camera',
                'nativeCameraIdentity': 'external_camera_app',
                'stockCameraUiUsed': false,
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

      await expectLater(
        const ReceiptNativeCameraService(
          methodChannel: channel,
        ).captureReceipt(config),
        throwsA(
          isA<ReceiptNativeCameraUnavailableException>().having(
            (error) => error.message,
            'message',
            contains('expected maintainiac_native_android'),
          ),
        ),
      );
    },
  );

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
              details: {'closeAction': 'back_no_photo_cancel'},
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

      final capture = ReceiptNativeCameraService(
        methodChannel: channel,
      ).captureReceipt(config);

      await expectLater(
        capture,
        throwsA(
          isA<ReceiptNativeCameraCanceledException>().having(
            (error) => error.closeAction,
            'closeAction',
            'back_no_photo_cancel',
          ),
        ),
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
      expect(
        source,
        contains('supportsTapFocus: nativeCamera.supportsTapFocus'),
      );
      expect(source, contains('supportsZoom: nativeCamera.supportsZoom'));
      expect(
        source,
        contains('supportsYuvLiveFrames: nativeCamera.supportsYuvLiveFrames'),
      );
      expect(
        source,
        contains(
          'supportsNativeEdgeSignals: nativeCamera.supportsNativeEdgeSignals',
        ),
      );
    },
  );
}
