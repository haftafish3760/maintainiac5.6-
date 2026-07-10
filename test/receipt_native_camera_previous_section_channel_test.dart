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

  test(
    'native service sends both neighboring guides for middle retake',
    () async {
      const channel = MethodChannel(
        'maintainiac/receipt_camera_two_sided_context',
      );
      late Map<dynamic, dynamic> sentArguments;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'captureReceipt');
            sentArguments = call.arguments as Map<dynamic, dynamic>;
            return {
              'originalPhotoPaths': ['/tmp/middle-retake.jpg'],
              'temporaryCaptureIds': ['native-middle-retake'],
              'capturedAt': '2026-06-28T12:00:00.000Z',
              'captureDiagnostics': {
                'hasPreviousSectionGuide': true,
                'hasNextSectionGuide': true,
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
        supportsContinuousFocus: true,
        supportsExposureCompensation: true,
        supportsTorch: true,
      );
      final config = const ReceiptNativeCameraSettings().sessionFor(
        deviceCapability: const ReceiptDeviceCapability.standard(),
        nativeCapabilities: capabilities,
        previousSectionGuidePhotoPath: '/tmp/section-one.jpg',
        nextSectionGuidePhotoPath: '/tmp/section-three.jpg',
        previousSectionReasonCode: 'retake_middle_with_previous_next_context',
        previousSectionGuidance:
            'Use both neighboring sections as alignment context.',
      );

      final result = await ReceiptNativeCameraService(
        methodChannel: channel,
      ).captureReceipt(config);

      expect(result.originalPhotoPaths, ['/tmp/middle-retake.jpg']);
      expect(
        sentArguments['previousSectionGuidePhotoPath'],
        '/tmp/section-one.jpg',
      );
      expect(
        sentArguments['nextSectionGuidePhotoPath'],
        '/tmp/section-three.jpg',
      );
      expect(
        sentArguments['nativeControlContractTags'],
        contains('two_sided_section_ghost'),
      );
      expect(
        sentArguments['nextSectionGhostGuidePolicy'],
        'next_section_top_context_ghost_at_bottom_repeat_3_to_5_lines',
      );
      expect(
        sentArguments['nextSectionGhostGuidePlacement'],
        'bottom_ghost_slice',
      );
      expect(sentArguments['nextSectionGhostSourceStartFraction'], 0);
      expect(sentArguments['nextSectionGhostOverlayTopFraction'], .80);
    },
  );

  test('native session suppresses second guide outside middle retakes', () {
    const capabilities = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      hasRearCamera: true,
      supportsContinuousFocus: true,
    );
    final bottomRetake = const ReceiptNativeCameraSettings().sessionFor(
      deviceCapability: const ReceiptDeviceCapability.standard(),
      nativeCapabilities: capabilities,
      previousSectionGuidePhotoPath: '/tmp/section-two.jpg',
      nextSectionGuidePhotoPath: '/tmp/section-four.jpg',
      previousSectionReasonCode: 'retake_bottom_with_previous_context',
    );
    final continuation = const ReceiptNativeCameraSettings().sessionFor(
      deviceCapability: const ReceiptDeviceCapability.standard(),
      nativeCapabilities: capabilities,
      previousSectionGuidePhotoPath: '/tmp/section-two.jpg',
      nextSectionGuidePhotoPath: '/tmp/section-four.jpg',
      previousSectionReasonCode: 'manual_add_photo_continuation',
    );

    expect(bottomRetake.hasNextSectionGuide, isFalse);
    expect(continuation.hasNextSectionGuide, isFalse);
    expect(
      bottomRetake.nativeControlContractTags,
      isNot(contains('two_sided_section_ghost')),
    );
    expect(
      continuation.nativeControlContractTags,
      isNot(contains('next_section_ghost')),
    );
  });
}
