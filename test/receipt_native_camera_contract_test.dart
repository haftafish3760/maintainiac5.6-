import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'native receipt camera defaults protect user control and OCR source',
    () {
      const settings = ReceiptNativeCameraSettings();

      expect(settings.assistedReceiptFill, isFalse);
      expect(settings.reviewDepth, ReceiptNativeReviewDepth.pricesOnly);
      expect(settings.manualShutterAlwaysAvailable, isTrue);
      expect(settings.autoCaptureEnabled, isFalse);
      expect(settings.tapFocusEnabled, isFalse);
      expect(settings.focusMode, ReceiptNativeFocusMode.continuous);
      expect(settings.usesContinuousFocusPrimary, isTrue);
      expect(settings.tapFocusIsAssistOnly, isFalse);
      expect(
        settings.nativeCameraBaselinePolicy,
        'camerax_avfoundation_native_baseline_receipt_workflow_overlay',
      );
      expect(
        settings.proCameraReplacementPolicy,
        'no_iso_raw_white_balance_lock_exposure_lock_or_tap_focus',
      );
      expect(
        settings.receiptWorkflowControlPriorityPolicy,
        'manual_shutter_torch_neutral_receipt_workflow_guidance_first',
      );
      expect(
        settings.torchControlPolicy,
        'show_receipt_light_when_device_supports_torch',
      );
      expect(
        settings.manualFocusAdjustmentPolicy,
        'optional_future_device_supported_control_not_release_blocker',
      );
      expect(settings.avoidsProCameraReplacementControls, isTrue);
      expect(settings.hasExposureControls, isTrue);
      expect(settings.hasConservativeLiveReceiptGuidance, isTrue);
      expect(
        settings.receiptFocusStrategyCode,
        'continuous_focus_primary_no_tap_assist',
      );
      expect(settings.meetsReceiptCameraQualityBaseline, isTrue);
      expect(settings.pinchZoomEnabled, isTrue);
      expect(settings.autoExposureAssistEnabled, isTrue);
      expect(settings.edgeDetectionEnabled, isTrue);
      expect(settings.motionBlurWarningEnabled, isTrue);
      expect(settings.glareWarningEnabled, isTrue);
      expect(settings.dirtyLensWarningEnabled, isTrue);
      expect(settings.lowLightWarningEnabled, isTrue);
      expect(settings.shadowWarningEnabled, isTrue);
      expect(settings.hasLiveReceiptQualityWarnings, isTrue);
      expect(settings.previousSectionGhostGuideEnabled, isTrue);
      expect(settings.saveOriginalTemporarily, isTrue);
      expect(settings.queueAcceptedCaptureLocally, isTrue);
      expect(settings.protectsInterruptedCapture, isTrue);
      expect(settings.ocrUsesTemporaryFullQualitySourceFirst, isTrue);
      expect(settings.dataSaverLevel, ReceiptDataSaverLevel.balanced);
    },
  );

  test('native capture result freezes returned paths and diagnostics', () {
    final originalPhotoPaths = ['/tmp/receipt-a.jpg'];
    final temporaryCaptureIds = ['capture-a'];
    final nestedDiagnostics = <String, Object?>{
      'stage': 'captured',
      'codes': ['edge_ready'],
    };
    final captureDiagnostics = <String, Object?>{'nested': nestedDiagnostics};

    final result = ReceiptNativeCaptureResult(
      engine: ReceiptNativeCameraEngine.cameraX,
      originalPhotoPaths: originalPhotoPaths,
      temporaryCaptureIds: temporaryCaptureIds,
      capturedAt: DateTime.utc(2026, 7, 6),
      captureDiagnostics: captureDiagnostics,
    );

    originalPhotoPaths.add('/tmp/late.jpg');
    temporaryCaptureIds.add('late-id');
    nestedDiagnostics['stage'] = 'mutated';
    (nestedDiagnostics['codes'] as List<String>).add('late-code');

    expect(result.originalPhotoPaths, ['/tmp/receipt-a.jpg']);
    expect(result.temporaryCaptureIds, ['capture-a']);
    final nested = result.captureDiagnostics['nested'] as Map<String, Object?>;
    expect(nested['stage'], 'captured');
    expect(nested['codes'], ['edge_ready']);
    expect(
      () => result.originalPhotoPaths.add('/tmp/nope.jpg'),
      throwsA(isA<UnsupportedError>()),
    );
    expect(() => nested['stage'] = 'nope', throwsA(isA<UnsupportedError>()));
  });

  test('settings descriptors cover the receipt camera control package', () {
    final descriptors = ReceiptNativeCameraSettings.descriptors;
    final ids = descriptors.map((descriptor) => descriptor.id).toSet();

    expect(ids, contains('assisted_receipt_fill'));
    expect(ids, contains('review_depth'));
    expect(ids, contains('auto_capture'));
    expect(ids, isNot(contains('tap_focus')));
    expect(ids, contains('pinch_zoom'));
    expect(ids, contains('exposure_slider'));
    expect(ids, contains('exposure_reset'));
    expect(ids, contains('auto_exposure_assist'));
    expect(ids, isNot(contains('focus_lock')));
    expect(ids, isNot(contains('exposure_lock')));
    expect(ids, isNot(contains('white_balance_lock')));
    expect(ids, contains('receipt_light'));
    expect(ids, contains('edge_detection'));
    expect(ids, isNot(contains('readability_warnings')));
    expect(ids, isNot(contains('dirty_lens_warning')));
    expect(ids, contains('long_receipt_mode'));
    expect(ids, contains('image_cleanup'));
    expect(ids, contains('safe_capture_queue'));
    expect(ids, isNot(contains('save_space_preview')));

    final assistedReceiptFill = descriptors.singleWhere(
      (descriptor) => descriptor.id == 'assisted_receipt_fill',
    );
    expect(assistedReceiptFill.defaultEnabled, isFalse);
    expect(assistedReceiptFill.description, contains('Optional'));
    expect(assistedReceiptFill.description, contains('turn Receipt Assist on'));

    final autoCapture = descriptors.singleWhere(
      (descriptor) => descriptor.id == 'auto_capture',
    );
    expect(autoCapture.defaultEnabled, isFalse);
    expect(autoCapture.description, contains('Optional'));
    expect(autoCapture.description, contains('off by default'));
    expect(
      autoCapture.description,
      contains('several steady, well-framed receipt views'),
    );
    expect(
      autoCapture.description,
      contains('shutter button still works anytime'),
    );
    final edgeDetection = descriptors.singleWhere(
      (descriptor) => descriptor.id == 'edge_detection',
    );
    expect(edgeDetection.defaultEnabled, isTrue);
    expect(edgeDetection.label, contains('edges'));
    expect(edgeDetection.description, contains('crop'));
    expect(
      edgeDetection.description,
      contains('crop guidance and safe straightening checks'),
    );

    final longReceipt = descriptors.singleWhere(
      (descriptor) => descriptor.id == 'long_receipt_mode',
    );
    expect(longReceipt.defaultEnabled, isTrue);
    expect(longReceipt.description, contains('sections'));
    expect(longReceipt.description, contains('overlap guidance'));
    expect(longReceipt.description, contains('section order review'));

    final cleanup = descriptors.singleWhere(
      (descriptor) => descriptor.id == 'image_cleanup',
    );
    expect(cleanup.defaultEnabled, isTrue);
    expect(cleanup.description, contains('cleaner receipt photo'));
    expect(cleanup.description, contains('crop'));
    expect(cleanup.description, contains('straighten'));
    expect(cleanup.description, contains('contrast'));
    expect(cleanup.description, contains('grayscale'));
    expect(cleanup.description, contains('shadow cleanup'));

    final safeQueue = descriptors.singleWhere(
      (descriptor) => descriptor.id == 'safe_capture_queue',
    );
    expect(safeQueue.description, contains('call, crash, or app switch'));
    expect(
      descriptors.where(
        (descriptor) => descriptor.group == ReceiptNativeSettingGroup.storage,
      ),
      hasLength(1),
    );
  });

  test('session config keeps OCR source and edge guidance protected', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_session_config.dart',
    ).readAsStringSync();
    const settings = ReceiptNativeCameraSettings();
    const native = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      cameraCount: 2,
      hasRearCamera: true,
      supportsContinuousFocus: true,
      supportsTorch: true,
      supportsYuvLiveFrames: true,
      supportsNativeEdgeSignals: true,
    );

    final config = settings.sessionFor(
      deviceCapability: const ReceiptDeviceCapability.standard(),
      nativeCapabilities: native,
    );

    expect(config.ocrSourceProtected, isTrue);
    expect(
      config.nativeCameraBaselinePolicy,
      'camerax_avfoundation_native_baseline_receipt_workflow_overlay',
    );
    expect(
      config.proCameraReplacementPolicy,
      'no_iso_raw_white_balance_lock_exposure_lock_or_tap_focus',
    );
    expect(
      config.receiptWorkflowControlPriorityPolicy,
      'manual_shutter_torch_neutral_receipt_workflow_guidance_first',
    );
    expect(
      config.torchControlPolicy,
      'show_receipt_light_when_device_supports_torch',
    );
    expect(
      config.manualFocusAdjustmentPolicy,
      'optional_future_device_supported_control_not_release_blocker',
    );
    expect(
      config.nativeControlContractTags,
      contains('native_camera_baseline'),
    );
    expect(config.nativeControlContractTags, contains('receipt_light'));
    expect(
      config.nativeControlContractTags,
      contains('manual_focus_optional_future'),
    );
    expect(source, contains('settings.ocrUsesTemporaryFullQualitySourceFirst'));
    expect(
      source,
      isNot(
        contains(
          'bool get ocrSourceProtected => settings.ocrUsesOriginalFirst',
        ),
      ),
    );
    expect(
      config.nativeCaptureMemoryPolicy,
      contains('temporary_source_for_ocr'),
    );
    expect(config.edgeDetectionEnabled, isTrue);
    expect(config.edgeOverlayEnabled, isTrue);
    expect(config.perspectiveCorrectionEnabled, isTrue);
    expect(config.autoCropSuggestionEnabled, isTrue);
    expect(config.orientationCorrectionEnabled, isTrue);
    expect(
      config.focusStrategyPolicy,
      'continuous_focus_primary_no_tap_assist',
    );
    expect(
      config.focusReadabilityFallbackPolicy,
      'not_needed_native_camera_continuous_focus_primary',
    );
    expect(config.continuousFocusEnabled, isTrue);
    expect(config.tapToFocusPolicy, 'continuous_focus_primary_no_tap_focus');
    expect(
      config.readabilityGuidancePolicy,
      'native_camera_receipt_quality_guidance_v1',
    );
  });

  test(
    'native camera retires tap focus even when legacy settings request it',
    () {
      const settings = ReceiptNativeCameraSettings(tapFocusEnabled: true);
      const native = ReceiptNativeCameraCapabilities(
        engine: ReceiptNativeCameraEngine.cameraX,
        available: true,
        cameraPermissionGranted: true,
        cameraCount: 2,
        hasRearCamera: true,
        supportsTapFocus: true,
        supportsContinuousFocus: true,
        supportsYuvLiveFrames: true,
        supportsNativeEdgeSignals: true,
      );

      final config = settings.sessionFor(
        deviceCapability: const ReceiptDeviceCapability.standard(),
        nativeCapabilities: native,
      );

      expect(settings.tapFocusIsAssistOnly, isFalse);
      expect(config.tapFocusEnabled, isFalse);
      expect(config.tapToFocusPolicy, 'continuous_focus_primary_no_tap_focus');
      expect(config.nativeControlContractTags, isNot(contains('focus_assist')));
      expect(
        config.capabilityPolicyCodes,
        isNot(contains('tap_focus_retired_continuous_focus_primary')),
      );
      expect(config.continuousFocusEnabled, isTrue);
      expect(
        config.focusStrategyPolicy,
        'continuous_focus_primary_no_tap_assist',
      );
      expect(
        config.focusReadabilityFallbackPolicy,
        'not_needed_native_camera_continuous_focus_primary',
      );
    },
  );

  test('native camera capability restore trims engine names', () {
    final capabilities = ReceiptNativeCameraCapabilities.fromMap(const {
      'engine': ' cameraX ',
      'available': true,
      'cameraPermissionGranted': true,
      'hasRearCamera': true,
    });

    expect(capabilities.engine, ReceiptNativeCameraEngine.cameraX);
    expect(capabilities.canOpenReceiptCamera, isTrue);
  });

  test(
    'native coverage diagnostic vocabulary is shared by bridge and review',
    () {
      expect(
        ReceiptCaptureDiagnosticKeys.latestFramingSignal,
        'latestFramingSignal',
      );
      expect(
        ReceiptCaptureDiagnosticKeys.latestPerspectiveReadiness,
        'latestPerspectiveReadiness',
      );
      expect(
        ReceiptCaptureDiagnosticKeys.latestEdgeCoverage,
        'latestEdgeCoverage',
      );
      expect(
        ReceiptCaptureDiagnosticKeys.photoCoverageStatus,
        'photoCoverageStatus',
      );
      expect(
        ReceiptCaptureDiagnosticKeys.photoCoverageNeedsMorePhotos,
        'photoCoverageNeedsMorePhotos',
      );
      expect(
        ReceiptNativeCoverageSignalValues.framingSignals,
        containsAll([
          ReceiptNativeCoverageSignalValues.framingOk,
          ReceiptNativeCoverageSignalValues.possiblyCutOff,
          ReceiptNativeCoverageSignalValues.moveCloser,
          ReceiptNativeCoverageSignalValues.receiptNotFound,
        ]),
      );
      expect(
        ReceiptNativeCoverageSignalValues.perspectiveReadiness,
        contains(
          ReceiptNativeCoverageSignalValues.perspectiveSkippedCutOffRisk,
        ),
      );

      final decision = ReceiptPhotoCoverageDecision.fromSignals(
        quality: const ReceiptPhotoQualityCheck(
          width: 1900,
          height: 3200,
          focusScore: 16,
          isLikelyReadable: true,
          brightness: 150,
          contrast: 56,
          textBandScore: .72,
          cropScore: .78,
        ),
        diagnostics: const {
          ReceiptCaptureDiagnosticKeys.latestFramingSignal:
              ReceiptNativeCoverageSignalValues.possiblyCutOff,
          ReceiptCaptureDiagnosticKeys.latestPerspectiveReadiness:
              ReceiptNativeCoverageSignalValues.perspectiveSkippedCutOffRisk,
          ReceiptCaptureDiagnosticKeys.latestEdgeCoverage: .84,
        },
      );

      expect(decision.status, ReceiptPhotoCoverageStatus.likelyComplete);
      expect(decision.reasonCode, 'native_cut_off_readable_check');
      expect(decision.shouldPromptForMorePhotos, isFalse);
    },
  );
}
