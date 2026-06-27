import 'package:image_picker/image_picker.dart';

class ReceiptPickedPhotoSet {
  const ReceiptPickedPhotoSet(this.paths);

  factory ReceiptPickedPhotoSet.fromFiles(Iterable<XFile?> files) {
    return ReceiptPickedPhotoSet(
      files
          .whereType<XFile>()
          .map((file) => file.path.trim())
          .where((path) => path.isNotEmpty)
          .toList(growable: false),
    );
  }

  final List<String> paths;

  bool get isEmpty => paths.isEmpty;
}

class ReceiptImagePicker {
  ReceiptImagePicker._();

  static const receiptCameraImageQuality = 100;
  static final ImagePicker _picker = ImagePicker();

  /// Production receipt capture uses the phone camera/gallery surfaces.
  ///
  /// The custom Flutter camera is kept as a legacy/test surface only. Receipt
  /// flows should enter through this picker so Android stays on the native
  /// camera app and iOS can use native scanner/camera behavior without exposing
  /// raw custom-camera controls to users.
  static Future<ReceiptPickedPhotoSet> takeReceiptPhotoSet() async {
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
