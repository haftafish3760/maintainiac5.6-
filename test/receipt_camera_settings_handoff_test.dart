import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('capture session honors saved camera guidance and proof preferences', () async {
    final reviewCaptureActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
    ).readAsString();
    final flowSettings = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_flow_helpers.dart',
    ).readAsString();
    final attachmentCameraActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
    ).readAsString();

    final preferenceMapper = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_preference_mapper.dart',
    ).readAsString();

    for (final source in [preferenceMapper]) {
      expect(
        source,
        contains('liveYuvAnalysisEnabled: guidanceEnabled'),
      );
      expect(
        source,
        contains('edgeDetectionEnabled: guidanceEnabled'),
      );
      expect(
        source,
        contains('edgeOverlayEnabled: guidanceEnabled'),
      );
      expect(
        source,
        contains('receiptFullyVisibleWarningEnabled: guidanceEnabled'),
      );
      expect(source, contains('receiptPhotoBackupEnabled:'));
      expect(source, contains('askSavedProofSizeEachReceipt:'));
      expect(source, contains('previousSectionGhostGuideEnabled:'));
    }
    expect(reviewCaptureActions, contains('receiptNativeCameraSettingsForCapture('));
    expect(reviewCaptureActions, contains('longReceiptMode: true'));
    expect(flowSettings, contains('receiptNativeCameraSettingsForCapture('));
    expect(flowSettings, contains('options.forceLongReceiptMode ?? false'));
    expect(
      attachmentCameraActions,
      contains('if (_needsBottomReceiptSection) return true;\n    return null;'),
    );
  });
}
