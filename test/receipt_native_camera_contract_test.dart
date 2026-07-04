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

      expect(settings.assistedReceiptFill, isTrue);
      expect(settings.reviewDepth, ReceiptNativeReviewDepth.pricesOnly);
      expect(settings.manualShutterAlwaysAvailable, isTrue);
      expect(settings.autoCaptureEnabled, isFalse);
      expect(settings.tapFocusEnabled, isFalse);
      expect(settings.focusMode, ReceiptNativeFocusMode.continuous);
      expect(settings.usesContinuousFocusPrimary, isTrue);
      expect(settings.tapFocusIsAssistOnly, isFalse);
      expect(settings.hasExposureAndSharpnessGuidance, isTrue);
      expect(settings.hasReceiptReadabilityGuidance, isTrue);
      expect(
        settings.receiptFocusStrategyCode,
        'continuous_focus_primary_no_tap_assist',
      );
      expect(settings.meetsReceiptCameraQualityBaseline, isTrue);
      expect(settings.pinchZoomEnabled, isTrue);
      expect(settings.autoExposureAssistEnabled, isTrue);
      expect(settings.edgeDetectionEnabled, isTrue);
      expect(settings.dirtyLensWarningEnabled, isTrue);
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
    expect(ids, isNot(contains('tap_focus')));
    expect(ids, contains('pinch_zoom'));
    expect(ids, contains('exposure_slider'));
    expect(ids, contains('exposure_reset'));
    expect(ids, contains('auto_exposure_assist'));
    expect(ids, contains('focus_lock'));
    expect(ids, contains('exposure_lock'));
    expect(ids, contains('white_balance_lock'));
    expect(ids, contains('receipt_light'));
    expect(ids, contains('edge_detection'));
    expect(ids, contains('readability_warnings'));
    expect(ids, contains('dirty_lens_warning'));
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
    final dirtyLens = descriptors.singleWhere(
      (descriptor) => descriptor.id == 'dirty_lens_warning',
    );
    expect(dirtyLens.defaultEnabled, isTrue);
    expect(dirtyLens.advanced, isTrue);
    expect(dirtyLens.description, contains('hazy'));

    final edgeDetection = descriptors.singleWhere(
      (descriptor) => descriptor.id == 'edge_detection',
    );
    expect(edgeDetection.defaultEnabled, isTrue);
    expect(edgeDetection.label, contains('edges'));
    expect(edgeDetection.description, contains('crop'));
    expect(edgeDetection.description, contains('perspective correction'));

    final readabilityWarnings = descriptors.singleWhere(
      (descriptor) => descriptor.id == 'readability_warnings',
    );
    expect(readabilityWarnings.defaultEnabled, isTrue);
    expect(readabilityWarnings.description, contains('blur'));
    expect(readabilityWarnings.description, contains('glare'));
    expect(readabilityWarnings.description, contains('low light'));
    expect(readabilityWarnings.description, contains('shadows'));
    expect(readabilityWarnings.description, contains('tiny text'));
    expect(
      readabilityWarnings.description,
      contains('missing receipt sections'),
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
    expect(cleanup.description, contains('OCR source'));
    expect(cleanup.description, contains('crop'));
    expect(cleanup.description, contains('straighten'));
    expect(cleanup.description, contains('contrast'));
    expect(cleanup.description, contains('grayscale'));
    expect(cleanup.description, contains('shadow cleanup'));

    final safeQueue = descriptors.singleWhere(
      (descriptor) => descriptor.id == 'safe_capture_queue',
    );
    expect(safeQueue.description, contains('call, crash, or app switch'));
  });

  test('session config keeps OCR source and edge guidance protected', () {
    const settings = ReceiptNativeCameraSettings();
    const native = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      cameraCount: 2,
      hasRearCamera: true,
      supportsContinuousFocus: true,
      supportsYuvLiveFrames: true,
      supportsNativeEdgeSignals: true,
    );

    final config = settings.sessionFor(
      deviceCapability: const ReceiptDeviceCapability.standard(),
      nativeCapabilities: native,
    );

    expect(config.ocrSourceProtected, isTrue);
    expect(config.nativeCaptureMemoryPolicy, contains('original_for_ocr'));
    expect(config.edgeDetectionEnabled, isTrue);
    expect(config.edgeOverlayEnabled, isTrue);
    expect(config.perspectiveCorrectionEnabled, isTrue);
    expect(config.autoCropSuggestionEnabled, isTrue);
    expect(config.orientationCorrectionEnabled, isTrue);
    expect(
      config.focusStrategyPolicy,
      'continuous_focus_primary_no_tap_assist',
    );
    expect(config.continuousFocusEnabled, isTrue);
    expect(config.tapToFocusPolicy, 'continuous_focus_primary_no_tap_focus');
    expect(
      config.readabilityGuidancePolicy,
      'live_readability_guides_blur_glare_light_edges_and_text_size',
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
        contains('tap_focus_retired_continuous_focus_primary'),
      );
      expect(config.continuousFocusEnabled, isTrue);
      expect(
        config.focusStrategyPolicy,
        'continuous_focus_primary_no_tap_assist',
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
