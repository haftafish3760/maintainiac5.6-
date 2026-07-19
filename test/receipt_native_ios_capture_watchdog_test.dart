import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test(
    'iOS capture watchdog rejects late callbacks and restores the shutter',
    () async {
      final sources = await readIosReceiptCameraBridgeSources();
      final camera = sources.cameraController;

      expect(camera, contains('let captureTimeoutSeconds = 20.0'));
      expect(camera, contains('activeCaptureUniqueId = captureUniqueId'));
      expect(camera, contains('self?.handleCaptureTimeout(captureUniqueId)'));
      expect(camera, contains('photo.resolvedSettings.uniqueID'));
      expect(
        camera,
        contains('guard finishCaptureAttempt(captureUniqueId) else { return }'),
      );
      expect(camera, contains('lastCaptureBlockReason = "capture_timeout"'));
      expect(camera, contains('shutterButton.isEnabled = true'));
      expect(
        camera,
        contains('if closeWasPending && !capturedPhotoPaths.isEmpty'),
      );
      expect(camera, contains('"captureTimeoutCount": captureTimeoutCount'));
      expect(
        camera,
        contains('"captureTimeoutSeconds": captureTimeoutSeconds'),
      );
    },
  );
}
