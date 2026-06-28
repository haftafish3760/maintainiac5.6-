import 'package:flutter/services.dart';

import 'receipt_native_camera_contract.dart';

class ReceiptNativeCameraUnavailableException implements Exception {
  const ReceiptNativeCameraUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReceiptNativeCameraCanceledException
    extends ReceiptNativeCameraUnavailableException {
  const ReceiptNativeCameraCanceledException()
    : super('Receipt photo capture was cancelled.');
}

class ReceiptNativeCameraService {
  const ReceiptNativeCameraService({MethodChannel? methodChannel})
    : _methodChannel =
          methodChannel ?? const MethodChannel('maintainiac/receipt_camera');

  final MethodChannel _methodChannel;

  Future<ReceiptNativeCameraCapabilities> readCapabilities() async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, dynamic>(
        'readCapabilities',
      );
      if (result == null) {
        return const ReceiptNativeCameraCapabilities.unavailable();
      }
      return ReceiptNativeCameraCapabilities.fromMap(result);
    } on MissingPluginException {
      return const ReceiptNativeCameraCapabilities.unavailable();
    } on PlatformException {
      return const ReceiptNativeCameraCapabilities.unavailable();
    }
  }

  Future<ReceiptNativeCaptureResult> captureReceipt(
    ReceiptNativeCameraSessionConfig config,
  ) async {
    try {
      final result = await _methodChannel.invokeMapMethod<String, dynamic>(
        'captureReceipt',
        _sessionArguments(config),
      );
      if (result == null) {
        throw const ReceiptNativeCameraUnavailableException(
          'Maintainiac receipt camera did not return a photo.',
        );
      }
      final paths = _stringList(result['originalPhotoPaths']);
      final captureIds = _stringList(result['temporaryCaptureIds']);
      if (paths.isEmpty) {
        throw const ReceiptNativeCameraUnavailableException(
          'Maintainiac receipt camera did not capture a receipt photo.',
        );
      }
      return ReceiptNativeCaptureResult(
        engine: config.nativeCapabilities.engine,
        originalPhotoPaths: paths,
        temporaryCaptureIds: captureIds,
        capturedAt:
            DateTime.tryParse(result['capturedAt']?.toString() ?? '') ??
            DateTime.now(),
        captureDiagnostics: Map<String, Object?>.from(
          result['captureDiagnostics'] is Map
              ? result['captureDiagnostics'] as Map
              : const {},
        ),
      );
    } on MissingPluginException {
      throw const ReceiptNativeCameraUnavailableException(
        'Maintainiac native receipt camera is not installed on this build.',
      );
    } on PlatformException catch (error) {
      if (error.code.toLowerCase().contains('cancel')) {
        throw const ReceiptNativeCameraCanceledException();
      }
      throw ReceiptNativeCameraUnavailableException(
        error.message ?? 'Maintainiac receipt camera could not open.',
      );
    }
  }

  Map<String, Object?> _sessionArguments(
    ReceiptNativeCameraSessionConfig config,
  ) {
    final settings = config.settings;
    return {
      'engine': config.nativeCapabilities.engine.name,
      'manualShutterAlwaysAvailable': settings.manualShutterAlwaysAvailable,
      'autoCaptureEnabled': config.autoCaptureEnabled,
      'autoCaptureAllowed': config.autoCaptureAllowed,
      'assistedReceiptFill': settings.assistedReceiptFill,
      'reviewDepth': settings.reviewDepth.name,
      'longReceiptMode': settings.longReceiptMode,
      'tapFocusEnabled': settings.tapFocusEnabled,
      'pinchZoomEnabled': settings.pinchZoomEnabled,
      'exposureSliderEnabled': settings.exposureSliderEnabled,
      'exposureResetEnabled': settings.exposureResetEnabled,
      'autoExposureAssistEnabled': settings.autoExposureAssistEnabled,
      'focusMode': settings.focusMode.name,
      'exposureMode': settings.exposureMode.name,
      'whiteBalanceMode': settings.whiteBalanceMode.name,
      'flashMode': settings.flashMode.name,
      'preferMacroWhenHelpful': settings.preferMacroWhenHelpful,
      'imageFormat': settings.imageFormat.name,
      'liveAnalysisEnabled': config.liveAnalysisEnabled,
      'edgeDetectionEnabled': config.edgeDetectionEnabled,
      'edgeOverlayEnabled': settings.edgeOverlayEnabled,
      'perspectiveCorrectionEnabled': settings.perspectiveCorrectionEnabled,
      'motionBlurWarningEnabled': settings.motionBlurWarningEnabled,
      'glareWarningEnabled': settings.glareWarningEnabled,
      'lowLightWarningEnabled': settings.lowLightWarningEnabled,
      'shadowWarningEnabled': settings.shadowWarningEnabled,
      'tooFarTooCloseWarningEnabled': settings.tooFarTooCloseWarningEnabled,
      'receiptFullyVisibleWarningEnabled':
          settings.receiptFullyVisibleWarningEnabled,
      'textTooSmallWarningEnabled': settings.textTooSmallWarningEnabled,
      'previousSectionGhostGuideEnabled':
          settings.previousSectionGhostGuideEnabled,
      'manualCropAfterCapture': settings.manualCropAfterCapture,
      'autoCropSuggestionEnabled': settings.autoCropSuggestionEnabled,
      'grayscalePreviewEnabled': settings.grayscalePreviewEnabled,
      'contrastBoostEnabled': settings.contrastBoostEnabled,
      'sharpeningEnabled': settings.sharpeningEnabled,
      'shadowReductionEnabled': settings.shadowReductionEnabled,
      'adaptiveThresholdEnabled': settings.adaptiveThresholdEnabled,
      'orientationCorrectionEnabled': settings.orientationCorrectionEnabled,
      'saveOriginalTemporarily': settings.saveOriginalTemporarily,
      'queueAcceptedCaptureLocally': settings.queueAcceptedCaptureLocally,
      'ocrUsesOriginalFirst': settings.ocrUsesOriginalFirst,
      'dataSaverLevel': settings.dataSaverLevel.name,
      'storageSafetyLevel': config.storageSafetyLevel.name,
      'storageConstrained': config.storageConstrained,
      'storageSafetyReason': config.storageSafetyReason,
      'maxSectionCount': config.maxSectionCount,
      'analysisGapMs': config.analysisGapMs,
      if (config.hasPreviousSectionGuide)
        'previousSectionGuidePhotoPath': config.previousSectionGuidePhotoPath,
    };
  }

  List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((entry) => entry.toString().trim())
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }
}
