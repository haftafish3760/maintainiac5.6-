import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'saved image choice is visible for every receipt and starts from last choice',
    () async {
      final saveActions = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
      ).readAsString();
      final savedImagePanel =
          await File(
            'lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart',
          ).readAsString() +
          await File(
            'lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_details.dart',
          ).readAsString();

      expect(
        saveActions,
        contains('Every receipt gets a visible saved-image choice'),
        reason: 'A person must preview the saved image for every receipt.',
      );
      expect(
        saveActions,
        isNot(contains('settings.defaultDataSaverUsesDeviceRecommendation')),
        reason: 'A remembered default must not skip the preview step.',
      );
      expect(saveActions, contains('await settings.setDefaultDataSaverLevel('));
      expect(savedImagePanel, contains('_ReceiptSavedImageSideRail'));
      expect(savedImagePanel, contains('Save space for this receipt'));
      expect(
        savedImagePanel,
        contains("saving ? 'Getting receipt ready' : 'Continue'"),
      );
      expect(savedImagePanel, contains('ReceiptDataSaverLevel.original'));
      expect(
        savedImagePanel,
        contains('earlyAccessProofCapacityLabel'),
        reason:
            'Every visible image-size option must disclose its 100 MB plan estimate.',
      );
    },
  );
}
