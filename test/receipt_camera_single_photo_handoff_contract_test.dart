import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a normal single receipt opens details before slow prep work', () async {
    final source = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsString();

    expect(
      source,
      contains('if (_canOpenSinglePhotoReceiptDetailsImmediately) {'),
    );
    expect(source, contains('_openSinglePhotoReceiptDetailsImmediately();'));
    expect(
      source.indexOf('_openSinglePhotoReceiptDetailsImmediately();'),
      lessThan(source.indexOf('_updateReviewState(() => _savingPhotos = true);')),
    );
    expect(
      source,
      contains("'receiptReviewOpeningRoute': 'single_photo_details_immediate'"),
    );
    expect(
      source,
      contains("'receiptPreparationOwner': 'receipt_reader_after_form_open'"),
    );
  });
}
