import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt review keeps retake add crop and continue available', () {
    final primary = File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
    ).readAsStringSync();
    final tray = File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
    ).readAsStringSync();

    expect(primary, contains('onRetake'));
    expect(primary, contains('onAddPhoto'));
    expect(primary, contains('onCrop'));
    expect(primary, contains('onContinue'));
    expect(primary, contains("message: 'Crop receipt photo'"));
    expect(tray, contains('onCrop: hasMultiplePhotos || interactionLocked'));
    expect(tray, contains('onModeChanged(_ReceiptReviewMode.crop)'));
  });
}
