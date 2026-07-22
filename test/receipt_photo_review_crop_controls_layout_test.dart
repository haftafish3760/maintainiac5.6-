import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
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
    final topBar = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart',
    ).readAsString();
    final editActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_image_edit_actions.dart',
    ).readAsString();
    final surfaces = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_surfaces.dart',
    ).readAsString();

    expect(cropper, contains('static const _hitSize = 56.0'));
    expect(cropper, contains('static const _edgeVisibleSize = 8.0'));
    expect(cropper, contains('Semantics('));
    expect(cropper, contains('Move bottom right receipt crop corner'));
    expect(cropper, contains('suggestedNormalizedCrop'));
    expect(cropper, contains('_suggestedCropRect('));
    expect(
      editActions,
      contains('suggestReceiptCropNormalizedForDecodedImage'),
    );
    expect(
      editActions,
      contains("['autoCropSuggestionEnabled'] !=\n        false"),
    );
    expect(
      surfaces,
      contains('suggestedNormalizedCrop: _suggestedCropNormalized'),
    );
    expect(cropControls, isNot(contains('class _ReceiptCropInstructionStrip')));
    expect(topBar, contains('Crop receipt — drag the yellow edges'));
    expect(
      cropControls,
      contains('label: Text(cropProcessing ? \'Cropping\' : \'Apply Crop\')'),
    );
    expect(controls, contains('String get editedPhotoCopyForSelectedPhoto'));
    expect(controls, contains("diagnostics['userEditedPhoto'] != true"));
    expect(controls, contains("'manual_crop' => 'Crop edit'"));
    expect(controls, contains("'manual_rotate' => 'Rotation edit'"));
    expect(
      controls,
      contains('This edited copy is the one Maintainiac will read.'),
    );
  });
}
