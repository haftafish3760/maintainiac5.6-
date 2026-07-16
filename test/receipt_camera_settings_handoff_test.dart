import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_preference_mapper.dart';

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
    final androidSessionArguments = await File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSessionArguments.kt',
    ).readAsString();
    final iosSessionArguments = await File(
      'ios/Runner/ReceiptCameraViewControllerSessionArguments.swift',
    ).readAsString();

    final preferenceMapper = await File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_preference_mapper.dart',
    ).readAsString();

    for (final source in [preferenceMapper]) {
      expect(source, contains('liveYuvAnalysisEnabled: guidanceEnabled'));
      expect(source, contains('edgeDetectionEnabled: guidanceEnabled'));
      expect(source, contains('edgeOverlayEnabled: guidanceEnabled'));
      expect(
        source,
        contains('receiptFullyVisibleWarningEnabled: guidanceEnabled'),
      );
      expect(source, contains('receiptPhotoBackupEnabled:'));
      expect(source, contains('askSavedProofSizeEachReceipt:'));
      expect(source, contains('previousSectionGhostGuideEnabled:'));
    }
    expect(
      reviewCaptureActions,
      contains('receiptNativeCameraSettingsForCapture('),
    );
    expect(
      reviewCaptureActions,
      isNot(contains('ReceiptNativeCameraSettings(')),
    );
    expect(reviewCaptureActions, contains('longReceiptMode: true'));
    expect(flowSettings, contains('receiptNativeCameraSettingsForCapture('));
    expect(flowSettings, isNot(contains('ReceiptNativeCameraSettings(')));
    expect(flowSettings, contains('options.forceLongReceiptMode ?? false'));
    expect(
      flowSettings,
      contains('options.forceAutoCapture ?? settings?.cameraAutoCapture ?? false'),
    );
    expect(
      androidSessionArguments,
      contains('getBooleanExtra("longReceiptMode", false)'),
    );
    expect(
      iosSessionArguments,
      contains('arguments["longReceiptMode"] as? Bool ?? false'),
    );
    for (final source in [androidSessionArguments, iosSessionArguments]) {
      expect(source, contains('autoCaptureEnabled'));
      expect(source, contains('receiptPhotoBackupEnabled'));
      expect(source, contains('askSavedProofSizeEachReceipt'));
    }
    expect(
      attachmentCameraActions,
      contains(
        'if (_needsBottomReceiptSection) return true;\n    return null;',
      ),
    );
  });

  test('standard capture starts short while continuation capture opts in', () {
    final standard = receiptNativeCameraSettingsForCapture(
      settings: null,
      assistedReceiptFill: false,
      longReceiptMode: false,
      autoCaptureEnabled: false,
      reviewDepth: ReceiptNativeReviewDepth.pricesOnly,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );
    final continuation = receiptNativeCameraSettingsForCapture(
      settings: null,
      assistedReceiptFill: false,
      longReceiptMode: true,
      autoCaptureEnabled: false,
      reviewDepth: ReceiptNativeReviewDepth.pricesOnly,
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
    );

    expect(standard.longReceiptMode, isFalse);
    expect(standard.hasConservativeLiveReceiptGuidance, isTrue);
    expect(continuation.longReceiptMode, isTrue);
    expect(continuation.previousSectionGhostGuideEnabled, isTrue);
  });
}
