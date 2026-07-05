import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_service.dart';

import 'helpers/receipt_native_camera_previous_section_channel_expectations.dart';
import 'helpers/receipt_native_camera_previous_section_diagnostics_expectations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      supportsTapFocus: true,
      supportsContinuousFocus: true,
      supportsFocusLock: true,
      supportsExposureCompensation: true,
      supportsExposureLock: true,
      supportsWhiteBalanceLock: true,
      supportsTorch: true,
      supportsZoom: true,
      minZoom: 1.0,
      maxZoom: 6.0,
      minExposureOffset: -1.5,
      maxExposureOffset: 1.5,
    );
    final config = const ReceiptNativeCameraSettings().sessionFor(
      deviceCapability: const ReceiptDeviceCapability.standard(),
      nativeCapabilities: capabilities,
      previousSectionGuidePhotoPath: '/tmp/section-one.jpg',
      previousSectionReasonCode: 'missing_bottom_edge_and_totals',
      previousSectionGuidance: 'Add Bottom Section',
    );

    final result = await ReceiptNativeCameraService(
      methodChannel: channel,
    ).captureReceipt(config);

    expectPreviousSectionGuideChannelArguments(sentArguments, result);
    expectPreviousSectionGuideCaptureDiagnostics(result, sentArguments);
  });

  test('native service sends next-section context for top retake', () async {
    const channel = MethodChannel('maintainiac/receipt_camera_next_context');
    late Map<dynamic, dynamic> sentArguments;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'captureReceipt');
          sentArguments = call.arguments as Map<dynamic, dynamic>;
          return {
            'originalPhotoPaths': ['/tmp/top-retake.jpg'],
            'temporaryCaptureIds': ['native-top-retake'],
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
      supportsContinuousFocus: true,
      supportsExposureCompensation: true,
      supportsTorch: true,
    );
    final config = const ReceiptNativeCameraSettings().sessionFor(
      deviceCapability: const ReceiptDeviceCapability.standard(),
      nativeCapabilities: capabilities,
      previousSectionGuidePhotoPath: '/tmp/section-two.jpg',
      previousSectionReasonCode: 'retake_top_with_next_context',
    );

    final result = await ReceiptNativeCameraService(
      methodChannel: channel,
    ).captureReceipt(config);

    expect(result.originalPhotoPaths, ['/tmp/top-retake.jpg']);
    expect(
      sentArguments['previousSectionReasonCode'],
      'retake_top_with_next_context',
    );
    expect(
      sentArguments['previousSectionGhostGuidePolicy'],
      'next_section_top_context_ghost_at_top_repeat_3_to_5_lines',
    );
    expect(sentArguments['previousSectionGhostGuideUsesNextContext'], isTrue);
    expect(
      sentArguments['previousSectionGhostGuideMatchTarget'],
      'next_section_top_lines',
    );
    expect(sentArguments['previousSectionGhostSourceStartFraction'], 0);
    expect(
      sentArguments['previousSectionGuidance'],
      contains('next receipt section'),
    );
  });
}
