import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers/receipt_camera_capture_layout_source_readers.dart';

void main() {
  test('add another photo opens capture without an intermediate guide', () async {
    final captureActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
    ).readAsString();

    expect(
      captureActions,
      contains(
        'alignmentGuidePhotoPath: guidePhotoPath,\n      showAlignmentGuide: false,',
      ),
    );
    expect(captureActions, contains('bool showAlignmentGuide = true'));
    expect(
      captureActions,
      contains('alignmentGuidePhotoPath != null && showAlignmentGuide'),
    );
  });

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
    final uiConfig = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_ui_config.dart',
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
    expect(
      reviewScreen,
      contains('widget.uiConfig.previewControlsHeightFraction'),
    );
    expect(
      reviewScreen,
      contains('relying on a hidden scroll-only continuation path'),
    );
    expect(reviewScreen, contains('widget.uiConfig.cropControlsHeight'));
    expect(reviewScreen, contains('_ReceiptReviewMode.order => .18'));
    expect(reviewScreen, contains('_ReceiptReviewMode.stitch => .20'));
    expect(reviewScreen, contains('_ReceiptReviewMode.dataSaver => .20'));
    expect(
      reviewScreen,
      contains('widget.uiConfig.previewControlsMultiPhotoHeight'),
    );
    expect(reviewScreen, contains('widget.uiConfig.dataSaverControlsHeight'));
    expect(
      reviewScreen,
      contains('return proportional < absolute ? proportional : absolute;'),
    );
    expect(
      reviewScreen,
      contains('backgroundColor: widget.uiConfig.previewBackgroundColor'),
    );
    expect(reviewScreen, contains('body: SafeArea(\n          child: Column('));
    expect(reviewScreen, contains('Expanded(\n                child: Stack('));
    expect(reviewScreen, isNot(contains('_reviewSurfaceBottomPadding')));
    expect(uiConfig, contains('class ReceiptPhotoReviewUiConfig'));
    expect(uiConfig, isNot(contains('keepControlsOutsidePreview')));
    expect(uiConfig, contains('String addPhotoLabel'));
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
    expect(
      reviewScreen,
      contains('onHideControls: _openingCamera || _savingPhotos'),
    );
    expect(
      reviewScreen,
      contains('final interactionLocked = _openingCamera || _savingPhotos;'),
    );
    expect(
      reviewScreen,
      contains('if (interactionLocked && _controlsVisible) return;'),
    );
    expect(reviewScreen, contains('if (interactionLocked) {'));
    expect(reviewScreen, contains('_controlsVisible = true;'));
    expect(commonControls, contains('minimumSize: const Size(0, 32)'));
    expect(previewControls, contains('height: 32'));
    expect(previewControls, contains('minimumSize: const Size(0, 38)'));
    expect(previewControls, contains('SizedBox(height: compact ? 5 : 7)'));
    expect(
      previewControls,
      contains('_ReceiptPhotoCountBadge(current: current, total: total)'),
    );
    expect(
      reviewScreen,
      contains('_photoPreviewTransformController.value = Matrix4.identity()'),
    );
    expect(controls, contains('Scrollbar('));
    expect(controls, contains('thumbVisibility: true'));
    expect(controls, contains('trackVisibility: true'));
    expect(controls, contains('enabled: !openingCamera && !savingPhotos'));
    expect(
      controls,
      contains('previewEnabled: !openingCamera && !savingPhotos'),
    );
    expect(controls, contains('enabled: !openingCamera && !savingPhotos'));
  });

  test('photo review tray uses explicit long-receipt language', () async {
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
    final cropAndProofControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_crop_and_proof_controls.dart',
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
    expect(previewControls, contains('SizedBox(height: compact ? 5 : 7)'));
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
    expect(
      controls,
      contains('final interactionLocked = openingCamera || savingPhotos;'),
    );
    expect(previewControls, contains('OutlinedButton.icon'));
    expect(previewControls, contains('_ReceiptPhotoSectionLabels.retakeLabel'));
    expect(
      previewControls,
      contains('_ReceiptPhotoSectionLabels.retakeSemanticLabel'),
    );
    expect(previewControls, contains('final addPhotoTooltip ='));
    expect(previewControls, contains('label: addPhotoTooltip'));
    expect(previewControls, contains('message: retakeSemanticLabel'));
    expect(previewControls, contains('label: retakeSemanticLabel'));
    expect(previewControls, contains("'Opening receipt details'"));
    expect(
      previewControls,
      contains('onPressed: savingPhotos ? null : onContinue'),
    );
    expect(controls, contains('onTap: interactionLocked'));
    expect(
      controls,
      contains('onAddPhoto: interactionLocked ? null : onAddPhoto'),
    );
    expect(controls, contains('onOrder: interactionLocked'));
    expect(controls, contains('onMatch: interactionLocked'));
    expect(controls, contains('onCrop: interactionLocked'));
    expect(controls, contains('selected: index == effectiveSelectedIndex'));
    expect(commonControls, contains("'Opening receipt details'"));
    expect(commonControls, contains("const Text('Opening')"));
    expect(commonControls, isNot(contains("'Opening receipt review'")));
    expect(controls, contains(': continueLabel'));
    expect(previewControls, contains('retakeSemanticLabel'));
    expect(previewControls, isNot(contains(r"'$current/$total'")));
    expect(previewControls, contains('onAddPhoto'));
    expect(previewControls, contains('retakeLabel'));
    expect(commonControls, contains("'Add Another Photo' =>"));
    expect(
      commonControls,
      contains('Add another receipt photo only if this receipt continues'),
    );
    expect(commonControls, contains("'Proof' => 'Preview saved proof size'"));
    expect(previewControls, contains('class _ReceiptMultiPhotoActionRail'));
    expect(previewControls, contains('onAddPhoto'));
    expect(previewControls, contains('class _ReceiptSinglePhotoActionRow'));
    expect(previewControls, contains('label: Text(strings.cropReceiptPhoto)'));
    expect(previewControls, isNot(contains('label: strings.savedProof')));
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
    expect(
      topBar,
      contains(
        'if (total > 1)\n                const PopupMenuItem(\n                  value: _ReceiptReviewMenuAction.remove,',
      ),
    );
    expect(
      reviewScreen,
      contains('final effectiveSelectedIndex = _photoPaths.isEmpty'),
    );
    expect(reviewScreen, contains('current: effectiveSelectedIndex + 1'));
    expect(topBar, contains('Review Receipt Photo'));
    expect(previewControls, contains('strings.cropReceiptPhoto'));
    expect(controls, contains('selectedIndex: effectiveSelectedIndex'));
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
    expect(controls, contains('it already shows the full receipt.'));
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
    expect(controls, contains("return 'Use Receipt';"));
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
    expect(
      modeControls,
      contains('enabled ? () => onSelected(_ReceiptReviewMode.preview) : null'),
    );
    expect(
      modeControls,
      contains('enabled ? () => onSelected(_ReceiptReviewMode.crop) : null'),
    );
    expect(modeControls, contains('enabled && photoCount > 1'));
    expect(
      modeControls,
      contains('onPressed: previewEnabled ? onBackToPreview : null'),
    );
    expect(sectionLabels, contains('Receipt Sections'));
    expect(sectionLabels, contains(r'Section ${index + 1} of $total'));
    expect(sectionLabels, contains('Add Next Receipt Photo'));
    expect(
      sectionLabels,
      contains('Add another photo only if the receipt continues.'),
    );
    expect(sectionLabels, contains('Add Another Photo'));
    expect(contextControls, contains('Add Another Photo'));
    expect(
      contextControls,
      contains('canRemove && !openingCamera ? onRemove : null'),
    );
    expect(orderControls, contains('final interactionLocked = openingCamera;'));
    expect(
      orderControls,
      contains(
        'onTap: interactionLocked ? null : () => onPhotoSelected(index)',
      ),
    );
    expect(orderControls, contains('canMoveEarlier && !interactionLocked'));
    expect(orderControls, contains('canMoveLater && !interactionLocked'));
    expect(
      controls,
      contains('disabled: openingCamera || effectiveSavingPhotos'),
    );
    expect(cropAndProofControls, contains('final bool enabled;'));
    expect(
      cropAndProofControls,
      contains('onTap: enabled ? () => onSelected(level) : null'),
    );
    expect(controls, isNot(contains('Add Another Receipt Photo')));
    expect(controls, isNot(contains('Read receipt')));
    expect(controls, isNot(contains('Read Receipt')));
    expect(controls, isNot(contains('Use This Photo')));
    expect(controls, isNot(contains('Saved copy')));
    expect(controls, isNot(contains('Saved Copy')));
    expect(previewControls, contains('onPressed: openingCamera'));
    expect(
      previewControls,
      contains(': () => onModeChanged(_ReceiptReviewMode.crop)'),
    );
    expect(
      previewControls,
      isNot(contains(': () => onModeChanged(_ReceiptReviewMode.dataSaver)')),
    );
  });
}
