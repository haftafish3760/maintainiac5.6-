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
      await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart',
      ).readAsString(),
      await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
      ).readAsString(),
      await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart',
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
    expect(controls, contains('Review Photos'));
    expect(
      cropAndProofControls,
      contains('Save device space without losing the original reading source'),
    );
    expect(cropAndProofControls, contains('Use Clear Photo'));
    expect(cropAndProofControls, contains('Save Small Copy'));
    expect(controls, contains('selectedReviewGuidance'));
    expect(controls, isNot(contains('selectedReviewAction')));
    expect(controls, isNot(contains('String get multiPhotoMatchStatusCopy')));
    expect(controls, isNot(contains('Check the order, then continue.')));
    expect(controls, isNot(contains('Read First')));
    expect(models, contains("readIntoForm('Ready for receipt review')"));
    expect(models, isNot(contains("readIntoForm('Read into form')")));
    expect(controls, contains('Use this photo'));
    expect(
      controls,
      contains(
        'Photo captured locally. Use this photo, retake it, or add another photo if the receipt continues.',
      ),
    );
    expect(dataSaverPanel, contains('Receipt Proof Storage'));
    expect(dataSaverPanel, contains('Uses clear photo first'));
    expect(dataSaverPanel, contains("value: 'Uses clear photo first'"));
    expect(dataSaverPanel, contains('Image kept after reading'));
    expect(dataSaverPanel, contains('Backup preference'));
    expect(
      dataSaverPanel,
      contains('This receipt stays on your device until you turn backup on'),
    );
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
      contains('Continue when the sections are in the right order.'),
    );
  });

  test('crop mode keeps receipt edges touchable and plainly labeled', () async {
    final cropper =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_edge_cropper.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_edge_cropper_handles.dart',
        ).readAsString();
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
    final cropControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_crop_controls.dart',
    ).readAsString();
    final editActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart',
    ).readAsString();

    expect(cropper, contains('static const _hitSize = 56.0'));
    expect(cropper, contains('static const _edgeVisibleSize = 8.0'));
    expect(cropper, contains('Semantics('));
    expect(cropper, contains('Move bottom right receipt crop corner'));
    expect(cropper, contains('double _cropViewportScale('));
    expect(cropper, contains('.clamp(1.0, 3.0)'));
    expect(cropper, contains('details.delta.dx / viewportScale'));
    expect(cropper, contains('details.delta.dy / viewportScale'));
    expect(cropControls, contains('class _ReceiptStraightenSlider'));
    expect(cropControls, contains('receipt-review-straighten-slider'));
    expect(cropControls, contains('The crop frame stays fixed.'));
    expect(cropControls, isNot(contains('Move Left')));
    expect(cropControls, isNot(contains('Move Right')));
    expect(controls, isNot(contains('editedPhotoCopyForSelectedPhoto')));
    expect(
      editActions,
      contains("updatedDiagnostics['userEditedPhoto'] = true"),
    );
    expect(editActions, contains("editAction: 'manual_crop'"));
    expect(editActions, contains("editAction: 'manual_rotate'"));
    expect(
      controls,
      isNot(contains('This edited copy is the one Maintainiac will read.')),
    );
  });
}
