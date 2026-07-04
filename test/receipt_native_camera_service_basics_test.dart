import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'native service sends one-section limit when long receipt mode is off',
    () async {
      const channel = MethodChannel(
        'maintainiac/receipt_camera_single_section',
      );
      late Map<dynamic, dynamic> sentArguments;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'captureReceipt');
            sentArguments = call.arguments as Map<dynamic, dynamic>;
            return {
              'originalPhotoPaths': ['/tmp/single-receipt.jpg'],
              'temporaryCaptureIds': ['single-section'],
              'capturedAt': '2026-06-29T12:10:00.000Z',
              'captureDiagnostics': {'maxSectionCount': 1},
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
            longReceiptMode: false,
            dirtyLensWarningEnabled: false,
          ).sessionFor(
            deviceCapability: const ReceiptDeviceCapability.highCapacity(),
            nativeCapabilities: capabilities,
            previousSectionGuidePhotoPath: '/tmp/ignored-guide.jpg',
          );

      await ReceiptNativeCameraService(
        methodChannel: channel,
      ).captureReceipt(config);

      expect(sentArguments['longReceiptMode'], isFalse);
      expect(sentArguments['dirtyLensWarningEnabled'], isFalse);
      expect(sentArguments['maxSectionCount'], 1);
      expect(
        sentArguments['focusReadabilityFallbackPolicy'],
        'continuous_focus_unavailable_live_readability_review_required',
      );
      expect(sentArguments, isNot(contains('previousSectionGuidePhotoPath')));
      expect(
        sentArguments['capabilityPolicyCodes'],
        contains('long_receipt_mode_disabled'),
      );
    },
  );

  test('native service contract keeps retired tap focus unexpected', () {
    final serviceContractSource = File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_service_contract_helpers.dart',
    ).readAsStringSync();

    expect(serviceContractSource, contains("'tapFocusEnabled': false"));
    expect(serviceContractSource, contains("'tapFocusControlExpected': false"));
    expect(
      serviceContractSource,
      isNot(contains("'tapFocusEnabled': config.tapFocusEnabled")),
    );
    expect(
      serviceContractSource,
      isNot(contains("'tapFocusControlExpected': config.tapFocusEnabled")),
    );
  });

  test('native service contract keeps retired lock controls disabled', () {
    final serviceContractSource = File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_service_contract_helpers.dart',
    ).readAsStringSync();

    for (final key in [
      'focusLockEnabled',
      'exposureLockEnabled',
      'whiteBalanceLockEnabled',
      'focusLockControlExpected',
      'exposureLockControlExpected',
      'whiteBalanceLockControlExpected',
    ]) {
      expect(serviceContractSource, contains("'$key': false"));
    }
    expect(serviceContractSource, isNot(contains(': config.focusLockEnabled')));
    expect(
      serviceContractSource,
      isNot(contains(': config.exposureLockEnabled')),
    );
    expect(
      serviceContractSource,
      isNot(contains(': config.whiteBalanceLockEnabled')),
    );
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
              'supportsContinuousFocus': true,
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
      expect(capabilities.supportsContinuousFocus, isTrue);
      expect(capabilities.supportsZoom, isTrue);
      expect(capabilities.maxZoom, 8);
      expect(capabilities.maxStillWidth, 4032);
      expect(capabilities.maxStillHeight, 3024);
    },
  );
}
