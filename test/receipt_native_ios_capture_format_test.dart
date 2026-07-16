import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS capture bytes match the staged receipt file extension', () async {
    final capture = await File(
      'ios/Runner/ReceiptCameraViewControllerCapture.swift',
    ).readAsString();
    final close = await File(
      'ios/Runner/ReceiptCameraViewControllerCaptureClose.swift',
    ).readAsString();

    expect(
      capture,
      contains('photoOutput.availablePhotoCodecTypes.contains(.jpeg)'),
    );
    expect(capture, contains('AVCapturePhotoSettings(format: ['));
    expect(capture, contains('AVVideoCodecKey: AVVideoCodecType.jpeg'));
    expect(capture, contains('settings = AVCapturePhotoSettings()'));
    expect(close, contains(').jpg")'));
  });
}
