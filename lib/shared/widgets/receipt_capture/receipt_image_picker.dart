import 'package:image_picker/image_picker.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'receipt_photo_path_identity.dart';

class ReceiptPickedPhotoSet {
  ReceiptPickedPhotoSet(Iterable<String> paths)
    : paths = List.unmodifiable(paths);

  factory ReceiptPickedPhotoSet.fromFiles(Iterable<XFile?> files) {
    return ReceiptPickedPhotoSet(
      uniqueNormalizedReceiptPhotoPaths([
        for (final file in files.whereType<XFile>())
          if (file.path.trim().isNotEmpty) file.path.trim(),
      ]),
    );
  }

  final List<String> paths;

  bool get isEmpty => paths.isEmpty;
}

class ReceiptImagePicker {
  ReceiptImagePicker._();

  static final ImagePicker _picker = ImagePicker();

  /// Backup receipt capture uses the phone camera/gallery surfaces.
  ///
  /// Production receipt capture should try the Maintainiac native receipt
  /// camera service first. This picker remains as a fallback/import surface so
  /// users can still capture a receipt if the native bridge is unavailable.
  static Future<ReceiptPickedPhotoSet> takeReceiptPhotoSet() async {
    return takeBackupReceiptPhotoSet();
  }

  static Future<ReceiptPickedPhotoSet> takeBackupReceiptPhotoSet() async {
    // Do not ask the picker to recompress the only high-quality source. Saved
    // proof size is chosen later, after review, without replacing this source.
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      requestFullMetadata: false,
    );
    return ReceiptPickedPhotoSet.fromFiles([photo]);
  }

  static Future<ReceiptPickedPhotoSet> chooseReceiptImageSet() async {
    final platformPicker = ImagePickerPlatform.instance;
    if (platformPicker is ImagePickerAndroid) {
      // Use Android's direct photo-picker contract. Leaving this disabled sends
      // modern Samsung devices through the ACTION_GET_CONTENT compatibility
      // activity, which can leave its Done surface visible while it prepares
      // the result instead of returning promptly to Maintainiac's handoff.
      platformPicker.useAndroidPhotoPicker = true;
    }
    final images = await _picker.pickMultiImage(requestFullMetadata: false);
    return ReceiptPickedPhotoSet.fromFiles(images);
  }
}
