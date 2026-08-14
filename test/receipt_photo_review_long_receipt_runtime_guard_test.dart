import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'long receipt review keeps ordered photos moving when combining is unavailable',
    () async {
      final processor = await File(
        'lib/shared/widgets/receipt_capture/receipt_image_processor.dart',
      ).readAsString();
      final stitchApi =
          await File(
            'lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_api.dart',
          ).readAsString() +
          await File(
            'lib/shared/widgets/receipt_capture/receipt_image_processor_stitch_support.dart',
          ).readAsString();
      final screen = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
      ).readAsString();
      final saveActions = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
      ).readAsString();
      final primaryRow = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
      ).readAsString();

      expect(screen, contains('var _stitchPreviewRequested = false;'));
      expect(screen, contains('return _ReceiptReviewMode.preview;'));
      expect(screen, contains('&&\n        _stitchPreviewRequested)'));
      expect(saveActions, isNot(contains('if (!_stitchPreviewRequested)')));
      expect(
        saveActions,
        isNot(contains('ReceiptPhotoPipelineNextStep.startOrWaitForCombine')),
      );
      expect(saveActions, contains('_ReceiptReviewMode.dataSaver'));
      expect(
        primaryRow,
        isNot(contains('Continue combines the receipt sections')),
      );
      expect(processor, contains("import 'dart:isolate';"));
      expect(processor, contains("import 'dart:isolate';"));
      expect(
        stitchApi,
        contains('Future<ReceiptStitchResult> _runReceiptStitchInBackground('),
      );
    },
  );

  test('manual alignment keeps the touch canvas visible', () async {
    final screen = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    ).readAsString();
    final build = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart',
    ).readAsString();
    final stitchPair =
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_pair_preview.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_photo.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_ghost_preview.dart',
        ).readAsString() +
        await File(
          'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_alignment_controls.dart',
        ).readAsString();
    final stitchActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_actions.dart',
    ).readAsString();
    final guide = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_guide.dart',
    ).readAsString();
    final alignmentActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_actions.dart',
    ).readAsString();
    final captureActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
    ).readAsString();
    final orderActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_order_actions.dart',
    ).readAsString();
    final modeControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_mode_controls.dart',
    ).readAsString();

    expect(
      build,
      isNot(
        contains('if (showingLongReceiptMatch) _buildLongReceiptSideRail()'),
      ),
    );
    expect(build, isNot(contains('if (!showingLongReceiptMatch)')));
    expect(build, contains('child: _buildReviewBottomControls(photoPath)'));
    expect(build, contains('canPop: _closingReview'));
    expect(build, contains('if (!didPop && !_closingReview)'));
    expect(
      build,
      contains('if (widget.uiConfig.showTopBar && !showingLongReceiptMatch)'),
    );
    expect(build, contains('_reviewMode != _ReceiptReviewMode.stitch &&'));
    expect(build, contains('child: _ReceiptStitchBackButton('));
    expect(build, contains('else if (showingLongReceiptMatch)'));
    expect(build, contains('_ReceiptStitchReviewActions('));
    expect(build, contains('if (_reviewMode == _ReceiptReviewMode.preview &&'));
    expect(build, contains('left: 8,'));
    expect(build, contains('top: 8,'));
    expect(stitchPair, contains('class _ReceiptStitchWorkingSurface'));
    expect(
      stitchPair,
      contains('Combining \$total receipt sections automatically'),
    );
    expect(stitchPair, contains("label: 'Receipt section \${selected + 1}'"));
    expect(stitchPair, contains('onPairSelected'));
    expect(stitchPair, contains('photoPaths.length > 2'));
    expect(stitchPair, contains('_ReceiptStitchPairNavigator('));
    expect(stitchPair, isNot(contains('Top section \${upper + 1}')));
    expect(stitchPair, isNot(contains('Bottom section \${lower + 1}')));
    // Manual recovery is an edge-to-edge canvas rather than receipt photos
    // trapped in cards. Direct gestures update the reversible alignment
    // transform without a large control panel covering the receipt.
    expect(stitchPair, contains('class _ReceiptGhostAlignmentPreview'));
    expect(stitchPair, contains('class _ReceiptManualAlignmentUpdate'));
    expect(stitchPair, contains('fit: StackFit.expand'));
    expect(stitchPair, contains('onScaleStart:'));
    expect(stitchPair, contains('onScaleUpdate:'));
    expect(stitchPair, contains('details.localFocalPoint'));
    expect(stitchPair, contains('details.rotation * 180 / math.pi'));
    expect(stitchPair, isNot(contains('height: 190')));
    expect(stitchPair, isNot(contains('ClipRRect(')));
    expect(stitchPair, contains('opacity: widget.noOverlap ? 1 : .82'));
    expect(stitchPair, contains('Ghost alignment preview for the bottom'));
    expect(stitchPair, contains("label: const Text('Show controls')"));
    expect(stitchPair, contains("child: const Text('Reset')"));
    expect(stitchPair, contains("child: const Text('Hide')"));
    expect(stitchPair, contains('onHorizontalDragEnd:'));
    expect(stitchPair, contains('Drag lower photo. Pinch to resize.'));
    expect(stitchPair, isNot(contains('class _ReceiptAlignmentSlider')));
    expect(stitchPair, isNot(contains("label: 'Move left'")));
    expect(
      stitchPair,
      isNot(contains('Match the repeated printed lines at this join')),
    );
    expect(stitchPair, contains('class _ReceiptStitchedReceiptSurface'));
    expect(stitchPair, contains('showHeader: false'));
    expect(stitchPair, contains('showSelectionBorder: false'));
    expect(stitchPair, contains('Could not safely combine every section'));
    expect(stitchPair, contains('cacheWidth: physicalWidth'));
    expect(
      stitchPair,
      isNot(contains('cacheHeight: physicalHeight')),
      reason: 'A fixed decode height can squash a tall combined receipt.',
    );
    expect(stitchPair, contains('panEnabled: _isZoomed'));
    expect(stitchPair, contains('boundaryMargin: const EdgeInsets.all(48)'));
    expect(stitchPair, contains('onDoubleTap: _toggleZoom'));
    expect(
      stitchPair,
      contains('Pinch or double tap to zoom the receipt image'),
    );
    expect(stitchPair, contains('maxLines: 1'));
    expect(stitchPair, contains('overflow: TextOverflow.ellipsis'));
    expect(stitchPair, isNot(contains('Pinch / double-tap')));
    expect(stitchPair, contains('onTap: widget.onSelected'));
    expect(stitchPair, contains("label: 'Reset receipt zoom'"));
    expect(stitchPair, contains('onPressed: _resetZoom'));
    expect(stitchPair, contains('pairIndex.clamp(0, photoPaths.length - 2)'));
    expect(stitchPair, isNot(contains('class _ReceiptStitchPairPreview')));
    expect(
      stitchPair,
      isNot(contains("'Overlap \${pairIndex + 1}-\${pairIndex + 2}")),
    );
    expect(stitchPair, contains('class _StitchPhotoHeader'));
    expect(
      stitchPair,
      contains('BorderSide(color: Color(0xFF28A745), width: 2)'),
    );
    expect(
      stitchPair,
      contains('Keep the selected-photo identity and gesture help outside the'),
    );
    expect(stitchPair, contains('required this.pairIndex'));
    expect(stitchActions, contains('class _ReceiptStitchBackButton'));
    expect(stitchActions, contains('class _ReceiptStitchReviewActions'));
    expect(stitchActions, contains("? 'Try alignment'"));
    expect(stitchActions, contains(": 'Align two photos'"));
    expect(stitchActions, contains(": 'Continue'"));
    expect(stitchActions, contains("tooltip: 'Review receipt sections'"));
    expect(stitchActions, contains('final compact ='));
    expect(stitchActions, contains('constraints.maxWidth < 480'));
    expect(
      stitchActions,
      contains('MediaQuery.textScalerOf(context).scale(1)'),
    );
    expect(
      await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_async.dart',
      ).readAsString(),
      contains('_selectedIndex = selected;'),
    );
    final stitchSurface = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_surface.dart',
    ).readAsString();
    expect(
      stitchSurface,
      contains('!_manualAlignmentActiveForSelectedPair'),
      reason:
          'A stitch retry must not hide the alignment canvas while the person is using it.',
    );
    final stitchAsync = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_stitch_preview_async.dart',
    ).readAsString();
    expect(stitchAsync, contains('void _setManualAlignmentGesture('));
    expect(stitchAsync, contains('void _resetManualAlignment()'));
    final manualGestureStart = stitchAsync.indexOf(
      'void _setManualAlignmentGesture(',
    );
    final manualResetStart = stitchAsync.indexOf(
      'void _resetManualAlignment()',
    );
    expect(manualGestureStart, isNonNegative);
    expect(manualResetStart, greaterThan(manualGestureStart));
    expect(
      stitchAsync.substring(manualGestureStart, manualResetStart),
      isNot(contains('_scheduleStitchPreviewRefresh()')),
      reason:
          'Direct finger movement must not run image registration on every update.',
    );
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();
    expect(controls, contains("return 'Use combined receipt';"));
    expect(controls, contains("return 'Align receipt sections';"));
    expect(
      controls.indexOf("return 'Use combined receipt';"),
      lessThan(controls.indexOf("return 'Checking receipt photos';")),
      reason:
          'A ready combined image must stay actionable during a stale retry.',
    );
    expect(
      controls,
      isNot(
        contains(
          'effectiveSavingPhotos ||\n                            waitingForStitch',
        ),
      ),
    );
    expect(guide, contains('required this.height'));
    expect(guide, contains('ColorFilter.matrix'));
    expect(
      captureActions,
      contains('nextSectionGuidePhotoPath: nextSectionGuidePhotoPath'),
    );
    expect(orderActions, contains('_reviewMode = _ReceiptReviewMode.preview;'));
    expect(orderActions, contains('_stitchPreviewRequested = false;'));
    expect(orderActions, isNot(contains('shouldMatchSections')));
    expect(modeControls, contains('return Wrap('));
    expect(
      screen,
      contains(
        '_scheduleDataSaverPreviewWork(_dataSaverPreviewSource(photoPath))',
      ),
    );
    final saveActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsString();
    expect(
      saveActions,
      isNot(
        contains('if (_stitchPreviewInFlight && _stitchPreviewResult == null)'),
      ),
      reason: 'Continue must reach the visible preparation step immediately.',
    );
    expect(saveActions, contains('await finishReceiptReview('));
    expect(modeControls, isNot(contains('scrollDirection: Axis.horizontal')));
    expect(alignmentActions, contains('Reference: bottom of previous photo'));
    expect(alignmentActions, contains('Reference: top of next photo'));
    expect(
      alignmentActions,
      contains('The camera will show the bottom of the last photo at the top.'),
    );
    expect(alignmentActions, isNot(contains('top ghost-slice guide')));
    expect(
      guide,
      contains('Match the printed lines at the bottom of your new photo'),
    );
  });
}
