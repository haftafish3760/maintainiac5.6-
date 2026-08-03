import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every receipt reaches a dedicated saved-image preview before handoff', () {
    final saveActions = File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsStringSync();
    final reviewBuild = File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart',
    ).readAsStringSync();
    final panel =
        File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart',
        ).readAsStringSync() +
        File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_details.dart',
        ).readAsStringSync();

    expect(
      saveActions,
      contains('Every receipt gets a visible saved-image choice'),
    );
    expect(saveActions, contains('_ReceiptReviewMode.dataSaver'));
    expect(reviewBuild, contains('_ReceiptSavedImageSideRail'));
    expect(reviewBuild, contains('_ReceiptSavedImageContinueBar'));
    expect(panel, contains('Save space for this receipt'));
    expect(panel, contains('Use This Saved Image'));
    expect(panel, contains('ReceiptDataSaverLevel.light'));
    expect(panel, contains('ReceiptDataSaverLevel.maximum'));
    expect(panel, contains('ReceiptDataSaverLevel.original'));
    expect(panel, isNot(contains('TextOverflow.ellipsis')));
    expect(panel, isNot(contains('showModalBottomSheet')));
  });
}
