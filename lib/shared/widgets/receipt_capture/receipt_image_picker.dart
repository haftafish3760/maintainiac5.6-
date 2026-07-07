import 'package:image_picker/image_picker.dart';

class ReceiptPickedPhotoSet {
  ReceiptPickedPhotoSet(Iterable<String> paths)
    : paths = List.unmodifiable(paths);

  factory ReceiptPickedPhotoSet.fromFiles(Iterable<XFile?> files) {
    return ReceiptPickedPhotoSet(
      files
          .whereType<XFile>()
          .map((file) => file.path.trim())
          .where((path) => path.isNotEmpty),
    );
  }

  final List<String> paths;

  bool get isEmpty => paths.isEmpty;
}

class ReceiptImagePicker {
  ReceiptImagePicker._();

  static const receiptCameraImageQuality = 100;
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
