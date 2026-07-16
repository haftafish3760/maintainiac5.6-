import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all non-native receipt acquisition uses one provenance-safe stager', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_acquired_photo_staging.dart',
    ).readAsStringSync();

    expect(source, contains('class ReceiptAcquiredPhotoStaging'));
    expect(source, contains('ReceiptNativeCaptureStaging'));
    expect(source, contains('originalPhotoPaths: sourcePaths'));
    expect(source, contains("'captureFlow': captureFlow"));
    expect(source, contains(r'$temporaryIdPrefix-$index'));
    expect(source, contains('That receipt photo could not be kept safely.'));
  });
}
