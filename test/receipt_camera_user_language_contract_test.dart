import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('camera and review status copy avoids OCR jargon', () {
    for (final path in [
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraDiagnosticsLabels.kt',
      'ios/Runner/ReceiptCameraViewControllerLabels.swift',
      'ios/Runner/ReceiptCameraViewControllerSettingsCopy.swift',
      'lib/shared/widgets/receipt_capture/receipt_capture_review_result_section_order_review.dart',
      'lib/shared/widgets/receipt_capture/receipt_native_saved_photo_warning_details.dart',
    ]) {
      expect(File(path).readAsStringSync(), isNot(contains('OCR')));
    }
    final localizedReviewCopy = File(
      'lib/shared/localization/maintaniac_localizations.dart',
    ).readAsStringSync();
    expect(
      localizedReviewCopy,
      contains('Maintainiac reads the clearest available receipt photo first.'),
    );
    expect(
      localizedReviewCopy,
      isNot(contains('Receipt assistance uses the clear OCR source first.')),
    );
  });
}
