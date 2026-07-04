import 'package:flutter/services.dart';

import 'receipt_assistance_policy.dart';
import 'receipt_native_capture_diagnostics_sanitizer.dart';
import 'receipt_native_camera_contract.dart';

part 'receipt_native_camera_service_contract_helpers.dart';

class ReceiptNativeCameraUnavailableException implements Exception {
  const ReceiptNativeCameraUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ReceiptNativeCameraCanceledException
    extends ReceiptNativeCameraUnavailableException {
  const ReceiptNativeCameraCanceledException({
    this.closeAction = 'unknown_cancel',
  }) : super('Receipt photo capture was cancelled.');

  final String closeAction;
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
      if (paths.isEmpty) {
        throw const ReceiptNativeCameraUnavailableException(
          'Maintainiac receipt camera did not capture a receipt photo.',
        );
      }
      if (_hasUnsafeNativeReceiptPaths(paths)) {
        throw const ReceiptNativeCameraUnavailableException(
          'Maintainiac receipt camera returned non-local or non-image receipt photo paths.',
        );
      }
      if (paths.length > config.maxSectionCount) {
        throw const ReceiptNativeCameraUnavailableException(
          'Maintainiac receipt camera returned too many receipt sections.',
        );
      }
      if (_hasDuplicateNativeReceiptPaths(paths)) {
        throw const ReceiptNativeCameraUnavailableException(
          'Maintainiac receipt camera returned duplicate receipt photo paths.',
        );
      }
      final captureIds = _safeNativeCaptureIds(
        result['temporaryCaptureIds'],
        paths.length,
      );
      final nativeDiagnostics = receiptNativeCaptureSanitizedDiagnostics(
        result['captureDiagnostics'],
      );
      if (_exceedsNativeReceiptByteBudget(
        nativeDiagnostics,
        config.maxLocalPhotoBytes,
      )) {
        throw const ReceiptNativeCameraUnavailableException(
          'Maintainiac receipt camera returned an oversized receipt photo.',
        );
      }
      _verifyMaintainiacReceiptSurface(config, nativeDiagnostics);
      return ReceiptNativeCaptureResult(
        engine: config.nativeCapabilities.engine,
        originalPhotoPaths: paths,
        temporaryCaptureIds: captureIds,
        capturedAt:
            DateTime.tryParse(result['capturedAt']?.toString() ?? '') ??
            DateTime.now(),
        captureDiagnostics: {
          ...nativeDiagnostics,
          'nativeReceiptCameraSurfaceVerified': true,
          'nativeReceiptCameraSurfaceVerification':
              'maintainiac_custom_surface_verified',
          'nativeReceiptCameraSurfaceActual':
              nativeDiagnostics['captureSurface']?.toString().trim().isEmpty ==
                  false
              ? nativeDiagnostics['captureSurface']
              : _expectedCaptureSurface(config),
          ..._nativeControlContract(config),
          ...config.cloudAssistPlan.toPrivacySafeDiagnostics(),
          ...config.installRecommendation.toPrivacySafeDiagnostics(),
          ...config.receiptBrainRecommendation.toPrivacySafeDiagnostics(),
          ...config.receiptBrainFootprintSummary.toPrivacySafeDiagnostics(),
          ...config.parserPackRoutingPlan.toPrivacySafeDiagnostics(),
          'localOnlyCapturePolicy': config.localOnlyCapturePolicy,
          'localOnlyBaseFlowCanRunNow':
              config.localOnlyAcceptanceGate.baseFlowCanRunLocallyNow,
          'localOnlyHeavyPacksMayBlockCapture':
              config.heavyReceiptPacksMayBlockCapture,
          'localOnlyCloudAssistMayBlockCapture':
              config.cloudAssistMayBlockCapture,
          'localOnlyCameraMustStayAvailableBeforePacks':
              !config.heavyReceiptPacksMayBlockCapture,
          'localOnlyProofSaveMustStayAvailableBeforePacks':
              config.localOnlyAcceptanceGate.canSaveReceiptProof,
          'localOnlyBasicReviewMustStayAvailableBeforePacks':
              config.localOnlyAcceptanceGate.canOpenBasicLocalReview,
          'capabilityPolicyCodes': config.capabilityPolicyCodes,
          if (config.hasPreviousSectionGuide) ...{
            'previousSectionReasonCode': config.previousSectionGuideReasonCode,
            'previousSectionGhostGuidePolicy':
                config.previousSectionGhostGuidePolicy,
            'previousSectionGhostGuideRepeatLineTarget':
                config.previousSectionGhostGuideRepeatLineTarget,
            'previousSectionGhostGuidePlacement':
                config.previousSectionGhostGuidePlacement,
            'previousSectionGhostGuideMatchTarget':
                config.previousSectionGhostGuideMatchTarget,
            'previousSectionGhostSourceStartFraction':
                config.previousSectionGhostSourceStartFractionOrDefault,
            'previousSectionGhostSourceHeightFraction':
                config.previousSectionGhostSourceHeightFractionOrDefault,
            'previousSectionGhostOverlayTopFraction':
                config.previousSectionGhostOverlayTopFractionOrDefault,
            'previousSectionGhostOverlayHeightFraction':
                config.previousSectionGhostOverlayHeightFractionOrDefault,
            'previousSectionGhostOpacity':
                config.previousSectionGhostOpacityOrDefault,
            'previousSectionGhostSlicePercent':
                config.previousSectionGhostSlicePercent,
            'previousSectionMissingBottomAndTotals':
                config.previousSectionGuideMissingBottomAndTotals,
            'previousSectionGuidanceAvailable': config
                .previousSectionGuideGuidance
                .trim()
                .isNotEmpty,
          },
        },
      );
    } on MissingPluginException {
      throw const ReceiptNativeCameraUnavailableException(
        'Maintainiac native receipt camera is not installed on this build.',
      );
    } on PlatformException catch (error) {
      if (error.code.toLowerCase().contains('cancel')) {
        throw ReceiptNativeCameraCanceledException(
          closeAction: _platformCloseAction(error.details),
        );
      }
      throw ReceiptNativeCameraUnavailableException(
        error.message ?? 'Maintainiac receipt camera could not open.',
      );
    }
  }
}

bool _hasDuplicateNativeReceiptPaths(List<String> paths) {
  final seen = <String>{};
  for (final path in paths) {
    if (!seen.add(path)) return true;
  }
  return false;
}

bool _hasUnsafeNativeReceiptPaths(List<String> paths) {
  for (final path in paths) {
    if (!path.startsWith('/')) return true;
    if (path.contains('\u0000')) return true;
    if (path.contains('://')) return true;
    if (!_isNativeReceiptImagePath(path)) return true;
  }
  return false;
}

bool _isNativeReceiptImagePath(String path) {
  final lowerPath = path.toLowerCase();
  return lowerPath.endsWith('.jpg') ||
      lowerPath.endsWith('.jpeg') ||
      lowerPath.endsWith('.png') ||
      lowerPath.endsWith('.heic') ||
      lowerPath.endsWith('.heif');
}

bool _exceedsNativeReceiptByteBudget(
  Map<String, Object?> diagnostics,
  int maxLocalPhotoBytes,
) {
  if (maxLocalPhotoBytes <= 0) return false;
  final byteSize = _nativeReceiptByteSize(diagnostics);
  return byteSize != null && byteSize > maxLocalPhotoBytes;
}

int? _nativeReceiptByteSize(Map<String, Object?> diagnostics) {
  final values = [
    diagnostics['photoByteSize'],
    diagnostics['totalCapturedByteSize'],
  ];
  for (final value in values) {
    if (value is int && value > 0) return value;
    if (value is double && value.isFinite && value > 0) {
      return value.round();
    }
  }
  return null;
}
