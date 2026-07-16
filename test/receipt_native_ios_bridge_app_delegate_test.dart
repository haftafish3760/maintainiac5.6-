import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test('iOS receipt camera bridge uses AVFoundation method channel', () async {
    final sources = await readIosReceiptCameraBridgeSources();
    final appDelegate = sources.appDelegate;

    expect(appDelegate, contains('import AVFoundation'));
    expect(appDelegate, contains('maintainiac/receipt_camera'));
    expect(appDelegate, contains('FlutterMethodChannel'));
    expect(appDelegate, contains('readCapabilities'));
    expect(appDelegate, contains('captureReceipt'));
    expect(appDelegate, contains('ReceiptCameraViewController'));
    expect(appDelegate, contains('present(controller, animated: true)'));
    expect(appDelegate, contains('originalPhotoPaths'));
    expect(appDelegate, contains('native_camera_cancelled'));
    expect(appDelegate, contains('captureDiagnostics": diagnostics'));
    expect(appDelegate, contains('AVCaptureDevice.DiscoverySession'));
    expect(appDelegate, contains('AVCaptureDevice.authorizationStatus'));
    expect(appDelegate, contains('maxAvailableVideoZoomFactor'));
    expect(appDelegate, contains('maxStillDimensions'));
    expect(appDelegate, contains('highResolutionStillImageDimensions'));
    expect(appDelegate, contains('"maxStillWidth": stillDimensions.width'));
    expect(appDelegate, contains('"maxStillHeight": stillDimensions.height'));
    expect(appDelegate, contains('minExposureTargetBias'));
    expect(appDelegate, contains('maxExposureTargetBias'));
    expect(appDelegate, contains('isFocusPointOfInterestSupported'));
    expect(
      appDelegate,
      contains(
        '"supportsContinuousFocus": camera?.isFocusModeSupported(.continuousAutoFocus)',
      ),
    );
    expect(
      appDelegate,
      contains('isLockingFocusWithCustomLensPositionSupported'),
    );
    expect(appDelegate, contains('isExposureModeSupported(.custom)'));
    expect(appDelegate, contains('isWhiteBalanceModeSupported(.locked)'));
    expect(
      appDelegate,
      contains('isLockingWhiteBalanceWithCustomDeviceGainsSupported'),
    );
    expect(appDelegate, contains('hasTorch'));
    expect(appDelegate, contains('hasFlash'));
    expect(appDelegate, contains('"engine": "avFoundation"'));
    expect(
      appDelegate,
      contains('"supportsNativeEdgeSignals": true'),
    );
    expect(
      appDelegate,
      contains('computes framing signals\n      // from live YUV frames'),
    );
    expect(appDelegate, isNot(contains('UIImagePickerController')));
    expect(appDelegate, isNot(contains('PHPickerViewController')));
  });
}
