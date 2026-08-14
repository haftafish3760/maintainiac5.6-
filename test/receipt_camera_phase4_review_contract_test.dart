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
        'The person reviews the\n    // ordered photos first; automatic assembly starts only after Continue.',
      ),
    );
    expect(
      reviewScreen,
      contains('if (_photoPaths.isEmpty) return _buildEmptyReviewRecovery();'),
    );
    expect(
      reviewScreen,
      contains(
        'final selectedPhotoIndex = _selectedIndex.clamp(0, _photoPaths.length - 1);',
      ),
    );
    expect(
      reviewScreen,
      contains('final photoPath = _photoPaths[selectedPhotoIndex];'),
    );
    expect(reviewScreen, isNot(contains("return _ReceiptReviewMode.stitch;")));
    expect(
      controls,
      contains('final hasCapturedPhotos = photoPaths.isNotEmpty;'),
    );
    expect(
      controls,
      contains(
        'final effectiveSavingPhotos = savingPhotos && hasCapturedPhotos;',
      ),
    );
    expect(controls, contains("return 'Choose Saved Image Size';"));
    expect(previewRow, contains('uiConfig.addPhotoLabel'));
    expect(previewTray, isNot(contains("'Add Next Section'")));
    expect(previewRow, contains('retakeLabel'));
    expect(previewRow, contains('continueLabel'));
    expect(
      previewTray,
      contains('onRetake: interactionLocked ? null : onRetake'),
    );
    expect(
      previewTray,
      contains('onAddPhoto: interactionLocked ? null : onAddPhoto'),
    );
    expect(
      previewTray,
      contains('final effectiveSelectedIndex = photoPaths.isEmpty'),
    );
    expect(
      previewTray,
      contains('selectedIndex.clamp(0, photoPaths.length - 1);'),
    );
    expect(
      controls,
      contains('onContinue: continueEnabled ? onContinue : null'),
    );
    expect(previewRow, contains("'Opening'"));
    expect(commonControls, contains("const Text('Opening')"));
    expect(
      commonControls,
      contains(
        "final semanticLabel = savingPhotos ? 'Opening receipt details' : label;",
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
      isNot(
        contains(
          "const ReceiptPickerStatus(label: 'Opening receipt details...')",
        ),
      ),
    );
  });

  test('receipt photo review keeps clear retake and continuation wording', () async {
    final sectionLabels = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_section_labels.dart',
    ).readAsString();
    final contextControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_context_controls.dart',
    ).readAsString();
    final previewControls = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_controls.dart',
    ).readAsString();
    final previewRow = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
    ).readAsString();

    expect(sectionLabels, contains("return 'Retake Photo';"));
    expect(sectionLabels, contains("return 'Retake Section \${index + 1}';"));
    expect(
      sectionLabels,
      contains(
        "return index >= total - 1 ? 'Add Next Receipt Photo' : 'Add Missing Photo';",
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
        'Retake is safer for receipt reading. Use this photo only if the store, date, total, and item prices are readable.',
      ),
    );
    expect(
      previewRow,
      contains(
        'Add bottom receipt section and repeat 3-5 readable lines in the top reference strip',
      ),
    );
    expect(previewRow, isNot(contains('_ReceiptPhotoCountBadge')));
    expect(previewControls, isNot(contains('_ReceiptPhotoCountBadge')));
    expect(previewRow, contains('FittedBox('));
    expect(previewRow, contains('maxLines: 1'));
    expect(
      await File(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
      ).readAsString(),
      contains('SizedBox(height: compactControls ? 5 : 7)'),
    );
    expect(
      contextControls,
      contains(
        'Use this photo only if the store, date, total, and item prices are readable.',
      ),
    );
    final completionActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_completion_actions.dart',
    ).readAsString();
    final exitActions = await File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_exit_actions.dart',
    ).readAsString();
    expect(completionActions, contains('decision.shouldPromptForMorePhotos'));
    expect(exitActions, contains("const Text('Back to Photos')"));
    expect(completionActions, isNot(contains("const Text('Stay In Review')")));
    expect(exitActions, isNot(contains("const Text('Stay In Review')")));
  });
}
