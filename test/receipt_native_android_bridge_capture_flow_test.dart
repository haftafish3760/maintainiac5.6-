import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_native_android_bridge_source_readers.dart';

void main() {
  test('Android receipt camera bridge uses CameraX method channel', () async {
    final sources = await readAndroidReceiptCameraBridgeSources();
    final activity = sources.activity;
    final importActions = sources.importActions;
    final captureFlow = sources.captureFlow;
    final imagePicker = sources.imagePicker;

    expect(activity, contains('maintainiac/receipt_camera'));
    expect(activity, contains('ProcessCameraProvider'));
    expect(activity, contains('providerFuture.get()'));
    expect(activity, contains('CameraCharacteristics.LENS_FACING_BACK'));
    expect(activity, contains('readCapabilities'));
    expect(activity, contains('captureReceipt'));
    expect(activity, contains('ReceiptCameraActivity::class.java'));
    expect(activity, contains('startActivityForResult'));
    expect(activity, contains('originalPhotoPaths'));
    expect(activity, contains('native_camera_cancelled'));
    expect(activity, contains('receiptCaptureDiagnostics'));
    expect(activity, contains('extraCaptureDiagnostics'));
    expect(activity, contains('captureSurface'));
    expect(activity, contains('maintainiac_native_android'));
    expect(activity, contains('is Iterable<*> ->'));
    expect(activity, contains('bundle.putStringArrayList(key, strings)'));
    expect(activity, contains('CameraCharacteristics'));
    expect(activity, contains('CONTROL_ZOOM_RATIO_RANGE'));
    expect(activity, contains('CONTROL_AE_COMPENSATION_RANGE'));
    expect(
      activity,
      contains('"supportsContinuousFocus" to focusModes.contains'),
    );
    expect(
      activity,
      contains('CameraCharacteristics.CONTROL_AF_MODE_CONTINUOUS_PICTURE'),
    );
    expect(activity, contains('SCALER_STREAM_CONFIGURATION_MAP'));
    expect(activity, contains('ImageFormat.JPEG'));
    expect(activity, contains('maxJpegStillSize'));
    expect(activity, contains('maxStillSize?.width'));
    expect(activity, contains('maxStillSize?.height'));
    expect(activity, isNot(contains('MediaStore.ACTION_IMAGE_CAPTURE')));
    expect(imagePicker, contains('Backup receipt capture'));
    expect(imagePicker, contains('Production receipt capture should try'));
    expect(imagePicker, contains('Maintainiac native receipt'));
    expect(
      importActions,
      contains('_takeMaintainiacNativeCameraPhoto(settings)'),
    );
    expect(importActions, contains('_takePhoneCameraBackupPhoto()'));
    expect(
      importActions,
      contains("'primaryCaptureFlow': 'maintainiac_native_receipt_camera'"),
    );
    expect(importActions, contains("'phoneCameraBackupRole': 'fallback_only'"));
    expect(
      importActions.indexOf('_takeMaintainiacNativeCameraPhoto(settings)'),
      lessThan(importActions.indexOf('_takePhoneCameraBackupPhoto()')),
    );
    expect(
      captureFlow,
      contains("'primaryCaptureFlow': 'maintainiac_native_receipt_camera'"),
    );
    expect(captureFlow, contains("'maintainiacCustomCameraPrimary': true"));
    expect(captureFlow, contains("'stockCameraUiAllowedAsPrimary': false"));
    expect(captureFlow, contains("'phoneCameraBackupRole': 'fallback_only'"));
    expect(captureFlow, contains("'fallbackCaptureRequiresUserAction': true"));
  });
}
