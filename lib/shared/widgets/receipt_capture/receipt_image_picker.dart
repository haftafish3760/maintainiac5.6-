import 'package:image_picker/image_picker.dart';

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

  static const receiptCameraImageQuality = 100;
  static final ImagePicker _picker = ImagePicker();

  /// Production receipt capture opens the phone's system camera first, then
  /// returns to Maintainiac for numbered review and long-receipt stitching.
  static Future<ReceiptPickedPhotoSet> takeReceiptPhotoSet() async {
    return _takeSystemCameraReceiptPhotoSet();
  }

  /// Compatibility entry point for legacy callers. It uses the same phone
  /// camera path as the primary receipt flow.
  static Future<ReceiptPickedPhotoSet> takeBackupReceiptPhotoSet() async {
    return _takeSystemCameraReceiptPhotoSet();
  }

  static Future<ReceiptPickedPhotoSet>
  _takeSystemCameraReceiptPhotoSet() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: receiptCameraImageQuality,
      requestFullMetadata: false,
    );
    return ReceiptPickedPhotoSet.fromFiles([photo]);
  }

  static Future<ReceiptPickedPhotoSet> chooseReceiptImageSet() async {
    final images = await _picker.pickMultiImage(
      imageQuality: receiptCameraImageQuality,
      requestFullMetadata: false,
    );
    return ReceiptPickedPhotoSet.fromFiles(images);
  }
}
