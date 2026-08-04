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
    expect(settingsSheet, isNot(contains('if (hasSavedReceiptProof) ...[')));
    expect(
      settingsSheet,
      contains('_ReceiptDataSaverDefaultPicker(settings: settings)'),
    );
    expect(
      settingsSheet,
      contains('Your next receipt review shows the actual saved image size'),
    );
    expect(
      settingsSheet,
      contains(
        'Changes save as soon as you tap a switch. Apply Settings closes this screen. Saved image size appears after you capture or attach a receipt first.',
      ),
    );
    expect(
      storageSettings,
      contains('Receipt Assist always reads the clear source first'),
    );
    expect(
      storageSettings,
      contains('After a photo is taken, you preview the actual saved image'),
    );
    expect(storageSettings, contains('Saved Receipt Image'));
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
        'Changes apply to this camera session. The phone keeps control of its supported autofocus, lens, exposure, and stabilization features.',
      ),
    );
    expect(
      iosCameraSettings,
      contains(
        'These controls apply while this camera is open. Set your usual receipt defaults in Receipt Settings.',
      ),
    );
    expect(iosCameraSettings, isNot(contains('SAVED PROOF SIZE')));
    expect(
      iosCopy,
      contains(
        'Maintainiac reads the temporary full-quality photo first. Saved proof size stays hidden until there is real receipt proof to review.',
      ),
    );
    expect(
      iosCopy,
      contains(
        'Maintainiac reads the temporary full-quality photo first. Smaller saved proof copies are made after the receipt has been read.',
      ),
    );
  });
}
