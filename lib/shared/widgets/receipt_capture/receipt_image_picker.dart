import 'package:image_picker/image_picker.dart';

class ReceiptImagePicker {
  ReceiptImagePicker._();

  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> takeReceiptPhoto() {
    return _picker.pickImage(source: ImageSource.camera, imageQuality: 100);
  }

  static Future<XFile?> chooseReceiptImage() {
    return _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
  }
}
