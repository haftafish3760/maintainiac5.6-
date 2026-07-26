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
    final images = await _picker.pickMultiImage(requestFullMetadata: false);
    return ReceiptPickedPhotoSet.fromFiles(images);
  }
}
