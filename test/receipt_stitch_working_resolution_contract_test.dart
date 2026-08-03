import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stitching bounds private camera working copies before crop and combine',
      () async {
    final api = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_api.dart',
    ).readAsString();
    final resize = await File(
      'lib/shared/widgets/receipt_capture/receipt_image_processor_resize_helpers.dart',
    ).readAsString();

    expect(api, contains('final targetWidth = _stitchTargetWidth(inputPaths.length);'));
    expect(api, contains('final workingWidth = _stitchWorkingWidth(targetWidth);'));
    expect(api, contains('_resizeForStitchWorkingWidth(image, workingWidth)'));
    expect(api, contains('_autoCropReceipt(workingImage)'));
    expect(
      api,
      contains('The original user photos remain unchanged.'),
      reason: 'The performance bound must not silently alter saved originals.',
    );
    expect(resize, contains('int _stitchWorkingWidth(int targetWidth) => targetWidth + 400;'));
    expect(resize, contains('if (source.width <= workingWidth) return source;'));
  });
}
