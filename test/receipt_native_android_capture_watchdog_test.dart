import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test(
    'Android capture watchdog recovers without accepting late callbacks',
    () async {
      final sources = await readAndroidReceiptCameraBridgeSources();
      final camera = sources.cameraActivity;

      expect(camera, contains('internal var captureTimeoutMs = 20_000L'));
      expect(camera, contains('activeCaptureAttemptId = captureAttemptId'));
      expect(
        camera,
        contains('{ handleCaptureTimeout(captureAttemptId, outputFile) }'),
      );
      expect(
        camera,
        contains('if (!finishCaptureAttempt(captureAttemptId)) {'),
      );
      expect(camera, contains('outputFile.delete()'));
      expect(camera, contains('lastCaptureBlockReason = "capture_timeout"'));
      expect(camera, contains('shutterButton.isEnabled = true'));
      expect(
        camera,
        contains('if (closeWasPending && capturedPhotoPaths.isNotEmpty())'),
      );
      expect(camera, contains('"captureTimeoutCount" to captureTimeoutCount'));
      expect(camera, contains('"captureTimeoutMs" to captureTimeoutMs'));
    },
  );
}
