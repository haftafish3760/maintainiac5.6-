import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_ios_bridge_source_readers.dart';

void main() {
  test('iOS bridge protects close and review handoff controls', () async {
    final sources = await readIosReceiptCameraBridgeSources();
    final cameraController = sources.cameraController;

    expect(cameraController, contains('Take receipt photo'));
    expect(cameraController, contains('doneButton'));
    expect(
      cameraController,
      contains('Next: review captured receipt photos in Maintainiac'),
    );
    expect(cameraController, contains('finishWithCapturedPhotos'));
    expect(cameraController, contains('@objc func cancelCapture()'));
    expect(cameraController, contains('if closeResultDelivered {'));
    expect(cameraController, contains('closeRetryCount += 1'));
    expect(cameraController, contains('presentingViewController != nil'));
    expect(cameraController, contains('pendingCloseAfterCapture'));
    expect(
      cameraController,
      contains('Saving this receipt photo before opening review.'),
    );
    expect(
      cameraController,
      contains('latestAutoCaptureStatus = "closing_after_capture"'),
    );
    expect(
      cameraController,
      contains(
        'cancelWithoutCapturedPhoto(reason: "back_capture_failed_cancel")',
      ),
    );
    expect(
      cameraController,
      contains('func cancelWithoutCapturedPhoto(reason: String)'),
    );
    expect(
      cameraController,
      contains(
        'finishWithCapturedPhotos(closeReason: "back_returned_captured_sections")',
      ),
    );
    expect(
      cameraController,
      contains('cancelWithoutCapturedPhoto(reason: "back_no_photo_cancel")'),
    );
    expect(
      cameraController,
      contains('cancelWithoutCapturedPhoto(reason: "done_no_photo_cancel")'),
    );
    expect(cameraController, contains('closeResultDelivered = true'));

    final cancelStart = cameraController.indexOf('@objc func cancelCapture()');
    final inFlightCloseStart = cameraController.indexOf(
      'if captureInFlight {',
      cancelStart,
    );
    final normalClosingStart = cameraController.indexOf(
      'closingCamera = true',
      cancelStart,
    );
    expect(cancelStart, greaterThanOrEqualTo(0));
    expect(inFlightCloseStart, greaterThan(cancelStart));
    expect(normalClosingStart, greaterThan(inFlightCloseStart));
  });

  test('iOS bridge keeps long receipt add-section controls discoverable', () async {
    final sources = await readIosReceiptCameraBridgeSources();
    final cameraController = sources.cameraController;

    expect(cameraController, contains('Next'));
    expect(cameraController, contains('Add Photo'));
    expect(cameraController, contains('captureAdditionalPhoto'));
    expect(cameraController, contains('manual_add_photo'));
    expect(
      cameraController,
      contains('Next (\\(capturedPhotoPaths.count) photos)'),
    );
    expect(
      cameraController,
      contains('Next: review captured receipt photos in Maintainiac'),
    );
    expect(
      cameraController,
      contains('Add another receipt photo if this receipt continues'),
    );
    expect(
      cameraController,
      contains('func addSectionButtonTitle() -> String'),
    );
    expect(
      cameraController,
      contains('func addSectionButtonAccessibilityLabel() -> String'),
    );
    expect(cameraController, contains('return "Add Bottom"'));
    expect(
      cameraController,
      contains('Add bottom receipt section with overlap from this photo'),
    );
    expect(
      cameraController,
      contains(
        'addPhotoButton.setTitle(addSectionButtonTitle(), for: .normal)',
      ),
    );
    expect(
      cameraController,
      contains(
        'addPhotoButton.accessibilityLabel = addSectionButtonAccessibilityLabel()',
      ),
    );
    expect(cameraController, contains('return "Add Photo"'));
    expect(
      cameraController,
      contains('bottomBar.addArrangedSubview(addPhotoButton)'),
    );
    expect(
      cameraController,
      contains('bottomBar.addArrangedSubview(bottomReviewButton)'),
    );
    expect(
      cameraController,
      contains(
        'bottomReviewButton.accessibilityLabel =\n      "Next: review captured receipt photos in Maintainiac"',
      ),
    );
    expect(
      cameraController,
      contains('capturedPhotoPaths.isEmpty || !longReceiptMode'),
    );
    expect(
      cameraController,
      contains('bottomReviewButton.isHidden = capturedPhotoPaths.isEmpty'),
    );
    expect(cameraController, contains('controls.append("add_photo")'));
    expect(
      cameraController,
      contains('lastCaptureBlockReason = "capture_in_flight"'),
    );
    expect(
      cameraController,
      contains('lastCaptureBlockReason = "closing_camera"'),
    );
    expect(
      cameraController,
      contains('lastCaptureBlockReason = "camera_surface_inactive"'),
    );
    expect(
      cameraController,
      contains('captureBlockedSurfaceInactiveCount += 1'),
    );
    expect(cameraController, isNot(contains('guard isAutoCaptureReady')));
  });
}
