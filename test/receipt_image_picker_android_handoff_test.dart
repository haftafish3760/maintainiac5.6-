import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_image_picker.dart';

void main() {
  late ImagePickerPlatform originalPlatform;

  setUp(() {
    originalPlatform = ImagePickerPlatform.instance;
  });

  tearDown(() {
    ImagePickerPlatform.instance = originalPlatform;
  });

  test('Android photo selection enables the direct photo picker first', () async {
    final platform = _RecordingImagePickerAndroid();
    ImagePickerPlatform.instance = platform;

    final result = await ReceiptImagePicker.chooseReceiptImageSet();

    expect(platform.photoPickerEnabledWhenCalled, isTrue);
    expect(result.paths, ['/tmp/receipt-picker-proof.jpg']);
  });
}

class _RecordingImagePickerAndroid extends ImagePickerAndroid {
  bool? photoPickerEnabledWhenCalled;

  @override
  Future<List<XFile>> getMultiImageWithOptions({
    MultiImagePickerOptions options = const MultiImagePickerOptions(),
  }) async {
    photoPickerEnabledWhenCalled = useAndroidPhotoPicker;
    return [XFile('/tmp/receipt-picker-proof.jpg')];
  }
}
