import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Capture Photo uses the phone camera as the primary receipt capture',
    () async {
      final actions = await File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
      ).readAsString();
      final systemCamera = await File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_camera_fallback_actions.dart',
      ).readAsString();
      final picker = await File(
        'lib/shared/widgets/receipt_capture/receipt_image_picker.dart',
      ).readAsString();

      expect(actions, contains('await _takeSystemCameraReceiptPhoto();'));
      expect(actions, isNot(contains('_takeMaintainiacNativeCameraPhoto')));
      expect(
        systemCamera,
        contains('ReceiptImagePicker.takeReceiptPhotoSet()'),
      );
      expect(
        systemCamera,
        contains("'systemPhoneCameraRole': 'primary_capture'"),
      );
      expect(systemCamera, contains('reviewPickedPhotoPaths('));
      expect(picker, contains('source: ImageSource.camera'));
      expect(picker, contains('preferredCameraDevice: CameraDevice.rear'));
    },
  );

  test('Add Another and Retake use the same system camera path', () async {
    final actions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
    ).readAsString();
    final models = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_models.dart',
    ).readAsString();

    expect(actions, contains('ReceiptImagePicker.takeReceiptPhotoSet()'));
    expect(actions, isNot(contains('_pickWithMaintainiacNativeCamera')));
    expect(actions, contains('alignmentGuidePhotoPath: guidePhotoPath'));
    expect(actions, contains('nextSectionGuidePhotoPath:'));
    expect(models, contains('fromSystemCameraPaths'));
    expect(models, contains('systemPhoneCameraHadPreviousSectionGuide'));
  });

  test('system camera capture returns to numbered review before OCR', () async {
    final review = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_review_read_actions.dart',
    ).readAsString();
    final screen = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    ).readAsString();

    expect(review, contains('ReceiptPhotoReviewScreen('));
    expect(
      review,
      contains('initialSelectedIndex: importOrder.firstImportedPhotoIndex'),
    );
    expect(screen, contains('start on the actual captured photo preview'));
  });
}
