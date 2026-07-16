import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('initial photo review keeps the receipt image primary', () async {
    final screen = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_build.dart',
    ).readAsString();
    final tray = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
    ).readAsString();

    expect(screen, contains('body: SafeArea('));
    expect(screen, contains('Expanded(\n                child: Stack('));
    expect(screen, contains('_buildPhotoSurface('));
    expect(tray, contains('_ReceiptPreviewPrimaryRow('));
    expect(tray, isNot(contains('_ReceiptMultiPhotoActionRail(')));
    expect(tray, isNot(contains('_ReceiptSinglePhotoActionRow(')));
    expect(tray, isNot(contains('_ReceiptPhotoQualityRecoveryStrip(')));
  });

  test('review exposes only selected photo, retake, add, and continue', () async {
    final primary = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
    ).readAsString();
    final tray = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
    ).readAsString();
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();

    expect(
      primary,
      contains('_ReceiptPhotoCountBadge(current: current, total: total)'),
    );
    expect(primary, contains('_ReceiptPhotoSectionLabels.retakeLabel'));
    expect(primary, contains('final addPhotoLabel'));
    expect(primary, contains('onPressed: savingPhotos ? null : onRetake'));
    expect(primary, contains('onPressed: savingPhotos ? null : onAddPhoto'));
    expect(primary, contains("uiConfig.labelFor('addPhoto'"));
    expect(primary, isNot(contains("'Add Bottom Section'")));
    expect(primary, isNot(contains('Add the bottom section')));
    final coverageLabels = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_coverage_decision_labels.dart',
    ).readAsString();
    expect(
      coverageLabels,
      contains("String get addSectionButtonLabel => 'Add Another Photo'"),
    );
    expect(coverageLabels, isNot(contains('Add Bottom Section')));
    expect(tray, contains('_ReceiptOrderThumbnail('));
    expect(
      controls,
      contains(
        "if (reviewMode != _ReceiptReviewMode.stitch) return 'Use Receipt';",
      ),
    );
  });

  test(
    'using a multi-photo receipt prepares the match in the background',
    () async {
      final save = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
      ).readAsString();
      final primary = await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
      ).readAsString();

      expect(save, contains('if (_needsStitchReviewBeforeSave)'));
      expect(save, contains('await _ensureStitchPreview(force: true);'));
      expect(save, isNot(contains('_reviewMode = _ReceiptReviewMode.stitch')));
      expect(
        save.indexOf('_updateReviewState(() => _savingPhotos = true);'),
        lessThan(save.indexOf('await _ensureStitchPreview(force: true);')),
      );
      expect(primary, contains("? const Text('Preparing')"));
    },
  );

  test('adding another receipt photo shows the previous-section guide', () async {
    final captureActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_capture_actions.dart',
    ).readAsString();

    final addAnotherStart = captureActions.indexOf(
      'Future<void> addAnotherReceiptPhoto()',
    );
    final retakeStart = captureActions.indexOf(
      'Future<void> retakeCurrentReceiptPhoto()',
    );
    final addAnother = captureActions.substring(addAnotherStart, retakeStart);

    expect(addAnother, contains('alignmentGuidePhotoPath: guidePhotoPath'));
    expect(addAnother, isNot(contains('showAlignmentGuide: false')));
    expect(
      captureActions,
      contains('showAlignmentGuide: _shouldShowLongReceiptGuidance'),
    );
    expect(captureActions, contains('?.cameraLongReceiptTips ??\n      true'));
  });

  test('long receipt guide is honest about the system camera handoff', () async {
    final alignmentActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_actions.dart',
    ).readAsString();
    expect(alignmentActions, contains("return 'Open Phone Camera';"));
    expect(
      alignmentActions,
      contains('You will return to the numbered receipt review.'),
    );
    expect(alignmentActions, isNot(contains('review the order')));
    expect(alignmentActions, isNot(contains('Match Photos')));
    expect(alignmentActions, isNot(contains('top of the next camera photo')));
    expect(alignmentActions, contains('Use the reference photo below.'));
    expect(alignmentActions, contains('Open your phone camera'));
    expect(alignmentActions, isNot(contains('_ReceiptAlignmentGuideNote(')));
  });

  test('possible continuation asks before using the receipt', () async {
    final completionActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_completion_actions.dart',
    ).readAsString();

    expect(completionActions, contains('showDialog<_ReceiptContinueDecision>'));
    expect(completionActions, contains('Keep Reviewing'));
    expect(completionActions, contains('decision.addSectionButtonLabel'));
    expect(completionActions, contains('decision.continueAnywayButtonLabel'));
    expect(completionActions, contains('await addAnotherReceiptPhoto()'));
    expect(
      completionActions,
      isNot(
        contains(
          'decision: _ReceiptContinueDecision.continueAnyway,\n      coverageDecision',
        ),
      ),
    );
  });
}
