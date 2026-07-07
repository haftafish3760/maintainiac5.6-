import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt photo review stays photo-first before processing handoff', () async {
    final reviewScreen = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
    ).readAsString();
    final controls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
    ).readAsString();
    final commonControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_common_controls.dart',
    ).readAsString();
    final previewRow = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
    ).readAsString();
    final previewTray = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
    ).readAsString();

    expect(reviewScreen, contains('return _ReceiptReviewMode.preview;'));
    expect(
      reviewScreen,
      contains(
        'Even for long receipts, start on the actual captured photo preview',
      ),
    );
    expect(reviewScreen, contains('if (_photoPaths.isEmpty) return _buildEmptyReviewRecovery();'));
    expect(reviewScreen, isNot(contains("return _ReceiptReviewMode.stitch;")));
    expect(controls, contains('final hasCapturedPhotos = photoPaths.isNotEmpty;'));
    expect(
      controls,
      contains('final effectiveSavingPhotos = savingPhotos && hasCapturedPhotos;'),
    );
    expect(controls, contains("return 'Use Receipt';"));
    expect(previewRow, contains("'Add Another Photo'"));
    expect(previewRow, contains('retakeLabel'));
    expect(previewRow, contains('continueLabel'));
    expect(previewTray, contains('onRetake: interactionLocked ? null : onRetake'));
    expect(previewTray, contains('onAddPhoto: interactionLocked ? null : onAddPhoto'));
    expect(previewTray, contains('final effectiveSelectedIndex = photoPaths.isEmpty'));
    expect(previewTray, contains('selectedIndex.clamp(0, photoPaths.length - 1);'));
    expect(controls, contains('onContinue: continueEnabled ? onContinue : null'));
    expect(previewRow, contains("'Preparing'"));
    expect(commonControls, contains("const Text('Preparing')"));
    expect(
      commonControls,
      contains(
        "final semanticLabel = savingPhotos ? 'Preparing receipt details' : label;",
      ),
    );
    expect(
      controls,
      contains(
        "effectiveSavingPhotos\n                            ? const ReceiptPickerStatus(\n                                label: 'Opening receipt details...',",
      ),
    );
    expect(
      controls,
      isNot(contains("const ReceiptPickerStatus(label: 'Preparing receipt details...')")),
    );
  });

  test('receipt photo review keeps clear retake and continuation wording', () async {
    final sectionLabels = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart',
    ).readAsString();
    final contextControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart',
    ).readAsString();
    final previewRow = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
    ).readAsString();

    expect(sectionLabels, contains("return 'Retake Photo';"));
    expect(sectionLabels, contains("return 'Retake Section \${index + 1}';"));
    expect(
      sectionLabels,
      contains(
        "return total <= 1 ? 'Add Another Photo' : 'Add Next Receipt Photo';",
      ),
    );
    expect(
      contextControls,
      contains(
        'Use this photo only if the store, date, total, and item prices are readable.',
      ),
    );
    expect(
      contextControls,
      contains(
        'Retake is safer for OCR quality. Use this photo only if the store, date, total, and item prices are readable.',
      ),
    );
    expect(
      previewRow,
      contains(
        'Add bottom receipt section and repeat 3-5 readable lines in the top ghost slice',
      ),
    );
    expect(previewRow, contains('_ReceiptPhotoCountBadge(current: current, total: total)'));
    expect(previewRow, contains('maxLines: compact ? 1 : 2'));
    expect(previewRow, contains('SizedBox(height: compact ? 5 : 7)'));
    expect(
      contextControls,
      contains('Use this photo only if the store, date, total, and item prices are readable.'),
    );
  });
}
