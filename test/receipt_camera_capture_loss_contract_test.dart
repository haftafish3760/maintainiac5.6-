import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native capture never silently continues after its photo disappears', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
    ).readAsStringSync();

    expect(source, contains('if (!staged.hasPhotos) {'));
    expect(
      source,
      contains('That receipt photo was no longer available. Retake it'),
    );
    expect(
      source,
      contains('if (staged.photoPaths.length < capturedPhotoCount) {'),
    );
    expect(
      source,
      contains('One or more receipt photos could not be kept.'),
    );
  });
}
