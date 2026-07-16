import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'receipt review opens on the captured photo before processing',
    () async {
      final screen = await _read(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_screen.dart',
      );
      final controls = await _read(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_controls.dart',
      );

      expect(screen, contains('return _ReceiptReviewMode.preview;'));
      expect(
        screen,
        contains(
          'if (_photoPaths.isEmpty) return _buildEmptyReviewRecovery();',
        ),
      );
      expect(
        screen,
        contains('final photoPath = _photoPaths[selectedPhotoIndex];'),
      );
      expect(
        controls,
        contains('final hasCapturedPhotos = photoPaths.isNotEmpty;'),
      );
      expect(
        controls,
        contains('onContinue: continueEnabled ? onContinue : null'),
      );
    },
  );

  test(
    'preview gives one plain set of actions and keeps the photo count visible',
    () async {
      final primaryRow = await _read(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
      );
      final tray = await _read(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_action_tray.dart',
      );

      expect(
        primaryRow,
        contains('_ReceiptPhotoCountBadge(current: current, total: total)'),
      );
      expect(primaryRow, contains('onPressed: savingPhotos ? null : onRetake'));
      expect(
        primaryRow,
        contains('onPressed: savingPhotos ? null : onAddPhoto'),
      );
      expect(
        primaryRow,
        contains('onPressed: savingPhotos ? null : onContinue'),
      );
      expect(
        primaryRow,
        contains('Add another receipt photo if the receipt continues'),
      );
      expect(primaryRow, isNot(contains('Add Bottom Section')));
      expect(tray, contains('_ReceiptOrderThumbnail('));
      expect(tray, isNot(contains('_ReceiptMultiPhotoActionRail(')));
    },
  );

  test(
    'cancelling or backing out has clear recovery instead of a fake processing state',
    () async {
      final completionActions = await _read(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_completion_actions.dart',
      );
      final exitActions = await _read(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_exit_actions.dart',
      );

      expect(completionActions, contains('decision.shouldPromptForMorePhotos'));
      expect(exitActions, contains("const Text('Back to Photos')"));
      expect(
        completionActions,
        isNot(contains("const Text('Stay In Review')")),
      );
      expect(exitActions, isNot(contains("const Text('Stay In Review')")));
    },
  );
}

Future<String> _read(String path) => File(path).readAsString();
