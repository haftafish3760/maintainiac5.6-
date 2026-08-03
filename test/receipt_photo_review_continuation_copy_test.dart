import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  test('receipt review continuation copy explains the next screen', () async {
    final controls = [
      await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
      ).readAsString(),
      await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
      ).readAsString(),
      await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_status.dart',
      ).readAsString(),
    ].join('\n');
    final cropAndProofControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart',
    ).readAsString();
    final dataSaverPanel =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_details.dart',
        ).readAsString();
    final models = await readReceiptCaptureModelsSource();
    expect(controls, contains('Opening receipt details'));
    expect(controls, contains("return 'Continue';"));
    expect(
      cropAndProofControls,
      contains('Save device space without losing the original reading source'),
    );
    expect(cropAndProofControls, contains('Use Clear Photo'));
    expect(cropAndProofControls, contains('Save Small Copy'));
    expect(controls, contains('selectedReviewGuidance'));
    expect(controls, contains('selectedReviewAction'));
    expect(controls, contains('String get multiPhotoMatchStatusCopy'));
    expect(
      controls,
      contains(
        'Continue when these receipt sections are in top-to-bottom order',
      ),
    );
    expect(controls, contains('Your receipt is ready as one combined image.'));
    expect(controls, contains('Keep the photos in order.'));
    expect(controls, isNot(contains('Read First')));
    expect(models, contains("readIntoForm('Ready for receipt review')"));
    expect(models, isNot(contains("readIntoForm('Read into form')")));
    expect(controls, contains('Check the store, date, total, '));
    expect(dataSaverPanel, contains('Receipt Proof Storage'));
    expect(dataSaverPanel, contains('Uses clear photo first'));
    expect(dataSaverPanel, contains("value: 'Uses clear photo first'"));
    expect(dataSaverPanel, contains('Image kept after reading'));
    expect(
      dataSaverPanel,
      contains(
        'This receipt stays on your device until you turn backup on in Receipt settings.',
      ),
    );
    expect(
      dataSaverPanel,
      isNot(contains('CloudBackupStatusSnapshot.notConnected')),
    );
    expect(dataSaverPanel, isNot(contains('Cloud allowance')));
    final sectionLabels = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart',
    ).readAsString();
    expect(sectionLabels, contains('This should be the top of the receipt.'));
    expect(
      sectionLabels,
      contains('This should be the bottom of the receipt.'),
    );
    expect(
      sectionLabels,
      contains(
        'This should continue downward with 3-5 repeated readable lines',
      ),
    );
    expect(
      sectionLabels,
      contains('Confirm the bottom section, then continue.'),
    );
  });
}
