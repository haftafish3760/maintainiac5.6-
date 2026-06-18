import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt capture exposes camera help and long receipt guidance', () async {
    final settingsSheet = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
    ).readAsString();
    final helpSheet = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart',
    ).readAsString();
    final cameraHints = await File(
      'lib/shared/widgets/receipt_capture/receipt_camera_hints.dart',
    ).readAsString();
    final reviewHint = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_long_receipt_hint.dart',
    ).readAsString();
    final reviewTopBar = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart',
    ).readAsString();
    final reviewActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsString();
    final reviewStrip = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_strip.dart',
    ).readAsString();

    expect(settingsSheet, contains('Camera Help'));
    expect(helpSheet, contains('Receipt Camera Help'));
    expect(helpSheet, contains('Live Guidance'));
    expect(helpSheet, contains('Best Shot'));
    expect(helpSheet, contains('Long Receipts'));
    expect(cameraHints, contains('Long receipt: use sections'));
    expect(reviewHint, contains('Add more photos before saving'));
    expect(reviewTopBar, contains('sectionLabel'));
    expect(reviewTopBar, contains('Move Earlier'));
    expect(reviewTopBar, contains('Move Later'));
    expect(reviewActions, contains('_moveCurrentPhoto'));
    expect(reviewStrip, contains('receipt section'));
  });
}
