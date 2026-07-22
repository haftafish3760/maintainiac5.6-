import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';

void main() {
  test('iPhone live framing capability allows opted-in automatic capture', () {
    final native = ReceiptNativeCameraCapabilities.fromMap(const {
      'engine': 'avFoundation',
      'available': true,
      'cameraPermissionGranted': true,
      'cameraCount': 2,
      'hasRearCamera': true,
      'supportsContinuousFocus': true,
      'supportsExposureCompensation': true,
      'supportsZoom': true,
      'supportsYuvLiveFrames': true,
      'supportsNativeEdgeSignals': true,
      'minZoom': 1.0,
      'maxZoom': 5.0,
      'minExposureOffset': -2.0,
      'maxExposureOffset': 2.0,
    });

    final config = const ReceiptNativeCameraSettings(autoCaptureEnabled: true)
        .sessionFor(
          deviceCapability: const ReceiptDeviceCapability.standard(),
          nativeCapabilities: native,
        );

    expect(native.engine, ReceiptNativeCameraEngine.avFoundation);
    expect(native.supportsNativeEdgeSignals, isTrue);
    expect(config.edgeDetectionEnabled, isTrue);
    expect(config.autoCaptureAllowed, isTrue);
    expect(config.autoCaptureEnabled, isTrue);
    expect(config.tapFocusEnabled, isFalse);
    expect(config.continuousFocusEnabled, isTrue);
    expect(config.pinchZoomEnabled, isTrue);
  });
}
