import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  test('photo review bottom controls stay capped by mode', () async {
    final reviewScreen = await readReceiptPhotoReviewScreenSource();
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
    final previewControls =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
        ).readAsString();
    final commonControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart',
    ).readAsString();
    final orderControls =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_order_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_order_thumbnail.dart',
        ).readAsString();

    expect(
      reviewScreen,
      contains('double _reviewBottomControlsMaxHeight(BuildContext context)'),
    );
    expect(reviewScreen, contains('_ReceiptReviewMode.preview => .22'));
    expect(
      reviewScreen,
      contains('relying on a hidden scroll-only continuation path'),
    );
    expect(reviewScreen, contains('_ReceiptReviewMode.crop => 78.0'));
    expect(reviewScreen, contains('_ReceiptReviewMode.order => .18'));
    expect(reviewScreen, contains('_ReceiptReviewMode.stitch => .20'));
    expect(reviewScreen, contains('_ReceiptReviewMode.dataSaver => .20'));
    expect(
      reviewScreen,
      contains(
        '_ReceiptReviewMode.preview => _photoPaths.length > 1 ? 188.0 : 166.0',
      ),
    );
    expect(reviewScreen, contains('_ReceiptReviewMode.dataSaver => 168.0'));
    expect(
      reviewScreen,
      contains('return proportional < absolute ? proportional : absolute;'),
    );
    expect(
      reviewScreen,
      contains('_controlsVisible ? _reviewSurfaceBottomPadding(context) : 0'),
    );
    expect(reviewScreen, contains('_reviewPreviewCacheWidth(context)'));
    expect(reviewScreen, contains('targetWidth.clamp(900, 2600)'));
    expect(reviewScreen, contains('filterQuality: FilterQuality.medium'));
    expect(reviewScreen, contains('gaplessPlayback: true'));
    expect(orderControls, contains('cacheWidth: 180'));
    expect(orderControls, contains('cacheHeight: 240'));
    expect(orderControls, contains('filterQuality: FilterQuality.low'));
    expect(reviewScreen, contains('TransformationController()'));
    expect(reviewScreen, contains('onDoubleTapDown'));
    expect(reviewScreen, contains('onDoubleTap: _togglePhotoPreviewZoom'));
    expect(reviewScreen, contains('_ReceiptShowReviewControlsButton'));
    expect(
      reviewScreen,
      contains('transformationController: _photoPreviewTransformController'),
    );
    expect(reviewScreen, contains('boundaryMargin: const EdgeInsets.all(48)'));
    expect(reviewScreen, contains('void _togglePhotoPreviewZoom()'));
    expect(reviewScreen, contains('void _resetPhotoPreviewZoom()'));
    expect(commonControls, contains('minimumSize: const Size(0, 32)'));
    expect(previewControls, contains('height: 32'));
    expect(previewControls, contains('minimumSize: const Size(0, 38)'));
    expect(previewControls, contains('const SizedBox(height: 7)'));
    expect(
      reviewScreen,
      contains('_photoPreviewTransformController.value = Matrix4.identity()'),
    );
    expect(controls, contains('Scrollbar('));
    expect(controls, contains('thumbVisibility: true'));
    expect(controls, contains('trackVisibility: true'));
    expect(controls, contains('enabled: !openingCamera && !savingPhotos'));
    expect(controls, contains('previewEnabled: !openingCamera && !savingPhotos'));
  });

  test('photo review tray uses explicit long-receipt language', () async {
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
    final previewControls =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
        ).readAsString();
    final commonControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart',
    ).readAsString();
    final orderControls =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_order_controls.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_order_thumbnail.dart',
        ).readAsString();
    final contextControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart',
    ).readAsString();
    final modeControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart',
    ).readAsString();
    final sectionLabels = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart',
    ).readAsString();
    final topBar = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart',
    ).readAsString();
    expect(previewControls, contains('class _ReceiptPreviewPrimaryRow'));
    expect(previewControls, contains('mainAxisSize: MainAxisSize.min'));
    expect(previewControls, contains('const SizedBox(height: 7)'));
    expect(controls, contains('Flexible('));
    expect(controls, contains('fit: FlexFit.loose'));
    expect(controls, contains('SingleChildScrollView('));
    expect(commonControls, contains('class _ReceiptNextReviewLabel'));
    expect(commonControls, contains('class _ReceiptStackedButtonLabel'));
    expect(previewControls, contains('Tooltip('));
    expect(previewControls, contains('Semantics('));
    expect(previewControls, contains('message: savingPhotos'));
    expect(
      previewControls,
      contains('Add another receipt photo if the receipt continues'),
    );
    expect(controls, contains('final interactionLocked = openingCamera || savingPhotos;'));
    expect(previewControls, contains('OutlinedButton.icon'));
    expect(
      previewControls,
      contains('_ReceiptPhotoSectionLabels.retakeLabel'),
    );
    expect(
      previewControls,
      contains('_ReceiptPhotoSectionLabels.retakeSemanticLabel'),
    );
    expect(previewControls, contains('final addPhotoTooltip ='));
    expect(previewControls, contains('label: addPhotoTooltip'));
    expect(previewControls, contains('message: retakeSemanticLabel'));
    expect(previewControls, contains('label: retakeSemanticLabel'));
    expect(previewControls, contains("'Opening receipt details'"));
    expect(previewControls, contains('onPressed: savingPhotos ? null : onContinue'));
    expect(controls, contains('onTap: interactionLocked'));
    expect(controls, contains('onAddPhoto: interactionLocked ? null : onAddPhoto'));
    expect(controls, contains('onOrder: interactionLocked'));
    expect(controls, contains('onMatch: interactionLocked'));
    expect(controls, contains('onCrop: interactionLocked'));
    expect(commonControls, contains("'Preparing receipt details'"));
    expect(commonControls, contains("const Text('Preparing')"));
    expect(commonControls, isNot(contains("'Preparing receipt review'")));
    expect(controls, contains(': continueLabel'));
    expect(previewControls, contains(r"'Photo $current of $total'"));
    expect(previewControls, isNot(contains(r"'$current/$total'")));
    expect(previewControls, contains("label: 'Add Another Photo'"));
    expect(previewControls, contains("'Photo \$current of \$total'"));
    expect(commonControls, contains("'Add Another Photo' =>"));
    expect(
      commonControls,
      contains('Add another receipt photo only if this receipt continues'),
    );
    expect(commonControls, contains("'Proof' => 'Preview saved proof size'"));
    expect(previewControls, contains('class _ReceiptMultiPhotoActionRail'));
    expect(previewControls, contains('Add Another Photo'));
    expect(previewControls, contains("label: 'Proof'"));
    expect(previewControls, contains("? 'Add Bottom Section'"));
    expect(
      previewControls,
      contains(
        "'Add bottom receipt section and repeat 3-5 readable lines in the top ghost slice'",
      ),
    );
    expect(
      commonControls,
      isNot(contains("'Space' => 'Preview saved receipt size'")),
    );
    expect(previewControls, isNot(contains("label: 'Proof Size'")));
    expect(previewControls, isNot(contains("label: 'Add Section'")));
    expect(topBar, contains('Add Another Photo'));
    expect(topBar, contains('Review Receipt Photo'));
    expect(previewControls, contains('Crop Current'));
    expect(
      controls,
      contains(
        'Photo captured locally. Use this photo, retake it, or add another photo if the receipt continues.',
      ),
    );
    expect(
      controls,
      contains('if (coverageDecision.shouldPromptForMorePhotos)'),
    );
    expect(
      controls,
      contains(
        'add the bottom receipt section and repeat 3-5 readable lines in the top ghost slice',
      ),
    );
    expect(controls, contains('or use this photo only if '));
    expect(
      controls,
      contains(
        'it already shows the full receipt.',
      ),
    );
    expect(controls, contains('Saved locally for recovery.'));
    expect(controls, contains('captureSurface.startsWith'));
    expect(controls, contains('maintainiac_native_receipt_camera'));
    expect(controls, contains('String get captureMemoryPolicyCopy'));
    expect(controls, contains("diagnostics['nativeCaptureMemoryPolicy']"));
    expect(controls, contains("diagnostics['storageConstrained'] == true"));
    expect(
      controls,
      contains(
        'Maintainiac reads the full captured photo first; smaller saved copies are only for storage and recovery.',
      ),
    );
    expect(
      controls,
      contains("return 'Use Receipt';"),
    );
    expect(commonControls, contains("primary: 'Add'"));
    expect(commonControls, contains("secondary: 'Bottom Section'"));
    expect(
      contextControls,
      contains(
        'Use this photo, or add another photo only if the receipt continues.',
      ),
    );
    expect(
      contextControls,
      contains(
        'Use this photo only if the store, date, total, and item prices are readable.',
      ),
    );
    expect(sectionLabels, contains('This should be the top of the receipt.'));
    expect(modeControls, contains('Photo Order'));
    expect(modeControls, contains('Match Photos'));
    expect(modeControls, contains('final bool enabled;'));
    expect(modeControls, contains('enabled ? () => onSelected(_ReceiptReviewMode.preview) : null'));
    expect(modeControls, contains('enabled ? () => onSelected(_ReceiptReviewMode.crop) : null'));
    expect(modeControls, contains('enabled && photoCount > 1'));
    expect(modeControls, contains('onPressed: previewEnabled ? onBackToPreview : null'));
    expect(sectionLabels, contains('Receipt Sections'));
    expect(sectionLabels, contains(r'Section ${index + 1} of $total'));
    expect(sectionLabels, contains('Add Next Receipt Photo'));
    expect(
      sectionLabels,
      contains('Add another photo only if the receipt continues.'),
    );
    expect(sectionLabels, contains('Add Another Photo'));
    expect(contextControls, contains('Add Another Photo'));
    expect(contextControls, contains('canRemove && !openingCamera ? onRemove : null'));
    expect(orderControls, contains('final interactionLocked = openingCamera;'));
    expect(orderControls, contains('onTap: interactionLocked ? null : () => onPhotoSelected(index)'));
    expect(orderControls, contains('canMoveEarlier && !interactionLocked'));
    expect(orderControls, contains('canMoveLater && !interactionLocked'));
    expect(controls, contains('disabled: openingCamera || savingPhotos'));
    expect(controls, isNot(contains('Add Another Receipt Photo')));
    expect(controls, isNot(contains('Read receipt')));
    expect(controls, isNot(contains('Read Receipt')));
    expect(controls, isNot(contains('Use This Photo')));
    expect(controls, isNot(contains('Saved copy')));
    expect(controls, isNot(contains('Saved Copy')));
    expect(
      previewControls,
      contains('onPressed: openingCamera'),
    );
    expect(
      previewControls,
      contains(': () => onModeChanged(_ReceiptReviewMode.crop)'),
    );
    expect(
      previewControls,
      contains(': () => onModeChanged(_ReceiptReviewMode.dataSaver)'),
    );
  });

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
    final dataSaverPanel = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_data_saver_panel.dart',
    ).readAsString();
    final models = await readReceiptCaptureModelsSource();
    expect(controls, contains('Opening receipt details'));
    expect(controls, contains('Check Photo Match'));
    expect(cropAndProofControls, contains('Receipt Details And Saved Proof'));
    expect(cropAndProofControls, contains('Use Clear Photo'));
    expect(cropAndProofControls, contains('Save Small Copy'));
    expect(controls, contains('selectedReviewGuidance'));
    expect(controls, contains('selectedReviewAction'));
    expect(controls, contains('String get multiPhotoMatchStatusCopy'));
    expect(
      controls,
      contains('Use Match Photos to check whether one combined receipt image'),
    );
    expect(controls, contains('Use Receipt will use one combined receipt image.'));
    expect(controls, contains('ordered sections from top to bottom'));
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
    expect(
      dataSaverPanel,
      contains('Receipt assistance uses the clear OCR source first'),
    );
    expect(dataSaverPanel, contains('Proof kept after reading'));
    expect(dataSaverPanel, contains('Backup status'));
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
    expect(sectionLabels, contains('Confirm bottom section, then match.'));
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

    expect(cropper, contains('static const _hitSize = 56.0'));
    expect(cropper, contains('static const _edgeVisibleSize = 8.0'));
    expect(cropper, contains('Semantics('));
    expect(cropper, contains('Move bottom right receipt crop corner'));
    expect(cropControls, contains('class _ReceiptCropInstructionStrip'));
    expect(
      cropControls,
      contains(
        'Drag the yellow edges until the full receipt is inside the frame.',
      ),
    );
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
