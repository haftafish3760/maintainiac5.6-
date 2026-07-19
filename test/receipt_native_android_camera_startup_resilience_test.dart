import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test(
    'Android camera startup failure retries once then returns to fallback',
    () async {
      final sources = await readAndroidReceiptCameraBridgeSources();
      final camera = sources.cameraActivity;
      final host = sources.activity;

      expect(
        camera,
        contains(
          'if (cameraStartInProgress || closingCamera || closeResultDelivered) return',
        ),
      );
      expect(
        camera,
        contains('runCatching { providerFuture.get() }.getOrElse'),
      );
      expect(
        camera,
        contains('if (cameraStartAttemptCount < 2 && isCameraSurfaceActive())'),
      );
      expect(
        camera,
        contains(r'lastCameraStartStatus = "retry_scheduled_$reason"'),
      );
      expect(camera, contains('cancelForCameraStartupFailure(reason)'));
      expect(
        camera,
        contains(
          'putExtra(ReceiptCameraActivity.extraCameraFailureReason, reason)',
        ),
      );
      expect(camera, contains('runCatching { cameraProvider?.unbindAll() }'));
      expect(
        camera,
        isNot(
          contains('ProcessCameraProvider.getInstance(this).get().unbindAll()'),
        ),
      );
      expect(
        camera,
        contains('"cameraStartAttemptCount" to cameraStartAttemptCount'),
      );
      expect(
        camera,
        contains('"cameraStartFailureCount" to cameraStartFailureCount'),
      );
      expect(
        camera,
        contains('"lastCameraStartStatus" to lastCameraStartStatus'),
      );
      expect(host, contains('"native_camera_unavailable"'));
      expect(host, contains('"cameraFailureReason" to cameraFailureReason'));
    },
  );

  test('permission failure message is emitted once', () async {
    final sources = await readAndroidReceiptCameraBridgeSources();
    const message = 'showPickerError(flowResult.message);';
    final permissionCase = sources.importActions.substring(
      sources.importActions.indexOf(
        'case ReceiptCaptureFlowStatus.permissionDenied:',
      ),
      sources.importActions.indexOf(
        'case ReceiptCaptureFlowStatus.nativeUnavailable:',
      ),
    );

    expect(message.allMatches(permissionCase), hasLength(1));
  });
}
