import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt review exposes named long-receipt sections', () async {
    final labels = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart',
    ).readAsString();
    final strip = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_strip.dart',
    ).readAsString();
    final topBar = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart',
    ).readAsString();

    expect(labels, contains("'Top'"));
    expect(labels, contains("'Middle'"));
    expect(labels, contains("'Bottom'"));
    expect(labels, contains('countLabel'));
    expect(strip, contains('_ReceiptPhotoSectionLabels.label'));
    expect(strip, contains('receipt section'));
    expect(topBar, contains('sectionLabel'));
  });
}
