import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test('iOS camera survives settings cover and session interruption', () async {
    final sources = await readIosReceiptCameraBridgeSources();
    final camera = sources.cameraController;
    final layout = await File(
      'ios/Runner/ReceiptCameraViewControllerLayout.swift',
    ).readAsString();
    final disappearBlock = layout.substring(
      layout.indexOf('override func viewWillDisappear'),
      layout.indexOf('func buildLayout()'),
    );

    expect(disappearBlock, contains('cameraViewClosing = true'));
    expect(disappearBlock, isNot(contains('closingCamera = true')));
    expect(
      camera,
      contains('if !closeResultDelivered {\n      closingCamera = false'),
    );
    expect(camera, contains('registerSessionRecoveryObservers()'));
    expect(camera, contains('.AVCaptureSessionWasInterrupted'));
    expect(camera, contains('.AVCaptureSessionInterruptionEnded'));
    expect(camera, contains('.AVCaptureSessionRuntimeError'));
    expect(camera, contains('error?.code == .mediaServicesWereReset'));
    expect(camera, contains('case .sensitiveContentMitigationActivated:'));
    expect(camera, contains('interrupted_sensitive_content_mitigation'));
    expect(camera, contains('guard sessionRecoveryAttemptCount < 2 else'));
    expect(camera, contains('self.sessionRecoveryAttemptCount = 0'));
    expect(camera, contains('removeSessionRecoveryObservers()'));
    expect(
      camera,
      contains('"sessionInterruptionCount": sessionInterruptionCount'),
    );
    expect(
      camera,
      contains('"sessionRuntimeErrorCount": sessionRuntimeErrorCount'),
    );
    expect(
      camera,
      contains('"lastSessionRecoveryStatus": lastSessionRecoveryStatus'),
    );
    expect(
      RegExp(
        '"latestCaptureShutterExposureTargetBias": '
        'latestCaptureShutterExposureTargetBias',
      ).allMatches(camera),
      hasLength(1),
    );
    expect(camera, contains('Go back to choose another receipt source.'));
  });
}
