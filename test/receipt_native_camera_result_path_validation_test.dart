import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('native service rejects duplicate receipt photo paths', () async {
    const channel = MethodChannel(
      'maintainiac/receipt_camera_duplicate_paths_test',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'captureReceipt');
          return {
            'originalPhotoPaths': [
              '/tmp/duplicate-section.jpg',
              ' /tmp/duplicate-section.jpg ',
            ],
            'temporaryCaptureIds': ['duplicate-a', 'duplicate-b'],
            'capturedAt': '2026-07-03T10:45:00.000Z',
            'captureDiagnostics': const {},
          };
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await expectLater(
      const ReceiptNativeCameraService(
        methodChannel: channel,
      ).captureReceipt(_highCapacityConfig()),
      throwsA(
        isA<ReceiptNativeCameraUnavailableException>().having(
          (error) => error.message,
          'message',
          contains('duplicate receipt photo paths'),
        ),
      ),
    );
  });

  test('native service rejects non-local receipt photo paths', () async {
    const channel = MethodChannel(
      'maintainiac/receipt_camera_non_local_path_test',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'captureReceipt');
          return {
            'originalPhotoPaths': [
              'https://example.invalid/receipt.jpg',
              'relative-receipt.jpg',
            ],
            'temporaryCaptureIds': ['remote-a', 'relative-b'],
            'capturedAt': '2026-07-03T10:46:00.000Z',
            'captureDiagnostics': {
              'captureSurface': 'maintainiac_native_android',
            },
          };
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await expectLater(
      const ReceiptNativeCameraService(
        methodChannel: channel,
      ).captureReceipt(_highCapacityConfig()),
      throwsA(
        isA<ReceiptNativeCameraUnavailableException>().having(
          (error) => error.message,
          'message',
          contains('non-local or non-image receipt photo paths'),
        ),
      ),
    );
  });

  test('native service rejects non-image receipt photo paths', () async {
    const channel = MethodChannel('maintainiac/receipt_wrong_file_type_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'captureReceipt');
          return {
            'originalPhotoPaths': ['/tmp/receipt-capture.txt'],
            'temporaryCaptureIds': ['receipt-capture'],
            'capturedAt': '2026-07-03T10:47:00.000Z',
            'captureDiagnostics': {
              'captureSurface': 'maintainiac_native_android',
            },
          };
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await expectLater(
      const ReceiptNativeCameraService(
        methodChannel: channel,
      ).captureReceipt(_highCapacityConfig()),
      throwsA(
        isA<ReceiptNativeCameraUnavailableException>().having(
          (error) => error.message,
          'message',
          contains('non-local or non-image receipt photo paths'),
        ),
      ),
    );
  });

  test('native service rejects NUL-containing receipt photo paths', () async {
    const channel = MethodChannel('maintainiac/receipt_nul_path_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'captureReceipt');
          return {
            'originalPhotoPaths': ['/tmp/receipt\u0000capture.jpg'],
            'temporaryCaptureIds': ['receipt-nul'],
            'capturedAt': '2026-07-03T10:48:00.000Z',
            'captureDiagnostics': {
              'captureSurface': 'maintainiac_native_android',
            },
          };
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await expectLater(
      const ReceiptNativeCameraService(
        methodChannel: channel,
      ).captureReceipt(_highCapacityConfig()),
      throwsA(
        isA<ReceiptNativeCameraUnavailableException>().having(
          (error) => error.message,
          'message',
          contains('non-local or non-image receipt photo paths'),
        ),
      ),
    );
  });

  test('native service rejects more paths than session allows', () async {
    const channel = MethodChannel('maintainiac/receipt_too_many_paths_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'captureReceipt');
          return {
            'originalPhotoPaths': [
              '/tmp/receipt-top.jpg',
              '/tmp/receipt-bottom.jpg',
            ],
            'temporaryCaptureIds': ['receipt-top', 'receipt-bottom'],
            'capturedAt': '2026-07-03T10:49:00.000Z',
            'captureDiagnostics': {
              'captureSurface': 'maintainiac_native_android',
            },
          };
        });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await expectLater(
      const ReceiptNativeCameraService(
        methodChannel: channel,
      ).captureReceipt(_highCapacityConfig(longReceiptMode: false)),
      throwsA(
        isA<ReceiptNativeCameraUnavailableException>().having(
          (error) => error.message,
          'message',
          contains('too many receipt sections'),
        ),
      ),
    );
  });
}

ReceiptNativeCameraSessionConfig _highCapacityConfig({
  bool longReceiptMode = true,
}) {
  const capabilities = ReceiptNativeCameraCapabilities(
    engine: ReceiptNativeCameraEngine.cameraX,
    available: true,
    cameraPermissionGranted: true,
    hasRearCamera: true,
  );
  return ReceiptNativeCameraSettings(
    longReceiptMode: longReceiptMode,
  ).sessionFor(
    deviceCapability: const ReceiptDeviceCapability.highCapacity(),
    nativeCapabilities: capabilities,
  );
}
