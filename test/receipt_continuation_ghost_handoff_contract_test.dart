import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_flow.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';

void main() {
  test('continuation ghost is inactive without a valid guide photo', () {
    final guide = ReceiptCaptureContinuationGuide.fromPreviousPhotos(
      previousPhotoPaths: const [
        'relative-receipt.jpg',
        'https://example.test/receipt.jpg',
        '/tmp/receipt-note.txt',
      ],
      reasonCode: 'missing_bottom_edge_and_totals',
      guidance: 'Repeat the last lines.',
    );
    final options = guide.applyTo(
      const ReceiptCaptureFlowOptions(
        module: ReceiptCaptureFlowModule.expenses,
        forceLongReceiptMode: true,
      ),
    );
    final session =
        ReceiptNativeCameraSettings(
          longReceiptMode: options.forceLongReceiptMode ?? false,
        ).sessionFor(
          deviceCapability: const ReceiptDeviceCapability.highCapacity(),
          nativeCapabilities: _nativeCapabilities,
          previousSectionGuidePhotoPath: options.previousSectionGuidePhotoPath,
          previousSectionReasonCode: options.previousSectionReasonCode,
          previousSectionGuidance: options.previousSectionGuidance,
          previousSectionGhostSourceStartFraction:
              options.previousSectionGhostSourceStartFraction,
          previousSectionGhostSourceHeightFraction:
              options.previousSectionGhostSourceHeightFraction,
          previousSectionGhostOverlayTopFraction:
              options.previousSectionGhostOverlayTopFraction,
          previousSectionGhostOverlayHeightFraction:
              options.previousSectionGhostOverlayHeightFraction,
          previousSectionGhostOpacity: options.previousSectionGhostOpacity,
        );

    expect(guide.hasReason, isTrue);
    expect(guide.hasGuidePhoto, isFalse);
    expect(options.previousSectionReasonCode, 'missing_bottom_edge_and_totals');
    expect(options.previousSectionGuidePhotoPath, isNull);
    expect(session.hasPreviousSectionGuide, isFalse);
    expect(session.previousSectionGhostGuidePolicy, 'not_requested');
    expect(session.previousSectionGuideGuidance, isEmpty);
    expect(
      session.nativeControlContractTags,
      isNot(contains('previous_section_ghost')),
    );
  });

  test('continuation ghost activates from last valid local image path', () {
    final guide = ReceiptCaptureContinuationGuide.fromPreviousPhotos(
      previousPhotoPaths: const [
        '/tmp/section-1.jpg',
        'relative-section.jpg',
        ' /tmp/section-2.PNG ',
      ],
      reasonCode: 'manual_add_photo_continuation',
      guidance: 'Repeat the last readable lines.',
    );
    final options = guide.applyTo(
      const ReceiptCaptureFlowOptions(
        module: ReceiptCaptureFlowModule.expenses,
        forceLongReceiptMode: true,
      ),
    );
    final session = const ReceiptNativeCameraSettings(longReceiptMode: true)
        .sessionFor(
          deviceCapability: const ReceiptDeviceCapability.highCapacity(),
          nativeCapabilities: _nativeCapabilities,
          previousSectionGuidePhotoPath: options.previousSectionGuidePhotoPath,
          previousSectionReasonCode: options.previousSectionReasonCode,
          previousSectionGuidance: options.previousSectionGuidance,
          previousSectionGhostSourceStartFraction:
              options.previousSectionGhostSourceStartFraction,
          previousSectionGhostSourceHeightFraction:
              options.previousSectionGhostSourceHeightFraction,
          previousSectionGhostOverlayTopFraction:
              options.previousSectionGhostOverlayTopFraction,
          previousSectionGhostOverlayHeightFraction:
              options.previousSectionGhostOverlayHeightFraction,
          previousSectionGhostOpacity: options.previousSectionGhostOpacity,
        );

    expect(guide.guidePhotoPath, '/tmp/section-2.PNG');
    expect(session.hasPreviousSectionGuide, isTrue);
    expect(session.previousSectionGhostGuidePlacement, 'top_ghost_slice');
    expect(session.previousSectionGhostSourceStartFractionOrDefault, .80);
    expect(session.previousSectionGhostSourceHeightFractionOrDefault, .20);
    expect(session.previousSectionGhostOverlayTopFractionOrDefault, 0);
    expect(session.previousSectionGhostOverlayHeightFractionOrDefault, .20);
    expect(session.previousSectionGhostSlicePercent, 20);
    expect(
      session.nativeControlContractTags,
      contains('previous_section_ghost'),
    );
  });

  test(
    'continuation ghost clamps unsafe slice fractions for native handoff',
    () {
      final options = const ReceiptCaptureFlowOptions(
        module: ReceiptCaptureFlowModule.expenses,
        forceLongReceiptMode: true,
        previousSectionGuidePhotoPath: '/tmp/section-3.jpg',
        previousSectionReasonCode: 'manual_add_photo_continuation',
        previousSectionGuidance: 'Repeat the last readable lines.',
        previousSectionGhostSourceStartFraction: 1.8,
        previousSectionGhostSourceHeightFraction: -.4,
        previousSectionGhostOverlayTopFraction: -.2,
        previousSectionGhostOverlayHeightFraction: 1.4,
        previousSectionGhostOpacity: 2.1,
      );

      final session = const ReceiptNativeCameraSettings(longReceiptMode: true)
          .sessionFor(
            deviceCapability: const ReceiptDeviceCapability.highCapacity(),
            nativeCapabilities: _nativeCapabilities,
            previousSectionGuidePhotoPath:
                options.previousSectionGuidePhotoPath,
            previousSectionReasonCode: options.previousSectionReasonCode,
            previousSectionGuidance: options.previousSectionGuidance,
            previousSectionGhostSourceStartFraction:
                options.previousSectionGhostSourceStartFraction,
            previousSectionGhostSourceHeightFraction:
                options.previousSectionGhostSourceHeightFraction,
            previousSectionGhostOverlayTopFraction:
                options.previousSectionGhostOverlayTopFraction,
            previousSectionGhostOverlayHeightFraction:
                options.previousSectionGhostOverlayHeightFraction,
            previousSectionGhostOpacity: options.previousSectionGhostOpacity,
          );

      expect(session.hasPreviousSectionGuide, isTrue);
      expect(session.previousSectionGhostGuidePlacement, 'top_ghost_slice');
      expect(session.previousSectionGhostSourceStartFractionOrDefault, .92);
      expect(session.previousSectionGhostSourceHeightFractionOrDefault, .15);
      expect(session.previousSectionGhostOverlayTopFractionOrDefault, 0);
      expect(session.previousSectionGhostOverlayHeightFractionOrDefault, .20);
      expect(session.previousSectionGhostOpacityOrDefault, .62);
      expect(session.previousSectionGhostSlicePercent, 15);
      expect(
        session.nativeControlContractTags,
        contains('previous_section_ghost'),
      );
    },
  );

  test(
    'continuation ghost replaces non-finite native fractions with defaults',
    () {
      final options = ReceiptCaptureFlowOptions(
        module: ReceiptCaptureFlowModule.expenses,
        forceLongReceiptMode: true,
        previousSectionGuidePhotoPath: '/tmp/section-4.jpg',
        previousSectionReasonCode: 'missing_bottom_edge_and_totals',
        previousSectionGhostSourceStartFraction: double.nan,
        previousSectionGhostSourceHeightFraction: double.infinity,
        previousSectionGhostOverlayTopFraction: double.negativeInfinity,
        previousSectionGhostOverlayHeightFraction: double.nan,
        previousSectionGhostOpacity: double.infinity,
      );

      final session = const ReceiptNativeCameraSettings(longReceiptMode: true)
          .sessionFor(
            deviceCapability: const ReceiptDeviceCapability.highCapacity(),
            nativeCapabilities: _nativeCapabilities,
            previousSectionGuidePhotoPath:
                options.previousSectionGuidePhotoPath,
            previousSectionReasonCode: options.previousSectionReasonCode,
            previousSectionGhostSourceStartFraction:
                options.previousSectionGhostSourceStartFraction,
            previousSectionGhostSourceHeightFraction:
                options.previousSectionGhostSourceHeightFraction,
            previousSectionGhostOverlayTopFraction:
                options.previousSectionGhostOverlayTopFraction,
            previousSectionGhostOverlayHeightFraction:
                options.previousSectionGhostOverlayHeightFraction,
            previousSectionGhostOpacity: options.previousSectionGhostOpacity,
          );

      expect(session.hasPreviousSectionGuide, isTrue);
      expect(
        session.previousSectionGhostGuidePolicy,
        'bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
      );
      expect(session.previousSectionGhostSourceStartFractionOrDefault, .80);
      expect(session.previousSectionGhostSourceHeightFractionOrDefault, .20);
      expect(session.previousSectionGhostOverlayTopFractionOrDefault, 0);
      expect(session.previousSectionGhostOverlayHeightFractionOrDefault, .20);
      expect(session.previousSectionGhostOpacityOrDefault, .36);
      expect(session.previousSectionGhostSlicePercent, 20);
    },
  );

  test('continuation ghost normalizes direct native reason aliases', () {
    final session = const ReceiptNativeCameraSettings(longReceiptMode: true)
        .sessionFor(
          deviceCapability: const ReceiptDeviceCapability.highCapacity(),
          nativeCapabilities: _nativeCapabilities,
          previousSectionGuidePhotoPath: '/tmp/section-5.jpg',
          previousSectionReasonCode: ' Missing Bottom Edge And Totals ',
        );

    expect(
      session.previousSectionGuideReasonCode,
      'missing_bottom_edge_and_totals',
    );
    expect(
      session.previousSectionGhostGuidePolicy,
      'bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
    );
    expect(
      session.previousSectionGhostGuideMatchTarget,
      'subtotal_total_and_final_lines',
    );
    expect(session.previousSectionGhostOpacityOrDefault, .36);
  });
}

const _nativeCapabilities = ReceiptNativeCameraCapabilities(
  engine: ReceiptNativeCameraEngine.cameraX,
  available: true,
  cameraPermissionGranted: true,
  cameraCount: 2,
  hasRearCamera: true,
  supportsYuvLiveFrames: true,
  supportsNativeEdgeSignals: true,
);
