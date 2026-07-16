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
    expect(primary, contains('onRetake: interactionLocked ? null : onRetake'));
    expect(
      primary,
      contains('onAddPhoto: interactionLocked ? null : onAddPhoto'),
    );
    expect(tray, contains('_ReceiptOrderThumbnail('));
    expect(
      controls,
      contains("return photoPaths.length > 1 ? 'Continue' : 'Use Receipt'"),
    );
  });

  test('continuing a multi-photo receipt opens the match step', () async {
    final save = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_save_actions.dart',
    ).readAsString();

    expect(save, contains('if (_needsStitchReviewBeforeSave)'));
    expect(save, contains('_reviewMode = _ReceiptReviewMode.stitch'));
    expect(save, contains('_ensureStitchPreview(force: true)'));
  });
}
