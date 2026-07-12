import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phase 8 keeps storage proof settings behind attached receipt proof', () async {
    final publishHelpers = await File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_publish_helpers.dart',
    ).readAsString();
    final settingsSheet = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
    ).readAsString();
    final storageSettings = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_review_storage_settings.dart',
    ).readAsString();
    final storageHandoff = await File(
      'lib/shared/widgets/receipt_capture/receipt_capture_review_result_handoff_storage.dart',
    ).readAsString();
    final androidSettings = await File(
      'android/app/src/main/kotlin/com/maintainiac/ReceiptCameraSettingsDialog.kt',
    ).readAsString();
    final iosCameraSettings = await File(
      'ios/Runner/ReceiptCameraFullScreenSettingsViewController.swift',
    ).readAsString();
    final iosCopy = await File(
      'ios/Runner/ReceiptCameraViewControllerSettingsCopy.swift',
    ).readAsString();

    expect(publishHelpers, contains('hasSavedReceiptProof:'));
    expect(
      publishHelpers,
      contains('_photoPaths.isNotEmpty || _documentAttachments.isNotEmpty'),
    );
    expect(settingsSheet, contains('required this.hasSavedReceiptProof'));
    expect(settingsSheet, contains('final bool hasSavedReceiptProof;'));
    expect(settingsSheet, contains('if (hasSavedReceiptProof) ...['));
    expect(
      settingsSheet,
      contains('_ReceiptDataSaverDefaultPicker(settings: settings)'),
    );
    expect(
      settingsSheet,
      contains(
        'Saved Receipt Proof Size appears after your first receipt photo or file is attached.',
      ),
    );
    expect(
      settingsSheet,
      contains(
        'Changes save as soon as you tap a switch. Apply Settings closes this screen. Saved proof size appears after you capture or attach a receipt first.',
      ),
    );
    expect(
      storageSettings,
      contains('OCR still uses the clearest receipt source first'),
    );
    expect(
      storageSettings,
      contains('You preview the actual saved proof after taking a photo.'),
    );
    expect(storageSettings, contains('Receipt Details And Saved Proof'));
    expect(storageHandoff, contains('saved_proof_kept_for_receipt_record'));
    expect(
      storageHandoff,
      contains('ocr_source_used_for_reading_before_saved_proof'),
    );
    expect(
      storageHandoff,
      contains('temporary_ocr_source_separate_from_saved_proof'),
    );
    expect(
      storageHandoff,
      contains('clear_ocr_source_read_before_saved_proof_copy'),
    );
    expect(
      storageHandoff,
      contains("return 'saved_proof_ocr_fallback_review';"),
    );
    expect(
      storageHandoff,
      contains("return 'temporary_full_quality_source_guard_review';"),
    );
    expect(
      storageHandoff,
      contains("return 'temporary_ocr_source_saved_data_saver_proof';"),
    );
    expect(
      storageHandoff,
      contains("return 'temporary_ocr_source_original_quality_proof';"),
    );
    expect(storageHandoff, contains("return 'saved_proof_storage_ready';"));

    expect(
      androidSettings,
      contains(
        'Receipt Assist, saved-photo, and account preferences stay in Expense Settings.',
      ),
    );
    expect(
      iosCameraSettings,
      contains(
        'Receipt Assist, saved-photo, and account preferences stay in Expense Settings.',
      ),
    );
    expect(iosCameraSettings, isNot(contains('SAVED PROOF SIZE')));
    expect(
      iosCopy,
      contains(
        'OCR reads the temporary full-quality photo first. Saved proof size stays hidden until there is real receipt proof to review.',
      ),
    );
    expect(
      iosCopy,
      contains(
        'OCR reads the temporary full-quality photo first. Smaller saved proof copies are made after the receipt has been read.',
      ),
    );
  });
}
