import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test(
    'iOS preview analysis and photo output share interface orientation',
    () async {
      final sources = await readIosReceiptCameraBridgeSources();
      final camera = sources.cameraController;

      expect(camera, contains('func updateCaptureOrientation()'));
      expect(
        camera,
        contains('view.window?.windowScene?.interfaceOrientation'),
      );
      expect(camera, contains('previewLayer?.connection'));
      expect(camera, contains('photoOutput.connection(with: .video)'));
      expect(camera, contains('videoOutput.connection(with: .video)'));
      expect(camera, contains('connection.isVideoOrientationSupported'));
      expect(
        camera,
        contains('connection.videoOrientation = captureOrientation'),
      );
      expect(camera, contains('case .portraitUpsideDown:'));
      expect(camera, contains('case .landscapeLeft:'));
      expect(camera, contains('case .landscapeRight:'));
      expect(
        camera,
        contains(
          'previewLayer?.frame = view.bounds\n    updateCaptureOrientation()',
        ),
      );
      expect(
        camera,
        contains('"lastCaptureOrientation": lastCaptureOrientation'),
      );
    },
  );
}
