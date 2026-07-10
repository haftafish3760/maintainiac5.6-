import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt review keeps actions outside the photo workspace', () async {
    final config = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_ui_config.dart',
    ).readAsString();
    final build = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart',
    ).readAsString();

    expect(config, isNot(contains('keepControlsOutsidePreview')));
    expect(build, contains('Expanded('));
    expect(build, contains('child: _buildReviewBottomControls(photoPath)'));
  });
}
