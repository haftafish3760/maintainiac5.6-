import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'first use asks only whether Receipt Assist should help fill the receipt',
    () async {
      final cameraActions = await _read(
        'lib/shared/widgets/receipt_capture/receipt_attachment_camera_actions.dart',
      );
      final firstUseSheet = await _read(
        'lib/shared/widgets/receipt_capture/receipt_camera_first_use_intro_sheet.dart',
      );
      final uiConfig = await _read(
        'lib/shared/widgets/receipt_capture/receipt_capture_ui_config.dart',
      );

      expect(cameraActions, contains('_showFirstUseReceiptCameraIntro'));
      expect(uiConfig, contains("this.firstUseTitle = 'Receipt Assist'"));
      expect(firstUseSheet, contains('useReceiptAssist'));
      expect(firstUseSheet, contains('manualEntry'));
      expect(firstUseSheet, isNot(contains('Storage And Privacy')));
    },
  );

  test(
    'help keeps long-receipt guidance brief and tied to real review actions',
    () async {
      final helpSheet = await _read(
        'lib/shared/widgets/receipt_capture/receipt_camera_help_sheet.dart',
      );
      final primaryRow = await _read(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_preview_primary_row.dart',
      );
      final alignmentGuide = await _read(
        'lib/shared/widgets/receipt_capture/receipt_photo_review_alignment_guide.dart',
      );

      expect(helpSheet, contains('Receipt Photo Help'));
      expect(
        primaryRow,
        contains('_ReceiptPhotoCountBadge(current: current, total: total)'),
      );
      expect(
        primaryRow,
        contains('Add Another Photo only if the receipt continues'),
      );
      expect(primaryRow, isNot(contains('_ReceiptMultiPhotoActionRail')));
      expect(
        alignmentGuide,
        contains('Repeat 3-5 readable lines from this bottom area'),
      );
    },
  );

  test(
    'receipt settings remain an optional help path, not a capture blocker',
    () async {
      final settings = await _read(
        'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
      );
      final sourceSheet = await _read(
        'lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart',
      );

      expect(settings, contains('Expense Receipt Settings'));
      expect(sourceSheet, contains('Capture Photo'));
      expect(sourceSheet, contains('Upload Photos'));
      expect(sourceSheet, contains('Upload PDF/File'));
      expect(sourceSheet, contains('Paste/Text'));
    },
  );
}

Future<String> _read(String path) => File(path).readAsString();
