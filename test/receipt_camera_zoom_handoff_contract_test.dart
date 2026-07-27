import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('camera review handoff preserves exact shutter zoom', () {
    final evidence = ReceiptCameraCaptureEvidence(
      captureSurface: 'maintainiac_native_android',
      captureFlow: 'assisted',
      resolutionTier: 'high',
      resolutionPreset: 'veryHigh',
      flashMode: 'off',
      exposureMode: 'auto',
      focusMode: 'auto',
      exposurePointSupported: true,
      focusPointSupported: true,
      exposureOffset: 0,
      minExposureOffset: -2,
      maxExposureOffset: 2,
      zoomLevel: 2.75,
      minZoomLevel: 1,
      maxZoomLevel: 10,
      previewWidth: 1920,
      previewHeight: 1080,
      liveBrightness: 140,
      liveContrast: 24,
      liveFocusScore: 12,
      liveReadiness: 'ready',
      imageStreamActiveAtCapture: true,
    );

    final diagnostics = evidence.toCaptureDiagnostics(
      quality: null,
      photoIndex: 0,
    );

    expect(
      diagnostics[ReceiptCaptureDiagnosticKeys.latestCaptureShutterZoomRatio],
      2.75,
    );
  });
}
