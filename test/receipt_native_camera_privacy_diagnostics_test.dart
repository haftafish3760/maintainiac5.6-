import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_diagnostics_sanitizer.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'native diagnostic sanitizer removes receipt content in generic values',
    () {
      final sanitized = receiptNativeCaptureSanitizedDiagnostics({
        'status': 'camera_ready',
        'genericMerchantValue': "LOWE'S HOME CENTERS, LLC",
        'genericAddressValue': '6400 BRODIE LANE',
        'genericPhoneValue': '(512) 895-5560',
        'genericTotalValue': 'TOTAL: 3.24',
        'genericSubtotalValue': 'SUBTOTAL: 2.99',
        'genericCurrencyValue': r'$3.24',
        'nested': {
          'safeBucket': 'waiting_for_receipt_target',
          'genericStore': 'Home Depot',
          'genericTax': 'TAX: 0.25',
        },
        'safeList': ['edge_ready', 'TOTAL: 3.24', 'manual_capture_ready'],
      });

      expect(sanitized, containsPair('status', 'camera_ready'));
      expect(sanitized, isNot(contains('genericMerchantValue')));
      expect(sanitized, isNot(contains('genericAddressValue')));
      expect(sanitized, isNot(contains('genericPhoneValue')));
      expect(sanitized, isNot(contains('genericTotalValue')));
      expect(sanitized, isNot(contains('genericSubtotalValue')));
      expect(sanitized, isNot(contains('genericCurrencyValue')));
      expect(sanitized['nested'], {'safeBucket': 'waiting_for_receipt_target'});
      expect(sanitized['safeList'], ['edge_ready', 'manual_capture_ready']);
      expect(sanitized.toString(), isNot(contains("LOWE'S")));
      expect(sanitized.toString(), isNot(contains('3.24')));
      expect(sanitized.toString(), isNot(contains('6400')));
    },
  );

  test('hardware profile exposes privacy-safe capability buckets', () {
    const hardware = ReceiptHardwareProfile(
      deviceManufacturer: 'Samsung',
      deviceModel: 'Galaxy Private Model',
      deviceName: 'Robbie Phone',
      freeStorageMb: 4200,
      availableRamMb: 9000,
      cpuCores: 8,
      cameraPermissionGranted: true,
      cameraCount: 4,
      hasRearCamera: true,
      hasFrontCamera: true,
      supportsTapFocus: true,
      supportsContinuousFocus: true,
      supportsExposureCompensation: true,
      supportsZoom: true,
      supportsYuvLiveFrames: true,
      supportsNativeEdgeSignals: true,
      maxStillWidth: 4032,
      maxStillHeight: 3024,
    );

    final label = hardware.privacySafeCapabilityLabel();
    final diagnostics = hardware.privacySafeCapabilityDiagnostics();

    expect(label, contains('capability'));
    expect(label, contains('storage'));
    expect(label, contains('rear camera available'));
    expect(label, contains('continuous focus'));
    expect(label, isNot(contains('tap focus')));
    expect(label, contains('pinch zoom'));
    expect(label, isNot(contains('Samsung')));
    expect(label, isNot(contains('Galaxy Private Model')));
    expect(label, isNot(contains('Robbie Phone')));
    expect(diagnostics, containsPair('cameraCount', 4));
    expect(diagnostics, containsPair('supportsContinuousFocus', true));
    expect(diagnostics, containsPair('legacyTapFocusSupported', true));
    expect(diagnostics, containsPair('supportsZoom', true));
    expect(diagnostics, containsPair('maxStillMegapixels', 12));
    expect(diagnostics.containsKey('deviceManufacturer'), isFalse);
    expect(diagnostics.containsKey('deviceModel'), isFalse);
    expect(diagnostics.containsKey('deviceName'), isFalse);
  });

  test('production receipt camera runtime stays manufacturer agnostic', () {
    final productionSources = <File>[
      ..._sourceFilesUnder('lib/shared/widgets/receipt_capture'),
      ..._sourceFilesUnder('android/app/src/main/kotlin/com/maintainiac'),
      ..._sourceFilesUnder('ios/Runner'),
    ];
    final brandTokens = RegExp(
      r'\b(Samsung|Galaxy|S24|S25|S9|Google Pixel|Motorola|OnePlus)\b',
    );
    final violations = <String>[];

    for (final file in productionSources) {
      final text = file.readAsStringSync();
      if (brandTokens.hasMatch(text)) violations.add(file.path);
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Receipt camera runtime must stay capability-based, not tied to one '
          'phone maker. Use docs or real-device scripts for named test devices.',
    );
  });

  test('native camera screens report control diagnostics without content', () async {
    final androidMainSource = File(
      'android/app/src/main/kotlin/com/maintainiac/MainActivity.kt',
    ).readAsStringSync();
    final iosDelegateSource = File(
      'ios/Runner/AppDelegate.swift',
    ).readAsStringSync();
    final androidSource = await readAndroidReceiptCameraUnit();
    final iosSource = await readIosReceiptCameraUnit();
    final dartSource = _readNativeCameraContractSource();
    final serviceSource =
        File(
          'lib/shared/widgets/receipt_capture/receipt_native_camera_service.dart',
        ).readAsStringSync() +
        File(
          'lib/shared/widgets/receipt_capture/receipt_native_camera_service_contract_helpers.dart',
        ).readAsStringSync();
    final stagingSafeKeysSource = File(
      'lib/shared/widgets/receipt_capture/receipt_native_capture_staging_safe_keys.dart',
    ).readAsStringSync();

    for (final source in [androidSource, iosSource]) {
      expect(source, contains('settingsOpenCount'));
      expect(source, contains('receipt_native_controls_v1'));
      expect(source, contains('summary_only_no_receipt_content'));
      expect(source, contains('tapFocusControlExpected'));
      expect(source, contains('tapToFocusPolicy'));
      expect(source, contains('pinchZoomControlExpected'));
      expect(source, contains('zoomGesturePolicy'));
      expect(source, contains('exposureSliderControlExpected'));
      expect(source, contains('exposureResetControlExpected'));
      expect(source, contains('previewExposurePolicy'));
      expect(source, contains('preCaptureExposurePolicy'));
      expect(source, contains('previewBrightnessGuardPolicy'));
      expect(source, contains('shutterSpeedPolicy'));
      expect(source, contains('autoCapturePolicy'));
      expect(source, contains('manualShutterTapCount'));
      expect(source, contains('manualCaptureStartedCount'));
      expect(source, contains('autoCaptureAttemptCount'));
      expect(source, contains('autoCaptureStartedCount'));
      expect(source, contains('captureBlockedNoCameraCount'));
      expect(source, contains('captureBlockedBusyCount'));
      expect(source, contains('captureBlockedClosingCount'));
      expect(source, contains('captureBlockedSurfaceInactiveCount'));
      expect(source, contains('lastCaptureTrigger'));
      expect(source, contains('lastCaptureBlockReason'));
      expect(source, contains('guidanceBlockingPolicy'));
      expect(source, contains('manualCaptureBlockPolicy'));
      expect(
        source,
        contains('quality_guidance_warns_never_blocks_manual_capture'),
      );
      expect(
        source,
        contains('only_busy_closing_no_camera_or_inactive_surface'),
      );
      expect(source, contains('latestCaptureLiveBrightnessAtShutter'));
      expect(source, contains('latestCapturedLiveToSavedLumaDelta'));
      expect(source, contains('latestCapturedLiveToSavedLumaDeltaBucket'));
      expect(source, contains('latestCapturedPreviewParitySignal'));
      expect(source, contains('saved_photo_darker_than_preview_review_needed'));
      expect(dartSource, contains('String get preCaptureExposurePolicy'));
      expect(
        dartSource,
        contains('receipt_paper_metering_dim_rescue_v2_manual_slider'),
      );
      expect(
        serviceSource,
        contains("'preCaptureExposurePolicy': config.preCaptureExposurePolicy"),
      );
      expect(source, contains('settingsControlExpected'));
      expect(source, contains('backControlExpected'));
      expect(source, contains('torchControlExpected'));
      expect(source, contains('closeAction'));
      expect(source, contains('closeRequestCount'));
      expect(source, contains('closeDuringCaptureCount'));
      expect(source, contains('closeNoPhotoCancelCount'));
      expect(source, contains('closeReturnedSectionsCount'));
      expect(source, contains('nativeCaptureReviewTransitionPolicy'));
      expect(
        source,
        contains('captured_photos_must_open_review_then_receipt_details'),
      );
      expect(source, contains('nativeCaptureReviewTransitionTarget'));
      expect(source, contains('receipt_photo_review_next_to_receipt_details'));
      expect(source, contains('nativeCaptureReviewDiscardPolicy'));
      expect(source, contains('never_discard_captured_photo_on_back'));
      expect(source, isNot(contains('latestReadabilitySignal ==')));
      expect(source, isNot(contains('latestFramingSignal ==')));
      expect(source, isNot(contains('dim_receipt_rescue')));
      expect(source, isNot(contains('rawOcrText')));
      expect(source, isNot(contains('receiptText')));
    }

    expect(serviceSource, contains('previousSectionGhostGuideUsesNextContext'));
    expect(
      stagingSafeKeysSource,
      contains('previousSectionGhostGuideUsesNextContext'),
    );
    expect(
      stagingSafeKeysSource,
      contains('previousSectionGhostGuideMatchTarget'),
    );
    expect(stagingSafeKeysSource, contains('nativeRecoveryOriginalPhotoCount'));
    expect(stagingSafeKeysSource, contains('nativeRecoveryExistingPhotoCount'));
    expect(stagingSafeKeysSource, contains('nativeRecoveryMissingPhotoCount'));
    expect(stagingSafeKeysSource, contains('nativeRecoveryResumeReadiness'));
    expect(
      stagingSafeKeysSource,
      contains('nativeRecoveryPartialResumeReviewRequired'),
    );
    expect(
      stagingSafeKeysSource,
      isNot(contains('previousSectionGuidePhotoPath')),
    );
    expect(stagingSafeKeysSource, isNot(contains('receiptText')));

    expect(androidSource, contains('extraCloseAction'));
    expect(androidSource, contains('closeDuringCapturePolicy'));
    expect(androidSource, contains('closeNoPhotoPolicy'));
    expect(androidSource, contains('capturedPhotoReviewDestination'));
    expect(
      androidSource,
      contains('Back keeps captured photos and opens receipt photo review.'),
    );
    expect(
      androidSource,
      contains('Back closes the camera when no receipt photo was captured.'),
    );
    expect(
      androidMainSource,
      contains('ReceiptCameraActivity.extraCloseAction'),
    );
    expect(androidMainSource, contains('mapOf("closeAction" to closeAction)'));
    expect(iosSource, contains('onCancel: ((String) -> Void)?'));
    expect(iosSource, contains('self?.onCancel?(reason)'));
    expect(
      iosDelegateSource,
      contains('details: ["closeAction": closeAction]'),
    );
  });
}

List<File> _sourceFilesUnder(String rootPath) {
  return Directory(rootPath).listSync(recursive: true).whereType<File>().where((
    file,
  ) {
    final path = file.path;
    return path.endsWith('.dart') ||
        path.endsWith('.kt') ||
        path.endsWith('.swift');
  }).toList();
}

String _readNativeCameraContractSource() {
  final paths = [
    'lib/shared/widgets/receipt_capture/receipt_native_camera_contract.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_camera_settings.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_camera_settings_session.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_camera_settings_policy.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_camera_settings_descriptors.dart',
    'lib/shared/widgets/receipt_capture/receipt_native_camera_session_config.dart',
  ];
  return paths.map((path) => File(path).readAsStringSync()).join('\n');
}
